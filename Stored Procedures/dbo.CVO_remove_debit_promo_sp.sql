SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- v1.0 CT 08/08/2013 - Removes the drawdown promo from the order

CREATE PROC [dbo].[CVO_remove_debit_promo_sp]	@order_no		INT,
											@ext			INT
							
AS
BEGIN
	DECLARE @hdr_rec_id			INT,
			@credit_amount		DECIMAL(20,8),
			@order_note			VARCHAR(255),
			@credit_note		VARCHAR(255),
			@order_note_start	VARCHAR(20),
			@order_note_end		VARCHAR(20)


	-- Get drawdown details
	SELECT
		@hdr_rec_id = hdr_rec_id,
		@credit_amount = SUM(credit_amount)
	FROM
		dbo.CVO_debit_promo_customer_det (NOLOCK)
	WHERE
		order_no = @order_no 
		AND ext = @ext
		AND posted = 0
	GROUP BY
		hdr_rec_id

	IF ISNULL(@hdr_rec_id,0) = 0 OR ISNULL(@credit_amount,0) <=0
	BEGIN
		RETURN
	END

	-- Remove detail lines
	DELETE FROM 
		dbo.CVO_debit_promo_customer_det
	WHERE
		order_no = @order_no 
		AND ext = @ext
		AND hdr_rec_id = @hdr_rec_id

	-- Update header record
	UPDATE
		dbo.CVO_debit_promo_customer_hdr
	SET
		available = ISNULL(available,0) + @credit_amount,
		open_orders = ISNULL(open_orders,0) - @credit_amount
	WHERE
		hdr_rec_id = @hdr_rec_id

	-- Update order note
	SELECT
		@order_note = note
	FROM
		dbo.orders (NOLOCK)
	WHERE
		order_no = @order_no
		AND ext = @ext

	IF ISNULL(@order_note,'') <> ''
	BEGIN
		SET @order_note_start = 'Credit for '
		SET @order_note_end = ' to be applied'
		SET @credit_note = ''

		SET @credit_note = @order_note_start +  dbo.f_get_order_promo_debit_amount (@order_no,@ext) + @order_note_end
		SET @order_note = REPLACE(@order_note,@credit_note,'')

		UPDATE
			dbo.orders
		SET
			note = @order_note
		WHERE
			order_no = @order_no
			AND ext = @ext
	END

END
GO
GRANT EXECUTE ON  [dbo].[CVO_remove_debit_promo_sp] TO [public]
GO
