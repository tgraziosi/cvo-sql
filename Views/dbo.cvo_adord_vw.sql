SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO





-- select * --into #t 
	--From cvo_adord_vw where territory like '%20205%' and status = 'v'
	--tempdb..sp_help #t - char(1)
	--drop table #t
-- 2/5/2013 - tag - updated order totals on open orders to properly include discounts

CREATE view [dbo].[cvo_adord_vw] as
SELECT         
 convert(varchar(10),orders.order_no) order_no ,        
 convert(varchar(3),orders.ext) ext , 
 orders.cust_code,        
 orders.ship_to ,        
 orders.ship_to_name ,        
 orders.location ,         
 orders.cust_po ,        
 orders.routing,        
 orders.fob,        
 orders.attention,        
 orders.tax_id,        
 orders.terms,        
 orders.curr_key,        
 orders.salesperson,       -- T McGrady NOV.29.2010        
 orders.ship_to_region AS Territory,   -- T McGrady NOV.29.2010        
 total_amt_order = 
	case orders.status
		when 'T' then orders.gross_sales
		else  orders.total_amt_order
		end,
-- orders.total_amt_order ,        
 total_discount=
	case orders.status
		when 'T' then total_discount
		else orders.tot_ord_disc 
		end,
-- 020514 - per LM request 
 Net_Sale_Amount = 
    case orders.status
        when 'T' THEN ORDERS.GROSS_SALES - ORDERS.TOTAL_DISCOUNT
        else orders.total_amt_order - orders.tot_ord_disc
        end,
 total_tax =
	case orders.status
		when 'T' then total_tax
		else orders.tot_ord_tax
		end,        
 freight=
	case orders.status
		when 'T' then freight
		else orders.tot_ord_freight
		end,        
-- tag - 5/21/2012 - add qty ordered and shipped per KM request
 qty_ordered = (select sum(isnull(ordered,0)-isnull(cr_ordered,0)) from ord_list ol (nolock) where
		orders.order_no = ol.order_no and orders.ext = ol.order_ext),
 qty_shipped = (select sum(isnull(shipped,0)-isnull(cr_shipped,0)) from ord_list ol (nolock) where
		orders.order_no = ol.order_no and orders.ext = ol.order_ext),
  --orders.total_invoice , 
 total_invoice = 
	case orders.status
		when 'T' then total_invoice
		else (orders.total_amt_order-orders.tot_ord_disc+orders.tot_ord_tax+orders.tot_ord_freight)
		end,
 convert(varchar(10),orders.invoice_no) invoice_no ,        
 orders_invoice.doc_ctrl_num,        
 date_invoice = orders.invoice_date ,        
 orders.date_entered ,        
 date_sch_ship = orders.sch_ship_date ,  
 orders.date_shipped ,          
 cast(orders.status as varchar(1)) status ,         
 status_desc =         
  CASE orders.status        
   WHEN 'A' THEN 'Hold for Quote'        
   WHEN 'B' THEN 'Both a credit and price hold'        
   WHEN 'C' THEN 'Credit Hold'        
   WHEN 'E' THEN 'EDI'        
   WHEN 'H' THEN 'Price Hold'        
   WHEN 'M' THEN 'Blanket Order(parent)'        
   WHEN 'N' THEN 'New'        
   WHEN 'P' THEN 'Open/Picked'        
   WHEN 'Q' THEN 'Open/Printed'        
   WHEN 'R' THEN 'Ready/Posting'        
   WHEN 'S' THEN 'Shipped/Posted'        
   WHEN 'T' THEN 'Shipped/Transferred'        
   WHEN 'V' THEN 'Void'        
   WHEN 'X' THEN 'Voided/Cancel Quote'        
   ELSE ''        
  END,         
 orders.who_entered,        
-- orders.blanket,        
-- blanket_desc=        
--   CASE orders.blanket        
--   WHEN 'N' THEN 'No'        
--   WHEN 'Y' THEN 'Yes'        
--   ELSE ''        
--  END,        
 shipped_flag =        
   CASE orders.status        
   WHEN 'A' THEN 'No'        
   WHEN 'B' THEN 'No'        
   WHEN 'C' THEN 'No'        
   WHEN 'E' THEN 'No'        
   WHEN 'H' THEN 'No'        
   WHEN 'M' THEN 'No'        
   WHEN 'N' THEN 'No'        
   WHEN 'P' THEN 'No'        
   WHEN 'Q' THEN 'No'        
   WHEN 'R' THEN 'Yes'        
   WHEN 'S' THEN 'Yes'        
   WHEN 'T' THEN 'Yes'        
   WHEN 'V' THEN 'No'        
   WHEN 'X' THEN 'No'        
   ELSE ''        
  END,        
 orders.hold_reason,       -- T McGrady NOV.29.2010        
 orders.orig_no,        
 orders.orig_ext,        
