SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROC [dbo].[tdc_plw_so_allocate_selected_lines]  
 @user_id varchar(50),  
 @template_code varchar(20),  
 @con_no  int  
  
AS  

-- v1.0 CB 01/04/2011 - 14.Planners Workbench - Additional criteria
-- v1.1 CT 18/09/2012 - Call autopack routine
-- v1.2 CB 21/12/2012 - When allocating by line update cvo_soft_alloc just for the lines affected
-- v1.3 CB 09/01/2013 - Issue #1067 - Implement custom frame processing for allocate by line
-- v1.4 CB 20/03/2013 - add case_flag to cvo_soft_alloc_det
-- v1.5 CB 21/03/2013 - add case adjust to cvo_soft_alloc_det
-- v1.6 CB 06/06/2013 - Issue #1286 - Ship complete processing
-- v1.7 CB 04/07/2013 - Issue #1325 - Keep soft alloc no
-- v1.8 CB 04/02/2014 - Issue #1358 - Remove call to ship complete hold
-- v1.9 CB 31/07/2015 - Rebuild consolidated picks
-- v2.0 CB 12/01/2016 - #1586 - When orders are allocated or a picking list printed then update backorder processing
-- v2.1 CB 04/12/2018 - #1687 Box Type Update
  
DECLARE @order_no  int,  
 @order_ext  int,  
 @line_no  int,  
 @part_no  varchar(30),  
 @location  varchar(10),  
 @next_con_no  int,  
 @con_name  varchar(20),  
 @con_desc  varchar(255),  
 @con_seq_no   int,   
 @pre_pack_flg  char(1),  
 @alloc_type  varchar(2),  
 @one4one  char(1),
 @rec_key  INT, -- v1.1
 @sa_qty	decimal(20,8), -- v1.2
 @alloc_qty decimal(20,8), -- v1.2
 @new_soft_alloc_no int, -- v1.2
 @iRet int, -- v1.6
 @consolidation_no int -- v1.9

  
