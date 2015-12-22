SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[tdc_3pl_convert_quote_to_contract]
	@cust_code		varchar(8),
	@ship_to		varchar(10),
	@contract_name		varchar(20),
	@contract_description	varchar(255),
	@default_period		varchar(10),
	@userid			varchar(50),
	@output_options		int,
	@err_msg		varchar(255) OUTPUT
AS
	DECLARE
		@quote_id	int,
		@inv_line_count	int,
		@line_no	int,
		@location	varchar(10),
		@template_name	varchar(30),
		@line_part	varchar(30),
		@line_part_desc	varchar(100),
		@formula	varchar(7650)

	--See if contract name already exists
	IF EXISTS(SELECT * FROM tdc_3pl_contracts (NOLOCK) WHERE cust_code = @cust_code AND ship_to = @ship_to AND contract_name = @contract_name)
	BEGIN
		SELECT @err_msg = 'Contract name already exists.'
		RETURN -1
	END
	
	--INSERT contract header
	INSERT INTO tdc_3pl_contracts (cust_code, ship_to, contract_name, default_period, contract_desc, created_by, created_date, modified_by, modified_date)
		SELECT @cust_code, @ship_to, @contract_name, @default_period, @contract_description, @userid, getdate(), @userid, getdate()

	--UPDATE part filter
	IF EXISTS(SELECT * FROM #quote_part_filter)
	BEGIN
		INSERT INTO tdc_3pl_assigned_parts (cust_code, ship_to, contract_name, filter_value, type)
			SELECT @cust_code, @ship_to, @contract_name, filter_value, part_type 
			  FROM #quote_part_filter
	END
	
--////////////////////////////////////////////////////////////////////////

	--UPDATE inventory costs
	SELECT @line_no = 1
	IF @output_options = 1 --All on the same line, grouped by location
	BEGIN
		TRUNCATE TABLE #location_store

		INSERT INTO #location_store (location)
			SELECT DISTINCT location 
			  FROM #quote_inv_templates_assigned

		SELECT @inv_line_count = COUNT(*) FROM #location_store

		DECLARE	location_cursor	CURSOR FOR
			SELECT location 
			  FROM #location_store
		OPEN location_cursor
		FETCH NEXT FROM location_cursor INTO @location
		WHILE @@FETCH_STATUS = 0
		BEGIN
			SELECT @formula = ''
			DECLARE item_cursor CURSOR FOR
				SELECT template_name 
				  FROM #quote_inv_templates_assigned
				WHERE location = @location
			OPEN item_cursor
			FETCH NEXT FROM item_cursor INTO @template_name
			WHILE @@FETCH_STATUS = 0
			BEGIN
				SELECT @formula = @formula + @template_name + '+'
				FETCH NEXT FROM item_cursor INTO @template_name
			END
			CLOSE item_cursor
			DEALLOCATE item_cursor

			--TRIM OFF THE LAST '+' FROM THE FORMULA
			SELECT @formula = SUBSTRING(@formula, 1, LEN(@formula)-1)

			--SET DEFAULT LINE DESCRIPTIONS
			SELECT @line_part = 'Inventory Cost ' + CAST(@line_no AS varchar(10))
			SELECT @line_part_desc = 'Inventory Cost Desription ' + CAST(@line_no AS varchar(10))

			--INSERT RECORD
			INSERT INTO tdc_3pl_invoice_items 
				(cust_code, ship_to, contract_name, line_part, line_part_desc, location, line_no, formula)
			SELECT @cust_code, @ship_to, @contract_name, @line_part, @line_part_desc, @location, @line_no, @formula

			SELECT @line_no = @line_no + 1
			FETCH NEXT FROM location_cursor INTO @location
		END
		CLOSE location_cursor
		DEALLOCATE location_cursor

	END
	ELSE
	BEGIN
		SELECT @inv_line_count = COUNT(*) FROM #quote_inv_templates_assigned

		DECLARE item_cursor CURSOR FOR
			SELECT location, template_name 
			  FROM #quote_inv_templates_assigned
			ORDER BY location, template_name
		OPEN item_cursor
		FETCH NEXT FROM item_cursor INTO @location, @template_name
		WHILE @@FETCH_STATUS = 0
		BEGIN
			SELECT @formula = @template_name

			--SET DEFAULT LINE DESCRIPTIONS
			SELECT @line_part = 'Inventory Cost ' + CAST(@line_no AS varchar(10))
			SELECT @line_part_desc = 'Inventory Cost Desription ' + CAST(@line_no AS varchar(10))

			--INSERT RECORD
			INSERT INTO tdc_3pl_invoice_items 
				(cust_code, ship_to, contract_name, line_part, line_part_desc, location, line_no, formula)
			SELECT @cust_code, @ship_to, @contract_name, @line_part, @line_part_desc, @location, @line_no, @formula
	
			SELECT @line_no = @line_no + 1

			FETCH NEXT FROM item_cursor INTO @location, @template_name
		END
		CLOSE item_cursor
		DEALLOCATE item_cursor
	END
	
	--UPDATE formula costs
	INSERT INTO tdc_3pl_invoice_items (cust_code, ship_to, contract_name, line_part, line_part_desc, location, line_no, formula)
		SELECT @cust_code, @ship_to, @contract_name, line_part, line_part_desc, location, line_no + @inv_line_count, formula
		  FROM #quote_invoice_items
		ORDER BY line_no
	
	--	UPDATE is_contract field for the QUOTATION
	SELECT @quote_id = quote_id 
	  FROM #quotation_tbl (NOLOCK)

	UPDATE tdc_3pl_quotation_tbl 
		SET is_contract = 'Y' 
	WHERE quote_id = @quote_id

RETURN 0
GO
GRANT EXECUTE ON  [dbo].[tdc_3pl_convert_quote_to_contract] TO [public]
GO
