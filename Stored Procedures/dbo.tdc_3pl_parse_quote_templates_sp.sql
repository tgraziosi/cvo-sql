SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[tdc_3pl_parse_quote_templates_sp]
	@quote_id	int
AS

TRUNCATE TABLE #quote_assigned_formulas
TRUNCATE TABLE #template_value_change
TRUNCATE TABLE #template_labor_change
TRUNCATE TABLE #quote_templates_needed_tbl
TRUNCATE TABLE #quote_templates_needed_labor_details_tbl

DECLARE
	@line_no		int,
	@formula 		varchar(8000), 
	@location		varchar(10),
	@template_name  	varchar(30),
	@template_type		varchar(15),
	@used_value		decimal(20,8),
	@value			decimal(20,8)

DECLARE
	@det_template_name	varchar(30), 
	@det_location		varchar(10), 
	@det_tran_id		int,
	@det_category		varchar(50),
	@det_fee		decimal(20,8),
	@check_fee		decimal(20,8)

DECLARE quote_item_cursor CURSOR FOR
	SELECT line_no, location, formula
	  FROM #quote_invoice_items
	ORDER BY line_no
-- --FOR DEBUGGING USE THIS STATEMENT
-- --BEGIN DEBUGGING......
-- -- 	SELECT line_no, location, formula
-- -- 	  FROM tdc_3pl_quote_invoice_items	--replace with temp table reference
-- -- 	WHERE quote_id = @quote_id
-- -- 	ORDER BY line_no
-- --END DEBUGGING......
OPEN quote_item_cursor
FETCH NEXT FROM quote_item_cursor INTO @line_no, @location, @formula
WHILE @@FETCH_STATUS = 0
BEGIN
	--Parse formula
	EXEC tdc_3pl_parse_formula '3PLQUOTE', @formula, @location

	INSERT INTO #quote_assigned_formulas (line_no, location, template_name)
	SELECT @line_no, location, selected
	  FROM #quote_selected_formula
	WHERE selected NOT IN ('+', '-', '*', '/', '(', ')')

	FETCH NEXT FROM quote_item_cursor INTO @line_no, @location, @formula
END
CLOSE quote_item_cursor
DEALLOCATE quote_item_cursor

--WE now have all templates being used in this Quote.
DECLARE assigned_template CURSOR FOR
	SELECT DISTINCT a.template_name, a.location, b.template_type, b.value
	  FROM #quote_assigned_formulas a,
		tdc_3pl_templates b (NOLOCK)
	WHERE a.template_name = b.template_name
	  AND a.location = b.location
OPEN assigned_template
FETCH NEXT FROM assigned_template INTO @template_name, @location, @template_type, @value
WHILE @@FETCH_STATUS = 0
BEGIN
	--INSERT "NEEDED" TEMPLATE HEADER
	INSERT INTO #quote_templates_needed_tbl
		SELECT @template_name, @location, @template_type, @value

	IF @template_type = 'Labor'
	BEGIN
		INSERT INTO #quote_templates_needed_labor_details_tbl
			SELECT template_name, location, tran_id, category, fee 
			  FROM tdc_3pl_labor_assigned_transactions 
			WHERE location = @location 
			  AND template_name = @template_name
	END

	FETCH NEXT FROM assigned_template INTO @template_name, @location, @template_type, @value
END
CLOSE assigned_template
DEALLOCATE assigned_template

