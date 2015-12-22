SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*
v1.0 CT 23/04/2013 - Created

retval values: 
-1	= successful, but nothing to process
0	= successful and data to process
1	= invalid criteria

Testing Code:
EXEC dbo.CVO_calculate_discount_adjustment_wrap_sp	@customer_code = '010125', 
													@date_from	 = '2013-01-30',
													@date_to = '1 april 2013',
													@order_no_from = NULL, 
													@ext_from = NULL, 
													@order_no_to = NULL, 
													@ext_to	 = NULL, 
													@price_class= 'D'

*/
CREATE PROCEDURE [dbo].[CVO_calculate_discount_adjustment_wrap_sp]	@customer_code	VARCHAR(8), 
																@date_from		DATETIME = NULL,
																@date_to		DATETIME = NULL,
																@order_no_from	INT = NULL, 
																@ext_from		INT = NULL, 
																@order_no_to	INT = NULL, 
																@ext_to			INT = NULL, 
																@price_class	VARCHAR(8)
																  
AS
BEGIN
	DECLARE @ret_val		INT,  
			@message		VARCHAR(1000)


	SET NOCOUNT ON

	EXEC dbo.CVO_calculate_discount_adjustment_sp	@customer_code = @customer_code, 
													@date_from	 = @date_from,
													@date_to = @date_to,
													@order_no_from = @order_no_from, 
													@ext_from = @ext_from, 
													@order_no_to = @order_no_to, 
													@ext_to	 = @ext_to, 
													@price_class = @price_class,
													@ret_val = @ret_val OUTPUT,  
													@message = @message OUTPUT

	SELECT 
		@ret_val, 
		CASE @ret_val 
			WHEN 0 THEN @message 
			WHEN -2 THEN @message
			ELSE '' 
		END
	

END

GO
GRANT EXECUTE ON  [dbo].[CVO_calculate_discount_adjustment_wrap_sp] TO [public]
GO
