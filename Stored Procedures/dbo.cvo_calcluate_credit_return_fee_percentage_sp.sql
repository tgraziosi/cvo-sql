SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[cvo_calcluate_credit_return_fee_percentage_sp] (@order_no INT, @ext INT)
AS
BEGIN
	DECLARE @fee				DECIMAL(20,8),
			@fee_type			INT,
			@fee_line			INT,
			@total_amt_order	DECIMAL(20,8),
			@tot_ord_disc		DECIMAL(20,8),
			@prev_fee_amount	DECIMAL(20,8),
			@fee_amount			DECIMAL(20,8),
			@curr_factor		DECIMAL(20,8),
			@oper_factor		DECIMAL(20,8),
			@curr_price			DECIMAL(20,8),
			@oper_price			DECIMAL(20,8)

	-- Check that the order is a credit return
	IF NOT EXISTS (SELECT 1 FROM dbo.orders_all (NOLOCK) WHERE order_no = @order_no AND ext = @ext AND [type] = 'C')
	BEGIN
		RETURN
	END

	-- Get fee info
	SELECT
		@fee = fee,
		@fee_type = fee_type,
		@fee_line = fee_line
	FROM
		dbo.cvo_orders_all (NOLOCK)
	WHERE
		order_no = @order_no
		AND ext = @ext

	-- Is there a fee
	IF ISNULL(@fee,0) = 0
	BEGIN
		RETURN
	END

	-- Is there a fee line
	IF ISNULL(@fee_line,0) = 0
	BEGIN
		RETURN
	END

	-- Is it percentage
	IF ISNULL(@fee_type,0) <> 1
	BEGIN
		RETURN
	END

	-- Get credit return details
	SELECT
		--@total_amt_order = total_amt_order,
		--@tot_ord_disc = tot_ord_disc,
		@curr_factor = curr_factor,
		@oper_factor = oper_factor
	FROM 
		dbo.orders_all (NOLOCK) 
	WHERE 
		order_no = @order_no 
		AND ext = @ext	

	-- Get order total
	SELECT 
		@total_amt_order = SUM(CASE discount WHEN 0 THEN price ELSE ROUND((price - (price * (discount/100))),2) END * cr_ordered) 
	FROM 
		dbo.ord_list (NOLOCK)
	WHERE 
		order_no = @order_no 
		AND order_ext = @ext
		AND line_no <> @fee_line 

	-- Get previous fee amount
	SELECT
		@prev_fee_amount = price
	FROM
		dbo.ord_list (NOLOCK)
	WHERE 
		order_no = @order_no 
		AND order_ext = @ext
		AND line_no = @fee_line

	-- Calculate new amount
	SET @fee_amount = ROUND(ISNULL(@total_amt_order,0) * (@fee/100),2) * -1
	--SET @fee_amount = ROUND((@total_amt_order - ISNULL(@prev_fee_amount,0) - @tot_ord_disc) * (@fee/100),2) * -1
	
	-- If new fee is same as previous fee then there is nothing to do
	IF @fee_amount = ISNULL(@prev_fee_amount,0)
	BEGIN
		RETURN
	END

	-- Calculate curr_price and oper_price
	IF @curr_factor >= 0 
	BEGIN
		SET @curr_price = ROUND(@fee_amount / @curr_factor, 2 )
	END
	ELSE
	BEGIN
		SET @curr_price = ROUND(@fee_amount * ABS(@curr_factor), 2)
	END

	IF @oper_factor >= 0
	BEGIN 
		SET @oper_price = ROUND(@curr_price * @oper_factor, 2 )
	END
	ELSE
	BEGIN
		SET @oper_price = ROUND(@curr_price / ABS(@oper_factor), 2 )
	END

	-- Update credit line
	UPDATE
		dbo.ord_list 
	SET
		price = @fee_amount,
		curr_price = @curr_price,
		oper_price = @oper_price
	WHERE 
		order_no = @order_no 
		AND order_ext = @ext
		AND line_no = @fee_line

	
	-- Update credit total
	UPDATE
		dbo.orders_all
	SET
		total_amt_order = total_amt_order - @prev_fee_amount + @fee_amount
	WHERE 
		order_no = @order_no 
		AND ext = @ext
	
END
GO
GRANT EXECUTE ON  [dbo].[cvo_calcluate_credit_return_fee_percentage_sp] TO [public]
GO
