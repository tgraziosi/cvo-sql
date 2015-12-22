SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
  
/*  
Copyright (c) 2012 Epicor Software (UK) Ltd  
Name:   cvo_debit_promo_apply_credit_for_splits_sp    
Project ID:  Issue 864  
Type:   Stored Procedure  
Description: Applies credit for split order  
Developer:  Chris Tyler  
  
History  
-------  

-- EXEC dbo.cvo_debit_promo_apply_credit_for_splits_sp 1419759,1
  
*/  
  
CREATE PROC [dbo].[cvo_debit_promo_apply_credit_for_splits_sp]	@order_no  INT,  
															@ext  INT
AS
BEGIN

	SET NOCOUNT ON
 
	DECLARE @promo_id			VARCHAR(20),  
			@promo_level		VARCHAR(30),
			@hdr_rec_id			INT,			
			@promo_amount		DECIMAL(20,8),
			@credit_note		VARCHAR(255),
			@credit_amount		DECIMAL(20,8),
			@order_note_start	VARCHAR(20),
			@order_note_end		VARCHAR(20),
			@order_credit		DECIMAL(20,8),
			@order_note			VARCHAR(255),
			@curr_credit_note	VARCHAR(255),
			@note_start			INT,
			@note_end			INT,
			@note_length		INT,
			@update_note		SMALLINT	

	-- Get promo
	SELECT
		@promo_id = promo_id,
		@promo_level = promo_level
	FROM
		dbo.cvo_orders_all (NOLOCK)
	WHERE
		order_no = @order_no   
		AND ext = @ext

	-- Check it's a drawdown promo
	IF NOT EXISTS (SELECT 1 FROM dbo.cvo_promotions (NOLOCK) WHERE promo_id = @promo_id AND promo_level = @promo_level AND ISNULL(drawdown_promo,0) = 1)
	BEGIN
		RETURN
	END

	-- Apply drawdown amount to promo
	SELECT
		@hdr_rec_id = hdr_rec_id,
		@promo_amount = SUM(credit_amount)
	FROM
		dbo.CVO_debit_promo_customer_det (NOLOCK)
	WHERE
		order_no = @order_no 
		AND ext = @ext
		AND posted = 0
	GROUP BY
		hdr_rec_id

	IF (ISNULL(@hdr_rec_id,0) <> 0) AND (ISNULL(@promo_amount,0) > 0)
	BEGIN
		-- Update header record
		UPDATE
			dbo.CVO_debit_promo_customer_hdr
		SET
			available = ISNULL(available,0) - @promo_amount,
			open_orders = ISNULL(open_orders,0) + @promo_amount
		WHERE
			hdr_rec_id = @hdr_rec_id

	END
	ELSE 
	BEGIN
		RETURN
	END

	-- Update note
	SET @order_note_start = 'Credit for $'
	SET @order_note_end = ' to be applied'
	SET @credit_note = ''

	-- Build order note string
	SET @credit_note = @order_note_start + CAST(CAST(@promo_amount AS MONEY) AS VARCHAR(10)) + @order_note_end

	-- Get note from order
	SELECT
		@order_note = note
	FROM
		dbo.orders (NOLOCK)
	WHERE
		order_no = @order_no
		AND ext = @ext

	IF ISNULL(@order_note,'') <> ''
	BEGIN

		-- Check if there is already a note for the credit added
		SET @update_note = 0
		SET @note_start = CHARINDEX(@order_note_start,@order_note,1)

		IF @note_start <> 0
		BEGIN
			SET @note_end = CHARINDEX(@order_note_end,@order_note,@note_start)

			IF @note_end <> 0
			BEGIN
				-- Credit note exists on order - check if it for a different amount
				SET @note_length = LEN(@order_note_start) + LEN(@order_note_end) + (@note_end - (@note_start + LEN(@order_note_start)))
				SET @curr_credit_note = SUBSTRING(@order_note,@note_start,@note_length)

				IF @curr_credit_note = @credit_note
				BEGIN
					-- Same amount - no change required
					SET @update_note = 0
				END
				ELSE
				BEGIN
					-- Different amount, replace it
					SET @update_note = 1
					SET @order_note = REPLACE(@order_note,@curr_credit_note,@credit_note)
				END
			END
			ELSE
			BEGIN
				-- Credit note doesn't exist, add it to note
				IF ISNULL(@credit_note,'') <> ''
				BEGIN
					SET @update_note = 1
					SET @order_note = @order_note + CHAR(13) + CHAR(10) + @credit_note
				END
			END
		END
		ELSE
		BEGIN
			-- Credit note doesn't exist, add it to note
			IF ISNULL(@credit_note,'') <> ''
			BEGIN
				SET @update_note = 1
				SET @order_note = @order_note + CHAR(13) + CHAR(10) + @credit_note
			END
		END
	END
	ELSE 
	BEGIN
		-- No note - create it
		IF ISNULL(@credit_note,'') <> ''
		BEGIN
			SET @update_note = 1
			SET @order_note = @credit_note
		END
	END
			
	IF @update_note = 1
	BEGIN
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
GRANT EXECUTE ON  [dbo].[cvo_debit_promo_apply_credit_for_splits_sp] TO [public]
GO
