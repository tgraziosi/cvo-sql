SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[tdc_plw_wo_soft_alloc_sp]
		@user_id   		   varchar(50),
		@template_code		   varchar(50),
		@passed_in_order_by_clause varchar(255) 
AS

DECLARE @prod_no 	int,
	@prod_ext 	int,
	@rm_part   	varchar(30),
	@lot_ser   	varchar(25),
	@bin_no   	varchar(12),
	@line_no   	int,
	@lb_tracking	char(1),
	@filled_ind	char(1),
	@conv_factor	decimal(20,8),
	@location	varchar(10),
	@PRODIN_Bin   	varchar(12),
	@bin_first   	varchar(12),
	@bin_group   	varchar(12),
	@search_sort	varchar(12),
	@assigned_user  varchar(50),
	@on_hold	char(1),
	@cdock		char(1),
	@alloc_type  	varchar(2)

DECLARE	@in_stock_qty_for_part		decimal(20, 8),
	@alloc_qty_for_part		decimal(20, 8),
	@alloc_qty_for_part_line_no	decimal(20, 8),
	@needed_qty_for_part_line_no	decimal(20, 8),
	@avail_qty_for_part		decimal(20, 8),
	@avail_qty_for_part_line_no	decimal(20, 8),
	@qty_plan_for_part_line_no	decimal(20, 8),
	@qty_used_for_part_line_no	decimal(20, 8),
	@qty_picked_for_part_line_no	decimal(20, 8),
	@qty_picked_for_wo		decimal(20, 8),
	@bin_2_bin_move_qty		decimal(20, 8),
	@swap_qty			decimal(20, 8)

DECLARE	@declare_clause			varchar(500),
	@lb_cursor_clause		varchar(5000),
	@lbs_order_by 			varchar(5000),
	@order_by_value 		char(1),
	@data				varchar(1000),
	@SQL				varchar(1000)

DECLARE @seq_no				int,
	@priority			int

-- Truncate the working temporary tables		
TRUNCATE TABLE #lot_bin_stock
TRUNCATE TABLE #wo_soft_alloc_working_tbl

SET @alloc_type = 'WO'

--------------------------------------------------------------------------------------------------------------
-- Call the unallocate stored procedure and free the inventory that is to be unallocated
--------------------------------------------------------------------------------------------------------------
BEGIN TRAN
	EXEC tdc_plw_wo_unallocate_sp @user_id 
COMMIT TRAN

