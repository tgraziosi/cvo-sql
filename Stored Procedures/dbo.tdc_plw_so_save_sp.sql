SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- v1.0 CB 01/04/2011 - 14.Planners Workbench - Additional criteria
-- v1.1 CB 13/04/2011 - Future Allocations
-- v10.1 CB 12/07/2012 - CVO-CF-1 - Custom Frame Processing
-- v10.2 CB 14/09/2012 - If allocating by bin group, call standard code
-- v10.3 CB 17/09/2012 - For custom frames - If order has custom frame and regular frame and is ship complete then allocate regular frame - ship complete hold
-- v10.4 CB 21/12/2012 - Issue #1041 - Keep soft alloc in sync
-- v10.5 CB 20/03/2013 - add case flag to cvo_soft_alloc_det
-- v10.6 CB 21/03/2013 - add case adjust to cvo_soft_alloc_det
-- v10.7 CB 09/05/2013 - Performance
-- v10.8 CB 04/07/2013 - Issue #1325 - Keep soft alloc no
-- v10.9 CB 11/09/2013 - Fix issue with duplicate soft alloc records
-- v11.0 CB 04/02/2014 - Issue #1358 - Remove call to ship complete hold
-- v11.1 CB 11/02/2014 - Issue #1452 - Remove call to release date hold
-- v11.2 CB 22/09/2014 - #572 Masterpack - Stock Order Consolidation
-- v11.3 CB 15/01/2015 - Only call consolidation routine if the record is selected
-- v11.4 CB 12/01/2016 - #1586 - When orders are allocated or a picking list printed then update backorder processing
-- v11.5 CB 29/11/2018 - If allocating an extra line after another has been picked the system is adding into soft alloc the picked lines
-- v11.6 CB 04/12/2018 - #1687 Box Type Update

CREATE PROCEDURE [dbo].[tdc_plw_so_save_sp]
			@con_no			   int,
			@template_code		   varchar(20),
			@user_id   		   varchar(50),	
			@passed_in_order_by_clause varchar(255)
			--BEGIN SED003 -- Case Part
			--JVM 04/05/2010			
			,@full_alloc_unalloc INT = 0
			--END   SED003 -- Case Part
AS

DECLARE @order_no 		int,
	@order_ext 		int,
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
	@ret 			int,
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
	@sa_qty				decimal(20,8), -- v10.4
	@alloc_qty			decimal(20,8), -- v10.4
	@new_soft_alloc_no	int -- v10.4

-- v10.7 Start
DECLARE	@row_id				int,
		@last_row_id		int,
		@line_row_id		int,
		@last_line_row_id	int
-- v10.7 End

-- v11.2 Start
DECLARE @stcons_no		int,
		@last_stcons_no	int
-- v11.2 End

-- v10.3 Start
-- Create table for exclusions
IF OBJECT_ID('tempdb..#exclusions') IS NOT NULL
	DROP TABLE #exclusions

CREATE TABLE #exclusions (
	order_no		int,
	order_ext		int,
	has_line_exc	int NULL) 

IF OBJECT_ID('tempdb..#line_exclusions') IS NOT NULL
	DROP TABLE #line_exclusions

CREATE TABLE #line_exclusions (
	order_no		int,
	order_ext		int,
	line_no			int)

UPDATE	a
SET		type_code = CASE WHEN b.type_code IN ('SUN','FRAME') THEN '0' ELSE '1' END 
FROM	#so_allocation_detail_view a
JOIN	inv_master b (NOLOCK)
ON		a.part_no = b.part_no

EXEC dbo.cvo_soft_alloc_CF_check_sp 1

-- v10.3 End

--------------------------------------------------------------------------------------------------------------
-- Clear the errors table
--------------------------------------------------------------------------------------------------------------
TRUNCATE TABLE #so_alloc_err

