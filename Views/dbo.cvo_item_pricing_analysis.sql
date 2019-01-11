SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


-- select * from cvo_item_pricing_analysis where doc_ctrl_num like '%inv0415024%'
-- select * from cvo_item_pricing_analysis where (date_shipped between '8/1/2013' and '11/15/2013') and list_price = net_price and orig_list_price = list_price and price_code <> 'A'


CREATE view [dbo].[cvo_item_pricing_analysis] as 
SELECT 
-- posted credits and invoices  
o.cust_code,   o.ship_to,    
isnull(c.territory_code,o.ship_to_region) territory_code,
isnull(co.buying_group,'') buying_group,
o.type Doc_Type, 
x.doc_ctrl_num, 
x.order_ctrl_num,
co.ra1, 
ol.order_no,  ol.order_ext, ol.line_no,
o.date_entered,    
CONVERT(DATETIME,DATEADD(D,X.DATE_APPLIED-711858,'1/1/1950'),101) date_applied,
o.date_shipped,     
isnull(c.address_name,o.ship_to_name) as ship_to_name,       
isnull(inv.category,'') category, isnull(inv.type_code,'') type_code, isnull(inva.field_2,'') Style,
ol.part_no, 
ISNULL(ol.ordered,0)-isnull(ol.cr_ordered,0) as ordered,
ISNULL(ol.shipped,0)-isnull(ol.cr_shipped,0) as Shipped,
isnull(cc.price_code,'') price_code, 
isnull(ol.price_type,'') price_type,
isnull(pp.price_a,0) price_a,
isnull(cl.orig_list_price,0) Orig_List_price,
isnull(cl.list_price,0) List_Price,
isnull(inva.field_33,'N') List_price_only,
ISNULL(inva.field_34, '') no_commission,
isnull(cl.is_amt_disc,'') is_amt_disc,
case isnull(cl.is_amt_disc,'') when 'y' then isnull(cl.amt_disc,0) else 0 end as amt_disc,
ol.curr_price,
ol.discount,
convert(decimal(10,4),p.disc_perc) disc_perc,
case o.type when 'I' then
		case isnull(cl.is_amt_disc,'') when 'Y' then round(isnull(cl.amt_disc,0),2)
		else round(ol.curr_price * (ol.discount / 100.00),2) end
	else round(ol.curr_price * (ol.discount / 100.00),2) 
end as Discount_amt, 


CASE o.type WHEN 'I' THEN ROUND((ol.curr_price - ROUND(cl.amt_disc,2)),2,1)  -- v10.7
   ELSE CASE ol.discount WHEN 0 THEN ol.curr_price  
   -- START v11.6
   ELSE CASE WHEN cl.list_price = ol.curr_price THEN ROUND(cl.list_price - (cl.list_price * ol.discount/100),2)
      ELSE ROUND((ol.curr_price - ROUND(ol.curr_price * ol.discount/100,2 * ol.discount/100,2)),2,1) END

END END as net_price,  
    
--CASE o.type WHEN 'I' THEN 
--		CASE isnull(cl.is_amt_disc,'')   
--			WHEN 'Y' THEN round((ol.curr_price - round(isnull(cl.amt_disc,0),2)), 2)		
--			ELSE round(ol.curr_price - (ol.curr_price * (ol.discount / 100.00)),2) END	
--    ELSE round(ol.curr_price -  (ol.curr_price *  (ol.discount / 100.00)),2)		
--END as Net_price,

--CASE o.type
--    WHEN 'I' THEN 
--			CASE isnull(cl.is_amt_disc,'')   
--			WHEN 'Y' THEN	round(ol.shipped * ol.curr_price,2) -  
--						round((ol.shipped * round(isnull(cl.amt_disc,0),2)),2)		
--			ELSE	round(ol.shipped * ol.curr_price,2) -   
--					round(( (ol.shipped * ol.curr_price) * (ol.discount / 100.00)),2) END			
--    ELSE round(-ol.cr_shipped * ol.curr_price,2) -  
--      round(( (-ol.cr_shipped * ol.curr_price) * (ol.discount / 100.00)),2) 		
--END as ExtPrice,

