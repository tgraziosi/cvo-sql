SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


/* for debugging ...
select datepart(m,date_applied), datepart(yy,date_applied), sum(extprice) 
from cvo_gdserial_vw where date_applied > '12/31/2009' 
-- and cust_code = '012808'
group by datepart(yy,date_applied), datepart(m,date_applied)
order by datepart(yy,date_applied), datepart(m,date_applied)

select * from cvo_gdserial_vw where date_applied between '04/01/2012' and '05/31/2012'
group by doc_ctrl_num

declare @date2 datetime
set @date2 = '9/30/2012'
select datediff(day,'1/1/1950',convert(datetime,
  convert(varchar( 8), (year(@date2) * 10000) + (month(@date2) * 100) + day(@date2)))  ) + 711858

select left(doc_ctrl_num,10) as invoice, sum(extprice)
from cvo_gdserial_vw where date_applied between '09/01/2012' and '09/30/2012'
group by left(doc_ctrl_num,10)

select left(doc_ctrl_num,10) as invoice, sum(amt_net) from cvo_invreg_vw
where date_applied between 734747 and 734776
group by left(doc_ctrl_num,10)

select year, x_month, sum(anet) from cvo_customer_sales_by_month 
group by year, x_month

select * from cvo_gdserial_vw where date_applied between '1/1/2012' and '6/30/2012'
and territory_code = 30336

*/


CREATE VIEW [dbo].[cvo_gdserial_vw]      
AS
-- v1.1 - TAG - 04/24/2012 - remove qualification on price > 0
-- v1.2 - tag - 06/04/2012 - update to use date applied instead of date shipped
-- v2.0 - tag/EL - 10/12 - re-write and validate to invoiced sales
-- v2.1 - tag - add return code for credits

SELECT 
-- posted credits and invoices          
ol.order_no,       
ol.order_ext,       
ol.line_no,       
x.doc_ctrl_num,       
isnull(c.address_name,o.ship_to_name) as ship_to_name,       
isnull(o.cust_po,'') cust_po,       
isnull(inv.category,'') category,          
isnull(inv.type_code,'') type_code,        
ol.part_no,       
ol.part_type,       
ol.ordered,       
isnull(ol.shipped,0)-isnull(ol.cr_shipped,0) as Shipped,       
CASE o.type WHEN 'I' THEN 
		CASE isnull(cl.is_amt_disc,'N')   
			WHEN 'Y' THEN round((ol.curr_price - isnull(cl.amt_disc,0)), 2)		
			ELSE round(ol.curr_price - (ol.curr_price * (ol.discount / 100.00)),2) END	
    ELSE round(ol.curr_price -  (ol.curr_price *  (ol.discount / 100.00)),2)		
END as price,
CASE o.type
    WHEN 'I' THEN 
			CASE isnull(cl.is_amt_disc,'N')   
			WHEN 'Y' THEN	round(ol.shipped * ol.curr_price,2) -  
						round((ol.shipped * isnull(cl.amt_disc,0)),2)		
			ELSE	round(ol.shipped * ol.curr_price,2) -   
					round(( (ol.shipped * ol.curr_price) * (ol.discount / 100.00)),2) END			
    ELSE round(-ol.cr_shipped * ol.curr_price,2) -  
      round(( (-ol.cr_shipped * ol.curr_price) * (ol.discount / 100.00)),2) 		
END as ExtPrice,
cost = case
 WHEN o.type ='I' THEN ol.cost + ol.ovhd_dolrs + ol.util_dolrs    
 ELSE (ol.cost + ol.ovhd_dolrs + ol.util_dolrs)*-1    
 END,   
