SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


-- SELECT dbo.f_cvo_get_soft_alloc_stock (0, '001', 'bcgcolink5316')

CREATE FUNCTION [dbo].[f_cvo_get_soft_alloc_stock] (@soft_alloc_no INT,
												@location varchar(10),
												@part_no VARCHAR (30))
												
RETURNS DECIMAL(20,8)

--ALTER PROC [dbo].[cvo_get_available_stock_sp]	@soft_alloc_no	int,
--											@location		varchar(10),
--											@part_no		varchar(30)
AS
BEGIN

	-- Declarations
	DECLARE	@sa_stock		decimal(20,8),
			@alloc_stock	decimal(20,8)
	
	-- How much stock is commited to soft allocations compared to hard allocation for this order
/*  v1.2
	SELECT	@sa_stock = ISNULL(SUM(CASE WHEN a.deleted = 1 THEN (a.quantity * -1) ELSE a.quantity END),0)
	FROM	dbo.cvo_soft_alloc_det a (NOLOCK)
--	WHERE	a.status IN (0, 1, -3)
	WHERE	a.status IN (0, 1)
	AND		a.soft_alloc_no = @soft_alloc_no
	AND		a.location = @location
	AND		a.part_no = @part_no
*/
	-- v1.2
	SELECT	@sa_stock = SUM(ISNULL((CASE WHEN a.deleted = 1 THEN (a.quantity * -1) ELSE a.quantity END),0) - CASE WHEN a.change >= 1 THEN ISNULL((b.qty),0) ELSE 0 END) -- v1.4
			-- v1.4ISNULL(SUM(CASE WHEN a.deleted = 1 THEN (a.quantity * -1) ELSE a.quantity END),0) - ISNULL(SUM(b.qty),0)
	FROM	dbo.cvo_soft_alloc_det a (NOLOCK)
	-- START v1.3
	--LEFT JOIN tdc_soft_alloc_tbl b (NOLOCK)
	LEFT JOIN (SELECT order_no, order_ext, line_no, part_no, SUM(qty) qty FROM dbo.tdc_soft_alloc_tbl (NOLOCK) WHERE order_type = 'S' GROUP BY order_no, order_ext, line_no, part_no) b
	ON	a.order_no = b.order_no
	AND	a.order_ext = b.order_ext
	AND	a.part_no = b.part_no
	AND a.line_no = b.line_no
	-- END v1.3
	WHERE	a.status IN (0, 1)
	AND		a.soft_alloc_no = @soft_alloc_no
	AND		a.location = @location
	AND		a.part_no = @part_no
	
	-- How much stock is commited to soft allocations compared to hard allocation for other orders
/*	v1.2
	SELECT	@alloc_stock = ISNULL(SUM(CASE WHEN a.deleted = 1 THEN (a.quantity * -1) ELSE a.quantity END),0)
	FROM	dbo.cvo_soft_alloc_det a (NOLOCK)
	WHERE	a.status IN (0, 1, -1)
	AND		a.soft_alloc_no <> @soft_alloc_no
	AND		a.location = @location
	AND		a.part_no = @part_no
*/
	-- v1.2
	SELECT	@alloc_stock = SUM(ISNULL((CASE WHEN a.deleted = 1 THEN (a.quantity * -1) ELSE a.quantity END),0) - CASE WHEN a.change >= 1 THEN ISNULL((b.qty),0) ELSE 0 END) -- v1.4
							-- v1.4 ISNULL(SUM(CASE WHEN a.deleted = 1 THEN (a.quantity * -1) ELSE a.quantity END),0))-- - ISNULL(SUM(b.qty),0)
	FROM	dbo.cvo_soft_alloc_det a (NOLOCK)
	-- START v1.3
	--LEFT JOIN tdc_soft_alloc_tbl b (NOLOCK)
	LEFT JOIN (SELECT order_no, order_ext, line_no, part_no, SUM(qty) qty FROM dbo.tdc_soft_alloc_tbl (NOLOCK) WHERE order_type = 'S' GROUP BY order_no, order_ext, line_no, part_no) b
	ON	a.order_no = b.order_no
	AND	a.order_ext = b.order_ext
	AND	a.part_no = b.part_no
	AND a.line_no = b.line_no
	-- END v1.3
	WHERE	a.status IN (0, 1, -1)
	AND		a.soft_alloc_no <> @soft_alloc_no
	AND		a.location = @location
	AND		a.part_no = @part_no

--	SELECT '@sa_stock',@sa_stock
--	SELECT '@alloc_stock',@alloc_stock

	-- Return the quantity
	Return ISNULL(@sa_stock,0) + ISNULL(@alloc_stock,0)
END


GO
GRANT REFERENCES ON  [dbo].[f_cvo_get_soft_alloc_stock] TO [public]
GO
GRANT EXECUTE ON  [dbo].[f_cvo_get_soft_alloc_stock] TO [public]
GO
