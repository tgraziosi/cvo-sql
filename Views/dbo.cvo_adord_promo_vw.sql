SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE view [dbo].[cvo_adord_promo_vw] as
SELECT   
 orders.user_def_fld4,	--fzambada add Megasys orders
 orders.order_no ,  
 orders.ext ,  
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
 orders.total_amt_order ,  
 total_tax =orders.tot_ord_tax ,  
 total_discount=orders.tot_ord_disc ,  
 freight=orders.tot_ord_freight,  
 orders.total_invoice ,  
 convert(varchar,orders.invoice_no) AS invoice_no ,  
 orders_invoice.doc_ctrl_num,  
 date_invoice = orders.invoice_date ,  
 orders.date_entered ,  
 date_sch_ship = orders.sch_ship_date ,  
 orders.date_shipped ,    
 orders.status ,   
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
 orders.blanket,  
 blanket_desc=  
   CASE orders.blanket  
   WHEN 'N' THEN 'No'  
   WHEN 'Y' THEN 'Yes'  
   ELSE ''  
  END,  
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
 CASE multiple_flag   
  WHEN 'Y' THEN 'Yes'   
  WHEN 'N' THEN 'No'   
  ELSE 'No' END multiple_ship_to,  
  Ctel_Order_Num = ISNULL(EAI_ord_xref.FO_order_no, ' '),
 cvo.promo_id,	-- tag
 cvo.promo_level,
 source = 'E' -- tag
FROM orders orders (nolock) LEFT OUTER JOIN   
 orders_invoice orders_invoice (nolock) ON ( orders.order_no = orders_invoice.order_no  
                                      AND  orders.ext      = orders_invoice.order_ext  )   
        LEFT OUTER JOIN EAI_ord_xref EAI_ord_xref (nolock) 
         ON ( orders.order_no = EAI_ord_xref.BO_order_no  ) 
left join cvo_orders_all cvo (nolock) on ( orders.order_no = cvo.order_no and orders.ext = cvo.ext )
  
WHERE  orders.type = 'I'   
and cvo.promo_id is not null
union all
select 
t1.user_def_fld4,	--fzambada add Megasys orders
 t1.order_no ,  
 t1.ext ,  
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
 total_tax =t1.tot_ord_tax ,  
 total_discount=t1.tot_ord_disc ,  
 freight=t1.tot_ord_freight,  
 t1.total_invoice ,  
 t1.invoice_no ,  
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
 t1.blanket,  
 blanket_desc=  
   CASE t1.blanket  
   WHEN 'N' THEN 'No'  
   WHEN 'Y' THEN 'Yes'  
   ELSE ''  
  END,  
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
 CASE multiple_flag   
  WHEN 'Y' THEN 'Yes'   
  WHEN 'N' THEN 'No'   
  ELSE 'No' END multiple_ship_to,  
  '' as Ctel_Order_Num,
 t1.user_def_fld3,	-- tag
 t1.user_def_fld9,
 source = 'M' -- tag
FROM cvo_orders_all_hist t1 (nolock)
WHERE  t1.type = 'I'
and t1.user_def_fld3 is not null
GO
GRANT SELECT ON  [dbo].[cvo_adord_promo_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[cvo_adord_promo_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[cvo_adord_promo_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[cvo_adord_promo_vw] TO [public]
GO