--Let's see what templates are currently being stored for this quote, if any.
IF NOT EXISTS(SELECT * FROM #quote_templates_used_tbl (NOLOCK))
BEGIN
	--THIS IS THE 1ST TIME WE ARE ADDING TEMPLATES TO THIS QUOTE
	--ADD ALL OF THE TEMPLATES
	INSERT INTO #quote_templates_used_tbl
		SELECT * FROM #quote_templates_needed_tbl
	--ADD ALL OF THE LABOR DETAILS
	INSERT INTO #quote_templates_labor_details_tbl
		SELECT * FROM #quote_templates_needed_labor_details_tbl
END
ELSE
BEGIN
	--WE NOW NEED TO SEE IF WE NEED TO REMOVE OR ADD ANY TEMPLATES OR TRANSACTIONS
	--WE ALSO NEED TO SEE IF ANY "VALUES" HAVE CHANGED
	-- SELECT * FROM #quote_templates_needed_tbl
	-- SELECT * FROM #quote_templates_needed_labor_details_tbl
	DECLARE templates_needed CURSOR FOR
		SELECT template_name, location, template_type, ISNULL(value , 0)
		  FROM #quote_templates_needed_tbl
	OPEN templates_needed
	FETCH NEXT FROM templates_needed INTO @template_name, @location, @template_type, @value
	WHILE @@FETCH_STATUS = 0
	BEGIN
		--DOES THIS TEMPLATE EXIST IN THE #quote_templates_used_tbl TABLE?
		IF EXISTS(SELECT * FROM #quote_templates_used_tbl (NOLOCK) WHERE location = @location AND template_name = @template_name)
		BEGIN
			--CHECK TO SEE IF THE TEMPLATE VALUE(S) HAVE CHANGED
			--1ST CHECK VALUE
			SELECT @used_value = ISNULL(value, 0)
			  FROM #quote_templates_used_tbl (NOLOCK) 
			WHERE location = @location 
			  AND template_name = @template_name

			IF @value <> @used_value
			BEGIN
				INSERT INTO #template_value_change (location, template_name, tran_id, category, change_description, old_value, new_value)
					SELECT @location, @template_name, 1, 'TEMPLATE HEADER VALUE CHANGE', 'Value Changed', @used_value, @value
			END

			--NEXT CHECK INDIVIDUAL VALUES IF THE TEMPLATE IS A "LABOR" TEMPLATE
			IF @template_type = 'Labor'
			BEGIN
				--LOOP THROUGH TRANSACTIONS CURRENTLY DEFINED AND SEE...
				--IF THERE ARE ANY NEW TRANSACTIONS AND...
				--IF THE FEES HAVE CHANGED
				--...WE WILL LOG ANY DISCREPANCIES
					--ARE WE MISSING ANY NEW TRANSACTIONS?
					--'NEW TRANSACTION'
					--LABOR TRANSACTIONS CURRENTLY DEFINED FOR THE SPECIFIED TEMPLATE
				DECLARE detail_cursor CURSOR FOR
					SELECT template_name, location, tran_id, category, fee
					  FROM #quote_templates_needed_labor_details_tbl
					WHERE template_name = @template_name AND location = @location
				OPEN detail_cursor
				FETCH NEXT FROM detail_cursor INTO @det_template_name, @det_location, @det_tran_id, @det_category, @det_fee
				WHILE @@FETCH_STATUS = 0
				BEGIN
					IF EXISTS(SELECT * 
						    FROM #quote_templates_labor_details_tbl(NOLOCK) 
						  WHERE template_name = @det_template_name 
						    AND location = @det_location 
						    AND tran_id = @det_tran_id 
						    AND category = @det_category)
					BEGIN
						--Have fees changed?
						SELECT @check_fee = fee
						  FROM #quote_templates_labor_details_tbl(NOLOCK) 
						WHERE template_name = @det_template_name 
						  AND location = @det_location 
						  AND tran_id = @det_tran_id 
						  AND category = @det_category

						IF @det_fee <> @check_fee
						BEGIN
							INSERT INTO #template_labor_change (template_name, location, tran_id, category, change_description, old_fee, new_fee)
							SELECT @det_template_name, @det_location, @det_tran_id, @det_category, 'Fee Changed', @check_fee, @det_fee
						END
					END
					ELSE
					BEGIN
						--New Transaction
						INSERT INTO #template_labor_change (template_name, location, tran_id, category, change_description, old_fee, new_fee)
						SELECT @det_template_name, @det_location, @det_tran_id, @det_category, 'New Transaction', 0, @det_fee						
					END
					FETCH NEXT FROM detail_cursor INTO @det_template_name, @det_location, @det_tran_id, @det_category, @det_fee
				END	
				CLOSE detail_cursor
				DEALLOCATE detail_cursor

				--THEN
				--LOOP THROUGH TRANSACTIONS DEFINED FROM ORIGINAL QUOTE AND SEE...
				--IF THERE ARE ANY TRANSACTIONS THAT HAVE BEEN REMOVED
				--...WE WILL LOG ANY DISCREPANCIES
					--DO WE HAVE TRANSACTIONS THAT WERE ELIMINATED FROM THE TEMPLATE SINCE 
					--THE QUOTE WAS CREATED?
					--'DELETED'
				DECLARE detail_cursor CURSOR FOR
					SELECT template_name, location, tran_id, category, fee
					  FROM #quote_templates_labor_details_tbl
					WHERE template_name = @template_name AND location = @location
				OPEN detail_cursor
				FETCH NEXT FROM detail_cursor INTO @det_template_name, @det_location, @det_tran_id, @det_category, @det_fee
				WHILE @@FETCH_STATUS = 0
				BEGIN
					IF NOT EXISTS(SELECT * 
						    FROM #quote_templates_needed_labor_details_tbl(NOLOCK) 
						  WHERE template_name = @det_template_name 
						    AND location = @det_location 
						    AND tran_id = @det_tran_id 
						    AND category = @det_category)
					BEGIN
						--Removed Transaction
						INSERT INTO #template_labor_change (template_name, location, tran_id, category, change_description, old_fee, new_fee)
						SELECT @det_template_name, @det_location, @det_tran_id, @det_category, 'Removed Transaction', @det_fee, 0
					END
					FETCH NEXT FROM detail_cursor INTO @det_template_name, @det_location, @det_tran_id, @det_category, @det_fee
				END	
				CLOSE detail_cursor
				DEALLOCATE detail_cursor
			END
		END
		ELSE
		BEGIN	--INSERT ALL OF THE VALUES FOR THIS TEMPLATE
			--  IF IT IS "LABOR", WE ALSO NEED TO INSERT ALL OF THE RELATED TRANSACTIONS TOO
			--INSERT HEADER
			INSERT INTO #quote_templates_used_tbl
				SELECT @template_name, @location, @template_type, @value

			--IF "LABOR" TRANSACTION, INSERT ALL DETAILS
			IF @template_type = 'Labor'
			BEGIN
				INSERT INTO #quote_templates_labor_details_tbl
					SELECT template_name, location, tran_id, category, fee 
					  FROM #quote_templates_needed_labor_details_tbl 
					WHERE location = @location 
					  AND template_name = @template_name
			END
		END
		FETCH NEXT FROM templates_needed INTO @template_name, @location, @template_type, @value
	END
	CLOSE templates_needed
	DEALLOCATE templates_needed

	DECLARE templates_used CURSOR FOR
		SELECT template_name, location, template_type, ISNULL(value , 0)
		  FROM #quote_templates_used_tbl
	OPEN templates_used
	FETCH NEXT FROM templates_used INTO @template_name, @location, @template_type, @value
	WHILE @@FETCH_STATUS = 0
	BEGIN
		IF NOT EXISTS(SELECT * FROM #quote_templates_needed_tbl (NOLOCK) WHERE template_name = @template_name AND location = @location)
		BEGIN
			DELETE FROM #quote_templates_labor_details_tbl WHERE template_name = @template_name AND location = @location
			DELETE FROM #quote_templates_used_tbl WHERE template_name = @template_name AND location = @location
		END

		FETCH NEXT FROM templates_used INTO @template_name, @location, @template_type, @value
	END
	CLOSE templates_used
	DEALLOCATE templates_used
END

--LET'S UPDATE THE ASSIGNED LABOR VALUES
--ADD ONES THAT DO NOT CURRENTLY EXIST
INSERT INTO #quote_assigned_labor_values (category, tran_id, qty, [transaction], expert)
	SELECT DISTINCT a.category, a.tran_id, 0, b.[transaction], b.expert
	  FROM #quote_templates_labor_details_tbl a,
		tdc_3pl_labor_avail_transactions b
	WHERE a.category = b.category 
	  AND a.tran_id = b.tran_id
	  AND a.category + CAST(a.tran_id AS VARCHAR) NOT IN 
		(SELECT category + CAST(tran_id AS VARCHAR)
		  FROM #quote_assigned_labor_values)	

--REMOVE THOSE NOT BEING USED ANYMORE
DELETE FROM #quote_assigned_labor_values
	WHERE category + CAST(tran_id AS VARCHAR) NOT IN 
				(SELECT category + CAST(tran_id AS VARCHAR)
				  FROM #quote_templates_labor_details_tbl)	

IF NOT EXISTS(SELECT * FROM #quote_templates_labor_details_tbl (NOLOCK))
BEGIN
	TRUNCATE TABLE #quote_assigned_labor_values
END

--  	SELECT * FROM #quote_templates_used_tbl
-- 	SELECT * FROM #quote_templates_labor_details_tbl
-- 	SELECT DISTINCT category, tran_id FROM #quote_templates_labor_details_tbl ORDER BY category, tran_id

IF EXISTS(SELECT * FROM #template_value_change (NOLOCK)) OR EXISTS(SELECT * FROM #template_labor_change (NOLOCK))
	RETURN 1
ELSE
	RETURN 0
GO
GRANT EXECUTE ON  [dbo].[tdc_3pl_parse_quote_templates_sp] TO [public]
GO
