SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[tdc_3pl_calc_quote_line_cost] 
	@line_no	int,
	@location	varchar(10), 
	@formula 	varchar(7650),
	@line_cost 	decimal(20,8) OUTPUT
AS

IF OBJECT_ID('tempdb..#price') IS NOT NULL 
	DROP TABLE #price

CREATE TABLE #price
(
	price decimal(20, 8) NOT NULL
)

DECLARE @template_name		varchar(30),
 	@calculated_formula	varchar(7650),
	@operator		char(1),
	@price			varchar(20),
	@template_type		varchar(15),
	@value			decimal(20,8)

SELECT @calculated_formula = ''

TRUNCATE TABLE #quote_selected_formula

EXEC tdc_3pl_parse_formula '3PLQUOTE', @formula, @location

DECLARE template_cursor CURSOR FOR 
	SELECT selected FROM #quote_selected_formula ORDER BY rowid
OPEN template_cursor
FETCH NEXT FROM template_cursor INTO @template_name 
WHILE (@@FETCH_STATUS <> -1)
BEGIN
	SELECT @operator = '+' --SET THE DEFAULT VALUE FOR THE OPERATOR VARIABLE
	IF @template_name IN ('+', '-', '*', '/', '(', ')')
	BEGIN
		SELECT @operator = @template_name
		SET @price = ''
	END
	ELSE
	BEGIN
		SELECT @template_type   = template_type,
		       @value           = ISNULL(value,0)
		  FROM #quote_templates_used_tbl (NOLOCK)
                 WHERE location      = @location
                   AND template_name = @template_name
		----------------------------------------------------------------------------------
		-- Value									--
		----------------------------------------------------------------------------------
		IF @template_type = 'Value'
		BEGIN
			SELECT @price = CAST(@value AS varchar(20))
		END
		----------------------------------------------------------------------------------
		-- Labor									--
		----------------------------------------------------------------------------------
		IF @template_type = 'Labor'
		BEGIN
			-- @template_type
			-- @value
			-- @location
			-- @template_name
			-- @line_no
			-- @location
			SELECT 	@price = CAST(ISNULL(SUM(a.qty * b.fee),0) AS VARCHAR(20))
			  FROM	#quote_assigned_labor_values	   a (NOLOCK),
				#quote_templates_labor_details_tbl b (NOLOCK)
			WHERE b.template_name = @template_name
			  AND b.location = @location
			  AND b.tran_id = a.tran_id
			  AND b.category = a.category
		END			
	END

	SELECT @price = ISNULL(@price, '')
	SELECT @calculated_formula = @calculated_formula + @operator + @price

	FETCH NEXT FROM template_cursor INTO @template_name 
END
CLOSE	   template_cursor
DEALLOCATE template_cursor

--INSERT THE PRICE FOR THE PARTICULAR LINE
TRUNCATE TABLE #price
EXEC ('INSERT INTO #price SELECT ' + @calculated_formula)

SELECT @line_cost = ISNULL(price , 0) FROM #price

RETURN 0
GO
GRANT EXECUTE ON  [dbo].[tdc_3pl_calc_quote_line_cost] TO [public]
GO