(CASE o.type WHEN 'I' THEN ROUND((ol.curr_price - ROUND(cl.amt_disc,2)),2,1)  -- v10.7
   ELSE CASE ol.discount WHEN 0 THEN ol.curr_price  
   -- START v11.6
   ELSE CASE WHEN cl.list_price = ol.curr_price THEN ROUND(cl.list_price - (cl.list_price * ol.discount/100),2)
      ELSE ROUND((ol.curr_price - ROUND(ol.curr_price * ol.discount/100,2 * ol.discount/100,2)),2,1) END

END END ) * CASE WHEN o.type = 'i' THEN ol.shipped ELSE ol.cr_shipped END AS ExtPrice,  

isnull(co.promo_id,'') promo_id,
isnull(co.promo_level,'') promo_level,
o.user_category,
cl.promo_item, 
cl.free_frame, 
o.terms,
ol.return_code,
inv.upc_code,
o.who_entered,
'Posted' as source 
FROM ord_list ol (NOLOCK)
INNER JOIN orders o (NOLOCK) ON ol.order_no = o.order_no AND ol.order_ext = o.ext       
inner JOIN orders_invoice oi (NOLOCK) ON ol.order_no = oi.order_no AND       
            ol.order_ext = oi.order_ext    
inner join dbo.artrx x (nolock) on oi.trx_ctrl_num = x.trx_ctrl_num
left outer join cvo_orders_all co (nolock) on ol.order_no = co.order_no AND       
            ol.order_ext = co.ext   
left outer join cvo_ord_list cl (nolock) on ol.order_no = cl.order_no and ol.order_ext = cl.order_ext
	and ol.line_no = cl.line_no
left outer join CVO_disc_percent p (nolock) on ol.order_no = p.order_no and ol.order_ext = p.order_ext and ol.line_no = p.line_no  
left outer join armaster c (nolock) on o.cust_code = c.customer_code and o.ship_to = c.ship_to_code      
left outer join arcust cc (nolock) on o.cust_code = cc.customer_code 
left outer JOIN inv_master inv (NOLOCK) ON ol.part_no = inv.part_no    
left outer JOIN inv_master_add inva (NOLOCK) ON ol.part_no = inva.part_no    
left outer join part_price pp (nolock) on ol.part_no = pp.part_no
where 1=1
and (ol.ordered <> 0 or ol.cr_ordered <> 0)
and x.trx_type in (2031,2032)
AND x.DOC_DESC NOT LIKE 'CONVERTED%' AND x.doc_desc NOT LIKE '%NONSALES%'
AND x.doc_ctrl_num NOT LIKE 'CB%' AND x.doc_ctrl_num NOT LIKE 'FIN%'
and x.void_flag = 0 and x.posted_flag = 1
-- and inv.type_code in ('frame','sun')
--and CONVERT(DATETIME,DATEADD(D,X.DATE_APPLIED-711858,'1/1/1950'),101) between '10/1/2011' and '10/1/2012'
--and (co.promo_id is null 
--	or co.promo_id not in ('don','eag','eor','qop','eos','ff','survey','si','ca','sv','pc'))
--and o.user_category not in ('st-sa')

-- unposted
UNION ALL

SELECT 
-- unposted credits and invoices  
o.cust_code,   o.ship_to,    
isnull(c.territory_code,o.ship_to_region) territory_code,
isnull(co.buying_group,'') buying_group,
o.type Doc_Type, x.doc_ctrl_num, x.order_ctrl_num,
co.ra1, 
ol.order_no,  ol.order_ext, ol.line_no,
o.date_entered,    
CONVERT(DATETIME,DATEADD(D,X.DATE_APPLIED-711858,'1/1/1950'),101) date_applied,
o.date_shipped,     
isnull(c.address_name,o.ship_to_name) as ship_to_name,       
isnull(inv.category,'') category, isnull(inv.type_code,'') type_code, isnull(inva.field_2,'') Style,

