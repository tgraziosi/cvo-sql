SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- v1.0 CB 23/04/2015 - Performance Changes   
CREATE PROC [dbo].[tdc_validate_order_to_ship_sp]	@stage_no        varchar(11),  
												@order_no        INT,   
												@order_ext       INT,  
												@order_type      CHAR(1)  
AS   
BEGIN
   
   
	DECLARE @order_and_ext        VARCHAR(50),  
            @err_msg                     VARCHAR(255),  
            @part_no          VARCHAR(30),  
            @line_no                       INT,  
            @picked                       DECIMAL(20, 8),  
            @packed                      DECIMAL(20, 8),  
            @staged                       DECIMAL(20, 8),  
            @language        VARCHAR(10),  
            @kit_item         VARCHAR(30)  

	-- v1.0 Start
	DECLARE	@row_id			int,
			@last_row_id	int
	-- v1.0 End
   
	SELECT @language = ISNULL((SELECT Language FROM tdc_sec (nolock) WHERE userid = (SELECT who FROM #temp_who)), 'us_english')  
   
	SELECT @order_and_ext = CAST(@order_no AS VARCHAR(50))  
	IF @order_type <> 'T'  
            SELECT @order_and_ext = @order_and_ext + '-' + CAST(@order_ext AS VARCHAR(50))  
   
	-- If Stage_To_Load_Flag in tdc_config is set, then need to make sure  
	-- status of all cartons of the order are ready        
	IF (SELECT active FROM TDC_CONFIG (NOLOCK) WHERE [function] = 'stage_to_load_flag') = 'Y'   
	BEGIN  
		IF EXISTS(SELECT * FROM tdc_carton_tx (NOLOCK) WHERE order_no   = @order_no AND order_ext  = @order_ext AND order_type = @order_type AND stl_status = 'N')  
        BEGIN  
			SELECT @err_msg = 'Not all cartons have been loaded for order: ' + @order_and_ext  
            UPDATE	tdc_stage_carton 
			SET		stage_error = @err_msg   
            WHERE	carton_no IN (SELECT carton_no   
                                  FROM	tdc_carton_tx (NOLOCK)    
								  WHERE order_no   = @order_no   
                                  AND order_ext  = @order_ext  
                                  AND order_type = @order_type)  
            AND		carton_no IN (SELECT carton_no FROM #temp_ship_confirm_cartons)   
                        
			RETURN -1  
		END  
	END  
      
	--Make sure no PRE-PACK allocations for order  
	IF EXISTS(SELECT * FROM tdc_soft_alloc_tbl (NOLOCK) WHERE order_no  = @order_no AND order_ext = @order_ext AND alloc_type = 'PR')  
	BEGIN  
		IF EXISTS(SELECT * FROM tdc_soft_alloc_tbl (NOLOCK) WHERE order_no   = @order_no AND order_ext  = @order_ext AND order_type = @order_type)  
        BEGIN  
			SELECT @err_msg = 'Order must first be unallocated: ' + @order_and_ext  
            UPDATE	tdc_stage_carton 
			SET		stage_error = @err_msg   
            WHERE carton_no IN (SELECT carton_no FROM tdc_carton_tx (NOLOCK)    
								WHERE order_no = @order_no   
                                AND order_ext = @order_ext  
                                AND order_type = @order_type)  
            RETURN -2  
		END  
	END  
   
	--Make sure pick transactions on queue for order  
	IF EXISTS(SELECT * FROM tdc_pick_queue (NOLOCK) WHERE trans_type_no   = @order_no AND trans_type_ext  = @order_ext  
			AND (trans = CASE WHEN @order_type = 'S' THEN 'STDPICK'  
                              WHEN @order_type = 'W' THEN 'WOPPICK'  
                              WHEN @order_type = 'T' THEN 'XFERPICK' END  
			OR trans = 'PKGBLD'))  
	--SCR #37175 11-08-06 ToddR Added or trans = 'PKGBLD' to prevent force unallocation of unpicked pkgbld allocations.  
	BEGIN  
		-- SCR #37041 (Jim 9/22/06): if an order is picked/packed 100% delete it from allocation tables anyway  
		IF @order_type = 'S' AND NOT EXISTS (SELECT 1 FROM ord_list (nolock) WHERE order_no = @order_no AND order_ext = @order_ext   
										AND ordered > shipped AND part_type IN ('P', 'C'))  
		BEGIN  
			DELETE FROM tdc_soft_alloc_tbl WHERE order_no = @order_no AND order_ext = @order_ext  
			DELETE FROM tdc_pick_queue WHERE trans_type_no = @order_no AND trans_type_ext = @order_ext   
		END  
		ELSE  
		BEGIN  
			SELECT @err_msg = 'Pick transactions exist on pick queue for order: ' + @order_and_ext  
            UPDATE	tdc_stage_carton   
            SET		stage_error = @err_msg   
            WHERE	carton_no IN (SELECT carton_no FROM tdc_carton_tx (NOLOCK)    
								WHERE order_no = @order_no   
                                AND order_ext = @order_ext  
                                AND order_type = @order_type)  
            AND		carton_no IN (SELECT carton_no FROM #temp_ship_confirm_cartons)              
            RETURN -3  
		END  
	END  
  
	--SCR 37116 11-07-06 Added or include for cdock transactions  
	IF EXISTS(SELECT * FROM tdc_pick_queue (NOLOCK) WHERE trans_type_no   = @order_no AND trans_type_ext  = @order_ext AND trans           like '%CDOCK%')  
	BEGIN  
		SELECT @err_msg = 'There are crossdock allocations for this order which must be unallocated: ' + @order_and_ext  
        UPDATE	tdc_stage_carton   
        SET		stage_error = @err_msg   
        WHERE	carton_no IN (SELECT carton_no FROM tdc_carton_tx (NOLOCK)    
                               WHERE order_no = @order_no   
                               AND order_ext = @order_ext  
                               AND order_type = @order_type)  
        AND		carton_no IN (SELECT carton_no FROM #temp_ship_confirm_cartons)              
        RETURN -99  
	END  

	--SCR 37116 11-07-06 Added or include for cdock transactions   
	IF @order_type = 'S'  
	BEGIN  

		-- v1.0 Start
		CREATE TABLE #tdc_val_kit_line_cur (
			row_id			int IDENTITY(1,1),
			line_no			int)

		INSERT	#tdc_val_kit_line_cur (line_no)
		-- v1.0 DECLARE kit_line_cur CURSOR FOR 
		SELECT DISTINCT line_no FROM ord_list_kit (NOLOCK) WHERE order_no = @order_no AND order_ext = @order_ext  
		
		-- v1.0 OPEN kit_line_cur  
		-- v1.0 FETCH NEXT FROM kit_line_cur INTO @line_no   
		-- v1.0 WHILE @@fetch_status = 0  

		SET @last_row_id = 0

		SELECT	TOP 1 @row_id = row_id,
				@line_no = line_no
		FROM	#tdc_val_kit_line_cur
		WHERE	row_id > @last_row_id
		ORDER BY row_id ASC

		WHILE @@ROWCOUNT <> 0
		BEGIN  
        
			--Make sure all subcomponents for custom kits  
			--in order have been packed.  
			---------------------------------------------------------------------------------------  
			-- Get the list of sum(pack_qty) / qty_per_kit  
			---------------------------------------------------------------------------------------  
			IF ISNULL((SELECT DISTINCT COUNT (cnt) FROM (  
			---------------------------------------------------------------------------------------  
			-- Components not substituted  
			---------------------------------------------------------------------------------------  
			SELECT	cnt = sum(pack_qty) / qty_per_kit  
			FROM	tdc_carton_detail_tx a (NOLOCK),   
					tdc_ord_list_kit b (NOLOCK)  
			WHERE	a.order_no = b.order_no  
			AND		a.order_ext = b.order_ext  
			AND		a.line_no = b.line_No  
			AND		b.sub_kit_part_no is null  
			AND		a.order_no = @order_no  
			AND		a.order_ext = @order_ext  
			AND		a.part_no = b.kit_part_no   
			AND		a.line_no = @line_no  
			AND		a.part_no not in (select isnull(kit_part_no, '') from tdc_ord_list_kit (NOLOCK)  
										WHERE order_no = a.order_no  
										AND order_ext = a.order_ext  
										AND line_No = a.line_No  
										AND sub_kit_part_no is not null)  
			GROUP BY a.order_no, a.order_ext, a.line_no, b.kit_part_no, b.qty_per_kit                 
			UNION  
			---------------------------------------------------------------------------------------  
			-- Substituted components   
			---------------------------------------------------------------------------------------  
			SELECT	cnt = sum(pack_qty) / qty_per_kit   
			FROM		tdc_carton_detail_tx a (NOLOCK),   
						tdc_ord_list_kit b (NOLOCK)  
			WHERE	a.order_no = b.order_no  
			AND		a.order_ext = b.order_ext  
			AND		a.line_no = b.line_No  
			AND		b.sub_kit_part_no is not null  
			AND		a.order_no = @order_no  
			AND		a.order_ext = @order_ext  
			AND		a.line_no = @line_no  
			AND		(a.part_no = b.kit_part_no or a.part_no = isnull(b.sub_kit_part_no, ''))  
			GROUP BY a.order_no, a.order_ext, a.line_no, b.kit_part_no , b.qty_per_kit                             
			UNION  
			---------------------------------------------------------------------------------------  
			-- Components not packed  
			---------------------------------------------------------------------------------------  
			SELECT	cnt = 0  
			FROM	tdc_ord_list_kit c (NOLOCK)   
			WHERE	order_no = @order_no  
			AND		order_ext = @order_ext  
			AND		c.line_no = @line_no  
			AND NOT EXISTS(SELECT * FROM tdc_carton_detail_tx d  (NOLOCK)  
							WHERE d.order_no= c.order_no  
							AND d.order_ext = c.order_ext  
							AND d.line_no = c.line_No  
							AND (d.part_no = c.kit_part_no OR d.part_no = c.sub_kit_part_no)))  q), 0) <> 1  
			AND EXISTS(SELECT * FROM tdc_ord_list_kit c (NOLOCK)   
			WHERE	order_no = @order_no  
			AND		order_ext = @order_ext  
			AND		line_no = @line_no)   
			BEGIN  
				SELECT @err_msg = 'Not all parts in custom kit packed for order: ' + @order_and_ext + '; ' + 'Line No: ' + CAST(@line_no AS VARCHAR)  
				UPDATE	tdc_stage_carton 
				SET		stage_error = @err_msg   
				WHERE	carton_no IN (SELECT carton_no FROM tdc_carton_tx (NOLOCK)    
									WHERE order_no = @order_no   
									AND order_ext = @order_ext  
									AND order_type = @order_type)  
				AND		carton_no IN (SELECT carton_no   
								FROM #temp_ship_confirm_cartons)              
		
				-- v1.0 CLOSE kit_line_cur  
				-- v1.0 DEALLOCATE kit_line_cur  
				RETURN -4  
			END  
    
			SET @last_row_id = @row_id

			SELECT	TOP 1 @row_id = row_id,
					@line_no = line_no
			FROM	#tdc_val_kit_line_cur
			WHERE	row_id > @last_row_id
			ORDER BY row_id ASC

			-- v1.0 FETCH NEXT FROM kit_line_cur INTO @line_no  
		END  
		
		-- v1.0 CLOSE kit_line_cur  
		-- v1.0 DEALLOCATE kit_line_cur  
	END  

	-- v1.0 Start
	CREATE TABLE #tdc_item_packed_cur (
		row_id			int IDENTITY(1,1),
		order_no		int,
		order_ext		int,
		line_no			int,
		part_no			varchar(30),
		shipped			decimal(20,8))

	--Make sure that all parts picked have been packed  
	IF @order_type = 'S'  
	BEGIN  


		INSERT	#tdc_item_packed_cur (order_no, order_ext, line_no, part_no, shipped)
        -- v1.0 DECLARE tdc_item_packed_cur INSENSITIVE CURSOR FOR   
        SELECT	ol.order_no, ol.order_ext, ol.line_no, ol.part_no, ol.shipped  
        FROM	ord_list ol (NOLOCK) 
        WHERE	ol.order_no = @order_no  
        AND		ol.order_ext = @order_ext  
        AND		ol.part_type not in ('M','V')  

	END  
	ELSE IF @order_type = 'T'  
	BEGIN  
    
		INSERT	#tdc_item_packed_cur (order_no, order_ext, line_no, part_no, shipped)
        -- v1.0 DECLARE tdc_item_packed_cur INSENSITIVE CURSOR FOR   
        SELECT	xl.xfer_no, 0, xl.line_no, xl.part_no, xl.shipped  
        FROM	xfer_list xl (NOLOCK) 
        WHERE	xl.xfer_no = @order_no  
   
	END  
   
	-- Get picked/shipped quantities from ord_list table.  
	-- v1.0 OPEN tdc_item_packed_cur  
	-- v1.0 FETCH NEXT FROM tdc_item_packed_cur INTO @order_no, @order_ext, @line_no, @part_no, @picked  
    -- v1.0 WHILE (@@FETCH_STATUS = 0)  

	SET @last_row_id = 0

	SELECT	TOP 1 @row_id = row_id,
			@order_no = order_no,
			@order_ext = order_ext,
			@line_no = line_no,
			@part_no = part_no,
			@picked = shipped
	FROM	#tdc_item_packed_cur
	WHERE	row_id > @last_row_id
	ORDER BY row_id ASC

	WHILE @@ROWCOUNT <> 0
	BEGIN  
		-- Compare against what has been packed.  
        SELECT	@packed = ISNULL(SUM(pack_qty), 0)  
		FROM	tdc_carton_detail_tx (NOLOCK)  
        WHERE	order_no  = @order_no  
        AND		order_ext = @order_ext  
        AND		line_no   = @line_no  
        AND		carton_no IN (SELECT carton_no   
                              FROM tdc_carton_tx(NOLOCK)  
                              WHERE order_no   = @order_no  
                              AND order_ext  = @order_ext  
                              AND order_type = @order_type)  
   
		IF (@packed < @picked)  
        BEGIN  
			SELECT @err_msg = 'Not all items picked have been packed for order: ' + @order_and_ext  
            UPDATE	tdc_stage_carton 
			SET		stage_error = @err_msg   
			WHERE	carton_no IN (SELECT carton_no FROM tdc_carton_tx (NOLOCK)    
                                  WHERE order_no   = @order_no   
                                  AND order_ext  = @order_ext  
                                  AND order_type = @order_type)  
            AND		carton_no IN (SELECT carton_no   
                                  FROM #temp_ship_confirm_cartons)               
   
            -- v1.0 CLOSE tdc_item_packed_cur  
            -- v1.0 DEALLOCATE tdc_item_packed_cur  
            RETURN -5  
		END  
        ELSE  
        BEGIN  
			-- Compare against what has been staged.  
            SELECT	@staged   = ISNULL(SUM(pack_qty), 0)  
            FROM	tdc_carton_detail_tx (NOLOCK)  
            WHERE	order_no  = @order_no  
            AND		order_ext = @order_ext  
            AND		line_no   = @line_no  
            AND		carton_no IN (SELECT carton_no   
                                  FROM tdc_carton_tx(NOLOCK)  
                                  WHERE order_no   = @order_no  
                                  AND order_ext  = @order_ext  
                                  AND order_type = @order_type  
                                  AND status >= 'S')  
            AND		status >= 'S'  
   
			IF (@staged < @packed)  
            BEGIN  
				SELECT @err_msg = 'Not all items packed have been staged for order: ' + @order_and_ext  
                UPDATE	tdc_stage_carton 
				SET		stage_error = @err_msg   
                WHERE	carton_no IN (SELECT carton_no FROM tdc_carton_tx (NOLOCK)    
                                      WHERE order_no   = @order_no   
                                      AND order_ext  = @order_ext  
                                      AND order_type = @order_type)  
                                      AND carton_no IN (SELECT carton_no   
                                                        FROM #temp_ship_confirm_cartons)   
				-- v1.0 CLOSE tdc_item_packed_cur  
                -- v1.0 DEALLOCATE tdc_item_packed_cur  
                RETURN -6  
			END       
                                                              
            IF @order_type = 'S' AND (SELECT back_ord_flag FROM orders_all (NOLOCK) WHERE order_no = @order_no AND ext = @order_ext) = '1'  
            BEGIN  
				IF (@staged < (	SELECT ordered   
								FROM ord_list (NOLOCK)                         
                                WHERE order_no  = @order_no  
                                AND order_ext = @order_ext  
                                AND line_no   = @line_no))  
                BEGIN  
					SELECT @err_msg = 'Not all items ordered have been staged for Ship Complete order: ' + @order_and_ext  
                    UPDATE	tdc_stage_carton 
					SET		stage_error = @err_msg   
                    WHERE	carton_no IN (SELECT carton_no FROM tdc_carton_tx (NOLOCK)    
                                          WHERE order_no = @order_no   
                                          AND order_ext = @order_ext  
                                          AND order_type = @order_type)  
                                          AND carton_no IN (SELECT carton_no   
                                                            FROM #temp_ship_confirm_cartons)   
					-- v1.0 CLOSE tdc_item_packed_cur  
					-- v1.0 DEALLOCATE tdc_item_packed_cur  
					RETURN -7  
				END
			END  
		END  
   
		SET @last_row_id = @row_id

		SELECT	TOP 1 @row_id = row_id,
				@order_no = order_no,
				@order_ext = order_ext,
				@line_no = line_no,
				@part_no = part_no,
				@picked = shipped
		FROM	#tdc_item_packed_cur
		WHERE	row_id > @last_row_id
		ORDER BY row_id ASC
        
		-- v1.0 FETCH NEXT FROM tdc_item_packed_cur INTO @order_no, @order_ext, @line_no, @part_no, @picked  
	END  
   
	-- v1.0 CLOSE tdc_item_packed_cur  
	-- v1.0 DEALLOCATE tdc_item_packed_cur  
   
	-- If the order is spread accross multiple stages make sure the cartons on  
	-- other stages are marked as tdc shipped before marking the order as shipped in ERP  
	IF EXISTS (SELECT * FROM tdc_carton_tx a(NOLOCK),  
                             tdc_stage_carton b(NOLOCK)  
                        WHERE a.carton_no = b.carton_no  
                        AND b.stage_no <> @stage_no  
                        AND a.order_no = @order_no  
                        AND a.order_ext = @order_ext  
                        AND a.order_type = @order_type  
                        AND tdc_ship_flag <> 'Y'  
                        AND a.carton_no IN(SELECT carton_no   
											FROM tdc_carton_detail_tx  
                                            WHERE carton_no = a.carton_no))                                          
	-- Make sure that all cartons created for this sales order have been staged  
	OR EXISTS(SELECT * FROM tdc_carton_tx a(NOLOCK)  
                       WHERE a.order_no = @order_no  
                       AND a.order_ext = @order_ext  
                       AND a.order_type = @order_type  
                       AND a.carton_no NOT IN (SELECT carton_no  
												FROM tdc_stage_carton (NOLOCK)  
                                                WHERE tdc_ship_flag = 'Y')  
                       AND a.carton_no IN(SELECT carton_no   
											FROM tdc_carton_detail_tx b  
                                            WHERE b.carton_no = a.carton_no))              
   
	BEGIN  
		SELECT @err_msg = 'Not all cartons have been shipped for order: ' + @order_and_ext  
        UPDATE	tdc_stage_carton 
		SET		stage_error = @err_msg   
        WHERE	carton_no IN (SELECT carton_no FROM tdc_carton_tx (NOLOCK)    
								WHERE order_no = @order_no   
                                AND order_ext = @order_ext  
                                AND order_type = @order_type)  
        AND		carton_no IN (SELECT carton_no   
								FROM #temp_ship_confirm_cartons)   
        RETURN -8  
	END  
   
	UPDATE	tdc_stage_carton   
	SET		stage_error = NULL   
	WHERE	carton_no IN (SELECT carton_no FROM tdc_carton_tx (NOLOCK)    
                          WHERE order_no   = @order_no   
                          AND order_ext  = @order_ext  
                          AND order_type = @order_type)  
	AND		carton_no IN (SELECT carton_no   
							FROM #temp_ship_confirm_cartons)      

	RETURN 1  
END
GO
GRANT EXECUTE ON  [dbo].[tdc_validate_order_to_ship_sp] TO [public]
GO
