SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[tdc_3pl_templates_view] 
	@where_clause varchar(5000)
AS

DECLARE @insert_clause	varchar (1000),
	@location	varchar (10),	
	@template_name	varchar (30),
	@currency 	varchar (8),
	@symbol		varchar (8),
	@charge_per_day	varchar (35),
	@value		varchar (35),
	@spaces		int,
	@max_len        int

SET @insert_clause = 
	'INSERT INTO #templates
	 SELECT location, template_name, template_type,
	        ISNULL(template_desc, ''''),          
	        ISNULL(CAST(charge_per_day  AS varchar(35)), ''0''),    
	        ISNULL(CAST(value           AS varchar(35)), ''0''),   
	        ISNULL(CAST(free_days_begin AS varchar(10)), ''0''),   
	        ISNULL(CAST(free_days_end   AS varchar(10)), ''0''),   
	        ISNULL(currency, ''''),  
	        ISNULL(sp_name,  '''')   
	   FROM tdc_3pl_templates (NOLOCK)  '  

EXEC (@insert_clause + @where_clause)

DECLARE currency_cursor CURSOR FOR
	SELECT location, template_name, currency, charge_per_day, value
          FROM #templates 
OPEN currency_cursor
FETCH NEXT FROM currency_cursor INTO @location, @template_name, @currency, @charge_per_day, @value
WHILE (@@FETCH_STATUS <> -1)
BEGIN
	SELECT @symbol = LTRIM(RTRIM(symbol)) FROM glcurr_vw (NOLOCK) WHERE currency_code = @currency

	EXEC tdc_trim_zeros_sp @charge_per_day output
	EXEC tdc_trim_zeros_sp @value          output

	SELECT @charge_per_day = @symbol + ISNULL(@charge_per_day, '0')
	SELECT @value = @symbol + ISNULL(@value, '0')
	
	UPDATE #templates
           SET charge_per_day = @charge_per_day,
               value          = @value
         WHERE location       = @location
	   AND template_name  = @template_name

	FETCH NEXT FROM currency_cursor INTO @location, @template_name, @currency, @charge_per_day, @value
END
CLOSE      currency_cursor
DEALLOCATE currency_cursor
 	
RETURN
GO
GRANT EXECUTE ON  [dbo].[tdc_3pl_templates_view] TO [public]
GO