----------------------------------------------------------------------------------------------------------------------------------
-- Remove any previous cross dock allocations for the orders selected FROM the #wo_alloc_management table to be processed 	--
----------------------------------------------------------------------------------------------------------------------------------
BEGIN TRAN
	DELETE FROM tdc_soft_alloc_tbl
	WHERE EXISTS (SELECT * FROM #wo_alloc_management
		       WHERE tdc_soft_alloc_tbl.order_no   = #wo_alloc_management.prod_no 
			 AND tdc_soft_alloc_tbl.order_ext  = #wo_alloc_management.prod_ext 
			 AND tdc_soft_alloc_tbl.location   = #wo_alloc_management.location 
			 AND tdc_soft_alloc_tbl.lot_ser    = 'CDOCK' 
			 AND tdc_soft_alloc_tbl.bin_no     = 'CDOCK' 
			 AND tdc_soft_alloc_tbl.order_type = 'W'				
			 AND #wo_alloc_management.sel_flg != 0)
	
	DELETE FROM tdc_pick_queue
	WHERE EXISTS (SELECT * FROM #wo_alloc_management
		       WHERE tdc_pick_queue.trans_type_no   	= #wo_alloc_management.prod_no
	 		 AND tdc_pick_queue.trans_type_ext  	= #wo_alloc_management.prod_ext 
			 AND tdc_pick_queue.location   		= #wo_alloc_management.location 
			 AND tdc_pick_queue.lot    		= 'CDOCK' 
			 AND tdc_pick_queue.bin_no    		= 'CDOCK' 
			 AND tdc_pick_queue.trans 		= 'WO-CDOCK'				
			 AND #wo_alloc_management.sel_flg != 0)
	
		DELETE FROM tdc_cdock_mgt
		WHERE EXISTS (SELECT * FROM #wo_alloc_management
			       WHERE tdc_cdock_mgt.tran_no  = CAST(#wo_alloc_management.prod_no AS VARCHAR)
				 AND tdc_cdock_mgt.tran_ext  = CAST(#wo_alloc_management.prod_ext AS VARCHAR)
				 AND tdc_cdock_mgt.location       = #wo_alloc_management.location 
				 AND tdc_cdock_mgt.tran_type          = 'WO-CDOCK'				
				 AND #wo_alloc_management.sel_flg != 0)
COMMIT TRAN

------------------------------------------------------------------------------------------------------------------
-- Now we determine which prod_no gets the inventory first.							--
-- We'll loop through the selected orders with ORDER BY depending on the allocation criteria. 			--
------------------------------------------------------------------------------------------------------------------
SELECT @declare_clause = 'DECLARE selected_orders_cursor CURSOR FOR
			  	SELECT prod_no, prod_ext, location FROM #wo_alloc_management WHERE sel_flg <> 0 ' +
       @passed_in_order_by_clause 

EXEC (@declare_clause)

OPEN selected_orders_cursor
FETCH NEXT FROM selected_orders_cursor INTO @prod_no, @prod_ext, @location

WHILE (@@FETCH_STATUS = 0)
BEGIN	
	------------------------------------------------------------------------------------------
	-- Get the user's settings
	------------------------------------------------------------------------------------------
	SELECT @bin_group     = bin_group,
	       @search_sort   = search_sort,
	       @bin_first     = bin_first,
	       @priority      = tran_priority,
	       @on_hold       = on_hold,
	       @cdock         = cdock,
	       @PRODIN_bin    = pass_bin,
	       @assigned_user = CASE WHEN user_group = '' OR user_group like '%DEFAULT%' 
				     THEN NULL
				     ELSE user_group
				END
	  FROM tdc_plw_process_templates (NOLOCK)
	 WHERE template_code  = @template_code
	   AND UserID         = @user_id
	   AND location       = @location
	   AND order_type     = 'W'
	   AND type           = 'one4one'

	--------------------------------------------------------------------------------------------------------------
	-- Get the bin sort by based on the bin first option and user selected Bin Sort creteria
	--------------------------------------------------------------------------------------------------------------	
	EXEC dbo.tdc_plw_wo_get_bin_sort @search_sort, @bin_first,  @lbs_order_by OUTPUT

	------------------------------------------------------------------------------------------
	-- Get in_stock qty, plan_qty, used_qty for every part_no / seq_no on every prod_no	--
	------------------------------------------------------------------------------------------
	
	------------------------------------------------------------------------------------------------
	--Look to see if we are just allocating by line, if so, we want to remove all other rows from the allocation table
	------------------------------------------------------------------------------------------------
	TRUNCATE TABLE #wo_soft_alloc_working_tbl

	IF EXISTS(SELECT * FROM #wo_soft_alloc_byline_tbl)
	BEGIN
		INSERT INTO #wo_soft_alloc_working_tbl (prod_no, prod_ext, location, line_no, rm_part, lb_tracking, qty_needed, conv_factor)
		SELECT pl.prod_no, pl.prod_ext, pl.location, pl.line_no, pl.part_no, pl.lb_tracking, 0, 1
		  FROM prod_list pl (NOLOCK) 
		 WHERE pl.prod_no  = @prod_no
		   AND pl.prod_ext = @prod_ext
		   AND pl.location = @location 
           AND pl.line_no  > 1
		   AND pl.direction <> 1
		   AND pl.part_type IN ('M','P')
		   AND pl.line_no IN (SELECT line_no FROM #wo_soft_alloc_byline_tbl)
		GROUP BY pl.prod_no, pl.prod_ext, pl.location, pl.line_no, pl.part_no, pl.lb_tracking
	END
	ELSE
	BEGIN
		INSERT INTO #wo_soft_alloc_working_tbl
			   (prod_no, prod_ext, location, line_no, rm_part, lb_tracking, qty_needed, conv_factor)
		SELECT pl.prod_no, pl.prod_ext, pl.location, pl.line_no, pl.part_no, pl.lb_tracking, 0, 1
		  FROM prod_list pl (NOLOCK) 
		 WHERE pl.prod_no  = @prod_no
		   AND pl.prod_ext = @prod_ext
		   AND pl.location = @location 
		   AND pl.line_no  > 1
		   AND pl.direction <> 1
		   AND pl.part_type IN ('M','P')
		GROUP BY pl.prod_no, pl.prod_ext, pl.location, pl.line_no, pl.part_no, pl.lb_tracking
	END

	------------------------------------------------------------------------------------------
	-- Calculate needed qty for every part_no / seq_no on every prod_no			--
	------------------------------------------------------------------------------------------
	DECLARE needed_qty_cursor CURSOR FOR
		SELECT line_no, rm_part 
                  FROM #wo_soft_alloc_working_tbl
		 WHERE prod_no  = @prod_no
                   AND prod_ext = @prod_ext
		   AND location = @location

	OPEN needed_qty_cursor
	FETCH NEXT FROM needed_qty_cursor INTO @line_no, @rm_part
	
	WHILE (@@FETCH_STATUS = 0)
	BEGIN
		-- Get plan_qty and used_qty for the part/seq_no on the order
		SELECT @qty_plan_for_part_line_no = 0
		SELECT @qty_plan_for_part_line_no = plan_qty * conv_factor,
		       @qty_used_for_part_line_no = used_qty * conv_factor,
		       @conv_factor	          = conv_factor
	          FROM prod_list (NOLOCK)
		 WHERE prod_no  = @prod_no
		   AND prod_ext = @prod_ext
		   AND line_no  = @line_no
	 	   AND location = @location
		   AND part_no  = @rm_part

		-- Get allocated qty for the part/seq_no on the order
		SELECT @alloc_qty_for_part_line_no = 0
		SELECT @alloc_qty_for_part_line_no = SUM(qty)
	          FROM tdc_soft_alloc_tbl (NOLOCK)
		 WHERE order_no   = @prod_no
		   AND order_ext  = @prod_ext
		   AND order_type = 'W'
	 	   AND location   = @location
		   AND line_no    = @line_no
		   AND part_no    = @rm_part
	  	 GROUP BY location

		--  Get Picked Qty for the rm_part/line_no on the order
		SELECT @qty_picked_for_part_line_no = 0
		SELECT @qty_picked_for_part_line_no = SUM(pick_qty) 
		  FROM tdc_wo_pick (NOLOCK)
		 WHERE prod_no  = @prod_no
		   AND prod_ext = @prod_ext
		   AND location = @location
		   AND line_no  = @line_no
		   AND part_no  = @rm_part
		 GROUP BY location

		SELECT @needed_qty_for_part_line_no = 0
		SELECT @needed_qty_for_part_line_no = (@qty_plan_for_part_line_no - @qty_used_for_part_line_no) - @alloc_qty_for_part_line_no -
						      (@qty_picked_for_part_line_no - @qty_used_for_part_line_no )
	
		-- Set Allocated and Needed qty
		UPDATE #wo_soft_alloc_working_tbl
		   SET qty_needed  = @needed_qty_for_part_line_no,
		       conv_factor = @conv_factor
		 WHERE prod_no     = @prod_no
		   AND prod_ext    = @prod_ext
	 	   AND location    = @location
		   AND rm_part     = @rm_part
		   AND line_no     = @line_no
		
		FETCH NEXT FROM needed_qty_cursor INTO @line_no, @rm_part
	END
	
	CLOSE	   needed_qty_cursor
	DEALLOCATE needed_qty_cursor
	
	
	
	TRUNCATE TABLE #lot_bin_stock
	

	----------------------------------------------------------------------------------------------------------
	-- Get available LOTs and BINs (type: OPEN or REPLENISH) for every part on all the selected orders.	--
	----------------------------------------------------------------------------------------------------------
	SET @SQL = 
		'INSERT INTO #lot_bin_stock (location, rm_part, lot_ser, bin_no, avail_qty, warning)
		 SELECT DISTINCT lb.location, lb.part_no, lb.lot_ser, lb.bin_no, 0, NULL
		   FROM lot_bin_stock              lb (NOLOCK), 
		        tdc_bin_master             bm (NOLOCK), 
		        #wo_soft_alloc_working_tbl wo
		  WHERE lb.location = wo.location 
		    AND lb.part_no  = wo.rm_part  
		    AND lb.bin_no   = bm.bin_no
		    AND lb.location = bm.location
		    AND lb.location = ''' + @location + '''' +
		  ' AND bm.usage_type_code IN (''OPEN'', ''REPLENISH'')'
	
	IF ISNULL(@bin_group, '[ALL]') <> '[ALL]'
	BEGIN
		SET @SQL = @SQL + ' AND bm.group_code = ''' + @bin_group + ''''
	END
	
	EXEC (@SQL)

	------------------------------------------------------------------------------------------
	-- Get available qty for every part / location /lot /bin for all the selected orders.	--
	------------------------------------------------------------------------------------------
	DECLARE lb_quantities_cursor CURSOR FOR
		SELECT rm_part, lot_ser, bin_no FROM #lot_bin_stock 
		
	OPEN lb_quantities_cursor
	FETCH NEXT FROM lb_quantities_cursor INTO @rm_part, @lot_ser, @bin_no

	WHILE (@@FETCH_STATUS = 0)
	BEGIN		
		-- Get in stock qty for the part/location/lot/bin.
		SELECT @in_stock_qty_for_part = 0
		SELECT @in_stock_qty_for_part = SUM(qty)
	          FROM lot_bin_stock (NOLOCK)
		 WHERE location  = @location
		   AND part_no   = @rm_part
		   AND bin_no    = @bin_no
		   AND lot_ser   = @lot_ser
		 GROUP BY location

		-- Get total allocated qty for the part/location/lot/bin regardless order numbers.
		SELECT @alloc_qty_for_part = 0
		SELECT @alloc_qty_for_part = SUM(qty)
	          FROM tdc_soft_alloc_tbl (NOLOCK)
		 WHERE location  = @location
		   AND part_no   = @rm_part
		   AND lot_ser   = @lot_ser
		   AND bin_no    = @bin_no
		 GROUP BY location
	
		-- Get inventory for this part/location/lot/bin that a warehouse manager requested a bin-to-bin move on.
		SELECT @bin_2_bin_move_qty = 0
		SELECT @bin_2_bin_move_qty =  SUM(qty_to_process)
		  FROM tdc_pick_queue (NOLOCK)
		 WHERE location = @location 
		   AND part_no  = @rm_part 
		   AND lot      = @lot_ser 
		   AND bin_no   = @bin_no 
		   AND trans    = 'MGTBIN2BIN'
		 GROUP BY location

		------------------------------------------------------------------------------------------------------------------
		-- Calculate available qty for the part on LOT/BIN.								--
		------------------------------------------------------------------------------------------------------------------
		UPDATE #lot_bin_stock
	  	   SET avail_qty = ISNULL((@in_stock_qty_for_part - @alloc_qty_for_part - @bin_2_bin_move_qty), 0)
		 WHERE location  = @location
		   AND rm_part   = @rm_part
		   AND lot_ser   = @lot_ser
		   AND bin_no    = @bin_no
	
		------------------------------------------------------------------------------------------------------------------
		-- This warning will be displaied from the VB app:								--
		-- Warning, Bin: ' + @lb_bin + ' bypassed for this allocation by bin to bin queue trans!
		------------------------------------------------------------------------------------------------------------------
		IF @bin_2_bin_move_qty > 0
		BEGIN
			UPDATE #lot_bin_stock
		  	   SET warning = 'Y'
			 WHERE location  = @location
			   AND rm_part   = @rm_part
			   AND lot_ser   = @lot_ser
			   AND bin_no    = @bin_no	
		END

		FETCH NEXT FROM lb_quantities_cursor INTO @rm_part, @lot_ser, @bin_no
	END
	
	CLOSE	   lb_quantities_cursor
	DEALLOCATE lb_quantities_cursor

	-------------------------------------------------------------------------------------------------------------------------------
	-- We'll loop through the parts on the order and determine from wich BIN we'll get inventory first based on the conifg flags --
	------------------------------------------------------------------------------------------------------------------------------- 
	DECLARE parts_on_order_cursor CURSOR FOR
		SELECT line_no, rm_part, lb_tracking, qty_needed, conv_factor
		  FROM #wo_soft_alloc_working_tbl
	         WHERE prod_no  = @prod_no
		   AND prod_ext = @prod_ext
		   AND location = @location

	OPEN parts_on_order_cursor
	FETCH NEXT FROM parts_on_order_cursor INTO @line_no, @rm_part, @lb_tracking, @needed_qty_for_part_line_no, @conv_factor
	
	WHILE (@@FETCH_STATUS = 0)
	BEGIN
		IF @needed_qty_for_part_line_no = 0
		BEGIN
			FETCH NEXT FROM parts_on_order_cursor INTO @line_no, @rm_part, @lb_tracking, @needed_qty_for_part_line_no, @conv_factor
			CONTINUE
		END

		SET @data = 'Line: ' + CAST(@line_no as varchar(3)) + '; Order Type: W '

		IF (@lb_tracking = 'Y')
		BEGIN
			----------------------------------------------------------------------------------------------------------
			-- 	Now we'll loop through the LOTs/BINs and do the allocation. 					--
			---------------------------------------------------------------------------------------------------------- 

			-- Declare cursor as a string so we can dynamically change ORDER BY clause
			SELECT @lb_cursor_clause = 'DECLARE lots_bins_cursor CURSOR FOR
							    SELECT tlb.lot_ser, tlb.bin_no, avail_qty 
			  				      FROM lot_bin_stock lb (NOLOCK), #lot_bin_stock tlb, tdc_bin_master bm (NOLOCK)
							     WHERE lb.location  = tlb.location
							       AND lb.part_no   = tlb.rm_part
							       AND lb.bin_no    = tlb.bin_no
							       AND lb.lot_ser   = tlb.lot_ser
			            			       AND avail_qty > 0
	 		          			       AND lb.location  = bm.location
			            			       AND lb.bin_no    = bm.bin_no
							       AND tlb.rm_part  = ' + CHAR(39) + @rm_part  + CHAR(39) +
							     ' AND tlb.location = ' + CHAR(39) + @location + CHAR(39) + 
						    @lbs_order_by
			EXEC (@lb_cursor_clause)

			OPEN lots_bins_cursor
			FETCH NEXT FROM lots_bins_cursor INTO @lot_ser, @bin_no, @avail_qty_for_part_line_no 

			-- This indicator will become 'Y' when we allocated a part
			SELECT @filled_ind = 'N' 

			WHILE (@@FETCH_STATUS = 0 AND @filled_ind = 'N')
			BEGIN
				BEGIN TRAN

				SELECT @swap_qty = 0

				IF (@avail_qty_for_part_line_no >= @needed_qty_for_part_line_no)
				BEGIN
					IF @conv_factor <> 1
						SELECT @swap_qty = FLOOR(@needed_qty_for_part_line_no / @conv_factor) * @conv_factor
					ELSE
						SELECT @swap_qty = @needed_qty_for_part_line_no

					IF(@swap_qty > 0)
					BEGIN
						IF EXISTS (SELECT * FROM tdc_soft_alloc_tbl (NOLOCK)
							    WHERE order_no   = @prod_no 
							      AND order_ext  = @prod_ext  
							      AND order_type = 'W'
							      AND location   = @location 
							      AND line_no    = @line_no
							      AND part_no    = @rm_part 
							      AND lot_ser    = @lot_ser 
							      AND bin_no     = @bin_no)
						BEGIN
							UPDATE tdc_soft_alloc_tbl
							   SET qty           = qty  + @swap_qty,
							       dest_bin      = @PRODIN_Bin,
							       q_priority    = @priority,
							       assigned_user = @assigned_user,
							       user_hold     = @on_hold,
							       alloc_type    = @alloc_type
						         WHERE order_no      = @prod_no 
						           AND order_ext     = @prod_ext  
						           AND order_type    = 'W'
						           AND location      = @location 
						           AND line_no       = @line_no
						           AND part_no       = @rm_part 
						           AND lot_ser       = @lot_ser 
						           AND bin_no        = @bin_no
						END
						ELSE
						BEGIN
							INSERT INTO tdc_soft_alloc_tbl(order_no, order_ext, location, line_no, part_no, lot_ser, bin_no, qty,   
										       order_type, target_bin, dest_bin, alloc_type, q_priority, assigned_user, user_hold)
							VALUES 	(@prod_no, @prod_ext, @location, @line_no, @rm_part, @lot_ser, @bin_no, @swap_qty, 
								 'W', @bin_no, @PRODIN_Bin, @alloc_type, @priority, @assigned_user, @on_hold)
						END 	
		
						INSERT INTO tdc_log (tran_date, UserID, trans_source, module, trans, tran_no, tran_ext, part_no, lot_ser, bin_no, location, quantity, data)
						VALUES(GETDATE(), @user_id, 'VB', 'PLW', 'ALLOCATION', @prod_no, @prod_ext, @rm_part, @lot_ser, @bin_no, @location, @swap_qty, @data)

						SELECT @filled_ind = 'Y'
					END
				END  
				ELSE				
				IF (@avail_qty_for_part_line_no > 0)-- is there at least some items that could be picked FROM this bin 
				BEGIN
					IF @conv_factor <> 1
						SELECT @swap_qty = FLOOR(@avail_qty_for_part_line_no / @conv_factor) * @conv_factor
					ELSE	
						SELECT @swap_qty = @avail_qty_for_part_line_no
	
					IF(@swap_qty > 0)
					BEGIN
						IF EXISTS (SELECT * FROM tdc_soft_alloc_tbl (NOLOCK)
							    WHERE order_no   = @prod_no 
							      AND order_ext  = @prod_ext 
							      AND order_type = 'W' 
							      AND location   = @location 
							      AND line_no    = @line_no
							      AND part_no    = @rm_part 
							      AND lot_ser    = @lot_ser 
							      AND bin_no     = @bin_no)
						BEGIN
							UPDATE tdc_soft_alloc_tbl
							   SET qty           = qty  + @swap_qty,
							       dest_bin      = @PRODIN_Bin,
							       q_priority    = @priority,
							       assigned_user = @assigned_user,
							       user_hold     = @on_hold,
							       alloc_type    = @alloc_type
						         WHERE order_no      = @prod_no 
						           AND order_ext     = @prod_ext  
						           AND order_type    = 'W'
						           AND location      = @location 
						           AND line_no       = @line_no
						           AND part_no       = @rm_part 
						           AND lot_ser       = @lot_ser 
						           AND bin_no        = @bin_no
						END
						ELSE
						BEGIN
							INSERT INTO tdc_soft_alloc_tbl(order_no, order_ext, location, line_no, part_no,lot_ser, bin_no, qty,  
										       order_type, target_bin, dest_bin, alloc_type, q_priority, assigned_user, user_hold)
							VALUES 	(@prod_no, @prod_ext, @location, @line_no, @rm_part, @lot_ser, @bin_no, 
								 @swap_qty, 'W', @bin_no, @PRODIN_Bin, @alloc_type, @priority, @assigned_user, @on_hold)
						END 	
	
						INSERT INTO tdc_log (tran_date, UserID, trans_source, module, trans, tran_no, tran_ext, part_no, lot_ser, bin_no, location, quantity, data)
						VALUES(GETDATE(), @user_id, 'VB', 'PLW', 'ALLOCATION', @prod_no, @prod_ext, @rm_part, @lot_ser, @bin_no, @location, @swap_qty, @data)

						-- Decrement needed qty by what has been allocated 
						SELECT @needed_qty_for_part_line_no = @needed_qty_for_part_line_no - @swap_qty	
					END
				END -- IF (@avail_qty_for_part_line_no > 0)

				-- Decrement available qty by what has been allocated 
				UPDATE #lot_bin_stock 
				   SET avail_qty = avail_qty - @swap_qty
				 WHERE location  = @location
				   AND rm_part   = @rm_part
				   AND lot_ser   = @lot_ser
				   AND bin_no    = @bin_no

				DELETE FROM #lot_bin_stock 
				 WHERE location  = @location
				   AND rm_part   = @rm_part
				   AND lot_ser   = @lot_ser
				   AND bin_no    = @bin_no
				   AND avail_qty = 0

				COMMIT TRAN

				FETCH NEXT FROM lots_bins_cursor INTO @lot_ser, @bin_no, @avail_qty_for_part_line_no 
			END

			CLOSE	   lots_bins_cursor
			DEALLOCATE lots_bins_cursor

			IF (@filled_ind = 'N' AND @cdock = 'Y')
			BEGIN
				IF @conv_factor <> 1
					SELECT @swap_qty = FLOOR(@needed_qty_for_part_line_no / @conv_factor) * @conv_factor
				ELSE
					SELECT @swap_qty = @needed_qty_for_part_line_no 

				BEGIN TRAN

				INSERT INTO tdc_soft_alloc_tbl(order_no, order_ext, location, line_no, part_no,lot_ser, bin_no, qty,  
							       order_type, target_bin, dest_bin, alloc_type, q_priority, assigned_user, user_hold)
				VALUES 	(@prod_no, @prod_ext, @location, @line_no, @rm_part, 'CDOCK', 'CDOCK', 
					 @swap_qty, 'W', NULL, @prodin_bin, @alloc_type, @priority, @assigned_user, @on_hold)

				EXEC  @seq_no = tdc_queue_get_next_seq_num 'tdc_pick_queue', @priority

				INSERT INTO tdc_pick_queue (trans_source, trans,  priority,  seq_no, company_no, location, warehouse_no, trans_type_no, trans_type_ext, 
							    tran_receipt_no, line_no, pcsn, part_no, eco_no, lot, mfg_lot, mfg_batch, serial_no, bin_no, qty_to_process, 
							    qty_processed, qty_short, next_op, tran_id_link, date_time, assign_group, assign_user_id, [user_id], status, tx_status, tx_control, tx_lock)
				VALUES ('PLW', 'WO-CDOCK', @priority, @seq_no, NULL, @location, NULL, @prod_no, @prod_ext, NULL, @line_no, NULL, @rm_part, NULL, 'CDOCK', NULL, NULL, NULL, 'CDOCK',
					@swap_qty, 0, 0, NULL, NULL, GETDATE(), NULL, NULL, NULL, NULL, NULL, 'M', 'V')

				INSERT INTO tdc_log (tran_date, UserID, trans_source, module, trans, tran_no, tran_ext, part_no, lot_ser, bin_no, location, quantity, data)
				VALUES(GETDATE(), @user_id, 'VB', 'PLW', 'ALLOCATION', @prod_no, @prod_ext, @rm_part, 'CDOCK', 'CDOCK', @location, @swap_qty, @data)
				
				COMMIT TRAN
			END
		END
		ELSE -- @lb_tracking = 'N'
		BEGIN
			--Get all inv that has been prev allocated for this loc/part 
			SELECT @alloc_qty_for_part = 0
			SELECT @alloc_qty_for_part = SUM(qty)
			  FROM tdc_soft_alloc_tbl (NOLOCK)
			 WHERE location = @location
			   AND part_no  = @rm_part
			GROUP BY location, part_no

			-- Get picked qty for all the WOs
			SELECT @qty_picked_for_wo = 0
			SELECT @qty_picked_for_wo = SUM(pick_qty) - SUM(used_qty)
  			  FROM tdc_wo_pick (NOLOCK)
			 WHERE part_no  = @rm_part 
			   AND location = @location
			 GROUP BY location

			-- Get available qty = total amount of inventory in stock minus what has been allocated 
			SELECT @avail_qty_for_part = 0
			SELECT @avail_qty_for_part = in_stock - @qty_picked_for_wo - @alloc_qty_for_part
			  FROM inventory (NOLOCK)
			 WHERE location = @location
			   AND part_no  = @rm_part

			/* determine IF we have enough quantity to allocate and set a common update variable */
			IF (@avail_qty_for_part >= @needed_qty_for_part_line_no)
			BEGIN
				IF @conv_factor <> 1
					SELECT @swap_qty = FLOOR(@needed_qty_for_part_line_no / @conv_factor) * @conv_factor
				ELSE
					SELECT @swap_qty = @needed_qty_for_part_line_no 
			END
			ELSE
			BEGIN
				IF @conv_factor <> 1
					SELECT @swap_qty = FLOOR(@avail_qty_for_part / @conv_factor) * @conv_factor
				ELSE
					SELECT @swap_qty = @avail_qty_for_part
			END

			IF(@swap_qty > 0)
			BEGIN
				BEGIN TRAN

				IF EXISTS (SELECT * FROM tdc_soft_alloc_tbl (NOLOCK)
					    WHERE order_no  = @prod_no
					      AND order_ext = @prod_ext 
					      AND order_type = 'W'
					      AND location  = @location 
					      AND line_no   = @line_no 
					      AND part_no   = @rm_part)
				BEGIN
					UPDATE tdc_soft_alloc_tbl
					   SET qty           = qty  + @swap_qty,
					       dest_bin      = @PRODIN_Bin,
					       q_priority    = @priority,
					       assigned_user = @assigned_user,
					       user_hold     = @on_hold,
					       alloc_type    = @alloc_type
				         WHERE order_no      = @prod_no 
				           AND order_ext     = @prod_ext  
				           AND order_type    = 'W'
				           AND location      = @location 
				           AND line_no       = @line_no
				           AND part_no       = @rm_part 
				END
				ELSE
				BEGIN
					INSERT INTO tdc_soft_alloc_tbl(order_no, order_ext, location, line_no, part_no,lot_ser, bin_no, qty,  
								       order_type, target_bin, dest_bin, alloc_type, q_priority, assigned_user, user_hold)
					VALUES 	(@prod_no, @prod_ext, @location, @line_no, @rm_part, 
						 NULL, NULL, @swap_qty, 'W', NULL, @PRODIN_Bin, @alloc_type, @priority, @assigned_user, @on_hold)
				END

				INSERT INTO tdc_log (tran_date, UserID, trans_source, module, trans, tran_no, tran_ext, part_no, lot_ser, bin_no, location, quantity, data)
				VALUES(GETDATE(), @user_id, 'VB', 'PLW', 'ALLOCATION', @prod_no, @prod_ext, @rm_part, NULL, NULL, @location, @swap_qty, @data)

				COMMIT TRAN
			END
		END -- @lb_tracking = 'N'

		FETCH NEXT FROM parts_on_order_cursor INTO @line_no, @rm_part, @lb_tracking, @needed_qty_for_part_line_no, @conv_factor
	END

	CLOSE	   parts_on_order_cursor
	DEALLOCATE parts_on_order_cursor

	FETCH NEXT FROM selected_orders_cursor INTO @prod_no, @prod_ext, @location
END

CLOSE	   selected_orders_cursor
DEALLOCATE selected_orders_cursor


------------------------------------------------------------------------------------------
-- 			Insert a new record into the history table			--
------------------------------------------------------------------------------------------
DELETE FROM tdc_alloc_history_tbl FROM #wo_alloc_management 
 WHERE order_no   = prod_no
   AND order_ext  = prod_ext 
   AND order_type = 'W'
   AND tdc_alloc_history_tbl.location = #wo_alloc_management.location 
   AND sel_flg   != 0

INSERT INTO tdc_alloc_history_tbl(order_no, order_ext, location, fill_pct, alloc_date, alloc_by, order_type)
SELECT prod_no, prod_ext, location, curr_alloc_pct, getdate(), @user_id, 'W'
  FROM #wo_alloc_management WHERE sel_flg != 0

 
TRUNCATE TABLE #wo_soft_alloc_working_tbl

RETURN
GO
GRANT EXECUTE ON  [dbo].[tdc_plw_wo_soft_alloc_sp] TO [public]
GO
