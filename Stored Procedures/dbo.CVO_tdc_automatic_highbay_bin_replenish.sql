SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[CVO_tdc_automatic_highbay_bin_replenish]
	@in_location 		varchar(10),
	@in_part_no			varchar(30),
	@in_bin_no   		varchar(12),
	@in_delta_qty      	decimal (20,8),
	@in_qty_from_lbs 	decimal (20,8)
	
AS
BEGIN
	SET NOCOUNT ON

	DECLARE	@Priority			int,
			@q_priority			int,
			@order_by_value		varchar(255),
			@order_by_clause 	varchar(255),
			@Bin2BinGroupId		varchar(25),
			@repl_max 			decimal(20,8),
			@repl_min 			decimal(20,8),
			@repl_qty 			decimal(20,8),
			@pending_mgtb2b_qty decimal(20,8),
			@current_bin_qty	decimal(20,8),
			@insert_lbclause1 	varchar(255),
			@insert_lbclause2 	varchar(255),
			@max_bin_level		int,
			@qty_to_move		decimal(20,8),
			@id					int,
			@last_id			int,
			@lb_loc 			varchar(10),
			@lb_part 			varchar(30),
			@lb_lot 			varchar(25),
			@lb_bin 			varchar(12),
			@lb_qty 			decimal(20,8),
			@SeqNo				int 


	/* select the default priority for this management bin2bin */
	SELECT @priority = ISNULL((SELECT value_str 
				     FROM tdc_config (nolock)  
				    WHERE [function] = 'MGT_Pick_Q_Priority' AND active = 'Y'), 0)

	IF @Priority = 0
	BEGIN
		RAISERROR 84695 'Error Invalid Priority.'
		RETURN
	END

	SELECT @q_priority = cast(value_str as int) FROM tdc_config WHERE [function] = 'Pick_Q_Priority'

	IF (@q_priority IS NULL) OR (@q_priority = 0)
		SELECT @q_priority = 5

	CREATE TABLE #temp_replenish (
				id			int identity(1,1),
				location	varchar(10),
				part_no		varchar(30),
				lot_ser		varchar(20),
				bin_no		varchar(20),
				qty			decimal(20,8))


	/* Build select statement for lot-bin-stock query...specifically the order by logic */
	SELECT @order_by_value = value_str 
    FROM tdc_config (nolock)
    WHERE [function] = 'dist_cust_pick'

	IF @order_by_value IS NULL
		SET @order_by_value = 1

	SELECT @Bin2BinGroupId = (SELECT group_id FROM tdc_group (NOLOCK) WHERE trans_type = 'MGTB2B')	

	SET @repl_max = 100000 

	SELECT	@repl_min = min_qty
	FROM	CVO_bin_replenishment_tbl (NOLOCK)
	WHERE	bin_no = @in_bin_no  
	AND		part_no = @in_part_no 

	SELECT	@max_bin_level = ISNULL(maximum_level,0) -- v1.0 Use level from tdc_bin_master
	FROM	tdc_bin_master (NOLOCK)
	WHERE	location = '001'
	AND		bin_no = @in_bin_no

	SET	@repl_qty = @max_bin_level - @in_qty_from_lbs -- v1.0 Use new max level
		
	/* Get existing quantity for this part in the replenishment bin */  
	SET @current_bin_qty = @in_qty_from_lbs

	/* We need to take in consideration any existing moves (Mgtb2b) on the queue already */ 
	SELECT @pending_mgtb2b_qty = ISNULL((SELECT sum(qty_to_process) 
					       FROM tdc_pick_queue (nolock)
					      WHERE trans_source = 'MGT'
						AND trans = 'MGTB2B'
						AND location = @in_location
						AND trans_type_no = 0
						AND trans_type_ext = 0
						AND line_no = 0 
						AND next_op = @in_bin_no
						AND part_no = @in_part_no), 0)
		
	IF @current_bin_qty >= @repl_min
	BEGIN
		RETURN
	END


	IF (@current_bin_qty + @repl_qty) <= @repl_max
	BEGIN         
		SELECT @qty_to_move = @repl_qty 
	END
	ELSE
	BEGIN
		SELECT @qty_to_move = @repl_max - @repl_qty
	END

	IF (@qty_to_move > 0) /*ONLY NEED TO PROCESS QUANTITIES THAT ARE GREATER THAN 0 */
	BEGIN
		INSERT	#temp_replenish (location, part_no , lot_ser, bin_no, qty)
		SELECT	a.location, a.part_no, a.lot_ser, a.bin_no, a.qty
		FROM	lot_bin_stock a (NOLOCK)
		JOIN	tdc_bin_master b (NOLOCK)
		ON		a.location = b.location
		AND		a.bin_no = b.bin_no
		WHERE	a.location = '001'
		AND		a.part_no = @in_part_no
		AND		b.usage_type_code = 'OPEN'
		AND		b.group_code <> 'HIGHBAY'
		AND		a.bin_no <> 'CUSTOM'
		AND		ISNULL(b.bm_udef_e,'') <> '1' -- v1.4
		ORDER BY 
				CASE WHEN @order_by_value = 1 THEN a.date_expires END DESC,
				CASE WHEN @order_by_value = 2 THEN a.date_expires END ASC,	
				CASE WHEN @order_by_value = 3 THEN a.lot_ser + a.bin_no END ASC,	
				CASE WHEN @order_by_value = 4 THEN a.lot_ser + a.bin_no END DESC,	
				CASE WHEN @order_by_value = 5 THEN a.qty END ASC,	
				CASE WHEN @order_by_value = 6 THEN a.qty END DESC	

		UPDATE	#temp_replenish
		SET		qty = qty - ISNULL((SELECT	SUM(qty) 
									FROM	tdc_soft_alloc_tbl (nolock)
									WHERE	#temp_replenish.location = tdc_soft_alloc_tbl.location
									AND		#temp_replenish.part_no = tdc_soft_alloc_tbl.part_no
									AND		#temp_replenish.bin_no = tdc_soft_alloc_tbl.bin_no
									AND		tdc_soft_alloc_tbl.order_no > 0), 0)

		DELETE	#temp_replenish
		WHERE	qty <= 0

	END

	SET @last_id = 0

	SELECT	TOP 1 @id = id,
			@lb_loc = location, 
			@lb_part = part_no, 
			@lb_lot = lot_ser, 
			@lb_bin = bin_no, 
			@lb_qty = qty
	FROM	#temp_replenish
	WHERE	id > @last_id
	ORDER BY id ASC
	
	WHILE @@ROWCOUNT <> 0
	BEGIN

		IF (@lb_qty >= @qty_to_move)
		BEGIN 
			IF EXISTS (SELECT * 
					     FROM tdc_soft_alloc_tbl
					    WHERE order_no = 0
					      AND order_ext = 0
					      AND order_type = 'S'
					      AND location = @lb_loc
					      AND line_no = 0
					      AND part_no = @lb_part
					      AND lot_ser = @lb_lot
					      AND bin_no = @lb_bin
					      AND dest_bin = @in_bin_no )
			BEGIN
				UPDATE	tdc_soft_alloc_tbl
  				SET		qty = @qty_to_move
				WHERE	order_no = 0
				AND		order_ext = 0
				AND		order_type = 'S'
				AND		location = @lb_loc
				AND		line_no = 0
				AND		part_no = @lb_part
				AND		lot_ser = @lb_lot
				AND		bin_no = @lb_bin
				AND		dest_bin = @in_bin_no
			END
			ELSE
			BEGIN
				INSERT INTO tdc_soft_alloc_tbl
					(order_type, order_no, order_ext, location, line_no, part_no,
						 lot_ser, bin_no, qty, target_bin, dest_bin, q_priority)
				VALUES ('S', 0, 0, @in_location, 0, @in_part_no, 
					@lb_lot, @lb_bin, @qty_to_move, @in_bin_no, @in_bin_no, @q_priority)

				EXEC @SeqNo = tdc_queue_get_next_seq_num 'tdc_pick_queue', @Priority 	

				IF (@SeqNo = 0)
				BEGIN
						IF @@TRANCOUNT > 0 ROLLBACK TRAN
						RAISERROR 84695 'Error Invalid Sequence or Trans Id or Priority.'
						RETURN
				END
	
				INSERT INTO tdc_pick_queue (trans_source, trans, priority, seq_no,
      					location, trans_type_no, trans_type_ext, line_no, part_no, eco_no, lot,qty_to_process, 
       					qty_processed, qty_short,next_op, bin_no, date_time,assign_group, tx_control, tx_lock)
				VALUES ('MGT', 'MGTB2B', @Priority, @SeqNo, @in_location,  0,  0, 0, 
					@in_part_no, 'Y', @lb_lot, @qty_to_move, 0, 0, @in_bin_no, @lb_bin, GETDATE(), @Bin2BinGroupId, 'M', 'R') 

				IF @@ERROR <> 0 
				BEGIN
					IF @@TRANCOUNT > 0 ROLLBACK TRAN
					RAISERROR 84691 'Error Inserting into Pick_queue table.'
					RETURN
				END
			END
			
			DROP TABLE 	#temp_replenish
			

			RETURN
		END
		ELSE
		BEGIN
			IF EXISTS (SELECT * 
					     FROM tdc_soft_alloc_tbl
					    WHERE order_no = 0
					      AND order_ext = 0
					      AND order_type = 'S'
					      AND location = @lb_loc
					      AND line_no = 0 
					      AND part_no = @lb_part
					      AND lot_ser = @lb_lot
					      AND bin_no = @lb_bin)
			BEGIN
				UPDATE tdc_soft_alloc_tbl
				   SET qty = @lb_qty
				 WHERE order_no = 0
				   AND order_ext = 0
				   AND order_type = 'S'
				   AND location = @lb_loc
				   AND line_no = 0 
				   AND part_no = @lb_part
				   AND lot_ser = @lb_lot
				   AND bin_no = @lb_bin
			END
			ELSE
			BEGIN
					/* Allocate the inv to move and put an entry on the queue */
				INSERT INTO tdc_soft_alloc_tbl
					(order_type,order_no, order_ext, location, line_no, part_no,
					 lot_ser, bin_no, qty, target_bin, dest_bin, q_priority)
				VALUES ('S', 0, 0, @in_location, 0, @lb_part, 
					@lb_lot, @lb_bin, @lb_qty, @in_bin_no, @in_bin_no, @q_priority)

			   	IF @@ERROR <> 0 
				BEGIN
					IF @@TRANCOUNT > 0 ROLLBACK TRAN
					RAISERROR 84691 'Error Inserting into tdc_soft_alloc_table.'
					RETURN
				END

				EXEC @SeqNo = tdc_queue_get_next_seq_num 'tdc_pick_queue', @Priority 	

				IF (@SeqNo = 0) 
				BEGIN
					IF @@TRANCOUNT > 0 ROLLBACK TRAN
					RAISERROR 84695 'Error Invalid Sequence or Trans Id or Priority .'
					RETURN
				END
	
				INSERT INTO tdc_pick_queue (trans_source, trans, priority, seq_no,
       					location, trans_type_no, trans_type_ext, line_no, part_no, eco_no, lot,qty_to_process, 
       					qty_processed, qty_short,next_op, bin_no, date_time,assign_group, tx_control, tx_lock)
				VALUES ('MGT', 'MGTB2B', @Priority,  @SeqNo, @in_location,  0,  0, 0, 
					@in_part_no, 'Y', @lb_lot, @lb_qty, 0, 0, @in_bin_no, @lb_bin, GETDATE(), @Bin2BinGroupId, 'M', 'R') 

				IF @@ERROR <> 0 
				BEGIN
					IF @@TRANCOUNT > 0 ROLLBACK TRAN
					RAISERROR 84691 'Error Inserting into Pick_queue table.'
					RETURN
				END
			END

			SELECT @qty_to_move = @qty_to_move - @lb_qty	

		END 

		SET @last_id = @id

		SELECT	TOP 1 @id = id,
				@lb_loc = location, 
				@lb_part = part_no, 
				@lb_lot = lot_ser, 
				@lb_bin = bin_no, 
				@lb_qty = qty
		FROM	#temp_replenish
		WHERE	id > @last_id
		ORDER BY id ASC

	END
	
	DELETE tdc_pick_queue WHERE trans = 'MGTB2B' AND bin_no = next_op AND eco_no IS NULL

	DROP TABLE #temp_replenish

	RETURN
END
GO
GRANT EXECUTE ON  [dbo].[CVO_tdc_automatic_highbay_bin_replenish] TO [public]
GO
