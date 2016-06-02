SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- v1.0 CT 05/11/2013 - Updates order's promo credit based on shipped amounts
-- v1.1 CB 20/04/2016 - #1584 - Add discount amount
-- Called from cvo_get_pack_list_details_sp - call this SP to test code
-- EXEC cvo_pack_list_debit_promo_details_sp 1419125, 0

CREATE PROC [dbo].[cvo_pack_list_debit_promo_details_sp]	@order_no INT,
														@ext INT
AS
BEGIN
	SET NOCOUNT ON


	DECLARE @part_no VARCHAR(30)

	-- Create temp table
	CREATE TABLE #credit(
		part_no			VARCHAR(30),
		credit_amount	DECIMAL(20,8))

	-- Load credits for the order
	INSERT INTO #credit(
		part_no,
		credit_amount)
	SELECT 
		b.part_no,
		SUM(a.credit_amount)
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
	GROUP BY
		b.part_no

	-- Remove lines without credits
	DELETE FROM #credit WHERE credit_amount <= 0

	-- Apply credits to detail
	SET @part_no = ''
	WHILE 1=1
	BEGIN
		SELECT TOP 1
			@part_no = part_no
		FROM
			#detail
		WHERE
			part_no > @part_no
			AND is_credit = 0
		ORDER BY 
			part_no

		IF @@ROWCOUNT = 0
			BREAK

		-- Check if there is a credit for this part
		IF EXISTS (SELECT 1 FROM #credit WHERE part_no = @part_no)
		BEGIN
			INSERT INTO #detail(
				part_no,
				pack_qty,
				ordered,
				qty_short,
				list_price,
				gross_price,
				net_price,
				ext_net_price,
				discount_amount,
				discount_pct,
				note,
				is_credit)
			SELECT
				a.part_no,
				a.pack_qty,
				1,
				0,
				b.credit_amount * -1,
				b.credit_amount * -1,
				b.credit_amount * -1,
				b.credit_amount * -1,
				0,
				0,
				'',
				1
			FROM
				#detail a 
			INNER JOIN
				#credit b
			ON
				a.part_no = b.part_no
			WHERE
				a.part_no = @part_no
				AND a.is_credit = 0
		END
	END

	-- v1.1 Start
	INSERT INTO #detail(
		part_no,
		pack_qty,
		ordered,
		qty_short,
		list_price,
		gross_price,
		net_price,
		ext_net_price,
		discount_amount,
		discount_pct,
		note,
		is_credit)	
	SELECT	part_no, 1, 1, 0, price, price, price, price, 0, 0, '', 0
	FROM	ord_list (NOLOCK)
	WHERE	order_no = @order_no
	AND		order_ext = @ext
	AND		part_no = 'PROMOTION DISCOUNT'
	-- v1.1 End
END
GO
GRANT EXECUTE ON  [dbo].[cvo_pack_list_debit_promo_details_sp] TO [public]
GO
