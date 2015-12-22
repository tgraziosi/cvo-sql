SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[tdc_3pl_quote_preview_sp]
	@total_cost	varchar(20) OUTPUT
AS

DECLARE
	@line_no		int,
	@location		varchar(10),
	@formula		varchar(7650),
	@fixed_costs		decimal(20,8),
	@line_cost		decimal(20,8),
	@labor_costs		decimal(20,8),
	@currency		varchar(8),
	@currency_symbol	varchar(8),
	@line_part       	varchar(30),
	@line_part_desc  	varchar(100),
	@update_cost_str	varchar(20),
	@fixed_lines		int,
	@number_of_days 	int,
	@decimal_index		int,
	@rowid			int

TRUNCATE TABLE #quote_preview

SELECT 	@labor_costs = 0

SELECT @number_of_days = CAST(contract_length AS INT) FROM #quotation_tbl 

--SUM UP ALL FIXED COSTS
SELECT @fixed_costs = SUM(inv_qty*inv_cost_amount)*@number_of_days
  FROM #quote_inventory_costs_tbl

SELECT @fixed_lines = MAX(line_no) FROM #quote_inventory_costs_tbl

--INSERT ALL FIXED COSTS INTO THE OUTPUT TEMP TABLE
INSERT INTO #quote_preview (quote_category, line_no, item_description, item_cost)
	SELECT 'Inventory Cost(s)', line_no, inv_cost_description, inv_qty*inv_cost_amount*@number_of_days
	  FROM #quote_inventory_costs_tbl
	ORDER BY line_no

--SUM UP EACH LINE ITEM
DECLARE quote_line CURSOR FOR
	SELECT line_no, location, line_part, line_part_desc, formula FROM #quote_invoice_items
OPEN quote_line
FETCH NEXT FROM quote_line INTO @line_no, @location, @line_part, @line_part_desc, @formula
WHILE @@FETCH_STATUS = 0
BEGIN
	SELECT @line_cost = 0

	--CALCULATE LINE COST
	EXEC tdc_3pl_calc_quote_line_cost @line_no, @location, @formula, @line_cost OUTPUT

	--INSERT EACH LINE INTO THE OUTPUT TEMP TABLE
	INSERT INTO #quote_preview (quote_category, line_no, item_description, item_cost)
		SELECT 'Formula Generated Cost(s)', @line_no+@fixed_lines, @line_part + ' - [' + @line_part_desc + ']', @line_cost

	--SUM labor costs
	SELECT @labor_costs = @labor_costs + @line_cost

	FETCH NEXT FROM quote_line INTO @line_no, @location, @line_part, @line_part_desc, @formula
END
CLOSE quote_line
DEALLOCATE quote_line

SELECT @total_cost = @fixed_costs + @labor_costs

SELECT @currency = quote_currency FROM #quotation_tbl
SELECT @currency_symbol = symbol FROM glcurr_vw (NOLOCK) WHERE currency_code = @currency

EXEC tdc_format_decimal_string_sp 2, @total_cost OUTPUT

SET @total_cost = @currency_symbol + ' ' + @total_cost

--FORMAT ALL OF THE OUTPUT FROM THE TEMP TABLE
DECLARE output_update CURSOR FOR
	SELECT rowid, item_cost
	  FROM #quote_preview
OPEN output_update
FETCH NEXT FROM output_update INTO @rowid, @update_cost_str
WHILE @@FETCH_STATUS = 0
BEGIN
	EXEC tdc_format_decimal_string_sp 2, @update_cost_str OUTPUT
	SET @update_cost_str = @currency_symbol + ' ' + @update_cost_str
	
	UPDATE #quote_preview
	  SET item_cost = @update_cost_str
	WHERE rowid = @rowid

	FETCH NEXT FROM output_update INTO @rowid, @update_cost_str
END
CLOSE output_update
DEALLOCATE output_update

RETURN 0
GO
GRANT EXECUTE ON  [dbo].[tdc_3pl_quote_preview_sp] TO [public]
GO
