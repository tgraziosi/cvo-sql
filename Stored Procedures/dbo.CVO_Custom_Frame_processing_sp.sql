SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Procedure CVO_Custom_Frame_processing_sp    Script Date: 12/01/2010  ***** 
Object:      Procedure  CVO_Custom_Frame_processing_sp  
Source file: CVO_Custom_Frame_processing_sp.sql
Author:		 Craig Boston
Created:	 12/10/2010
Function:    
Modified:    
Calls:    
Called by:   
Copyright:   Epicor Software 2010.  All rights reserved.  
v1.1 CB 02/07/2012 - CVO-CF-1 Custom Frame Processing - Auto pick completed frame
v1.2 CB 10/07/2012 - CVO-CF-1 Custom Frame Processing - Ensure bins used are OPEN or REPLENISH when search for part return bins
v1.3 CB 23/07/2012 - Exclude CUSTOM bins from bin search
v1.4 CB 27/07/2012 - Remove v1.1
v1.5 CB 27/07/2012 - Use primary and secondary bins for final part putaway
v1.6 CT 07/08/2012 - If no primary, secondary or bins containing part exist, use default bin from config
v1.7 CB 13/09/2012 - Use only OPEN bins and fix issue if primary bin is not set it returns blank and not null
v1.8 CB 26/11/2012 - Issue #975 - Custom Frame Putaway label

BEGIN TRAN
select * from tdc_pick_queue where tran_id = 6911
EXEC CVO_Custom_Frame_processing_sp 1,1306,0,1,'001','BCALBBRO5115','1',1
select * from tdc_pick_queue where trans_type_no = 1306
ROLLBACK TRAN


*/

CREATE PROC [dbo].[CVO_Custom_Frame_processing_sp]	@type int,
												@order_no int,
												@order_ext int,
												@line_no int,
												@location varchar(10),
												@part_no varchar(30),
												@lot varchar(25),
												@qty decimal(20,8),
												@bin_no varchar(25) = NULL
AS
BEGIN
	-- Declarations
	DECLARE	@qty_processed	decimal(20,8),
			@reason_code	varchar(10),
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
			@tx_lock		varchar(2),
			@last_part_no	varchar(30),
			@dest_bin_no	varchar(20),
			@priority		int,
			@SeqNo			int,
			@Bin2BinGroupId	varchar(25),
			@type_code		varchar(30),
			@f_line_no		int, -- v1.1
			@f_part_no		varchar(30), -- v1.1
			@f_qty			decimal(20,8), -- v1.1
			@f_lot			varchar(25), -- v1.1
			@f_expires		varchar(12), -- v1.1
			@f_queue_tran	int, -- v1.1
			@userid			varchar(50) -- v1.8

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


	-- Processing the substituted components from a custom frame
	-- When MGTB2B queue transaction is processed then create an adhoc adjustment to move them out of stock
	-- Get the information from the record
	SELECT	@dest_bin_no = ISNULL((SELECT value_str FROM tdc_config (nolock)  
				WHERE [function] = 'CVO_CUSTOM_BIN' AND active = 'Y'), 'UNKNOWN')

	SELECT	@type_code = type_code
	FROM	inv_master (NOLOCK)
	WHERE	part_no = @part_no

	IF @type = 0 AND @bin_no = @dest_bin_no AND UPPER(@type_code) = 'PARTS'
	BEGIN
--		SELECT	@location = location,
--				@part_no = part_no,
--				@bin_no = next_op,
--				@lot = lot,
--				@qty = qty_to_process,
--				@qty_processed = qty_to_process,
--				@order_no = trans_type_no,
--				@order_ext = trans_type_ext,
--				@line_no = line_no,
--				@tx_lock = tx_lock
--		FROM	deleted
--		WHERE	trans = 'MGTB2B'
--		AND		trans_type_no > 0
--		AND		line_no > 0

		-- If a record has been picked up then process it
		IF @location IS NOT NULL
		BEGIN

			-- Only process if this queue record is be processed properly
