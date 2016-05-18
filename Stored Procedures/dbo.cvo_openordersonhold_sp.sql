SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[cvo_openordersonhold_sp] @ToDate DATETIME, @FutShip INT = 0

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
	   CASE oo.hold_reason 
			when 'pd' then 'Past Due'
			when 'CL' then 'Credit Limit'
			else ccs.status_desc
       end as hold_descr
	, h.hold_reason adm_hold_reason
	, CASE WHEN oo.date_sch_ship > @ToDate AND ISNULL(h.hold_reason,'')='' THEN 'Future Ship' 
		ELSE ISNULL(ch.hold_dept,'Other') END AS hold_dept
	, ar.addr_sort1 as CustomerType
	, C.OpenAR
from cvo_adord_vw oo (nolock)
inner join armaster ar (nolock) on oo.cust_code = ar.customer_code and oo.ship_to = ar.ship_To_code
left outer join cc_status_codes ccs (nolock) on oo.hold_reason = ccs.status_code
left outer join adm_oehold h (nolock) on oo.hold_reason = h.hold_code
left outer join cvo_adm_oehold ch (nolock) on oo.hold_reason = ch.hold_code
left outer join 
(
 Select customer_code, sUM(amount) AS OpenAR
 FROM artrxage (nolock)
 group by customer_code
) as C on oo.cust_code = c.customer_code

WHERE ((oo.date_sch_ship < dateadd(d,1,@ToDate)
and oo.status in ('A','B','C') )
OR ( @FutShip = 1 AND oo.date_sch_ship > @ToDate AND oo.hold_reason = '' ) )
and who_entered <> 'BACKORDR'

END

GO
GRANT EXECUTE ON  [dbo].[cvo_openordersonhold_sp] TO [public]
GO
