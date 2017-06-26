SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[cvo_po_receipt_label]	@po_no varchar(20),
										@po_line int,
										@orig_qty decimal(20,8),
										@q_tran int,
										@receipt_no int,
										@user varchar(50),
										@from_bin varchar(20),
										@lot_ser varchar(25),
										@date_expires varchar(10),
										@qc_flag char(1),
										@qc_no int,
										@reprint_data int = 1

AS
BEGIN
	-- DIRECTIVES
	SET NOCOUNT ON

	-- DECLARATIONS
	DECLARE @qty			decimal(20,8),
			@to_bin			varchar(20),
			@order_no		int,
			@order_ext		int,
			@line_no		int,
			@part_no		varchar(30),
			@lb_tracking	char(1),
			@customer_name	varchar(40),
			@vendor			varchar(10),
			@vendor_name	varchar(40),
			@sku_code		varchar(16),
			@cmdty_code		varchar(8),
			@height			decimal(20,8),
			@width			decimal(20,8),
			@length			decimal(20,8),
			@weight_ea		decimal(20,8),
			@so_qty_inc		decimal(20,8),
			@cubic_feet		decimal(20,8),
			@cat1			varchar(16),	
			@cat2			varchar(16),
			@cat3			varchar(16),
			@cat4			varchar(16),
			@cat5			varchar(16),
			@uom			varchar(8),
			@location		varchar(10),
			@item_desc		varchar(255),
			@upc_code		varchar(12),
			@gtin			varchar(14), 
			@ean8			varchar(8), 
			@ean13			varchar(13), 
			@ean14			varchar(14)
			-- 062317
			, @reldate DATETIME
			, @inhouse  DATETIME
            
	-- WORKING TABLE
	CREATE TABLE #cvo_label_data (
		row_id		int IDENTITY(1,1),
		field_name	varchar(300),
		field_data	varchar(300))

	-- PROCESSING
	SELECT	@part_no = part_no,
			@location = location
	FROM	pur_list (NOLOCK)
	WHERE	po_no = @po_no
	AND		line = @po_line

	SELECT	@sku_code = ISNULL(a.sku_code, ''), 
			@height = a.height, 
			@width = a.width, 
			@length = a.length, 
			@cmdty_code = ISNULL(a.cmdty_code, ''), 
			@weight_ea = a.weight_ea, 
			@so_qty_inc = ISNULL(a.so_qty_increment, 0), 
			@cubic_feet = a.cubic_feet, 
			@uom = a.uom,
			@lb_tracking = a.lb_tracking,
			@cat1 = ISNULL(category_1, ''), 
			@cat2 = ISNULL(category_2, ''), 
			@cat3 = ISNULL(category_3, ''), 
			@cat4 = ISNULL(category_4, ''), 
			@cat5 = ISNULL(category_5, ''),
			@item_desc = a.description,
			@upc_code = c.upc,
			@gtin = c.gtin,
			@ean8 = c.ean_8,
			@ean13 = c.ean_13,
			@ean14 = c.ean_14,
			@qc_flag = a.qc_flag,
			@reldate = b.field_26 -- 062317

	FROM	inv_master a (NOLOCK)
	JOIN	inv_master_add b (NOLOCK)
	ON		a.part_no = b.part_no
	LEFT JOIN uom_id_code c (NOLOCK)
	ON		a.part_no = c.part_no
	WHERE	a.part_no = @part_no

	IF (@lb_tracking = 'Y' AND @q_tran <> 0)
	BEGIN
		SELECT	@qty = qty_to_process,
				@to_bin = next_op
		FROM	dbo.tdc_put_queue (NOLOCK)
		WHERE	tran_id = @q_tran
	END
	ELSE
	BEGIN
		SET @qty = @orig_qty
	END

	SET @order_no = 0

	SELECT	@order_no = order_no,
			@line_no = line_no
	FROM	dbo.orders_auto_po (NOLOCK)
	WHERE	po_no = @po_no

	IF (@order_no > 0)
	BEGIN
		SELECT	@order_ext = order_ext
		FROM	dbo.ord_list (NOLOCK)
		WHERE	order_no = @order_no
		AND		line_no = @line_no

		SELECT	@customer_name = ship_to_name
		FROM	dbo.orders_all (NOLOCK)
		WHERE	order_no = @order_no
		AND		ext = @order_ext
	END

	-- 062317 - get inhouse date and release date for receipt tag
	--                                1         2         3         4 
    --                       1234567890123456789012345678901234567890

	IF (@order_no = 0)
	begin
		SELECT @customer_name = 'Rel Date: mm/dd/rr - Due Date: mm/dd/ii'
		SELECT @inhouse = r.inhouse_date FROM dbo.releases AS r WHERE r.po_no = @po_no AND r.po_line = @po_line
	
		SELECT @customer_name = REPLACE(@customer_name,'mm/dd/rr', CONVERT(VARCHAR(8),@reldate,1))
		SELECT @customer_name = REPLACE(@customer_name,'mm/dd/ii', CONVERT(VARCHAR(8),@inhouse,1))
		END
    
	SELECT	@vendor = r.vendor,
			@qc_no = r.qc_no,
			@vendor_name = a.vendor_name
	FROM	dbo.receipts r (NOLOCK)
	JOIN	dbo.apvend a (NOLOCK)
	ON		r.vendor = a.vendor_code
	WHERE	r.receipt_no = @receipt_no

	INSERT	#cvo_label_data (field_name, field_data) VALUES ('LP_USER_STAT_ID', @user)
	INSERT	#cvo_label_data (field_name, field_data) VALUES ('LP_LOCATION', @location)
	INSERT	#cvo_label_data (field_name, field_data) VALUES ('LP_PO', @po_no)
	INSERT	#cvo_label_data (field_name, field_data) VALUES ('LP_ITEM', @part_no)
	INSERT	#cvo_label_data (field_name, field_data) VALUES ('LP_LINE_NO', CAST(@po_line as varchar(10)))
	INSERT	#cvo_label_data (field_name, field_data) VALUES ('LP_ITEM_DESC', @item_desc)
	INSERT	#cvo_label_data (field_name, field_data) VALUES ('LP_LB_TRACKING', @lb_tracking)
	INSERT	#cvo_label_data (field_name, field_data) VALUES ('LP_BIN', @from_bin)
	INSERT	#cvo_label_data (field_name, field_data) VALUES ('LP_LOT', @lot_ser)
	INSERT	#cvo_label_data (field_name, field_data) VALUES ('LP_QUANTITY', CAST(CAST(@qty as int) as varchar(20)))
	INSERT	#cvo_label_data (field_name, field_data) VALUES ('LP_EXP_DATE', @date_expires)
	INSERT	#cvo_label_data (field_name, field_data) VALUES ('LP_RECEIPT_NO', CAST(@receipt_no as varchar(20)))
	INSERT	#cvo_label_data (field_name, field_data) VALUES ('LP_VENDOR_NO', @vendor)
	INSERT	#cvo_label_data (field_name, field_data) VALUES ('LP_VENDOR_NAME', @vendor_name)
	INSERT	#cvo_label_data (field_name, field_data) VALUES ('LP_ITEM_UPC', @upc_code)
	INSERT	#cvo_label_data (field_name, field_data) VALUES ('LP_QC_FLAG', @qc_flag)
	INSERT	#cvo_label_data (field_name, field_data) VALUES ('LP_QC_NO', CAST(@qc_no as varchar(20)))
	INSERT	#cvo_label_data (field_name, field_data) VALUES ('LP_Q_ID', CAST(@q_tran as varchar(20)))
	INSERT	#cvo_label_data (field_name, field_data) VALUES ('LP_ITEM_UOM', @uom)
	INSERT	#cvo_label_data (field_name, field_data) VALUES ('LP_UOM_QTY', CAST(CAST(@qty as int) as varchar(20)))
	INSERT	#cvo_label_data (field_name, field_data) VALUES ('LP_UOM', @uom)
	INSERT	#cvo_label_data (field_name, field_data) VALUES ('LP_PO_UOM', @uom)
	INSERT	#cvo_label_data (field_name, field_data) VALUES ('LP_SKU', @sku_code)
	INSERT	#cvo_label_data (field_name, field_data) VALUES ('LP_HEIGHT', CAST(CAST(@height as int) as varchar(20)))
	INSERT	#cvo_label_data (field_name, field_data) VALUES ('LP_WIDTH', CAST(CAST(@width as int)as varchar(20)))
	INSERT	#cvo_label_data (field_name, field_data) VALUES ('LP_LENGTH', CAST(CAST(@length as int) as varchar(20)))
	INSERT	#cvo_label_data (field_name, field_data) VALUES ('LP_CMDTY_CODE', @cmdty_code)
	INSERT	#cvo_label_data (field_name, field_data) VALUES ('LP_WEIGHT', CAST(CAST(@weight_ea as int) as varchar(20)))
	INSERT	#cvo_label_data (field_name, field_data) VALUES ('LP_SO_QTY_INCR', CAST(CAST(@so_qty_inc as int) as varchar(20)))
	INSERT	#cvo_label_data (field_name, field_data) VALUES ('LP_CUBIC_FEET', CAST(CAST(@cubic_feet as int) as varchar(20)))
	INSERT	#cvo_label_data (field_name, field_data) VALUES ('LP_CATEGORY_1', @cat1)
	INSERT	#cvo_label_data (field_name, field_data) VALUES ('LP_CATEGORY_2', @cat2)
	INSERT	#cvo_label_data (field_name, field_data) VALUES ('LP_CATEGORY_3', @cat3)
	INSERT	#cvo_label_data (field_name, field_data) VALUES ('LP_CATEGORY_4', @cat4)
	INSERT	#cvo_label_data (field_name, field_data) VALUES ('LP_CATEGORY_5', @cat5)
	INSERT	#cvo_label_data (field_name, field_data) VALUES ('LP_ITEM_GTIN', @gtin)
	INSERT	#cvo_label_data (field_name, field_data) VALUES ('LP_ITEM_EAN8', @ean8)
	INSERT	#cvo_label_data (field_name, field_data) VALUES ('LP_ITEM_EAN13', @ean13)
	INSERT	#cvo_label_data (field_name, field_data) VALUES ('LP_ITEM_EAN14', @ean14)
	INSERT	#cvo_label_data (field_name, field_data) VALUES ('LP_ORD_NO', CAST(@order_no as varchar(20)))
	INSERT	#cvo_label_data (field_name, field_data) VALUES ('LP_ORD_EXT', CAST(@order_ext as varchar(20)))
	INSERT	#cvo_label_data (field_name, field_data) VALUES ('LP_ORD_CUSTNAME', @customer_name)
	INSERT	#cvo_label_data (field_name, field_data) VALUES ('LP_TO_BIN', @to_bin)

	IF (@reprint_data = 1)
	BEGIN
		INSERT	cvo_receipt_reprint (po_no, line_no, part_no, lp_string, lp_value)
		VALUES	(@po_no, @po_line, @part_no, 'LP_USER_STAT_ID', @user)

		INSERT	cvo_receipt_reprint (po_no, line_no, part_no, lp_string, lp_value)
		VALUES	(@po_no, @po_line, @part_no, 'LP_LOCATION', @location)

		INSERT	cvo_receipt_reprint (po_no, line_no, part_no, lp_string, lp_value)
		VALUES	(@po_no, @po_line, @part_no, 'LP_PO', @po_no)

		INSERT	cvo_receipt_reprint (po_no, line_no, part_no, lp_string, lp_value)
		VALUES	(@po_no, @po_line, @part_no, 'LP_ITEM', @part_no)

		INSERT	cvo_receipt_reprint (po_no, line_no, part_no, lp_string, lp_value)
		VALUES	(@po_no, @po_line, @part_no, 'LP_LINE_NO', CAST(@po_line as varchar(10)))

		INSERT	cvo_receipt_reprint (po_no, line_no, part_no, lp_string, lp_value)
		VALUES	(@po_no, @po_line, @part_no, 'LP_ITEM_DESC', @item_desc)

		INSERT	cvo_receipt_reprint (po_no, line_no, part_no, lp_string, lp_value)
		VALUES	(@po_no, @po_line, @part_no, 'LP_LB_TRACKING', @lb_tracking)

		INSERT	cvo_receipt_reprint (po_no, line_no, part_no, lp_string, lp_value)
		VALUES	(@po_no, @po_line, @part_no, 'LP_BIN', @from_bin)

		INSERT	cvo_receipt_reprint (po_no, line_no, part_no, lp_string, lp_value)
		VALUES	(@po_no, @po_line, @part_no, 'LP_LOT', @lot_ser)
		
		INSERT	cvo_receipt_reprint (po_no, line_no, part_no, lp_string, lp_value)
		VALUES	(@po_no, @po_line, @part_no, 'LP_QUANTITY', CAST(CAST(@qty as int)as varchar(20)))

		INSERT	cvo_receipt_reprint (po_no, line_no, part_no, lp_string, lp_value)
		VALUES	(@po_no, @po_line, @part_no, 'LP_EXP_DATE', @date_expires)

		INSERT	cvo_receipt_reprint (po_no, line_no, part_no, lp_string, lp_value)
		VALUES	(@po_no, @po_line, @part_no, 'LP_RECEIPT_NO', CAST(@receipt_no as varchar(20)))

		INSERT	cvo_receipt_reprint (po_no, line_no, part_no, lp_string, lp_value)
		VALUES	(@po_no, @po_line, @part_no, 'LP_VENDOR_NO', @vendor)

		INSERT	cvo_receipt_reprint (po_no, line_no, part_no, lp_string, lp_value)
		VALUES	(@po_no, @po_line, @part_no, 'LP_VENDOR_NAME', @vendor_name)

		INSERT	cvo_receipt_reprint (po_no, line_no, part_no, lp_string, lp_value)
		VALUES	(@po_no, @po_line, @part_no, 'LP_ITEM_UPC', @upc_code)

		INSERT	cvo_receipt_reprint (po_no, line_no, part_no, lp_string, lp_value)
		VALUES	(@po_no, @po_line, @part_no, 'LP_QC_FLAG', @qc_flag)

		INSERT	cvo_receipt_reprint (po_no, line_no, part_no, lp_string, lp_value)
		VALUES	(@po_no, @po_line, @part_no, 'LP_QC_NO', CAST(@qc_no as varchar(20)))

		INSERT	cvo_receipt_reprint (po_no, line_no, part_no, lp_string, lp_value)
		VALUES	(@po_no, @po_line, @part_no, 'LP_Q_ID', CAST(@q_tran as varchar(20)))

		INSERT	cvo_receipt_reprint (po_no, line_no, part_no, lp_string, lp_value)
		VALUES	(@po_no, @po_line, @part_no, 'LP_ITEM_UOM', @uom)

		INSERT	cvo_receipt_reprint (po_no, line_no, part_no, lp_string, lp_value)
		VALUES	(@po_no, @po_line, @part_no, 'LP_UOM_QTY', CAST(CAST(@qty as int) as varchar(20)))

		INSERT	cvo_receipt_reprint (po_no, line_no, part_no, lp_string, lp_value)
		VALUES	(@po_no, @po_line, @part_no, 'LP_UOM', @uom)

		INSERT	cvo_receipt_reprint (po_no, line_no, part_no, lp_string, lp_value)
		VALUES	(@po_no, @po_line, @part_no, 'LP_PO_UOM', @uom)

		INSERT	cvo_receipt_reprint (po_no, line_no, part_no, lp_string, lp_value)
		VALUES	(@po_no, @po_line, @part_no, 'LP_SKU', @sku_code)

		INSERT	cvo_receipt_reprint (po_no, line_no, part_no, lp_string, lp_value)
		VALUES	(@po_no, @po_line, @part_no, 'LP_HEIGHT', CAST(CAST(@height as int) as varchar(20)))

		INSERT	cvo_receipt_reprint (po_no, line_no, part_no, lp_string, lp_value)
		VALUES	(@po_no, @po_line, @part_no, 'LP_WIDTH', CAST(CAST(@width as int) as varchar(20)))

		INSERT	cvo_receipt_reprint (po_no, line_no, part_no, lp_string, lp_value)
		VALUES	(@po_no, @po_line, @part_no, 'LP_LENGTH', CAST(CAST(@length as int) as varchar(20)))

		INSERT	cvo_receipt_reprint (po_no, line_no, part_no, lp_string, lp_value)
		VALUES	(@po_no, @po_line, @part_no, 'LP_CMDTY_CODE', @cmdty_code)

		INSERT	cvo_receipt_reprint (po_no, line_no, part_no, lp_string, lp_value)
		VALUES	(@po_no, @po_line, @part_no, 'LP_WEIGHT', CAST(CAST(@weight_ea as int) as varchar(20)))

		INSERT	cvo_receipt_reprint (po_no, line_no, part_no, lp_string, lp_value)
		VALUES	(@po_no, @po_line, @part_no, 'LP_SO_QTY_INCR', CAST(CAST(@so_qty_inc as int) as varchar(20)))

		INSERT	cvo_receipt_reprint (po_no, line_no, part_no, lp_string, lp_value)
		VALUES	(@po_no, @po_line, @part_no, 'LP_CUBIC_FEET', CAST(CAST(@cubic_feet as int) as varchar(20)))

		INSERT	cvo_receipt_reprint (po_no, line_no, part_no, lp_string, lp_value)
		VALUES	(@po_no, @po_line, @part_no, 'LP_CATEGORY_1', @cat1)

		INSERT	cvo_receipt_reprint (po_no, line_no, part_no, lp_string, lp_value)
		VALUES	(@po_no, @po_line, @part_no, 'LP_CATEGORY_2', @cat2)

		INSERT	cvo_receipt_reprint (po_no, line_no, part_no, lp_string, lp_value)
		VALUES	(@po_no, @po_line, @part_no, 'LP_CATEGORY_3', @cat3)

		INSERT	cvo_receipt_reprint (po_no, line_no, part_no, lp_string, lp_value)
		VALUES	(@po_no, @po_line, @part_no, 'LP_CATEGORY_4', @cat4)

		INSERT	cvo_receipt_reprint (po_no, line_no, part_no, lp_string, lp_value)
		VALUES	(@po_no, @po_line, @part_no, 'LP_CATEGORY_5', @cat5)

		INSERT	cvo_receipt_reprint (po_no, line_no, part_no, lp_string, lp_value)
		VALUES	(@po_no, @po_line, @part_no, 'LP_ITEM_GTIN', @gtin)

		INSERT	cvo_receipt_reprint (po_no, line_no, part_no, lp_string, lp_value)
		VALUES	(@po_no, @po_line, @part_no, 'LP_ITEM_EAN8', @ean8)

		INSERT	cvo_receipt_reprint (po_no, line_no, part_no, lp_string, lp_value)
		VALUES	(@po_no, @po_line, @part_no, 'LP_ITEM_EAN13', @ean13)

		INSERT	cvo_receipt_reprint (po_no, line_no, part_no, lp_string, lp_value)
		VALUES	(@po_no, @po_line, @part_no, 'LP_ITEM_EAN14', @ean14)

		INSERT	cvo_receipt_reprint (po_no, line_no, part_no, lp_string, lp_value)
		VALUES	(@po_no, @po_line, @part_no, 'LP_ORD_NO', CAST(@order_no as varchar(20)))

		INSERT	cvo_receipt_reprint (po_no, line_no, part_no, lp_string, lp_value)
		VALUES	(@po_no, @po_line, @part_no, 'LP_ORD_EXT', CAST(@order_ext as varchar(20)))

		INSERT	cvo_receipt_reprint (po_no, line_no, part_no, lp_string, lp_value)
		VALUES	(@po_no, @po_line, @part_no, 'LP_ORD_CUSTNAME', @customer_name)

		INSERT	cvo_receipt_reprint (po_no, line_no, part_no, lp_string, lp_value)
		VALUES	(@po_no, @po_line, @part_no, 'LP_TO_BIN', @to_bin)
	END

	SELECT	field_name, field_data
	FROM	#cvo_label_data
	ORDER BY row_id

	DROP TABLE #cvo_label_data

END

GO
GRANT EXECUTE ON  [dbo].[cvo_po_receipt_label] TO [public]
GO
