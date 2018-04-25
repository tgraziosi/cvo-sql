SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[CVO_no_stock_process_partial_sp]	@order_no int,
														@order_ext int,
														@line_no int,
														@location varchar(10),
														@part_no varchar(30),
														@bin_no	varchar(20),
														@lot_ser varchar(25),
														@picked_qty decimal(20,8),
														@orig_qty decimal(20,8),
														@userid varchar(50),
														@tran_id int
AS

BEGIN

	-- Directives
	SET NOCOUNT ON

	-- Declarations
	DECLARE	@bin_qty		decimal(20,8),
			@cust_code		varchar(10),
			@ret			int,
			@ret_message	varchar(255),
			@new_order_no	int,
			@date_expires	varchar(12),
			@issue_no		int,
			@uom			varchar(2),
			@group_code		varchar(10),
			@description	varchar(255),
			@sku_code		varchar(30), 
			@height			decimal(20,8), 
			@width			decimal(20,8), 
			@length			decimal(20,8), 
			@cmdty_code		varchar(8),
			@weight_ea		decimal(20,8), 
			@so_qty_increment decimal(20,8),
			@cubic_feet		decimal(20,8),
			@category_1		varchar(15),
			@category_2		varchar(15),
			@category_3		varchar(15),
			@category_4		varchar(15),
			@category_5		varchar(15),
			@UPC			varchar(12),
			@GTIN			varchar(14),
			@EAN_8			varchar(8),
			@EAN_13			varchar(13),
			@EAN_14			varchar(14),
			@data			varchar(7500),
			@status			varchar(8),
			@hold_code		varchar(10), 
			@hold_reason	varchar(40),
			@back_ord_flag	char(1),
			@qty_to_unalloc decimal(20,8),
			@case_line_no	int, -- v1.1
			@case_bin		varchar(20), -- v1.1
			@case_part		varchar(30), -- v1.1
			@case_tran_id	int, -- v1.1
			@case_lot_ser	varchar(25), -- v1.1
			@case_qty		decimal(20,8), -- v1.1
			@case_last_id	int, -- v1.1
			@case_done		int, -- v1.1
			@case_unalloc_qty	decimal(20,8), -- v1.1
			@case_orig_qty	decimal(20,8), -- v1.1
			@new_soft_alloc_no int, -- v1.2
			@notifications	SMALLINT, -- v1.4
			@retval			INT, -- v1.4
			@consolidation_no int, -- v2.3
			@removed_qty decimal(20,8) -- v2.5

	-- START v1.4
	/*
	-- Create working table
	CREATE TABLE #ordercancel (
		ret				int,
		ret_message		varchar(255),
		new_order_no	int)
	*/
	-- END v1.4

	IF (SELECT OBJECT_ID('tempdb..#adm_inv_adj')) IS NOT NULL 
	BEGIN   
		DROP TABLE #adm_inv_adj  
	END

	CREATE TABLE #adm_inv_adj (
		adj_no			int	null,
		loc				varchar(10) not null,
		part_no			varchar(30)	not null,
		bin_no			varchar(12) null,
		lot_ser			varchar(25) null,
		date_exp		datetime null,
		qty				decimal(20,8) not null,
		direction		int	not null,
		who_entered		varchar(50)	not null,
		reason_code		varchar(10) null,
		code			varchar(8) not null,
		cost_flag		char(1)	null,
		avg_cost		decimal(20,8) null,
		direct_dolrs	decimal(20,8) null,
		ovhd_dolrs		decimal(20,8) null,
		util_dolrs		decimal(20,8) null,
		err_msg			varchar(255) null,
		row_id			int identity not null)

	-- START v2.2
	-- Write tdc_log entry
	INSERT INTO tdc_log (tran_date,UserID,trans_source,module,trans,tran_no,tran_ext,part_no, lot_ser,bin_no,location,quantity,data) 										
	VALUES (getdate(), @userid, 'CO', NULL , 'No Stock', CAST(@order_no as varchar(10)), CAST(@order_ext as varchar(5)), @part_no, '', @bin_no, @location, '', 'NO STOCK') 
	-- END v2.2

	-- Get the lot_bin_stock qty
	SELECT	@bin_qty = qty,
			@date_expires = CONVERT(varchar(12), date_expires, 101)
	FROM	lot_bin_stock (NOLOCK)
	WHERE	location = @location
	AND		bin_no = @bin_no
	AND		part_no = @part_no
	AND		lot_ser = @lot_ser

	IF @bin_qty IS NULL
		SET @bin_qty = 0

	-- Get order details
	SELECT	@cust_code = cust_code,
			@status = status,
			@back_ord_flag = back_ord_flag
	FROM	orders_all (NOLOCK)
	WHERE	order_no = @order_no
	AND		ext = @order_ext
	

	-- Get the hold code and reason for the order type
	-- START v2.1
	SELECT  @notifications = a.notifications_console
	FROM	so_usrcateg a (NOLOCK)
	JOIN	orders_all b (NOLOCK)
	ON		a.category_code = b.user_category
	WHERE	b.order_no = @order_no
	AND		b.ext = @order_ext	

	/*
	SELECT	@hold_code = a.hold_code,
			@hold_reason = a.hold_reason,
			@notifications = b.notifications -- v1.4
	SELECT  @notifications = a.notifications_console
	FROM	adm_oehold a (NOLOCK)
	JOIN	so_usrcateg b (NOLOCK)
	ON		a.hold_code = b.no_stock_hold
	JOIN	orders_all c (NOLOCK)
	ON		b.category_code = c.user_category
	WHERE	c.order_no = @order_no
	AND		c.ext = @order_ext	
	*/
	-- END v2.1

	SET @removed_qty = @bin_qty - @picked_qty -- v2.5

	-- START v1.4
	-- Pick what was entered in the console screen
	IF @picked_qty > 0
	BEGIN
		EXEC dbo.cvo_autopick_line_sp @tran_id, @order_no, @order_ext, @line_no, @picked_qty, 999, @userid
	END

	-- Adjust off what was missing from bin 
	IF (@bin_qty - @picked_qty) > 0
	BEGIN
		-- v2.7 Start
		IF NOT EXISTS (SELECT 1 FROM dbo.CVO_no_stock_approval WHERE location = @location AND part_no = @part_no AND lot_ser = @lot_ser
						AND bin_no = @bin_no)
		BEGIN
			-- v2.6 Start
			INSERT	dbo.CVO_no_stock_approval (approve, created_by, created_on,	location, part_no, lot_ser, bin_no, reason_code,
				adj_code, qty, date_expires, direction)
			SELECT	0, @userid, GETDATE(), @location, @part_no, @lot_ser, @bin_no, '', 'CYC', (@bin_qty - @picked_qty),
				@date_expires, -1
		END
		-- v2.7 End
		/*
		DELETE #adm_inv_adj

		INSERT INTO #adm_inv_adj (loc, part_no, bin_no, lot_ser, date_exp, qty, direction, who_entered, 
									reason_code, code) 									
		VALUES(@location, @part_no, @bin_no, @lot_ser, @date_expires, (@bin_qty - @picked_qty), -1, @userid, '', 'CYC')

		EXEC dbo.tdc_adm_inv_adj 		

		SELECT	@issue_no = max(issue_no) 
		FROM	dbo.issues
		WHERE	part_no = @part_no
		AND		code = 'CYC'

		SELECT	@uom = uom, @description = description FROM inventory (nolock) WHERE part_no = @part_no AND location = @location 
		SELECT	@group_code = group_code FROM tdc_bin_master (nolock) WHERE location = @location AND bin_no = @bin_no
		SELECT	@sku_code = isnull(sku_code, ''), @height = height, @width = width, @length = length, 
				@cmdty_code = isnull(cmdty_code, ''), @weight_ea = weight_ea, @so_qty_increment = isnull(so_qty_increment, 0), 
				@cubic_feet = cubic_feet 
		FROM	inv_master (nolock) WHERE part_no = @part_no
		SELECT	@category_1 = isnull(category_1, ''), @category_2 = isnull(category_2, ''), 
				@category_3 = isnull(category_3, ''), @category_4 = isnull(category_4, ''), 
				@category_5 = isnull(category_5, '') 
		FROM	inv_master_add (nolock) WHERE part_no = @part_no
		SELECT	@UPC = ISNULL(UPC, ''), @GTIN = ISNULL(GTIN, ''), @EAN_8 = ISNULL(EAN_8, ''), 
				@EAN_13 = ISNULL(EAN_13, ''), @EAN_14 = ISNULL(EAN_14, '')						
		FROM	uom_id_code (nolock) WHERE part_no = @part_no 
		AND		UOM = @uom

		SELECT @data = 'LP_ITEM_EAN14: ; LP_ITEM_EAN13: ; LP_ITEM_EAN8: ; LP_ITEM_GTIN: ; LP_ITEM_UPC: ' 
		SELECT @data = @data + LTRIM(RTRIM(@UPC)) + '; LP_CATEGORY_5: '+ LTRIM(RTRIM(@category_2)) + '; LP_CATEGORY_4: ' 
		SELECT @data = @data + LTRIM(RTRIM(@category_4)) + '; LP_CATEGORY_3: ' + LTRIM(RTRIM(@category_3)) + '; LP_CATEGORY_2: '
		SELECT @data = @data + LTRIM(RTRIM(@category_2)) + '; LP_CATEGORY_1: ; LP_CUBIC_FEET: ' + STR(@cubic_feet) + '; LP_SO_QTY_INCR: '
		SELECT @data = @data + STR(@so_qty_increment) + '; LP_WEIGHT: ' + STR(@weight_ea) + '; LP_CMDTY_CODE: '
		SELECT @data = @data + STR(@so_qty_increment) + '; LP_WEIGHT: ' + STR(@weight_ea) + '; LP_CMDTY_CODE: '
		SELECT @data = @data + LTRIM(RTRIM(@cmdty_code)) + '; LP_LENGTH: ' + STR(@length)+ '; LP_WIDTH: ' + STR(@width) + '; LP_HEIGHT: ' 
		SELECT @data = @data + STR(@height) + '; LP_SKU: ; LP_ADJ_DIR: OUT; LP_ADJ_CODE: CYC; ' 
		SELECT @data = @data + 'LP_REASON_CODE: ; LP_BASE_UOM: ' + LTRIM(RTRIM(@uom)) + '; LP_ITEM_UOM: ' + LTRIM(RTRIM(@uom))
		SELECT @data = @data + '; LP_BASE_QTY: ' + STR(((@bin_qty - @picked_qty) * -1)) + '; LP_LB_TRACKING: Y; LP_ITEM_DESC: '
		SELECT @data = @data + LTRIM(RTRIM(@description)) + '; '

		INSERT INTO tdc_log (tran_date,UserID,trans_source,module,trans,tran_no,tran_ext,part_no,
									lot_ser,bin_no,location,quantity,data) 										
		VALUES (getdate(), @userid, 'CO', 'ADH', 'ADHOC', CAST(@issue_no as varchar(10)), '', @part_no, @lot_ser, @bin_no, 
					@location, LTRIM(STR((@bin_qty - @picked_qty) * -1)), @data) 
		*/
		-- v2.6 End
	END

	-- Search for stock
	EXEC @retval = dbo.CVO_no_stock_check_stock_sp	@order_no, @order_ext, @line_no, @tran_id 
	
	-- No stock found
	IF @retval = -1
	BEGIN
		-- START v1.7
		IF ISNULL(@back_ord_flag,0) <> 1 -- v2.4
		-- END v1.7
		BEGIN
			-- Unallocate missing qty		
			-- Create working table for case association
			SELECT * INTO #cvo_ord_list FROM cvo_ord_list WHERE 1 = 2
			
			-- Call routine to build frame case relationship
			EXEC dbo.CVO_create_fc_relationship_sp @order_no, @order_ext
			-- v1.1 End
		
			-- Unallocate the missing quantity from the order
			SET @qty_to_unalloc = @orig_qty - @picked_qty
			
			UPDATE	tdc_soft_alloc_tbl   
			SET		qty = qty - @qty_to_unalloc,  
					trg_off = 1 
			WHERE	order_no = @order_no  
			AND		order_ext = @order_ext  
			AND		order_type = 'S'  
			AND		location = @location  
			AND		line_no = @line_no  
			AND		part_no = @part_no  
			AND		lot_ser = @lot_ser  
			AND		bin_no = @bin_no  
	 
			IF @@ERROR <> 0  
			BEGIN  
				RAISERROR ('Update tdc_soft_alloc_tbl table failed.  Unable to unallocate.',16, 1)  
				RETURN  
			END  
			
			-- If we have reduced the line to 0 then remove it
			IF EXISTS (SELECT 1 FROM tdc_soft_alloc_tbl WHERE	order_no = @order_no AND order_ext = @order_ext AND	order_type = 'S' AND location = @location  
														AND		line_no = @line_no  AND		part_no = @part_no  AND		lot_ser = @lot_ser  AND		bin_no = @bin_no  AND qty = 0)
			BEGIN
				DELETE FROM tdc_soft_alloc_tbl WHERE	order_no = @order_no AND order_ext = @order_ext AND	order_type = 'S' AND location = @location  
														AND		line_no = @line_no  AND		part_no = @part_no  AND		lot_ser = @lot_ser  AND		bin_no = @bin_no

				IF @@ERROR <> 0  
				BEGIN  
					RAISERROR ('Delete tdc_soft_alloc_tbl table failed.  Unable to unallocate.',16, 1)  
					RETURN  
				END  
			END

  			UPDATE	tdc_pick_queue   
			SET		qty_to_process = qty_to_process - @qty_to_unalloc  
			WHERE	tran_id = @tran_id
	  
			IF @@ERROR <> 0  
			BEGIN          
				RAISERROR ('Update tdc_pick_queue table failed.  Unable to unallocate.',16, 1)  
				RETURN  
			END  

			-- If we have reduced the line to 0 then remove it
			IF EXISTS (SELECT 1 FROM tdc_pick_queue WHERE tran_id = @tran_id AND qty_to_process = 0)
			BEGIN
				DELETE FROM tdc_pick_queue WHERE tran_id = @tran_id	
	  
				IF @@ERROR <> 0  
				BEGIN          
					RAISERROR ('Update tdc_pick_queue table failed.  Unable to unallocate.',16, 1)  
					RETURN  
				END 
			END

			UPDATE	tdc_soft_alloc_tbl   
			SET		trg_off = 0 
			WHERE	order_no = @order_no  
			AND		order_ext = @order_ext  
			AND		order_type = 'S'  
			AND		location = @location  
			AND		line_no = @line_no  
			AND		part_no = @part_no  
			AND		lot_ser = @lot_ser  
			AND		bin_no = @bin_no  
	  
			-- Log the record  
			INSERT INTO tdc_log (tran_date, UserID, trans_source, module, trans, tran_no, tran_ext, part_no,   
									lot_ser, bin_no, location, quantity, data)  
			SELECT getdate(), @userid, 'VB', 'PLWSO', 'UNALLOCATION', @order_no, @order_ext, @part_no,   
					@lot_ser,  @bin_no, @location, @qty_to_unalloc, 'line number = ' + RTRIM(CAST(@line_no AS varchar(10)))  

			-- v1.1 Start
			-- Adjust allocation for associated cases
			SET		@case_line_no = NULL
			SELECT	@case_line_no = line_no
			FROM	#cvo_ord_list
			WHERE	order_no = @order_no
			AND		order_ext = @order_ext
			AND		from_line_no = 	@line_no

			-- If case line exists
			IF (@case_line_no IS NOT NULL)
			BEGIN

				SELECT	@case_part = part_no
				FROM	ord_list (NOLOCK)
				WHERE	order_no = @order_no
				AND		order_ext = @order_ext
				AND		line_no = @case_line_no

				SELECT	@case_tran_id = COUNT(1) FROM tdc_soft_alloc_tbl (NOLOCK) WHERE order_no = @order_no AND order_ext = @order_ext AND line_no = @case_line_no
								AND part_no = @case_part AND order_type = 'S'
				IF (@case_tran_id > 0)
				BEGIN

					SELECT	@case_orig_qty = SUM(qty)
					FROM	tdc_soft_alloc_tbl (NOLOCK) 
					WHERE	order_no = @order_no 
					AND		order_ext = @order_ext 
					AND		line_no = @case_line_no
					AND		part_no = @case_part 
					AND		order_type = 'S'

					--IF (@orig_qty > @case_orig_qty)
					--	SET @case_unalloc_qty = @case_orig_qty - (@orig_qty - @qty_to_unalloc)
					--ELSE
						SET @case_unalloc_qty = @qty_to_unalloc

					SET	@case_last_id = 0
					SET @case_done = 0

					SELECT	TOP 1 @case_tran_id = tran_id,
							@case_bin = bin_no,
							@case_part = part_no,
							@case_lot_ser = lot,
							@case_qty = qty_to_process
					FROM	tdc_pick_queue (NOLOCK)
					WHERE	trans_type_no = @order_no
					AND		trans_type_ext = @order_ext
					AND		line_no = @case_line_no
					AND		trans = 'STDPICK'
					AND		tran_id > @case_last_id
					ORDER BY tran_id ASC

					WHILE (@@ROWCOUNT <> 0 AND @case_done = 0)
					BEGIN
						-- Does this pick cover the quantity to unallocate
						IF (@case_qty >= @case_unalloc_qty)
						BEGIN
						
							UPDATE	tdc_soft_alloc_tbl   
							SET		qty = qty - @case_unalloc_qty,  
									trg_off = 1 
							WHERE	order_no = @order_no  
							AND		order_ext = @order_ext  
							AND		order_type = 'S'  
							AND		location = @location  
							AND		line_no = @case_line_no  
							AND		part_no = @case_part  
							AND		lot_ser = @case_lot_ser  
							AND		bin_no = @case_bin  
					  
							IF @@ERROR <> 0  
							BEGIN  
								RAISERROR ('Update tdc_soft_alloc_tbl table failed.  Unable to unallocate.',16, 1)  
								RETURN  
							END  
					  
							-- If we have reduced the line to 0 then remove it
							IF EXISTS (SELECT 1 FROM tdc_soft_alloc_tbl WHERE	order_no = @order_no AND order_ext = @order_ext AND	order_type = 'S' AND location = @location  
																		AND		line_no = @case_line_no  AND	part_no = @case_part  AND	lot_ser = @case_lot_ser  AND	bin_no = @case_bin  AND qty = 0)
							BEGIN
								DELETE FROM tdc_soft_alloc_tbl WHERE	order_no = @order_no AND order_ext = @order_ext AND	order_type = 'S' AND location = @location  
																		AND		line_no = @case_line_no  AND	part_no = @case_part  AND	lot_ser = @case_lot_ser  AND	bin_no = @case_bin 

								IF @@ERROR <> 0  
								BEGIN  
									RAISERROR ('Delete tdc_soft_alloc_tbl table failed.  Unable to unallocate.',16, 1)  
									RETURN  
								END  
							END

							UPDATE	tdc_pick_queue   
							SET		qty_to_process = qty_to_process - @case_unalloc_qty  
							WHERE	tran_id = @case_tran_id
					  
							IF @@ERROR <> 0  
							BEGIN          
								RAISERROR ('Update tdc_pick_queue table failed.  Unable to unallocate.',16, 1)  
								RETURN  
							END  

							-- If we have reduced the line to 0 then remove it
							IF EXISTS (SELECT 1 FROM tdc_pick_queue WHERE tran_id = @case_tran_id AND qty_to_process = 0)
							BEGIN
								DELETE FROM tdc_pick_queue WHERE tran_id = @case_tran_id	
					  
								IF @@ERROR <> 0  
								BEGIN          
									RAISERROR ('Update tdc_pick_queue table failed.  Unable to unallocate.',16, 1)  
									RETURN  
								END 
							END

							UPDATE	tdc_soft_alloc_tbl   
							SET		trg_off = 0 
							WHERE	order_no = @order_no  
							AND		order_ext = @order_ext  
							AND		order_type = 'S'  
							AND		location = @location  
							AND		line_no = @case_line_no  
							AND		part_no = @case_part  
							AND		lot_ser = @case_lot_ser  
							AND		bin_no = @case_bin  
					  
							-- Log the record  
							INSERT INTO tdc_log (tran_date, UserID, trans_source, module, trans, tran_no, tran_ext, part_no,   
													lot_ser, bin_no, location, quantity, data)  
							SELECT getdate(), @userid, 'VB', 'PLWSO', 'UNALLOCATION', @order_no, @order_ext, @case_part,   
									@case_lot_ser,  @case_bin, @location, @case_unalloc_qty, 'line number = ' + RTRIM(CAST(@case_line_no AS varchar(10)))  

							SET @case_done = 1
						END
						ELSE
						BEGIN
							UPDATE	tdc_soft_alloc_tbl   
							SET		qty = qty - @case_qty,  
									trg_off = 1 
							WHERE	order_no = @order_no  
							AND		order_ext = @order_ext  
							AND		order_type = 'S'  
							AND		location = @location  
							AND		line_no = @case_line_no  
							AND		part_no = @case_part  
							AND		lot_ser = @case_lot_ser  
							AND		bin_no = @case_bin  
					  
							IF @@ERROR <> 0  
							BEGIN  
								RAISERROR ('Update tdc_soft_alloc_tbl table failed.  Unable to unallocate.',16, 1)  
								RETURN  
							END  
					  
							UPDATE	tdc_pick_queue   
							SET		qty_to_process = qty_to_process - @case_qty  
							WHERE	tran_id = @case_tran_id
					  
							IF @@ERROR <> 0  
							BEGIN          
								RAISERROR ('Update tdc_pick_queue table failed.  Unable to unallocate.',16, 1)  
								RETURN  
							END  

							UPDATE	tdc_soft_alloc_tbl   
							SET		trg_off = 0 
							WHERE	order_no = @order_no  
							AND		order_ext = @order_ext  
							AND		order_type = 'S'  
							AND		location = @location  
							AND		line_no = @case_line_no  
							AND		part_no = @case_part  
							AND		lot_ser = @case_lot_ser  
							AND		bin_no = @case_bin  
					  
							-- Log the record  
							INSERT INTO tdc_log (tran_date, UserID, trans_source, module, trans, tran_no, tran_ext, part_no,   
													lot_ser, bin_no, location, quantity, data)  
							SELECT getdate(), @userid, 'VB', 'PLWSO', 'UNALLOCATION', @order_no, @order_ext, @case_part,   
									@case_lot_ser,  @case_bin, @location, @case_qty, 'line number = ' + RTRIM(CAST(@case_line_no AS varchar(10)))  

							SET @case_unalloc_qty = @case_unalloc_qty - @case_qty

							IF (@case_unalloc_qty <= 0)
								SET @case_done = 1
							

						END

						SET	@case_last_id = @case_tran_id

						SELECT	TOP 1 @case_tran_id = tran_id,
								@case_bin = bin_no,
								@case_part = part_no,
								@case_lot_ser = lot,
								@case_qty = qty_to_process
						FROM	tdc_pick_queue (NOLOCK)
						WHERE	trans_type_no = @order_no
						AND		trans_type_ext = @order_ext
						AND		line_no = @case_line_no
						AND		trans = 'STDPICK'
						AND		tran_id > @case_last_id
						ORDER BY tran_id ASC
					END
				END				
			END
		
			-- Write soft allocation records for unallocated stock
			-- v1.3 Start
			SET @new_soft_alloc_no = NULL

			SELECT	@new_soft_alloc_no = soft_alloc_no
			FROM	cvo_soft_alloc_no_assign (NOLOCK)
			WHERE	order_no = @order_no
			AND		order_ext = @order_ext
		
			IF (@new_soft_alloc_no IS NULL)
			BEGIN

				-- v1.2 Start
				BEGIN TRAN
					UPDATE	dbo.cvo_soft_alloc_next_no
					SET		next_no = next_no + 1
				COMMIT TRAN	
				SELECT	@new_soft_alloc_no = next_no
				FROM	dbo.cvo_soft_alloc_next_no
			END
			-- v1.3 End

			-- Soft allocation header
			INSERT INTO cvo_soft_alloc_hdr (soft_alloc_no, order_no, order_ext, location, bo_hold, status)
			VALUES (@new_soft_alloc_no, @order_no, @order_ext, @location, 1, 0)	-- v2.0		

			INSERT	dbo.cvo_soft_alloc_det (soft_alloc_no, order_no, order_ext, line_no, location, part_no, quantity,  
												kit_part, change, deleted, is_case, is_pattern, is_pop_gift, status)
			SELECT	@new_soft_alloc_no, @order_no, @order_ext, @line_no, @location, @part_no, @orig_qty - @picked_qty, 0, 0, 0, 0, 0, 0, 0

			IF (ISNULL(@case_line_no,0) > 0)
			BEGIN
				INSERT	dbo.cvo_soft_alloc_det (soft_alloc_no, order_no, order_ext, line_no, location, part_no, quantity,  
													kit_part, change, deleted, is_case, is_pattern, is_pop_gift, status)
				SELECT	@new_soft_alloc_no, @order_no, @order_ext, @case_line_no, @location, @case_part, @orig_qty - @picked_qty, 0, 0, 0, 1, 0, 0, 0
			END
			-- v1.2 End

			DROP TABLE #cvo_ord_list
		END
		-- Put Ship Complete transactions on hold
		IF ISNULL(@back_ord_flag,0) = 1
		BEGIN
			-- v2.4 Start
			-- EXEC cvo_no_stock_hold_ship_complete_allocations_sp @order_no, @order_ext
			
			EXEC @ret = dbo.cvo_cancel_order_sp @order_no, @order_ext, @userid, @cust_code, @location, 2
			IF (@ret <> 0)
			BEGIN
				RAISERROR ('Ship Complete Order Reset Failed.', 16, 1)     
				SELECT -2
				RETURN
			END

			EXEC dbo.cvo_recreate_sa_sp	@order_no, @order_ext
			-- v2.4 End

		END
		
		/*
		-- Set the order on hold if the order is ship complete
		IF ISNULL(@back_ord_flag,0) = 1 AND (@hold_code IS NOT NULL)
		BEGIN
			UPDATE	orders_all
			SET		[status] = 'A',
					hold_reason = @hold_code
			WHERE	order_no = @order_no
			AND		ext = @order_ext
		END
		*/

		-- Send email if option enabled and order is not a backorder
		IF ISNULL(@notifications,0) = 1 AND @order_ext = 0 
		BEGIN
			-- START v1.5
			-- Ship Complete email
			IF ISNULL(@back_ord_flag,0) = 1
			BEGIN
				EXEC dbo.CVO_no_stock_email_sp	@order_no = @order_no, @order_ext = @order_ext, @line_no = @line_no, @type = 2
			END
			-- START v1.6
			--ELSE
			-- Allow BO email
			IF ISNULL(@back_ord_flag,0) = 0
			BEGIN
				EXEC dbo.CVO_no_stock_email_sp	@order_no = @order_no, @order_ext = @order_ext, @line_no = @line_no, @type = 1
			END

			-- Allow Partial email
			IF ISNULL(@back_ord_flag,0) = 2
			BEGIN
				EXEC dbo.CVO_no_stock_email_sp	@order_no = @order_no, @order_ext = @order_ext, @line_no = @line_no, @type = 3
			END
			-- END v1.6
			-- END v1.5
		END
	
		IF @@ERROR <> 0
		BEGIN
			RAISERROR ('No Stock Email Failed.', 16, 1)     
			SELECT -2
			RETURN 
		END
	END

	-- v2.5 Start
	IF (@removed_qty > 0)
		EXEC CVO_no_stock_admin_email_sp @order_no, @order_ext, @bin_no, @part_no, @removed_qty
	-- v2.5 End
	
	-- START v1.8
	-- Check there's nothing allocated
	IF NOT EXISTS (SELECT 1 FROM dbo.tdc_soft_alloc_tbl (NOLOCK) WHERE order_type = 'S' AND order_no = @order_no AND order_ext = @order_ext)
	BEGIN
		-- Check there's nothing already picked
		IF NOT EXISTS (SELECT 1 FROM dbo.tdc_carton_detail_tx (NOLOCK) WHERE order_no = @order_no AND order_ext = @order_ext)
		BEGIN
			-- v2.4 Start
			IF ISNULL(@back_ord_flag,0) = 1
			BEGIN
				UPDATE	dbo.orders_all
				SET		[status] = 'A', 
						printed = 'N',
						hold_reason = 'SC'
				WHERE	order_no = @order_no 
				AND		ext = @order_ext
				AND		[status] = 'N'	
			END
			ELSE
			BEGIN
				UPDATE
					dbo.orders_all
				SET
					[status] = 'N', 
					printed = 'N' -- v1.9 - TAG - 050114
				WHERE
					order_no = @order_no 
					AND ext = @order_ext
					AND [status] > 'N'	
			END
			-- v2.4 End
		END
	END
	-- END v1.8

	-- v2.3 Start
	SET @consolidation_no = NULL
	SELECT	@consolidation_no = consolidation_no 
	FROM	cvo_masterpack_consolidation_det (NOLOCK) 
	WHERE	order_no = @order_no
	AND		order_ext = @order_ext

	IF (@consolidation_no IS NOT NULL)
	BEGIN
		DELETE	cvo_masterpack_consolidation_det
		WHERE	order_no = @order_no
		AND		order_ext = @order_ext

		UPDATE	cvo_orders_all 
		SET		st_consolidate = 0
		WHERE	order_no = @order_no
		AND		ext = @order_ext

		IF NOT EXISTS (SELECT 1 FROM cvo_masterpack_consolidation_det (NOLOCK) WHERE consolidation_no = @consolidation_no)
		BEGIN
			DELETE	cvo_masterpack_consolidation_hdr
			WHERE	consolidation_no = @consolidation_no

			DELETE  cvo_st_consolidate_release
			WHERE	consolidation_no = @consolidation_no
			
		END
	END
	-- v2.3 End 


	SELECT @retval
	RETURN 

		/*
		-- v1.1 Start
		

		-- v1.3 Start
		SET @new_soft_alloc_no = NULL

		SELECT	@new_soft_alloc_no = soft_alloc_no
		FROM	cvo_soft_alloc_no_assign (NOLOCK)
		WHERE	order_no = @order_no
		AND		order_ext = @order_ext
	
		IF (@new_soft_alloc_no IS NULL)
		BEGIN

			-- v1.2 Start
			BEGIN TRAN
				UPDATE	dbo.cvo_soft_alloc_next_no
				SET		next_no = next_no + 1
			COMMIT TRAN	
			SELECT	@new_soft_alloc_no = next_no
			FROM	dbo.cvo_soft_alloc_next_no
		END
		-- v1.3 End

		-- Soft allocation header
		INSERT INTO cvo_soft_alloc_hdr (soft_alloc_no, order_no, order_ext, location, bo_hold, status)
		VALUES (@new_soft_alloc_no, @order_no, @order_ext, @location, 0, 0)			

		INSERT	dbo.cvo_soft_alloc_det (soft_alloc_no, order_no, order_ext, line_no, location, part_no, quantity,  
											kit_part, change, deleted, is_case, is_pattern, is_pop_gift, status)
		SELECT	@new_soft_alloc_no, @order_no, @order_ext, @line_no, @location, @part_no, @orig_qty - @picked_qty, 0, 0, 0, 0, 0, 0, 0

		IF (ISNULL(@case_line_no,0) > 0)
		BEGIN
			INSERT	dbo.cvo_soft_alloc_det (soft_alloc_no, order_no, order_ext, line_no, location, part_no, quantity,  
												kit_part, change, deleted, is_case, is_pattern, is_pop_gift, status)
			SELECT	@new_soft_alloc_no, @order_no, @order_ext, @case_line_no, @location, @case_part, @orig_qty - @picked_qty, 0, 0, 0, 1, 0, 0, 0
		END
		-- v1.2 End

		DROP TABLE #cvo_ord_list

		
		-- Process the missing stock and adjust out the missing quantity
		DELETE #adm_inv_adj

		INSERT INTO #adm_inv_adj (loc, part_no, bin_no, lot_ser, date_exp, qty, direction, who_entered, 
									reason_code, code) 									
		VALUES(@location, @part_no, @bin_no, @lot_ser, @date_expires, (@bin_qty - @picked_qty), -1, @userid, '', 'CYC')

		EXEC dbo.tdc_adm_inv_adj 		

		SELECT	@issue_no = max(issue_no) 
		FROM	dbo.issues
		WHERE	part_no = @part_no
		AND		code = 'CYC'

		SELECT	@uom = uom, @description = description FROM inventory (nolock) WHERE part_no = @part_no AND location = @location 
		SELECT	@group_code = group_code FROM tdc_bin_master (nolock) WHERE location = @location AND bin_no = @bin_no
		SELECT	@sku_code = isnull(sku_code, ''), @height = height, @width = width, @length = length, 
				@cmdty_code = isnull(cmdty_code, ''), @weight_ea = weight_ea, @so_qty_increment = isnull(so_qty_increment, 0), 
				@cubic_feet = cubic_feet 
		FROM	inv_master (nolock) WHERE part_no = @part_no
		SELECT	@category_1 = isnull(category_1, ''), @category_2 = isnull(category_2, ''), 
				@category_3 = isnull(category_3, ''), @category_4 = isnull(category_4, ''), 
				@category_5 = isnull(category_5, '') 
		FROM	inv_master_add (nolock) WHERE part_no = @part_no
		SELECT	@UPC = ISNULL(UPC, ''), @GTIN = ISNULL(GTIN, ''), @EAN_8 = ISNULL(EAN_8, ''), 
				@EAN_13 = ISNULL(EAN_13, ''), @EAN_14 = ISNULL(EAN_14, '')						
		FROM	uom_id_code (nolock) WHERE part_no = @part_no 
		AND		UOM = @uom

		SELECT @data = 'LP_ITEM_EAN14: ; LP_ITEM_EAN13: ; LP_ITEM_EAN8: ; LP_ITEM_GTIN: ; LP_ITEM_UPC: ' 
		SELECT @data = @data + LTRIM(RTRIM(@UPC)) + '; LP_CATEGORY_5: '+ LTRIM(RTRIM(@category_2)) + '; LP_CATEGORY_4: ' 
		SELECT @data = @data + LTRIM(RTRIM(@category_4)) + '; LP_CATEGORY_3: ' + LTRIM(RTRIM(@category_3)) + '; LP_CATEGORY_2: '
		SELECT @data = @data + LTRIM(RTRIM(@category_2)) + '; LP_CATEGORY_1: ; LP_CUBIC_FEET: ' + STR(@cubic_feet) + '; LP_SO_QTY_INCR: '
		SELECT @data = @data + STR(@so_qty_increment) + '; LP_WEIGHT: ' + STR(@weight_ea) + '; LP_CMDTY_CODE: '
		SELECT @data = @data + STR(@so_qty_increment) + '; LP_WEIGHT: ' + STR(@weight_ea) + '; LP_CMDTY_CODE: '
		SELECT @data = @data + LTRIM(RTRIM(@cmdty_code)) + '; LP_LENGTH: ' + STR(@length)+ '; LP_WIDTH: ' + STR(@width) + '; LP_HEIGHT: ' 
		SELECT @data = @data + STR(@height) + '; LP_SKU: ; LP_ADJ_DIR: OUT; LP_ADJ_CODE: CYC; ' 
		SELECT @data = @data + 'LP_REASON_CODE: ; LP_BASE_UOM: ' + LTRIM(RTRIM(@uom)) + '; LP_ITEM_UOM: ' + LTRIM(RTRIM(@uom))
		SELECT @data = @data + '; LP_BASE_QTY: ' + STR(((@bin_qty - @picked_qty) * -1)) + '; LP_LB_TRACKING: Y; LP_ITEM_DESC: '
		SELECT @data = @data + LTRIM(RTRIM(@description)) + '; '

		INSERT INTO tdc_log (tran_date,UserID,trans_source,module,trans,tran_no,tran_ext,part_no,
									lot_ser,bin_no,location,quantity,data) 										
		VALUES (getdate(), @userid, 'CO', 'ADH', 'ADHOC', CAST(@issue_no as varchar(10)), '', @part_no, @lot_ser, @bin_no, 
					@location, LTRIM(STR((@bin_qty - @picked_qty) * -1)), @data) 
		
		SET @new_order_no = -1
		IF (@hold_code IS NOT NULL)
			EXEC dbo.CVO_no_stock_email_sp	@order_no, @order_ext, @new_order_no, @line_no

		IF @@ERROR <> 0
		BEGIN
			RAISERROR ('No Stock Email Failed.', 16, 1)     
			RETURN
		END
	END -- End Allow backorder or ship partial
	ELSE
	BEGIN -- Ship Complete
	
		-- If the order is still new then do not call the cancellation routine just unallocate
		IF @status < 'P'
		BEGIN
		
			-- UnAllocate any item that did allocate
			EXEC CVO_UnAllocate_sp @order_no, @order_ext, 0, @userid

			IF (@hold_code IS NOT NULL)
			BEGIN

				-- Set the order on hold
				UPDATE	orders_all
				SET		status = 'A',
						hold_reason = @hold_code
				WHERE	order_no = @order_no
				AND		ext = @order_ext
			END

			-- Create the soft allocation
			EXEC dbo.cvo_create_soft_alloc_sp @order_no, @order_ext

			UPDATE	cvo_soft_alloc_det
			SET		inv_avail = NULL
			WHERE	order_no = @order_no
			AND		order_ext = @order_ext
			AND		line_no = @line_no
			AND		status = 0

		END
		ELSE
		BEGIN

			INSERT	#ordercancel (ret, ret_message, new_order_no)
			EXEC	dbo.cvo_cancel_order_sp	@order_no, @order_ext, @userid, @cust_code, @location, 1 -- v1.2

			SELECT	@ret = ret, @ret_message = ret_message, @new_order_no = new_order_no FROM #ordercancel

			IF (@ret IS NULL OR @ret < 0)
			BEGIN
				RAISERROR ('Order Cancel Failed.', 16, 1)     
				RETURN
			END

			-- Update the note on the old order
			UPDATE 	orders_all
			SET		note = 'Voided order ' + CAST(@order_no AS varchar(20)) + ' - missing stock. ' + note
			WHERE	order_no = @order_no
			AND		ext = @order_ext

			IF (@hold_code IS NOT NULL AND @new_order_no > 0)
			BEGIN
				-- Set the order on hold
				UPDATE	orders_all
				SET		status = 'A',
						note =  'Original order voided. New order:' + CAST(@new_order_no as varchar(20)) + ' has been created.' + note,
						hold_reason = @hold_code
				WHERE	order_no = @new_order_no
				AND		ext = 0
			END

			UPDATE	cvo_soft_alloc_det
			SET		inv_avail = NULL
			WHERE	order_no = @order_no
			AND		order_ext = @order_ext
			AND		line_no = @line_no
			AND		status = 0

		END

		-- Email No Stock Confirmation
		IF @status < 'P'
			SET @new_order_no = -1

		IF (@hold_code IS NOT NULL)
			EXEC dbo.CVO_no_stock_email_sp	@order_no, @order_ext, @new_order_no, @line_no

		IF @@ERROR <> 0
		BEGIN
			RAISERROR ('No Stock Email Failed.', 16, 1)     
			RETURN
		END

		-- Stock Adjustment
		IF EXISTS(SELECT 1 FROM lot_bin_stock (NOLOCK) WHERE bin_no = @bin_no AND location = @location AND part_no = @part_no AND lot_ser = @lot_ser AND @bin_qty > @picked_qty)
		BEGIN

			DELETE #adm_inv_adj

			INSERT INTO #adm_inv_adj (loc, part_no, bin_no, lot_ser, date_exp, qty, direction, who_entered, 
										reason_code, code) 									
			VALUES(@location, @part_no, @bin_no, @lot_ser, @date_expires, (@bin_qty - @picked_qty), -1, @userid, '', 'CYC')

			EXEC dbo.tdc_adm_inv_adj 		

			SELECT	@issue_no = max(issue_no) 
			FROM	dbo.issues
			WHERE	part_no = @part_no
			AND		code = 'CYC'

			SELECT	@uom = uom, @description = description FROM inventory (nolock) WHERE part_no = @part_no AND location = @location 
			SELECT	@group_code = group_code FROM tdc_bin_master (nolock) WHERE location = @location AND bin_no = @bin_no
			SELECT	@sku_code = isnull(sku_code, ''), @height = height, @width = width, @length = length, 
					@cmdty_code = isnull(cmdty_code, ''), @weight_ea = weight_ea, @so_qty_increment = isnull(so_qty_increment, 0), 
					@cubic_feet = cubic_feet 
			FROM	inv_master (nolock) WHERE part_no = @part_no
			SELECT	@category_1 = isnull(category_1, ''), @category_2 = isnull(category_2, ''), 
					@category_3 = isnull(category_3, ''), @category_4 = isnull(category_4, ''), 
					@category_5 = isnull(category_5, '') 
			FROM	inv_master_add (nolock) WHERE part_no = @part_no
			SELECT	@UPC = ISNULL(UPC, ''), @GTIN = ISNULL(GTIN, ''), @EAN_8 = ISNULL(EAN_8, ''), 
					@EAN_13 = ISNULL(EAN_13, ''), @EAN_14 = ISNULL(EAN_14, '')						
			FROM	uom_id_code (nolock) WHERE part_no = @part_no 
			AND		UOM = @uom

			SELECT @data = 'LP_ITEM_EAN14: ; LP_ITEM_EAN13: ; LP_ITEM_EAN8: ; LP_ITEM_GTIN: ; LP_ITEM_UPC: ' 
			SELECT @data = @data + LTRIM(RTRIM(@UPC)) + '; LP_CATEGORY_5: '+ LTRIM(RTRIM(@category_2)) + '; LP_CATEGORY_4: ' 
			SELECT @data = @data + LTRIM(RTRIM(@category_4)) + '; LP_CATEGORY_3: ' + LTRIM(RTRIM(@category_3)) + '; LP_CATEGORY_2: '
			SELECT @data = @data + LTRIM(RTRIM(@category_2)) + '; LP_CATEGORY_1: ; LP_CUBIC_FEET: ' + STR(@cubic_feet) + '; LP_SO_QTY_INCR: '
			SELECT @data = @data + STR(@so_qty_increment) + '; LP_WEIGHT: ' + STR(@weight_ea) + '; LP_CMDTY_CODE: '
			SELECT @data = @data + STR(@so_qty_increment) + '; LP_WEIGHT: ' + STR(@weight_ea) + '; LP_CMDTY_CODE: '
			SELECT @data = @data + LTRIM(RTRIM(@cmdty_code)) + '; LP_LENGTH: ' + STR(@length)+ '; LP_WIDTH: ' + STR(@width) + '; LP_HEIGHT: ' 
			SELECT @data = @data + STR(@height) + '; LP_SKU: ; LP_ADJ_DIR: OUT; LP_ADJ_CODE: CYC; ' 
			SELECT @data = @data + 'LP_REASON_CODE: ; LP_BASE_UOM: ' + LTRIM(RTRIM(@uom)) + '; LP_ITEM_UOM: ' + LTRIM(RTRIM(@uom))
			SELECT @data = @data + '; LP_BASE_QTY: ' + STR(((@bin_qty - @picked_qty) * -1)) + '; LP_LB_TRACKING: Y; LP_ITEM_DESC: '
			SELECT @data = @data + LTRIM(RTRIM(@description)) + '; '

			INSERT INTO tdc_log (tran_date,UserID,trans_source,module,trans,tran_no,tran_ext,part_no,
										lot_ser,bin_no,location,quantity,data) 										
			VALUES (getdate(), @userid, 'CO', 'ADH', 'ADHOC', CAST(@issue_no as varchar(10)), '', @part_no, @lot_ser, @bin_no, 
						@location, LTRIM(STR((@bin_qty - @picked_qty) * -1)), @data) 
		END
	END -- End Ship Complete

	-- Clean up
	DROP TABLE #ordercancel

	*/
	-- END v1.4
END
GO
GRANT EXECUTE ON  [dbo].[CVO_no_stock_process_partial_sp] TO [public]
GO