--------------------------------------------------------------------------------------------------------------
-- Set the flags
--------------------------------------------------------------------------------------------------------------
SET @one_for_one_flg = CASE WHEN @con_no = 0 THEN 'Y'       ELSE 'N'    END
SET @one4one_or_cons = CASE WHEN @con_no = 0 THEN 'one4one' ELSE 'cons' END

-- v1.1 Start - Unmark any records where the allocation date is in the future
UPDATE	a
SET		sel_flg = 0
FROM	#so_alloc_management a
JOIN	dbo.cvo_orders_all b (NOLOCK)
ON		a.order_no = b.order_no
AND		a.order_ext = b.ext
WHERE	ISNULL(b.allocation_date,GETDATE()-1) > GETDATE()
-- v1.1 End

--------------------------------------------------------------------------------------------------------------
-- Call the unallocate stored procedure and free the inventory that is to be unallocated
--------------------------------------------------------------------------------------------------------------

BEGIN TRAN
	EXEC tdc_plw_so_unallocate_sp @user_id, @con_no 
COMMIT TRAN


----------------------------------------------------------------------------------------------------------------------------------
-- Remove any previous cross dock allocations for the orders selected FROM the #so_alloc_management table to be processed 	--
----------------------------------------------------------------------------------------------------------------------------------
BEGIN TRAN
	--BEGIN SED003 -- Case Part
	--JVM 04/05/2010
	IF @full_alloc_unalloc = 1
	BEGIN 	
		DELETE cvo 
		FROM   CVO_qty_to_alloc_tbl cvo, #so_alloc_management so
		WHERE  cvo.order_no	 = so.order_no	AND
			   cvo.order_ext = so.order_ext	AND
			   cvo.location	 = so.location	AND
			   so.sel_flg2   = -1
	END
	--END   SED003 -- Case Part
	
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

	DELETE FROM tdc_cdock_mgt
	WHERE EXISTS (SELECT * FROM #so_alloc_management
		       WHERE tdc_cdock_mgt.tran_no  = CAST(#so_alloc_management.order_no AS VARCHAR)
	 		 AND ISNULL(tdc_cdock_mgt.tran_ext, 0) = #so_alloc_management.order_ext
			 AND tdc_cdock_mgt.location       = #so_alloc_management.location 
			 AND tdc_cdock_mgt.tran_type          = 'SO-CDOCK'				
			 AND #so_alloc_management.sel_flg != 0)

COMMIT TRAN


--------------------------------------------------------------------------------------------------------------
-- Loop through orders using the passed in order-by clause
--------------------------------------------------------------------------------------------------------------
-- v10.7 Start
CREATE TABLE #plw_selected_orders_cur (
		row_id		int IDENTITY(1,1),
		order_no	int,
		order_ext	int,
		location	varchar(10))

CREATE TABLE #plw_alloc_line_cur (
		line_row_id		int IDENTITY(1,1),
		line_no			int,
		part_no			varchar(30))

SELECT @declare_clause = 'INSERT #plw_selected_orders_cur (order_no, order_ext, location) 
			  	SELECT order_no, order_ext, location FROM #so_alloc_management WHERE sel_flg <> 0 ' + 
				@passed_in_order_by_clause 

--SELECT @declare_clause = 'DECLARE selected_orders_cur CURSOR FOR
--			  	SELECT order_no, order_ext, location FROM #so_alloc_management WHERE sel_flg <> 0 ' + 
--				@passed_in_order_by_clause 
 
EXEC (@declare_clause)

CREATE INDEX #plw_selected_orders_cur_ind0 ON #plw_selected_orders_cur(row_id)

--OPEN selected_orders_cur
--FETCH NEXT FROM selected_orders_cur INTO @order_no, @order_ext, @location
--
--WHILE (@@FETCH_STATUS = 0)
--BEGIN	

SET	@last_row_id = 0

SELECT	TOP 1 @row_id = row_id,
		@order_no = order_no,
		@order_ext = order_ext,
		@location = location
FROM	#plw_selected_orders_cur
WHERE	row_id > @last_row_id
ORDER BY row_id ASC

