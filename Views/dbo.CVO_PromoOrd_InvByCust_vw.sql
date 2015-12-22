SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW [dbo].[CVO_PromoOrd_InvByCust_vw]
AS

select type, promo_id,promo_level,t1.order_no, cust_code, t1.ship_to, t1.ship_to_name,t1.cust_po, t1.date_entered, t1.status, date_shipped, 
case total_invoice WHEN 0 THEN total_amt_order ELSE (total_invoice -( freight+t1.total_tax)) END as 'Net Sales',
Count(t3.part_no) as Qty
from orders_All t1
join cvo_orders_all t2 on t1.order_no=t2.order_no and t1.ext=t2.ext
join ord_list t3 on t1.order_no=t3.order_no and t1.ext=t3.order_ext
where promo_id is not null
and t1.ext='0'
and promo_id in ('aab','bep')
AND date_entered BETWEEN (GETDATE()-30) and GETDATE()
group by type, promo_id,promo_level,t1.order_no, cust_code, t1.ship_to, t1.ship_to_name,t1.cust_po, t1.date_entered, t1.status, date_shipped, 
total_invoice, total_amt_order,freight, t1.total_tax,gross_sales


GO
