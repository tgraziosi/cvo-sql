SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

  
CREATE view [dbo].[CVO_BGLog_source_vw] as  
-- select  * From cvo_bglog_source_vw where DOC_CTRL_NUM = 'inv0388976'
-- select * From cvo_bglog_source_vw where inv_date between '08/26/2017' and '09/25/2017'
-- v2.0 TM 04/27/2012 - Ignore AR Records that are Voided  
-- tag - 072712 - ar only credit's - dont qualify on the terms, as it doesn't matter  
-- tag - 1/3/2012 - fix so that mixed discount orders dont merge  
-- v2.1 CT 13/02/2013 - Change to return additional field of ndd containing credit return fees
-- v2.2 CB 26/02/2013 - View not including tax and freight only credits
-- v2.3 CB 21/03/2013 - Freight and tax not showing on std AR credit memo
-- v2.4 CT 21/03/2013 - Remove ndd filed, stop credit return fee lines being included in data returned

-- v2.5 CB 10/07/2013 - Issue #927 - Buying Group Switching
-- v2.6 CB 18/09/2013 - Issue #927 - Buying Group Switching - RB Orders set to and from BGs
-- v2.7 CHANGES MADE BY CVO
-- v2.8	CT 20/10/2014 - Issue #1367 - For Sales Orders and Credit Returns, if net price > list price, set list = net and discount = 0 and disc_perc = 0
-- v2.9 CB 12/03/2015 - Issue #1469 - Deal with finance and late charges and chargebacks
-- vTAG - 030518 - performance.  Dont use get_buying_group_name function. remove arnarel from joins - don't need. re-arrange joins

-- 1 -- order h  - freight and tax
-- tag - don't even look for detail lines... dont need them
select   
-- v2.6 dbo.f_cvo_get_buying_group(h.cust_code, CONVERT(varchar(10),DATEADD(DAY, x.date_doc - 693596, '01/01/1900'),121)) parent, -- v2.5
-- v2.5 r.parent,   
-- v2.6 dbo.f_cvo_get_buying_group_name	(dbo.f_cvo_get_buying_group(h.cust_code, CONVERT(varchar(10),DATEADD(DAY, x.date_doc - 693596, '01/01/1900'),121))) parent_name, -- v2.5
-- v2.5 m.customer_name as parent_name, 
cv.buying_group parent, -- v2.6  
bg.customer_name parent_name,
-- dbo.f_cvo_get_buying_group_name	(cv.buying_group) parent_name, -- v2.6 
h.cust_code,  
b.customer_name as customer_name,  
i.doc_ctrl_num,  
t.days_due as trm,  
'Invoice' as type,
--case when h.type = 'I' then 'Invoice' else 'Credit' end as type,  
convert(varchar(12),dateadd(d,x.date_doc-639906,'1/1/1753'),101) as inv_date,
-- convert(varchar(12), h.date_shipped, 101) as inv_date,  
round((h.total_tax  + h.freight),2) as inv_tot,  
0 as mer_tot,  
0 as net_amt,  
h.freight as freight,  
h.total_tax as tax,  
0 as mer_disc,  
 round((h.total_tax  + h.freight),2) as inv_due,  
0 as disc_perc,  
case when x.date_due <> 0 then
right(convert(varchar(12),dateadd(dd,x.date_due-639906,'1/1/1753'),101),4)    
+ '/'+  
left(convert(varchar(12),dateadd(dd,x.date_due-639906,'1/1/1753'),101),2)  
else convert(varchar(4),datepart(year,getdate()))+'/'+convert(varchar(2), datepart(month,getdate()))
end
as due_year_month,  
x.date_doc as xinv_date
-- convert(int,datediff(dd,'1/1/1753',h.date_shipped) + 639906) as xinv_date
--,NULL as ndd -- v2.1   -- v2.4

from dbo.cvo_orders_all cv (NOLOCK) -- v2.6
JOIN dbo.orders h (nolock)  ON   h.order_no = cv.order_no  -- v2.6
	AND  h.ext = cv.ext   -- v2.6
join dbo.orders_invoice i (nolock) on h.order_no =i.order_no and h.ext = i.order_ext  
--join artrx x (nolock) on i.doc_ctrl_num = x.doc_ctrl_num  
join dbo.artrx x (nolock) on i.trx_ctrl_num = x.trx_ctrl_num  
--left join dbo.arnarel r (nolock) on h.cust_code = r.child  
--left join dbo.arcust m (nolock)on r.parent = m.customer_code  
LEFT JOIN arcust bg (nolock) ON bg.customer_code = cv.buying_group
join dbo.arcust B (nolock)on h.cust_code = b.customer_code  
--join ord_list d (nolock) on h.order_no = d.order_no and h.ext = d.order_ext  
--join Cvo_ord_list c (nolock) on  d.order_no =c.order_no and d.order_ext = c.order_ext and d.line_no = c.line_no  
--join CVO_disc_percent p (nolock) on d.order_no = p.order_no and d.order_ext = p.order_ext and d.line_no = p.line_no  
join dbo.arterms t (nolock) on  h.terms = t.terms_code  
--join CVO_min_display_vw z (nolock) on z.order_no = d.order_no and h.ext = z.order_ext and d.display_line = z.min_line
 

where (h.freight <> 0 or h.total_tax <> 0)  
and h.type = 'I'  
and h.terms not like 'INS%'   
and x.void_flag <> 1     --v2.0  
AND cv.buying_group > '' -- v2.6
-- v2.6 AND dbo.f_cvo_get_buying_group(h.cust_code, CONVERT(varchar(10),DATEADD(DAY, x.date_doc - 693596, '01/01/1900'),121)) > '' -- v2.5


union  all
  
