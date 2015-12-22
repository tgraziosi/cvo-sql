SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[tdc_putaway_bin_replenish]
	@location 	varchar(10),
	@part_no	varchar(30),
	@lot_ser 	varchar(25),
	@bin_no   	varchar(12),
	@qty      	decimal (20,8)
AS

-- EXEC tdc_putaway_bin_replenish 'Dallas', 'ACCT-ACM-FS35', 'lot-001', 'W', 100

DECLARE @repl_bin   		varchar(12),
	@repl_max 		decimal(20,8),
	@repl_min 		decimal(20,8),
	@repl_qty 		decimal(20,8),
        @pending_mgtb2b_qty     decimal(20,8),
	@lb_qty 		decimal(20,8),
	@current_bin_qty	decimal(20,8),
	@qty_to_move		decimal(20,8),
	@priority		int,
	@seqno			int,
	@bin2bingroupid		varchar(25),
	@q_priority		int,
-- new data for replenish logging
	@replenish_min_lvl decimal (20, 0) ,	-- from tdc_bin_replenishment
	@replenish_max_lvl decimal (20, 0) ,	-- from tdc_bin_replenishment
	@replenish_qty  decimal (20, 0) ,		-- from tdc_bin_replenishment
	@last_modified_date datetime ,		-- from tdc_bin_replenishment
	@modified_by varchar(50) ,			-- from tdc_bin_replenishment
	@auto_replen int,				-- from tdc_bin_replenishment
    @inventory_vw_total_qty		decimal(20,8),
	@tranid int

IF NOT EXISTS (SELECT * FROM tdc_bin_master (nolock) WHERE location = @location AND bin_no = @bin_no AND status = 'A' AND usage_type_code = 'OPEN')
	RETURN 0

SELECT @priority = ISNULL((SELECT value_str 
			     FROM tdc_config (nolock)  
			    WHERE [function] = 'mgt_pick_q_priority' AND active = 'Y'), 0)

IF @priority = 0
BEGIN
	RAISERROR('Error Invalid Priority.', 1, -16)
	RETURN -100
END

SELECT @q_priority = cast(value_str as int) FROM tdc_config WHERE [function] = 'pick_q_priority'

IF (@q_priority IS NULL) OR (@q_priority = 0)
	SELECT @q_priority = 5

SELECT @bin2bingroupid = (SELECT group_id FROM tdc_group (NOLOCK) WHERE trans_type = 'MGTB2B')	

DECLARE replenish_bin_cursor CURSOR FOR 
	SELECT replenish_max_lvl, replenish_min_lvl, replenish_qty, bin_no
	  FROM tdc_bin_replenishment
	 WHERE location = @location 
	   AND part_no  = @part_no
	   AND auto_replen = 1
	ORDER BY bin_no

OPEN replenish_bin_cursor

FETCH NEXT FROM replenish_bin_cursor INTO @repl_max, @repl_min, @repl_qty, @repl_bin

