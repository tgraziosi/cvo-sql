SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE VIEW [dbo].[CVO_orders_promo_exp_vw] AS

	SELECT	o.order_no, o.ext, o.cust_code, co.promo_id, co.promo_level, o.date_entered, o.total_amt_order 
	FROM	orders_all o 
		INNER JOIN CVO_orders_all co ON o.order_no = co.order_no AND o.ext = co.ext

GO
GRANT REFERENCES ON  [dbo].[CVO_orders_promo_exp_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[CVO_orders_promo_exp_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[CVO_orders_promo_exp_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[CVO_orders_promo_exp_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[CVO_orders_promo_exp_vw] TO [public]
GO
