SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- EXEC dbo.cvo_validate_POP_check_sp '035192','CB','20','BCZBANNER'

CREATE PROC [dbo].[cvo_validate_POP_check_sp]	@cust_code varchar(10),
											@promo_id varchar(20),
											@promo_level varchar(20),
											@part_no varchar(30)
AS
BEGIN
	-- DIRECTIVES
	SET NOCOUNT ON

	-- DECLARATIONS
	DECLARE	@POP_months			int,
			@POP_qty			int,
			@POP_sales			int,
			@line_no			int,
			@brand				varchar(30),
			@check_date			datetime,
			@total_count		int,
			@total_sales		int

	-- PROCESSING
	SELECT	@POP_months = POP_months,
			@POP_qty = POP_qty,
			@POP_Sales = POP_sales
	FROM	inv_master_add (NOLOCK)
	WHERE	part_no = @part_no

	IF (@POP_months = 0 OR @POP_qty = 0 OR @POP_sales = 0)
	BEGIN
		SELECT 1
		RETURN
	END

	SET @check_date = DATEADD(m,(@POP_months * -1), GETDATE())

	SELECT	@brand = category
	FROM	inv_master (NOLOCK)
	WHERE	part_no = @part_no

	SET @total_count = 0
	SET @total_sales = 0

	-- v1.1 Start
	IF OBJECT_ID('tempdb..#cvo_POP_check')IS NOT NULL 
	BEGIN
		SELECT	@total_sales = ISNULL(SUM(a.ordered),0)
		FROM	#cvo_POP_check a (NOLOCK)
		JOIN	inv_master c (NOLOCK)
		ON		a.part_no = c.part_no
		WHERE	a.date_entered >= @check_date
		AND		c.category = @brand
		AND		c.type_code IN ('FRAME','SUN')

		IF (@total_sales IS NULL)
			SET @total_sales = 0
	END
	-- v1.1 End

	SELECT	@total_sales = @total_sales + ISNULL(SUM(CASE WHEN a.type = 'I' THEN b.shipped ELSE (b.cr_shipped * -1) END),0) -- v1.1
	FROM	orders_all a (NOLOCK)
	JOIN	ord_list b (NOLOCK)
	ON		a.order_no = b.order_no
	AND		a.ext = b.order_ext
	JOIN	inv_master c (NOLOCK)
	ON		b.part_no = c.part_no
	WHERE	a.cust_code = @cust_code
	AND		a.date_entered >= @check_date
	AND		a.status = 'T'
	AND		c.category = @brand
	AND		c.type_code IN ('FRAME','SUN')


	IF (@total_sales < @POP_sales)
	BEGIN
		SELECT -1
		RETURN
	END

	-- v1.1 Start
	IF OBJECT_ID('tempdb..#cvo_POP_check')IS NOT NULL 
	BEGIN
		SELECT	@total_count = 1
	END
	-- v1.1 End

	SELECT	@total_count = @total_count + ISNULL(SUM(CASE WHEN a.type = 'I' THEN b.shipped ELSE (b.cr_shipped * -1) END),0) -- v1.1
	FROM	orders_all a (NOLOCK)
	JOIN	ord_list b (NOLOCK)
	ON		a.order_no = b.order_no
	AND		a.ext = b.order_ext
	WHERE	a.cust_code = @cust_code
	AND		a.date_entered >= @check_date
	AND		a.status = 'T'
	AND		b.part_no = @part_no 

	IF (@total_count > @POP_qty)
	BEGIN
		SELECT -2
		RETURN
	END

	SELECT 1
	RETURN

END
GO
GRANT EXECUTE ON  [dbo].[cvo_validate_POP_check_sp] TO [public]
GO
