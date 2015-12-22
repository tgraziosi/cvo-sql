SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- v1.0 CT 28/02/2013 - Applies the credit from a drawdown promo for the order
-- v1.1 CT 07/02/2014 - Issue #864 - Fix to logic for marking records as posted

CREATE PROC [dbo].[CVO_debit_promo_posted_order_sp]	@order_no		INT,
												@ext			INT
							
AS
BEGIN
	SET NOCOUNT ON

	DECLARE @customer_code	VARCHAR(8),
			@hdr_rec_id		INT,
			@credit_amount	DECIMAL(20,8),
			@error_no		SMALLINT, 
			@error_desc		VARCHAR(1000), 
			@trx_ctrl_num	VARCHAR(16)

	-- Check if order has any drawdown promo credits applied to it
	SELECT
		@hdr_rec_id = hdr_rec_id,
		@credit_amount = SUM(credit_amount)
	FROM
		dbo.CVO_debit_promo_customer_det
	WHERE
		order_no = @order_no 
		AND ext = @ext
	GROUP BY
		hdr_rec_id

	IF ISNULL(@hdr_rec_id,0) = 0 OR ISNULL(@credit_amount,0) <=0
	BEGIN
		RETURN
	END
	
	-- Create credit memo
	EXEC dbo.CVO_debit_promo_credit_memo_sp	@order_no, @ext, @credit_amount, @error_no OUTPUT, @error_desc OUTPUT, @trx_ctrl_num OUTPUT
	
	IF @error_no <> 0
	BEGIN
		-- Mark records as not having posted fully
		UPDATE
			CVO_debit_promo_customer_det
		SET
			posted = -1
		WHERE
			hdr_rec_id = @hdr_rec_id
			-- START v1.1
			AND order_no = @order_no 
			AND ext = @ext
			-- END v1.1

		RETURN
	END

	-- Update detail lines to show as posted
	UPDATE
		CVO_debit_promo_customer_det
	SET
		posted = 1,
		trx_ctrl_num = @trx_ctrl_num
	WHERE
		hdr_rec_id = @hdr_rec_id
		-- START v1.1
		AND order_no = @order_no 
		AND ext = @ext
		-- END v1.1


	-- Update header values
	UPDATE
		dbo.CVO_debit_promo_customer_hdr
	SET
		balance = ISNULL(balance,0) - @credit_amount,
		open_orders = ISNULL(open_orders,0) - @credit_amount
	WHERE 
		hdr_rec_id = @hdr_rec_id

	RETURN
END
GO
GRANT EXECUTE ON  [dbo].[CVO_debit_promo_posted_order_sp] TO [public]
GO