ol.part_no,
ISNULL(ol.ordered,0)-isnull(ol.cr_ordered,0) as ordered,
 isnull(ol.shipped,0)-isnull(ol.cr_shipped,0) as Shipped,
isnull(cc.price_code,'') price_code, 
isnull(ol.price_type,'') price_type,
isnull(pp.price_a,0) price_a,
isnull(cl.orig_list_price,0) Orig_List_price,
isnull(cl.list_price,0) List_Price,
isnull(inva.field_33,'N') List_price_only,
ISNULL(inva.field_34, '') no_commission,
isnull(cl.is_amt_disc,'') is_amt_disc,
case isnull(cl.is_amt_disc,'') when 'y' then isnull(cl.amt_disc,0) else 0 end as amt_disc,
ol.curr_price,
ol.discount,
convert(decimal(10,4),p.disc_perc) disc_perc,

case o.type when 'I' then
		case isnull(cl.is_amt_disc,'') when 'Y' then round(isnull(cl.amt_disc,0),2,1)
		else round(ol.curr_price * (ol.discount / 100.00),2) end
	else round(ol.curr_price * (ol.discount / 100.00),2) 
end as Discount_amt,  
   
--CASE o.type WHEN 'I' THEN 
--		CASE isnull(cl.is_amt_disc,'')   
--			WHEN 'Y' THEN round((ol.curr_price - round(isnull(cl.amt_disc,0),2)), 2)		
--			ELSE round(ol.curr_price - (ol.curr_price * (ol.discount / 100.00)),2) END	
--    ELSE round(ol.curr_price -  (ol.curr_price *  (ol.discount / 100.00)),2)		
--END as Net_price,

CASE o.type WHEN 'I' THEN ROUND((ol.curr_price - ROUND(cl.amt_disc,2)),2,1)  -- v10.7
   ELSE CASE ol.discount WHEN 0 THEN ol.curr_price  
   -- START v11.6
   ELSE CASE WHEN cl.list_price = ol.curr_price THEN ROUND(cl.list_price - (cl.list_price * ol.discount/100),2)
      ELSE ROUND((ol.curr_price - ROUND(ol.curr_price * ol.discount/100,2 * ol.discount/100,2)),2,1) END

END END as net_price,  

--CASE o.type
--    WHEN 'I' THEN 
--			CASE isnull(cl.is_amt_disc,'')   
--			WHEN 'Y' THEN	round(ol.shipped * ol.curr_price,2) -  
--						round((ol.shipped * round(isnull(cl.amt_disc,0),2)),2)		
--			ELSE	   ROUND((ol.shipped * ol.curr_price) -   
--					 (ol.shipped * (ol.curr_price * ol.discount / 100.00) )  ,2) END			
--    ELSE round(-ol.cr_shipped * ol.curr_price,2) -  
--      round(( (-ol.cr_shipped * ol.curr_price) * (ol.discount / 100.00)),2) 		
--END as ExtPrice,

(CASE o.type WHEN 'I' THEN ROUND((ol.curr_price - ROUND(cl.amt_disc,2)),2,1)  -- v10.7
   ELSE CASE ol.discount WHEN 0 THEN ol.curr_price  
   -- START v11.6
   ELSE CASE WHEN cl.list_price = ol.curr_price THEN ROUND(cl.list_price - (cl.list_price * ol.discount/100),2)
      ELSE ROUND((ol.curr_price - ROUND(ol.curr_price * ol.discount/100,2 * ol.discount/100,2)),2,1) END

END END ) * CASE WHEN o.type = 'i' THEN ol.shipped ELSE ol.cr_shipped END  AS ExtPrice,  

isnull(co.promo_id,'') promo_id,
isnull(co.promo_level,'') promo_level,
o.user_category,
cl.promo_item, 
cl.free_frame, 
o.terms,
ol.return_code,
inv.upc_code,
o.who_entered,
'UnPosted' as source 
FROM ord_list ol (NOLOCK)
INNER JOIN orders o (NOLOCK) ON ol.order_no = o.order_no AND ol.order_ext = o.ext       
inner JOIN orders_invoice oi (NOLOCK) ON ol.order_no = oi.order_no AND       
            ol.order_ext = oi.order_ext    
