SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- Epicor Software (UK) Ltd (c)2014
-- For ClearVision Optical - 68668
-- Returns additioal freigt charge - decimal(20,8)
-- v1.0 CT 28/01/2014	returns the additional freight charge for an orders

-- SELECT dbo.f_calculate_residential_charge (1420063, 0)

CREATE FUNCTION [dbo].[f_calculate_residential_charge]	(@order_no	INT,
													 @ext		INT) 
RETURNS DECIMAL(20,8)
AS
BEGIN
	DECLARE @charge			DECIMAL(20,8),
			@cust_code		VARCHAR(10),
			@ship_to		VARCHAR(10)

	SET @charge = 0

	-- Get order settings
	SELECT
		@cust_code = cust_code,
		@ship_to = ship_to	
	FROM
		dbo.orders_all (NOLOCK)
	WHERE
		order_no = @order_no
		AND ext = @ext

	IF @@ROWCOUNT = 0
		RETURN @charge

	-- If there is a ship to check that
	IF ISNULL(@ship_to,'') <> ''
	BEGIN
		IF NOT EXISTS (SELECT 1 FROM dbo.cvo_armaster_all (NOLOCK) WHERE customer_code = @cust_code AND ship_to = @ship_to AND address_type = 1 AND ISNULL(residential_address,0) = 1)
		BEGIN
			RETURN @charge
		END
	END
	ELSE
	BEGIN
		-- No ship to, check cust_code
		IF NOT EXISTS (SELECT 1 FROM dbo.cvo_armaster_all (NOLOCK) WHERE customer_code = @cust_code AND address_type = 0 AND ISNULL(residential_address,0) = 1)
		BEGIN
			RETURN @charge
		END
	END


	-- Get config setting
	IF EXISTS (SELECT 1 FROM dbo.config (NOLOCK) WHERE flag = 'RESIDENT_ADDR_CHARGE')
	BEGIN
		SELECT 
			@charge = CAST(value_str AS DECIMAL(20,8))
		FROM 
			dbo.config (NOLOCK) 
		WHERE 
			flag = 'RESIDENT_ADDR_CHARGE'
	END
		
	RETURN @charge 

END
GO
GRANT REFERENCES ON  [dbo].[f_calculate_residential_charge] TO [public]
GO
GRANT EXECUTE ON  [dbo].[f_calculate_residential_charge] TO [public]
GO
