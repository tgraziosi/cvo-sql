SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- Epicor Software (UK) Ltd (c)2013
-- For ClearVision Optical - 68668
-- v1.0 CT 08/08/2013	Returns the order's credit amount as a string for display on orders form

-- SELECT dbo.f_get_order_promo_debit_amount (1419096,0)

CREATE FUNCTION [dbo].[f_get_order_promo_debit_amount](@order_no INT, @ext INT)
RETURNS VARCHAR(20)
AS
BEGIN
	DECLARE @credit_amount	DECIMAL(20,8),
			@ret_string		VARCHAR(20)

	SET @ret_string = ''

	SELECT
		@credit_amount = SUM(credit_amount)
	FROM
		dbo.CVO_debit_promo_customer_det (NOLOCK)
	WHERE
		order_no = @order_no 
		AND ext = @ext

	IF ISNULL(@credit_amount,0) > 0
	BEGIN
	SET @ret_string = '$' + CAST(CAST(@credit_amount AS MONEY) AS VARCHAR(10)) 
	END

	RETURN @ret_string
END 
GO
GRANT REFERENCES ON  [dbo].[f_get_order_promo_debit_amount] TO [public]
GO
GRANT EXECUTE ON  [dbo].[f_get_order_promo_debit_amount] TO [public]
GO
