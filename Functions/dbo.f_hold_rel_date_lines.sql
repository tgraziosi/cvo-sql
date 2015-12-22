SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE FUNCTION [dbo].[f_hold_rel_date_lines](@order_no int, @order_ext int)
RETURNS @rettab table (line_no int)
AS
BEGIN

	-- Get the line for any item that has yet to be released
	INSERT INTO @rettab
	SELECT	a.line_no
	FROM	cvo_ord_list a (NOLOCK)
	JOIN	ord_list b (NOLOCK)
	ON		a.order_no = b.order_no
	AND		a.order_ext = b.order_ext
	AND		a.line_no = b.line_no
	JOIN	inv_master_add c (NOLOCK)
	ON		b.part_no = c.part_no
	WHERE	c.field_26 > GETDATE()
	AND		a.order_no = @order_no
	AND		a.order_ext = @order_ext

	INSERT INTO @rettab
	SELECT	a.line_no
	FROM	cvo_ord_list_kit a (NOLOCK)
	JOIN	ord_list b (NOLOCK)
	ON		a.order_no = b.order_no
	AND		a.order_ext = b.order_ext
	AND		a.line_no = b.line_no
	JOIN	inv_master_add c (NOLOCK)
	ON		a.part_no = c.part_no
	WHERE	c.field_26 > GETDATE()
	AND		a.order_no = @order_no
	AND		a.order_ext = @order_ext


	-- Get the line for any item that is associated with an item yet to be released
	INSERT INTO @rettab
	SELECT	a.line_no
	FROM	cvo_ord_list a (NOLOCK)
	JOIN	ord_list b (NOLOCK)
	ON		a.order_no = b.order_no
	AND		a.order_ext = b.order_ext
	AND		a.line_no = b.line_no
	WHERE	a.order_no = @order_no
	AND		a.order_ext = @order_ext
	AND		a.from_line_no IN (SELECT line_no FROM @rettab)


	RETURN
END

GO
GRANT REFERENCES ON  [dbo].[f_hold_rel_date_lines] TO [public]
GO
GRANT SELECT ON  [dbo].[f_hold_rel_date_lines] TO [public]
GO