--			IF @tx_lock <> 'C'
--				RETURN


			-- Create a adhoc stock adjustment to remove the stock

			SELECT @reason_code = ISNULL((SELECT value_str FROM tdc_config (nolock)  
						WHERE [function] = 'CUS_FRAME_CONS' AND active = 'Y'), 'CUS')		 
				
			SELECT	@date_expires = CONVERT(varchar(12), date_expires, 101) 								
			FROM	lot_bin_stock (nolock) 								
			WHERE	location = @location 
			AND		part_no = @part_no 
			AND		bin_no = @bin_no 
			AND		lot_ser = @lot

			INSERT INTO #adm_inv_adj (loc, part_no, bin_no, lot_ser, date_exp, qty, direction, who_entered, 
										reason_code, code) 									
			VALUES(@location, @part_no, @bin_no, @lot, @date_expires, @qty, -1,'CustomFrames', '', @reason_code)

			EXEC dbo.tdc_adm_inv_adj 

			SELECT	@issue_no = max(issue_no) 
			FROM	dbo.issues
			WHERE	part_no = @part_no
			AND		code = @reason_code

			INSERT INTO dbo.tdc_ei_bin_log (module, trans, tran_no, tran_ext, location, part_no, from_bin, 
						userid, direction, quantity) 														  
			VALUES( 'ADH', 'ADHOC', @issue_no, 0, @location, @part_no, @bin_no, 'CustomFrames', -1, @qty)

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

			INSERT INTO dbo.tdc_3pl_issues_log (trans, issue_no, location, part_no, bin_no, bin_group, uom, 
									qty, userid, expert) 																
			VALUES ('ADHOC', @issue_no,	 @location, @part_no, @bin_no, @group_code, @uom, (@qty * -1),  
						'CustomFrames', 'N')
			
			SELECT @data = 'LP_ITEM_EAN14: ; LP_ITEM_EAN13: ; LP_ITEM_EAN8: ; LP_ITEM_GTIN: ; LP_ITEM_UPC: ' 
			SELECT @data = @data + LTRIM(RTRIM(@UPC)) + '; LP_CATEGORY_5: '+ LTRIM(RTRIM(@category_2)) + '; LP_CATEGORY_4: ' 
			SELECT @data = @data + LTRIM(RTRIM(@category_4)) + '; LP_CATEGORY_3: ' + LTRIM(RTRIM(@category_3)) + '; LP_CATEGORY_2: '
			SELECT @data = @data + LTRIM(RTRIM(@category_2)) + '; LP_CATEGORY_1: ; LP_CUBIC_FEET: ' + STR(@cubic_feet) + '; LP_SO_QTY_INCR: '
			SELECT @data = @data + STR(@so_qty_increment) + '; LP_WEIGHT: ' + STR(@weight_ea) + '; LP_CMDTY_CODE: '
			SELECT @data = @data + STR(@so_qty_increment) + '; LP_WEIGHT: ' + STR(@weight_ea) + '; LP_CMDTY_CODE: '
			SELECT @data = @data + LTRIM(RTRIM(@cmdty_code)) + '; LP_LENGTH: ' + STR(@length)+ '; LP_WIDTH: ' + STR(@width) + '; LP_HEIGHT: ' 
			SELECT @data = @data + STR(@height) + '; LP_SKU: ; LP_ADJ_DIR: OUT; LP_ADJ_CODE: ' + LTRIM(RTRIM(@reason_code)) + '; ' 
			SELECT @data = @data + 'LP_REASON_CODE: ; LP_BASE_UOM: ' + LTRIM(RTRIM(@uom)) + '; LP_ITEM_UOM: ' + LTRIM(RTRIM(@uom))
			SELECT @data = @data + '; LP_BASE_QTY: ' + STR((@qty * -1)) + '; LP_LB_TRACKING: Y; LP_ITEM_DESC: '
			SELECT @data = @data + LTRIM(RTRIM(@description)) + '; '

			INSERT INTO tdc_log (tran_date,UserID,trans_source,module,trans,tran_no,tran_ext,part_no,
										lot_ser,bin_no,location,quantity,data) 										
			VALUES (getdate(), 'CustomFrames', 'CO', 'ADH', 'ADHOC', STR(@issue_no), '', @part_no, @lot, @bin_no, 
						@location, LTRIM(STR(@qty * -1)), @data) 

			-- Update the order to picked
			UPDATE	orders_all
			SET		status = 'P',
					printed = 'P'
			WHERE	order_no = @order_no
			AND		ext = @order_ext
			AND		status < 'R'


		END
	END


	IF @type = 1
	BEGIN
	
		-- Processing the components of a custom frame when they have been substituted
		-- When the standard pick is processed create a adhoc adjustment into stock of the components and create
		-- MGTB2B moves
		-- Get the information from the record
