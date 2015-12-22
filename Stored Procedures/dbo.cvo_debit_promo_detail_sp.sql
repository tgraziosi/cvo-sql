SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- v1.0 CT 04/11/13 - Issue #864 - details for debit promo.
-- EXEC cvo_debit_promo_detail_sp 2

CREATE PROC [dbo].[cvo_debit_promo_detail_sp]	@hdr_rec_id INT
AS
BEGIN

	DECLARE @amount			DECIMAL(20,8),
			@balance		DECIMAL(20,8),
			@available		DECIMAL(20,8),
			@rec_id			INT,
			@order_no		VARCHAR(20),
			@credit_amount	DECIMAL(20,8),
			@no_details		SMALLINT

	SET @no_details = 0

	-- Create temp tables
	CREATE TABLE #details (
		rec_id INT IDENTITY(1,1),
		order_no INT,
		ext INT,
		credit_amount DECIMAL(20,8),
		shipped SMALLINT)

	CREATE TABLE #output (
		rec_id INT IDENTITY(1,1),
		data VARCHAR (1000))

	SELECT
		@amount = ISNULL(amount,0),
		@balance = ISNULL(balance,0),
		@available = ISNULL(available,0)
	FROM
		dbo.CVO_debit_promo_customer_hdr (NOLOCK)
	WHERE
		hdr_rec_id = @hdr_rec_id

	-- Load details into temp table group by order
	INSERT INTO #details(
		order_no,
		ext,
		credit_amount,
		shipped)
	SELECT
		order_no,
		ext,
		SUM(credit_amount),
		CASE ISNULL(trx_ctrl_num,'') WHEN '' THEN 0 ELSE 1 END
	FROM
		dbo.CVO_debit_promo_customer_det (NOLOCK)
	WHERE
		hdr_rec_id = @hdr_rec_id
	GROUP BY
		order_no,
		ext,
		trx_ctrl_num
	ORDER BY
		order_no,
		ext


	IF @@ROWCOUNT = 0
	BEGIN
		SET @no_details = 1
	END	

	
	INSERT INTO #output (data) SELECT 'Promotion Amount: $' + CAST(CAST(@amount AS MONEY) AS VARCHAR(15))
	INSERT INTO #output (data) SELECT ''
	
	IF @no_details = 0
	BEGIN
		INSERT INTO #output (data) SELECT 'Shipped Orders:'

		SET @rec_id = 0
		WHILE 1=1
		BEGIN
			SELECT TOP 1
				@rec_id = rec_id,
				@order_no = CAST(order_no AS VARCHAR(10)) + '-' + CAST (ext AS VARCHAR(3)),
				@credit_amount = credit_amount
			FROM
				#details
			WHERE
				rec_id > @rec_id
				AND shipped = 1
			ORDER BY
				rec_id
			
			IF @@ROWCOUNT = 0
				BREAK

			INSERT INTO #output (data) SELECT @order_no + ' $' + CAST(CAST(@credit_amount AS MONEY) AS VARCHAR(15))
		END

		INSERT INTO #output (data) SELECT ''
	END

	INSERT INTO #output (data) SELECT 'Promotion Balance: $' + CAST(CAST(@balance AS MONEY) AS VARCHAR(15))
	INSERT INTO #output (data) SELECT ''

	IF @no_details = 0
	BEGIN
		INSERT INTO #output (data) SELECT 'Open Orders:'
		SET @rec_id = 0
		WHILE 1=1
		BEGIN
			SELECT TOP 1
				@rec_id = rec_id,
				@order_no = CAST(order_no AS VARCHAR(10)) + '-' + CAST (ext AS VARCHAR(3)),
				@credit_amount = credit_amount
			FROM
				#details
			WHERE
				rec_id > @rec_id
				AND shipped = 0
			ORDER BY
				rec_id
			
			IF @@ROWCOUNT = 0
				BREAK

			INSERT INTO #output (data) SELECT @order_no + ' $' + CAST(CAST(@credit_amount AS MONEY) AS VARCHAR(15))
		END

		INSERT INTO #output (data) SELECT ''
	END

	INSERT INTO #output (data) SELECT 'Available Balance: $' + CAST(CAST(@available AS MONEY) AS VARCHAR(15))

	SELECT data FROM #output ORDER BY rec_id

	DROP TABLE #details
	DROP TABLE #output

END
GO
GRANT EXECUTE ON  [dbo].[cvo_debit_promo_detail_sp] TO [public]
GO
