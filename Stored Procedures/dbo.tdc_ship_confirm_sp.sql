SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- v1.0 CB 14/06/2012 - Move coop processing to posting routine so as to include credits
-- v1.1 CB 19/06/2012 - Add validation for automated ship confirm job
-- v1.2 CB 16/07/2012 - Add validation for automated ship confirm job - Transfers
-- v1.3 CB 07/08/2013 - Isssue #1202 - Transfer email moved to transfer ship confirm
-- v1.4 CT 23/04/2014 - Issue #572 - mark masterpack consolidation number as shipped
-- v1.5 CT 22/10/2014 - Issue #572 - if masterpack consolidation, clear any existing parent pick records.
-- v1.6 CB 23/04/2015 - Performance Changes

CREATE PROCEDURE [dbo].[tdc_ship_confirm_sp]	@stage_no			varchar(50),
										@alter_by			int,
										@user_id			varchar(255),
										@ebackofficeship	char(1),
										@currentstage		varchar(255) output,    
										@allshipped			INT output,    
										@err_msg			varchar(255) output    

AS     
BEGIN

	--BEGIN  SED002 -- Freight 	  -- Freight Recalculation
	--JVM 03/02/10

	DECLARE @carton_no	INT,
			@freight	DECIMAL(20,8)
	--END    SED002 -- Freight 	  -- Freight Recalculation
    
	DECLARE @order_no int,    
			@order_ext int,    
			@load_no int,    
			@ret  int,    
			@order_type char(1),    
			@location varchar(10),    
			@line_no int,    
			@order_shipped  char(1)  

	DECLARE @valid int -- v1.1  

	-- START v1.5
	DECLARE @mp_consolidation_no INT
	-- END v1.5

	-- v1.6 Start
	DECLARE	@row_id			int,
			@last_row_id	int    
	-- v1.6 End

	SELECT @AllShipped = 1    
    
	TRUNCATE TABLE #temp_ship_confirm_cartons    
    
	--Fill the table to filter cartons for shipping    
	INSERT INTO #temp_ship_confirm_cartons(carton_no)    
	SELECT	a.carton_no     
	FROM	#temp_ship_confirm_display_tbl a,    
			tdc_stage_carton b(NOLOCK)    
	WHERE	a.stage_no = @stage_no    
	AND		a.carton_no = b.carton_no    
	UNION     
	SELECT	a.carton_no    
	FROM	tdc_master_pack_ctn_tbl a(NOLOCK),    
			#temp_ship_confirm_display_tbl b,    
			tdc_stage_carton c(NOLOCK)    
	WHERE	a.pack_no = b.carton_no    
	AND		b.stage_no = @stage_no    
	AND		a.carton_no = c.carton_no    
	AND		b.master_pack = 'Y'           
    
	-- If there are any records left in tdc_soft_alloc_tbl for the orders that have been packed    
	-- using Pack Verify transaction, un-allocate them.    

	CREATE TABLE #tdc_sc_unalloc_cur (
		row_id			int IDENTITY(1,1),
		order_no		int,
		order_ext		int,
		location		varchar(10) NULL,
		line_no			int)

	INSERT	#tdc_sc_unalloc_cur (order_no, order_ext, location, line_no)
	-- v1.6 DECLARE unalloc_cur CURSOR FOR    
	SELECT	DISTINCT c.order_no,  c.order_ext, c.location, c.line_no    
    FROM	tdc_carton_detail_tx a (NOLOCK),    
			tdc_stage_carton     b (NOLOCK),    
			tdc_soft_alloc_tbl   c (NOLOCK)    
    WHERE	a.carton_no = b.carton_no    
    AND		b.stage_no  = @stage_no    
    AND		a.order_no  = c.order_no    
    AND		a.order_ext = c.order_ext    
    AND		pack_tx     = 'Pack Verify'    
    AND		a.carton_no IN (SELECT carton_no     
						FROM #temp_ship_confirm_cartons)     

	-- v1.6 OPEN unalloc_cur    
	-- v1.6 FETCH NEXT FROM unalloc_cur INTO @order_no, @order_ext, @location, @line_no    

	-- v1.6 Start
	SET @last_row_id = 0

	SELECT	TOP 1 @row_id = row_id,
			@order_no = order_no,
			@order_ext = order_ext,
			@location = location,
			@line_no = line_no
	FROM	#tdc_sc_unalloc_cur
	WHERE	row_id > @last_row_id
	ORDER BY row_id ASC
  
	-- v1.6 WHILE(@@FETCH_STATUS = 0)    
	WHILE @@ROWCOUNT <> 0
	BEGIN    
		IF EXISTS(SELECT * FROM ord_list (NOLOCK) WHERE order_no  = @order_no AND order_ext = @order_ext AND location  = @location    
			AND line_no   = @line_no AND ordered   = shipped)    
		BEGIN    
			DELETE	FROM tdc_soft_alloc_tbl    
			WHERE	order_no   = @order_no    
			AND		order_ext  = @order_ext    
			AND		order_type = 'S'    
			AND		location   = @location    
            AND		line_no    = @line_no    
    
			DELETE	FROM tdc_pick_queue    
			WHERE	trans_type_no   = @order_no    
			AND		trans_type_ext  = @order_ext    
			AND		location   = @location    
            AND		line_no    = @line_no    
		END    

		SET @last_row_id = @row_id

		SELECT	TOP 1 @row_id = row_id,
				@order_no = order_no,
				@order_ext = order_ext,
				@location = location,
				@line_no = line_no
		FROM	#tdc_sc_unalloc_cur
		WHERE	row_id > @last_row_id
		ORDER BY row_id ASC    

		-- v1.6 FETCH NEXT FROM unalloc_cur INTO @order_no, @order_ext, @location, @line_no    
	END    
    
	-- v1.6 CLOSE      unalloc_cur    
	-- v1.6 DEALLOCATE unalloc_cur    
    
	INSERT INTO tdc_log (tran_date, trans, data, module, UserID)      
	VALUES (GETDATE(),'ShipConfirm_begin','StageNo = ' + @stage_no, 'PPS',@user_id)     

	--BEGIN SED002 -- Freight 	  -- Freight Recalculation
	--JVM 03/02/10
	/*Once the freight amount is arrived at for the aggregate of the group, 
    the freight amount will be placed on the first order in the group.  
    If this is a master pack no recalculation is required.*/

	INSERT INTO #cartonsToShip (carton_no, order_no, order_ext, tot_ord_freight, master_pack, commit_ok, first_so_in_carton)
	SELECT	DISTINCT dt.carton_no, dt.order_no, dt.order_ext, o.freight, s.master_pack, 0, 0
	FROM	tdc_stage_carton s		(NOLOCK),     
			tdc_carton_tx c			(NOLOCK),
			tdc_carton_detail_tx dt (NOLOCK),
			orders o				(NOLOCK)      
	WHERE	s.stage_no		= @stage_no		AND
			s.carton_no		= c.carton_no	AND
			s.carton_no		= dt.carton_no	AND
			c.carton_no		= dt.carton_no	AND 	
			c.order_no		= dt.order_no	AND
			c.order_ext		= dt.order_ext	AND 		     
			c.order_type	= 'S'			AND
			s.adm_ship_flag	= 'N'			AND    
			o.order_no		= c.order_no	AND  
			o.ext			= c.order_ext	AND
			o.status		IN('P' , 'Q')	AND
			s.carton_no		IN (SELECT carton_no FROM #temp_ship_confirm_cartons)	
	--END   SED002 -- Freight 	  -- Freight Recalculation
 
	--BEGIN SED009 -- Tranfer Orders - Product Shipping to & From a Sales Rep
	--JVM 09/21/2010
	--only for xfers
    INSERT INTO #xfersToShip (order_no, order_ext, carton_no, commit_ok)
	SELECT DISTINCT c.order_no, c.order_ext, c.carton_no, 0  
	FROM	tdc_stage_carton s	(NOLOCK),       
			tdc_carton_tx	 c	(NOLOCK),       
			xfers			 x	(NOLOCK)        
	WHERE	s.stage_no		= @stage_no		AND 
			s.carton_no		= c.carton_no	AND 
			c.order_type	= 'T'			AND 
			s.adm_ship_flag = 'N'			AND 
			x.xfer_no		= c.order_no	AND 
			x.status IN('P','Q')			AND
			s.carton_no IN (SELECT carton_no           
						    FROM #temp_ship_confirm_cartons)  
   
	--END   SED009 -- Tranfer Orders - Product Shipping to & From a Sales Rep
             
	--Main cursor for ship confirm    
	--This cursor calls validation procedure,     
	--and then calls shipping procedure    

	CREATE TABLE #tdc_sc_cur_confirm (
		row_id			int IDENTITY(1,1),
		order_no		int,
		order_ext		int,
		order_type		char(1),
		carton_no		int)

	INSERT	#tdc_sc_cur_confirm (order_no, order_ext, order_type, carton_no)
	-- v1.6 DECLARE cur_confirm CURSOR FOR    
	SELECT	DISTINCT c.order_no, c.order_ext, 'S', c.carton_no
	-- SED002 -- Freight 	  -- Freight Recalculatio
	FROM	tdc_stage_carton s (NOLOCK),     
			tdc_carton_tx c (NOLOCK) ,     
			orders_all o (NOLOCK)      
	WHERE	s.stage_no = @stage_no    
	AND		s.carton_no = c.carton_no      
	AND		c.order_type = 'S'    
	AND		s.adm_ship_flag = 'N'      
	AND		o.order_no = c.order_no     
	AND		o.ext = c.order_ext      
	AND		o.status IN('P' , 'Q')     
	AND		s.carton_no IN (SELECT carton_no     
				          FROM #temp_ship_confirm_cartons)     
	UNION     
	SELECT	DISTINCT c.order_no, c.order_ext, 'T', c.carton_no
	-- SED002 -- Freight 	  -- Freight Recalculation
	FROM	tdc_stage_carton s (NOLOCK),     
			tdc_carton_tx c (NOLOCK) ,     
			xfers_all x (NOLOCK)      
	WHERE	s.stage_no = @stage_no    
	AND		s.carton_no = c.carton_no      
	AND		c.order_type = 'T'    
	AND		s.adm_ship_flag = 'N'      
	AND		x.xfer_no = c.order_no      
	AND		x.status IN('P' , 'Q')    
	AND		s.carton_no IN (SELECT carton_no     
					FROM #temp_ship_confirm_cartons)     
	
	-- v1.6 OPEN cur_confirm    
	-- v1.6 FETCH NEXT FROM cur_confirm INTO @order_no, @order_ext, @order_type, @carton_no    
	-- v1.6 WHILE(@@FETCH_STATUS = 0)    

	SET @last_row_id = 0

	SELECT	TOP 1 @row_id = row_id,
			@order_no = order_no,
			@order_ext = order_ext,
			@order_type = order_type,
			@carton_no = carton_no
	FROM	#tdc_sc_cur_confirm
	WHERE	row_id > @last_row_id
	ORDER BY row_id ASC

	WHILE @@ROWCOUNT <> 0
	BEGIN    
 
		-- v1.1 Validation - Start
		-- 1. Inactive Customer
		SET @valid = 1
		IF EXISTS (SELECT 1 FROM arcust a (NOLOCK) JOIN orders_all b (NOLOCK) on a.customer_code = b.cust_code WHERE b.order_no = @order_no
					AND b.ext = @order_ext AND a.status_type = 2)
		BEGIN
			SET @err_msg = 'Order ' + CAST(@order_no AS varchar(12)) + '-' + CAST(@order_ext AS varchar(5)) + ': Customer is inactive'
			INSERT cvo_ship_confirm_audit (process_run_date, stage_no, error_result)
			VALUES (GETDATE(), @stage_no, @err_msg) 
			SET @err_msg = ''
			SET @valid = 0
		END 

		-- 2. Transfer already shipped
		IF EXISTS (SELECT 1 FROM lot_bin_xfer (NOLOCK) WHERE tran_no = @order_no AND tran_ext = @order_ext AND tran_code = 'S')
		BEGIN
			SET @valid = 0
		END

		-- 2. Transfer already shipped
		IF EXISTS (SELECT 1 FROM xfer_list (NOLOCK) where xfer_no = @order_no and ordered > shipped)
		BEGIN
			IF EXISTS (SELECT 1 FROM xfers_all (NOLOCK) WHERE xfer_no = @order_no AND back_ord_flag = 1)
			BEGIN
				SET @err_msg = 'Transfer ' + CAST(@order_no AS varchar(12)) + ': Must be shipped complete'
				INSERT cvo_ship_confirm_audit (process_run_date, stage_no, error_result)
				VALUES (GETDATE(), @stage_no, @err_msg) 
				SET @err_msg = ''
				SET @valid = 0
			END
		END

		IF @valid = 1
		BEGIN

			BEGIN TRAN    
			EXEC @ret = tdc_do_ship_order_sp @order_type, @order_no, @order_ext, @stage_no, @eBackOfficeShip, @user_id, @alter_by, @order_shipped OUTPUT    
			IF @ret = 0     
			--BEGIN SED001 -- Coop Points     -- CVO_coop_dollars
			--JVM 01/26/10 
			BEGIN
				IF @order_type = 'S'
				BEGIN
					-- START v1.4
					IF EXISTS(SELECT 1 FROM dbo.cvo_masterpack_consolidation_hdr a (NOLOCK) INNER JOIN dbo.cvo_masterpack_consolidation_det b (NOLOCK) ON a.consolidation_no = b.consolidation_no
							WHERE b.order_no = @order_no AND b.order_ext = @order_ext AND a.shipped = 0)
					BEGIN
						-- START v1.5
						SET @mp_consolidation_no = NULL
						SELECT	@mp_consolidation_no = a.consolidation_no 
						FROM	dbo.cvo_masterpack_consolidation_hdr a (NOLOCK) 
						INNER JOIN dbo.cvo_masterpack_consolidation_det b (NOLOCK) 
						ON		a.consolidation_no = b.consolidation_no
						WHERE	b.order_no = @order_no 
						AND		b.order_ext = @order_ext 
						AND		a.shipped = 0

						IF ISNULL(@mp_consolidation_no,0) <> 0 
						BEGIN
							DELETE	a
							FROM	dbo.tdc_pick_queue a
							INNER JOIN dbo.cvo_masterpack_consolidation_picks b (NOLOCK)
							ON		a.mp_consolidation_no = b.consolidation_no
							AND		a.tran_id = b.parent_tran_id
							LEFT JOIN dbo.tdc_pick_queue c (NOLOCK)
							ON		b.child_tran_id = c.tran_id
							WHERE	a.mp_consolidation_no = @mp_consolidation_no
							AND		c.tran_id is NULL
						END
						-- END v1.5

						UPDATE	a
						SET		a.shipped = 1
						FROM	dbo.cvo_masterpack_consolidation_hdr a 
						INNER JOIN dbo.cvo_masterpack_consolidation_det b (NOLOCK) 
						ON		a.consolidation_no = b.consolidation_no
						WHERE	b.order_no = @order_no 
						AND		b.order_ext = @order_ext 
						AND		a.shipped = 0
					END
					-- END v1.4

					--EXEC CVO_coop_dollars @order_no, @order_ext -- v1.0
					--BEGIN SED002 -- Freight 	  -- Freight Recalculation
					--JVM 03/02/10
					UPDATE	#cartonsToShip 
					SET		commit_ok = 1 
					WHERE	order_no = @order_no 
					AND		order_ext = @order_ext --mrc
	   
					SELECT	@freight = ISNULL(SUM(tot_ord_freight),0) 
					FROM	#cartonsToShip 
					WHERE	carton_no = @carton_no 
	   
					UPDATE	#cartonsToShip 
					SET		tot_multi_carton_ord_freight = @freight   
					WHERE	order_no = @order_no   
					AND		order_ext = @order_ext --mrc
					--END   SED002 -- Freight 	  -- Freight Recalculation
					
					COMMIT TRAN  
				END
			
				--BEGIN SED009 -- Tranfer Orders - Product Shipping to & From a Sales Rep
				--JVM 09/21/2010  
				--only for xfers   
				IF @order_type = 'T'
				BEGIN
					UPDATE	#xfersToShip 
					SET		commit_ok = 1 
					WHERE	order_no = @order_no 
					AND		order_ext = @order_ext

					-- v1.3 Start
					EXEC CVO_send_xfer_notification_sp @order_no, 1
					-- v1.3 End 

					COMMIT TRAN  
				END     
				--END   SED009 -- Tranfer Orders - Product Shipping to & From a Sales Rep   
			END
			--END SED001 -- Coop Points     -- CVO_coop_dollars
			ELSE    
				IF @@TRANCOUNT > 0 ROLLBACK TRAN    
		END    
		-- v1.1 End

		IF @order_shipped = 'N'     
			SELECT @allShipped = 0    

		--Get the next order, ext, carton 
	
		SET @last_row_id = @row_id

		SELECT	TOP 1 @row_id = row_id,
				@order_no = order_no,
				@order_ext = order_ext,
				@order_type = order_type,
				@carton_no = carton_no
		FROM	#tdc_sc_cur_confirm
		WHERE	row_id > @last_row_id
		ORDER BY row_id ASC

		-- v1.6 FETCH NEXT FROM cur_confirm INTO @order_no, @order_ext, @order_type, @carton_no
		--BEGIN SED002 -- Freight 	  -- Freight Recalculation
	END    
    
	-- v1.6 CLOSE cur_confirm    
	-- v1.6 DEALLOCATE cur_confirm    
    
	--BEGIN SED002 -- Freight 	  -- Freight Recalculation
	--JVM 03/02/10
	/*Once the freight amount is arrived at for the aggregate of the group, 
    the freight amount will be placed on the first order in the group.  
    If this is a master pack no recalculation is required.*/

	UPDATE	o 
	SET		o.freight		= 0.00
	FROM	orders_all o, #cartonsToShip s 
	WHERE	o.order_no		= s.order_no	
	AND		o.ext			= s.order_ext	
	AND		s.commit_ok		= 1				
	AND		s.master_pack	= 'N'

	-- v1.6 Start
	CREATE TABLE #tdc_sc_cur_carton (
		row_id			int IDENTITY(1,1),
		carton_no		int)

	INSERT	#tdc_sc_cur_carton (carton_no)
	-- v1.6 DECLARE cur_carton CURSOR FOR    
	SELECT	DISTINCT carton_no FROM #cartonsToShip WHERE commit_ok = 1 AND master_pack = 'N'

	-- v1.6 OPEN cur_carton    
	-- v1.6 FETCH NEXT FROM cur_carton INTO @carton_no
	-- v1.6 WHILE(@@FETCH_STATUS = 0)    

	SET @last_row_id = 0

	SELECT	TOP 1 @row_id = row_id,
			@carton_no = carton_no
	FROM	#tdc_sc_cur_carton
	WHERE	row_id > @last_row_id
	ORDER BY row_id ASC

	WHILE @@ROWCOUNT <> 0
	BEGIN   
		--get first order packed into the carton 
		SELECT	 @order_no	= order_no,
				 @order_ext = order_ext
		FROM	 tdc_carton_detail_tx
		WHERE	 carton_no	= @carton_no 
		ORDER BY rec_date DESC 
						
		UPDATE	#cartonsToShip 
		SET		first_so_in_carton	= 1 
		WHERE	order_no			= @order_no	
		AND		order_ext			= @order_ext
		
		SET @last_row_id = @row_id

		SELECT	TOP 1 @row_id = row_id,
				@carton_no = carton_no
		FROM	#tdc_sc_cur_carton
		WHERE	row_id > @last_row_id
		ORDER BY row_id ASC

		-- v1.6 FETCH NEXT FROM cur_carton INTO  @carton_no   
	END    

	-- v1.6 CLOSE cur_carton    
	-- v1.6 DEALLOCATE cur_carton  
	
	UPDATE o 
	SET    o.freight = s.tot_multi_carton_ord_freight
	FROM   orders o, #cartonsToShip s 
	WHERE  o.order_no = s.order_no 
	AND o.ext = s.order_ext 
	AND s.first_so_in_carton = 1  
	AND s.commit_ok = 1 
	AND s.master_pack = 'N'	  
		          
	IF @ebackofficeship = 'Y'    
	BEGIN    

		CREATE TABLE #tdc_sc_load_cur (
			row_id			int IDENTITY(1,1),
			load_no			int)

		INSERT	#tdc_sc_load_cur (load_no)
		-- v1.6 DECLARE load_cur CURSOR FOR     
		SELECT	DISTINCT c.load_no    
		FROM	tdc_stage_carton a(NOLOCK),    
				tdc_carton_tx b(NOLOCK),    
				load_list c(NOLOCK),    
				load_master d(NOLOCK)    
		WHERE	a.stage_no = @stage_no    
		AND		a.carton_no = b.carton_no    
		AND		b.order_no = c.order_no    
		AND		b.order_ext = c.order_ext    
		AND		d.load_no = c.load_no    
		AND		d.status < 'R'    
		ORDER BY c.load_no    
    
		-- v1.6 OPEN load_cur    
		-- v1.6 FETCH NEXT FROM load_cur INTO @load_no    
		-- v1.6 WHILE(@@FETCH_STATUS = 0)    

		SET @last_row_id = 0

		SELECT	TOP 1 @row_id = row_id,
				@load_no = load_no
		FROM	#tdc_sc_load_cur
		WHERE	row_id > @last_row_id
		ORDER BY row_id ASC

		WHILE @@ROWCOUNT <> 0
		BEGIN    
			EXEC @ret = tdc_ship_load_sp @stage_no, @load_no, @user_id, @alter_by    
    
			IF @ret < 0     
			BEGIN    
				IF @@TRANCOUNT > 0 ROLLBACK TRAN     
				SELECT @allShipped = 0    
			END    
    
			SET @last_row_id = @row_id

			SELECT	TOP 1 @row_id = row_id,
					@load_no = load_no
			FROM	#tdc_sc_load_cur
			WHERE	row_id > @last_row_id
			ORDER BY row_id ASC

			-- v1.6 FETCH NEXT FROM load_cur INTO @load_no    
		END    
     
		-- v1.6 CLOSE load_cur    
		-- v1.6 DEALLOCATE load_cur    
	END    
    
	UPDATE	tdc_stage_carton    
	SET		adm_ship_date = CASE WHEN adm_ship_date IS NULL THEN GETDATE() ELSE adm_ship_date END,    
			adm_ship_flag = 'Y',    
			tdc_ship_date = CASE WHEN tdc_ship_date IS NULL THEN GETDATE() ELSE tdc_ship_date END,    
			tdc_ship_flag = 'Y'    
	FROM	tdc_stage_carton a (NOLOCK),    
			tdc_carton_Tx b(NOLOCK),    
			orders_all c(NOLOCK)    
	WHERE	a.carton_no= b.carton_no    
	AND		b.order_no= c.order_no    
	AND		b.order_ext = c.ext    
	AND		c.status >= 'R'    
	AND		b.order_type = 'S'    
	AND		a.stage_no= @stage_no    
    
    
	UPDATE	tdc_stage_carton    
	SET		adm_ship_date = CASE WHEN adm_ship_date IS NULL THEN GETDATE() ELSE adm_ship_date END,    
			adm_ship_flag = 'Y',    
			tdc_ship_date = CASE WHEN tdc_ship_date IS NULL THEN GETDATE() ELSE tdc_ship_date END,    
			tdc_ship_flag = 'Y'    
	FROM	tdc_stage_carton a (NOLOCK),    
			tdc_carton_Tx b(NOLOCK),    
			xfers_all c(NOLOCK)    
	WHERE	a.carton_no= b.carton_no    
	AND		b.order_no= c.xfer_no    
	AND		b.order_ext = 0    
	AND		c.status >= 'R'    
	AND		b.order_type = 'T'    
	AND		a.stage_no= @stage_no    
    
	IF (@AllShipped = 1 AND @eBackOfficeShip = 'Y')    
	BEGIN    
		EXEC tdc_increment_stage_sp @CurrentStage OUTPUT    
    
		INSERT INTO tdc_log (tran_date, trans, data, module, UserID)      
		VALUES (GETDATE(),'ShipConfirm', 'All shipped', 'PPS', @user_id)    
    
		--COMMENTS ADDED PER GREG JENKIN'S REQUEST: AARON GOODMAN AND JOHN COLLINS CONFIRMED THAT THE ORIGINAL CODE HERE WAS NOT VALID    
		IF NOT EXISTS(SELECT TOP 1 * FROM tdc_stage_carton (NOLOCK) WHERE stage_no = @stage_no AND adm_ship_flag = 'N')    
		BEGIN    
			UPDATE	tdc_stage_numbers_tbl     
			SET		active = 'N'    
			WHERE	stage_no = @stage_no    
		END    
    
		IF @@ERROR <> 0     
		BEGIN    
			SELECT @err_msg = 'UPDATE tdc_stage_numbers_tbl failed'    
			RETURN -1    
		END    
    END    
	ELSE    
	BEGIN    
		INSERT INTO tdc_log (tran_date, trans, data, module, UserID)      
		VALUES (GETDATE(),'ShipConfirm', 'Error during ship', 'PPS', @user_id)    
	END    
    
	RETURN 1 
END
GO
GRANT EXECUTE ON  [dbo].[tdc_ship_confirm_sp] TO [public]
GO