--		SELECT	@location = location,
--				@part_no = part_no,
--				@bin_no = next_op,
--				@lot = lot,
--				@qty = qty_processed,
--				@qty_processed = qty_processed,
--				@order_no = trans_type_no,
--				@order_ext = trans_type_ext,
--				@line_no = line_no,
--				@tx_lock = tx_lock
--		FROM	deleted
--		WHERE	trans = 'STDPICK'
--		AND		trans_type_no > 0
--		AND		line_no > 0


		-- Check if this item is a kit and if there have been any substitutions
		IF EXISTS (SELECT 1 FROM dbo.cvo_ord_list_kit (NOLOCK) WHERE order_no = @order_no AND order_ext = @order_ext
					AND line_no = @line_no AND replaced = 'S')
		BEGIN
		
			-- For Each substitution do an adhoc adjustment in to stock and create MGTB2B transactions
			SET @last_part_no = ''

			SELECT TOP 1 @part_no = part_no_original
			FROM	dbo.CVO_ord_list_kit (NOLOCK)
			WHERE	order_no = @order_no
			AND		order_ext = @order_ext
			AND		line_no = @line_no
			AND		replaced = 'S'
			AND		part_no_original > @last_part_no
			ORDER BY part_no_original

			WHILE @@ROWCOUNT <> 0
			BEGIN
				
				-- Clear out the temp adjustment table
				TRUNCATE TABLE #adm_inv_adj

				-- Create stock adjustment
				SELECT @reason_code = ISNULL((SELECT value_str FROM tdc_config (nolock)  
							WHERE [function] = 'CUS_FRAME_CONS' AND active = 'Y'), 'CUS')		 
					
				SELECT	@date_expires = GETDATE()

				-- v1.5 Start
				-- v1.7 Check for '' as well as null
				SET @bin_no = NULL
				-- Primary bin
				SELECT	TOP 1 @bin_no = bin_no
				FROM	tdc_bin_part_qty (NOLOCK)                       
				WHERE	location  = @location   
				AND		part_no   = @part_no   
				AND		[primary] = 'Y'  
				ORDER BY seq_no, bin_no

				IF (@bin_no IS NULL OR @bin_no = '') -- If no bin found then find secondary -- v1.7 Check for '' as well as null
				BEGIN
					SELECT	TOP 1 @bin_no = bin_no
					FROM	tdc_bin_part_qty (NOLOCK)                       
					WHERE	location  = @location   
					AND		part_no   = @part_no   
					AND		[primary] = 'N'  
					ORDER BY seq_no, bin_no
				END
				-- v1.5 End				

				-- Get the bin - First look for an existing bin
--				SET @bin_no = NULL -- v1.5
				IF (@bin_no IS NULL OR @bin_no = '') -- If no bin found then find a bin containing the part  -- v1.7 Check for '' as well as null
				BEGIN
					SELECT	TOP 1 @bin_no = a.bin_no
					FROM	dbo.tdc_bin_master a (NOLOCK)
					JOIN	dbo.lot_bin_stock b (NOLOCK)
					ON		a.location = b.location
					AND		a.bin_no = b.bin_no
					WHERE	b.location = @location
					AND		b.part_no = @part_no