---- v1.1      
--item_gp = case when ol.curr_price = 0
-- then 0 
-- else
--  CASE    
--  WHEN o.type ='I' THEN  
--	   ( ROUND(ol.curr_price -(ol.curr_price * (ol.discount / 100)),2)
--		- ol.cost) / ol.curr_price * 100     
--  ELSE (( ROUND(ol.curr_price -(ol.curr_price * (ol.discount / 100)),2) 
--		- ol.cost) / ol.curr_price * 100) * -1    
--  END
-- end,    
CONVERT(DATETIME,DATEADD(D,X.DATE_APPLIED-711858,'1/1/1950'),101) date_applied,
o.date_shipped,       
isnull(inv.description,ol.description) description,       
o.cust_code,       
o.ship_to,    
isnull(c.territory_code,o.ship_to_region) territory_code,
ol.location, 
case when o.type = 'i' then isnull(ol.reference_code,'')
	when o.type = 'c' then isnull(ol.return_code,'')
	end as reference_code,   
o.user_category as order_type,      
x_date_shipped = (datediff(day, '01/01/1900', o.date_shipped ) + 693596)      
                   + (datepart(hh,o.date_shipped)*.01       
                   + datepart(mi,o.date_shipped)*.0001       
                   + datepart(ss,o.date_shipped)*.000001),       
x_type = o.type,
'Posted' as source 
FROM ord_list ol (NOLOCK)
INNER JOIN orders o (NOLOCK) ON ol.order_no = o.order_no AND ol.order_ext = o.ext       
inner JOIN orders_invoice oi (NOLOCK) ON ol.order_no = oi.order_no AND       
            ol.order_ext = oi.order_ext    
inner join dbo.artrx x (nolock) on oi.trx_ctrl_num = x.trx_ctrl_num
left outer join cvo_ord_list cl (nolock) on ol.order_no = cl.order_no and ol.order_ext = cl.order_ext
	and ol.line_no = cl.line_no
left outer join armaster c (nolock) on o.cust_code = c.customer_code and o.ship_to = c.ship_to_code      
left outer JOIN inv_master inv (NOLOCK) ON ol.part_no = inv.part_no      

where 1=1
and (ol.shipped <> 0 or ol.cr_shipped <> 0)
and x.trx_type in (2031,2032)
AND x.DOC_DESC NOT LIKE 'CONVERTED%'
AND x.doc_desc NOT LIKE '%NONSALES%'
AND x.doc_ctrl_num NOT LIKE 'CB%'
AND x.doc_ctrl_num NOT LIKE 'FIN%'
and x.void_flag = 0
and x.posted_flag = 1
 

union all
-- unposted credits and invoices
SELECT 
ol.order_no,       
ol.order_ext,       
ol.line_no,       
x.doc_ctrl_num,       
isnull(c.address_name,o.ship_to_name) as ship_to_name,       
isnull(o.cust_po,'') cust_po,       
isnull(inv.category,'') category,          
isnull(inv.type_code,'') type_code,        
ol.part_no,       
ol.part_type,       
ol.ordered,       
isnull(ol.shipped,0)-isnull(ol.cr_shipped,0) as Shipped,       
CASE o.type WHEN 'I' THEN 
		CASE isnull(cl.is_amt_disc,'N')   
			WHEN 'Y' THEN round((ol.curr_price - isnull(cl.amt_disc,0)), 2)		
			ELSE round(ol.curr_price - (ol.curr_price * (ol.discount / 100.00)),2) END	
    ELSE round(ol.curr_price -  (ol.curr_price *  (ol.discount / 100.00)),2)		
END as price,
CASE o.type
    WHEN 'I' THEN 
			CASE isnull(cl.is_amt_disc,'N')   
			WHEN 'Y' THEN	round(ol.shipped * ol.curr_price,2) -  
							round((ol.shipped * isnull(cl.amt_disc,0)),2)		
			ELSE	round(ol.shipped * ol.curr_price,2) -   
					round(( (ol.shipped * ol.curr_price) * (ol.discount / 100.00)),2) END			
    ELSE round(-ol.cr_shipped * ol.curr_price,2) -  
      round(( (-ol.cr_shipped * ol.curr_price) * (ol.discount / 100.00)),2) 		
