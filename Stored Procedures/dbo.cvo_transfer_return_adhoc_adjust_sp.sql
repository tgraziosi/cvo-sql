SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- v1.0 CT 24/06/2013 - Issue #1034 - Create an adhoc adjustment for transfer return


CREATE PROC [dbo].[cvo_transfer_return_adhoc_adjust_sp] (@location VARCHAR(10), @part_no VARCHAR(30), @qty DECIMAL (20,8), @bin_no VARCHAR(12), @who_entered VARCHAR(20), @xfer_no INT)
AS
BEGIN

	DECLARE @qty_processed decimal(20,8),  
			@reason_code varchar(10),  
			@date_expires varchar(12),  
			@issue_no  int,  
			@uom   varchar(2),  
			@group_code  varchar(10),  
			@description varchar(255),  
			@sku_code  varchar(30),   
			@height   decimal(20,8),   
			@width   decimal(20,8),   
			@length   decimal(20,8),   
			@cmdty_code  varchar(8),  
			@weight_ea  decimal(20,8),   
			@so_qty_increment decimal(20,8),  
			@cubic_feet  decimal(20,8),  
			@category_1  varchar(15),  
			@category_2  varchar(15),  
			@category_3  varchar(15),  
			@category_4  varchar(15),  
			@category_5  varchar(15),  
			@UPC   varchar(12),  
			@GTIN   varchar(14),  
			@EAN_8   varchar(8),  
			@EAN_13   varchar(13),  
			@EAN_14   varchar(14),  
			@data   varchar(7500)
			

	-- Create temp tables

	CREATE TABLE #temp_who (
		who		VARCHAR(50),
		login_id	VARCHAR(50))
	
	INSERT INTO #temp_who (who, login_id) VALUES ('manager', 'manager')

	IF (SELECT OBJECT_ID('tempdb..#adm_inv_adj')) IS NOT NULL   
	BEGIN     
		DROP TABLE #adm_inv_adj    
	END  

	CREATE TABLE #adm_inv_adj (  
		adj_no   int null,  
		loc    varchar(10) not null,  
		part_no   varchar(30) not null,  
		bin_no   varchar(12) null,  
		lot_ser   varchar(25) null,  
		date_exp  datetime null,  
		qty    decimal(20,8) not null,  
		direction  int not null,  
		who_entered  varchar(50) not null,  
		reason_code  varchar(10) null,  
		code   varchar(8) not null,  
		cost_flag  char(1) null,  
		avg_cost  decimal(20,8) null,  
		direct_dolrs decimal(20,8) null,  
		ovhd_dolrs  decimal(20,8) null,  
		util_dolrs  decimal(20,8) null,  
		err_msg   varchar(255) null,  
		row_id   int identity not null)  


	SET @date_expires = DATEADD(yy,1,GETDATE())
	SELECT @reason_code = value_str FROM dbo.tdc_config WHERE [function] = 'TRANSFER_RET_ADJCODE'

	SELECT @reason_code = ISNULL(@reason_code,'XRET')

	-- Load temp table
	INSERT INTO #adm_inv_adj (
		loc, 
		part_no, 
		bin_no, 
		lot_ser, 
		date_exp, 
		qty, 
		direction, 
		who_entered,   
        reason_code, 
		code)            
   VALUES(
		@location, 
		@part_no, 
		@bin_no, 
		'1', 
		@date_expires, 
		@qty, 
		1,
		@who_entered, 
		'', 
		@reason_code)  

	-- Execute std code
	EXEC dbo.tdc_adm_inv_adj  

	-- Get issue no
	SELECT @issue_no = max(issue_no)   
	FROM dbo.issues  
	WHERE part_no = @part_no  
	AND  code = @reason_code 

	-- Write logs
	INSERT INTO dbo.tdc_ei_bin_log (module, trans, tran_no, tran_ext, location, part_no, from_bin, userid, direction, quantity)                   
	VALUES( 'ADH', 'ADHOC', @issue_no, 0, @location, @part_no, @bin_no, @who_entered, 1, @qty)  

	SELECT 
		@group_code = group_code 
	FROM 
		dbo.tdc_bin_master (NOLOCK) 
	WHERE 
		location = @location 
		AND bin_no = @bin_no  
	
	SELECT 
		@uom = uom, 
		@description = [description], 
		@sku_code = isnull(sku_code, ''), 
		@height = height, 
		@width = width, 
		@length = [length],   
		@cmdty_code = isnull(cmdty_code, ''), 
		@weight_ea = weight_ea, 
		@so_qty_increment = isnull(so_qty_increment, 0),   
		@cubic_feet = cubic_feet   
	FROM 
		dbo.inv_master (NOLOCK) 
	WHERE 
		part_no = @part_no  
	
	SELECT 
		@category_1 = isnull(category_1, ''), 
		@category_2 = isnull(category_2, ''),   
		@category_3 = isnull(category_3, ''), 
		@category_4 = isnull(category_4, ''),   
		@category_5 = isnull(category_5, '')   
	FROM 
		dbo.inv_master_add (NOLOCK) 
	WHERE 
		part_no = @part_no  
	
	SELECT 
		@UPC = ISNULL(UPC, ''), 
		@GTIN = ISNULL(GTIN, ''), 
		@EAN_8 = ISNULL(EAN_8, ''),   
		@EAN_13 = ISNULL(EAN_13, ''), @EAN_14 = ISNULL(EAN_14, '')        
	FROM 
		dbo.uom_id_code (NOLOCK) 
	WHERE 
		part_no = @part_no   
		AND  UOM = @uom  
  
	INSERT INTO dbo.tdc_3pl_issues_log (trans, issue_no, location, part_no, bin_no, bin_group, uom, qty, userid, expert)                   
	VALUES ('ADHOC', @issue_no,  @location, @part_no, @bin_no, @group_code, @uom, @qty, @who_entered, 'N') 

	SELECT @data = 'Transfer Return: ' + LTRIM(STR(@xfer_no)) + '; ' 
	SELECT @data = @data + 'LP_ITEM_EAN14: ; LP_ITEM_EAN13: ; LP_ITEM_EAN8: ; LP_ITEM_GTIN: ; LP_ITEM_UPC: '   
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
  
	INSERT INTO tdc_log (
		tran_date,
		UserID,
		trans_source,
		module,
		trans,
		tran_no,
		tran_ext,
		part_no,  
		lot_ser,
		bin_no,
		location,
		quantity,
		data)             
	SELECT 
		GETDATE(), 
		@who_entered, 
		'CO', 
		'ADH', 
		'ADHOC', 
		LTRIM(STR(@issue_no)), 
		'', 
		@part_no, 
		'1', 
		@bin_no,   
		@location, 
		LTRIM(STR(@qty)), 
		@data
	
	
END
GO
GRANT EXECUTE ON  [dbo].[cvo_transfer_return_adhoc_adjust_sp] TO [public]
GO