inner join dbo.arinpchg x (nolock) on oi.trx_ctrl_num = x.trx_ctrl_num
left outer join cvo_orders_all co (nolock) on ol.order_no = co.order_no AND       
            ol.order_ext = co.ext   
left outer join cvo_ord_list cl (nolock) on ol.order_no = cl.order_no and ol.order_ext = cl.order_ext
	and ol.line_no = cl.line_no
left outer join CVO_disc_percent p (nolock) on ol.order_no = p.order_no and ol.order_ext = p.order_ext and ol.line_no = p.line_no  
left outer join armaster c (nolock) on o.cust_code = c.customer_code and o.ship_to = c.ship_to_code      
left outer join arcust cc (nolock) on o.cust_code = cc.customer_code 
left outer JOIN inv_master inv (NOLOCK) ON ol.part_no = inv.part_no    
left outer JOIN inv_master_add inva (NOLOCK) ON ol.part_no = inva.part_no    
left outer join part_price pp (nolock) on ol.part_no = pp.part_no
where 1=1
and (ol.ordered <> 0 or ol.cr_ordered <> 0)
and x.trx_type in (2031,2032)
AND x.DOC_DESC NOT LIKE 'CONVERTED%' AND x.doc_desc NOT LIKE '%NONSALES%'
AND x.doc_ctrl_num NOT LIKE 'CB%' AND x.doc_ctrl_num NOT LIKE 'FIN%'
-- and x.void_flag = 0 and x.posted_flag = 1
-- and inv.type_code in ('frame','sun')
--and CONVERT(DATETIME,DATEADD(D,X.DATE_APPLIED-711858,'1/1/1950'),101) between '10/1/2011' and '10/1/2012'
--and (co.promo_id is null 
--	or co.promo_id not in ('don','eag','eor','qop','eos','ff','survey','si','ca','sv','pc'))
--and o.user_category not in ('st-sa')

union all
-- open orders
SELECT 
o.cust_code,   o.ship_to,    
isnull(c.territory_code,o.ship_to_region) territory_code,
isnull(co.buying_group,'') buying_group,
o.type Doc_Type, 
null as doc_ctrl_num,
NULL AS order_ctrl_num,
co.ra1, 
ol.order_no,  ol.order_ext,  ol.line_no,
o.date_entered,   
null as date_applied,
o.date_shipped,     
isnull(c.address_name,o.ship_to_name) as ship_to_name,       
isnull(inv.category,'') category, isnull(inv.type_code,'') type_code, 
isnull(inva.field_2,'') Style,
ol.part_no, 
ISNULL(ol.ordered,0)-isnull(ol.cr_ordered,0) as ordered,
isnull(ol.ordered,0)-isnull(ol.cr_ordered,0) as Shipped,
isnull(cc.price_code,'') price_code, 
isnull(ol.price_type,'') price_type,
isnull(pp.price_a,0) price_a,
isnull(cl.orig_list_price,0) Orig_List_price,
isnull(cl.list_price,0) List_Price,
isnull(inva.field_33,'N') List_price_only,
ISNULL(inva.field_34, '') no_commission,
isnull(cl.is_amt_disc,'') is_amt_disc,
case isnull(cl.is_amt_disc,'') when 'y' then isnull(cl.amt_disc,0) else 0 end as amt_disc,
ol.curr_price,
ol.discount,
convert(decimal(10,4),p.disc_perc) disc_perc,
case o.type when 'I' then
		case isnull(cl.is_amt_disc,'') when 'Y' then round(isnull(cl.amt_disc,0),2)
		else round(ol.curr_price * (ol.discount / 100.00),2) end
	else round(ol.curr_price * (ol.discount / 100.00),2) 
end as Discount_amt,   
  