END as ExtPrice,
cost = CASE    
 WHEN o.type ='I' THEN ol.cost     
 ELSE ol.cost*-1    
 END,   
---- v1.1      
--item_gp = case when ol.curr_price = 0
-- then 0 
-- else
--  CASE    
--  WHEN o.type ='I' THEN  
--	   ( ROUND(ol.curr_price -(ol.curr_price * (ol.discount / 100)),2)
--		- ol.cost) / ol.curr_price * 100     
--  ELSE (( ROUND(ol.curr_price -(ol.curr_price * (ol.discount / 100)),2) 
--		- ol.cost) / ol.curr_price * 100) * -1    
--  END
-- end,    
CONVERT(DATETIME,DATEADD(D,X.DATE_APPLIED-711858,'1/1/1950'),101) date_applied,
o.date_shipped,       
isnull(inv.description,ol.description),       
o.cust_code,       
o.ship_to,    
isnull(c.territory_code,o.ship_to_region),
ol.location, -- tag - 05/30/2012 - add back location 
case when o.type = 'i' then isnull(ol.reference_code,'')
	when o.type = 'c' then isnull(ol.return_code,'')
	end as reference_code,  
o.user_category as order_type,      
x_date_shipped = (datediff(day, '01/01/1900', o.date_shipped ) + 693596)      
                   + (datepart(hh,o.date_shipped)*.01       
                   + datepart(mi,o.date_shipped)*.0001       
                   + datepart(ss,o.date_shipped)*.000001),       
x_type = o.type,    
'Unposted' as source
FROM ord_list ol (NOLOCK)
INNER JOIN orders o (NOLOCK) ON ol.order_no = o.order_no AND ol.order_ext = o.ext       
inner JOIN orders_invoice oi (NOLOCK) ON ol.order_no = oi.order_no AND       
            ol.order_ext = oi.order_ext    
inner join dbo.arinpchg x (nolock) on oi.trx_ctrl_num = x.trx_ctrl_num
left outer join cvo_ord_list cl (nolock) on ol.order_no = cl.order_no and ol.order_ext = cl.order_ext
	and ol.line_no = cl.line_no
left outer join armaster c (nolock) on o.cust_code = c.customer_code and o.ship_to = c.ship_to_code      
left outer JOIN inv_master inv (NOLOCK) ON ol.part_no = inv.part_no      

where 1=1
and (ol.shipped <> 0 or ol.cr_shipped <> 0) 
and x.trx_type in (2031,2032)
AND x.DOC_DESC NOT LIKE 'CONVERTED%'
AND x.doc_desc NOT LIKE '%NONSALES%'
AND x.doc_ctrl_num NOT LIKE 'CB%'
AND x.doc_ctrl_num NOT LIKE 'FIN%'


union all
-- AR only activity

