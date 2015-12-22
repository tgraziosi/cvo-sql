SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- v1.0 CT 02/12/2013 - Checks if an RAF needs to be recreated for a credit return due to changes to the credit return lines
-- v1.1 CT 11/12/2014 - Issue #1505 - RAF needs to be recreated if email address has changed

-- Selects 0 for not required, 1 for required

CREATE PROC [dbo].[CVO_check_credit_return_raf_data_sp]	@order_no		INT,
													@ext			INT,
													@email_address	VARCHAR(255) -- v1.1  
AS
BEGIN
	-- Directives
	SET NOCOUNT ON

	DECLARE @cust_code		VARCHAR(10),
			@ship_to		VARCHAR(10),
			@customer_name	VARCHAR(40),
			@contact_name	VARCHAR(40),
			@contact_email	VARCHAR(255),
			@archive_count	INT,
			@new_count		INT,
			@line_no		INT

	-- If there aren't any entries in the RAF archive table then return false
	IF NOT EXISTS (SELECT 1 FROM dbo.cvo_raf_det_archive (NOLOCK) WHERE order_no = @order_no AND ext = @ext)
	BEGIN
		SELECT 0
		RETURN
	END

	-- If the credit return isn't new or hold then return false
	IF NOT EXISTS (SELECT 1 FROM dbo.orders (NOLOCK) WHERE order_no = @order_no AND ext = @ext AND [status] < 'R')
	BEGIN
		SELECT 0
		RETURN
	END

	-- START v1.1
	IF EXISTS (SELECT 1 FROM dbo.cvo_orders_all (NOLOCK) WHERE order_no = @order_no AND ext = @ext)
	BEGIN
		IF EXISTS (SELECT 1 FROM dbo.cvo_orders_all (NOLOCK) WHERE order_no = @order_no AND ext = @ext AND ISNULL(email_address,'') <> ISNULL(@email_address,''))
		BEGIN
			SELECT 1
			RETURN
		END
	END
	-- END v1.1

	-- Create temp table to hold new details
	CREATE TABLE #new_details(
		order_no		INT NOT NULL,
		ext				INT NOT NULL,
		line_no			INT NOT NULL,
		display_line	INT NOT NULL,
		part_no			VARCHAR(30) NOT NULL,
		[description]	VARCHAR(255) NOT NULL,
		quantity		DECIMAL(20,8) NOT NULL)

	-- Populate table
	INSERT INTO #new_details(
		order_no,
		ext,
		line_no,
		display_line,
		part_no,
		[description],
		quantity)
	SELECT
		order_no,
		order_ext,
		line_no,
		display_line,
		part_no,
		[description],
		cr_ordered
	FROM
		dbo.ord_list  (NOLOCK)
	WHERE
		order_no = @order_no
		AND order_ext = @ext
		AND part_type = 'P'

	-- Comparisons
	-- 1. Same number of lines
	SELECT @archive_count = COUNT(1) FROM dbo.cvo_raf_det_archive (NOLOCK) WHERE order_no = @order_no AND ext = @ext
	SELECT @new_count = COUNT(1) FROM #new_details 

	IF @new_count <> @archive_count
	BEGIN
		SELECT 1
		RETURN
	END
	
	-- 2. Line details
	SET @line_no = 0
	WHILE 1=1
	BEGIN
		SELECT TOP 1
			@line_no = line_no 
		FROM
			#new_details
		WHERE 
			line_no > @line_no
		ORDER BY
			line_no

		IF @@ROWCOUNT = 0
			BREAK

		-- Check details match
		IF NOT EXISTS(SELECT 1 FROM dbo.cvo_raf_det_archive a (NOLOCK) INNER JOIN #new_details b ON a.line_no = b.line_no AND a.display_line = b.display_line 
						AND a.part_no = b.part_no AND a.[description] = b.[description] AND a.quantity = b.quantity
						WHERE a.order_no = @order_no AND a.ext = @ext AND a.line_no = @line_no)
		BEGIN
			SELECT 1
			RETURN
		END

	END
	
	SELECT 0
	RETURN	
END
GO
GRANT EXECUTE ON  [dbo].[CVO_check_credit_return_raf_data_sp] TO [public]
GO
