SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[tdc_batch_work_order_commit_sp]
AS

	DECLARE @prod_no int, 
		@employee_code varchar(10), 
		@shift int, 
		@userid varchar(50), 
		@lot varchar(25), -- output lot
		@in_bin varchar(12), 
		@out_bin varchar(12), 
		@produce_qty decimal(20, 8)
	
	DECLARE	@order_plan_qty decimal(20, 8),
		@order_qty 	decimal(20, 8),
		@plan_qty 	decimal(20, 8),
		@qty 	  	decimal(20, 8),
		@consumed_qty	decimal(20, 8),
		@prod_qty	decimal(20, 8),
		@diff_qty 	decimal(20, 8),
		@allow_fraction smallint

	DECLARE @desc		varchar(255),
		@lot_ser	varchar(25),	
		@seq_no 	varchar(30),
		@item 		varchar(30),
		@batch_item 	varchar(30),
		@batch_lot 	varchar(25),
		@location 	varchar(10),
		@upc_code	varchar(20),
		@lb_tracking 	varchar(1),
		@tdclog 	varchar(1),
		@uom		varchar(2),
		@data		varchar(1000),
		@percube_reg	char(1),
		@bincube_reg	char(1)

	DECLARE @status 	int,
		@line		int,
		@Q_tran_id	int,
		@row_id		int

	SET @Q_tran_id = 0
	SELECT @row_id = 0

	SELECT 	@prod_no = prod_no, @employee_code = rtrim(employee_code), @shift = shift, @userid = userid, 
		@lot = lot, @in_bin = in_bin, @out_bin = out_bin, @percube_reg = percube_reg, @bincube_reg = bincube_reg
	  FROM #batch_work_commit
	 WHERE row_id = 1

	SELECT @produce_qty = sum(produce_qty) FROM #batch_work_commit

	TRUNCATE TABLE #prod_use_temp
	TRUNCATE TABLE #batch_parts

	SET @tdclog = 'N'
	IF EXISTS (SELECT * FROM tdc_config (nolock) WHERE [function] = 'log_all_users' AND active = 'Y')
		SELECT @tdclog = 'Y'
	ELSE IF EXISTS (SELECT * FROM tdc_sec (nolock) WHERE UserID = @userid AND Log_User = 'Y')
		SELECT @tdclog = 'Y'

	SELECT @order_plan_qty = qty_scheduled, @order_qty = qty, @location = location, @item = part_no 
	  FROM produce (nolock) 
	 WHERE prod_no = @prod_no AND prod_ext = 0

	DECLARE each_usage_cursor CURSOR FOR 
		SELECT seq_no, part_no, plan_qty, lb_tracking, line_no
		  FROM prod_list
		 WHERE prod_no = @prod_no 
		   AND prod_ext = 0
		   AND direction = -1 
		   AND plan_qty > 0
		   AND part_type NOT IN ('X', 'R')
		   AND NOT EXISTS ( SELECT * FROM inv_master (nolock) WHERE inv_master.status = 'V' AND inv_master.part_no = prod_list.part_no )

	OPEN each_usage_cursor
	
	FETCH NEXT FROM each_usage_cursor INTO @seq_no, @batch_item, @plan_qty, @lb_tracking, @line
	
	WHILE @@FETCH_STATUS = 0
	BEGIN
		-- Consumption
		TRUNCATE TABLE #prod_use_temp
		
		SELECT @consumed_qty = @produce_qty * (@plan_qty / @order_plan_qty)

		-- check if part allows fractions
		SELECT @allow_fraction = allow_fractions, @desc = [description], @upc_code = upc_code, @uom = uom 
		  FROM inv_master (nolock) 
		 WHERE part_no = @batch_item
		
		EXEC tdc_parse_string_sp @desc, @desc OUT			

		IF(@allow_fraction = 0)
			SELECT @consumed_qty = FLOOR(@consumed_qty)
	--	ELSE
	--		SELECT @consumed_qty = ROUND(@consumed_qty, 2)

		IF(@lb_tracking = 'Y')
		BEGIN
			TRUNCATE TABLE #tdc_wo_pick

			INSERT INTO #tdc_wo_pick (diff_qty, lot_ser)
			SELECT (wo.pick_qty - wo.used_qty) AS diff_qty, pt.lot_ser AS lot_ser
			  FROM tdc_wo_pick wo, #consume_parts pt
			 WHERE wo.prod_no = @prod_no 
			   AND wo.part_no = @batch_item
			   AND wo.line_no= @line
			   AND wo.dest_bin = @in_bin 
			   AND ((wo.pick_qty - wo.used_qty) > 0)
			   AND wo.part_no = pt.part_no
			   AND wo.lot_ser = pt.lot_ser
			   AND pt.prompt = 'Y'

			SELECT @prod_qty = @consumed_qty

			DECLARE multiple_lot_cursor CURSOR FOR
				SELECT diff_qty, lot_ser
				  FROM #tdc_wo_pick
			OPEN multiple_lot_cursor
			FETCH NEXT FROM multiple_lot_cursor INTO @diff_qty, @lot_ser
			
			WHILE @@FETCH_STATUS = 0
			BEGIN
				IF(@allow_fraction = 0)
					SELECT @diff_qty = FLOOR(@diff_qty)
			--	ELSE
			--		SELECT @diff_qty = ROUND(@diff_qty, 2)
	
				IF(@prod_qty <= @diff_qty)
				BEGIN
					SELECT @diff_qty = @prod_qty
					SELECT @prod_qty = 0
				END
				ELSE
				BEGIN
					SELECT @prod_qty = @prod_qty - @diff_qty
				END

				SELECT @qty = qty
				  FROM lot_bin_stock
				 WHERE location = @location 
				   AND part_no = @batch_item 
				   AND lot_ser = @lot_ser 
				   AND bin_no = @in_bin

				IF(@qty < @diff_qty) 
				BEGIN
					DEALLOCATE multiple_lot_cursor
					DEALLOCATE each_usage_cursor
		
					RAISERROR('There is not enough of item %s in stock', 16, -1, @batch_item)
					RETURN -102
				END

				UPDATE tdc_wo_pick
				   SET used_qty = used_qty + @diff_qty
				 WHERE prod_no = @prod_no
				   AND part_no = @batch_item
				   AND line_no= @line
				   AND dest_bin = @in_bin
				   AND lot_ser = @lot_ser
							
				IF EXISTS ( SELECT * FROM tdc_inv_list (nolock) WHERE location = @location AND part_no = @batch_item AND wo_batch_track = 1 )
				BEGIN
					INSERT INTO tdc_wo_batch_track (prod_no, prod_ext, output_part, output_lot, input_part, input_lot, batch_status, userid)
								VALUES(@prod_no, 0, @item, @lot, @batch_item, @lot_ser, 'P', @userid)
				END

				INSERT INTO #prod_use_temp (employee_key, prod_no, prod_ext, seq_no, part_no, project_key, tran_date, plan_qty,	used_qty, plan_pcs, pieces, shift, who_entered, note, scrap_pcs, lot_ser, bin_no, err_msg, c_status)
						    VALUES (@employee_code, @prod_no, 0, @seq_no, @batch_item, NULL, getdate(), @plan_qty, @diff_qty, 0, 0, @shift, @userid, '', 0, @lot_ser, @in_bin, NULL, '') 
				INSERT INTO #batch_parts VALUES(@batch_item, @desc, @lot_ser, @diff_qty)

				IF(@prod_qty <= 0) BREAK
			
				FETCH NEXT FROM multiple_lot_cursor INTO @diff_qty, @lot_ser
			END
			
			DEALLOCATE multiple_lot_cursor

			IF(@prod_qty > 0)
			BEGIN
				DEALLOCATE each_usage_cursor
				RAISERROR('There is not enough of item %s in production input bin', 16, -1, @batch_item)
				RETURN -101
			END
		END
		ELSE
		BEGIN
			SELECT @qty = in_stock
			  FROM inventory
			 WHERE location = @location 
			   AND part_no = @batch_item

			IF(@qty < @consumed_qty) 
			BEGIN
				DEALLOCATE each_usage_cursor
				RAISERROR('There is not enough of item %s in stock', 16, -1, @batch_item)
				RETURN -102
			END

			UPDATE tdc_wo_pick
			   SET used_qty = used_qty + @consumed_qty 
			 WHERE prod_no = @prod_no 
			   AND line_no= @line
			   AND part_no = @batch_item

			INSERT INTO #prod_use_temp (employee_key, prod_no, prod_ext, seq_no, part_no, project_key, tran_date, plan_qty,	used_qty, plan_pcs, pieces, shift, who_entered, note, scrap_pcs, c_status)
					    VALUES (@employee_code, @prod_no, 0, @seq_no, @batch_item, NULL, getdate(), @plan_qty, @consumed_qty, 0, 0, @shift, @userid, '', 0, '')
			INSERT INTO #batch_parts VALUES(@batch_item, @desc, NULL, @consumed_qty)
		END

		IF((@lb_tracking = 'Y') AND (@bincube_reg = 'Y'))
		BEGIN
			INSERT INTO dbo.tdc_ei_bin_log (module, trans, tran_no, tran_ext, location, part_no, from_bin, userid, direction, quantity)
							VALUES('BMF', 'BATKIT', @prod_no, 0, @location, @batch_item, @in_bin, @userid, -1, @consumed_qty)
		END

		EXEC @status = tdc_bc_prod_use
		
		IF (@status < 0)
		BEGIN
			DEALLOCATE each_usage_cursor
			RETURN -103
		END	

		-- Writing into tdc_log	
		IF (@tdclog = 'Y')
		BEGIN
			SELECT @data = 'LP_PROD_SEQ_NO: ' + ISNULL(@seq_no, '') 
			SELECT @data = @data + '. LP_ITEM_DESC: ' + ISNULL(@desc, '') 
			SELECT @data = @data + '. LP_ITEM_UPC: ' + ISNULL(@upc_code, '')
			SELECT @data = @data + '. LP_ITEM_UOM: ' + ISNULL(@uom, '')
			SELECT @data = @data + '. LP_LB_TRACKING: ' + ISNULL(@lb_tracking, '')

			INSERT INTO tdc_log (tran_date, UserID, trans_source, module, trans, tran_no, tran_ext, part_no, lot_ser, bin_no, location, quantity, data) 
				SELECT getdate(), @userid, 'CO', 'BMF', 'USAGE', @prod_no, 0, @batch_item, lot, @in_bin, @location, qty, @data
				  FROM #batch_parts 
				 WHERE item = @batch_item
		END

		-- Get the next usage.
		FETCH NEXT FROM each_usage_cursor INTO @seq_no, @batch_item, @plan_qty, @lb_tracking, @line
	END

	DEALLOCATE each_usage_cursor

