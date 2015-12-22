SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



/* tag 11/30/2011 - New view for Customer Order Status Query*/
/* tag 2/20/2012 - Add Global ship to information */
-- tag - 071712 -  repurpose cvo_order_status_vw as cvo_daily_order_log_detail for SSRS portal
-- tag - 08/13/2012 - add invoice number and remove where clause so this view can be used for invoices too.
-- select * from cvo_daily_order_log_detail_vw where date_entered between '04/15/2012' and'04/16/2012'
-- 092412 - remove part of where clause referring to the order type
CREATE VIEW [dbo].[cvo_Daily_Order_Log_detail_vw]
AS
select 
-- top 100
o.ship_to_region as territory,
o.salesperson,
o.cust_code,
(select a.customer_name from arcust a (nolock) 
	where a.customer_code = o.cust_code and a.address_type = 0)
	as customer_name,
o.ship_to,
ship_to_name = ISNULL(
	case o.ship_to
	when '' then ''
	else (select a.ADDRESS_name from armaster a (nolock) 
		  where a.customer_code = o.cust_code and a.ship_to_code = o.ship_to)
	end,''),
o.ORDER_NO, 
o.ext, 
o.date_entered, 
o.date_shipped,
o.req_ship_date,
o.sch_ship_date,
o.invoice_date,
o.total_amt_order,
o.tot_ord_freight,
o.tot_ord_tax, 
(select sum(ordered) 
 from ord_list ol (nolock)
 inner join inv_master i (nolock) on ol.part_no = i.part_no
 where o.order_no = ol.order_no and o.ext = ol.order_ext
	and i.type_code in ('FRAME','SUN') ) as tot_ord_qty, 
(select sum(shipped) 
 from ord_list ol (nolock)
 inner join inv_master i (nolock) on ol.part_no = i.part_no
 where o.order_no = ol.order_no and o.ext = ol.order_ext
	and i.type_code in ('FRAME','SUN') ) as tot_shp_qty,  
 o.status,
 CASE o.status        
   WHEN 'A' THEN 'User Hold' -- per KB request 062413 
   WHEN 'B' THEN 'Credit Hold'        
   WHEN 'C' THEN 'Credit Hold'        
   WHEN 'E' THEN 'Other'        
   WHEN 'H' THEN 'User Hold' -- per KB request 062413        
   WHEN 'M' THEN 'Other'        
   WHEN 'N' THEN 'Received' 
   when 'P' then
	case 
	when isnull((select top (1) c.status from tdc_carton_tx c (nolock)  
		 where o.order_no = c.order_no and o.ext = c.order_ext
         and (c.void=0 or c.void is null)), '') IN ('F','S','X') then 'Shipped'       
	else 'Processing'
	end
   WHEN 'Q' THEN 'Processing'        
   WHEN 'R' THEN 'Shipped'        
   WHEN 'S' THEN 'Shipped'        
   WHEN 'T' THEN 'Shipped'        
   WHEN 'V' THEN 'Void'        
   WHEN 'X' THEN 'Void'        
   ELSE '' 
  END as status_desc,      
isnull(cvo.promo_id,'') as promo_id,
isnull(cvo.promo_level,'') as promo_level,
isnull(o.cust_po,'') as Cust_po,
-- o.ship_to_name,
o.ship_to_add_1,
o.ship_to_add_2,
o.ship_to_add_3,
o.ship_to_add_4,
o.ship_to_city,
o.ship_to_state,
o.ship_to_zip,
isnull(o.sold_to,'') as Global_ship_to,
isnull(o.sold_to_addr1,'') as Global_name,
--o.total_amt_order,

--
-- total_amt_order = 
--	case o.status
--		when 'T' then o.gross_sales
--		else  o.total_amt_order
--		end,
----o.freight,
-- freight=
--	case o.status
--		when 'T' then freight
--		else o.tot_ord_freight
--		end,        
----o.total_tax,
-- total_tax =
--	case o.status
--		when 'T' then total_tax
--		else o.tot_ord_tax
--		end,
--isnull(c.carrier_code,isnull(o.routing,'')) as carrier,
--isnull(c.cs_tracking_no,'') as tracking,
case when 
	isnull((select top (1) c.cs_tracking_no from tdc_carton_tx c (nolock)  
	where o.order_no = c.order_no and o.ext = c.order_ext
       and (c.void=0 or c.void is null)), '') = '' then
	isnull((select top (1) c.carrier_code from tdc_carton_tx c (nolock)
	where o.order_no = c.order_no and o.ext = c.order_ext
       and (c.void=0 or c.void is null)), '')
	else isnull((select top (1) c.cs_tracking_no from tdc_carton_tx c (nolock)  
	where o.order_no = c.order_no and o.ext = c.order_ext
       and (c.void=0 or c.void is null)), '') 
	end as tracking,
o.who_entered,
o.gross_sales as tot_inv_sales,
o.freight as tot_inv_freight,
o.total_tax as tot_inv_tax,
O.INVOICE_NO,
o.user_category as OrderType,
o.type +'-'+left(o.user_category,2) as Type,
o.void

from orders o (nolock) 
inner join cvo_orders_all cvo (nolock)
on o.order_no = cvo.order_no and o.ext = cvo.ext
--join ord_list od 
--on o.order_no = od.order_no and o.ext = od.order_ext
--left outer join tdc_carton_tx c on o.order_no = c.order_no and o.ext = c.order_ext
-- where clause for orders
where o.status <> 'V' and o.void = 'N' and o.type='I'
-- 092412 - don't need it anymore -- and left(o.user_category,2)='ST' 
-- and right(o.user_category,2) not in ('RB','TB','PM') 
--and o.who_entered <> 'BACKORDR'
-- where clause for invoices
-- where o.status = 'T'
--order by o.order_no, o.ext
--and o.status = 'p'


GO
GRANT SELECT ON  [dbo].[cvo_Daily_Order_Log_detail_vw] TO [public]
GO
