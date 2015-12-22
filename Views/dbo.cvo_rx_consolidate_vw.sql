SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW [dbo].[cvo_rx_consolidate_vw]
AS
	
	SELECT	a.order_no, a.ext, a.routing, a.user_category user_cat, ISNULL(a.sold_to,'') sold_to, ISNULL(b.third_party_code,'') tp_code, a.cust_code, a.ship_to
	FROM	dbo.orders_all a (NOLOCK)
	LEFT JOIN cvo_order_third_party_ship_to b (NOLOCK)
	ON 		a.order_no = b.order_no 
	AND		a.ext = b.order_ext 
	WHERE	a.type = 'I' 
	AND		UPPER(LEFT(a.user_category,2)) = 'RX'
	AND		UPPER(RIGHT(a.user_category,2)) <> 'RB'
	AND		a.status < 'P'
	AND		a.ext = 0
GO
GRANT REFERENCES ON  [dbo].[cvo_rx_consolidate_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[cvo_rx_consolidate_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[cvo_rx_consolidate_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[cvo_rx_consolidate_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[cvo_rx_consolidate_vw] TO [public]
GO