-- 2 -- order lines  
select   
-- v2.6 dbo.f_cvo_get_buying_group(h.cust_code, CONVERT(varchar(10),DATEADD(DAY, x.date_doc - 693596, '01/01/1900'),121)) parent, -- v2.5
-- v2.5 r.parent,     
-- v2.6 dbo.f_cvo_get_buying_group_name	(dbo.f_cvo_get_buying_group(h.cust_code, CONVERT(varchar(10),DATEADD(DAY, x.date_doc - 693596, '01/01/1900'),121))) parent_name, -- v2.5
-- v2.5 m.customer_name as parent_name, 
cv.buying_group parent, -- v2.6  
-- dbo.f_cvo_get_buying_group_name	(cv.buying_group) parent_name, -- v2.6 
bg.customer_name parent_name,
h.cust_code,  
b.customer_name as customer_name,  
i.doc_ctrl_num,  
t.days_due as trm,  
'Invoice' as type,
--case when h.type = 'I' then 'Invoice' else 'Credit' end as type,  
--datediff(dd,'1/1/1753',h.invoice_date) + 639906 as inv_date,  
convert(varchar(12),dateadd(dd,(x.date_doc)-639906,'1/1/1753'),101) as inv_date,
--convert(varchar(12), h.date_shipped, 101) as inv_date, 
-- START v2.8 
sum(round(((CASE WHEN d.curr_price > c.list_price THEN d.curr_price ELSE c.list_price END) * d.shipped),2)) as inv_tot,
--sum(round((c.list_price * d.shipped),2)) as inv_tot,  
-- END v2.8
--sum(round((curr_price * d.shipped),2)) as inv_tot, 
-- START v2.8 
sum(round(((CASE WHEN d.curr_price > c.list_price THEN d.curr_price ELSE c.list_price END) * d.shipped),2)) as mer_tot,  
--sum(round((c.list_price * d.shipped),2)) as mer_tot,  
-- END v2.8
--sum(round((curr_price * d.shipped),2)) as mer_tot,  
0 as net_amt,  
0 as freight,  
0 as tax,  
--sum(round(((d.curr_price*(1-(d.discount/100)) * d.shipped)),2)) as mer_disc,  
--sum(round(((d.curr_price*(1-(d.discount/100)) * d.shipped)),2)) as inv_due,  
-- START v2.8
sum(d.Shipped * ROUND(curr_price -(curr_price * ((CASE WHEN d.curr_price > c.list_price THEN 0 ELSE d.discount END) / 100)),2)) as mer_disc, 
--sum(d.Shipped * ROUND(curr_price -(curr_price * (d.discount / 100)),2)) as mer_disc,  
sum(d.Shipped * ROUND(curr_price -(curr_price * ((CASE WHEN d.curr_price > c.list_price THEN 0 ELSE d.discount END) / 100)),2)) as inv_due,   
--sum(d.Shipped * ROUND(curr_price -(curr_price * (d.discount / 100)),2)) as inv_due,  
-- END v2.8
-- p.disc_perc,  
-- tag - 1/3/2012 - fix so that mixed discount orders dont merge  
--disc_perc = CASE WHEN max(d.discount) > 0 THEN max(d.discount/100) ELSE p.disc_perc END,  
--disc_perc = CASE WHEN avg(round(d.discount,2)) > 0 THEN avg(round(d.discount/100,2)) ELSE p.disc_perc END, 
-- START v2.8
CASE 	when SUM(CASE WHEN d.curr_price > c.list_price THEN d.curr_price ELSE c.list_price END) = 0 then 0
WHEN (CASE WHEN d.curr_price > c.list_price THEN 0 ELSE d.discount END) > 0 and (CASE WHEN d.curr_price > c.list_price THEN 0 ELSE p.disc_perc END) <> 0 then -- two levels of discount in play
		round(1 - (sum(d.shipped*round(curr_price-(curr_price*((CASE WHEN d.curr_price > c.list_price THEN 0 ELSE (CASE WHEN d.curr_price > c.list_price THEN 0 ELSE d.discount END) END)/100)),2)) 
		/
		sum(round(((CASE WHEN d.curr_price > c.list_price THEN d.curr_price ELSE c.list_price END) * d.shipped),2)) ), 2)
	WHEN (CASE WHEN d.curr_price > c.list_price THEN 0 ELSE d.discount END) > 0 AND (CASE WHEN d.curr_price > c.list_price THEN 0 ELSE p.disc_perc END) = 0 THEN 
		(CASE WHEN d.curr_price > c.list_price THEN 0 ELSE d.discount END)/100 
	ELSE (CASE WHEN d.curr_price > c.list_price THEN 0 ELSE p.disc_perc END) END
	AS disc_perc,  
/*
disc_perc = CASE 	when SUM(c.list_price) = 0 then 0
	WHEN d.discount > 0 and p.disc_perc <> 0 then -- two levels of discount in play
		round(1 - (sum(d.shipped*round(curr_price-(curr_price*(d.discount/100)),2)) 
		/
		sum(round((c.list_price * d.shipped),2)) ), 2)
	WHEN D.DISCOUNT > 0 AND P.DISC_PERC = 0 THEN 
		d.discount/100 
	ELSE p.disc_perc END,  
*/
-- END v2.8
-- disc_perc = CASE WHEN round(d.discount,2) > 0 THEN round(d.discount/100,2) ELSE p.disc_perc END,  
--right(convert(varchar(12), dateadd(dd, datediff(dd, '1/1/1753', h.date_shipped) + 639906 + convert(int,right(t.days_due,2)) - 639906, '1/1/1753'),101) ,4)  
--+ '/'+  
--left(convert(varchar(12), dateadd(dd, datediff(dd, '1/1/1753', h.date_shipped) + 639906 + convert(int,right(t.days_due,2)) - 639906, '1/1/1753'),101) ,2)  
right(convert(varchar(12),dateadd(dd,max(x.date_due)-639906,'1/1/1753'),101),4)    
+ '/'+  
left(convert(varchar(12),dateadd(dd,max(x.date_due)-639906,'1/1/1753'),101),2)  
as due_year_month,  
x.date_doc as xinv_date
-- convert(int,datediff(dd,'1/1/1753',h.date_shipped) + 639906) as xinv_date
-- ,NULL as ndd -- v2.1    -- v2.4
from 
cvo_orders_all cv (NOLOCK) -- v2.6

JOIN orders h (nolock)  
ON   h.order_no = cv.order_no  -- v2.6
AND  h.ext = cv.ext   -- v2.6 
join orders_invoice i (nolock) on h.order_no =i.order_no and h.ext = i.order_ext  
join arterms t (nolock) on h.terms = t.terms_code  
join artrx x (nolock) on i.doc_ctrl_num = x.doc_ctrl_num  
--left join dbo.arnarel r (nolock) on h.cust_code = r.child  
--left join dbo.arcust m (nolock)on r.parent = m.customer_code  
LEFT JOIN arcust bg (nolock) ON bg.customer_code = cv.buying_group
join arcust B (nolock)on h.cust_code = b.customer_code  
join ord_list d (nolock) on h.order_no = d.order_no and h.ext = d.order_ext  
join Cvo_ord_list c (nolock) on  d.order_no =c.order_no and d.order_ext = c.order_ext and d.line_no = c.line_no  
join CVO_disc_percent p (nolock) on d.order_no = p.order_no and d.order_ext = p.order_ext and d.line_no = p.line_no 