-- CASE multiple_flag         
--  WHEN 'Y' THEN 'Yes'         
--  WHEN 'N' THEN 'No'         
--  ELSE 'No' END multiple_ship_to,        
--  Ctel_Order_Num = ISNULL(EAI_ord_xref.FO_order_no, ' '),  
 cvo.promo_id, -- tag - add promos  
 cvo.promo_level,
 orders.user_category as order_type,	-- tag 01/25/2012       
 -- convert(varchar(10),orders.user_def_fld4) user_def_fld4, --fzambada add Megasys orders      
-- 080212 - TAG
-- 082312 - tag - only tally up frames and suns
ISNULL( (select sum(ordered) 
 from ord_list ol (nolock)
 inner join inv_master i (nolock) on ol.part_no = i.part_no
 where ORDERS.order_no = ol.order_no and ORDERS.ext = ol.order_ext
	and i.type_code in ('FRAME','SUN') ), 0) as FramesOrdered, 
ISNULL( (select sum(shipped) 
 from ord_list ol (nolock)
 inner join inv_master i (nolock) on ol.part_no = i.part_no
 where ORDERS.order_no = ol.order_no and ORDERS.ext = ol.order_ext
	and i.type_code in ('FRAME','SUN') ), 0) as FramesShipped, 
 orders.back_ord_flag,
 isnull(ar.addr_sort1,'') as Cust_type,
 isnull(user_def_fld4,'') as HS_order_no, -- 101613 - as per HK
 allocation_date =  cvo.allocation_date ,     

  x_date_invoice = dbo.adm_get_pltdate_f(orders.invoice_date) ,        
 x_date_entered = dbo.adm_get_pltdate_f(orders.date_entered) ,        
 x_date_sch_ship = dbo.adm_get_pltdate_f(orders.sch_ship_date) ,        
 x_date_shipped = dbo.adm_get_pltdate_f(orders.date_shipped) ,
 source = 'E' -- tag  
       
FROM orders orders (nolock) LEFT OUTER JOIN         
 orders_invoice orders_invoice (nolock) ON ( orders.order_no = orders_invoice.order_no        
                                      AND  orders.ext      = orders_invoice.order_ext  )         
--        LEFT OUTER JOIN EAI_ord_xref EAI_ord_xref (nolock)       
--        ON ( orders.order_no = EAI_ord_xref.BO_order_no  )   
left join cvo_orders_all cvo (nolock) on ( orders.order_no = cvo.order_no and orders.ext = cvo.ext ) -- tag = add promos       
left outer join armaster ar (nolock) on orders.cust_code = ar.customer_code and orders.ship_to = ar.ship_to_code
WHERE  orders.type = 'I' 
-- and orders.status<>'V'  and orders.status<>'X'  
  
union all      
select       
 convert(varchar(10),t1.order_no) order_no ,        
 convert(varchar(3),t1.ext) ext ,      
 t1.cust_code,        
 t1.ship_to ,        
 t1.ship_to_name ,        
 t1.location ,         
 t1.cust_po ,        
 t1.routing,        
 t1.fob,        
 t1.attention,        
 t1.tax_id,        
 t1.terms,        
 t1.curr_key,        
 t1.salesperson,       -- T McGrady NOV.29.2010        
 t1.ship_to_region AS Territory,   -- T McGrady NOV.29.2010        
 t1.total_amt_order ,        
 total_discount=t1.discount ,   
 t1.total_amt_order - t1.discount as Net_Sales_Amount,
  total_tax =t1.total_tax ,          
 freight=t1.freight,        
 --t1.total_invoice ,        
-- (t1.total_amt_order+t1.tot_ord_tax+t1.tot_ord_freight) AS total_invoice,
-- tag - 5/21/2012 - add qty ordered and shipped per KM request
	qty_ordered = (select sum(isnull(ordered,0)) from cvo_ord_list_hist ol (nolock) where
		t1.order_no = ol.order_no and t1.ext = ol.order_ext),
	qty_shipped = (select sum(isnull(shipped,0)) from cvo_ord_list_hist ol (nolock) where
		t1.order_no = ol.order_no and t1.ext = ol.order_ext),
   
