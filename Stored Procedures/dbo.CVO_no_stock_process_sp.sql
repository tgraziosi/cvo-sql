SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[CVO_no_stock_process_sp]	@order_no int,
												@order_ext int,
												@line_no int,
												@location varchar(10),
												@part_no varchar(30),
												@bin_no	varchar(20),
												@lot_ser varchar(25),
												@counted_qty decimal(20,8),
												@userid varchar(50)
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
			@hold_reason	varchar(40) 


	-- Create working table
	CREATE TABLE #ordercancel (
		ret				int,
		ret_message		varchar(255),
		new_order_no	int)

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

	-- Cancel the order
	SELECT	@cust_code = cust_code,
			@status = status
	FROM	orders_all (NOLOCK)
	WHERE	order_no = @order_no
	AND		ext = @order_ext


	-- Get the hold code and reason for the order type
	SELECT	@hold_code = a.hold_code,
			@hold_reason = a.hold_reason
	FROM	adm_oehold a (NOLOCK)
	JOIN	so_usrcateg b (NOLOCK)
	ON		a.hold_code = b.no_stock_hold
	JOIN	orders_all c (NOLOCK)
	ON		b.category_code = c.user_category
	WHERE	c.order_no = @order_no
	AND		c.ext = @order_ext	

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

		-- v1.3 Start
		UPDATE	cvo_soft_alloc_hdr
		SET		bo_hold = 1
		WHERE	order_no = @order_no
		AND		order_ext = @order_ext
		-- v1.3 End

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

		-- v1.3 Start
		UPDATE	cvo_soft_alloc_hdr
		SET		bo_hold = 1
		WHERE	order_no = @order_no
		AND		order_ext = @order_ext
		-- v1.3 End

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
	IF EXISTS(SELECT 1 FROM lot_bin_stock (NOLOCK) WHERE bin_no = @bin_no AND location = @location AND part_no = @part_no AND lot_ser = @lot_ser AND @bin_qty > @counted_qty)
	BEGIN

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

			INSERT INTO #adm_inv_adj (loc, part_no, bin_no, lot_ser, date_exp, qty, direction, who_entered, 
										reason_code, code) 									
			VALUES(@location, @part_no, @bin_no, @lot_ser, @date_expires, (@bin_qty - @counted_qty), -1, @userid, '', 'CYC')

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
			SELECT @data = @data + '; LP_BASE_QTY: ' + STR(((@bin_qty - @counted_qty) * -1)) + '; LP_LB_TRACKING: Y; LP_ITEM_DESC: '
			SELECT @data = @data + LTRIM(RTRIM(@description)) + '; '

			INSERT INTO tdc_log (tran_date,UserID,trans_source,module,trans,tran_no,tran_ext,part_no,
										lot_ser,bin_no,location,quantity,data) 										
			VALUES (getdate(), @userid, 'CO', 'ADH', 'ADHOC', CAST(@issue_no as varchar(10)), '', @part_no, @lot_ser, @bin_no, 
						@location, LTRIM(STR((@bin_qty - @counted_qty) * -1)), @data) 
	END

	-- Clean up
	DROP TABLE #ordercancel

END
GO
GRANT EXECUTE ON  [dbo].[CVO_no_stock_process_sp] TO [public]
GO
