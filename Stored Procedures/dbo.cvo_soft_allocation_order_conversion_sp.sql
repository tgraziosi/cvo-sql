SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/*
BEGIN TRAN
SELECT * FROM ord_list WHERE order_no = 1399618
SELECT * FROM cvo_ord_list WHERE order_no = 1399618
SELECT * FROM cvo_soft_alloc_det WHERE order_no = 1399618
EXEC cvo_soft_allocation_order_conversion_sp 1399618, 0
SELECT * FROM ord_list WHERE order_no = 1399618
SELECT * FROM cvo_ord_list WHERE order_no = 1399618
SELECT * FROM cvo_soft_alloc_det WHERE order_no = 1399618
ROLLBACK TRAN
*/
CREATE PROC [dbo].[cvo_soft_allocation_order_conversion_sp]	@order_no int,
														@order_ext int
AS
BEGIN
	-- Directives
	SET NOCOUNT ON
	
	-- Working tables	
	CREATE TABLE #conv_ord_list (
		line_no		int,
		part_no		varchar(30),
		ordered		decimal(20,8))
	
	CREATE TABLE #conv_remove_ord_list (
		line_no		int,
		part_no		varchar(30))

	-- Get the cases and consolidate them
	INSERT	#conv_ord_list
	SELECT	MIN(a.line_no), a.part_no, SUM(a.ordered)
	FROM	ord_list a (NOLOCK)
	JOIN	cvo_ord_list b (NOLOCK)
	ON		a.order_no = b.order_no
	AND		a.order_ext = b.order_ext
	AND		a.line_no = b.line_no
	WHERE	a.order_no = @order_no
	AND		a.order_ext = @order_ext
	AND		b.is_case = 1
	GROUP BY a.part_no

	-- Get the lines to remove
	INSERT	#conv_remove_ord_list
	SELECT	a.line_no, a.part_no
	FROM	ord_list a (NOLOCK)
	JOIN	cvo_ord_list b (NOLOCK)
	ON		a.order_no = b.order_no
	AND		a.order_ext = b.order_ext
	AND		a.line_no = b.line_no
	LEFT JOIN #conv_ord_list c
	ON		a.line_no = c.line_no
	WHERE	a.order_no = @order_no
	AND		a.order_ext = @order_ext
	AND		b.is_case = 1
	AND		c.line_no IS NULL

	EXEC cvo_create_order_line_relationship_sp @order_no, @order_ext

	-- Remove the cvo_ord_list records
	DELETE	a
	FROM	cvo_ord_list a
	JOIN	#conv_remove_ord_list b
	ON		a.line_no = b.line_no
	WHERE	a.order_no = @order_no
	AND		a.order_ext = @order_ext

	-- Remove the ord_list records
	DELETE	a
	FROM	ord_list a
	JOIN	#conv_remove_ord_list b
	ON		a.line_no = b.line_no
	WHERE	a.order_no = @order_no
	AND		a.order_ext = @order_ext

	-- Update ord_list with the consolidated qty
	UPDATE	a
	SET		ordered = b.ordered
	FROM	ord_list a 
	JOIN	#conv_ord_list b
	ON		a.line_no = b.line_no
	WHERE	a.order_no = @order_no
	AND		a.order_ext = @order_ext
	
	-- Remove all soft allocation records
	DELETE	cvo_soft_alloc_hdr WHERE order_no = @order_no AND order_ext = @order_ext
	DELETE	cvo_soft_alloc_det WHERE order_no = @order_no AND order_ext = @order_ext

	EXEC cvo_create_soft_alloc_from_old_sp @order_no, @order_ext

	UPDATE	cvo_ord_list
	SET		from_line_no = 0
	WHERE	order_no = @order_no
	AND		order_ext = @order_ext


END
GO
GRANT EXECUTE ON  [dbo].[cvo_soft_allocation_order_conversion_sp] TO [public]
GO
