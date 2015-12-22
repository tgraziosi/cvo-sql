SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[tdc_3pl_have_assigned_parts_sp]	
	@cust_code	varchar(8),
	@ship_to	varchar(10),
	@contract_name	varchar(20)
AS
DECLARE	--input parameters
	@location 	varchar(10),
	@template_name	varchar(30),
	@formula 	varchar(8000),
	@line_no	int
--Do we have a part filter defined? If so, we don't care about anything else in this procedure, 
--if not, we need to make sure the user
IF NOT EXISTS(SELECT TOP 1 * FROM tdc_3pl_assigned_parts (NOLOCK) WHERE cust_code = @cust_code AND ship_to = @ship_to AND contract_name = @contract_name)
BEGIN
	IF OBJECT_ID('tempdb..#processing_selected_formula') IS NOT NULL DROP TABLE #processing_selected_formula
	CREATE TABLE #processing_selected_formula
	(
		selected      varchar(30)  NOT NULL, 
		[description] varchar(255)     NULL, 
		location      varchar(10)      NULL, 
                rowid         int IDENTITY
	)

	IF OBJECT_ID('tempdb..#invoice_items_temp') IS NOT NULL DROP TABLE #invoice_items_temp
	CREATE TABLE #invoice_items_temp
	(	
		location	varchar(10),
		template_name	varchar(30)
	)

	DECLARE item_cursor CURSOR FOR
		SELECT location, line_no, formula 
		  FROM tdc_3pl_invoice_items 
		WHERE cust_code = @cust_code 
		  AND ship_to = @ship_to 
		  AND contract_name = @contract_name
	OPEN item_cursor
	FETCH NEXT FROM item_cursor INTO @location, @line_no, @formula
	WHILE @@FETCH_STATUS = 0
	BEGIN
		EXEC tdc_3pl_parse_formula '3PLPROCESS', @formula, @location
		DELETE FROM #processing_selected_formula WHERE selected IN ('(', ')', '+', '-', '*', '/')
		TRUNCATE TABLE #invoice_items_temp
		INSERT INTO #invoice_items_temp (location, template_name)
			--Labor
			SELECT location, template_name 
			FROM tdc_3pl_templates 
			WHERE template_type = 'Labor'
			  AND location = @location
			UNION
			--Distinct Bins
			SELECT DISTINCT b.location, b.template_name
			FROM 	tdc_3pl_templates a (NOLOCK),
				tdc_3pl_assigned_bins b (NOLOCK)
			WHERE a.template_type = 'Inv Storage'
			  AND a.location = b.location
			  AND a.template_name = b.template_name
			  AND a.location = @location

		IF EXISTS(SELECT TOP 1 * 
			    FROM #processing_selected_formula a, #invoice_items_temp b 
			  WHERE a.selected = b.template_name AND a.location = b.location)
		BEGIN
			CLOSE item_cursor
			DEALLOCATE item_cursor
			RETURN -1
		END
		FETCH NEXT FROM item_cursor INTO @location, @line_no, @formula
	END
	CLOSE item_cursor
	DEALLOCATE item_cursor
END
RETURN 0
GO
GRANT EXECUTE ON  [dbo].[tdc_3pl_have_assigned_parts_sp] TO [public]
GO
