SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*
v1.0 CT 25/06/2013 - Created


EXEC CVO_debit_promo_enrollment_sp	1419832, 0

*/
CREATE PROCEDURE [dbo].[CVO_debit_promo_enrollment_sp]	@order_no		INT, 
													@ext			INT	
													

AS
BEGIN

	SET NOCOUNT ON

	DECLARE @promo_id			VARCHAR(20),
			@promo_level		VARCHAR(30),
			@customer_code		VARCHAR(8),
			@order_amount		DECIMAL(20,8),
			@credit				DECIMAL(20,8),
			@fixed_credit		SMALLINT,
			@promo_percentage	DECIMAL(5,2),
			@drawdown_id		VARCHAR(20),
			@drawdown_level		VARCHAR(30),
			@expiry_days		INT,
			@start_date			DATETIME,
			@expiry_date		DATETIME

	-- Get order details
	SELECT
		@customer_code = a.cust_code,
		@order_amount = ISNULL(a.gross_sales,0) - ISNULL(a.total_discount,0),
		@promo_id = b.promo_id,
		@promo_level = b.promo_level
	FROM
		dbo.orders a (NOLOCK)
	INNER JOIN
		dbo.cvo_orders_all b (NOLOCK)
	ON
		a.order_no = b.order_no
		AND a.ext = b.ext
	WHERE
		a.order_no = @order_no
		AND a.ext = @ext

	-- If no promo then exit
	IF ISNULL(@promo_id,'') = ''
	BEGIN
		RETURN
	END

	-- Exit if this isn't a debit promo
	IF NOT EXISTS (SELECT 1 FROM dbo.cvo_promotions (NOLOCK) WHERE promo_id = @promo_id AND promo_level = @promo_level AND ISNULL(debit_promo,0) = 1)
	BEGIN
		RETURN
	END


	-- Get promo details
	SELECT
		@fixed_credit = CASE ISNULL(debit_promo_amount,0) WHEN 0 THEN 0 ELSE 1 END,
		@credit = ISNULL(debit_promo_amount,0),
		@promo_percentage = ISNULL(debit_promo_percentage,0),
		@drawdown_id = drawdown_id,
		@drawdown_level = drawdown_level,
		@expiry_days = drawdown_expiry_days
	FROM
		dbo.cvo_promotions (NOLOCK)
	WHERE
		promo_id = @promo_id
		AND promo_level = @promo_level		
		AND ISNULL(debit_promo,0) = 1

	-- If no drawdown promo set the exit
	IF ISNULL(@drawdown_id,'') = '' OR ISNULL(@drawdown_level,'') = ''
	BEGIN
		RETURN
	END

	-- Get drawdown promo details
	SELECT
		@expiry_days = drawdown_expiry_days
	FROM
		dbo.cvo_promotions (NOLOCK)
	WHERE
		promo_id = @drawdown_id
		AND promo_level = @drawdown_level		
		AND ISNULL(drawdown_promo,0) = 1

	-- If no details returned then exit
	IF @@ROWCOUNT = 0
	BEGIN
		RETURN
	END

	-- If no expiry days exit
	IF ISNULL(@expiry_days,0) <=0
	BEGIN
		RETURN
	END

	-- Calculate credit to apply
	IF @fixed_credit = 0
	BEGIN
		SET @credit = ROUND(@order_amount * (@promo_percentage/100),2)
	END

	-- Exit if there isn't a credit to apply 
	IF ISNULL(@credit,0) <= 0 
	BEGIN
		RETURN
	END

	-- Check if customer is already enrolled in the drawdown promo
	IF EXISTS(SELECT 1 FROM dbo.CVO_debit_promo_customer_hdr (NOLOCK) WHERE customer_code = @customer_code AND drawdown_promo_id = @drawdown_id AND drawdown_promo_level = @drawdown_level)
	BEGIN
		-- If the promo is for a % amount then add it on the the existing amount
		IF @fixed_credit = 0
		BEGIN
			UPDATE
				CVO_debit_promo_customer_hdr
			SET
				amount = ISNULL(amount,0) + @credit,
				balance = ISNULL(balance,0) + @credit,
				available = ISNULL(available,0) + @credit
			WHERE 
				customer_code = @customer_code 
				AND drawdown_promo_id = @drawdown_id 
				AND drawdown_promo_level = @drawdown_level
		END
	END
	ELSE
	BEGIN
		-- Not enrolled, enrol customer
		SET @start_date = DATEADD(dd, 0, DATEDIFF(dd, 0, GETDATE()))
		SET @expiry_date = DATEADD(dd, @expiry_days, @start_date)

		-- Insert record
		INSERT INTO dbo.CVO_debit_promo_customer_hdr(
			customer_code,
			debit_promo_id,
			debit_promo_level,
			drawdown_promo_id,
			drawdown_promo_level,
			[start_date],
			[expiry_date],
			amount,
			balance,
			available,
			open_orders)
		SELECT
			@customer_code,
			@promo_id,
			@promo_level,
			@drawdown_id,
			@drawdown_level,
			@start_date,
			@expiry_date,
			@credit,
			@credit,
			@credit,
			0
	END	

	RETURN	
END
GO
GRANT EXECUTE ON  [dbo].[CVO_debit_promo_enrollment_sp] TO [public]
GO
