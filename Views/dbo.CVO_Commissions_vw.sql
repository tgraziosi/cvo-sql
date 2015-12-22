SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

CREATE VIEW [dbo].[CVO_Commissions_vw]
AS
SELECT     
orders_invoice.doc_ctrl_num, 
CASE orders.type WHEN 'I' THEN 'Invoice' ELSE 'Return' END as doc_type,
shippers.date_shipped, 
shippers.order_no, 
shippers.order_ext, 
orders.date_entered,
orders.user_category as order_type,
IsNull(cvo1.promo_id,' ') as promo_id,
IsNull(cvo1.promo_level,' ') as promo_level,
Substring(orders.ship_to_region,1,2) as region,
orders.ship_to_region,
orders.salesperson,
arsalesp.date_of_hire,
IsNull(arsalesp.draw_amount,0) as draw_amount,
shippers.cust_code, 
arcust.customer_name,
orders.ship_to,
orders.ship_to_name, 
orders.sold_to as buying_group_no,
orders.sold_to_addr1 as buying_group_name,
shippers.part_no,
CASE orders.type WHEN 'I' THEN shippers.ordered ELSE shippers.cr_ordered * -1 END as ordered, 
CASE orders.type WHEN 'I' THEN shippers.shipped ELSE shippers.cr_shipped * -1 END as shipped, 
CASE orders.type WHEN 'I' THEN shippers.price ELSE shippers.price * -1 END as price,
CASE orders.type WHEN 'I' THEN shippers.shipped * shippers.price
				 ELSE (shippers.cr_shipped * shippers.price) * -1 END as invoice_net_amt,
IsNull(cvo1.commission_pct,0) as commission_pct,
CASE orders.type WHEN 'I' THEN (shippers.shipped * shippers.price) * (IsNull(cvo1.commission_pct,0) /100)
				 ELSE ((shippers.cr_shipped * shippers.price) * (IsNull(cvo1.commission_pct,0) / 100)) * -1 
				 END as commission_amount,
orders.routing as carrier,
ord_list.total_tax,
orders.tot_ord_freight as order_freight,
x_date_shipped = (datediff(day, '01/01/1900', shippers.date_shipped ) + 693596)
               + (datepart(hh,shippers.date_shipped)*.01 
               + datepart(mi,shippers.date_shipped)*.0001 
               + datepart(ss,shippers.date_shipped)*.000001),
x_date_entered = (datediff(day, '01/01/1900', orders.date_entered ) + 693596)
               + (datepart(hh,orders.date_entered)*.01 
               + datepart(mi,orders.date_entered)*.0001 
               + datepart(ss,orders.date_entered)*.000001)

FROM
	dbo.shippers
	LEFT OUTER JOIN dbo.cvo_orders_all cvo1 ON dbo.shippers.order_no = cvo1.order_no AND dbo.shippers.order_ext = cvo1.ext
	INNER JOIN arcust ON dbo.shippers.cust_code = arcust.customer_code
	INNER JOIN dbo.orders ON dbo.shippers.order_no = dbo.orders.order_no AND dbo.shippers.order_ext = dbo.orders.ext
	INNER JOIN dbo.ord_list ON dbo.shippers.part_no = dbo.ord_list.part_no AND dbo.shippers.order_no = dbo.ord_list.order_no AND 
                      dbo.shippers.order_ext = dbo.ord_list.order_ext AND dbo.shippers.line_no = ord_list.line_no
	INNER JOIN dbo.orders_invoice ON dbo.shippers.order_no = dbo.orders_invoice.order_no AND 
                      dbo.shippers.order_ext = dbo.orders_invoice.order_ext
	LEFT OUTER JOIN arsalesp ON orders.salesperson = arsalesp.salesperson_code
	


GO
GRANT REFERENCES ON  [dbo].[CVO_Commissions_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[CVO_Commissions_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[CVO_Commissions_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[CVO_Commissions_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[CVO_Commissions_vw] TO [public]
GO