WHILE (@@ROWCOUNT <> 0)
BEGIN
-- v10.7 End
	------------------------------------------------------------------------------------------
	-- Get the user's settings
	------------------------------------------------------------------------------------------
	-- v10.1 Start - Do not allow allocation if the custom frame is not fully available
	IF EXISTS (SELECT 1 FROM #so_alloc_management WHERE order_no = @order_no AND order_ext = @order_ext AND cf = 'Y' AND curr_fill_pct < 100 AND cust_flg <> 1)
	BEGIN
		-- v10.7 Start
		SET	@last_row_id = @row_id

		SELECT	TOP 1 @row_id = row_id,
				@order_no = order_no,
				@order_ext = order_ext,
				@location = location
		FROM	#plw_selected_orders_cur
		WHERE	row_id > @last_row_id
		ORDER BY row_id ASC

		IF (@@ROWCOUNT = 0)
			BREAK

--		FETCH NEXT FROM selected_orders_cur INTO @order_no, @order_ext, @location
--		IF (@@FETCH_STATUS <> 0)
--			BREAK
		-- v10.7 End
	END
	-- v10.1 End

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
	 WHERE template_code  = @template_code
	   AND UserID         = @user_id
	   AND location       = @location
	   AND order_type     = 'S'
	   AND type           = @one4one_or_cons


	IF @alloc_type = 'PB'
	BEGIN
		IF EXISTS (SELECT * FROM tdc_config (NOLOCK) WHERE [function] = 'pallet_loadseq_nullable' AND value_str = 'Epicor')
		BEGIN
			IF NOT EXISTS (SELECT * FROM load_list (NOLOCK) WHERE order_no = @order_no AND order_ext = @order_ext)
			BEGIN
				SET @user_hold = 'Y'
			END
		END
	END

	--------------------------------------------------------------------------------------------------------------
	-- Get the bin sort by based on the bin first option and user selected Bin Sort creteria
	-- Used for one4one and for cons only if Automatic Alloc Search was selected
	--------------------------------------------------------------------------------------------------------------	
	IF (@one4one_or_cons = 'one4one') OR (@one4one_or_cons = 'cons' AND @search_type = 'AUTOMATIC')
	BEGIN
		EXEC dbo.tdc_plw_so_get_bin_sort @search_sort, @bin_first,  @lbs_order_by OUTPUT
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

		IF @con_no = 0 --ONE_FOR_ONE
		BEGIN			
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
			  FROM tdc_user_filter_set (NOLOCK)
                         WHERE userid     = @user_id 
                           AND order_type = 'S'
		END
		------------------------------------------------------------------------------------------------------------------
		ELSE --NOT ONE_FOR_ONE
		------------------------------------------------------------------------------------------------------------------
		BEGIN		
			--------------------------------------------------------------------------------------------------------------
			-- Create a new record in tdc_main and tdc_cons_ords
			--------------------------------------------------------------------------------------------------------------
			IF EXISTS(SELECT * FROM tdc_main (NOLOCK) WHERE consolidation_no = @con_no)
			BEGIN
				IF EXISTS (SELECT * FROM tdc_cons_ords (NOLOCK) WHERE consolidation_no = @con_no AND alloc_type = 'PR')
					UPDATE tdc_main SET pre_pack = 'Y' WHERE consolidation_no = @con_no
				ELSE
					UPDATE tdc_main SET pre_pack = @pre_pack_flg WHERE consolidation_no = @con_no
			END

			SELECT @con_seq_no  = @con_seq_no + 1	
			SELECT @next_con_no = @con_no
	
			INSERT INTO tdc_cons_ords (consolidation_no, order_no,order_ext,location,status,seq_no,print_count,order_type, alloc_type)
			VALUES (@con_no, @order_no, @order_ext, @location, 'O', @con_seq_no , 0, 'S', @alloc_type)
			
			INSERT INTO tdc_log (tran_date, UserID, trans_source, module, trans,tran_no , tran_ext, part_no, lot_ser, bin_no, location, quantity, data)
			VALUES (getdate(), @user_id , 'VB', 'PLW' , 'Allocation', @con_no, 0, '', '', '', @location, '', 'ADD order number = ' + CONVERT(VARCHAR(10),@order_no) + '-' + CONVERT(VARCHAR(10),@order_ext))			
		END --Not ONE_FOR_ONE	

		COMMIT TRAN	
	END --Cons_ords update
	ELSE
	BEGIN
		UPDATE tdc_cons_ords 
	           SET alloc_type = @alloc_type
		 WHERE order_no   = @order_no
		   AND order_ext  = @order_ext
		   AND location   = @location

		UPDATE tdc_main SET pre_pack = @pre_pack_flg WHERE consolidation_no = @con_no
	END

	
	DELETE #plw_alloc_line_cur -- v10.7

	--------------------------------------------------------------------------------------------------------------
	-- Loop through the lines in the detail view temp table for the selected orders and allocate them.
	--------------------------------------------------------------------------------------------------------------
	IF EXISTS (SELECT * FROM tdc_plw_alloc_template_part_filter (NOLOCK) 
		    WHERE userid        = @user_id
		      AND location      = @location
		      AND order_type    = 'S'
		      AND template_code = @template_code) 
	   AND @con_no > 0
	BEGIN	
		--------------------------------------------------------------------------------------------------------------
		-- If the part filter is in use, join to the filter table
		--------------------------------------------------------------------------------------------------------------
		-- v10.7 Start
		INSERT	#plw_alloc_line_cur (line_no, part_no)
			SELECT a.line_no, a.part_no
			  FROM #so_allocation_detail_view 	  a,
			       tdc_plw_alloc_template_part_filter b (NOLOCK)
			 WHERE a.order_no      = @order_no
			   AND a.order_ext     = @order_ext
			   AND a.location      = @location
			   AND b.userid        = @user_id
			   AND b.order_type    = 'S'
		      	   AND b.template_code = @template_code
			   AND b.location      = a.location
			   AND b.part_no       = a.part_no
			 ORDER BY type_code ASC, a.line_no, a.part_no -- v10.3 Force order to do frames first

--		DECLARE alloc_line_cur 	CURSOR FOR
--			SELECT a.line_no, a.part_no
--			  FROM #so_allocation_detail_view 	  a,
--			       tdc_plw_alloc_template_part_filter b (NOLOCK)
--			 WHERE a.order_no      = @order_no
--			   AND a.order_ext     = @order_ext
--			   AND a.location      = @location
--			   AND b.userid        = @user_id
--			   AND b.order_type    = 'S'
--		      	   AND b.template_code = @template_code
--			   AND b.location      = a.location
--			   AND b.part_no       = a.part_no
--			 ORDER BY type_code ASC, a.line_no, a.part_no -- v10.3 Force order to do frames first
	END
	ELSE
	BEGIN
		--------------------------------------------------------------------------------------------------------------
		-- If the part filter is not in use, allocate everything.
		--------------------------------------------------------------------------------------------------------------
		INSERT	#plw_alloc_line_cur (line_no, part_no)
			SELECT line_no, part_no
			  FROM #so_allocation_detail_view 
			 WHERE order_no  = @order_no
			   AND order_ext = @order_ext
			   AND location  = @location
			 ORDER BY type_code ASC, line_no, part_no -- v10.3 Force order to do frames first

--		DECLARE alloc_line_cur CURSOR FOR
--			SELECT line_no, part_no
--			  FROM #so_allocation_detail_view 
--			 WHERE order_no  = @order_no
--			   AND order_ext = @order_ext
--			   AND location  = @location
--			 ORDER BY type_code ASC, line_no, part_no -- v10.3 Force order to do frames first
	END

	SET @last_line_row_id = 0

	SELECT	TOP 1 @line_row_id = line_row_id,
			@line_no = line_no,
			@part_no = part_no
	FROM	#plw_alloc_line_cur
	WHERE	line_row_id > @last_line_row_id
	ORDER BY line_row_id ASC

	WHILE (@@ROWCOUNT <> 0)
	BEGIN

--	OPEN alloc_line_cur
--	FETCH NEXT FROM alloc_line_cur INTO @line_no, @part_no
	
--	WHILE @@FETCH_STATUS = 0
--	BEGIN				
-- v10.7 End

		-- v10.3 Start - Check line is not excluded
		IF EXISTS (SELECT 1 FROM #line_exclusions WHERE order_no = @order_no AND order_ext = @order_ext AND line_no = @line_no)
		BEGIN
			-- v10.7 Start

			SET @last_line_row_id = @line_row_id

			SELECT	TOP 1 @line_row_id = line_row_id,
					@line_no = line_no,
					@part_no = part_no
			FROM	#plw_alloc_line_cur
			WHERE	line_row_id > @last_line_row_id
			ORDER BY line_row_id ASC

			IF (@@ROWCOUNT = 0)
				BREAK

--			FETCH NEXT FROM alloc_line_cur INTO @line_no, @part_no
--			IF @@FETCH_STATUS <> 0
--				BREAK
			-- v10.7
		END
		-- v10.3 End


		BEGIN TRAN 
		--BEGIN SED009 -- AutoAllocation    
		--JVM 07/09/2010      		
		--pass allocate control to CVO_allocate_by_bin_group_sp
		IF @bin_group <> '[ALL]' -- v10.3 Start
		BEGIN

			EXEC @ret = tdc_plw_so_allocate_line_sp @user_id,         @template_code, @order_no,    @order_ext,  @line_no,   @part_no,          
								@one_for_one_flg, @bin_group, @search_sort, @alloc_type, @pkg_code,  @replen_group,
								@multiple_parts,  @bin_first, @priority,    @user_hold,  @cdock_flg, @pass_bin, 
								@assigned_user,   @lbs_order_by
								--BEGIN SED003 -- Case Part
								--JVM 04/05/2010
								  --, 0 -- Default @lbs_order_by
								  --, 1 --         @max_qty_to_alloc
								--END   SED003 -- Case Part
		END
		ELSE
		BEGIN
			EXEC @ret = CVO_allocate_by_bin_group_sp @user_id,         @template_code, @order_no,    @order_ext,  @line_no,   @part_no,          
								@one_for_one_flg, @bin_group, @search_sort, @alloc_type, @pkg_code,  @replen_group,
								@multiple_parts,  @bin_first, @priority,    @user_hold,  @cdock_flg, @pass_bin, 
								@assigned_user,   @lbs_order_by	
		END -- v10.3 End
		--END   SED009 -- AutoAllocation  																

		COMMIT TRAN			

		-- v10.7 Start
		SET @last_line_row_id = @line_row_id

		SELECT	TOP 1 @line_row_id = line_row_id,
				@line_no = line_no,
				@part_no = part_no
		FROM	#plw_alloc_line_cur
		WHERE	line_row_id > @last_line_row_id
		ORDER BY line_row_id ASC

--		FETCH NEXT FROM alloc_line_cur INTO @line_no, @part_no
	END

--	CLOSE      alloc_line_cur	
--	DEALLOCATE alloc_line_cur
-- v10.7 End


	-- v10.1 Start - If custom frame then create other queue transactions and print works order and pick ticket
	IF EXISTS(SELECT * FROM CVO_ord_list (NOLOCK) WHERE order_no = @order_no AND order_ext = @order_ext AND is_customized = 'S') 
	BEGIN
		-- v1.4
		IF EXISTS (SELECT 1 FROM tdc_soft_alloc_tbl (NOLOCK) WHERE order_no = @order_no AND order_ext = @order_ext AND order_type = 'S')
		BEGIN
--			IF NOT EXISTS (SELECT * FROM dbo.tdc_config WHERE [function] = 'mod_ebo_inv')
--					INSERT INTO tdc_config ([function],mod_owner, description, active) VALUES ('mod_ebo_inv','EBO','Allow modify inventory from eBO','Y')	

			-- v10.3 Start - Check line is not excluded
			IF NOT EXISTS (SELECT 1 FROM #line_exclusions WHERE order_no = @order_no AND order_ext = @order_ext) -- Stop WO print as queue trans will be on hold
			BEGIN

				-- v10.1 Start
				EXEC dbo.CVO_Create_Frame_Bin_Moves_sp @order_no, @order_ext

				UPDATE dbo.cvo_ord_list_kit SET location = location WHERE order_no = @order_no AND order_ext = @order_ext
				-- v10.1 End

				IF (OBJECT_ID('tempdb..#PrintData') IS NOT NULL) 
					DROP TABLE #PrintData

				CREATE TABLE #PrintData 
				(row_id			INT IDENTITY (1,1)	NOT NULL
				,data_field		VARCHAR(300)		NOT NULL
				,data_value		VARCHAR(300)			NULL)
				
				EXEC CVO_disassembled_frame_sp @order_no, @order_ext
				
				EXEC CVO_disassembled_inv_adjust_sp @order_no, @order_ext
					
				EXEC CVO_disassembled_print_inv_adjust_sp @order_no, @order_ext		
					
				UPDATE	cvo_orders_all 
				SET		flag_print = 2 
				WHERE	order_no = @order_no 
				AND		 ext = @order_ext

	--			DELETE FROM dbo.tdc_config WHERE [function] = 'mod_ebo_inv'
							
				-- v1.5 Start
				EXEC dbo.cvo_print_pick_ticket_sp @order_no, @order_ext
				-- v1.5 End 
			END -- v10.3
		END -- v1.4					

	END


	-- v10.4 Start

	CREATE TABLE #tmp_alloc (
			line_no		int,
			qty			decimal(20,8))

	SELECT	@alloc_qty = SUM(qty) 
	FROM	tdc_soft_alloc_tbl (NOLOCK)
	WHERE	order_no = @order_no
	AND		order_ext= @order_ext

	IF (@alloc_qty IS NULL)
		SET @alloc_qty = 0

	INSERT	#tmp_alloc
	SELECT	line_no, SUM(qty)
	FROM	tdc_soft_alloc_tbl (NOLOCK)
	WHERE	order_no = @order_no
	AND		order_ext= @order_ext
	GROUP BY line_no

	SELECT	@sa_qty = SUM(ordered)
	FROM	ord_list (NOLOCK)
	WHERE	order_no = @order_no
	AND		order_ext= @order_ext

	IF	(@sa_qty = @alloc_qty) -- Line Fully allocated
	BEGIN

		UPDATE	cvo_soft_alloc_det
		SET		status = -2
		WHERE	order_no = @order_no
		AND		order_ext= @order_ext
		AND		status IN (0,-1,-3)
		
		IF NOT EXISTS (SELECT 1 FROM cvo_soft_alloc_det (NOLOCK) WHERE order_no = @order_no AND order_ext= @order_ext AND status IN (0,-1,-3))
		BEGIN
			UPDATE	cvo_soft_alloc_hdr
			SET		status = -2
			WHERE	order_no = @order_no
			AND		order_ext= @order_ext
			AND		status IN (0,-1,-3)
		END

		-- v10.8 Start
		DELETE	cvo_soft_alloc_hdr 
		WHERE	order_no = @order_no
		AND		order_ext = @order_ext
		AND		status = -2 

		DELETE	cvo_soft_alloc_det
		WHERE	order_no = @order_no
		AND		order_ext = @order_ext
		AND		status = -2 
		-- v10.8 End
	END
	ELSE
	BEGIN
		IF (@alloc_qty > 0) -- Lines partially allocated
		BEGIN

			UPDATE	cvo_soft_alloc_hdr
			SET		status = -2
			WHERE	order_no = @order_no
			AND		order_ext= @order_ext
			AND		status IN (0,-1,-3)

			UPDATE	cvo_soft_alloc_det
			SET		status = -2
			WHERE	order_no = @order_no
			AND		order_ext= @order_ext				
			AND		status IN (0,-1,-3)

			-- v10.8 Start
			DELETE	cvo_soft_alloc_hdr 
			WHERE	order_no = @order_no
			AND		order_ext = @order_ext
			AND		status = -2 

			DELETE	cvo_soft_alloc_det
			WHERE	order_no = @order_no
			AND		order_ext = @order_ext
			AND		status = -2 
		
			SET	@new_soft_alloc_no = NULL

			SELECT	@new_soft_alloc_no = soft_alloc_no
			FROM	cvo_soft_alloc_no_assign (NOLOCK)
			WHERE	order_no = @order_no
			AND		order_ext = @order_ext

			IF (@new_soft_alloc_no IS NULL)
			BEGIN
				BEGIN TRAN
					UPDATE	dbo.cvo_soft_alloc_next_no
					SET		next_no = next_no + 1
				COMMIT TRAN	
				SELECT	@new_soft_alloc_no = next_no
				FROM	dbo.cvo_soft_alloc_next_no

				-- v10.9 Start
				INSERT cvo_soft_alloc_no_assign (order_no, order_ext, soft_alloc_no)
				SELECT @order_no, @order_ext, @new_soft_alloc_no
				-- v10.9 End

			END
			-- v10.8 End

			-- Insert cvo_soft_alloc header
			-- v10.9 Start
			IF NOT EXISTS (SELECT 1 FROM cvo_soft_alloc_hdr (NOLOCK) WHERE order_no = @order_no AND order_ext = @order_ext)
			BEGIN
				INSERT INTO cvo_soft_alloc_hdr (soft_alloc_no, order_no, order_ext, location, bo_hold, status)
				VALUES (@new_soft_alloc_no, @order_no, @order_ext, @location, 0, 0)		
			END
			-- v10.9 End

			-- v10.9 Start
			DELETE	cvo_soft_alloc_det WHERE order_no = @order_no AND order_ext = @order_ext
			-- v10.9 End

			INSERT INTO	dbo.cvo_soft_alloc_det (soft_alloc_no, order_no, order_ext, line_no, location, part_no, quantity,  
										kit_part, change, deleted, is_case, is_pattern, is_pop_gift, status, add_case_flag)	-- 10.5		
			SELECT	@new_soft_alloc_no, @order_no, @order_ext, a.line_no, a.location, a.part_no, (a.ordered - ISNULL(c.qty,0)),
					0, 0, 0, b.is_case, b.is_pattern, b.is_pop_gif, 0, b.add_case -- v10.5
			FROM	ord_list a (NOLOCK)
			JOIN	cvo_ord_list b (NOLOCK)
			ON		a.order_no = b.order_no
			AND		a.order_ext = b.order_ext
			AND		a.line_no = b.line_no
			LEFT JOIN
					#tmp_alloc c (NOLOCK)
			ON		a.line_no = c.line_no			
			WHERE	a.order_no = @order_no
			AND		a.order_ext = @order_ext
			AND		((a.ordered - a.shipped) - ISNULL(c.qty,0)) > 0 -- v11.5
			-- v11.5 AND		(a.ordered - ISNULL(c.qty,0)) > 0

			-- v10.6
			EXEC dbo.cvo_update_soft_alloc_case_adjust_sp @new_soft_alloc_no, @order_no, @order_ext

			INSERT INTO	dbo.cvo_soft_alloc_det (soft_alloc_no, order_no, order_ext, line_no, location, part_no, quantity,  
										kit_part, change, deleted, is_case, is_pattern, is_pop_gift, status)			
			SELECT	@new_soft_alloc_no, @order_no, @order_ext, a.line_no, a.location, b.part_no, (a.ordered - ISNULL(c.qty,0)),
					1, 0, 0, 0, 0, 0, 0
			FROM	ord_list a (NOLOCK)
			JOIN	cvo_ord_list_kit b (NOLOCK)
			ON		a.order_no = b.order_no
			AND		a.order_ext = b.order_ext
			AND		a.line_no = b.line_no
			LEFT JOIN
					#tmp_alloc c (NOLOCK)
			ON		a.line_no = c.line_no
			WHERE	a.order_no = @order_no
			AND		a.order_ext = @order_ext	
			AND		b.replaced = 'S'	
			AND		((a.ordered - a.shipped) - ISNULL(c.qty,0)) > 0	-- v11.5
			-- v11.5 AND		(a.ordered - ISNULL(c.qty,0)) > 0	
		END

	END

	DROP TABLE #tmp_alloc
	-- v10.4 End

	
	-- v10.7 Start
-- v11.1	EXEC dbo.cvo_hold_rel_date_allocations_sp @order_no, @order_ext -- moved from tdc_plw_so_alloc_management_sp
-- v11.0	EXEC dbo.cvo_hold_ship_complete_allocations_sp @order_no, @order_ext -- moved from tdc_plw_so_alloc_management_sp

	-- v11.4 Start
	EXEC dbo.cvo_update_bo_processing_sp 'A', @order_no, @order_ext
	-- v11.4 End

	-- v11.6 Start
	EXEC dbo.cvo_calculate_packaging_sp	@order_no, @order_ext, 'S'
		-- v11.6 End


	SET	@last_row_id = @row_id

	SELECT	TOP 1 @row_id = row_id,
			@order_no = order_no,
			@order_ext = order_ext,
			@location = location
	FROM	#plw_selected_orders_cur
	WHERE	row_id > @last_row_id
	ORDER BY row_id ASC

--	FETCH NEXT FROM selected_orders_cur INTO @order_no, @order_ext, @location

END

--CLOSE      selected_orders_cur
--DEALLOCATE selected_orders_cur
DROP TABLE  #plw_selected_orders_cur
DROP TABLE #plw_alloc_line_cur

-- v11.2 Start
CREATE TABLE #consolidate_picks(
		consolidation_no	int,
		order_no			int,
		ext					int)

SET @last_stcons_no = 0

SELECT	TOP 1 @stcons_no = mp_consolidation_no
FROM	#so_alloc_management
WHERE	mp_consolidation_no > ''
AND		sel_flg <> 0 -- v11.3
AND		mp_consolidation_no > @last_stcons_no
ORDER BY mp_consolidation_no ASC

WHILE (@@ROWCOUNT <> 0)
BEGIN

	DELETE #consolidate_picks

	INSERT	#consolidate_picks
	SELECT	@stcons_no, order_no, order_ext
	FROM	cvo_masterpack_consolidation_det (NOLOCK)
	WHERE	consolidation_no = @stcons_no

	EXEC dbo.cvo_masterpack_consolidate_pick_records_sp @stcons_no

	SET @last_stcons_no = @stcons_no

	SELECT	TOP 1 @stcons_no = mp_consolidation_no
	FROM	#so_alloc_management
	WHERE	mp_consolidation_no > ''
	AND		sel_flg <> 0 -- v11.3
	AND		mp_consolidation_no > @last_stcons_no
	ORDER BY mp_consolidation_no ASC

END

DROP TABLE #consolidate_picks
-- v11.2 End

EXEC dbo.CVO_Consolidate_Pick_queue_sp -- moved from tdc_plw_so_alloc_management_sp

-- v10.7 End
--------------------------------------------------------------------------------------------------------------
-- Insert the history record
--------------------------------------------------------------------------------------------------------------
INSERT INTO tdc_alloc_history_tbl(order_no, order_ext, location, fill_pct, alloc_date, alloc_by, order_type)
SELECT order_no, order_ext, location, curr_alloc_pct, getdate(), @user_id, 'S'  FROM #so_alloc_management WHERE sel_flg != 0


GO

GRANT EXECUTE ON  [dbo].[tdc_plw_so_save_sp] TO [public]
GO