where 
cv.buying_group > '' -- v2.6
AND d.shipped > 0  
--and (d.display_line  <> 1 or (h.freight = 0 and h.total_tax = 0))  
and h.type = 'I'  
and h.terms not like 'INS%'   
and x.void_flag <> 1     --v2.0  
-- v2.6 AND dbo.f_cvo_get_buying_group(h.cust_code, CONVERT(varchar(10),DATEADD(DAY, x.date_doc - 693596, '01/01/1900'),121)) > '' -- v2.5

group by cv.buying_group, bg.customer_name, h.cust_code, b.customer_name, i.doc_ctrl_num, -- v2.6
-- START v2.8
t.days_due, h.type, x.date_doc, (CASE WHEN d.curr_price > c.list_price THEN 0 ELSE d.discount END), (CASE WHEN d.curr_price > c.list_price THEN 0 ELSE p.disc_perc END)  
--t.days_due, h.type, x.date_doc, d.discount, disc_perc  
-- END v2.8
  
  
union   all
  
-- 3 -- cr order header  - tax and freight portion
select   
-- v2.6 dbo.f_cvo_get_buying_group(h.cust_code, CONVERT(varchar(10),DATEADD(DAY, x.date_doc - 693596, '01/01/1900'),121)) parent, -- v2.5
-- v2.5 r.parent,       
-- v2.6 dbo.f_cvo_get_buying_group_name	(dbo.f_cvo_get_buying_group(h.cust_code, CONVERT(varchar(10),DATEADD(DAY, x.date_doc - 693596, '01/01/1900'),121))) parent_name, -- v2.5
-- v2.5 m.customer_name as parent_name, 
cv.buying_group parent, -- v2.6  
-- dbo.f_cvo_get_buying_group_name	(cv.buying_group) parent_name, -- v2.6 
bg.customer_name parent_name,
h.cust_code,  
b.customer_name as customer_name,  
i.doc_ctrl_num,  
t.days_due as trm,  
'Credit' as type,
--case when h.type = 'I' then 'Invoice' else 'Credit' end as type,  
convert(varchar(12),dateadd(dd,(x.date_doc)-639906,'1/1/1753'),101) as inv_date,
-- convert(varchar(12), h.date_shipped, 101) as inv_date,  
round((h.total_tax  + h.freight)  ,2) * -1  as inv_tot,  
0 as mer_tot,  
0 as net_amt,  
h.freight * -1 as freight,  
h.total_tax * -1 as tax,  
0 as mer_disc,  
round(h.total_tax  + h.freight ,2) * -1 as inv_due,  
0 as disc_perc,  
right(convert(varchar(12),dateadd(dd,(x.date_due)-639906,'1/1/1753'),101),4)    
+ '/' +  
left(convert(varchar(12),dateadd(dd,(x.date_due)-639906,'1/1/1753'),101),2)  
as due_year_month,  
x.date_doc as xinv_date
-- convert(int,datediff(dd,'1/1/1753',h.date_shipped) + 639906) as xinv_date
-- ,NULL as ndd -- v2.1    -- v2.4
FROM
cvo_orders_all cv (NOLOCK) -- v2.6

join orders h (nolock) 
ON   h.order_no = cv.order_no  -- v2.6
AND  h.ext = cv.ext   -- v2.6 
join orders_invoice i (nolock) on h.order_no =i.order_no and h.ext = i.order_ext  
join artrx x (nolock) on i.doc_ctrl_num = x.doc_ctrl_num and x.trx_type = 2032  
--join ord_list d (nolock) on h.order_no = d.order_no and h.ext = d.order_ext  
--left join arnarel r (nolock) on h.cust_code = r.child  
--left join arcust m (nolock)on r.parent = m.customer_code  
JOIN arcust bg (nolock) ON bg.customer_code = cv.buying_group
join arcust B (nolock)on h.cust_code = b.customer_code  
--join Cvo_ord_list c (nolock) on  d.order_no =c.order_no and d.order_ext = c.order_ext and d.line_no = c.line_no  
--join CVO_disc_percent p (nolock) on d.order_no = p.order_no and d.order_ext = p.order_ext and d.line_no = p.line_no  
join arterms t (nolock) on h.terms = t.terms_code  
--join CVO_min_display_vw z (nolock) on z.order_no = d.order_no and z.order_ext = d.order_ext and d.display_line = z.min_line  

WHERE cv.buying_group > '' -- v2.6
and (h.freight <> 0 or h.total_tax <> 0)  
and h.type = 'C'  
and h.terms not like 'INS%'   
and x.void_flag <> 1     --v2.0  

-- v2.6 AND dbo.f_cvo_get_buying_group(h.cust_code, CONVERT(varchar(10),DATEADD(DAY, x.date_doc - 693596, '01/01/1900'),121)) > '' -- v2.5
 
--and x.date_doc between dbo.adm_get_pltdate_f('04/01/2013') and dbo.adm_get_pltdate_F('04/10/2013')
 
  
union  all
  --  4 -- cr order lines  
