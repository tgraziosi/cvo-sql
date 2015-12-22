SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- v1.0 CT 05/11/2013 - Updates order's promo credit based on shipped amounts

CREATE PROC [dbo].[CVO_debit_promo_update_details_sp]	@order_no INT,
													@ext INT
AS
BEGIN
	SET NOCOUNT ON

	DECLARE @det_rec_id			INT,
			@hdr_rec_id			INT,
			@change				DECIMAL(20,8),
			@promo_available	DECIMAL(20,8),
			@credit_amount		DECIMAL(20,8),
			@order_note			VARCHAR(255),
			@credit_note		VARCHAR(255),
			@current_credit		VARCHAR(255),
			@order_note_start	VARCHAR(20),
			@order_note_end		VARCHAR(20)

	-- Check if the order has drawdown credit applied
	IF NOT EXISTS (SELECT 1 FROM dbo.CVO_debit_promo_customer_det (NOLOCK) WHERE order_no = @order_no AND ext = @ext AND posted = 0)
	BEGIN
		RETURN
	END

	-- Calculate existing order note 
	SET @order_note_start = 'Credit for '
	SET @order_note_end = ' to be applied'
	SET @current_credit = ''

	SET @current_credit = @order_note_start +  dbo.f_get_order_promo_debit_amount (@order_no,@ext) + @order_note_end

		
	-- Create temporary table
	CREATE TABLE #details (
		det_rec_id INT,
		hdr_rec_id INT,
		line_no INT,
		current_credit DECIMAL(20,8),
		line_value DECIMAL(20,8),
		change DECIMAL(20,8))

	-- Load table
	INSERT INTO #details(
		det_rec_id,
		hdr_rec_id,
		line_no,
		current_credit,
		line_value,
		change)
	SELECT
		a.det_rec_id,
		a.hdr_rec_id,
		a.line_no,
		a.credit_amount,
		CASE ISNULL(b.discount,0) WHEN 0 THEN ROUND(b.curr_price * b.shipped,2) ELSE ROUND((b.curr_price * b.shipped) * ((100 - b.discount)/100) ,2) END,
		0
	FROM
		dbo.CVO_debit_promo_customer_det a (NOLOCK)
	INNER JOIN
		dbo.ord_list b (NOLOCK)
	ON
		a.order_no = b.order_no
		AND a.ext = b.order_ext
		AND a.line_no = b.line_no
	WHERE
		a.order_no = @order_no
		AND a.ext = @ext
		AND a.posted = 0
	ORDER BY
		det_rec_id

	-- Calculate difference in credit
	UPDATE
		#details
	SET
		change = line_value - current_credit

	-- Remove any lines where there's no change
	DELETE FROM
		#details
	WHERE
		change = 0

	-- If there are no lines changed then exit
	IF NOT EXISTS (SELECT 1 FROM #details)
	BEGIN
		RETURN
	END

	-- Loop through lines where line value is less than credit
	SET @det_rec_id = 0
	WHILE 1=1
	BEGIN
		SELECT TOP 1
			@det_rec_id = det_rec_id,
			@hdr_rec_id = hdr_rec_id,
			@change = change * -1
		FROM
			#details
		WHERE
			det_rec_id > @det_rec_id
			AND	change < 0
		ORDER BY
			det_rec_id

		IF @@ROWCOUNT = 0
			BREAK

		-- Update promo detail line
		UPDATE
			dbo.CVO_debit_promo_customer_det
		SET
			credit_amount = credit_amount - @change
		WHERE
			det_rec_id = @det_rec_id

		-- Update promo header record
		UPDATE
			dbo.CVO_debit_promo_customer_hdr
		SET
			available = ISNULL(available,0) + @change,
			open_orders = ISNULL(open_orders,0) - @change
		WHERE
			hdr_rec_id = @hdr_rec_id	
	END	

	-- Loop through lines where line value is greater than credit, if possible apply any available credit to the lines
	SET @det_rec_id = 0
	WHILE 1=1
	BEGIN
		SELECT TOP 1
			@det_rec_id = det_rec_id,
			@hdr_rec_id = hdr_rec_id,
			@change = change 
		FROM
			#details
		WHERE
			det_rec_id > @det_rec_id
			AND	change > 0
		ORDER BY
			det_rec_id

		IF @@ROWCOUNT = 0
			BREAK

		-- Get amount of credit available on promo
		SELECT
			@promo_available = available
		FROM
			dbo.CVO_debit_promo_customer_hdr (NOLOCK)
		WHERE
			hdr_rec_id = @hdr_rec_id

		IF ISNULL(@promo_available,0) <= 0
			BREAK

		-- If there's not enough available to meet entire change, apply what is available
		IF @promo_available < @change
		BEGIN
			SET @change = @promo_available
		END

		-- Update promo detail line
		UPDATE
			dbo.CVO_debit_promo_customer_det
		SET
			credit_amount = credit_amount + @change
		WHERE
			det_rec_id = @det_rec_id

		-- Update promo header record
		UPDATE
			dbo.CVO_debit_promo_customer_hdr
		SET
			available = ISNULL(available,0) - @change,
			open_orders = ISNULL(open_orders,0) + @change
		WHERE
			hdr_rec_id = @hdr_rec_id	
	END

	-- Update order note
	SELECT
		@order_note = note
	FROM
		dbo.orders (NOLOCK)
	WHERE
		order_no = @order_no
		AND ext = @ext

	SET @credit_note = ''

	SET @credit_note = @order_note_start +  dbo.f_get_order_promo_debit_amount (@order_no,@ext) + @order_note_end

	IF ISNULL(@order_note,'') <> ''
	BEGIN
		SET @order_note = REPLACE(@order_note,@current_credit,@credit_note)
	END
	ELSE
	BEGIN
		SET @order_note = @credit_note
	END

	UPDATE
		dbo.orders
	SET
		note = @order_note
	WHERE
		order_no = @order_no
		AND ext = @ext
	
END
GO
GRANT EXECUTE ON  [dbo].[CVO_debit_promo_update_details_sp] TO [public]
GO