/************************  produce output ****************************************/

	-- Output
	TRUNCATE TABLE #prod_use_temp

	INSERT INTO #prod_use_temp 
	(employee_key, prod_no, prod_ext, seq_no, part_no, project_key, tran_date, plan_qty, used_qty, plan_pcs, pieces, shift, who_entered, note, scrap_pcs, lot_ser, bin_no, err_msg, c_status)
	SELECT @employee_code, @prod_no, 0, '', @item, NULL, getdate(), 0, produce_qty, 0, produce_qty, @shift, @userid, '', 0, lot, @out_bin, NULL, ''
	  FROM #batch_work_commit

	IF((@out_bin IS NOT NULL) AND (@bincube_reg = 'Y'))
	BEGIN
		INSERT INTO dbo.tdc_ei_bin_log (module, trans, tran_no, tran_ext, location, part_no, to_bin, userid, direction, quantity)
					VALUES('BMF', 'BATKIT', @prod_no, 0, @location, @item, @out_bin, @userid, 1, @produce_qty)
	END

	EXEC @status = tdc_prod_output 
	
	IF (@status < 0)
	BEGIN		
		RETURN -104
	END

	WHILE(@row_id >= 0)
	BEGIN
		SELECT @row_id = ISNULL((SELECT min(row_id)
					   FROM #batch_work_commit
					  WHERE row_id > @row_id), -1)
		IF @row_id = -1 BREAK

		SELECT @produce_qty = produce_qty, @lot = lot
		  FROM #batch_work_commit
		 WHERE row_id = @row_id

		SELECT @line = (SELECT top 1 line_no
				  FROM lot_bin_prod (nolock)
				 WHERE tran_no = @prod_no 
				   AND tran_ext = 0 
				   AND part_no = @item
				   AND lot_ser = @lot
				ORDER BY line_no DESC)

		EXEC @Q_tran_id = tdc_queue_wo_putaway_sp @prod_no, 0, @item, @out_bin, @produce_qty, @lot, @line
	END

RETURN @Q_tran_id
GO
GRANT EXECUTE ON  [dbo].[tdc_batch_work_order_commit_sp] TO [public]
GO
