SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- SELECT * FROM cvo_adord_cons_vw where shipped_flag = 'no' and status < 'r'

CREATE view [dbo].[cvo_adord_cons_vw] as
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
 
-- tag - 5/21/2012 - add qty ordered and shipped per KM request
 qty_ordered = qtys.qty_ordered,
 qty_shipped = qtys.qty_shipped,
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
     
 shipped_flag =        
   CASE when orders.status  < 'R' OR ORDERS.STATUS > 'T' THEN 'No'
		WHEN orders.status BETWEEN 'R' AND 'T' THEN 'Y'
		ELSE '' END,
		      
 orders.hold_reason,       -- T McGrady NOV.29.2010        
 cvo.promo_id, -- tag - add promos  
 cvo.promo_level,
 orders.user_category as order_type,	-- tag 01/25/2012       

ISNULL( qtys.framesordered , 0) as FramesOrdered, 
ISNULL( qtys.framesshipped , 0) as FramesShipped, 

 orders.back_ord_flag,
 isnull(ar.addr_sort1,'') as Cust_type,
 isnull(user_def_fld4,'') as HS_order_no, -- 101613 - as per HK
 allocation_date =  cvo.allocation_date ,     

 cons.consolidation_no ,
 cons.type cons_type,
 cons.carrier cons_carrier,
 cons.ship_date cons_ship_date,
 cons.closed cons_closed,
 cons.shipped cons_shipped,

 x_date_invoice = dbo.adm_get_pltdate_f(orders.invoice_date) ,        
 x_date_entered = dbo.adm_get_pltdate_f(orders.date_entered) ,        
 x_date_sch_ship = dbo.adm_get_pltdate_f(orders.sch_ship_date) ,        
 x_date_shipped = dbo.adm_get_pltdate_f(orders.date_shipped) ,
 source = 'E' -- tag  
       
FROM orders orders (nolock) LEFT OUTER JOIN         
 orders_invoice orders_invoice (nolock) ON ( orders.order_no = orders_invoice.order_no        
                                      AND  orders.ext      = orders_invoice.order_ext  )         
left join cvo_orders_all cvo (nolock) on ( orders.order_no = cvo.order_no and orders.ext = cvo.ext ) -- tag = add promos       
left outer join armaster ar (nolock) on orders.cust_code = ar.customer_code and orders.ship_to = ar.ship_to_code
LEFT OUTER JOIN 
( SELECT order_no, order_ext,
	sum(isnull(ordered,0)-isnull(cr_ordered,0) ) qty_ordered,
	sum(isnull(shipped,0)-isnull(cr_shipped,0) ) qty_shipped,
	SUM(CASE WHEN i.type_code IN ('frame','sun') THEN ordered ELSE 0 end) framesordered,
	SUM(CASE WHEN i.type_code IN ('frame','sun') THEN shipped ELSE 0 end) framesshipped
	FROM ORD_LIST OL (NOLOCK) JOIN INV_MASTER I (NOLOCK) ON OL.part_no = I.part_no
	GROUP BY order_no, order_ext
) qtys ON qtys.order_no = orders.order_no AND qtys.order_ext = orders.ext
LEFT OUTER JOIN
( SELECT cmcd.consolidation_no ,
         cmcd.order_no ,
         cmcd.order_ext ,
         cmch.type ,
         cmch.carrier ,
         cmch.ship_date ,
         cmch.closed ,
         cmch.shipped 
 FROM dbo.cvo_masterpack_consolidation_det AS cmcd
 JOIN dbo.cvo_masterpack_consolidation_hdr AS cmch
  ON cmch.consolidation_no = cmcd.consolidation_no
  ) cons ON cons.order_no = orders.order_no AND cons.order_ext = orders.ext

WHERE  orders.type = 'I' 

  




GO
GRANT REFERENCES ON  [dbo].[cvo_adord_cons_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[cvo_adord_cons_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[cvo_adord_cons_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[cvo_adord_cons_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[cvo_adord_cons_vw] TO [public]
GO