select   
-- v2.6 dbo.f_cvo_get_buying_group(h.cust_code, CONVERT(varchar(10),DATEADD(DAY, x.date_doc - 693596, '01/01/1900'),121)) parent, -- v2.5
-- v2.5 r.parent,        
-- v2.6 dbo.f_cvo_get_buying_group_name	(dbo.f_cvo_get_buying_group(h.cust_code, CONVERT(varchar(10),DATEADD(DAY, x.date_doc - 693596, '01/01/1900'),121))) parent_name, -- v2.5
-- v2.5 m.customer_name as parent_name,   
cv.buying_group parent, -- v2.6  
-- dbo.f_cvo_get_buying_group_name	(cv.buying_group) parent_name, -- v2.6 
bg.customer_name parent_name,
h.cust_code,  
b.customer_name as customer_name,  
i.doc_ctrl_num,  
t.days_due as trm,  
'Credit' as type,
--case when h.type = 'I' then 'Invoice' else 'Credit' end as type,  
--datediff(dd,'1/1/1753',h.invoice_date) + 639906 as inv_date,  
--convert(varchar(12), h.date_shipped, 101)  as inv_date,  
convert(varchar(12),dateadd(dd,(x.date_doc)-639906,'1/1/1753'),101) as inv_date,
-- START v2.8
sum(round(((CASE WHEN d.curr_price > c.list_price THEN d.curr_price ELSE c.list_price END) * d.cr_shipped),2)) * -1 as inv_tot, 
--sum(round((c.list_price * d.cr_shipped),2)) * -1 as inv_tot,
-- END v2.8  
--sum(round((curr_price * d.cr_shipped),2)) * -1 as inv_tot,  
-- START v2.8
sum(round(((CASE WHEN d.curr_price > c.list_price THEN d.curr_price ELSE c.list_price END) * d.cr_shipped),2)) * -1 as mer_tot,  
--sum(round((c.list_price * d.cr_shipped),2)) * -1 as mer_tot,  
--sum(round((curr_price * d.cr_shipped),2)) * -1 as mer_tot,  
0 as net_amt,  
0 as freight,  
0 as tax,  
--sum(round(((d.curr_price*(1-(d.discount/100)) * d.cr_shipped)),2)) * -1 as mer_disc,  
--sum(round(((d.curr_price*(1-(d.discount/100)) * d.cr_shipped)),2))  * -1 as inv_due,
-- START v2.8  
sum(d.cr_shipped * ROUND(curr_price -(curr_price * ((CASE WHEN d.curr_price > c.list_price THEN 0 ELSE d.discount END) / 100)),2,1)) * -1 as mer_disc,  
--sum(d.cr_shipped * ROUND(curr_price -(curr_price * (d.discount / 100)),2,1)) * -1 as mer_disc,  
sum(d.cr_shipped * ROUND(curr_price -(curr_price * ((CASE WHEN d.curr_price > c.list_price THEN 0 ELSE d.discount END) / 100)),2,1)) * -1 as inv_due,  
--sum(d.cr_shipped * ROUND(curr_price -(curr_price * (d.discount / 100)),2,1)) * -1 as inv_due,  
-- END v2.8
-- p.disc_perc,  
--disc_perc = CASE WHEN max(d.discount) > 0 THEN max(d.discount/100) ELSE p.disc_perc END,  
-- START v2.8
CASE WHEN sum(CASE WHEN d.curr_price > c.list_price THEN d.curr_price ELSE c.list_price END) = 0 then 0 
	when (CASE WHEN d.curr_price > c.list_price THEN 0 ELSE d.discount END) > 0 and (CASE WHEN d.curr_price > c.list_price THEN 0 ELSE p.disc_perc END) <> 0 then -- two levels of discount in play
		round(1 - (sum(d.cr_shipped*round(curr_price-(curr_price*((CASE WHEN d.curr_price > c.list_price THEN 0 ELSE (CASE WHEN d.curr_price > c.list_price THEN 0 ELSE d.discount END) END)/100)),2)) 
		/
		sum(round(((CASE WHEN d.curr_price > c.list_price THEN d.curr_price ELSE c.list_price END) * d.cr_shipped),2)) ), 2)
	WHEN (CASE WHEN d.curr_price > c.list_price THEN 0 ELSE d.discount END) > 0 AND (CASE WHEN d.curr_price > c.list_price THEN 0 ELSE p.disc_perc END) = 0 THEN 
		(CASE WHEN d.curr_price > c.list_price THEN 0 ELSE d.discount END) /100 
	ELSE (CASE WHEN d.curr_price > c.list_price THEN 0 ELSE p.disc_perc END) END
	AS disc_perc,    
/*
disc_perc = CASE WHEN sum(c.list_price) = 0 then 0 
	when d.discount > 0 and p.disc_perc <> 0 then -- two levels of discount in play
		round(1 - (sum(d.cr_shipped*round(curr_price-(curr_price*(d.discount/100)),2)) 
		/
		sum(round((c.list_price * d.cr_shipped),2)) ), 2)
	WHEN D.DISCOUNT > 0 AND P.DISC_PERC = 0 THEN 
		d.discount/100 
	ELSE p.disc_perc END,    
*/
-- END v2.8
--right(convert(varchar(12), dateadd(dd, datediff(dd, '1/1/1753', h.date_shipped) + 639906 + convert(int,right(t.days_due,2)) - 639906, '1/1/1753'),101) ,4)  
--+ '/'+  
--left(convert(varchar(12), dateadd(dd, datediff(dd, '1/1/1753', h.date_shipped) + 639906 + convert(int,right(t.days_due,2)) - 639906, '1/1/1753'),101) ,2)  
right(convert(varchar(12),dateadd(dd,max(x.date_due)-639906,'1/1/1753'),101),4)    
+ '/'+  
left(convert(varchar(12),dateadd(dd,max(x.date_due)-639906,'1/1/1753'),101),2)  
as due_year_month, 
x.date_doc as xinv_date
--convert(int,datediff(dd,'1/1/1753',h.date_shipped) + 639906) as xinv_date
-- ,SUM(CASE d.part_no WHEN 'Credit Return Fee' THEN (d.cr_shipped * ROUND(curr_price -(curr_price * (d.discount / 100)),2,1)) ELSE 0 END) * -1 AS ndd -- v2.1  -- v2.4
from 
cvo_orders_all cv (NOLOCK) -- v2.6

JOIN orders h (nolock)  
ON   h.order_no = cv.order_no  -- v2.6
AND  h.ext = cv.ext   -- v2.6
join orders_invoice i (nolock) on h.order_no =i.order_no and h.ext = i.order_ext  
join artrx x (nolock) on i.doc_ctrl_num = x.doc_ctrl_num and x.trx_type = 2032  
--left join arnarel r (nolock) on h.cust_code = r.child  
--left join arcust m (nolock)on r.parent = m.customer_code
JOIN arcust bg (nolock) ON bg.customer_code = cv.buying_group  
join arcust B (nolock)on h.cust_code = b.customer_code  
join ord_list d (nolock) on h.order_no = d.order_no and h.ext = d.order_ext  
join Cvo_ord_list c (nolock) on  d.order_no =c.order_no and d.order_ext = c.order_ext and d.line_no = c.line_no  
join CVO_disc_percent p (nolock) on d.order_no = p.order_no and d.order_ext = p.order_ext and d.line_no = p.line_no  
join arterms t (nolock) on h.terms = t.terms_code  

