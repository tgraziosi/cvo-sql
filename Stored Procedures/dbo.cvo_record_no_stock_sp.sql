SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[cvo_record_no_stock_sp]	@order_no	int,
										@order_ext	int
AS
BEGIN

	-- Directives
	SET NOCOUNT ON


	-- Create Working Table
	CREATE TABLE #check_allocation (
		line_no			int,
		part_no			varchar(30),
		qty_required	decimal(20,8),
		qty_allocated	decimal(20,8),
		part_type		varchar(10)) -- v1.2

	CREATE TABLE #check_allocated_qty (
		line_no			int,
		part_no			varchar(30),
		qty_allocated	decimal(20,8))


	-- Insert into the working tables the line to check
	INSERT	#check_allocation (line_no, part_no, qty_required, qty_allocated, part_type) -- v1.2
	SELECT	a.line_no, a.part_no, a.ordered, 0, b.type_code -- v1.2
	FROM	ord_list a (NOLOCK)
	JOIN	inv_master b (NOLOCK) -- v1.1
	ON		a.part_no = b.part_no -- v1.1
	WHERE	a.order_no = @order_no
	AND		a.order_ext = @order_ext
	AND		b.type_code NOT IN ('PARTS','CASE','PATTERN') -- v1.1
	AND		b.status <> 'C' -- v1.3

	INSERT	#check_allocated_qty (line_no, part_no, qty_allocated)
	SELECT	line_no, part_no, SUM(qty)
	FROM	tdc_soft_alloc_tbl (NOLOCK)
	WHERE	order_no = @order_no
	AND		order_ext = @order_ext
	GROUP BY	line_no, part_no

	-- Update the qty allocated
	UPDATE	a
	SET		qty_allocated = b.qty_allocated
	FROM	#check_allocation a
	JOIN	#check_allocated_qty b
	ON		a.line_no = b.line_no
	AND		a.part_no = b.part_no

	-- Insert records where they are not allocated either partially or fully but have been marked as available in soft alloc
	INSERT	#no_stock_orders (order_no, order_ext, line_no, no_stock)
	SELECT	@order_no, @order_ext, line_no, 1
	FROM	#check_allocation
	WHERE	qty_allocated < qty_required
	AND		part_type IN ('FRAME', 'SUN') -- v1.2

	-- v1.2 Start
	IF (@@ROWCOUNT = 0)
	BEGIN
		INSERT	#no_stock_orders (order_no, order_ext, line_no, no_stock)
		SELECT	@order_no, @order_ext, line_no, 1
		FROM	#check_allocation
		WHERE	qty_allocated < qty_required
		AND		part_type NOT IN ('FRAME', 'SUN')
	END
	-- v1.2 End

	-- Clean up
	DROP TABLE #check_allocation
	DROP TABLE #check_allocated_qty

END
GO
GRANT EXECUTE ON  [dbo].[cvo_record_no_stock_sp] TO [public]
GO