IF (NOT EXISTS(SELECT * FROM #so_alloc_management WHERE sel_flg <> 0)) AND (NOT EXISTS(SELECT * FROM #so_soft_alloc_byline_tbl) )  
	RETURN  

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

-- v1.9 Start
IF OBJECT_ID('tempdb..#consolidate_picks') IS NOT NULL
	DROP TABLE #consolidate_picks

CREATE TABLE #consolidate_picks(  
	consolidation_no	int,  
	order_no			int,  
	ext					int)  	
-- v1.9 End


UPDATE	a
SET		type_code = CASE WHEN b.type_code IN ('SUN','FRAME') THEN '0' ELSE '1' END 
FROM	#so_allocation_detail_view a
JOIN	inv_master b (NOLOCK)
ON		a.part_no = b.part_no

EXEC dbo.cvo_soft_alloc_CF_check_sp 1

IF EXISTS (SELECT 1 FROM #line_exclusions WHERE order_no = @order_no AND order_ext = @order_ext AND line_no = @line_no)
BEGIN
	RETURN
END

-- v10.3 End
  
SET @one4one = CASE @con_no WHEN 0 THEN 'Y' ELSE 'N' END  
  
DECLARE allocate_cursor CURSOR FOR  
 SELECT order_no, order_ext, line_no, part_no FROM #so_soft_alloc_byline_tbl ORDER BY line_no  
  
 OPEN allocate_cursor  
 FETCH NEXT FROM allocate_cursor INTO @order_no, @order_ext, @line_no, @part_no  
  
 WHILE @@FETCH_STATUS = 0  
 BEGIN  
	--BEGIN SED009 -- AutoAllocation    
	--JVM 07/09/2010   		
     /*EXEC tdc_plw_so_allocate_line_sp @user_id, @template_code, @order_no, @order_ext, @line_no, @part_no, @one4one,  
                 NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL
				--BEGIN SED003 -- Case Part
				--JVM 04/05/2010
				  --, 0 -- Default @lbs_order_by
				  --, 1 --         @max_qty_to_alloc
				--END   SED003 -- Case Part*/
		 EXEC CVO_allocate_by_bin_group_sp @user_id, @template_code, @order_no, @order_ext, @line_no, @part_no, @one4one,  
					 NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL					
	--END   SED009 -- AutoAllocation    

   -- v1.3 Start
	IF EXISTS(SELECT * FROM CVO_ord_list (NOLOCK) WHERE order_no = @order_no AND order_ext = @order_ext AND is_customized = 'S') 
	BEGIN
		IF EXISTS (SELECT 1 FROM tdc_soft_alloc_tbl (NOLOCK) WHERE order_no = @order_no AND order_ext = @order_ext AND order_type = 'S')
		BEGIN
			-- Check line is not excluded
			IF NOT EXISTS (SELECT 1 FROM #line_exclusions WHERE order_no = @order_no AND order_ext = @order_ext) -- Stop WO print as queue trans will be on hold
			BEGIN

				EXEC dbo.CVO_Create_Frame_Bin_Moves_sp @order_no, @order_ext

				UPDATE dbo.cvo_ord_list_kit SET location = location WHERE order_no = @order_no AND order_ext = @order_ext
				
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
						
				EXEC dbo.cvo_print_pick_ticket_sp @order_no, @order_ext

			END 
		END 
	END
  -- v1.3 End

  SELECT @location = location  
                  FROM ord_list (NOLOCK)  
                 WHERE order_no  = @order_no  
                   AND order_ext = @order_ext  
     AND line_no   = @line_no  


	-- v1.2 Start
	CREATE TABLE #tmp_alloc (
			line_no		int,
			qty			decimal(20,8))

	SELECT	@alloc_qty = SUM(qty) 
	FROM	tdc_soft_alloc_tbl (NOLOCK)
	WHERE	order_no = @order_no
	AND		order_ext= @order_ext
	AND		line_no = @line_no
	AND		part_no = @part_no

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
	AND		line_no = @line_no
	AND		part_no = @part_no

	IF	(@sa_qty = @alloc_qty) -- Line Fully allocated
	BEGIN

		UPDATE	cvo_soft_alloc_det
		SET		status = -2
		WHERE	order_no = @order_no
		AND		order_ext= @order_ext
		AND		line_no = @line_no
		AND		part_no = @part_no
		AND		status IN (0,-1,-3)
		
		IF NOT EXISTS (SELECT 1 FROM cvo_soft_alloc_det (NOLOCK) WHERE order_no = @order_no AND order_ext= @order_ext AND status IN (0,-1,-3))
		BEGIN
			UPDATE	cvo_soft_alloc_hdr
			SET		status = -2
			WHERE	order_no = @order_no
			AND		order_ext= @order_ext
			AND		status IN (0,-1,-3)
		END

		-- v1.7 Start
		DELETE	cvo_soft_alloc_hdr 
		WHERE	order_no = @order_no
		AND		order_ext = @order_ext
		AND		status = -2 

		DELETE	cvo_soft_alloc_det
		WHERE	order_no = @order_no
		AND		order_ext = @order_ext
		AND		status = -2 
		-- v1.7 End
	END
	ELSE
	BEGIN
		IF (@alloc_qty > 0) -- Line partially allocated
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

			-- v1.7 Start
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
			END
			-- v1.7 End

			-- Insert cvo_soft_alloc header
			INSERT INTO cvo_soft_alloc_hdr (soft_alloc_no, order_no, order_ext, location, bo_hold, status)
			VALUES (@new_soft_alloc_no, @order_no, @order_ext, @location, 0, 0)		

			INSERT INTO	dbo.cvo_soft_alloc_det (soft_alloc_no, order_no, order_ext, line_no, location, part_no, quantity,  
										kit_part, change, deleted, is_case, is_pattern, is_pop_gift, status, add_case_flag)	-- v1.4		
			SELECT	@new_soft_alloc_no, @order_no, @order_ext, a.line_no, a.location, a.part_no, (a.ordered - ISNULL(c.qty,0)),
					0, 0, 0, b.is_case, b.is_pattern, b.is_pop_gif, 0, b.add_case -- v1.4
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
			AND		(a.ordered - ISNULL(c.qty,0)) > 0

			-- v1.5
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
			AND		a.line_no = c.line_no
			WHERE	a.order_no = @order_no
			AND		a.order_ext = @order_ext	
			AND		b.replaced = 'S'
			AND		(a.ordered - ISNULL(c.qty,0)) > 0		
		END

	END

	DROP TABLE #tmp_alloc
	-- v1.2 End


  
  SELECT @pre_pack_flg = CASE dist_type   
             WHEN 'PrePack' THEN 'Y'  
      ELSE      'N'  
                  END,  
         @alloc_type  = CASE dist_type   
             WHEN 'PrePack'   THEN 'PR'  
             WHEN 'ConsolePick'  THEN 'PT'  
             WHEN 'PickPack'  THEN 'PP'  
             WHEN 'PackageBuilder'  THEN 'PB'  
               END  
    FROM tdc_plw_process_templates (NOLOCK)  
   WHERE template_code = @template_code  
     AND userid        = @user_id  
     AND location      = @location  
     AND order_type    = 'S'  
                   AND type          = CASE @one4one WHEN 'Y' THEN 'one4one' ELSE 'cons' END  
  
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
    
   ------------------------------------------------------------------------------------------------------------------  
   IF @one4one = 'Y' --ONE_FOR_ONE  
   ------------------------------------------------------------------------------------------------------------------  
   BEGIN     
    -- create a new record in tdc_main   
    -- get the next available cons number  
    EXEC @next_con_no = tdc_get_next_consol_num_sp  
     
    --our generic description and name   
    SELECT @con_name = 'Ord ' +  CONVERT(VARCHAR(20), @order_no) + ' Ext ' + CONVERT(VARCHAR(4), @order_ext)   
    SELECT @con_desc = 'Ord ' +  CONVERT(VARCHAR(20), @order_no) + ' Ext ' + CONVERT(VARCHAR(4), @order_ext)   
      
    -- Insert the new generated con number in tdc_main  
    INSERT INTO tdc_main ( consolidation_no, consolidation_name, order_type, [description], status, created_by, creation_date, pre_pack)   
    VALUES (@next_con_no , @con_name, 'S', @con_desc, 'O' , @user_id , GETDATE(), @pre_pack_flg )  
     
    INSERT INTO tdc_cons_ords (consolidation_no, order_no, order_ext,location, status, seq_no, print_count, order_type, alloc_type)  
    VALUES (@next_con_no, @order_no, @order_ext, @location,'O', 1 , 0, 'S', @alloc_type)  
     
    --need to update soft_alloc_tbl and set the target bin = to the bin_no  
    --this is a rule that on one to one the bin_no becomes the picking bin  
    IF EXISTS(SELECT * FROM tdc_cons_filter_set WHERE consolidation_no = @next_con_no)  
    BEGIN  
     DELETE FROM tdc_cons_filter_set WHERE consolidation_no = @next_con_no  
    END  
  
    -- Insert the record into the cons_filter_set table based on what the user  
    -- typed into the filter screen  
    INSERT INTO tdc_cons_filter_set (consolidation_no, location, order_status, ship_date_start, ship_date_end,  
           order_range_start, order_range_end, ext_range_start, ext_range_end, order_priority_start,  
           order_priority_end, order_priority_range, sold_to, ship_to, territory, carrier, destination_zone,   
           cust_op1, cust_op2, cust_op3, order_no_range, ext_no_range, fill_percent, orderby_1, orderby_2,   
           orderby_3, orderby_4, orderby_5, orderby_6, orderby_7, order_type, ship_to_name, ship_to_city,   
           ship_to_state, ship_to_zip, ship_to_country, con_type,opt_one_for_one, -- v1.0
		   frame_case_match, orderby_8, orderby_9, order_type_code, consolidate_shipment, delivery_date_start, -- v1.0
		   delivery_date_end, user_hold)  -- v1.0
    SELECT @next_con_no, location, order_status, ship_date_start,  ship_date_end, order_range_start, order_range_end,   
           ext_range_start, ext_range_end, order_priority_start, order_priority_end, order_priority_range, sold_to,   
           ship_to, territory, carrier, destination_zone, cust_op1, cust_op2, cust_op3, order_no_range, ext_no_range,   
           fill_percent, orderby_1, orderby_2, orderby_3, orderby_4,orderby_5,orderby_6,orderby_7, 'S',ship_to_name,   
           ship_to_city, ship_to_state, ship_to_zip, ship_to_country, con_type,opt_one_for_one, -- v1.0
		   frame_case_match, orderby_8, orderby_9, order_type_code, consolidate_shipment, delivery_date_start, -- v1.0
		   delivery_date_end, user_hold  -- v1.0
      FROM tdc_user_filter_set   
            WHERE userid     = @user_id   
       AND order_type = 'S'     
   END  
   ------------------------------------------------------------------------------------------------------------------  
   ELSE --NOT ONE_FOR_ONE  
   ------------------------------------------------------------------------------------------------------------------  
   BEGIN      
    SELECT @con_seq_no  = @con_seq_no + 1   
    SELECT @next_con_no = @con_no  
    
    INSERT INTO tdc_cons_ords (consolidation_no, order_no,order_ext,location,status,seq_no,print_count,order_type, alloc_type)  
    VALUES (@con_no, @order_no, @order_ext, @location, 'O', @con_seq_no , 0, 'S', @alloc_type)  
      
    INSERT INTO tdc_log (tran_date, UserID, trans_source, module, trans,tran_no , tran_ext, part_no, lot_ser, bin_no, location, quantity, data)  
    VALUES (getdate(), @user_id , 'VB', 'PLW' , 'Allocation', @con_no, 0, '', '', '', @location, '', 'ADD order number = ' + CONVERT(VARCHAR(10),@order_no) + '-' + CONVERT(VARCHAR(10),@order_ext))     
  
    --jcollins scr 34402   
    UPDATE tdc_main set pre_pack = @pre_pack_flg  
    WHERE consolidation_no = @con_no  
  
   END --Not ONE_FOR_ONE   
    
   COMMIT TRAN   
  END --Cons_ords update  
  
  FETCH NEXT FROM allocate_cursor INTO @order_no, @order_ext, @line_no, @part_no  
 END  
  
 CLOSE      allocate_cursor  
 DEALLOCATE allocate_cursor 

 -- START v1.1 - loop through orders and call autopack routine
 CREATE TABLE #orders (
	rec_key INT IDENTITY(1,1),
	order_no INT,
	order_ext INT)
 
 INSERT #orders(
	order_no,
	order_ext)
 SELECT 
	order_no, 
	order_ext
 FROM 
	#so_soft_alloc_byline_tbl
 GROUP BY
	order_no, 
	order_ext
	
 SET @rec_key = 0	 
 WHILE 1=1
 BEGIN
	SELECT TOP 1
		@rec_key = rec_key,
		@order_no = order_no,
		@order_ext = order_ext
	FROM
		#orders
	WHERE
		rec_key > @rec_key
	ORDER BY
		rec_key

	IF @@ROWCOUNT = 0
		BREAK

	-- v2.1 Start
	EXEC dbo.cvo_calculate_packaging_sp	@order_no, @order_ext, 'S'
	-- v2.1 End	

	EXEC dbo.CVO_build_autopack_carton_sp @order_no, @order_ext

	-- v1.9 Start
	SET @consolidation_no = 0
	SELECT	@consolidation_no = consolidation_no 
	FROM	cvo_masterpack_consolidation_det (NOLOCK) 
	WHERE	order_no = @order_no
	AND		order_ext = @order_ext

	IF (ISNULL(@consolidation_no,0) <> 0)
	BEGIN
		INSERT	#consolidate_picks
		SELECT	consolidation_no, order_no, order_ext
		FROM	cvo_masterpack_consolidation_det
		WHERE	consolidation_no = @consolidation_no	 
		AND		consolidation_no NOT IN (SELECT consolidation_no FROM #consolidate_picks)
	END 
	-- v1.9

	-- v1.6 Start
-- v1.8	EXEC @iret = dbo.cvo_hold_ship_complete_allocations_sp @order_no, @order_ext
	-- v1.6 End

	-- v2.0 Start
	EXEC dbo.cvo_update_bo_processing_sp 'A', @order_no, @order_ext
	-- v2.0 End

 END 
 -- END v1.1

-- v1.9 Start
 SET @consolidation_no = 0	 
 WHILE 1=1
 BEGIN
	SELECT TOP 1
		@consolidation_no = consolidation_no
	FROM
		#consolidate_picks
	WHERE
		consolidation_no > @consolidation_no
	ORDER BY
		consolidation_no

	IF @@ROWCOUNT = 0
		BREAK

	DELETE	tdc_pick_queue
	WHERE	mp_consolidation_no = @consolidation_no

	DELETE	cvo_masterpack_consolidation_picks
	WHERE	consolidation_no = @consolidation_no	

	EXEC dbo.cvo_masterpack_consolidate_pick_records_sp @consolidation_no	
END

DROP TABLE #consolidate_picks
-- v1.9 End

GO

GRANT EXECUTE ON  [dbo].[tdc_plw_so_allocate_selected_lines] TO [public]
GO
