SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create PROCEDURE [dbo].[cvo_openorders_promodiscountexeptions_sp]

AS
BEGIN
 --declare @ToDate datetime
 --select  @ToDate = getdate()
 -- exec cvo_openordersonhold_sp '05/11/2016', 0

select oo.order_no ,
       oo.ext ,
       oo.cust_code ,
       oo.ship_to ,
       oo.ship_to_name ,
       oo.location ,
       oo.cust_po ,
       oo.routing ,
       oo.fob ,
       oo.attention ,
       oo.tax_id ,
       oo.terms ,
       oo.curr_key ,
       oo.salesperson ,
       oo.Territory ,
       oo.total_amt_order ,
       oo.total_discount ,
       oo.Net_Sale_Amount ,
       oo.total_tax ,
       oo.freight ,
       oo.qty_ordered ,
       oo.qty_shipped ,
       oo.total_invoice ,
       oo.invoice_no ,
       oo.doc_ctrl_num ,
       oo.date_invoice ,
       oo.date_entered ,
       oo.date_sch_ship ,
       oo.date_shipped ,
       oo.status ,
       oo.status_desc ,
       oo.who_entered ,
       oo.shipped_flag ,
       oo.hold_reason ,
       oo.orig_no ,
       oo.orig_ext ,
       oo.promo_id ,
       oo.promo_level ,
       oo.order_type ,
       oo.FramesOrdered ,
       oo.FramesShipped ,
       oo.back_ord_flag ,
       oo.Cust_type ,
       oo.HS_order_no ,
       oo.allocation_date ,
       oo.x_date_invoice ,
       oo.x_date_entered ,
       oo.x_date_sch_ship ,
       oo.x_date_shipped ,
       oo.source,
	   dbo.calculate_region_fn(oo.territory) as Region,
	   p.order_discount
from cvo_adord_vw oo (nolock)
inner join armaster ar (nolock) on oo.cust_code = ar.customer_code and oo.ship_to = ar.ship_To_code
INNER JOIN cvo_promotions p (NOLOCK) ON p.promo_id = oo.promo_id AND p.promo_level = oo.promo_level
WHERE 1=1
and oo.status < 'R'
AND ISNULL(p.order_discount,0) = 100
AND oo.Net_Sale_Amount <> 0

END


GO
GRANT EXECUTE ON  [dbo].[cvo_openorders_promodiscountexeptions_sp] TO [public]
GO
