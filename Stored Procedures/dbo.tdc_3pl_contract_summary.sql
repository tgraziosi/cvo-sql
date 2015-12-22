SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[tdc_3pl_contract_summary]
	@cust_code     	varchar(10),
	@ship_to       	varchar(10),
	@contract_name 	varchar(20),
	@s_begin_date	varchar(15),
	@s_end_date	varchar(15),
	@ret		varchar(25) OUTPUT
AS

DECLARE @line_no 		int,
	@template_name		varchar(30),
 	@formula 		varchar(8000),
 	@calculated_formula	varchar(8000),
	@number_of_days  	decimal(20,8),
	@charge_per_day  	decimal(20,8),
	@value			decimal(20,8),
	@order_total		decimal(20,8),
	@price			varchar(20),
	@location		varchar(10),
	@template_type		varchar(15),
	@number_of_bins  	int,
	@free_days_begin	int,
	@free_days_end		int,
	@decimal_index		smallint,
	@sp_name		varchar(255),
	@currency		varchar(8),
	@currency_symbol	varchar(8),
	@type			char(1),
	@transaction		varchar(100), 
	@fee			decimal(20, 8),
	@param_list		varchar(300),
	@single_quote		char(1),
	@begin_date		datetime,
	@end_date		datetime,
	@operator		char(1)
	
	SET @order_total = 0

	SELECT @single_quote = ''''
	SELECT @begin_date = CAST(@s_begin_date AS datetime)
	SELECT @end_date = CAST(@s_end_date AS datetime)

IF OBJECT_ID('tempdb..#processing_selected_formula') IS NOT NULL DROP TABLE #processing_selected_formula
CREATE TABLE #processing_selected_formula (location varchar(10) NULL, selected  varchar(30) NOT NULL, [description] varchar(255) NULL, rowid int IDENTITY)

IF OBJECT_ID('tempdb..#price') IS NOT NULL DROP TABLE #price
CREATE TABLE #price (price decimal(20, 8) NOT NULL)

TRUNCATE TABLE #order

INSERT INTO #order (line_no, location, price, currency, charge, line_part, line_part_desc)                   
 SELECT line_no, location, 0, '', '0', line_part, line_part_desc
   FROM tdc_3pl_invoice_items         
  WHERE cust_code     = @cust_code
    AND ship_to       = @ship_to
    AND contract_name = @contract_name
DECLARE line_cursor CURSOR FOR 
	SELECT location, line_no FROM #order
OPEN line_cursor
FETCH NEXT FROM line_cursor INTO @location, @line_no 
WHILE (@@FETCH_STATUS <> -1)
BEGIN

	SELECT @formula = formula
	   FROM tdc_3pl_invoice_items         
	  WHERE cust_code     = @cust_code
	    AND ship_to       = @ship_to
	    AND contract_name = @contract_name
	    AND line_no       = @line_no
	    AND location      = @location

	SET @calculated_formula = ''

	TRUNCATE TABLE #processing_selected_formula

	EXEC tdc_3pl_parse_formula '3PLPROCESS', @formula, @location

	DECLARE template_cursor CURSOR FOR 
		SELECT selected FROM #processing_selected_formula ORDER BY rowid
	OPEN template_cursor
	FETCH NEXT FROM template_cursor INTO @template_name 
	WHILE (@@FETCH_STATUS <> -1)
	BEGIN
		SELECT @operator = '+'
		IF @template_name IN ('+', '-', '*', '/', '(', ')')
		BEGIN
			SELECT @operator = @template_name
			SET @price = ''
		END
		ELSE
		BEGIN
			SELECT @template_type   = template_type,
			       @charge_per_day  = ISNULL(charge_per_day, 0),
			       @free_days_begin = ISNULL(free_days_begin,0),
			       @free_days_end   = ISNULL(free_days_end, 0),
			       @sp_name         = ISNULL(sp_name, ''),
			       @value           = ISNULL(value,0),
			       @currency        = ISNULL(currency, ''),
			       @currency_symbol = (SELECT symbol FROM glcurr_vw (NOLOCK) WHERE currency_code = currency)
			  FROM tdc_3pl_templates
                         WHERE location      = @location
                           AND template_name = @template_name

			SELECT @begin_date = DATEADD(day,  @free_days_begin, @begin_date)
			SELECT @end_date   = DATEADD(day, -@free_days_end,   @end_date)

			SELECT @number_of_days = DATEDIFF(day, @begin_date, @end_date)

			IF @number_of_days < 0 SET @number_of_days = 0

			----------------------------------------------------------------------------------
			-- Value									--
			----------------------------------------------------------------------------------
			IF @template_type = 'Value'
			BEGIN
				SET @price = CAST(@value AS varchar(20))
			END
			
			----------------------------------------------------------------------------------
			-- Custom									--
			----------------------------------------------------------------------------------
			IF @template_type = 'Custom'
			BEGIN
				IF NOT EXISTS (SELECT * FROM sysobjects WHERE type = 'P' AND [name] = @sp_name)
				BEGIN
					CLOSE      line_cursor
					DEALLOCATE line_cursor

					CLOSE      template_cursor
					DEALLOCATE template_cursor

					RAISERROR ('Stored Procedure: %s does not exist in the database', 16, 1, @sp_name)
					TRUNCATE TABLE #order
					RETURN 
				END
				--BUILD SP PARAMETER LIST
					-- @customer	varchar(10),
					-- @ship_to	varchar(10),
					-- @location	varchar(10),
					-- @template_name	varchar(30),
					-- @currency	varchar(8),
					-- @begin_date	datetime,
					-- @end_date	datetime,
					-- @cost		decimal(20,8) OUTPUT

				SELECT @param_list = 	@single_quote + @cust_code + @single_quote + ', ' + 
							@single_quote + @ship_to + @single_quote + ', ' + 
							@single_quote + @location + @single_quote + ', ' + 
							@single_quote + @template_name + @single_quote + ', ' + 
							@single_quote + @currency + @single_quote + ', ' + 
							@single_quote + @s_begin_date + @single_quote + ', ' + 
							@single_quote + @s_end_date + @single_quote + ', '
				TRUNCATE TABLE #price

				EXEC ('DECLARE @output decimal(20, 8) EXEC ' + @sp_name + ' ' + @param_list + ' @output OUTPUT INSERT INTO #price SELECT @output')

				SELECT @price = ISNULL(CAST (SUM(price) AS varchar(20)), '0') FROM #price
			END

			----------------------------------------------------------------------------------
			-- Inv Storage									--
			----------------------------------------------------------------------------------
			IF @template_type = 'Inv Storage'
			BEGIN
				SELECT @number_of_bins = 0

				SELECT @type = ISNULL((SELECT DISTINCT type 
 							 FROM tdc_3pl_assigned_bins (NOLOCK)
                                                        WHERE location      = @location
							  AND template_name = @template_name), '')
				------------------------------------------
				-- Distinct bins
				------------------------------------------
				IF ISNULL(@type, '') = ''
				BEGIN	
					SELECT @type = ISNULL((SELECT DISTINCT type
								 FROM tdc_3pl_assigned_parts (NOLOCK) 
								WHERE cust_code     = @cust_code
 								  AND ship_to       = @ship_to
                                                                  AND contract_name = @contract_name), '')
					IF @type = 'P'
					BEGIN
						SELECT @number_of_bins = COUNT(DISTINCT bin_no) 
					 	  FROM tdc_3pl_receipts_log (NOLOCK)
						 WHERE tran_date BETWEEN @begin_date AND @end_date
						   AND part_no IN (SELECT filter_value
								     FROM tdc_3pl_assigned_parts (NOLOCK) 
								    WHERE cust_code     = @cust_code
								      AND ship_to       = @ship_to
                                                                      AND contract_name = @contract_name)
					END

					IF @type = 'G'
					BEGIN
						SELECT @number_of_bins = COUNT(DISTINCT bin_no) 
					 	  FROM tdc_3pl_receipts_log (NOLOCK)
						 WHERE tran_date BETWEEN @begin_date AND @end_date
						   AND part_no IN (SELECT a.part_no
								     FROM inv_master             a (NOLOCK),
								          tdc_3pl_assigned_parts b (NOLOCK)
								    WHERE a.category      = b.filter_value 
								      AND b.cust_code     = @cust_code
								      AND b.ship_to       = @ship_to
                                                                      AND b.contract_name = @contract_name)
					END

					IF @type = 'R'
					BEGIN
						SELECT @number_of_bins = COUNT(DISTINCT bin_no) 
					 	  FROM tdc_3pl_receipts_log (NOLOCK)
						 WHERE tran_date BETWEEN @begin_date AND @end_date
						   AND part_no IN (SELECT a.part_no
								     FROM inv_master             a (NOLOCK),
								          tdc_3pl_assigned_parts b (NOLOCK)
								    WHERE a.type_code     = b.filter_value 
								      AND b.cust_code     = @cust_code
								      AND b.ship_to       = @ship_to
                                                                      AND b.contract_name = @contract_name)
					END

					IF @type = 'L'
					BEGIN
						SELECT @number_of_bins = COUNT(DISTINCT bin_no) 
					 	  FROM tdc_3pl_receipts_log (NOLOCK)
						 WHERE tran_date BETWEEN @begin_date AND @end_date
						   AND location IN (SELECT filter_value
								     FROM tdc_3pl_assigned_parts (NOLOCK) 
								    WHERE cust_code     = @cust_code
								      AND ship_to       = @ship_to
                                                                      AND contract_name = @contract_name)
					END

				END
				------------------------------------------
				ELSE	-- Fixed bins 
				------------------------------------------
				BEGIN					
					IF @type = 'G'				
					BEGIN
						SELECT @number_of_bins = COUNT(*) 
						  FROM tdc_bin_master (NOLOCK)
                                                 WHERE location = @location
						   AND group_code IN (SELECT bin_no 
                            						FROM tdc_3pl_assigned_bins (NOLOCK) 
                                                                       WHERE location      = @location
									 AND template_name = @template_name)						
					END

					IF @type = 'B'				
					BEGIN
						SELECT @number_of_bins = COUNT(*) 
					          FROM tdc_3pl_assigned_bins (NOLOCK) 
                                                 WHERE location      = @location
						   AND template_name = @template_name
					END

				END

				SELECT @price = CAST(@number_of_bins * @charge_per_day * @number_of_days AS varchar(20))
			END
			----------------------------------------------------------------------------------
			-- Labor									--
			----------------------------------------------------------------------------------
			IF @template_type = 'Labor'
			BEGIN
				EXEC tdc_3pl_labor_template_price @cust_code, @ship_to, @contract_name, @location, @template_name, @begin_date,	@end_date, @price OUTPUT
			END			
		END	
		SELECT @price = ISNULL(@price, '')
		SELECT @calculated_formula = @calculated_formula + @operator + @price

		FETCH NEXT FROM template_cursor INTO @template_name 
	END

	CLOSE	   template_cursor
	DEALLOCATE template_cursor

	TRUNCATE TABLE #price

	EXEC ('INSERT INTO #price SELECT ' + @calculated_formula)
	 
	SELECT @price = ISNULL(CAST (price AS varchar(20)), '0') FROM #price

	SELECT @order_total = @order_total + CAST(@price AS decimal(20, 8))

	EXEC tdc_trim_zeros_sp @price output

	SELECT @price = ISNULL(@price, '0')
	SELECT @decimal_index = CHARINDEX('.', @price)

	IF @decimal_index = 0
		SELECT @price = @price + '.'
	
	SELECT @price = @price + '0000'

	SELECT @price = SUBSTRING(@price, 1, CHARINDEX('.', @price) + 2)

	UPDATE #order
	   SET price  = CASE WHEN CAST(@price AS decimal(20, 8)) <= 0
			     THEN 0
			     ELSE CAST(@price AS decimal(20, 8))
		        END,
	       currency = @currency,
	       charge = CASE WHEN CAST(@price AS decimal(20, 8)) <= 0
			     THEN @currency_symbol + ' ' + '0.00'
			     ELSE @currency_symbol + ' ' + @price
		        END
         WHERE line_no = @line_no 

	FETCH NEXT FROM line_cursor INTO @location, @line_no 
END

CLOSE	   line_cursor
DEALLOCATE line_cursor

IF (SELECT COUNT(DISTINCT currency) FROM #order (NOLOCK)) > 1
BEGIN
	RAISERROR ('Multiple currencies are not allowed', 16, 1)	
	RETURN
END

SET @ret = CAST (@order_total AS varchar(20))

EXEC tdc_trim_zeros_sp @ret output

SELECT @decimal_index = CHARINDEX('.', @ret)

IF @decimal_index = 0
	SELECT @ret = @ret + '.'

SELECT @ret = @ret + '0000'
SELECT @ret = SUBSTRING(@ret, 1, CHARINDEX('.', @ret) + 2)
SET @ret = @currency_symbol + ' ' + @ret

RETURN
GO
GRANT EXECUTE ON  [dbo].[tdc_3pl_contract_summary] TO [public]
GO
