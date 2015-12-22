SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[cvo_create_order_line_relationship_sp]	@order_no int,
														@order_ext int
AS
BEGIN
	
	-- Case relationship
	UPDATE	a
	SET		a.add_case = 'Y'
	FROM	cvo_ord_list a
	JOIN	cvo_ord_list b (NOLOCK)
	ON		a.order_no = b.order_no
	AND		a.order_ext = b.order_ext
	AND		a.line_no = b.from_line_no
	WHERE	b.from_line_no <> 0
	AND		b.is_case = 1
	AND		a.order_no = @order_no
	AND		a.order_ext = @order_ext

	UPDATE	b
	SET		b.from_line_no = 0
	FROM	cvo_ord_list a (NOLOCK)
	JOIN	cvo_ord_list b 
	ON		a.order_no = b.order_no
	AND		a.order_ext = b.order_ext
	AND		a.line_no = b.from_line_no
	WHERE	b.from_line_no <> 0
	AND		b.is_case = 1
	AND		a.order_no = @order_no
	AND		a.order_ext = @order_ext

	UPDATE	a
	SET		add_case_flag = b.add_case
	FROM	cvo_soft_alloc_det a
	JOIN	cvo_ord_list b (NOLOCK)
	ON		a.order_no = b.order_no
	AND		a.order_ext = b.order_ext
	AND		a.line_no = b.line_no
	WHERE	a.order_no = @order_no
	AND		a.order_ext = @order_ext
	AND		a.add_case_flag <> b.add_case

	-- Pattern Relationship
	UPDATE	a
	SET		a.add_pattern = 'Y'
	FROM	cvo_ord_list a
	JOIN	cvo_ord_list b (NOLOCK)
	ON		a.order_no = b.order_no
	AND		a.order_ext = b.order_ext
	AND		a.line_no = b.from_line_no
	WHERE	b.from_line_no <> 0
	AND		b.is_pattern = 1
	AND		a.order_no = @order_no
	AND		a.order_ext = @order_ext

	UPDATE	b
	SET		b.from_line_no = 0
	FROM	cvo_ord_list a (NOLOCK)
	JOIN	cvo_ord_list b 
	ON		a.order_no = b.order_no
	AND		a.order_ext = b.order_ext
	AND		a.line_no = b.from_line_no
	WHERE	b.from_line_no <> 0
	AND		b.is_pattern = 1
	AND		a.order_no = @order_no
	AND		a.order_ext = @order_ext

	-- Polarized
	UPDATE	a
	SET		a.add_polarized = 'Y'
	FROM	cvo_ord_list a
	JOIN	cvo_ord_list b (NOLOCK)
	ON		a.order_no = b.order_no
	AND		a.order_ext = b.order_ext
	AND		a.line_no = b.from_line_no
	WHERE	b.from_line_no <> 0
	AND		b.is_polarized = 1
	AND		a.order_no = @order_no
	AND		a.order_ext = @order_ext

	UPDATE	b
	SET		b.from_line_no = 0
	FROM	cvo_ord_list a (NOLOCK)
	JOIN	cvo_ord_list b 
	ON		a.order_no = b.order_no
	AND		a.order_ext = b.order_ext
	AND		a.line_no = b.from_line_no
	WHERE	b.from_line_no <> 0
	AND		b.is_polarized = 1
	AND		a.order_no = @order_no
	AND		a.order_ext = @order_ext


END
GO
GRANT EXECUTE ON  [dbo].[cvo_create_order_line_relationship_sp] TO [public]
GO