WHERE cv.buying_group > '' -- v2.6
and d.cr_shipped > 0  
--and (d.display_line  <> 1 or (h.freight = 0 and h.total_tax = 0))  
and h.type = 'C'  
and h.terms not like 'INS%'   
and x.void_flag <> 1     --v2.0 
AND d.part_no <> 'Credit Return Fee' -- v2.4 

-- v2.6 AND dbo.f_cvo_get_buying_group(h.cust_code, CONVERT(varchar(10),DATEADD(DAY, x.date_doc - 693596, '01/01/1900'),121)) > '' -- v2.5

group by cv.buying_group, bg.customer_name, h.cust_code, b.customer_name, i.doc_ctrl_num, t.days_due, x.date_due, h.type, -- v2.6 
-- START v2.8
x.date_doc, (CASE WHEN d.curr_price > c.list_price THEN 0 ELSE d.discount END), (CASE WHEN d.curr_price > c.list_price THEN 0 ELSE p.disc_perc END)  
--x.date_doc, d.discount, disc_perc 
-- END v2.8
  
union  all
  
-- 5 -- AR only records invoice  
select   
dbo.f_cvo_get_buying_group(h.customer_code, CONVERT(varchar(10),DATEADD(DAY, h.date_doc - 693596, '01/01/1900'),121)) parent, -- v2.5
-- v2.5 r.parent,       
dbo.f_cvo_get_buying_group_name	(dbo.f_cvo_get_buying_group(h.customer_code, CONVERT(varchar(10),DATEADD(DAY, h.date_doc - 693596, '01/01/1900'),121))) parent_name, -- v2.5
-- v2.5 m.customer_name as parent_name, 
h.customer_code,  
b.customer_name as customer_name,  
h.doc_ctrl_num,  
t.days_due as trm,  
'Invoice' as type,
--case when h.trx_type = 2031 then 'Invoice' else 'Credit' end as type,  
--h.date_doc as inv_date,  
convert(varchar(12),dateadd(dd,h.date_doc - 639906,'1/1/1753'),101) as inv_date,  
case when d.sequence_id = 1 then round((d.unit_price * d.qty_shipped) + h.amt_tax  + h.amt_freight  ,2)
      else round((d.unit_price * d.qty_shipped),2)  
end as inv_tot,  
round((d.unit_price * d.qty_shipped),2) as mer_tot,  
0 as net_amt,  
case when d.sequence_id  = 1 then h.amt_freight else 0  end as freight,  
case when d.sequence_id  = 1 then h.amt_tax   else 0  end as tax,  
(d.unit_price * d.qty_shipped)- d.discount_amt as mer_disc,  
case when d.sequence_id = 1 then round((d.unit_price * d.qty_shipped)- d.discount_amt + h.amt_tax  + h.amt_freight  ,2)  
      else round((d.unit_price * d.qty_shipped)-d.discount_amt,2)  
end as inv_due,  
-- d.discount_prc,  
d.discount_prc/100,  
SUBSTRING(convert(varchar(12),dateadd(dd,h.date_due - 639906,'1/1/1753'),101),7,4)  
+ '/'+  
SUBSTRING(convert(varchar(12),dateadd(dd,h.date_due - 639906,'1/1/1753'),101),1,2)  
as due_year_month,  
h.date_doc as xinv_date
-- ,NULL as ndd -- v2.1    -- v2.4
from artrx_all h (nolock)  
join artrxcdt d (nolock) on h.trx_ctrl_num = d.trx_ctrl_num  
--left join arnarel r (nolock) on h.customer_code = r.child  
--left join arcust m (nolock)on r.parent = m.customer_code  
join arcust B (nolock)on h.customer_code = b.customer_code  
join arterms t (nolock) on h.terms_code = t.terms_code  
where (h.order_ctrl_num = '' or left(h.doc_desc,3) not in ('SO:', 'CM:'))  
and h.trx_type in (2031)  
and h.doc_ctrl_num not like 'FIN%'   
and h.doc_ctrl_num not like 'CB%'   
and h.terms_code not like 'INS%'   
and h.void_flag <> 1     --v2.0  
AND dbo.f_cvo_get_buying_group(h.customer_code, CONVERT(varchar(10),DATEADD(DAY, h.date_doc - 693596, '01/01/1900'),121)) > '' -- v2.5

  
union  all
  
-- 6 -- AR only records credit  
select   
dbo.f_cvo_get_buying_group(h.customer_code, CONVERT(varchar(10),DATEADD(DAY, h.date_doc - 693596, '01/01/1900'),121)) parent, -- v2.5
-- v2.5 r.parent,          
dbo.f_cvo_get_buying_group_name	(dbo.f_cvo_get_buying_group(h.customer_code, CONVERT(varchar(10),DATEADD(DAY, h.date_doc - 693596, '01/01/1900'),121))) parent_name, -- v2.5
-- v2.5 m.customer_name as parent_name, 
h.customer_code,  
b.customer_name as customer_name,  
h.doc_ctrl_num,  
t.days_due as trm,  
'Credit' as type,
--case when h.trx_type = 2031 then 'Invoice' else 'Credit' end as type,  
--h.date_doc as inv_date,  
convert(varchar(12),dateadd(dd,h.date_doc - 639906,'1/1/1753'),101) as inv_date,  
case when d.sequence_id = 1 then case when h.recurring_flag = 2 then h.amt_tax*-1  
          when h.recurring_flag = 3 then h.amt_freight*-1  
          when h.recurring_flag = 4 then round(h.amt_tax + h.amt_freight,2)*-1  
          else round((d.unit_price * d.qty_returned) + h.amt_tax  + h.amt_freight  ,2)*-1 end  
            
      else round((d.unit_price * d.qty_returned),2)*-1  
