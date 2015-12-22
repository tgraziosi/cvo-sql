SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[cvo_release_to_soft_alloc_sp] @customer_code	varchar(8),
											 @set_hold		int = 0
AS	
BEGIN
	-- DIRECTIVES
	SET NOCOUNT ON

	CREATE TABLE #no_soft_alloc_orders (
		order_no	int,
		order_ext	int)

	IF (@set_hold = 0)
	BEGIN

		INSERT	#no_soft_alloc_orders (order_no, order_ext)
		SELECT	a.order_no,
				a.ext
		FROM	orders_all a (NOLOCK)
		LEFT JOIN cvo_alloc_hold_values_tbl b (NOLOCK)
		ON		a.hold_reason = b.hold_code
		WHERE	a.cust_code = @customer_code
		AND		((b.hold_code IS NOT NULL
		AND		a.status = 'A')
		OR		a.status = 'N')
		-- v5.2 End

		UPDATE	a
		SET		status = 0
		FROM	dbo.cvo_soft_alloc_hdr a
		JOIN	cvo_orders_all b (NOLOCK)
		ON		a.order_no = b.order_no
		AND		a.order_ext = b.ext
		JOIN	#no_soft_alloc_orders d
		ON		a.order_no = d.order_no 
		AND		a.order_ext = d.order_ext
		WHERE	b.allocation_date <= getdate()
		AND		a.status = -3

		UPDATE	a
		SET		status = 0
		FROM	dbo.cvo_soft_alloc_det a
		JOIN	cvo_orders_all b (NOLOCK)
		ON		a.order_no = b.order_no
		AND		a.order_ext = b.ext
		JOIN	#no_soft_alloc_orders d 
		ON		a.order_no = d.order_no 
		AND		a.order_ext = d.order_ext 
		WHERE	b.allocation_date <= getdate()
		AND		a.status = -3
	END
	ELSE
	BEGIN
	
		INSERT	#no_soft_alloc_orders (order_no, order_ext)
		SELECT	a.order_no,
				a.ext
		FROM	orders_all a (NOLOCK)
		LEFT JOIN cvo_alloc_hold_values_tbl b (NOLOCK)
		ON		a.hold_reason = b.hold_code
		WHERE	a.cust_code = @customer_code
		AND		((b.hold_code IS NULL
		AND		a.status = 'A')
		OR		a.status = 'C')
		-- v5.2 End

		UPDATE	a
		SET		status = -3
		FROM	dbo.cvo_soft_alloc_hdr a
		JOIN	#no_soft_alloc_orders d
		ON		a.order_no = d.order_no 
		AND		a.order_ext = d.order_ext
		WHERE	a.status = 0

		UPDATE	a
		SET		status = -3
		FROM	dbo.cvo_soft_alloc_det a
		JOIN	#no_soft_alloc_orders d
		ON		a.order_no = d.order_no 
		AND		a.order_ext = d.order_ext
		WHERE	a.status = 0
	END

END
GO
GRANT EXECUTE ON  [dbo].[cvo_release_to_soft_alloc_sp] TO [public]
GO
