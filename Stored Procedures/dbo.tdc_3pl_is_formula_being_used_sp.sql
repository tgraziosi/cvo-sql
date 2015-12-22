SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[tdc_3pl_is_formula_being_used_sp]
	@location	varchar(10),
	@template_name	varchar(30),
	@usage_count	int	OUTPUT
AS
DECLARE	@contract_name	varchar(30),
	@formula	varchar(7650),
	@line_no	int

SELECT @usage_count = 0
TRUNCATE TABLE #assigned_contracts_quotes
--GET THE NUMBER OF CONTRACTS THAT ARE USING THIS TEMPLATE
	--POPULATE THE TEMP TABLE
DECLARE item_cursor CURSOR FOR
	SELECT contract_name, formula, line_no
	  FROM tdc_3pl_invoice_items
	WHERE location = @location
OPEN item_cursor
FETCH NEXT FROM item_cursor INTO @contract_name, @formula, @line_no
WHILE @@FETCH_STATUS = 0
BEGIN
	TRUNCATE TABLE #selected_formula
	EXEC tdc_3pl_parse_formula '3PLSETUP', @formula, @location
	
	IF EXISTS(SELECT * FROM #selected_formula WHERE selected = @template_name AND location = @location)
	BEGIN
		INSERT INTO #assigned_contracts_quotes (contract_or_quote, category, line_no, formula)
			SELECT @contract_name, 'Contract', @line_no, @formula
	END

	FETCH NEXT FROM item_cursor INTO @contract_name, @formula, @line_no
END
CLOSE item_cursor
DEALLOCATE item_cursor

--GET THE NUMBER OF CONTRACTS THAT ARE USING THIS TEMPLATE
	--POPULATE THE TEMP TABLE
DECLARE item_cursor CURSOR FOR
	SELECT CAST(quote_id AS varchar(20)), formula, line_no
	  FROM tdc_3pl_quote_invoice_items
	WHERE location = @location
OPEN item_cursor
FETCH NEXT FROM item_cursor INTO @contract_name, @formula, @line_no
WHILE @@FETCH_STATUS = 0
BEGIN
	TRUNCATE TABLE #selected_formula
	EXEC tdc_3pl_parse_formula @formula, @location
	
	IF EXISTS(SELECT * FROM #selected_formula WHERE selected = @template_name AND location = @location)
	BEGIN
		INSERT INTO #assigned_contracts_quotes (contract_or_quote, category, line_no, formula)
			SELECT 'Quotation #'+@contract_name, 'Quote', @line_no, @formula
	END

	FETCH NEXT FROM item_cursor INTO @contract_name, @formula, @line_no
END
CLOSE item_cursor
DEALLOCATE item_cursor

IF EXISTS(SELECT * FROM #assigned_contracts_quotes(NOLOCK))
BEGIN
	SELECT @usage_count = COUNT(*)
	  FROM #assigned_contracts_quotes

	RETURN 1
END
ELSE
BEGIN
	SELECT @usage_count = 0

	RETURN 0
END
GO
GRANT EXECUTE ON  [dbo].[tdc_3pl_is_formula_being_used_sp] TO [public]
GO