--case when d.sequence_id = 1 then round((d.unit_price * d.qty_returned) + h.amt_tax  + h.amt_freight  ,2)*-1  
--      else round((d.unit_price * d.qty_returned),2)*-1  
end as inv_tot,  
case when h.recurring_flag < 2 then round((d.unit_price * d.qty_returned),2)*-1   
  else 0.0 end as mer_tot,  
--round((d.unit_price * d.qty_returned),2)*-1 as mer_tot,  
0 as net_amt,  
case   
when d.sequence_id  = 1 and h.recurring_flag in (1,3,4) then h.amt_freight *-1  -- v2.3 add recurring_flag 1 
else 0  
end as freight,  
case   
when d.sequence_id  = 1 and h.recurring_flag in (1,2,4) then h.amt_tax*-1   -- v2.3 add recurring_flag 1
else 0  
end as tax,  
case when h.recurring_flag < 2 then ((d.unit_price * d.qty_returned)-d.discount_amt)*-1   
  else 0.0 end as mer_disc,  
--((d.unit_price * d.qty_returned)-d.discount_amt)*-1 as mer_disc,  
case when d.sequence_id = 1 then case when h.recurring_flag = 2 then h.amt_tax*-1  
          when h.recurring_flag = 3 then h.amt_freight*-1  
          when h.recurring_flag = 4 then round(h.amt_tax + h.amt_freight,2)*-1  
          else round((d.unit_price * d.qty_returned)-d.discount_amt + h.amt_tax  + h.amt_freight  ,2)*-1 end  
      else round((d.unit_price * d.qty_returned)-d.discount_amt,2)*-1  
--case when d.sequence_id = 1 then round((d.unit_price * d.qty_returned)-d.discount_amt + h.amt_tax  + h.amt_freight  ,2)*-1  
--      else round((d.unit_price * d.qty_returned)-d.discount_amt,2)*-1  
end as inv_due,  
-- d.discount_prc,  
d.discount_prc/100,  
CASE h.date_due WHEN 0 THEN  
 SUBSTRING(CONVERT(varchar(10),dateadd(dd,h.date_doc - 639906,'1/1/1753'),101),7,4)  
 +'/'+ SUBSTRING(CONVERT(varchar(10),dateadd(dd,h.date_doc - 639906,'1/1/1753'),101),1,2)  
ELSE SUBSTRING(CONVERT(varchar(10),dateadd(dd,h.date_due - 639906,'1/1/1753'),101),7,4)  
 +'/'+ SUBSTRING(CONVERT(varchar(10),dateadd(dd,h.date_due - 639906,'1/1/1753'),101),1,2)  
END as due_year_month,  
h.date_doc as xinv_date
--,NULL as ndd -- v2.1    -- v2.4
from artrx_all h (nolock)  
join artrxcdt d (nolock) on h.trx_ctrl_num = d.trx_ctrl_num  
--left join arnarel r (nolock) on h.customer_code = r.child  
--left join arcust m (nolock)on r.parent = m.customer_code  
join arcust B (nolock)on h.customer_code = b.customer_code  
left join arterms t (nolock) on b.terms_code = t.terms_code    --v3.0 Use Customer Terms as CM does not have terms code  
where left(h.doc_desc,3) not in ('SO:', 'CM:')  
and h.trx_type in (2032)  
and h.doc_ctrl_num not like 'FIN%'   
and h.doc_ctrl_num not like 'CB%'   
-- and h.terms_code not like 'INS%' -- tag - don't care about terms on a credit memo  
and h.void_flag <> 1     --v2.0  
and ((recurring_flag < 2) or (recurring_flag > 1 and d.sequence_id = 1))  
AND dbo.f_cvo_get_buying_group(h.customer_code, CONVERT(varchar(10),DATEADD(DAY, h.date_doc - 693596, '01/01/1900'),121)) > '' -- v2.5
-- START v2.7
and not exists (select 1 from cvo_debit_promo_customer_det where trx_ctrl_num = h.trx_ctrl_num)
-- END v2.7

union  all
  
-- 6 AR Split only records  *** NEW ***  
select   
parent,     
parent_name,                                
cust_code,    
customer_name,                              
doc_ctrl_num,   
trm,  
type,      
inv_date,       
inv_tot,                                   
mer_tot,                                   
net_amt,       
freight,                                   
tax,                                       
mer_disc,                                  
inv_due,                                   
disc_perc,                                 
due_year_month,   
xinv_date
-- ,NULL as ndd -- v2.1      -- v2.4
from CVO_BGLog_installment_source_vw (nolock)  
  
-- START v2.7
union all

-- 8 -- cr debit promo tax line  
select   
cv.buying_group parent, -- v1.2  
--dbo.f_cvo_get_buying_group_name	(cv.buying_group) parent_name, -- v1.2  
bg.customer_name parent_name,
b.customer_code cust_code,  
b.customer_name as customer_name,  
x.doc_ctrl_num,  
t.days_due as trm,  
'Credit' as type, 
convert(varchar(12),dateadd(d,x.date_doc-639906,'1/1/1753'),101) as inv_date,
round((x.amt_tax)  ,2) * -1  as inv_tot,  
0 as mer_tot,  
0 as net_amt,  
0 as freight,  
x.amt_tax * -1 as tax,  
0 as mer_disc,  
round(x.amt_tax ,2) * -1 as inv_due,  
0 as disc_perc,  CASE   x.date_due WHEN 0 THEN
	right(convert(varchar(12),dateadd(dd,(x.date_doc)-639906,'1/1/1753'),101),4)      
	+ '/'+    
	left(convert(varchar(12),dateadd(dd,(x.date_doc)-639906,'1/1/1753'),101),2) 
ELSE  
	right(convert(varchar(12),dateadd(dd,(x.date_due)-639906,'1/1/1753'),101),4)      
	+ '/'+    
	left(convert(varchar(12),dateadd(dd,(x.date_due)-639906,'1/1/1753'),101),2) 
END
as due_year_month,  
x.date_doc as xinv_date
-- ,3 as rec_type -- v1.0

from 
(select distinct dd.trx_ctrl_num, co.order_no, co.ext, buying_group from  cvo_debit_promo_customer_det dd inner join  cvo_orders_all co on dd.order_no = co.order_no and dd.ext = co.ext) cv 
join artrx x (nolock) on cv.trx_ctrl_num = x.trx_ctrl_num
-- left join arnarel r (nolock) on r.child = x.customer_code
join arcust B (nolock) on b.customer_code  = x.customer_code
JOIN arcust bg (NOLOCK) ON bg.customer_code = cv.buying_group
join arterms t (nolock) on b.terms_code = t.terms_code  
where (x.amt_tax <> 0) 
and x.trx_type = 2032
and x.terms_code not like 'INS%'   
and x.void_flag <> 1     
AND cv.buying_group > '' -- v1.2

  
union  all
  
