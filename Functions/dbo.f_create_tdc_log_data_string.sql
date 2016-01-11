
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- v1.0 CT 18/10/2012 - Creates data line for tdc log
-- SELECT dbo.f_create_tdc_log_data_string (1419098,0,2)
CREATE FUNCTION [dbo].[f_create_tdc_log_data_string] (	@order_no INT,
													@ext INT,
													@line_no INT)
RETURNS VARCHAR(7500)
AS
BEGIN
	DECLARE @data				VARCHAR(7500),
			@cust_code			VARCHAR(8),
			@customer_name		VARCHAR(40),
			@uom				CHAR(2),
			@qc_flag			CHAR(1),
			@sku_code			VARCHAR(30), 
			@height				DECIMAL(20,8), 
			@width				DECIMAL(20,8), 
			@length				DECIMAL(20,8), 
			@cmdty_code			VARCHAR(8), 
			@weight_ea			DECIMAL(20,8), 
			@so_qty_increment	DECIMAL(20,8), 
			@cubic_feet			DECIMAL(20,8),
			@category_1			VARCHAR(15),
			@category_2			VARCHAR(15),
			@category_3			VARCHAR(15),
			@category_4			VARCHAR(15),
			@category_5			VARCHAR(15),
			@part_no			VARCHAR(30),
			@ordered			DECIMAL(20,8),
			@ean13				VARCHAR(13),
			@ean14				VARCHAR(14),
			@ean8				VARCHAR(8),
			@gtin				VARCHAR(14),
			@upc				VARCHAR(12),
			@qc_no				INT,
			@exp_date			DATETIME,
			@part_desc			VARCHAR(255),
			@lot_ser			VARCHAR(25),
			@part_type			CHAR(1)

	-- Get auto lot from tdc_config
	SELECT @lot_ser = LEFT(value_str,25) FROM dbo.tdc_config (NOLOCK) WHERE [function] = 'AUTO_LOT'
				   
	-- Get order line details
	SELECT
		@part_no = part_no,
		@ordered = cr_shipped,
		@part_type = part_type,
		@uom = uom -- only used for M parts, overwritten for other parts
	FROM
		dbo.ord_list (NOLOCK)
	WHERE	
		order_no = @order_no
		AND order_ext = @ext
		AND line_no = @line_no
	
	-- If part type = M then skip the rest of the selects and produce balnk data line
	IF @part_type <> 'M'
	BEGIN
		-- Get CUSTOMER_NO, CUSTOMER_NAME
		SELECT  
			@cust_code = o.cust_code, 
			@customer_name = a.customer_name 
		FROM 
			dbo.orders_all o (nolock) 
		INNER JOIN
			dbo.arcust a (nolock) 
		ON
			 o.cust_code = a.customer_code 
		WHERE 
			o.order_no = @order_no
			AND o.ext = @ext

		-- Get part details
		SELECT 
			@uom = uom ,
			@qc_flag = qc_flag,
			@sku_code = isnull(sku_code, ''), 
			@height = height, 
			@width = width, 
			@length = [length], 
			@cmdty_code = isnull(cmdty_code, ''), 
			@weight_ea = weight_ea, 
			@so_qty_increment = isnull(so_qty_increment, 0), 
			@cubic_feet = cubic_feet,
			@part_desc = [description]
		FROM 
			dbo.inv_master (nolock) 
		WHERE 
			part_no = @part_no

		-- Get uom details
		SELECT 
			@upc = ISNULL(UPC, ''), 
			@gtin = ISNULL(GTIN, ''), 
			@ean8 = ISNULL(EAN_8, ''), 
			@ean13 = ISNULL(EAN_13, ''), 
			@ean14 = ISNULL(EAN_14, '')						
		FROM 
			dbo.uom_id_code (nolock) 
		WHERE 
			part_no = @part_no 
			AND UOM = @uom

		-- Get additional part details
		SELECT 
			@category_1 = isnull(category_1, ''), 
			@category_2 = isnull(category_2, ''), 
			@category_3 = isnull(category_3, ''), 
			@category_4 = isnull(category_4, ''), 
			@category_5 = isnull(category_5, '') 
		FROM 
			dbo.inv_master_add (nolock) 
		WHERE 
			part_no = @part_no

		-- Set expiry date 1 year from today
		SET @exp_date = DATEADD(yy,1,GETDATE())

		-- Get QC No
		SELECT 
			@qc_no = qc_no 
		FROM 
			dbo.qc_results (nolock) 
		WHERE 
			tran_code = 'C' 
			AND tran_no = @order_no
			AND part_no = @part_no
			AND lot_ser = @lot_ser
			AND line_no = @line_no
	END
	
	-- Create data line
	SET @data = ''
	
	SET @data = @data + 'LP_CATEGORY_5: '	+ ISNULL(@category_5,'') + '; '
	SET @data = @data + 'LP_CATEGORY_4: '	+ ISNULL(@category_4,'') + '; '
	SET @data = @data + 'LP_CATEGORY_3: '	+ ISNULL(@category_3,'') + '; '
	SET @data = @data + 'LP_CATEGORY_2: '	+ ISNULL(@category_2,'') + '; '
	SET @data = @data + 'LP_CATEGORY_1: '	+ ISNULL(@category_1,'') + '; '

	SET @data = @data + 'LP_CUBIC_FEET: '	+ ISNULL(CAST(@cubic_feet AS VARCHAR(10)),'') + '; '
	SET @data = @data + 'LP_SO_QTY_INCR: '	+ ISNULL(CAST(CAST(@so_qty_increment AS INT) AS VARCHAR(10)),'') + '; '
	SET @data = @data + 'LP_WEIGHT: '		+ ISNULL(CAST(CAST(@weight_ea AS DECIMAL(10,3)) AS VARCHAR(10)),'') + '; '
	SET @data = @data + 'LP_CMDTY_CODE: '	+ ISNULL(@cmdty_code,'') + '; '
	SET @data = @data + 'LP_LENGTH: '		+ ISNULL(CAST(@length AS VARCHAR(10)),'') + '; '

	SET @data = @data + 'LP_WIDTH: '		+ ISNULL(CAST(@width AS VARCHAR(10)),'') + '; ' -- tag - round the value
	SET @data = @data + 'LP_HEIGHT: '		+ ISNULL(CAST(@height AS VARCHAR(10)),'') + '; '
	SET @data = @data + 'LP_SKU: '			+ ISNULL(@sku_code,'') + '; '
	SET @data = @data + 'LP_ORDERED_QTY: '	+ ISNULL(CAST(CAST(@ordered AS INT) AS VARCHAR(10)),'') + '; '
	SET @data = @data + 'LP_ORDERED_QTY_UOM: '	+ ISNULL(@uom,'') + '; '

	SET @data = @data + 'LP_UOM_QTY: '		+ ISNULL(CAST(CAST(@ordered AS INT) AS VARCHAR(10)),'') + '; '
	SET @data = @data + 'LP_UOM: '			+ ISNULL(@uom,'') + '; '
	SET @data = @data + 'LP_ITEM_UOM: '		+ ISNULL(@uom,'') + '; '
	SET @data = @data + 'LP_ITEM_EAN14: '	+ ISNULL(@ean14,'') + '; '
	SET @data = @data + 'LP_ITEM_EAN13: '	+ ISNULL(@ean13,'') + '; '

	SET @data = @data + 'LP_ITEM_EAN8: '	+ ISNULL(@ean8,'') + '; '
	SET @data = @data + 'LP_ITEM_GTIN: '	+ ISNULL(@gtin,'') + '; '
	SET @data = @data + 'LP_ITEM_UPC: '		+ ISNULL(@upc,'') + '; '
	SET @data = @data + 'LP_QC_NO: '		+ CAST(ISNULL(@qc_no,0) AS VARCHAR(10)) + '; '
	SET @data = @data + 'LP_QC_FLAG: '		+ ISNULL(@qc_flag,'') + '; '

	SET @data = @data + 'LP_CUSTOMER_NAME: '+ ISNULL(@customer_name,'') + '; '
	SET @data = @data + 'LP_CUSTOMER_CODE: '+ ISNULL(@cust_code,'') + '; '
	SET @data = @data + 'LP_EXP_DATE: '		+ ISNULL(CONVERT(VARCHAR(12),@exp_date,100),'') + '; '
	SET @data = @data + 'LP_ITEM_DESC: '	+ ISNULL(@part_desc,'') + '; '
	SET @data = @data + 'LP_LINE_NO: '		+ ISNULL(CAST(@line_no AS VARCHAR(10)),'') + '; '

	RETURN @data

END


GO

GRANT REFERENCES ON  [dbo].[f_create_tdc_log_data_string] TO [public]
GO
GRANT EXECUTE ON  [dbo].[f_create_tdc_log_data_string] TO [public]
GO
