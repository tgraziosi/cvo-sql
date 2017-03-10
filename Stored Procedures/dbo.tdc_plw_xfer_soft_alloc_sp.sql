SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- v1.0 CB 25/07/2012 - Add ship complete hold to transfer
-- v1.1 CT 12/11/2012 - Use fence qty when selecting bins
-- v1.2 CT 13/11/2012 - Call routine to update autoship table for autoship transfers
-- v1.3 CT 14/11/2012 - If we are auto-allocating, don't include excluded bins
-- v1.4 CT 29/11/2012 - Call routine to update autopack table for autopack transfers
-- v1.5 CT 11/06/2013 - If this is called by the Backorder Processing job, then only allocate the relevant lines/qtys
-- v1.6 CB 26/08/2016 - Sort order wrong way around
-- v1.7 CB 03/02/2017 - Remove v1.6
  
CREATE PROCEDURE [dbo].[tdc_plw_xfer_soft_alloc_sp]  
  @user_id        varchar(50),  
  @template_code     varchar(50),  
  @passed_in_order_by_clause varchar(255)   
AS  
BEGIN  
	DECLARE @xfer_no    int,  
			@from_loc   varchar(10),  
			@part_no      varchar(30),  
			@lot_ser      varchar(25),  
			@bin_no      varchar(12),  
			@pass_bin      varchar(12),  
			@line_no      int,  
			@lb_tracking   char(1),  
			@filled_ind   char(1),  
			@conv_factor   decimal(20, 8),  
			@data    varchar(1000),  
			@SQL    varchar(5000),  
			@bin_first      varchar(12),  
			@bin_group      varchar(12),  
			@search_sort   varchar(12),  
			@assigned_user    varchar(50),  
			@on_hold   char(1),  
			@cdock    char(1),  
			@alloc_type     varchar(2)  
	  
	DECLARE @in_stock_qty_for_part  decimal(20, 8),  
			@alloc_qty_for_part  decimal(20, 8),  
			@alloc_qty_for_part_line_no decimal(20, 8),  
			@needed_qty_for_part_line_no decimal(20, 8),  
			@avail_qty_for_part  decimal(20, 8),  
			@avail_qty_for_part_line_no decimal(20, 8),  
			@qty_ordered_for_part_line_no decimal(20, 8),  
			@qty_picked_for_part_line_no decimal(20, 8),  
			@bin_2_bin_move_qty  decimal(20, 8),  
			@swap_qty   decimal(20, 8)  
	  
	DECLARE @declare_clause   varchar(500),  
			@lb_cursor_clause  varchar(1000),  
			@lbs_order_by   varchar(1000),  
			@order_by_value   char(1)  

	DECLARE @seq_no    int,  
			@q_priority   int,
			@bop		SMALLINT, -- v1.5
			@qty		DECIMAL(20,8) -- v1.5

	-- START v1.1
	DECLARE @ALLOC_QTY_FENCE_QTY INT,
			@bulk_bin_group VARCHAR(12), 
			@high_bays_bin_group VARCHAR(12),
			@xfer_order_by	VARCHAR(1000)

	SELECT @ALLOC_QTY_FENCE_QTY = value_str FROM tdc_config (NOLOCK) WHERE [function] = 'ALLOC_QTY_FENCE'
	SELECT @bulk_bin_group		= value_str FROM tdc_config (NOLOCK) WHERE [function] = 'bulk_bin_group'
	SELECT @high_bays_bin_group	= value_str FROM tdc_config (NOLOCK) WHERE [function] = 'hight_bays_bin_group'

	-- Create temporary table for bin groups
	CREATE TABLE #xfer_bin_type (
		location	VARCHAR(10) NOT NULL,
		bin_no		VARCHAR(12)	NOT NULL,
		bin_group	VARCHAR(30)	NOT NULL,
		bin_sort	SMALLINT) -- 1 = Highbay, 2 = Bulk, 3 = Forward Pick
	-- END v1.1
	  
	-- Truncate the working temporary tables    
	TRUNCATE TABLE #xfer_lb_stock  
	TRUNCATE TABLE #xfer_soft_alloc_working_tbl 
	TRUNCATE TABLE #xfer_bin_type	-- v1.1
	  
	SET @alloc_type = 'XF'  
	  
	--------------------------------------------------------------------------------------------------------------  
	-- Call the unallocate stored procedure and free the inventory that is to be unallocated  
	--------------------------------------------------------------------------------------------------------------  
	-- START v1.5
	IF OBJECT_ID('tempdb..#backorder_processing_allocation') IS NULL
	BEGIN
		IF OBJECT_ID('tempdb..#backorder_processing_po_allocation') IS NULL
		BEGIN
			BEGIN TRAN  
			EXEC tdc_plw_xfer_unallocate_sp @user_id   
			COMMIT TRAN  
		END
	END	  
	-- END v1.5
	----------------------------------------------------------------------------------------------------------------------------------  
	-- Remove any previous cross dock allocations for the orders selected FROM the #xfer_alloc_management table to be processed  --  
	----------------------------------------------------------------------------------------------------------------------------------  
	BEGIN TRAN  
	   
	DELETE FROM tdc_soft_alloc_tbl  
	WHERE EXISTS (SELECT * FROM #xfer_alloc_management  
		WHERE tdc_soft_alloc_tbl.order_no   = #xfer_alloc_management.xfer_no   
		AND tdc_soft_alloc_tbl.location   = #xfer_alloc_management.from_loc   
		AND tdc_soft_alloc_tbl.lot_ser    = 'CDOCK'   
		AND tdc_soft_alloc_tbl.bin_no     = 'CDOCK'   
		AND tdc_soft_alloc_tbl.order_type = 'T'      
		AND #xfer_alloc_management.sel_flg != 0)  
	   
	DELETE FROM tdc_pick_queue  
	WHERE EXISTS (SELECT * FROM #xfer_alloc_management  
		WHERE tdc_pick_queue.trans_type_no   = #xfer_alloc_management.xfer_no  
		AND tdc_pick_queue.trans_type_ext  = 0  
		AND tdc_pick_queue.location   = #xfer_alloc_management.from_loc   
		AND tdc_pick_queue.lot        = 'CDOCK'   
		AND tdc_pick_queue.bin_no     = 'CDOCK'   
		AND tdc_pick_queue.trans      = 'XFER-CDOCK'      
		AND #xfer_alloc_management.sel_flg != 0)  
	   
	   
	DELETE FROM tdc_cdock_mgt  
	WHERE EXISTS (SELECT * FROM #xfer_alloc_management  
		WHERE tdc_cdock_mgt.tran_no  = CAST(#xfer_alloc_management.xfer_no AS VARCHAR)  
		AND tdc_cdock_mgt.location       = #xfer_alloc_management.from_loc   
		AND tdc_cdock_mgt.tran_type          = 'XFER-CDOCK'      
		AND #xfer_alloc_management.sel_flg != 0)  
	  
	COMMIT TRAN  
	  
	------------------------------------------------------------------------------------------------------------------  
	-- Now we determine which xfer_no gets the inventory first.       --  
	-- We'll loop through the selected orders with ORDER BY depending on the allocation criteria.    --  
	------------------------------------------------------------------------------------------------------------------  
	SELECT @declare_clause = 'DECLARE selected_orders_cursor CURSOR FOR  
		  SELECT xfer_no, from_loc FROM #xfer_alloc_management WHERE sel_flg <> 0 ' +  
		   @passed_in_order_by_clause   
	  
	EXEC (@declare_clause)  
	  
	OPEN selected_orders_cursor  
	FETCH NEXT FROM selected_orders_cursor INTO @xfer_no, @from_loc  
	  
	WHILE (@@FETCH_STATUS = 0)  
	BEGIN   
		------------------------------------------------------------------------------------------  
		-- Get the user's settings  
		------------------------------------------------------------------------------------------  
		SELECT 
			@bin_group     = bin_group,  
			@search_sort   = search_sort,  
			@bin_first     = bin_first,  
			@q_priority    = tran_priority,  
			@on_hold       = on_hold,  
			@cdock         = cdock,  
			@pass_bin      = pass_bin,  
			@assigned_user = CASE WHEN user_group = '' OR user_group like '%DEFAULT%' THEN NULL ELSE user_group END  
		FROM 
			tdc_plw_process_templates (NOLOCK)  
		WHERE 
			template_code  = @template_code  
			AND UserID         = @user_id  
			AND location       = @from_loc  
			AND order_type     = 'T'  
			AND type           = 'one4one'  

		--------------------------------------------------------------------------------------------------------------  
		-- Get the bin sort by based on the bin first option and user selected Bin Sort creteria  
		--------------------------------------------------------------------------------------------------------------   
		EXEC dbo.tdc_plw_xfer_get_bin_sort @search_sort, @bin_first,  @lbs_order_by OUTPUT  
	  
		------------------------------------------------------------------------------------------  
		-- Get in_stock qty, plan_qty, for every part_no / line_no on every xfer_no  --  
		------------------------------------------------------------------------------------------  
		------------------------------------------------------------------------------------------------  
		--Look to see if we are just allocating by line, if so, we want to remove all other rows from the allocation table  
		------------------------------------------------------------------------------------------------  
		TRUNCATE TABLE #xfer_soft_alloc_working_tbl  
	  
		IF EXISTS(SELECT * FROM #xfer_soft_alloc_byline_tbl)  
		BEGIN   
			INSERT INTO #xfer_soft_alloc_working_tbl (xfer_no, from_loc, line_no, part_no, lb_tracking, qty_needed, conv_factor)  
			SELECT xl.xfer_no, xl.from_loc, xl.line_no, xl.part_no, xl.lb_tracking, 0, 1  
			FROM xfer_list xl (NOLOCK)  
						 WHERE xl.xfer_no  = @xfer_no  
			 AND xl.from_loc = @from_loc  
			 AND xl.line_no IN (SELECT line_no FROM #xfer_soft_alloc_byline_tbl)  
		END  
		ELSE  
		BEGIN  
			INSERT INTO #xfer_soft_alloc_working_tbl (xfer_no, from_loc, line_no, part_no, lb_tracking, qty_needed, conv_factor)  
			SELECT xl.xfer_no, xl.from_loc, xl.line_no, xl.part_no, xl.lb_tracking, 0, 1  
			FROM xfer_list xl (NOLOCK)   
			WHERE xl.xfer_no  = @xfer_no  
			 AND xl.from_loc = @from_loc  
		END  
	  
		------------------------------------------------------------------------------------------  
		-- Calculate needed qty for every part_no / line_no on every xfer_no   --  
		------------------------------------------------------------------------------------------  
		DECLARE needed_qty_cursor CURSOR FOR  
		SELECT line_no, part_no FROM #xfer_soft_alloc_working_tbl  

		OPEN needed_qty_cursor  
		FETCH NEXT FROM needed_qty_cursor INTO @line_no, @part_no  
	   
		WHILE (@@FETCH_STATUS = 0)  
		BEGIN  
			-- Get Ordered and Shipped qty for the part / line_no on the order  
			SELECT @qty_ordered_for_part_line_no = 0  
			SELECT @qty_picked_for_part_line_no  = 0  

			SELECT 
				@qty_ordered_for_part_line_no = ordered * conv_factor,  
				@qty_picked_for_part_line_no  = shipped * conv_factor,  
				@conv_factor              = conv_factor  
			FROM 
				xfer_list (NOLOCK)  
			WHERE 
				xfer_no  = @xfer_no  
				AND from_loc = @from_loc  
				AND line_no  = @line_no  
				AND part_no  = @part_no  
	  
			-- Get allocated qty for the part / line_no on the order  
			SELECT @alloc_qty_for_part_line_no = 0  
			SELECT 
				@alloc_qty_for_part_line_no = SUM(qty)  
			FROM 
				tdc_soft_alloc_tbl (NOLOCK)  
			WHERE 
				order_no   = @xfer_no  
				AND order_ext  = 0  
				AND order_type = 'T'  
				AND location   = @from_loc  
				AND line_no    = @line_no  
				AND part_no    = @part_no  
			 GROUP BY 
				location  
	  
			--------------------------------------------------------------------------------------------------  
			--   Calculate needed qty for the part / line_no     --  
			--------------------------------------------------------------------------------------------------  
			SELECT @needed_qty_for_part_line_no = 0  
			SELECT @needed_qty_for_part_line_no = @qty_ordered_for_part_line_no - @alloc_qty_for_part_line_no - @qty_picked_for_part_line_no  
	   
			-- Set Needed qty  
			UPDATE 
				#xfer_soft_alloc_working_tbl  
			 SET 
				qty_needed  = @needed_qty_for_part_line_no,  
				conv_factor = @conv_factor  
			WHERE 
				xfer_no     = @xfer_no  
				AND from_loc    = @from_loc  
				AND part_no     = @part_no  
				AND line_no     = @line_no  
	    
			FETCH NEXT FROM needed_qty_cursor INTO @line_no, @part_no  
		END  
	   
		CLOSE    needed_qty_cursor  
		DEALLOCATE needed_qty_cursor  
	  
		-- START v1.5 - Backorder Processing - Remove order lines not being processed by the job
		IF OBJECT_ID('tempdb..#backorder_processing_allocation') IS NOT NULL
		BEGIN
     		DELETE		a
			FROM		#xfer_soft_alloc_working_tbl a
			LEFT JOIN	#backorder_processing_allocation b
			ON			a.xfer_no = b.order_no
			AND			a.line_no = b.line_no  
			WHERE		b.order_no IS NULL 

			-- Now update qtys
			UPDATE	a
			SET		qty_needed = b.qty + ISNULL(b.allocated,0)
			FROM	#xfer_soft_alloc_working_tbl a
			JOIN	#backorder_processing_allocation b
			ON		a.xfer_no = b.order_no
			AND		a.line_no = b.line_no   
		END
	
		-- Backorder Processing POs - Remove order lines not being processed by the job
		IF OBJECT_ID('tempdb..#backorder_processing_po_allocation') IS NOT NULL
		BEGIN
     		DELETE		a
			FROM		#xfer_soft_alloc_working_tbl a
			LEFT JOIN	#backorder_processing_po_allocation_summary b
			ON			a.xfer_no = b.order_no
			AND			a.line_no = b.line_no  
			WHERE		b.order_no IS NULL 

			-- Now update qtys
			UPDATE	a
			SET		qty_needed = b.qty + ISNULL(b.allocated,0)
			FROM	#xfer_soft_alloc_working_tbl a
			JOIN	#backorder_processing_po_allocation_summary b
			ON		a.xfer_no = b.order_no
			AND		a.line_no = b.line_no   
		END
		-- END v1.5


		----------------------------------------------------------------------------------------------------------  
		-- Get available LOTs and BINs (type: OPEN or REPLENISH) for every part on all the selected orders. --  
		----------------------------------------------------------------------------------------------------------  
		SET @SQL = 
			'INSERT INTO #xfer_lb_stock (from_loc, part_no, lot_ser, bin_no, avail_qty, warning)  
			SELECT DISTINCT lb.location, lb.part_no, lb.lot_ser, lb.bin_no, 0, NULL  
			FROM lot_bin_stock lb (NOLOCK), tdc_bin_master bm (NOLOCK), #xfer_soft_alloc_working_tbl xfer  
			WHERE lb.location = xfer.from_loc   
			AND lb.part_no  = xfer.part_no    
			AND lb.bin_no   = bm.bin_no  
			AND lb.location = bm.location  
			AND bm.usage_type_code IN (''OPEN'', ''REPLENISH'')'  
	   
		SELECT @SQL = @SQL + '   AND ISNULL(bm.bm_udef_e,'''') = '''' '  -- v1.0

		IF ISNULL(@bin_group, '[ALL]') <> '[ALL]'  
		BEGIN  
			SET @SQL = @SQL + ' AND bm.group_code = ''' + @bin_group + ''''  
		END  

		EXEC (@SQL)  

		-- START v1.3
		----------------------------------------------------------------------------------------------------------  
		-- If auto-allocating, remove excluded bins																--  
		---------------------------------------------------------------------------------------------------------- 
		IF @template_code = 'AUTO_ALLOC_T'
		BEGIN
			-- Delete inv excluded bins
			DELETE a
			FROM 
				#xfer_lb_stock a
			INNER JOIN
				cvo_inv_excluded_bins b
			ON
				a.from_loc = b.location
				AND a.bin_no = b.bin_no

			-- Delete non-allocating bins
			DELETE a
			FROM 
				#xfer_lb_stock a
			INNER JOIN
				cvo_non_allocating_bins b
			ON
				a.from_loc = b.location
				AND a.bin_no = b.bin_no
		END
		-- END v1.3

		-- START v1.1
		----------------------------------------------------------------------------------------------------------  
		-- Create bin type table based on contents of #xfer_lb_stock.											 --  
		---------------------------------------------------------------------------------------------------------- 
		INSERT #xfer_bin_type(
			location,
			bin_no,
			bin_group,
			bin_sort)
		SELECT
			a.from_loc,
			a.bin_no,
			b.group_code,
			CASE b.group_code
				WHEN @high_bays_bin_group THEN 1
				WHEN @bulk_bin_group THEN 2
				ELSE 3
			END		
		FROM
			#xfer_lb_stock a 
		INNER JOIN
			dbo.tdc_bin_master b (NOLOCK)
		ON
			a.from_loc = b.location
			AND a.bin_no = b.bin_no

		-- END v1.1

		------------------------------------------------------------------------------------------  
		-- Get available qty for every part / location / lot / bin for all the selected orders. --  
		------------------------------------------------------------------------------------------  
		DECLARE lb_quantities_cursor CURSOR FOR  
		SELECT from_loc, part_no, lot_ser, bin_no FROM #xfer_lb_stock   
		 
		OPEN lb_quantities_cursor  
		FETCH NEXT FROM lb_quantities_cursor INTO @from_loc, @part_no, @lot_ser, @bin_no  

		WHILE (@@FETCH_STATUS = 0)  
		BEGIN    
			-- Get in stock qty for the part/location/lot/bin.  
			SELECT @in_stock_qty_for_part = 0  
			SELECT 
				@in_stock_qty_for_part = SUM(qty)  
			FROM 
				lot_bin_stock (NOLOCK)  
			WHERE 
				location  = @from_loc  
				AND part_no   = @part_no  
				AND bin_no    = @bin_no  
				AND lot_ser   = @lot_ser  
			GROUP BY 
				location  
	   
			-- Get total allocated qty for the part / location / lot / bin regardless order numbers.  
			SELECT @alloc_qty_for_part = 0  
			SELECT 
				@alloc_qty_for_part = SUM(qty)  
			FROM 
				tdc_soft_alloc_tbl (NOLOCK)  
			WHERE 
				location  = @from_loc  
				AND part_no   = @part_no  
				AND lot_ser   = @lot_ser  
				AND bin_no    = @bin_no  
			GROUP BY 
				location  
	   
			-- Get inventory for this part / location /lot / bin that a warehouse manager requested a bin-to-bin move on.  
			SELECT @bin_2_bin_move_qty = 0  
			SELECT 
				@bin_2_bin_move_qty =  SUM(qty_to_process)  
			FROM 
				tdc_pick_queue (NOLOCK)  
			WHERE 
				location = @from_loc   
				AND part_no  = @part_no   
				AND lot      = @lot_ser   
				AND bin_no   = @bin_no   
				AND trans    = 'MGTBIN2BIN'  
			GROUP BY 
				location  
	  
			------------------------------------------------------------------------------------------------------------------  
			-- Calculate available qty for the part on LOT/BIN.        --  
			------------------------------------------------------------------------------------------------------------------  
			UPDATE 
				#xfer_lb_stock  
			SET 
				avail_qty = ISNULL((@in_stock_qty_for_part - @alloc_qty_for_part - @bin_2_bin_move_qty), 0)  
			WHERE 
				from_loc  = @from_loc  
				AND part_no   = @part_no  
				AND lot_ser   = @lot_ser  
				AND bin_no    = @bin_no  
	  
			------------------------------------------------------------------------------------------------------------------  
			-- This warning will be displaied from the VB app:        --  
			-- Warning, Bin: ' + @lb_bin + ' bypassed for this allocation by bin to bin queue trans!  
			------------------------------------------------------------------------------------------------------------------  
			IF @bin_2_bin_move_qty > 0  
			BEGIN  
				UPDATE #xfer_lb_stock  
					SET warning = 'Y'  
				WHERE from_loc  = @from_loc  
				  AND part_no   = @part_no  
				  AND lot_ser   = @lot_ser  
				  AND bin_no    = @bin_no   
			END  

			FETCH NEXT FROM lb_quantities_cursor INTO @from_loc, @part_no, @lot_ser, @bin_no  
		END  
	   
		CLOSE    lb_quantities_cursor  
		DEALLOCATE lb_quantities_cursor  
	  
		-------------------------------------------------------------------------------------------------------------------------------  
		-- We'll loop through the parts on the order and determine from wich BIN we'll get inventory first based on the conifg flags --  
		-------------------------------------------------------------------------------------------------------------------------------   
		DECLARE parts_on_order_cursor CURSOR FOR  
		SELECT line_no, part_no, lb_tracking, qty_needed, conv_factor  
		FROM #xfer_soft_alloc_working_tbl  
			  WHERE xfer_no  = @xfer_no  
		 AND from_loc = @from_loc  

		OPEN parts_on_order_cursor  
		FETCH NEXT FROM parts_on_order_cursor INTO @line_no, @part_no, @lb_tracking, @needed_qty_for_part_line_no, @conv_factor  

		WHILE (@@FETCH_STATUS = 0)  
		BEGIN  
			IF @needed_qty_for_part_line_no = 0  
			BEGIN  
				FETCH NEXT FROM parts_on_order_cursor INTO @line_no, @part_no, @lb_tracking, @needed_qty_for_part_line_no, @conv_factor  
				CONTINUE  
			END  
	  
			SET @data = 'Line: ' + CAST(@line_no as varchar(3)) + '; Order Type: T'  
	  
			IF (@lb_tracking = 'Y')  
			BEGIN  
				-- START v1.1
				-- If qty is over fence value then pick from highbay, then bulk then forward pick, if not reverse the order
				IF @needed_qty_for_part_line_no >= @ALLOC_QTY_FENCE_QTY 
				BEGIN
					SET @xfer_order_by = LEFT(@lbs_order_by,9) + ' bt.bin_sort ASC, ' + RIGHT(@lbs_order_by,LEN(@lbs_order_by) - 9)
-- v1.7					SET @xfer_order_by = LEFT(@lbs_order_by,9) + ' bt.bin_sort DESC, ' + RIGHT(@lbs_order_by,LEN(@lbs_order_by) - 9) -- v1.6
				END
				ELSE
				BEGIN
					SET @xfer_order_by = LEFT(@lbs_order_by,9) + ' bt.bin_sort DESC, ' + RIGHT(@lbs_order_by,LEN(@lbs_order_by) - 9)
-- v1.7					SET @xfer_order_by = LEFT(@lbs_order_by,9) + ' bt.bin_sort DESC, ' + RIGHT(@lbs_order_by,LEN(@lbs_order_by) - 9) -- v1.6
				END
		
	
				----------------------------------------------------------------------------------------------------------  
				--  Now we'll loop through the LOTs/BINs and do the allocation.      --  
				----------------------------------------------------------------------------------------------------------   
	  
				-- START v1.5
				SET @bop = 0
				IF OBJECT_ID('tempdb..#backorder_processing_po_allocation') IS NOT NULL
				BEGIN
					SET @bin_no = ''
					
					-- Do CROSSDOCK stock first
					WHILE 1=1
					BEGIN
						SELECT TOP 1
							@bin_no = bin_no,
							@qty = qty
						FROM
							#backorder_processing_po_allocation (NOLOCK)
						WHERE
							bin_no > @bin_no
							AND bin_no IS NOT NULL
							AND order_no = @xfer_no
							AND line_no = @line_no
							AND part_no = @part_no
						ORDER BY
							bin_no

						IF @@ROWCOUNT = 0
							BREAK

						-- Do stuff
						SET @lot_ser = '1'
						
						IF EXISTS (SELECT * FROM tdc_soft_alloc_tbl (NOLOCK)  
										   WHERE order_no   = @xfer_no   
											 AND order_ext  = 0  
											 AND order_type = 'T'  
											 AND location   = @from_loc   
											 AND line_no    = @line_no  
											 AND part_no    = @part_no   
											 AND lot_ser    = @lot_ser   
											 AND bin_no     = @bin_no)  
						BEGIN  
							UPDATE	
								tdc_soft_alloc_tbl  
							 SET 
								qty           = qty  + @qty,  
								dest_bin      = @pass_bin,  
								q_priority    = @q_priority,  
								assigned_user = @assigned_user,  
								user_hold     = @on_hold,  
								alloc_type    = @alloc_type  
						WHERE 
								order_no      = @xfer_no   
								AND order_ext     = 0  
								AND order_type    = 'T'  
								AND location      = @from_loc   
								AND line_no       = @line_no  
								AND part_no       = @part_no   
								AND lot_ser       = @lot_ser   
								AND bin_no        = @bin_no  
						END  
						ELSE  
						BEGIN  
							INSERT INTO tdc_soft_alloc_tbl(order_no, order_ext, location, line_no, part_no,lot_ser, bin_no, qty,    
									 order_type, target_bin, dest_bin,  alloc_type, q_priority, assigned_user, user_hold)  
							VALUES  (@xfer_no, 0, @from_loc, @line_no, @part_no, @lot_ser, @bin_no, @qty,   
							 'T', @bin_no, @pass_bin, @alloc_type, @q_priority, @assigned_user, @on_hold)  
						END      
     
						INSERT INTO tdc_log (tran_date, UserID, trans_source, module, trans, tran_no, tran_ext, part_no, lot_ser, bin_no, location, quantity, data)  
						VALUES(GETDATE(), @user_id, 'VB', 'PLW', 'ALLOCATION', @xfer_no, 0, @part_no, @lot_ser, @bin_no, @from_loc, @qty, @data)  

					END

					SET @qty = NULL

					-- Do std bin next, get the stock remaining and let the routine run with this
					SELECT
						@qty = SUM(qty)
					FROM
						#backorder_processing_po_allocation (NOLOCK)
					WHERE
						bin_no IS NULL
						AND order_no = @xfer_no
						AND line_no = @line_no
						AND part_no = @part_no


					SELECT @filled_ind = 'N' 

					IF ISNULL(@qty,0) = 0
					BEGIN
						SELECT @filled_ind = 'Y'  
					END

					SET @needed_qty_for_part_line_no = @qty

					SET @bop = 1
				END
				-- END v1.6		

				-- Declare cursor as a string so we can dynamically change ORDER BY clause 
				SELECT @lb_cursor_clause = 'DECLARE lots_bins_cursor CURSOR FOR  
					   SELECT tlb.lot_ser, tlb.bin_no, avail_qty   
						   FROM lot_bin_stock lb (NOLOCK), #xfer_lb_stock tlb, tdc_bin_master bm (NOLOCK), #xfer_bin_type bt  
						WHERE lb.location  = tlb.from_loc  
						  AND lb.part_no   = tlb.part_no  
						  AND lb.bin_no    = tlb.bin_no  
						  AND lb.lot_ser   = tlb.lot_ser  
						  AND tlb.avail_qty > 0  
						  AND lb.location  = bm.location  
						  AND lb.bin_no    = bm.bin_no
						  AND lb.location  = bt.location
						  AND lb.bin_no    = bt.bin_no  
						  AND tlb.part_no  = ' + CHAR(39) + @part_no  + CHAR(39) +  
						' AND tlb.from_loc = ' + CHAR(39) + @from_loc + CHAR(39) +   
						@xfer_order_by 
				/* 
				SELECT @lb_cursor_clause = 'DECLARE lots_bins_cursor CURSOR FOR  
					   SELECT tlb.lot_ser, tlb.bin_no, avail_qty   
						   FROM lot_bin_stock lb (NOLOCK), #xfer_lb_stock tlb, tdc_bin_master bm (NOLOCK)  
						WHERE lb.location  = tlb.from_loc  
						  AND lb.part_no   = tlb.part_no  
						  AND lb.bin_no    = tlb.bin_no  
						  AND lb.lot_ser   = tlb.lot_ser  
									 AND tlb.avail_qty > 0  
									AND lb.location  = bm.location  
									 AND lb.bin_no    = bm.bin_no  
						  AND tlb.part_no  = ' + CHAR(39) + @part_no  + CHAR(39) +  
						' AND tlb.from_loc = ' + CHAR(39) + @from_loc + CHAR(39) +   
						@lbs_order_by 
				*/ 
				-- END v1.1
				EXEC (@lb_cursor_clause)  
	  
				OPEN lots_bins_cursor  
				FETCH NEXT FROM lots_bins_cursor INTO @lot_ser, @bin_no, @avail_qty_for_part_line_no   
	  
				IF @bop = 0
				BEGIN
					-- This indicator will become 'Y' when we allocated a part  
					SELECT @filled_ind = 'N'   
				END

				WHILE (@@FETCH_STATUS = 0 AND @filled_ind = 'N')  
				BEGIN  
	  
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
							   WHERE order_no   = @xfer_no   
								 AND order_ext  = 0  
								 AND order_type = 'T'  
								 AND location   = @from_loc   
								 AND line_no    = @line_no  
								 AND part_no    = @part_no   
								 AND lot_ser    = @lot_ser   
								 AND bin_no     = @bin_no)  
							BEGIN  
								UPDATE tdc_soft_alloc_tbl  
								  SET qty           = qty  + @swap_qty,  
									  dest_bin      = @pass_bin,  
									  q_priority    = @q_priority,  
									  assigned_user = @assigned_user,  
									  user_hold     = @on_hold,  
									  alloc_type    = @alloc_type  
									   WHERE order_no      = @xfer_no   
								  AND order_ext     = 0  
										 AND order_type    = 'T'  
										 AND location      = @from_loc   
										 AND line_no       = @line_no  
										 AND part_no       = @part_no   
										 AND lot_ser       = @lot_ser   
										 AND bin_no        = @bin_no  
							END  
							ELSE  
							BEGIN  
								INSERT INTO tdc_soft_alloc_tbl(order_no, order_ext, location, line_no, part_no,lot_ser, bin_no, qty,    
										 order_type, target_bin, dest_bin,  alloc_type, q_priority, assigned_user, user_hold)  
								VALUES  (@xfer_no, 0, @from_loc, @line_no, @part_no, @lot_ser, @bin_no, @swap_qty,   
								 'T', @bin_no, @pass_bin, @alloc_type, @q_priority, @assigned_user, @on_hold)  
							END      
	     
							INSERT INTO tdc_log (tran_date, UserID, trans_source, module, trans, tran_no, tran_ext, part_no, lot_ser, bin_no, location, quantity, data)  
							VALUES(GETDATE(), @user_id, 'VB', 'PLW', 'ALLOCATION', @xfer_no, 0, @part_no, @lot_ser, @bin_no, @from_loc, @swap_qty, @data)  
	  
							SELECT @filled_ind = 'Y'  
						END  
					END    
					ELSE 
					BEGIN    
						IF (@avail_qty_for_part_line_no > 0)-- is there at least some items that could be picked FROM this bin   
						BEGIN  
							IF @swap_qty <> 1   
								SELECT @swap_qty = FLOOR(@avail_qty_for_part_line_no / @conv_factor) * @conv_factor  
							ELSE  
								SELECT @swap_qty = @avail_qty_for_part_line_no  
	       
							IF(@swap_qty > 0)  
							BEGIN  
								IF EXISTS (SELECT * FROM tdc_soft_alloc_tbl (NOLOCK)  
								   WHERE order_no   = @xfer_no   
									 AND order_ext  = 0  
									 AND order_type = 'T'  
									 AND location   = @from_loc   
									 AND line_no    = @line_no  
									 AND part_no    = @part_no   
									 AND lot_ser    = @lot_ser   
									 AND bin_no     = @bin_no)  
								BEGIN  
									UPDATE tdc_soft_alloc_tbl  
									SET qty           = qty  + @swap_qty,  
									  dest_bin      = @pass_bin,  
									  q_priority    = @q_priority,  
									  assigned_user = @assigned_user,  
									  user_hold     = @on_hold,  
									  alloc_type    = @alloc_type  
									   WHERE order_no      = @xfer_no   
									AND order_ext     = 0  
										 AND order_type    = 'T'  
										 AND location      = @from_loc   
										 AND line_no       = @line_no  
										 AND part_no       = @part_no   
										 AND lot_ser       = @lot_ser   
										 AND bin_no        = @bin_no  
								END  
								ELSE  
								BEGIN  
									INSERT INTO tdc_soft_alloc_tbl(order_no, order_ext, location, line_no, part_no,lot_ser, bin_no, qty,    
										 order_type, target_bin, dest_bin,  alloc_type, q_priority, assigned_user, user_hold)  
									VALUES  (@xfer_no, 0, @from_loc, @line_no, @part_no, @lot_ser, @bin_no, @swap_qty,   
									'T', @bin_no, @pass_bin, @alloc_type, @q_priority, @assigned_user, @on_hold)  
								END    
		   
								INSERT INTO tdc_log (tran_date, UserID, trans_source, module, trans, tran_no, tran_ext, part_no, lot_ser, bin_no, location, quantity, data)  
								VALUES(GETDATE(), @user_id, 'VB', 'PLW', 'ALLOCATION', @xfer_no, 0, @part_no, @lot_ser, @bin_no, @from_loc, @swap_qty, @data)  
		  
								-- Decrement needed qty by what has been allocated   
								SELECT @needed_qty_for_part_line_no = @needed_qty_for_part_line_no - @swap_qty   
							END  
						END -- IF (@avail_qty_for_part_line_no > 0)  
					END

					-- Decrement available qty by what has been allocated   
					UPDATE #xfer_lb_stock   
					SET avail_qty = avail_qty - @swap_qty  
					WHERE from_loc  = @from_loc  
					AND part_no   = @part_no  
					AND lot_ser   = @lot_ser  
					AND bin_no    = @bin_no  
	  
					DELETE FROM #xfer_lb_stock WHERE avail_qty = 0  
  
					FETCH NEXT FROM lots_bins_cursor INTO @lot_ser, @bin_no, @avail_qty_for_part_line_no   
				END  
	  
				CLOSE    lots_bins_cursor  
				DEALLOCATE lots_bins_cursor  
	  
				IF (@filled_ind = 'N' AND @cdock = 'Y')  
				BEGIN  
					IF @conv_factor <> 1  
						SELECT @swap_qty = FLOOR(@needed_qty_for_part_line_no / @conv_factor) * @conv_factor  
					ELSE  
						SELECT @swap_qty = @needed_qty_for_part_line_no   
	  
					INSERT INTO tdc_soft_alloc_tbl(order_no, order_ext, location, line_no, part_no,lot_ser, bin_no, qty,    
							  order_type, target_bin, dest_bin, alloc_type, q_priority, assigned_user, user_hold)  
					VALUES  (@xfer_no, 0, @from_loc, @line_no, @part_no, 'CDOCK', 'CDOCK', @swap_qty,   
					  'T', NULL, @pass_bin, @alloc_type, @q_priority, @assigned_user, @on_hold)  
	  
					EXEC @seq_no = tdc_queue_get_next_seq_num 'tdc_pick_queue', @q_priority  
	  
	  
					INSERT INTO tdc_pick_queue (trans_source, trans,  priority,  seq_no, company_no, location, warehouse_no, trans_type_no, trans_type_ext,   
						   tran_receipt_no, line_no, pcsn, part_no, eco_no, lot, mfg_lot, mfg_batch, serial_no, bin_no, qty_to_process,   
						   qty_processed, qty_short, next_op, tran_id_link, date_time, assign_group, assign_user_id, [user_id], status, tx_status, tx_control, tx_lock)  
					VALUES ('PLW', 'XFER-CDOCK', @q_priority, @seq_no, NULL, @from_loc, NULL, @xfer_no, 0, NULL, @line_no, NULL, @part_no, NULL, 'CDOCK', NULL, NULL, NULL, 'CDOCK',  
					 @swap_qty, 0, 0, NULL, NULL, GETDATE(), NULL, NULL, NULL, NULL, NULL, 'M', 'V')  
	  
					INSERT INTO tdc_log (tran_date, UserID, trans_source, module, trans, tran_no, tran_ext, part_no, lot_ser, bin_no, location, quantity, data)  
					VALUES(GETDATE(), @user_id, 'VB', 'PLW', 'ALLOCATION', @xfer_no, 0, @part_no, 'CDOCK', 'CDOCK', @from_loc, @swap_qty, @data)  
				END  
			END  
			ELSE -- @lb_tracking = 'N'  
			BEGIN  
				--Get all inv that has been prev allocated for this loc/part   
				SELECT @alloc_qty_for_part = 0  
				SELECT @alloc_qty_for_part = SUM(qty)  
				 FROM tdc_soft_alloc_tbl (NOLOCK)  
				WHERE location = @from_loc  
				  AND part_no  = @part_no  
				GROUP BY location, part_no  
	  
				-- Get available qty = total amount of inventory in stock minus what has been allocated   
				SELECT @avail_qty_for_part = 0  
				SELECT @avail_qty_for_part = in_stock - @alloc_qty_for_part  
				FROM inventory (NOLOCK)  
				WHERE location = @from_loc  
				AND part_no  = @part_no  
	  
				SELECT @avail_qty_for_part = @avail_qty_for_part -   
				ISNULL((SELECT SUM(tp.pick_qty - tp.used_qty)   
											FROM tdc_wo_pick tp (NOLOCK), prod_list pl (NOLOCK)   
				WHERE tp.prod_no  = pl.prod_no   
											 AND tp.prod_ext = pl.prod_ext   
				 AND tp.location = pl.location   
				 AND tp.part_no  = pl.part_no   
				 AND pl.status  < 'S'   
				 AND pl.lb_tracking = 'N'   
				 AND pl.location = @from_loc AND pl.part_no = @part_no),0)  
	  
				/* determine IF we have enough quantity to allocate and set a common update variable */  
				IF (@avail_qty_for_part >= @needed_qty_for_part_line_no)  
				BEGIN  
					IF @swap_qty <> 1  
						SELECT @swap_qty = FLOOR(@needed_qty_for_part_line_no / @conv_factor) * @conv_factor  
					ELSE  
						SELECT @swap_qty = @needed_qty_for_part_line_no   
				END  
				ELSE  
				BEGIN  
					IF @swap_qty <> 1  
						SELECT @swap_qty = FLOOR(@avail_qty_for_part / @conv_factor) * @conv_factor  
					ELSE  
						SELECT @swap_qty = @avail_qty_for_part  
				END  
	  
				IF(@swap_qty > 0)  
				BEGIN  
					IF EXISTS (SELECT * FROM tdc_soft_alloc_tbl (NOLOCK)  
						 WHERE order_no   = @xfer_no  
						   AND order_ext  = 0  
						   AND order_type = 'T'  
						   AND location   = @from_loc   
						   AND line_no    = @line_no   
						   AND part_no    = @part_no)  
					BEGIN  
						UPDATE tdc_soft_alloc_tbl  
						SET qty           = qty  + @swap_qty,  
							dest_bin      = @pass_bin,  
							q_priority    = @q_priority,  
							assigned_user = @assigned_user,  
							user_hold     = @on_hold,  
							alloc_type    = @alloc_type  
						WHERE order_no      = @xfer_no   
						AND order_ext     = 0  
						   AND order_type    = 'T'  
						   AND location      = @from_loc   
						   AND line_no       = @line_no  
						   AND part_no       = @part_no   
					END  
					ELSE  
					BEGIN  
						INSERT INTO tdc_soft_alloc_tbl(order_no, order_ext, location, line_no, part_no,lot_ser, bin_no, qty,    
							   order_type, target_bin, dest_bin, alloc_type, q_priority, assigned_user, user_hold)  
						VALUES  (@xfer_no, 0, @from_loc, @line_no, @part_no, NULL, NULL, @swap_qty,   
						'T', NULL, @pass_bin, @alloc_type, @q_priority, @assigned_user, @on_hold)  
					END  
	   
					INSERT INTO tdc_log (tran_date, UserID, trans_source, module, trans, tran_no, tran_ext, part_no, lot_ser, bin_no, location, quantity, data)  
					VALUES(GETDATE(), @user_id, 'VB', 'PLW', 'ALLOCATION', @xfer_no, 0, @part_no, NULL, NULL, @from_loc, @swap_qty, @data)  
	  
				END  
			END -- @lb_tracking = 'N'  
	  
			FETCH NEXT FROM parts_on_order_cursor INTO @line_no, @part_no, @lb_tracking, @needed_qty_for_part_line_no, @conv_factor  
	  
		END  
	  
		CLOSE    parts_on_order_cursor  
		DEALLOCATE parts_on_order_cursor  

		-- v1.0
		EXEC cvo_hold_ship_complete_xfer_allocations_sp @xfer_no

		-- v1.2
		EXEC cvo_xfer_autoship_allocated_sp @xfer_no

		-- v1.4
		EXEC cvo_xfer_autopack_allocated_sp @xfer_no

		FETCH NEXT FROM selected_orders_cursor INTO @xfer_no, @from_loc  
	END  
	  
	CLOSE    selected_orders_cursor  
	DEALLOCATE selected_orders_cursor  
	  
	------------------------------------------------------------------------------------------  
	--    Insert a new record into the history table   --  
	------------------------------------------------------------------------------------------  
	UPDATE tdc_alloc_history_tbl   
	   SET fill_pct = b.curr_alloc_pct  
	  FROM tdc_alloc_history_tbl a(NOLOCK),  
		   #xfer_alloc_management b  
	 WHERE a.order_no   = b.xfer_no  
	   AND a.order_ext  = 0  
	   AND a.order_type = 'T'  
	   AND a.location   = b.from_loc  
	            
	INSERT INTO tdc_alloc_history_tbl(order_no, order_ext, location, fill_pct, alloc_date, alloc_by, order_type)  
	SELECT xfer_no, 0, from_loc, curr_alloc_pct, GETDATE(), @user_id, 'T'  
	FROM #xfer_alloc_management a  
	WHERE (sel_flg <> 0 OR sel_flg2 <> 0)  
	AND a.xfer_no NOT IN (	SELECT order_no   
							FROM tdc_alloc_history_tbl b(NOLOCK)  
							WHERE order_type = 'T'  
							AND a.from_loc = b.location)  
	  
	TRUNCATE TABLE #xfer_soft_alloc_working_tbl   
	TRUNCATE TABLE #xfer_lb_stock  
	TRUNCATE TABLE #xfer_bin_type	-- v1.2 

	  
	RETURN  
END
GO
GRANT EXECUTE ON  [dbo].[tdc_plw_xfer_soft_alloc_sp] TO [public]
GO