--  4 -- cr order lines - debit promos 
select   
cv.buying_group parent, -- v1.2  
-- dbo.f_cvo_get_buying_group_name	(cv.buying_group) parent_name, -- v1.2   
bg.customer_name parent_name,
h.cust_code,  
b.customer_name as customer_name,  
xx.doc_ctrl_num,  
t.days_due as trm,  
'Credit' as type,  
convert(varchar(12),dateadd(d,x.date_doc-639906,'1/1/1753'),101) as inv_date,
--convert(varchar(12), h.date_shipped, 101)  as inv_date, 
-- START v2.8 
sum(round(((CASE WHEN d.curr_price > c.list_price THEN d.curr_price ELSE c.list_price END) * d.shipped),2)) * -1 as inv_tot,  
--sum(round((c.list_price * d.shipped),2)) * -1 as inv_tot,  
sum(round(((CASE WHEN d.curr_price > c.list_price THEN d.curr_price ELSE c.list_price END) * d.shipped),2)) * -1 as mer_tot,  
--sum(round((c.list_price * d.shipped),2)) * -1 as mer_tot,  
-- END v2.8
0 as net_amt,  
0 as freight,  
0 as tax,  
-- START v2.8
case when sum(dd.credit_amount) <= sum(d.shipped * ROUND(curr_price -(curr_price * ((CASE WHEN d.curr_price > c.list_price THEN 0 ELSE d.discount END) / 100)),2,1))
then sum(dd.credit_amount) * -1
else
    sum(d.shipped * ROUND(curr_price -(curr_price * ((CASE WHEN d.curr_price > c.list_price THEN 0 ELSE d.discount END) / 100)),2,1)) * -1
end as mer_disc,  
/*
case when sum(dd.credit_amount) <= sum(d.shipped * ROUND(curr_price -(curr_price * (d.discount / 100)),2,1))
then sum(dd.credit_amount) * -1
else
    sum(d.shipped * ROUND(curr_price -(curr_price * (d.discount / 100)),2,1)) * -1
end as mer_disc, 
*/
case when sum(dd.credit_amount) <= sum(d.shipped * ROUND(curr_price -(curr_price * ((CASE WHEN d.curr_price > c.list_price THEN 0 ELSE d.discount END) / 100)),2,1)) 
then sum(dd.credit_amount) * -1
else
sum(d.shipped * ROUND(curr_price -(curr_price * ((CASE WHEN d.curr_price > c.list_price THEN 0 ELSE d.discount END) / 100)),2,1)) * -1
end as inv_due,  
/*
case when sum(dd.credit_amount) <= sum(d.shipped * ROUND(curr_price -(curr_price * (d.discount / 100)),2,1)) 
then sum(dd.credit_amount) * -1
else
sum(d.shipped * ROUND(curr_price -(curr_price * (d.discount / 100)),2,1)) * -1
end as inv_due,  
*/
CASE 	when SUM(CASE WHEN d.curr_price > c.list_price THEN d.curr_price ELSE c.list_price END) = 0 then 0
	WHEN (CASE WHEN d.curr_price > c.list_price THEN 0 ELSE d.discount END) > 0 and (CASE WHEN d.curr_price > c.list_price THEN 0 ELSE p.disc_perc END) <> 0 then -- two levels of discount in play
		round(1 - (sum(d.shipped*round(curr_price-(curr_price*((CASE WHEN d.curr_price > c.list_price THEN 0 ELSE d.discount END)/100)),2)) 
		/
		sum(round(((CASE WHEN d.curr_price > c.list_price THEN d.curr_price ELSE c.list_price END) * d.shipped),2)) ), 2)
	WHEN (CASE WHEN d.curr_price > c.list_price THEN 0 ELSE d.discount END) > 0 AND (CASE WHEN d.curr_price > c.list_price THEN 0 ELSE p.disc_perc END) = 0 THEN 
		(CASE WHEN d.curr_price > c.list_price THEN 0 ELSE d.discount END)/100 
	ELSE (CASE WHEN d.curr_price > c.list_price THEN 0 ELSE p.disc_perc END) END
	AS disc_perc,
/*
disc_perc = CASE 	when suM(c.list_price) = 0 then 0
	WHEN d.discount > 0 and p.disc_perc <> 0 then -- two levels of discount in play
		round(1 - (sum(d.shipped*round(curr_price-(curr_price*(d.discount/100)),2)) 
		/
		sum(round((c.list_price * d.shipped),2)) ), 2)
	WHEN D.DISCOUNT > 0 AND P.DISC_PERC = 0 THEN 
		d.discount/100 
	ELSE p.disc_perc END, 
*/
-- END v2.8
CASE MAX(x.date_due) WHEN 0 THEN
	right(convert(varchar(12),dateadd(dd,MAX(x.date_doc)-639906,'1/1/1753'),101),4)      
	+ '/'+    
	left(convert(varchar(12),dateadd(dd,MAX(x.date_doc)-639906,'1/1/1753'),101),2) 
ELSE  
	right(convert(varchar(12),dateadd(dd,MAX(x.date_due)-639906,'1/1/1753'),101),4)      
	+ '/'+    
	left(convert(varchar(12),dateadd(dd,MAX(x.date_due)-639906,'1/1/1753'),101),2) 
END
-- END v1.0 
as due_year_month,  
x.date_doc as xinv_date
-- ,3 as rec_type -- v1.0
from
cvo_debit_promo_customer_det dd 
inner join ord_list d (nolock) on d.order_no = dd.order_no and d.order_ext = dd.ext and d.line_no = dd.line_no