select 
0 as order_no,
0 as order_ext,
sequence_id as line_no,
ad.doc_ctrl_num,
isnull(ar.address_name,'') as ship_to_name,
isnull(a.cust_po_num,'') as cust_po,
isnull(inv.category,'') category,
isnull(inv.type_code,'') type_code,
isnull(inv.part_no,'NA') part_no,
'' as part_type,
qty_shipped-qty_returned as ordered,
qty_shipped-qty_returned as shipped,
unit_price-discount_amt as price,
case when a.trx_type = 2031 then qty_shipped*(unit_price-discount_amt)
else -qty_returned*(unit_price-discount_amt) end as extprice,
0 as cost,
--0 as item_gp,
convert(varchar,dateadd(d,a.DATE_APPLIED-711858,'1/1/1950'),101) AS Date_Applied,
convert(varchar,dateadd(d,a.DATE_applied-711858,'1/1/1950'),101) AS Date_Shipped,
isnull(inv.description,'AR only activity') description,
isnull(ar.customer_code,'') as cust_code,
isnull(ar.ship_to_code,'') as ship_to,
isnull(ar.territory_code,'') as territory_code,
'001' as location,
left(isnull(AD.line_desc,''),32) as reference_code,
'' as order_type, 
a.date_applied as x_date_shipped,
case WHEN a.trx_type = 2031 then 'I' ELSE 'C' END AS X_TYPE,
'AR Only' as source
--select ad.*, a.* 
From artrxcdt ad (nolock) 
inner join artrx a (nolock) on ad.trx_ctrl_num = a.trx_ctrl_num
left outer join armaster ar (nolock) on a.customer_code = ar.customer_code and a.ship_to_code = ar.ship_to_code
left outer join inv_master inv (nolock) on ad.item_code = inv.part_no
where not exists (select * from orders_invoice oi (nolock) where ad.trx_ctrl_num = oi.trx_ctrl_num)
and a.trx_type in (2031,2032)
AND a.DOC_DESC NOT LIKE 'CONVERTED%'
AND a.doc_desc NOT LIKE '%NONSALES%'
AND a.doc_ctrl_num NOT LIKE 'CB%'
AND a.doc_ctrl_num NOT LIKE 'FIN%'
and a.void_flag = 0 and a.posted_flag = 1
and a.terms_code not like 'ins%'

union all  
-- History

SELECT           
O.order_no,       
O.ext,       
ol.line_no,       
O.invoice_no,       
isnull(c.address_name,o.ship_to_name) as ship_to_name,       
O.cust_po,       
isnull(inv.category,'') category,         -- CVO      
isnull(inv.type_code,'') type_code,         -- CVO      
isnull(inv.part_no,ol.part_no) part_no,       
ol.part_type,       
ol.ordered,       
ol.shipped-ol.cr_shipped as shipped,       
price = CASE    
 WHEN O.type= 'I' THEN ol.price     
 ELSE ol.price*-1    
 END,       
ExtPrice = (OL.shipped-OL.cr_shipped) * ol.price,
cost = CASE    
 WHEN O.type= 'I' THEN ol.cost     
 ELSE ol.cost*-1    
 END,
-- v1.1         
--item_gp = case when ol.price = 0 then 0
-- else
-- CASE    
-- WHEN O.type= 'I' THEN (ol.price - ol.cost) / ol.price * 100     
-- ELSE ((ol.price - ol.cost) / ol.price * 100)*-1    
-- END
-- end,  
O.date_shipped,       
O.date_shipped,
isnull(inv.description, ol.description),       
O.cust_code,       
O.ship_to,       
isnull(c.territory_code,o.ship_to_region) territory_code,
ol.location, 
case when o.type = 'i' then isnull(ol.reference_code,'')
	when o.type = 'c' then isnull(ol.return_code,'06-13')
	end as reference_code,
o.user_category as order_type,    
x_date_shipped = (datediff(day, '01/01/1900', O.date_shipped ) + 693596)      
                   + (datepart(hh,O.date_shipped)*.01       
                   + datepart(mi,O.date_shipped)*.0001       
                   + datepart(ss,O.date_shipped)*.000001),    
x_type = CASE    
 WHEN  O.type= 'I' THEN 'I'    
 ELSE 'C'    
END    ,
'Hist' as source
FROM CVO_ORDERS_ALL_HIST O (NOLOCK)    
INNER JOIN CVO_ORD_LIST_HIST ol(NOLOCK) ON O.order_no = ol.order_no AND O.ext = ol.order_ext       
left outer join armaster c (nolock) on o.cust_code = c.customer_code and o.ship_to = c.ship_to_code      
left outer JOIN inv_master inv (NOLOCK) ON OL.part_no = inv.part_no      


GO
GRANT SELECT ON  [dbo].[cvo_gdserial_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[cvo_gdserial_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[cvo_gdserial_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[cvo_gdserial_vw] TO [public]
GO