--					AND		a.group_code = 'PICKAREA' -- v1.7
					AND		a.usage_type_code IN ('OPEN') --,'REPLENISH') -- v1.2 v1.7
					AND		a.bin_no <> @dest_bin_no -- v1.3
					ORDER BY a.bin_no
				END

				-- START v1.6
				-- If no bin is found, get default bin from config
				IF (@bin_no IS NULL OR @bin_no = '') -- v1.7 Check for '' as well as null
				BEGIN
					SELECT @bin_no = value_str FROM dbo.tdc_config (NOLOCK) WHERE [function] = 'CUSTOM_FRAME_DEFAULT_PUTAWAY_BIN'
					
					-- If a value is returned, check it exists for this location
					IF @bin_no IS NOT NULL
					BEGIN 
						IF NOT EXISTS (SELECT 1 FROM dbo.tdc_bin_master WHERE bin_no = @bin_no AND location = @location)
						BEGIN
							SET @bin_no = NULL
						END
					END
				END
				-- END v1.6

				IF (@bin_no IS NULL OR @bin_no = '') -- If no bin found then find an empty bin -- v1.7 Check for '' as well as null
				BEGIN
					SELECT	TOP 1 @bin_no = a.bin_no
					FROM	dbo.tdc_bin_master a (NOLOCK)
					LEFT JOIN dbo.lot_bin_stock b (NOLOCK)
					ON		a.location = b.location
					AND		a.bin_no = b.bin_no
					WHERE	a.location = @location
					AND		b.location IS NULL
					AND		a.group_code = 'PICKAREA'
					AND		a.usage_type_code IN ('OPEN','REPLENISH') -- v1.2
					AND		a.bin_no <> @dest_bin_no -- v1.3
					ORDER BY a.bin_no
				END			
		
				-- Default lot number
				SELECT @lot = ISNULL((SELECT value_str FROM tdc_config (nolock)  
							WHERE [function] = 'auto_lot' AND active = 'Y'), '1')	

				-- Get the custom bin from the config
				SELECT	@dest_bin_no = ISNULL((SELECT value_str FROM tdc_config (nolock)  
								WHERE [function] = 'CVO_CUSTOM_BIN' AND active = 'Y'), 'UNKNOWN')

				INSERT INTO #adm_inv_adj (loc, part_no, bin_no, lot_ser, date_exp, qty, direction, who_entered, 
											reason_code, code) 									
				VALUES(@location, @part_no, @dest_bin_no, @lot, @date_expires, @qty, 1,'CustomFrames', '', @reason_code)

				EXEC dbo.tdc_adm_inv_adj 

				SELECT	@issue_no = max(issue_no) 
				FROM	dbo.issues
				WHERE	part_no = @part_no
				AND		code = @reason_code

				INSERT INTO dbo.tdc_ei_bin_log (module, trans, tran_no, tran_ext, location, part_no, from_bin, 
							userid, direction, quantity) 														  
				VALUES( 'ADH', 'ADHOC', @issue_no, 0, @location, @part_no, @dest_bin_no, 'CustomFrames', 1, @qty)

				SELECT	@uom = uom, @description = description FROM inventory (nolock) WHERE part_no = @part_no AND location = @location 
				SELECT	@group_code = group_code FROM tdc_bin_master (nolock) WHERE location = @location AND bin_no = @dest_bin_no
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

				INSERT INTO dbo.tdc_3pl_issues_log (trans, issue_no, location, part_no, bin_no, bin_group, uom, 
										qty, userid, expert) 																
				VALUES ('ADHOC', @issue_no,	 @location, @part_no, @dest_bin_no, @group_code, @uom, (@qty),  
							'CustomFrames', 'N')
				
				SELECT @data = 'LP_ITEM_EAN14: ; LP_ITEM_EAN13: ; LP_ITEM_EAN8: ; LP_ITEM_GTIN: ; LP_ITEM_UPC: ' 
				SELECT @data = @data + LTRIM(RTRIM(@UPC)) + '; LP_CATEGORY_5: '+ LTRIM(RTRIM(@category_2)) + '; LP_CATEGORY_4: ' 
				SELECT @data = @data + LTRIM(RTRIM(@category_4)) + '; LP_CATEGORY_3: ' + LTRIM(RTRIM(@category_3)) + '; LP_CATEGORY_2: '
				SELECT @data = @data + LTRIM(RTRIM(@category_2)) + '; LP_CATEGORY_1: ; LP_CUBIC_FEET: ' + STR(@cubic_feet) + '; LP_SO_QTY_INCR: '
				SELECT @data = @data + STR(@so_qty_increment) + '; LP_WEIGHT: ' + STR(@weight_ea) + '; LP_CMDTY_CODE: '
				SELECT @data = @data + STR(@so_qty_increment) + '; LP_WEIGHT: ' + STR(@weight_ea) + '; LP_CMDTY_CODE: '
				SELECT @data = @data + LTRIM(RTRIM(@cmdty_code)) + '; LP_LENGTH: ' + STR(@length)+ '; LP_WIDTH: ' + STR(@width) + '; LP_HEIGHT: ' 
				SELECT @data = @data + STR(@height) + '; LP_SKU: ; LP_ADJ_DIR: OUT; LP_ADJ_CODE: ' + LTRIM(RTRIM(@reason_code)) + '; ' 
				SELECT @data = @data + 'LP_REASON_CODE: ; LP_BASE_UOM: ' + LTRIM(RTRIM(@uom)) + '; LP_ITEM_UOM: ' + LTRIM(RTRIM(@uom))
				SELECT @data = @data + '; LP_BASE_QTY: ' + STR((@qty)) + '; LP_LB_TRACKING: Y; LP_ITEM_DESC: '
				SELECT @data = @data + LTRIM(RTRIM(@description)) + '; '

				INSERT INTO tdc_log (tran_date,UserID,trans_source,module,trans,tran_no,tran_ext,part_no,
											lot_ser,bin_no,location,quantity,data) 										
				VALUES (getdate(), 'CustomFrames', 'CO', 'ADH', 'ADHOC', STR(@issue_no), '', @part_no, @lot, @dest_bin_no, 
							@location, LTRIM(STR(@qty)), @data) 

				-- Get the queue priority
				SELECT @priority = ISNULL((SELECT value_str FROM tdc_config (nolock)  
								WHERE [function] = 'CUSTOM_FRAME_PRIORITY' AND active = 'Y'), 0)

				-- Get the trans
				SELECT @Bin2BinGroupId = (SELECT group_id FROM tdc_group (NOLOCK) WHERE trans_type = 'MGTB2B')	
		
				-- Create the MGTB2B queue transactions	
				-- Check if an existing tdc_soft_alloc_tbl record exists and the qty is greater then the qty passed in
				IF EXISTS (SELECT 1 FROM tdc_soft_alloc_tbl a WHERE a.order_no = 0 AND a.order_ext  = 0            
								AND a.order_type = 'S' AND a.line_no = 0 AND a.location = @location AND a.part_no = @part_no
								AND a.bin_no = @dest_bin_no AND a.target_bin = @bin_no AND a.dest_bin = @bin_no)
				BEGIN
					-- Increase the qty on the allocation record
					UPDATE	tdc_soft_alloc_tbl
					SET		qty = qty + @qty
					FROM 	tdc_soft_alloc_tbl a
					WHERE	a.order_no  = 0            
					AND		a.order_ext  = 0            
					AND		a.order_type = 'S'          
					AND		a.line_no    = 0   
					AND		a.location = @location 
					AND		a.part_no = @part_no
					AND		a.bin_no = @dest_bin_no 
					AND		a.target_bin = @bin_no 
					AND		a.dest_bin = @bin_no
				
				END
				ELSE
				BEGIN
					-- Create the allocation record
					INSERT INTO tdc_soft_alloc_tbl
						(order_type, order_no, order_ext, location, line_no, part_no,
						 lot_ser, bin_no, qty, target_bin, dest_bin, q_priority)
					VALUES ('S', 0, 0, @location, 0, @part_no, 
						@lot, @dest_bin_no, @qty, @bin_no, @bin_no, @priority)

				END

				EXEC @SeqNo = tdc_queue_get_next_seq_num 'tdc_pick_queue', @Priority 	

				INSERT INTO tdc_pick_queue (trans_source, trans, priority, seq_no,
						location, trans_type_no, trans_type_ext, line_no, part_no, lot,qty_to_process, 
						qty_processed, qty_short,next_op, bin_no, date_time,assign_group, tx_control, tx_lock)
				VALUES ('MGT', 'MGTB2B', @Priority, @SeqNo, @location,  @order_no,  @order_ext, @line_no, 
					@part_no, @lot, @qty, 0, 0, @bin_no, @dest_bin_no, GETDATE(), @Bin2BinGroupId, 'M', 'R') 


				SET @last_part_no = @part_no

				SELECT TOP 1 @part_no = part_no_original
				FROM	dbo.CVO_ord_list_kit (NOLOCK)
				WHERE	order_no = @order_no
				AND		order_ext = @order_ext
				AND		line_no = @line_no
				AND		replaced = 'S'
				AND		part_no_original > @last_part_no
				ORDER BY part_no_original

			END		
		
			-- v1.8 Call custom frame putaway label
			SELECT	@userid = login_id FROM #temp_who
			EXEC dbo.cvo_print_custom_frame_putaway_sp @userid,'999',@order_no,@order_ext,@line_no,@location

		END
	END

	-- v1.1 - Auto pick the compeleted frame once all transactions have been processed
	-- v1.4 - Remove v1.1
	/*
	IF NOT EXISTS (SELECT 1 FROM tdc_pick_queue (NOLOCK) WHERE trans_type_no = @order_no AND trans_type_ext = @order_ext
					AND	next_op = @dest_bin_no AND line_no = @line_no)
	BEGIN
		IF EXISTS (SELECT 1 FROM tdc_pick_queue (NOLOCK) WHERE trans_type_no = @order_no AND trans_type_ext = @order_ext
					AND	bin_no = @dest_bin_no AND trans = 'STDPICK' AND mfg_lot IS NULL AND line_no = @line_no)
		BEGIN

			-- Create working table
			IF (SELECT OBJECT_ID('tempdb..#adm_pick_ship')) IS NOT NULL 
			BEGIN   
				DROP TABLE #adm_pick_ship  
			END

			CREATE TABLE #adm_pick_ship (
					order_no	int	not null, 
					ext			int not null, 
					line_no		int not null, 
					part_no		varchar(30) not null, 
					tracking_no	varchar(30)	null, 
					bin_no		varchar(12) null, 
					lot_ser		varchar(25) null, 
					location	varchar(10)	null, 
					date_exp	datetime null, 
					qty			decimal(20,8) not null, 
					err_msg		varchar(255) null, 
					row_id		int identity not null)

			IF (SELECT OBJECT_ID('tempdb..#pick_custom_kit_order')) IS NOT NULL 
			BEGIN   
				DROP TABLE #pick_custom_kit_order  
			END			

			CREATE TABLE #pick_custom_kit_order (
					method		varchar(2) not null,
					order_no	int not null,
					order_ext	int not null,
					line_no		int not null,
					location	varchar(10) not null,
					item		varchar(30) null,
					part_no		varchar(30) not null,
					sub_part_no varchar(30) null,
					lot_ser		varchar(25) null,
					bin_no		varchar(12) null,
					quantity	decimal(20,8) not null,
					who			varchar(50) not null,
					row_id		int identity not null)

			-- Get the queue record info to process
			SELECT	@f_queue_tran = tran_id,
					@f_line_no = line_no,
					@f_part_no = part_no,
					@f_lot = lot,
					@f_qty = qty_to_process
			FROM	tdc_pick_queue (NOLOCK)
			WHERE	trans_type_no = @order_no 
			AND		trans_type_ext = @order_ext
			AND		bin_no = @dest_bin_no 
			AND		trans = 'STDPICK' 
			AND		mfg_lot IS NULL
			AND		line_no = @line_no

			-- No data found then exit
			IF @f_line_no IS NULL
				RETURN

			-- Get the expiry date
			SELECT	@f_expires = CONVERT(varchar(12), date_expires, 106) 
			FROM	lot_bin_stock  (nolock) 
			WHERE	part_no = @f_part_no
			AND		lot_ser = @f_lot
			AND		bin_no = @dest_bin_no
			AND		location = @location

			-- Insert the data for processing
			INSERT INTO #adm_pick_ship (order_no, ext, line_no, part_no, bin_no, lot_ser, location, date_exp, qty, err_msg) 
			VALUES(@order_no, @order_ext, @f_line_no, @f_part_no, @dest_bin_no, @f_lot, @location, @f_expires, @f_qty, NULL)

			-- Test that there is data to process
			IF NOT EXISTS (SELECT 1 FROM #adm_pick_ship)
				RETURN			
				
			-- Call standard picking routine
			EXEC tdc_queue_xfer_ship_pick_sp @f_queue_tran,'','S','0'

			IF (SELECT OBJECT_ID('tempdb..#adm_pick_ship')) IS NOT NULL 
			BEGIN   
				DROP TABLE #adm_pick_ship  
			END

			IF (SELECT OBJECT_ID('tempdb..#pick_custom_kit_order')) IS NOT NULL 
			BEGIN   
				DROP TABLE #pick_custom_kit_order  
			END			

			-- Now need to call routine again as it creates the part bin to bin moves
			EXEC dbo.CVO_Custom_Frame_processing_sp 1, @order_no, @order_ext, @f_line_no, @location, @f_part_no, @f_lot, @f_qty

		END
	END
	*/
END

GO
GRANT EXECUTE ON  [dbo].[CVO_Custom_Frame_processing_sp] TO [public]
GO
