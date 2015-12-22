SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- v1.0 CT 07/02/2014 - Issue #864 - Apply drawdown credit to backorder
-- EXEC CVO_apply_debit_promo_to_backorder_sp 1420069, 1, 'rcp','jmcdp',0
CREATE PROC [dbo].[CVO_apply_debit_promo_to_backorder_sp]	@order_no		INT,
														@ext			INT,
														@promo_id		VARCHAR(30),	
														@promo_level	VARCHAR(30),
														@orig_ext		INT
AS
BEGIN
	DECLARE @customer_code	VARCHAR(8),
			@hdr_rec_id			INT,
			@promo_available	DECIMAL(20,8),
			@line_no			INT,
			@line_value			DECIMAL(20,8),
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

	SET @order_note_start = 'Credit for $'
	SET @order_note_end = ' to be applied'
	SET @credit_note = ''

	-- Create temp tables for ord_list records
	CREATE TABLE #full_ord_list (
			part_no		VARCHAR(30),
			line_no		INT,
			brand		VARCHAR(30),
			category	VARCHAR(30),
			ordered		DECIMAL(20, 8),			
			gender		VARCHAR(15),							
			attribute	VARCHAR(10)								
		)

	CREATE TABLE #selected_ord_list (
			part_no			VARCHAR(30),
			line_no			INT,
			brand			VARCHAR(30),
			category		VARCHAR(30),
			ordered			DECIMAL(20, 8),		
			gender			VARCHAR(15),							
			attribute		VARCHAR(10)								
		)

	CREATE TABLE #processing_ord_list (
			line_no			INT,
			line_value		DECIMAL(20,8),
			credit_amount	DECIMAL(20,8))

	-- Get customer code from order
	SELECT
		@customer_code = cust_code
	FROM
		dbo.orders_all (NOLOCK)
	WHERE
		order_no = @order_no
		AND ext = @ext

	-- Get customer/promo details
	SELECT
		@hdr_rec_id = hdr_rec_id
	FROM
		dbo.CVO_debit_promo_customer_hdr (NOLOCK)
	WHERE
		customer_code = @customer_code
		AND drawdown_promo_id = @promo_id
		AND drawdown_promo_level = @promo_level

	IF ISNULL(@hdr_rec_id,0) = 0
	BEGIN
		RETURN
	END

	-- Load working ord_list table
	INSERT INTO	#full_ord_list(
		part_no,
		line_no,
		brand,
		category,
		ordered,
		gender,							
		attribute)
	SELECT
		a.part_no,
		a.line_no,
		i.category,
		i.type_code,
		a.ordered,					
		ISNULL(ia.field_2,''),							
		ISNULL(ia.field_32,'')	
	FROM
		dbo.ord_list (NOLOCK) a
	INNER JOIN 
		dbo.inv_master i (NOLOCK) 
	ON 
		a.part_no = i.part_no
	INNER JOIN 
		inv_master_add ia (NOLOCK) 
	ON 
		a.part_no = ia.part_no
	WHERE 
		a.order_no = @order_no
		AND a.order_ext = @ext

	-- Select order lines which were marked for credit on original order
	INSERT INTO	#selected_ord_list(
		part_no,
		line_no,
		brand,
		category,
		ordered,				
		gender,							
		attribute)
	SELECT
		a.part_no,
		a.line_no,
		a.brand,
		a.category,
		a.ordered,
		a.gender,							
		a.attribute	
	FROM
		#full_ord_list a (NOLOCK)
	INNER JOIN
		dbo.CVO_debit_promo_customer_det b (NOLOCK)
	ON
		a.line_no = b.line_no
	where 
		b.hdr_rec_id = @hdr_rec_id
		AND b.order_no = @order_no
		AND b.ext = @orig_ext
	
	-- Get a list of lines to be processed
	INSERT INTO #processing_ord_list(
		line_no,
		line_value,
		credit_amount)
	SELECT 
		a.line_no,
		CASE ISNULL(a.discount,0) WHEN 0 THEN ROUND(a.curr_price * a.ordered,2) ELSE ROUND((a.curr_price * a.ordered) * ((100 - a.discount)/100) ,2) END,
		0
	FROM
		dbo.ord_list a (NOLOCK)
	INNER JOIN
		#selected_ord_list b
	ON
		a.line_no = b.line_no
	WHERE
		a.order_no = @order_no
		AND a.order_ext = @ext

	-- Clear out zero value lines
	DELETE FROM #processing_ord_list WHERE ISNULL(line_value,0) <= 0

	-- Get available promo amount
	SELECT
		@promo_available = available
	FROM
		dbo.CVO_debit_promo_customer_hdr (NOLOCK)
	WHERE
		customer_code = @customer_code
		AND drawdown_promo_id = @promo_id
		AND drawdown_promo_level = @promo_level

	SET @line_no = 0

	-- Loop through lines and apply credit
	WHILE 1=1
	BEGIN
		-- Drop out if nothing left to apply
		IF ISNULL(@promo_available,0) <= 0
			BREAK

		-- Get next record
		SELECT TOP 1
			@line_no = line_no,
			@line_value = line_value
		FROM
			#processing_ord_list
		WHERE
			line_no > @line_no
		ORDER BY
			line_no	

		IF @@ROWCOUNT = 0
			BREAK

		IF @line_value < @promo_available
		BEGIN
			SET @credit_amount = @line_value
			SET @promo_available = @promo_available - @credit_amount
		END
		ELSE
		BEGIN
			SET @credit_amount = @promo_available
			SET @promo_available = 0
		END

		-- Update table
		UPDATE
			#processing_ord_list
		SET
			credit_amount = @credit_amount
		WHERE
			line_no = @line_no
	END
	
	-- Clear out lines with no credit
	DELETE FROM #processing_ord_list WHERE ISNULL(credit_amount,0) <= 0

	-- Write lines to CVO_debit_promo_customer_det
	INSERT INTO dbo.CVO_debit_promo_customer_det(
		hdr_rec_id,
		order_no,
		ext,
		line_no,
		credit_amount,
		posted)
	SELECT
		@hdr_rec_id,
		@order_no,
		@ext,
		line_no,
		credit_amount,
		0
	FROM
		#processing_ord_list

	-- Update header record
	SELECT @order_credit = SUM(credit_amount) FROM #processing_ord_list

	IF ISNULL(@order_credit,0) > 0 
	BEGIN

		UPDATE
			CVO_debit_promo_customer_hdr
		SET
			available = ISNULL(available,0) - @order_credit,
			open_orders = ISNULL(open_orders,0) + @order_credit
		WHERE 
			hdr_rec_id = @hdr_rec_id

		-- Build order note string
		SET @credit_note = @order_note_start + CAST(CAST(@order_credit AS MONEY) AS VARCHAR(10)) + @order_note_end

	END

	-- Add (or update) order note for credit amount
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
GRANT EXECUTE ON  [dbo].[CVO_apply_debit_promo_to_backorder_sp] TO [public]
GO
