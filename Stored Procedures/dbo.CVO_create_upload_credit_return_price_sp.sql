SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- v1.0 CT 03/12/2013 - Get the line price for a credit return created from sales order upload

CREATE PROC [dbo].[CVO_create_upload_credit_return_price_sp]	@customer_code	VARCHAR(8), 
															@part_no		VARCHAR(30), 
															@return_code	VARCHAR(40),
															@price			DECIMAL(20,8) OUTPUT,
															@list_price		DECIMAL(20,8) OUTPUT,
															@price_level	CHAR(1) OUTPUT,
															@std_pricing	SMALLINT OUTPUT  
AS
BEGIN
	
	SET @std_pricing = 0 -- False

	-- If return code is 05-24 then use std pricing
	IF @return_code = '05-24'
	BEGIN
		SET @std_pricing = 1 -- True
		RETURN
	END
	
	-- Create tenp table for return
	CREATE TABLE #price(
		price		DECIMAL(20,8) NULL,
		list_price	DECIMAL(20,8) NULL)

	-- Call custom pricing routine
	INSERT INTO #price EXEC dbo.CVO_credit_for_returns_price_sp @customer_code, @part_no
	
	SELECT 
		@price = price,
		@list_price = list_price
	FROM
		#price

	-- If price is returned as 0 then do std pricing
	IF ISNULL(@price,-1) = 0
	BEGIN
		SET @std_pricing = 1 -- True
		RETURN
	END
	
	
	-- If price is NULL then set 70% of list price
	IF @price IS NULL
	BEGIN
		SELECT 
			@price = price_a 
		FROM 
			dbo.part_price (NOLOCK) 
		WHERE
			part_no = @part_no

		SET @price = ROUND(@price - (@price * 0.7),2)
		SET @list_price = NULL
	END
	
	SET @price_level = 'Y'
	RETURN
	
END
GO
GRANT EXECUTE ON  [dbo].[CVO_create_upload_credit_return_price_sp] TO [public]
GO