inner join orders h (nolock)  on h.order_no = dd.order_no and h.ext = dd.ext
JOIN cvo_orders_all cv (NOLOCK) -- v1.2
ON   h.order_no = cv.order_no  -- v1.2
AND  h.ext = cv.ext   -- v1.2
join artrx xx on dd.trx_ctrl_num = xx.trx_ctrl_num
join orders_invoice i (nolock) on h.order_no =i.order_no and h.ext = i.order_ext  
join artrx x (nolock) on i.trx_ctrl_num = x.trx_ctrl_num   
--left join arnarel r (nolock) on h.cust_code = r.child  
--left join arcust m (nolock)on r.parent = m.customer_code  
JOIN arcust bg (NOLOCK) ON bg.customer_code = cv.buying_group
join arcust B (nolock)on h.cust_code = b.customer_code  
join Cvo_ord_list c (nolock) on  d.order_no =c.order_no and d.order_ext = c.order_ext and d.line_no = c.line_no  
join CVO_disc_percent p (nolock) on d.order_no = p.order_no and d.order_ext = p.order_ext and d.line_no = p.line_no  
join arterms t (nolock) on h.terms = t.terms_code  

WHERE cv.buying_group > '' -- v1.2 
AND d.shipped > 0  
and h.terms not like 'INS%'   
and x.void_flag <> 1     


group by cv.buying_group, bg.customer_name, h.cust_code, b.customer_name, xx.doc_ctrl_num, t.days_due, x.date_due, h.type, -- v1.2
-- START v2.8
x.date_doc, (CASE WHEN d.curr_price > c.list_price THEN 0 ELSE d.discount END), (CASE WHEN d.curr_price > c.list_price THEN 0 ELSE p.disc_perc END)  
--x.date_doc, d.discount, disc_perc  
-- END v2.8
-- END v2.7

-- v2.9 Start
UNION all

select   
dbo.f_cvo_get_buying_group(h.customer_code, CONVERT(varchar(10),DATEADD(DAY, h.date_doc - 693596, '01/01/1900'),121)) parent, -- v1.1
dbo.f_cvo_get_buying_group_name	(dbo.f_cvo_get_buying_group(h.customer_code, CONVERT(varchar(10),DATEADD(DAY, h.date_doc - 693596, '01/01/1900'),121))) parent_name, -- v1.1  
h.customer_code,  
b.customer_name as customer_name,  
h.doc_ctrl_num,  
0 as trm,  
case when h.trx_type = 2061 then 'Finance Charge' when h.trx_type = 2071 then 'Late Charge' else '' end as type,   
convert(varchar(12),dateadd(dd,h.date_doc - 639906,'1/1/1753'),101) as inv_date,  
h.amt_tot_chg inv_tot,  
h.amt_tot_chg as mer_tot,  
0 as net_amt,  
0 as freight,  
0 tax,  
0 as mer_disc,  
h.amt_tot_chg as inv_due,  
0, 
CASE   h.date_due WHEN 0 THEN
	right(convert(varchar(12),dateadd(dd,(h.date_doc)-639906,'1/1/1753'),101),4)      
	+ '/'+    
	left(convert(varchar(12),dateadd(dd,(h.date_doc)-639906,'1/1/1753'),101),2) 
ELSE  
	right(convert(varchar(12),dateadd(dd,(h.date_due)-639906,'1/1/1753'),101),4)      
	+ '/'+    
	left(convert(varchar(12),dateadd(dd,(h.date_due)-639906,'1/1/1753'),101),2) 
END
as due_year_month,  
h.date_doc as xinv_date
from artrx_all h (nolock)  
--left join arnarel r (nolock) on h.customer_code = r.child  
--left join arcust m (nolock)on r.parent = m.customer_code  
join arcust B (nolock)on h.customer_code = b.customer_code  
where h.trx_type in (2061,2071)  
and h.doc_ctrl_num not like 'CB%'   
and h.terms_code not like 'INS%'   
and h.void_flag <> 1  
AND dbo.f_cvo_get_buying_group(h.customer_code, CONVERT(varchar(10),DATEADD(DAY, h.date_doc - 693596, '01/01/1900'),121)) > '' 

UNION all

select   
dbo.f_cvo_get_buying_group(h.customer_code, CONVERT(varchar(10),DATEADD(DAY, h.date_doc - 693596, '01/01/1900'),121)) parent, -- v1.1
dbo.f_cvo_get_buying_group_name	(dbo.f_cvo_get_buying_group(h.customer_code, CONVERT(varchar(10),DATEADD(DAY, h.date_doc - 693596, '01/01/1900'),121))) parent_name, -- v1.1  
h.customer_code,  
b.customer_name as customer_name,  
h.doc_ctrl_num,  
0 as trm,  
case when h.trx_type = 2061 then 'Finance Charge' when h.trx_type = 2071 then 'Late Charge' else '' end as type,   
convert(varchar(12),dateadd(dd,h.date_doc - 639906,'1/1/1753'),101) as inv_date,  
h.amt_tot_chg inv_tot,  
h.amt_tot_chg as mer_tot,  
0 as net_amt,  
0 as freight,  
0 tax,  
0 as mer_disc,  
h.amt_tot_chg as inv_due,  
0, 
CASE   h.date_due WHEN 0 THEN
	right(convert(varchar(12),dateadd(dd,(h.date_doc)-639906,'1/1/1753'),101),4)      
	+ '/'+    
	left(convert(varchar(12),dateadd(dd,(h.date_doc)-639906,'1/1/1753'),101),2) 
ELSE  
	right(convert(varchar(12),dateadd(dd,(h.date_due)-639906,'1/1/1753'),101),4)      
	+ '/'+    
	left(convert(varchar(12),dateadd(dd,(h.date_due)-639906,'1/1/1753'),101),2) 
END
as due_year_month,  
h.date_doc as xinv_date
from artrx_all h (nolock)  
--left join arnarel r (nolock) on h.customer_code = r.child  
--left join arcust m (nolock)on r.parent = m.customer_code  
join arcust B (nolock)on h.customer_code = b.customer_code  
where h.trx_ctrl_num like 'CB%'   
and h.terms_code not like 'INS%'   
and h.void_flag <> 1  
AND dbo.f_cvo_get_buying_group(h.customer_code, CONVERT(varchar(10),DATEADD(DAY, h.date_doc - 693596, '01/01/1900'),121)) > '' 
-- v2.9 End



GO
GRANT REFERENCES ON  [dbo].[CVO_BGLog_source_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[CVO_BGLog_source_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[CVO_BGLog_source_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[CVO_BGLog_source_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[CVO_BGLog_source_vw] TO [public]
GO
