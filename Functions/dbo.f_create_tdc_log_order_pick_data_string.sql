SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- v1.0 CT 25/07/2013 - Creates data line for tdc log for order pick
-- SELECT dbo.f_create_tdc_log_order_pick_data_string (1419098,0,2)
CREATE FUNCTION [dbo].[f_create_tdc_log_order_pick_data_string] (@order_no INT,
															@ext INT,
														@line_no INT)
RETURNS VARCHAR(7500)
AS
BEGIN
	DECLARE @data				VARCHAR(7500),
			@uom				CHAR(2),
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
			@part_desc			VARCHAR(255),
			@lot_ser			VARCHAR(25),
			@part_type			CHAR(1),
			@attention			VARCHAR(40),
			@cust_po			VARCHAR(20),     	
			@phone				VARCHAR(20),	     	     	
			@ship_to			VARCHAR(10),	     	     	
			@ship_to_add_1		VARCHAR(40),
			@ship_to_add_2		VARCHAR(40),	     	     	
			@ship_to_add_3		VARCHAR(40),	     	     	
			@ship_to_add_4		VARCHAR(40),	     	     	
			@ship_to_add_5		VARCHAR(40),	     	     	
			@ship_to_city		VARCHAR(40),	     	     	
			@ship_to_country	VARCHAR(40),	     	     	
			@ship_to_name		VARCHAR(40),	     	     	
			@ship_to_region		VARCHAR(10),	     	     	
			@ship_to_state		VARCHAR(40),	     	     	
			@ship_to_zip		VARCHAR(15),	     	     	
			@special_instr		VARCHAR(255)	
						

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
	
	-- Get order header details
	SELECT 
		@attention = attention, 
		@cust_po = cust_po, 
		@phone = phone, 
		@ship_to = ship_to, 
		@ship_to_add_1 = ship_to_add_1, 
		@ship_to_add_2 = ship_to_add_2, 
		@ship_to_add_3 = ship_to_add_3, 
		@ship_to_add_4 = ship_to_add_4, 
		@ship_to_add_5 = ship_to_add_5, 
		@ship_to_city = ship_to_city, 
		@ship_to_country = ship_to_country, 
		@ship_to_name = ship_to_name, 
		@ship_to_region = ship_to_region, 
		@ship_to_state = ship_to_state, 
		@ship_to_zip = ship_to_zip, 
		@special_instr = special_instr 						  
	FROM 
		dbo.orders (nolock) 						 
	WHERE 
		order_no = @order_no 
		AND ext = @ext

	-- If part type = M then skip the rest of the selects and produce balnk data line
	IF @part_type <> 'M'
	BEGIN
		
		-- Get part details
		SELECT 
			@uom = uom ,
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

	END
	
	-- Create data line
	SET @data = ''
	
	SET @data = @data + 'LP_ITEM_EAN14: '	+ ISNULL(@ean14,'') + '; '
	SET @data = @data + 'LP_ITEM_EAN13: '	+ ISNULL(@ean13,'') + '; '
	SET @data = @data + 'LP_ITEM_EAN8: '	+ ISNULL(@ean8,'') + '; '
	SET @data = @data + 'LP_ITEM_GTIN: '	+ ISNULL(@gtin,'') + '; '
	SET @data = @data + 'LP_ITEM_UPC: '		+ ISNULL(@upc,'') + '; '

	SET @data = @data + 'LP_CATEGORY_5: '	+ ISNULL(@category_5,'') + '; '
	SET @data = @data + 'LP_CATEGORY_4: '	+ ISNULL(@category_4,'') + '; '
	SET @data = @data + 'LP_CATEGORY_3: '	+ ISNULL(@category_3,'') + '; '
	SET @data = @data + 'LP_CATEGORY_2: '	+ ISNULL(@category_2,'') + '; '
	SET @data = @data + 'LP_CATEGORY_1: '	+ ISNULL(@category_1,'') + '; '

	SET @data = @data + 'LP_CUBIC_FEET: '	+ ISNULL(CAST(@cubic_feet AS VARCHAR(10)),'') + '; '
	SET @data = @data + 'LP_SO_QTY_INCR: '	+ ISNULL(CAST(CAST(@so_qty_increment AS INT) AS VARCHAR(10)),'') + '; '
	SET @data = @data + 'LP_WEIGHT: '		+ ISNULL(CAST(@weight_ea AS VARCHAR(10)),'') + '; '
	SET @data = @data + 'LP_CMDTY_CODE: '	+ ISNULL(@cmdty_code,'') + '; '
	SET @data = @data + 'LP_LENGTH: '		+ ISNULL(CAST(@length AS VARCHAR(10)),'') + '; '

	SET @data = @data + 'LP_WIDTH: '		+ ISNULL(CAST(@width AS VARCHAR(10)),'') + '; '
	SET @data = @data + 'LP_HEIGHT: '		+ ISNULL(CAST(@height AS VARCHAR(10)),'') + '; '
	SET @data = @data + 'LP_SKU: '			+ ISNULL(@sku_code,'') + '; '
	SET @data = @data + 'LP_ITEM_UOM: '		+ ISNULL(@uom,'') + '; '
	SET @data = @data + 'LP_SPECIAL_INSTR: '	+ ISNULL(@special_instr,'') + '; '

	SET @data = @data + 'LP_SHIP_TO_ZIP: '		+ ISNULL(@ship_to_zip,'') + '; '
	SET @data = @data + 'LP_SHIP_TO_STATE: '	+ ISNULL(@ship_to_state,'') + '; '
	SET @data = @data + 'LP_SHIP_TO_REGION: '	+ ISNULL(@ship_to_region,'') + '; '
	SET @data = @data + 'LP_SHIP_TO_NAME: '		+ ISNULL(@ship_to_name,'') + '; '
	SET @data = @data + 'LP_SHIP_TO_COUNTRY: '	+ ISNULL(@ship_to_country,'') + '; '

	SET @data = @data + 'LP_SHIP_TO_CITY: '		+ ISNULL(@ship_to_city,'') + '; '
	SET @data = @data + 'LP_SHIP_TO_ADD_5: '	+ ISNULL(@ship_to_add_5,'') + '; '
	SET @data = @data + 'LP_SHIP_TO_ADD_4: '	+ ISNULL(@ship_to_add_4,'') + '; '
	SET @data = @data + 'LP_SHIP_TO_ADD_3: '	+ ISNULL(@ship_to_add_3,'') + '; '
	SET @data = @data + 'LP_SHIP_TO_ADD_2: '	+ ISNULL(@ship_to_add_2,'') + '; '

	SET @data = @data + 'LP_SHIP_TO_ADD_1: '	+ ISNULL(@ship_to_add_1,'') + '; '
	SET @data = @data + 'LP_SHIP_TO: '			+ ISNULL(@ship_to,'') + '; '
	SET @data = @data + 'LP_PHONE: '			+ ISNULL(@phone,'') + '; '
	SET @data = @data + 'LP_CUST_PO: '			+ ISNULL(@cust_po,'') + '; '
	SET @data = @data + 'LP_ATTENTION: '		+ ISNULL(@attention,'') + '; '

	SET @data = @data + 'LP_ITEM_UPC: '			+ ISNULL(@upc,'') + '; '
	SET @data = @data + 'LP_UOM: '				+ ISNULL(@uom,'') + '; '
	SET @data = @data + 'LP_UOM_QTY: '			+ ISNULL(CAST(CAST(@ordered AS INT) AS VARCHAR(10)),'') + '; '
	SET @data = @data + 'LP_ORDERED_QTY: '		+ ISNULL(CAST(CAST(@ordered AS INT) AS VARCHAR(10)),'') + '; '
	SET @data = @data + 'LP_LB_TRACKING: '		+ 'Y' + '; '

	SET @data = @data + 'LP_STATION: '			+ '' + '; '
	SET @data = @data + 'LP_ITEM_DESC: '		+ ISNULL(@part_desc,'') + '; '

	RETURN @data

END

GO
GRANT REFERENCES ON  [dbo].[f_create_tdc_log_order_pick_data_string] TO [public]
GO
GRANT EXECUTE ON  [dbo].[f_create_tdc_log_order_pick_data_string] TO [public]
GO
