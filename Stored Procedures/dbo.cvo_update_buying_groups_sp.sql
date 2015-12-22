SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[cvo_update_buying_groups_sp]
AS
BEGIN
	-- Directives
	SET NOCOUNT ON

	CREATE TABLE #openorders (
		order_no			int,
		order_ext			int,
		cust_code			varchar(10),
		buying_group		varchar(10),
		new_buying_group	varchar(10))

	-- Get all the open orders
	INSERT	#openorders (order_no, order_ext, cust_code, buying_group, new_buying_group)
	SELECT	a.order_no,
			a.ext,
			a.cust_code,
			ISNULL(b.buying_group,''),
			''
	FROM	orders_all a (NOLOCK)
	JOIN	cvo_orders_all b (NOLOCK)
	ON		a.order_no = b.order_no
	AND		a.ext = b.ext
	WHERE	a.status < 'R'
	AND		a.type = 'I'
	AND		RIGHT(a.user_category,2) <> 'RB'

	-- Update with the current buying group
	UPDATE	a
	SET		new_buying_group = b.parent
	FROM	#openorders a
	JOIN	cvo_buying_groups_hist b (NOLOCK)
	ON		a.cust_code = b.child
	WHERE	b.start_date < CONVERT(varchar(10),GETDATE(),121)
	AND		b.end_date IS NULL

	-- Update the open orders with the correct buying group
	UPDATE	a
	SET		buying_group = b.new_buying_group
	FROM	cvo_orders_all a
	JOIN	#openorders b
	ON		a.order_no = b.order_no
	AND		a.ext = b.order_ext
	WHERE	a.buying_group <> b.new_buying_group

	SELECT * FROM #openorders where buying_group <> new_buying_group

END
GO
GRANT EXECUTE ON  [dbo].[cvo_update_buying_groups_sp] TO [public]
GO