WHILE (@@FETCH_STATUS = 0)
BEGIN
	SELECT @lb_qty = ISNULL((SELECT sum(qty)
				   FROM lot_bin_stock
				  WHERE location = @location
				    AND part_no  = @part_no
				    AND bin_no   = @repl_bin), 0)

	SELECT @pending_mgtb2b_qty = ISNULL((SELECT sum(qty_to_process) 
					       FROM tdc_pick_queue
					      WHERE trans_source = 'MGT'
						AND trans = 'MGTB2B'
						AND location = @location
						AND trans_type_no  = 0
						AND trans_type_ext = 0
						AND line_no = 0 
						AND next_op = @repl_bin
						AND part_no = @part_no), 0)

	SELECT @current_bin_qty = @lb_qty + @pending_mgtb2b_qty

	IF (@repl_min > @current_bin_qty)
	BEGIN
		IF (@repl_qty >= @qty)
			SELECT @qty_to_move = @qty
		ELSE
			SELECT @qty_to_move = @repl_qty

		IF (@current_bin_qty + @qty_to_move) > @repl_max
			SELECT @qty_to_move = @repl_max - @current_bin_qty

		SELECT @qty = @qty - @qty_to_move

		IF EXISTS (SELECT * 
			     FROM tdc_soft_alloc_tbl
			    WHERE order_no = 0
			      AND order_ext = 0
			      AND order_type = 'S'
			      AND location = @location
			      AND line_no = 0
			      AND part_no = @part_no
			      AND lot_ser = @lot_ser
			      AND bin_no = @bin_no
			      AND dest_bin = @repl_bin)
		BEGIN
			UPDATE tdc_soft_alloc_tbl
			   SET qty = qty + @qty_to_move
		         WHERE order_no = 0
		           AND order_ext = 0
		           AND order_type = 'S'
		           AND location = @location
		           AND line_no = 0
		           AND part_no = @part_no
		           AND lot_ser = @lot_ser
			   AND bin_no = @bin_no
		           AND dest_bin = @repl_bin
		END
		ELSE
		BEGIN
			INSERT INTO tdc_soft_alloc_tbl
				(order_type, order_no, order_ext, location, line_no, part_no,  lot_ser, bin_no, qty, target_bin, dest_bin, q_priority)
			VALUES  ('S', 0, 0, @location, 0, @part_no, @lot_ser, @bin_no, @qty_to_move, @repl_bin, @repl_bin, @q_priority)

			EXEC @seqno = tdc_queue_get_next_seq_num 'tdc_pick_queue', @priority 	

			IF (@seqno = 0)
			BEGIN
				DEALLOCATE replenish_bin_cursor
				RAISERROR('Invalid Sequence Number.', 1, -16)
				RETURN -101
			END

			INSERT INTO tdc_pick_queue 
				(trans_source, trans, priority, seq_no, location, trans_type_no, trans_type_ext, line_no, part_no, eco_no, lot, qty_to_process, 
					qty_processed, qty_short, next_op, bin_no, date_time, assign_group, tx_control, tx_lock)
			VALUES ('MGT', 'MGTB2B', @priority, @seqno, @location,  0, 0, 0, 
				@part_no, 'tdc_ptawy_repl', @lot_ser, @qty_to_move, 0, 0, @repl_bin, @bin_no, GETDATE(), @bin2bingroupid, 'M', 'R') 

--Begin New Logging
-- get tran_id
SELECT @tranid = tran_id FROM tdc_pick_queue 
WHERE seq_no = @SeqNo and part_no = @part_no and trans = 'MGTB2B' and bin_no = @repl_bin

--get replenishment data
SELECT 
	   @replenish_min_lvl = [replenish_min_lvl]
      ,@replenish_max_lvl = [replenish_max_lvl]
      ,@replenish_qty = [replenish_qty]
      ,@last_modified_date = [last_modified_date]
      ,@modified_by = [modified_by]
      ,@auto_replen = [auto_replen]
  FROM [CVO].[dbo].[tdc_bin_replenishment] WHERE location = @location and part_no = @part_no and bin_no = @bin_no

-- get inventory view qty
SELECT @inventory_vw_total_qty = in_stock FROM inventory WHERE location = @location and part_no = @part_no 

INSERT INTO [CVO].[dbo].[tdc_replenishment_log]
           ([TranId],[tran_date],[proc_name],[proc_in_location],[proc_in_part_no],[proc_in_bin_no]
           ,[proc_in_delta_qty] ,[proc_in_qty_from_lbs]
           ,[repl_table_replenish_min_lvl],[repl_table_replenish_max_lvl],[repl_table_replenish_qty]
           ,[repl_table_last_modified_date],[repl_table_modified_by],[repl_table_auto_replen]
           ,[current_bin_qty],[qty_to_move],[repl_from_lb_bin],[repl_from_lb_qty],[inventory_vw_total_qty])
     VALUES
           (@TranId 
           ,getdate()
           ,'tdc_putaway_bin_replenish'
           ,@location
           ,@part_no
           ,@repl_bin
           ,0
           ,@lb_qty
           ,@replenish_min_lvl
           ,@replenish_max_lvl
           ,@replenish_qty
           ,@last_modified_date
           ,@modified_by
           ,@auto_replen
           ,@current_bin_qty
           ,@qty_to_move
           ,@bin_no
           ,@qty_to_move
           ,@inventory_vw_total_qty)


--End New Logging

		END
	END

	IF @qty <= 0 BREAK

   	FETCH NEXT FROM replenish_bin_cursor INTO @repl_max, @repl_min, @repl_qty, @repl_bin
END

DEALLOCATE replenish_bin_cursor
GO
GRANT EXECUTE ON  [dbo].[tdc_putaway_bin_replenish] TO [public]
GO