(t1.total_amt_order+t1.total_tax+t1.freight) as total_invoice,  
 convert(varchar(10),t1.invoice_no) invoice_no ,        
 '' as doc_ctrl_num,        
 date_invoice = t1.invoice_date ,        
 t1.date_entered ,        
 date_sch_ship = t1.sch_ship_date ,        
 t1.date_shipped ,          
 t1.status ,         
 status_desc =         
  CASE t1.status        
   WHEN 'A' THEN 'Hold for Quote'        
   WHEN 'B' THEN 'Both a credit and price hold'        
   WHEN 'C' THEN 'Credit Hold'        
   WHEN 'E' THEN 'EDI'        
   WHEN 'H' THEN 'Price Hold'        
   WHEN 'M' THEN 'Blanket Order(parent)'        
   WHEN 'N' THEN 'New'        
   WHEN 'P' THEN 'Open/Picked'        
   WHEN 'Q' THEN 'Open/Printed'        
   WHEN 'R' THEN 'Ready/Posting'        
   WHEN 'S' THEN 'Shipped/Posted'        
   WHEN 'T' THEN 'Shipped/Transferred'        
   WHEN 'V' THEN 'Void'        
   WHEN 'X' THEN 'Voided/Cancel Quote'        
   ELSE ''        
  END,         
 t1.who_entered,        
-- t1.blanket,        
-- blanket_desc=        
--   CASE t1.blanket        
--   WHEN 'N' THEN 'No'        
--   WHEN 'Y' THEN 'Yes'        
--   ELSE ''        
--  END,        
 shipped_flag =        
   CASE t1.status        
   WHEN 'A' THEN 'No'        
   WHEN 'B' THEN 'No'        
   WHEN 'C' THEN 'No'        
   WHEN 'E' THEN 'No'        
   WHEN 'H' THEN 'No'        
   WHEN 'M' THEN 'No'        
   WHEN 'N' THEN 'No'        
   WHEN 'P' THEN 'No'        
   WHEN 'Q' THEN 'No'        
   WHEN 'R' THEN 'Yes'        
   WHEN 'S' THEN 'Yes'        
   WHEN 'T' THEN 'Yes'        
   WHEN 'V' THEN 'No'        
   WHEN 'X' THEN 'No'        
   ELSE ''        
  END,        
 t1.hold_reason,       -- T McGrady NOV.29.2010        
 t1.orig_no,        
 t1.orig_ext,        
-- CASE multiple_flag         
--  WHEN 'Y' THEN 'Yes'         
--  WHEN 'N' THEN 'No'         
--  ELSE 'No' END multiple_ship_to,        
--  '' as Ctel_Order_Num,  
 t1.user_def_fld3, -- tag - add promos  
 t1.user_def_fld9,  
 t1.user_category as order_type,		-- tag 01/25/2012     
  
-- convert(varchar(10),t1.user_def_fld4) user_def_fld4, --fzambada add Megasys orders      
ISNULL((select sum(ordered) 
 from CVO_ord_list_HIST ol (nolock)
 inner join inv_master i (nolock) on ol.part_no = i.part_no
 where T1.order_no = ol.order_no and T1.ext = ol.order_ext
	and i.type_code in ('FRAME','SUN','PARTS') ), 0) as FramesOrdered, 
ISNULL((select sum(shipped) 
 from CVO_ord_list_HIST ol (nolock)
 inner join inv_master i (nolock) on ol.part_no = i.part_no
 where T1.order_no = ol.order_no and T1.ext = ol.order_ext
	and i.type_code in ('FRAME','SUN','PARTS') ), 0) as FramesShipped,  
 t1.back_ord_flag,
 isnull(ar.addr_sort1,'') as Cust_type,
  isnull(user_def_fld4,'') as HS_order_no, -- 101613 - as per HK
  allocation_date =  getdate() , 
 x_date_invoice = dbo.adm_get_pltdate_f(t1.invoice_date) ,        
 x_date_entered = dbo.adm_get_pltdate_f(t1.date_entered) ,        
 x_date_sch_ship = dbo.adm_get_pltdate_f(t1.sch_ship_date) ,        
 x_date_shipped = dbo.adm_get_pltdate_f(t1.date_shipped) ,
 source = 'M' -- tag   
FROM cvo_orders_all_hist t1 (nolock)  
left outer join armaster ar (nolock) on t1.cust_code = ar.customer_code and t1.ship_to = ar.ship_to_code

WHERE  t1.type = 'I'










GO
GRANT REFERENCES ON  [dbo].[cvo_adord_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[cvo_adord_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[cvo_adord_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[cvo_adord_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[cvo_adord_vw] TO [public]
GO
