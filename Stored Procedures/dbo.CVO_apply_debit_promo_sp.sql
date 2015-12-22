SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- v1.0 CT 08/08/2013 - Calculates the credit from a drawdown promo for the order
-- v1.1 CT 07/02/2014 - Issue #864 - If the promo has no order qualification lines, then all order lines qualify
-- v1.2 CB 19/06/2014 - Performance
-- EXEC CVO_apply_debit_promo_sp 1419921, 0, 'drawtest','001','010002',56
CREATE PROC [dbo].[CVO_apply_debit_promo_sp]	@order_no		INT,
											@ext			INT,
											@promo_id		VARCHAR(30),	
											@promo_level	VARCHAR(30),
											@customer_code	VARCHAR(8),
											@spid			INT
AS
BEGIN
	DECLARE @rec_id				INT,
			@brand_exclude		CHAR(1),						
			@category_exclude	CHAR(1),	
			@brand				VARCHAR(30),
			@category			VARCHAR(30),
			@gender_check		SMALLINT,
			@attribute			SMALLINT,
			@promo_line_no		INT,
			@promo_available	DECIMAL(20,8),
			@line_no			INT,
			@line_value			DECIMAL(20,8),
			@credit_amount		DECIMAL(20,8),
			@order_credit		DECIMAL(20,8),
			@hdr_rec_id			INT,
			@order_note			VARCHAR(255),
			@credit_note		VARCHAR(255),
			@curr_credit_note	VARCHAR(255),
			@order_note_start	VARCHAR(20),
			@order_note_end		VARCHAR(20),
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

	-- Remove the existing drawdown promo details from the order so we can reapply
	EXEC dbo.CVO_remove_debit_promo_sp @order_no, @ext

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
		
	-- START v1.1
	IF EXISTS (SELECT 1 FROM dbo.cvo_order_qualifications (NOLOCK) WHERE promo_id = @promo_id AND promo_level = @promo_level)
	BEGIN

		-- Loop through the order qualifications lines that have passed
		SET @rec_id = 0
		
		WHILE 1=1
		BEGIN
			SELECT TOP 1
				@rec_id = rec_id,
				@brand_exclude = brand_exclude,
				@category_exclude = category_exclude,
				@brand = brand,
				@category = category,
				@gender_check = gender_check,
				@attribute = attribute,
				@promo_line_no = line_no
			FROM
				dbo.CVO_drawdown_promo_qualified_lines (NOLOCK)
			WHERE
				rec_id > @rec_id
				AND SPID = @spid
				AND promo_id = @promo_id
				AND promo_level = @promo_level
			ORDER BY 
				rec_id

			IF @@ROWCOUNT = 0
				BREAK

			-- Load order lines which match
			INSERT INTO	#selected_ord_list(
				part_no,
				line_no,
				brand,
				category,
				ordered,				
				gender,							
				attribute)
			SELECT
				part_no,
				line_no,
				brand,
				category,
				ordered,
				gender,							
				attribute	
			FROM
				#full_ord_list (NOLOCK)
			WHERE
				((ISNULL(@brand_exclude,'N') = 'N' AND ISNULL(@brand,'') <> '' AND brand = @brand) 
						OR (ISNULL(@brand_exclude,'N') <> 'N' AND ISNULL(@brand,'') <> '' AND brand <> @brand) 
						OR (ISNULL(@brand,'') = ''))
				AND ((ISNULL(@category_exclude,'N') = 'N' AND ISNULL(@category,'') <> '' AND category = @category) 
						OR (ISNULL(@category_exclude,'N') <> 'N' AND ISNULL(@category,'') <> '' AND category <> @category) 
						OR (ISNULL(@category,'') = ''))
				AND ((ISNULL(@gender_check,0) = 0) OR (gender IN (SELECT gender FROM dbo.cvo_promotions_gender (NOLOCK) 
																				  WHERE promo_id = @promo_id AND promo_level = @promo_level and line_no = @promo_line_no AND line_type = 'O'))) 
				AND ((ISNULL(@attribute,0) = 0) OR (attribute IN (SELECT attribute FROM dbo.cvo_promotions_attribute (NOLOCK) 
																				  WHERE promo_id = @promo_id AND promo_level = @promo_level and line_no = @promo_line_no AND line_type = 'O')))
			
		END
	END
	ELSE
	BEGIN
		-- No order qualifcations, load all order lines
		INSERT INTO	#selected_ord_list(
			part_no,
			line_no,
			brand,
			category,
			ordered,				
			gender,							
			attribute)
		SELECT
			part_no,
			line_no,
			brand,
			category,
			ordered,
			gender,							
			attribute	
		FROM
			#full_ord_list (NOLOCK)
	END
	-- END v1.1
	
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
		(SELECT DISTINCT line_no FROM #selected_ord_list) b
	ON
		a.line_no = b.line_no
	WHERE
		a.order_no = @order_no
		AND a.order_ext = @ext

	-- Clear out zero value lines
	DELETE FROM #processing_ord_list WHERE ISNULL(line_value,0) <= 0

	-- Get amount of credit available on promo
	SELECT
		@hdr_rec_id = hdr_rec_id,
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
			dbo.orders  WITH (ROWLOCK)
		SET
			note = @order_note
		WHERE
			order_no = @order_no
			AND ext = @ext
	END
	

	-- Clear out table
	DELETE FROM dbo.CVO_drawdown_promo_qualified_lines WHERE SPID = @SPID

	-- Return amount of credit given to order
	SELECT ISNULL(@order_credit,0)
	

END
GO
GRANT EXECUTE ON  [dbo].[CVO_apply_debit_promo_sp] TO [public]
GO
