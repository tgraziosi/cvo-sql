SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- v1.0 CB 01/04/2011 - 14.Planners Workbench - Additional criteria

CREATE PROC [dbo].[tdc_plw_sia_process_sp]
	@where_clause1 		varchar(255), 
	@where_clause2 		varchar(255), 
	@where_clause3 		varchar(255), 
	@where_clause4 		varchar(255), 
	@user_id		varchar(50),
	@criteria_template	varchar(50),
	@process_template	varchar(50),
	@create_selection	char(1), 
	@method			varchar(25),
	@pct_filter		int
AS 

DECLARE @order_no 		int,
	@order_ext 		int,
	@ret			int,
	@location 		varchar(10),
	@line_no 		int,
	@part_no 		varchar(30),
	@declare_clause 	varchar(5000),
	@con_seq_no 		int, 
	@next_con_no		int,
	@con_name		varchar(20),
	@con_desc		varchar(255),
	@pre_pack_flg		char(1), 
	@one_for_one_flg	char(1),
	@lbs_order_by		varchar(5000),
	@target_bin		varchar(100),
	@dist_cust_pick		char(1),
	@TempAllocType		varchar(2),
	@bin_group		varchar(20),
	@assigned_user		varchar(50),
	@user_hold		char(1),
	@priority		int,
	@seq_no			int,
	@alloc_type	 	varchar(2),
	@search_sort	 	varchar(5000), 
	@cdock_flg	 	char(1), 
	@pass_bin	 	varchar(12),
	@bin_first		varchar(10),
	@bin_type		varchar(10),
	@replen_group		varchar(12),
	@one4one_or_cons	varchar(7),
	@pkg_code		varchar(10),
	@multiple_parts		char(1),
	@search_type		varchar(10),
	@max_qty_to_alloc	decimal(20, 8),
	@qty_to_alloc		int,
	@qty_ordered		int,
	@qty_alloc		int,
	@qty_picked		int,
	@qty_needed		int,	
	@part_type		char(1),
	@insert_clause		varchar (2000),
	@select_clause 		varchar (2000),
	@from_clause 		varchar (1000),
	@where_clause 		varchar (1000) ,
	@existing_alloc_type 	varchar(2)

	TRUNCATE TABLE #temp_sia_working_tbl
	TRUNCATE TABLE #so_alloc_err
 
	IF @method IS NULL AND @pct_filter IS NULL
	BEGIN
		SELECT @method = method,
		       @pct_filter = fill_percent
		  FROM tdc_plw_criteria_templates(NOLOCK)
		 WHERE userid = @user_id
		   AND template_code = @criteria_template
	END
	--------------------------------------------------------------------------------------------------------------------------------
	-- Fill the allocation mgt temp table
	--------------------------------------------------------------------------------------------------------------------------------
	IF @create_selection = 'Y'
	BEGIN
		TRUNCATE TABLE #so_alloc_management
	
		-- If there is a percent filter passed in, 
		-- or method = 'standard, detail lines are required.
		-- calculate the percanteges by calling the stored procedure
		IF @pct_filter > 0 OR @method = 'Standard'
		BEGIN

			EXEC tdc_plw_so_alloc_management_sp @criteria_template, @method, @where_clause1, @where_clause2, @where_clause3, @where_clause4, '', @pct_filter, 0, 0, 'ALL', @user_id
		END
		ELSE -- Otherwise, only get the orders.
		BEGIN
	
			-- First we get all the data we can get for the #so_alloc_management table.
			-- Later we'll update the the feilds that have to be calculated
			SELECT @insert_clause = ' INSERT INTO #so_alloc_management
							(sel_flg, sel_flg2, prev_alloc_pct, curr_alloc_pct,
							curr_fill_pct, order_no, order_ext, location,
							order_status, sch_ship_date, consolidation_no,
							cust_type, cust_type2, cust_type3, cust_name,
							cust_flg, cust_code, territory_code, carrier_code,
							dest_zone_code, ship_to, so_priority_code,
							ordered_dollars, shippable_dollars,shippable_margin_dollars, 
							alloc_type, user_code, user_category, load_no ) '
			
			SELECT @select_clause = ' SELECT DISTINCT 0 AS sel_flg, 0 AS sel_flg2, 0,
							 0 AS curr_alloc_pct, 0 AS curr_fill_pct, ord_list.order_no, 
						         ord_list.order_ext, ord_list.location, orders.status, orders.sch_ship_date, 
						         consolidation_no = 0,
						         armaster.addr_sort1, armaster.addr_sort2, armaster.addr_sort3,
						         armaster.address_name, orders.back_ord_flag, orders.cust_code,
						         orders.ship_to_region, orders.routing, orders.dest_zone_code,
						         orders.ship_to_name, orders.so_priority_code, NULL, NULL, NULL, NULL, orders.user_code, 
							 orders.user_category, load_no = NULL '
			
			SELECT @from_clause   = '   FROM orders (NOLOCK), 
						         ord_list(NOLOCK), 
						         armaster(NOLOCK),
							 tdc_order(NOLOCK)'
			
			SELECT @where_clause  = '  WHERE orders.order_no     = ord_list.order_no 
						     AND orders.ext          = ord_list.order_ext 
						     AND orders.cust_code    = armaster.customer_code
						     AND orders.cust_code    = armaster.customer_code
						     AND orders.ship_to      = armaster.ship_to_code
						     AND orders.type         = ''I''   
						     AND tdc_order.order_no  = orders.order_no
						     AND tdc_order.order_ext = orders.ext
						     AND armaster.address_type = (SELECT MAX(address_type) 
									            FROM armaster (NOLOCK) 
									    	   WHERE customer_code = orders.cust_code 
									     	     AND ship_to_code  = orders.ship_to) '
			
			
			
				--  INSERT INTO #so_alloc_management
				EXEC (@insert_clause + ' ' +
				      @select_clause + ' ' +
				      @from_clause   + ' ' +
				      @where_clause  + ' ' + 
				      @where_clause1 +  
				      @where_clause2 +  
				      @where_clause3 +  
				      @where_clause4 )
			
			
				DELETE FROM #so_alloc_management 
				       FROM tdc_cons_ords (NOLOCK)
				 WHERE #so_alloc_management.order_no = tdc_cons_ords.order_no
				   AND #so_alloc_management.order_ext = tdc_cons_ords.order_ext 
				   AND #so_alloc_management.location = tdc_cons_ords.location 
				   AND #so_alloc_management.consolidation_no IN (SELECT consolidation_no 
									           FROM tdc_cons_ords (NOLOCK)
									          GROUP BY consolidation_no HAVING count(*) > 1 ) 		
			
				--Remove unwanted parts
				IF EXISTS (SELECT * FROM tdc_sia_part_filter_tbl(NOLOCK) 
					    WHERE userid = @user_id 
					      AND template_code = @process_template) 	
				BEGIN
				
					DELETE FROM #so_alloc_management
					 WHERE CAST(order_no AS VARCHAR(20)) + '-' + CAST(order_ext AS VARCHAR(10)) + '-' + location  
					   NOT IN (
							SELECT CAST(order_no AS VARCHAR(20)) + '-' + CAST(order_ext AS VARCHAR(10)) + '-' + location  
							  FROM ord_list ol(NOLOCK)
							 WHERE part_no IN (SELECT part_no 
									    FROM tdc_sia_part_filter_tbl (NOLOCK) 
									   WHERE userid = @user_id 
					     				     AND template_code = @process_template
									     AND location = ol.location)
							UNION 
							SELECT CAST(order_no AS VARCHAR(20)) + '-' + CAST(order_ext AS VARCHAR(10)) + '-' + location 
							  FROM ord_list_kit olk(NOLOCK)
							 WHERE part_no IN (SELECT part_no 
									     FROM tdc_sia_part_filter_tbl (NOLOCK) 
									     WHERE userid = @user_id 
					      				       AND template_code = @process_template
									       AND location = olk.location)
						)
					 
				END
		END
			
		UPDATE #so_alloc_management SET sel_flg = -1
	END
 
	-------------------------------------------------------------------------------------------------------------------------------
	-- Validate the distribution type
	-------------------------------------------------------------------------------------------------------------------------------	
	IF ISNULL((	SELECT COUNT(DISTINCT a.alloc_type)
			  FROM tdc_cons_ords a(NOLOCK),
			       #so_alloc_management b(NOLOCK)
			 WHERE a.order_no = b.order_no
			   AND a.order_ext = b.order_ext
			   AND a.location = b.location
			   AND b.sel_flg != 0), 0) > 1
	BEGIN
		RAISERROR('Selection contains orders that have been previously allocated using different Distribution Process Type(s)', 16, 1)
		RETURN -1
	END
 
	SELECT @existing_alloc_type = CASE dist_type 
				WHEN 'PrePack' 		THEN 'PR'
				WHEN 'ConsolePick' 	THEN 'PT'
				WHEN 'PickPack' 	THEN 'PP'
				WHEN 'PackageBuilder' 	THEN 'PB'
			     end
 	  FROM tdc_plw_process_templates 
	 WHERE userid = @user_id
	   AND template_code = @process_template
 
	IF @existing_alloc_type IS NOT NULL
	BEGIN
		IF((SELECT DISTINCT a.alloc_type
			  FROM tdc_cons_ords a(NOLOCK),
			       #so_alloc_management b(NOLOCK)
			 WHERE a.order_no = b.order_no
			   AND a.order_ext = b.order_ext
			   AND a.location = b.location
			   AND b.sel_flg != 0) != @existing_alloc_type)
		BEGIN
		RAISERROR('Selection contains orders that have been previously allocated using different Distribution Process Type(s)', 16, 1)
		RETURN -2
		END
	END



	--------------------------------------------------------------------------------------------------------------------------------
	-- Fill the working table
	--------------------------------------------------------------------------------------------------------------------------------
	INSERT INTO #temp_sia_working_tbl(order_no, order_ext, location, part_no, lb_tracking, qty_ordered, qty_assigned, qty_needed, qty_to_alloc)
	SELECT a.order_no, a.order_ext, a.location, b.part_no, b.lb_tracking, FLOOR(SUM(b.ordered)), 
		CEILING(SUM(b.shipped)) + ISNULL((SELECT CEILING(SUM(qty))
					FROM tdc_soft_alloc_tbl(NOLOCK)
					WHERE order_no = a.order_no
					  AND order_ext = a.order_ext
					  AND location = a.location
					  AND part_no = b.part_no), 0),
		FLOOR(SUM(b.ordered)) - CEILING(sum(b.shipped)) - ISNULL((SELECT CEILING(SUM(qty))
					FROM tdc_soft_alloc_tbl(NOLOCK)
					WHERE order_no = a.order_no
					  AND order_ext = a.order_ext
					  AND location = a.location
					  AND part_no = b.part_no), 0),
		0

	  FROM #so_alloc_management a,
		ord_list b(NOLOCK)
	 WHERE a.order_no = b.order_no
	   AND a.order_ext = b.order_ext
	   AND a.location = b.location
	   AND b.part_type = 'P'
	   AND a.sel_flg = -1
	 GROUP BY a.order_no, a.order_ext, a.location, b.part_no, b.lb_tracking 

	INSERT INTO #temp_sia_working_tbl(order_no, order_ext, location, part_no, lb_tracking, qty_ordered, qty_assigned, qty_needed, qty_to_alloc)
	SELECT a.order_no, a.order_ext, a.location, b.kit_part_no, c.lb_tracking, FLOOR(SUM(b.ordered * b.qty_per_kit)), 
		CEILING(SUM(b.kit_picked)) + ISNULL((SELECT CEILING(SUM(qty))
					FROM tdc_soft_alloc_tbl(NOLOCK)
					WHERE order_no = a.order_no
					  AND order_ext = a.order_ext
					  AND location = a.location
					  AND part_no = b.kit_part_no), 0),
		FLOOR(SUM(b.ordered * b.qty_per_kit)) - CEILING(sum(b.kit_picked)) - ISNULL((SELECT CEILING(SUM(qty))
					FROM tdc_soft_alloc_tbl(NOLOCK)
					WHERE order_no = a.order_no
					  AND order_ext = a.order_ext
					  AND location = a.location
					  AND part_no = b.part_no), 0),
		0

	  FROM #so_alloc_management a,
		tdc_ord_list_kit b(NOLOCK),
		inv_master c (NOLOCK)
	 WHERE a.order_no = b.order_no
	   AND a.order_ext = b.order_ext
	   AND a.location = b.location
	   AND b.kit_part_no = c.part_no
	   AND a.sel_flg = -1
	 GROUP BY a.order_no, a.order_ext, a.location, b.part_no, b.kit_part_no, c.lb_tracking 



	IF @method = 'Even'
	BEGIN
		EXEC tdc_plw_sia_even_sp
	END
	ELSE IF @method = 'Weighted'
	BEGIN
		SELECT @ret = 0
		WHILE @ret = 0
		BEGIN
			EXEC @ret = tdc_plw_sia_weighted_sp
		END
	END
	ELSE
	BEGIN
		EXEC tdc_plw_so_save_sp 0, @process_template, @user_id, ''

		RETURN
	END

	--------------------------------------------------------------------------------------------------------------
	-- Clear the errors table
	--------------------------------------------------------------------------------------------------------------
	TRUNCATE TABLE #so_alloc_err
	
	--------------------------------------------------------------------------------------------------------------
	-- Set the flags
	--------------------------------------------------------------------------------------------------------------
	SET @one_for_one_flg = 'Y' 
	SET @one4one_or_cons = 'one4one' 
	
	--------------------------------------------------------------------------------------------------------------
	-- Call the unallocate stored procedure and free the inventory that is to be unallocated
	--------------------------------------------------------------------------------------------------------------
	
	BEGIN TRAN
		EXEC tdc_plw_so_unallocate_sp @user_id, 0
	COMMIT TRAN
	
	
	----------------------------------------------------------------------------------------------------------------------------------
	-- Remove any previous cross dock allocations for the orders selected FROM the #so_alloc_management table to be processed 	--
	----------------------------------------------------------------------------------------------------------------------------------
	BEGIN TRAN
	
		DELETE FROM tdc_soft_alloc_tbl
		WHERE EXISTS (SELECT * FROM #so_alloc_management
			       WHERE tdc_soft_alloc_tbl.order_no   = #so_alloc_management.order_no
		 		 AND tdc_soft_alloc_tbl.order_ext  = #so_alloc_management.order_ext
				 AND tdc_soft_alloc_tbl.location   = #so_alloc_management.location 
				 AND tdc_soft_alloc_tbl.lot_ser    = 'CDOCK' 
				 AND tdc_soft_alloc_tbl.bin_no     = 'CDOCK' 
				 AND tdc_soft_alloc_tbl.order_type = 'S'				
				 AND #so_alloc_management.sel_flg != 0)
			
		DELETE FROM tdc_pick_queue
		WHERE EXISTS (SELECT * FROM #so_alloc_management
			       WHERE tdc_pick_queue.trans_type_no  = #so_alloc_management.order_no
		 		 AND tdc_pick_queue.trans_type_ext = #so_alloc_management.order_ext
				 AND tdc_pick_queue.location       = #so_alloc_management.location 
				 AND tdc_pick_queue.lot            = 'CDOCK' 
				 AND tdc_pick_queue.bin_no         = 'CDOCK' 
				 AND tdc_pick_queue.trans          = 'SO-CDOCK'				
				 AND #so_alloc_management.sel_flg != 0)
	
	COMMIT TRAN
	 
	--------------------------------------------------------------------------------------------------------------
	-- Loop through orders using the passed in order-by clause
	--------------------------------------------------------------------------------------------------------------
	DECLARE sia_alloc_cur CURSOR FOR
		SELECT order_no, order_ext, location, part_no, qty_to_alloc
		  FROM #temp_sia_working_tbl 
		 WHERE qty_to_alloc > 0
	
	OPEN sia_alloc_cur
	FETCH NEXT FROM sia_alloc_cur INTO @order_no, @order_ext, @location, @part_no, @qty_to_alloc

	WHILE (@@FETCH_STATUS = 0)
	BEGIN	

		------------------------------------------------------------------------------------------
		-- Get the user's settings
		------------------------------------------------------------------------------------------
		SELECT @bin_group        = bin_group,
		       @search_sort      = search_sort,
		       @priority         = tran_priority,
		       @user_hold        = on_hold,
		       @cdock_flg        = cdock,
		       @multiple_parts   = multiple_parts,
		       @pass_bin         = pass_bin,
		       @bin_first        = bin_first,
		       @bin_type	 = bin_type,
		       @replen_group	 = replen_group,
		       @pkg_code	 = pkg_code,
		       @assigned_user    = CASE WHEN user_group = '' 
					          OR user_group like '%DEFAULT%' 
					        			THEN NULL
					        ELSE 			     user_group
					   END, 
		       @alloc_type       = CASE dist_type 
					        WHEN 'PrePack' 		THEN 'PR'
					        WHEN 'ConsolePick' 	THEN 'PT'
					        WHEN 'PickPack' 	THEN 'PP'
					        WHEN 'PackageBuilder' 	THEN 'PB'
				           END,
		       @pre_pack_flg     = CASE dist_type 
					        WHEN 'PrePack' 		THEN 'Y' 
					        ELSE 			     'N' 
					   END,
		       @search_type      = CASE ISNULL(bin_type, '')
						WHEN ''			THEN 'AUTOMATIC'
						ELSE			     'MANUAL'
					   END
		  FROM tdc_plw_process_templates (NOLOCK)
		 WHERE template_code  = @process_template
		   AND UserID         = @user_id
		   AND location       = @location
		   AND order_type     = 'S'
		   AND type           = @one4one_or_cons

		SELECT @qty_alloc = 0
		SELECT @qty_alloc = CEILING(SUM(qty))
		  FROM tdc_soft_alloc_tbl
		 WHERE location = @location
		   AND part_no = @part_No

		--------------------------------------------------------------------------------------------------------------
		-- Get the bin sort by based on the bin first option and user selected Bin Sort creteria
		-- Used for one4one and for cons only if Automatic Alloc Search was selected
		--------------------------------------------------------------------------------------------------------------	
		IF (@one4one_or_cons = 'one4one') OR (@one4one_or_cons = 'cons' AND @search_type = 'AUTOMATIC')
		BEGIN
			EXEC dbo.tdc_plw_so_get_bin_sort @one4one_or_cons, @search_sort, @bin_first,  @lbs_order_by OUTPUT
		END
	
		--------------------------------------------------------------------------------------------------------------
		-- Update the cons_ords table and tdc_main
		--------------------------------------------------------------------------------------------------------------	
		IF NOT EXISTS(SELECT * 
			        FROM tdc_cons_ords (NOLOCK)
			       WHERE order_no  = @order_no
				 AND order_ext = @order_ext
			         AND location  = @location)
		BEGIN
			BEGIN TRAN
			
			--------------------------------------------------------------------------------------------------------------
			-- Create a new record in tdc_main and tdc_cons_ords
			--------------------------------------------------------------------------------------------------------------

			-- get the next available cons number
			EXEC @next_con_no = tdc_get_next_consol_num_sp
		
			-- our generic description and name 
			SELECT @con_name = 'Ord ' +  CONVERT(VARCHAR(20), @order_no) + ' Ext ' + CONVERT(VARCHAR(4), @order_ext) 
			SELECT @con_desc = 'Ord ' +  CONVERT(VARCHAR(20), @order_no) + ' Ext ' + CONVERT(VARCHAR(4), @order_ext) 
		 
			-- Insert the new generated con number in tdc_main and tdc_cons_ords
			INSERT INTO tdc_main(consolidation_no, consolidation_name, order_type, [description], status, created_by, creation_date, pre_pack) 
			VALUES (@next_con_no , @con_name, 'S', @con_desc, 'O' , @user_id , GETDATE(), @pre_pack_flg)
		

			INSERT INTO tdc_cons_ords (consolidation_no, order_no, order_ext,location, status, seq_no, print_count, order_type, alloc_type)
			VALUES (@next_con_no, @order_no, @order_ext, @location, 'O', 1 , 0, 'S', @alloc_type)
			
			-- need to update soft_alloc_tbl and set the target bin = to the bin_no
			-- this is a rule that on one to one the bin_no becomes the picking bin
			IF EXISTS(SELECT * FROM tdc_cons_filter_set  (NOLOCK) WHERE consolidation_no = @next_con_no)
			BEGIN
				DELETE FROM tdc_cons_filter_set WHERE consolidation_no = @next_con_no
			END

			-- Insert the record into the cons_filter_set table based on what the user
			-- typed into the filter screen
			INSERT INTO tdc_cons_filter_set(consolidation_no, location, order_status, ship_date_start, ship_date_end,order_range_start,
							order_range_end, ext_range_start, ext_range_end, order_priority_start,order_priority_end, 
							order_priority_range,sold_to, ship_to, territory, carrier, destination_zone, cust_op1, 
							cust_op2, cust_op3, order_no_range, ext_no_range, fill_percent, orderby_1, orderby_2, 
							orderby_3, orderby_4, orderby_5, orderby_6, orderby_7, order_type, ship_to_name, ship_to_city,
							ship_to_state, ship_to_zip, ship_to_country, con_type,opt_one_for_one, -- v1.0
							frame_case_match, orderby_8, orderby_9, order_type_code, consolidate_shipment, delivery_date_start, -- v1.0
							delivery_date_end, user_hold)  -- v1.0
			SELECT @next_con_no, location, order_status, ship_date_start, ship_date_end, order_range_start, order_range_end, ext_range_start,
			       ext_range_end, order_priority_start, order_priority_end, order_priority_range, sold_to, ship_to, territory, carrier, 
			       destination_zone, cust_op1, cust_op2, cust_op3, order_no_range, ext_no_range, fill_percent, orderby_1, orderby_2, 
			       orderby_3, orderby_4,orderby_5,orderby_6,orderby_7, 'S',ship_to_name, ship_to_city, ship_to_state, ship_to_zip, 
			       ship_to_country, con_type,opt_one_for_one, -- v1.0
				   frame_case_match, orderby_8, orderby_9, order_type_code, consolidate_shipment, delivery_date_start, -- v1.0
				   delivery_date_end, user_hold  -- v1.0
			  FROM tdc_user_filter_set 
                         WHERE userid     = @user_id 
                           AND order_type = 'S'			
	
			COMMIT TRAN	

		END --Cons_ords update
		ELSE
		BEGIN
			UPDATE tdc_cons_ords 
		           SET alloc_type = @alloc_type
			 WHERE order_no   = @order_no
			   AND order_ext  = @order_ext
			   AND location   = @location

		END
	
		--------------------------------------------------------------------------------------------------------------
		-- If the part filter is not in use, allocate everything.
		--------------------------------------------------------------------------------------------------------------
		DECLARE alloc_line_cur CURSOR FOR
			SELECT line_no, 'P' 
			  FROM ord_list 
			 WHERE order_no  = @order_no
			   AND order_ext = @order_ext
			   AND location  = @location
			   AND part_no   = @part_no
			   AND part_type = 'P'
 			UNION
			SELECT line_no, 'C'
			  FROM ord_list_kit
			 WHERE order_no = @order_no
			   AND order_ext = @order_ext
			   AND location = @location
			   AND part_no = @part_no

		OPEN alloc_line_cur
		FETCH NEXT FROM alloc_line_cur INTO @line_no, @part_type
		
		WHILE @@FETCH_STATUS = 0
		BEGIN	
			SELECT @max_qty_to_alloc = @qty_to_alloc

			IF @part_type = 'P'
			BEGIN
				SELECT @qty_ordered = FLOOR(ordered),
				       @qty_picked = CEILING(shipped)
				  FROM ord_list
				 WHERE order_no = @order_No
				   AND order_ext = @order_ext
				   AND line_no = @line_No

			END
			ELSE
			BEGIN
				SELECT @qty_ordered = FLOOR(ordered * qty_per_kit),
				       @qty_picked = CEILING(kit_picked)
				  FROM tdc_ord_list_kit
				 WHERE order_no = @order_no
				   AND order_ext = @order_ext
				   AND line_no = @line_no
				   AND kit_part_no = @part_no
			END
			SELECT @qty_needed = @qty_ordered - @qty_picked - @qty_alloc

			IF @qty_needed < @max_qty_to_alloc
				SELECT @max_qty_to_alloc = @qty_needed

			IF @max_qty_to_alloc > 0
			BEGIN
				BEGIN TRAN
	
				EXEC @ret = tdc_plw_so_allocate_line_sp @user_id,         '',         @order_no,    @order_ext,  @line_no,   @part_no,          
									@one_for_one_flg, @bin_group, @search_sort, @alloc_type, @pkg_code,  @replen_group,
									@multiple_parts,  @bin_first, @priority,    @user_hold,  @cdock_flg, @pass_bin, 
									@assigned_user,   @lbs_order_by, @max_qty_to_alloc
				 
				COMMIT TRAN

				SELECT  @qty_to_alloc = @qty_to_alloc - @max_qty_to_alloc
			END
		
			FETCH NEXT FROM alloc_line_cur INTO @line_no, @part_type
		END
	
		CLOSE      alloc_line_cur	
		DEALLOCATE alloc_line_cur
	
		FETCH NEXT FROM sia_alloc_cur INTO @order_no, @order_ext, @location, @part_no, @qty_to_alloc
	END
	
	CLOSE      sia_alloc_cur
	DEALLOCATE sia_alloc_cur
	
	--------------------------------------------------------------------------------------------------------------
	-- Insert the history record
	--------------------------------------------------------------------------------------------------------------
	INSERT INTO tdc_alloc_history_tbl(order_no, order_ext, location, fill_pct, alloc_date, alloc_by, order_type)
	SELECT order_no, order_ext, location, curr_alloc_pct, getdate(), @user_id, 'S'  FROM #so_alloc_management WHERE sel_flg != 0

GO
GRANT EXECUTE ON  [dbo].[tdc_plw_sia_process_sp] TO [public]
GO