--CASE o.type WHEN 'I' THEN 
--		CASE isnull(cl.is_amt_disc,'')   
--			WHEN 'Y' THEN round((ol.curr_price - round(isnull(cl.amt_disc,0),2)), 2)		
--			ELSE round(ol.curr_price - (ol.curr_price * (ol.discount / 100.00)),2) END	
--    ELSE round(ol.curr_price -  (ol.curr_price *  (ol.discount / 100.00)),2)		
--END as Net_price,

CASE o.type WHEN 'I' THEN ROUND((ol.curr_price - ROUND(cl.amt_disc,2)),2,1)  -- v10.7
   ELSE CASE ol.discount WHEN 0 THEN ol.curr_price  
   -- START v11.6
   ELSE CASE WHEN cl.list_price = ol.curr_price THEN ROUND(cl.list_price - (cl.list_price * ol.discount/100),2)
      ELSE ROUND((ol.curr_price - ROUND(ol.curr_price * ol.discount/100,2 * ol.discount/100,2)),2,1) END

END END as net_price,  

--CASE o.type
--    WHEN 'I' THEN 
--			CASE isnull(cl.is_amt_disc,'')   
--			WHEN 'Y' THEN	round(ol.ordered * ol.curr_price,2) -  
--						round((ol.ordered * round(isnull(cl.amt_disc,0),2)),2)		
--			ELSE	round(ol.ordered * ol.curr_price,2) -   
--					round(( (ol.ordered * ol.curr_price) * (ol.discount / 100.00)),2) END			
--    ELSE round(-ol.cr_ordered * ol.curr_price,2) -  
--      round(( (-ol.cr_ordered * ol.curr_price) * (ol.discount / 100.00)),2) 		
--END as ExtPrice,
(CASE o.type WHEN 'I' THEN ROUND((ol.curr_price - ROUND(cl.amt_disc,2)),2,1)  -- v10.7
   ELSE CASE ol.discount WHEN 0 THEN ol.curr_price  
   -- START v11.6
   ELSE CASE WHEN cl.list_price = ol.curr_price THEN ROUND(cl.list_price - (cl.list_price * ol.discount/100),2)
      ELSE ROUND((ol.curr_price - ROUND(ol.curr_price * ol.discount/100,2 * ol.discount/100,2)),2,1) END

END END ) * CASE WHEN o.type = 'i' THEN ol.shipped ELSE ol.cr_shipped END  AS ExtPrice,  

isnull(co.promo_id,'') promo_id,
isnull(co.promo_level,'') promo_level,
o.user_category,
cl.promo_item,
cl.free_frame,
o.terms,
ol.return_code,
inv.upc_code,
o.who_entered,
'Open' as source 
FROM ord_list ol (NOLOCK)
INNER JOIN orders o (NOLOCK) ON ol.order_no = o.order_no AND ol.order_ext = o.ext       
--inner JOIN orders_invoice oi (NOLOCK) ON ol.order_no = oi.order_no AND       
--            ol.order_ext = oi.order_ext    
--inner join dbo.artrx x (nolock) on oi.trx_ctrl_num = x.trx_ctrl_num
left outer join cvo_orders_all co (nolock) on ol.order_no = co.order_no AND       
            ol.order_ext = co.ext   
left outer join cvo_ord_list cl (nolock) on ol.order_no = cl.order_no and ol.order_ext = cl.order_ext
	and ol.line_no = cl.line_no
