SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[cvo_bg_inv_store_doc_sp] @ord_no INT, @ord_ext int
AS
BEGIN
	-- DIRECTIVES
	SET NOCOUNT ON

	-- DECLARATIONS	
	DECLARE	@row_id			int,
			@order_no		int,
			@order_ext		int,
			@cust_code		varchar(10),
			@line_no		int,
			@qty			int,
			@gross_price	decimal(20,8),
			@discount_price decimal(20,8),
			@discount_perc	decimal(20,8),
			@net_price		decimal(20,8),												
			@ext_net_price	decimal(20,8)

	CREATE TABLE #bg_orders (
		row_id		int,
		order_no	int,
		order_ext	int,
		cust_code	varchar(10),
		line_no		int,
		qty			decimal(20,8))

	INSERT	#bg_orders
	SELECT	a.row_id, a.order_no, a.order_ext, b.cust_code, a.line_no, CASE WHEN b.type = 'I' THEN a.shipped ELSE a.cr_shipped END -- v1.1
	FROM	ord_list a (NOLOCK)
	JOIN	orders_all b (NOLOCK)
	ON		a.order_no = b.order_no
	AND		a.order_ext = b.ext
	JOIN	cvo_orders_all c (NOLOCK)
	ON		a.order_no = c.order_no
	AND		a.order_ext = c.ext
	WHERE	ISNULL(c.buying_group,'') > ''
	AND		a.order_no = @ord_no AND a.order_ext = @ord_ext
	ORDER BY row_id ASC

	CREATE INDEX #bg_orders_ind0 ON #bg_orders(row_id)

	DELETE FROM cvo_bg_inv_store WHERE order_no = @ord_no AND ext = @ord_ext

	SET @row_id = 0

	WHILE (1 = 1)
	BEGIN

		SELECT	TOP 1 @row_id = row_id,
				@order_no = order_no,
				@order_ext = order_ext,
				@cust_code = cust_code,
				@line_no = line_no,
				@qty = qty
		FROM	#bg_orders
		WHERE	row_id > @row_id
		ORDER BY row_id ASC

		IF (@@ROWCOUNT = 0)
			BREAK

		EXEC dbo.cvo_get_bglog_line_prices_sp	@order_no, @order_ext, @line_no, @cust_code, @qty, @gross_price OUTPUT, @discount_price OUTPUT,
												@net_price OUTPUT, @ext_net_price OUTPUT

		INSERT	dbo.cvo_bg_inv_store (order_no, ext, order_ext, inv_no, doc_ctrl_num, line_no, gross_price, discount_price, discount_perc,
					net_price, qty, ext_price)
		SELECT	a.order_no, a.ext, CAST(a.order_no as varchar(20)) + '-' + CAST(a.ext as varchar(10)), a.invoice_no, b.doc_ctrl_num, 
				@line_no, @gross_price, @discount_price, 0, @net_price, @qty, @ext_net_price
		FROM	orders_all a (NOLOCK)
		JOIN	orders_invoice b (NOLOCK)
		ON		a.order_no  = b.order_no
		AND		a.ext = b.order_ext
		WHERE	a.order_no = @order_no
		AND		a.ext = @order_ext

	END

	DROP TABLE #bg_orders

END

GO
GRANT EXECUTE ON  [dbo].[cvo_bg_inv_store_doc_sp] TO [public]
GO
