SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[CVO_no_stock_process_partial_cons_sp]	@cons_no int,
															@picked_qty decimal(20,8),
															@orig_qty decimal(20,8),
															@userid varchar(50),
															@station_id varchar(10),
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
			@orig_unalloc	decimal(20,8),
			@case_line_no	int,
			@case_bin		varchar(20),
			@case_part		varchar(30),
			@case_tran_id	int,
			@case_lot_ser	varchar(25),
			@case_qty		decimal(20,8), 
			@case_last_id	int, 
			@case_done		int, 
			@case_unalloc_qty	decimal(20,8), 
			@case_orig_qty	decimal(20,8),
			@new_soft_alloc_no int, 
			@notifications	SMALLINT, 
			@retval			INT,
			@order_no		int,
			@order_ext		int,
			@line_no		int,
			@location		varchar(10),
			@part_no		varchar(30),
			@bin_no			varchar(20),
			@lot_ser		varchar(25),
			@row_id			int,
			@last_row_id	int,
			@child_tran_id	int,
			@qty_required	DECIMAL(20,8),
			@stat_id		int,
			@consolidation_no int -- v1.1
 
	IF (@station_id > '')
		SET @stat_id =  CAST(@station_id as int)
	ELSE
		SET @stat_id =  0

	IF (SELECT OBJECT_ID('tempdb..#remove_parent_trans')) IS NOT NULL 
	BEGIN   
		DROP TABLE #remove_parent_trans  
	END

	CREATE TABLE #remove_parent_trans (
		tran_id		int)


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

	SELECT	@location = location,
			@part_no = part_no,	
			@bin_no = bin_no, 
			@lot_ser = lot
	FROM	tdc_pick_queue (NOLOCK)
	WHERE	tran_id = @tran_id

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
	SELECT	@hold_code = a.hold_code,
			@hold_reason = a.hold_reason,
			@notifications = b.notifications 
	FROM	adm_oehold a (NOLOCK)
	JOIN	so_usrcateg b (NOLOCK)
	ON		a.hold_code = b.no_stock_hold
	JOIN	orders_all c (NOLOCK)
	ON		b.category_code = c.user_category
	WHERE	c.order_no = @order_no
	AND		c.ext = @order_ext	

	-- Pick what was entered in the console screen
	IF @picked_qty > 0
	BEGIN
		EXEC dbo.cvo_masterpack_pick_consolidated_transaction_sp @tran_id, @picked_qty, @stat_id, @userid
	END

	-- Adjust off what was missing from bin 
	IF (@bin_qty - @picked_qty) > 0
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

	-- Search for stock
	EXEC @retval = dbo.CVO_no_stock_check_stock_cons_sp	@cons_no, @tran_id 
	
	-- No stock found
	IF @retval = -1
	BEGIN

		CREATE TABLE #no_stock_cons (
			row_id		int IDENTITY(1,1),
			order_no	int,
			order_ext	int,
			line_no		int,
			location	varchar(10),
			part_no		varchar(30),
			qty_req		decimal(20,8),
			bin_no		varchar(12),
			lot_ser		varchar(25),
			tran_id		int)

		INSERT	#remove_parent_trans
		SELECT	@tran_id

		INSERT	#no_stock_cons (order_no, order_ext, line_no, location, part_no, qty_req, bin_no, lot_ser, tran_id)
		SELECT	a.trans_type_no,
				a.trans_type_ext,
				a.line_no,
				a.location,
				a.part_no,
				a.qty_to_process,
				a.bin_no,
				a.lot,
				a.tran_id
		FROM	tdc_pick_queue a (NOLOCK)
		JOIN	cvo_masterpack_consolidation_picks b (NOLOCK)
		ON		a.tran_id = b.child_tran_id
		WHERE	b.parent_tran_id = @tran_id

		SET @last_row_id = 0
		SET @qty_to_unalloc = @orig_qty - @picked_qty
		SET @orig_unalloc = @qty_to_unalloc

		SELECT	TOP 1 @row_id = row_id,
				@order_no = order_no,
				@order_ext = order_ext,
				@line_no = line_no,
				@location = location,
				@part_no = part_no,
				@qty_required = qty_req,
				@bin_no = bin_no,
				@lot_ser = lot_ser,
				@child_tran_id = tran_id
		FROM	#no_stock_cons
		WHERE	row_id > @last_row_id
		ORDER BY row_id ASC

		WHILE (@@ROWCOUNT <> 0)
		BEGIN

			-- Unallocate missing qty		
			-- Create working table for case association
			IF (OBJECT_ID('tempdb..#cvo_ord_list') IS NOT NULL)
				DROP TABLE #cvo_ord_list

			SELECT * INTO #cvo_ord_list FROM cvo_ord_list WHERE 1 = 2
			
			-- Call routine to build frame case relationship
			EXEC dbo.CVO_create_fc_relationship_sp @order_no, @order_ext
		
			-- Unallocate the missing quantity from the order
			IF (@qty_to_unalloc < @qty_required)
			BEGIN
				SET @qty_required = @qty_to_unalloc
			END

			SET @qty_to_unalloc = @qty_to_unalloc - @qty_required						
		
			UPDATE	tdc_soft_alloc_tbl   
			SET		qty = qty - @qty_required,  
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
			IF EXISTS (SELECT 1 FROM tdc_soft_alloc_tbl (NOLOCK) WHERE order_no = @order_no AND order_ext = @order_ext AND	order_type = 'S' AND location = @location  
						AND line_no = @line_no AND part_no = @part_no AND lot_ser = @lot_ser AND bin_no = @bin_no AND qty = 0)
			BEGIN
				DELETE	tdc_soft_alloc_tbl 
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
					RAISERROR ('Delete tdc_soft_alloc_tbl table failed.  Unable to unallocate.',16, 1)  
					RETURN  
				END  
			END

			UPDATE	tdc_pick_queue   
			SET		qty_to_process = qty_to_process - @qty_required  
			WHERE	tran_id = @child_tran_id
  
			IF @@ERROR <> 0  
			BEGIN          
				RAISERROR ('Update tdc_pick_queue table failed.  Unable to unallocate.',16, 1)  
				RETURN  
			END  

			-- If we have reduced the line to 0 then remove it
			IF EXISTS (SELECT 1 FROM tdc_pick_queue (NOLOCK) WHERE tran_id = @child_tran_id AND qty_to_process = 0)
			BEGIN
				DELETE FROM tdc_pick_queue WHERE tran_id = @child_tran_id	

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
					@lot_ser,  @bin_no, @location, @qty_required, 'line number = ' + RTRIM(CAST(@line_no AS varchar(10)))  

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

					SET @case_unalloc_qty = @qty_required

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
							IF EXISTS (SELECT 1 FROM tdc_soft_alloc_tbl (NOLOCK) WHERE	order_no = @order_no AND order_ext = @order_ext AND	order_type = 'S' AND location = @location  
											AND line_no = @case_line_no AND	part_no = @case_part  AND	lot_ser = @case_lot_ser  AND	bin_no = @case_bin  AND qty = 0)
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

							UPDATE	a
							SET		qty_to_process = a.qty_to_process - @case_unalloc_qty
							FROM	tdc_pick_queue a
							JOIN	cvo_masterpack_consolidation_picks b (NOLOCK)
							ON		a.tran_id = b.parent_tran_id
							WHERE	b.consolidation_no = @cons_no
							AND		b.child_tran_id = @case_tran_id

				  
							IF @@ERROR <> 0  
							BEGIN          
								RAISERROR ('Update tdc_pick_queue table failed.  Unable to unallocate.',16, 1)  
								RETURN  
							END  

							-- If we have reduced the line to 0 then remove it
							IF EXISTS (SELECT 1 FROM tdc_pick_queue (NOLOCK) WHERE tran_id = @case_tran_id AND qty_to_process = 0)
							BEGIN
								DELETE FROM tdc_pick_queue WHERE tran_id = @case_tran_id	

								INSERT	#remove_parent_trans
								SELECT	parent_tran_id
								FROM	cvo_masterpack_consolidation_picks (NOLOCK)
								WHERE	child_tran_id = @case_tran_id
								AND		consolidation_no = @cons_no
				  
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

							UPDATE	a
							SET		qty_to_process = a.qty_to_process - @case_qty
							FROM	tdc_pick_queue a
							JOIN	cvo_masterpack_consolidation_picks b (NOLOCK)
							ON		a.tran_id = b.parent_tran_id
							WHERE	b.consolidation_no = @cons_no
							AND		b.child_tran_id = @case_tran_id
				  
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
			SET @new_soft_alloc_no = NULL

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

			-- Soft allocation header
			INSERT INTO cvo_soft_alloc_hdr (soft_alloc_no, order_no, order_ext, location, bo_hold, status)
			VALUES (@new_soft_alloc_no, @order_no, @order_ext, @location, 1, 0)	-- v2.0		

			INSERT	dbo.cvo_soft_alloc_det (soft_alloc_no, order_no, order_ext, line_no, location, part_no, quantity,  
												kit_part, change, deleted, is_case, is_pattern, is_pop_gift, status)
			SELECT	@new_soft_alloc_no, @order_no, @order_ext, @line_no, @location, @part_no, @qty_required, 0, 0, 0, 0, 0, 0, 0

			IF (ISNULL(@case_line_no,0) > 0)
			BEGIN
				INSERT	dbo.cvo_soft_alloc_det (soft_alloc_no, order_no, order_ext, line_no, location, part_no, quantity,  
													kit_part, change, deleted, is_case, is_pattern, is_pop_gift, status)
				SELECT	@new_soft_alloc_no, @order_no, @order_ext, @case_line_no, @location, @case_part, @qty_required, 0, 0, 0, 1, 0, 0, 0
			END

			DROP TABLE #cvo_ord_list
		
			-- Put Ship Complete transactions on hold
			IF ISNULL(@back_ord_flag,0) = 1
			BEGIN
				EXEC cvo_no_stock_hold_ship_complete_allocations_sp @order_no, @order_ext
			END
		
			-- Send email if option enabled and order is not a backorder
			IF ISNULL(@notifications,0) = 1 AND @order_ext = 0 
			BEGIN
				-- Ship Complete email
				IF ISNULL(@back_ord_flag,0) = 1
				BEGIN
					EXEC dbo.CVO_no_stock_email_sp	@order_no = @order_no, @order_ext = @order_ext, @line_no = @line_no, @type = 2
				END
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
			END
	
			IF @@ERROR <> 0
			BEGIN
				RAISERROR ('No Stock Email Failed.', 16, 1)     
				SELECT -2
				RETURN 
			END
	
			-- Check there's nothing allocated
			IF NOT EXISTS (SELECT 1 FROM dbo.tdc_soft_alloc_tbl (NOLOCK) WHERE order_type = 'S' AND order_no = @order_no AND order_ext = @order_ext)
			BEGIN
				-- Check there's nothing already picked
				IF NOT EXISTS (SELECT 1 FROM dbo.tdc_carton_detail_tx (NOLOCK) WHERE order_no = @order_no AND order_ext = @order_ext)
				BEGIN
					UPDATE
						dbo.orders_all
					SET
						[status] = 'N', 
						printed = 'N' 
					WHERE
						order_no = @order_no 
						AND ext = @order_ext
						AND [status] > 'N'
				END
			END

			-- v1.1 Start
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
			-- v1.1 End 

			IF (@qty_to_unalloc <= 0)
				BREAK


			SET @last_row_id = @row_id

			SELECT	TOP 1 @row_id = row_id,
					@order_no = order_no,
					@order_ext = order_ext,
					@line_no = line_no,
					@location = location,
					@part_no = part_no,
					@qty_required = qty_req,
					@bin_no = bin_no,
					@lot_ser = lot_ser,
					@child_tran_id = tran_id
			FROM	#no_stock_cons
			WHERE	row_id > @last_row_id
			ORDER BY row_id ASC
		END	
	END

	DELETE	a
	FROM	tdc_pick_queue a
	JOIN	#remove_parent_trans b
	ON		a.tran_id = b.tran_id

	SELECT @retval
	RETURN 
	
END
GO
GRANT EXECUTE ON  [dbo].[CVO_no_stock_process_partial_cons_sp] TO [public]
GO
