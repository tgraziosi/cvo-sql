SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[cvo_get_available_stock_sp]	@soft_alloc_no	int,
											@location		varchar(10),
											@part_no		varchar(30),
											@no_output		int = 0
AS
BEGIN
	-- Directives
	SET NOCOUNT ON

	-- Declarations
	DECLARE	@sa_stock		decimal(20,8),
			@alloc_stock	decimal(20,8)
	
	-- v1.6 Start
	IF (@soft_alloc_no = 0)
	BEGIN
		SELECT	@alloc_stock = SUM(ISNULL((CASE WHEN a.deleted = 1 THEN (a.quantity * -1) ELSE a.quantity END),0) - CASE WHEN a.change >= 1 THEN CASE WHEN a.deleted = 1 THEN (ISNULL((b.qty),0) * -1) ELSE ISNULL((b.qty),0) END ELSE 0 END) -- v1.4
		FROM	dbo.cvo_soft_alloc_det a (NOLOCK)
		LEFT JOIN (SELECT order_no, order_ext, line_no, part_no, SUM(qty) qty FROM dbo.tdc_soft_alloc_tbl (NOLOCK) WHERE order_type = 'S' GROUP BY order_no, order_ext, line_no, part_no) b
		ON	a.order_no = b.order_no
		AND	a.order_ext = b.order_ext
		AND	a.part_no = b.part_no
		AND a.line_no = b.line_no
		WHERE	a.status NOT IN (-2,-3) -- v1.5 IN (0, 1, -1)
		AND		a.location = @location
		AND		a.part_no = @part_no

	END
	ELSE
	BEGIN

		-- v1.2
		SELECT	@sa_stock = SUM(ISNULL((CASE WHEN a.deleted = 1 THEN (a.quantity * -1) ELSE a.quantity END),0) - CASE WHEN a.change >= 1 THEN CASE WHEN a.deleted = 1 THEN (ISNULL((b.qty),0) * -1) ELSE ISNULL((b.qty),0) END ELSE 0 END) -- v1.4
		FROM	dbo.cvo_soft_alloc_det a (NOLOCK)
		LEFT JOIN (SELECT order_no, order_ext, line_no, part_no, SUM(qty) qty FROM dbo.tdc_soft_alloc_tbl (NOLOCK) WHERE order_type = 'S' GROUP BY order_no, order_ext, line_no, part_no) b
		ON	a.order_no = b.order_no
		AND	a.order_ext = b.order_ext
		AND	a.part_no = b.part_no
		AND a.line_no = b.line_no

		WHERE	a.status IN (0, 1)
		AND		a.soft_alloc_no = @soft_alloc_no
		AND		a.location = @location
		AND		a.part_no = @part_no
		
		-- v1.2
		SELECT	@alloc_stock = SUM(ISNULL((CASE WHEN a.deleted = 1 THEN (a.quantity * -1) ELSE a.quantity END),0) - CASE WHEN a.change >= 1 THEN ISNULL((b.qty),0) ELSE 0 END) -- v1.4
		FROM	dbo.cvo_soft_alloc_det a (NOLOCK)
		LEFT JOIN (SELECT order_no, order_ext, line_no, part_no, SUM(qty) qty FROM dbo.tdc_soft_alloc_tbl (NOLOCK) WHERE order_type = 'S' GROUP BY order_no, order_ext, line_no, part_no) b
		ON	a.order_no = b.order_no
		AND	a.order_ext = b.order_ext
		AND	a.part_no = b.part_no
		AND a.line_no = b.line_no
		WHERE	a.status NOT IN (-2,-3) -- v1.5 IN (0, 1, -1)
		AND		a.soft_alloc_no < @soft_alloc_no
		AND		a.location = @location
		AND		a.part_no = @part_no
	END
	-- v1.6 End

	-- Return the quantity
	IF (@no_output = 1)
		RETURN ISNULL(@sa_stock,0) + ISNULL(@alloc_stock,0)
	ELSE
		SELECT ISNULL(@sa_stock,0) + ISNULL(@alloc_stock,0)
END
GO
GRANT EXECUTE ON  [dbo].[cvo_get_available_stock_sp] TO [public]
GO