left outer join CVO_disc_percent p (nolock) on ol.order_no = p.order_no and ol.order_ext = p.order_ext and ol.line_no = p.line_no  
left outer join armaster c (nolock) on o.cust_code = c.customer_code and o.ship_to = c.ship_to_code      
left outer join arcust cc (nolock) on o.cust_code = cc.customer_code 
left outer JOIN inv_master inv (NOLOCK) ON ol.part_no = inv.part_no    
left outer JOIN inv_master_add inva (NOLOCK) ON ol.part_no = inva.part_no  
left outer join part_price pp (nolock) on ol.part_no = pp.part_no  
where 1=1
and ol.status  <'T'
--and (ol.shipped <> 0 or ol.cr_shipped <> 0)
--and x.trx_type in (2031,2032)
--AND x.DOC_DESC NOT LIKE 'CONVERTED%' AND x.doc_desc NOT LIKE '%NONSALES%'
--AND x.doc_ctrl_num NOT LIKE 'CB%' AND x.doc_ctrl_num NOT LIKE 'FIN%'
--and x.void_flag = 0 and x.posted_flag = 1
-- and inv.type_code in ('frame','sun')

union all  
-- History

SELECT  
O.cust_code,       
O.ship_to,       
isnull(c.territory_code,o.ship_to_region) territory_code,
'' as buying_group,
o.type Doc_type,
'' as doc_ctrl_num,  
'' AS order_ctrl_num,
'' as ra1,           
O.order_no,       
O.ext,  
ol.line_no,
o.date_entered,
o.date_shipped,
o.date_shipped,
isnull(c.address_name,o.ship_to_name) as ship_to_name,       
isnull(inv.category,'') category,         -- CVO      
isnull(inv.type_code,'') type_code,         -- CVO 
isnull(inva.field_2,'') Style,
isnull(inv.part_no,ol.part_no) part_no,  
ISNULL(ol.ordered,0)-isnull(ol.cr_ordered,0) as ordered,     
ol.shipped-ol.cr_shipped as shipped,       
isnull(cc.price_code,'') price_code, 
isnull(ol.price_type,'') price_type,
isnull(pp.price_a,0) price_a,
pp.price_a as Orig_List_price,
pp.price_a as List_price,
isnull(inva.field_33,'N') List_price_only,
ISNULL(inva.field_34, '') no_commission,
'' as is_amt_disc,
0 amt_disc,
ol.price,
ol.discount,
0 as disc_perc,
pp.price_a - ol.price as Discount_amt,
Net_price = CASE    
 WHEN O.type= 'I' THEN ol.price     
 ELSE ol.price*-1    
 END,       
ExtPrice = (OL.shipped-OL.cr_shipped) * ol.price,
isnull(o.user_def_fld3,'') as promo_id,
isnull(o.user_def_fld9,'') as promo_level,
o.user_category,
'X' AS promo_item,
0 AS free_frame,
o.terms,
'ST' AS return_code,
inv.upc_code,
o.who_entered,
'Hist' as source
FROM CVO_ORDERS_ALL_HIST O (NOLOCK)    
INNER JOIN CVO_ORD_LIST_HIST ol(NOLOCK) ON O.order_no = ol.order_no AND O.ext = ol.order_ext       
left outer join armaster c (nolock) on o.cust_code = c.customer_code and o.ship_to = c.ship_to_code      
left outer join arcust cc (nolock) on o.cust_code = cc.customer_code 
left outer JOIN inv_master inv (NOLOCK) ON OL.part_no = inv.part_no 
left outer JOIN inv_master_add inva (NOLOCK) ON ol.part_no = inva.part_no    
left outer join part_price pp (nolock) on ol.part_no = pp.part_no   
where 1=1
-- and inv.type_code in ('frame','sun') 
--and o.date_shipped between '10/1/2011' and '10/1/2012'
--and (o.user_def_fld3 is null 
--	or o.user_def_fld3 not in ('don','eag','eor','qop','eos','ff','survey','si','ca','sv','pc'))
--and user_category not in ('st-sa')















GO

GRANT REFERENCES ON  [dbo].[cvo_item_pricing_analysis] TO [public]
GO
GRANT SELECT ON  [dbo].[cvo_item_pricing_analysis] TO [public]
GO
GRANT INSERT ON  [dbo].[cvo_item_pricing_analysis] TO [public]
GO
GRANT DELETE ON  [dbo].[cvo_item_pricing_analysis] TO [public]
GO
GRANT UPDATE ON  [dbo].[cvo_item_pricing_analysis] TO [public]
GO
