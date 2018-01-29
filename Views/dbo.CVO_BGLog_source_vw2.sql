SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

  
  
CREATE view [dbo].[CVO_BGLog_source_vw2] as  
-- v1.0 CT 16/04/13 - New view created based on cvo_BGLog_source_vw to return credit fees details along with existing info. Called from CVO_BGLog_vw
-- v1.1 CB 23/07/2013 - Issue #927 - Buying Group Switching
-- v1.2 CB 18/09/2013 - Issue #927 - Buying Group Switching - RB Orders set to and from buying group
-- v1.3 CHANGES BY CVO
-- v1.4	CT 20/10/2014 - Issue #1367 - For Sales Orders and Credit Returns, if net price > list price, set list = net and discount = 0 and disc_perc = 0
-- v1.5 CB 12/03/2015 - Issue #1469 - Deal with finance and late charges and chargebacks
-- v1.6 CB 30/04/2015 - For credits do not check terms code
-- v1.7 CB 05/05/2015 - Issue #1538 - Not displaying free frames correctly for BGs
-- v1.8 CB 22/01/2018 - Fix issue for BG when promo or discount applied

  
-- 1 -- order h  
select   
-- v1.2 dbo.f_cvo_get_buying_group(h.cust_code, CONVERT(varchar(10),DATEADD(DAY, x.date_doc - 693596, '01/01/1900'),121)) parent, -- v1.1
-- v1.2 dbo.f_cvo_get_buying_group_name	(dbo.f_cvo_get_buying_group(h.cust_code, CONVERT(varchar(10),DATEADD(DAY, x.date_doc - 693596, '01/01/1900'),121))) parent_name, -- v1.1  
cv.buying_group parent, -- v1.2  
dbo.f_cvo_get_buying_group_name	(cv.buying_group) parent_name, -- v1.2  
-- v1.1 r.parent,   
-- v1.1 m.customer_name as parent_name,   
h.cust_code,  
b.customer_name as customer_name,  
i.doc_ctrl_num,  
t.days_due as trm,  
case when h.type = 'I' then 'Invoice' else 'Credit' end as type, 
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
-- START v1.0 - fix issue casued by 0 date_due
CASE   x.date_due WHEN 0 THEN
	right(convert(varchar(12),dateadd(dd,(x.date_doc)-639906,'1/1/1753'),101),4)      
	+ '/'+    
	left(convert(varchar(12),dateadd(dd,(x.date_doc)-639906,'1/1/1753'),101),2) 
ELSE  
	right(convert(varchar(12),dateadd(dd,(x.date_due)-639906,'1/1/1753'),101),4)      
	+ '/'+    
	left(convert(varchar(12),dateadd(dd,(x.date_due)-639906,'1/1/1753'),101),2) 
END
-- END v1.0
as due_year_month,  
x.date_doc as xinv_date,
-- convert(int,datediff(dd,'1/1/1753',h.date_shipped) + 639906) as xinv_date,
1 as rec_type -- v1.0
from orders h (nolock)  
join orders_invoice i (nolock) on h.order_no =i.order_no and h.ext = i.order_ext  
--join artrx x (nolock) on i.doc_ctrl_num = x.doc_ctrl_num  
join artrx x (nolock) on i.trx_ctrl_num = x.trx_ctrl_num  
--join ord_list d (nolock) on h.order_no = d.order_no and h.ext = d.order_ext  
left join arnarel r (nolock) on h.cust_code = r.child  
left join arcust m (nolock)on r.parent = m.customer_code  
join arcust B (nolock)on h.cust_code = b.customer_code  
--join Cvo_ord_list c (nolock) on  d.order_no =c.order_no and d.order_ext = c.order_ext and d.line_no = c.line_no  
--join CVO_disc_percent p (nolock) on d.order_no = p.order_no and d.order_ext = p.order_ext and d.line_no = p.line_no  
join arterms t (nolock) on  h.terms = t.terms_code  
--join CVO_min_display_vw z (nolock) on z.order_no = d.order_no and h.ext = z.order_ext and d.display_line = z.min_line  
JOIN cvo_orders_all cv (NOLOCK) -- v1.2
ON   h.order_no = cv.order_no  -- v1.2
AND  h.ext = cv.ext   -- v1.2
where (h.freight <> 0 or h.total_tax <> 0)  
and h.type = 'I'  
and h.terms not like 'INS%'   
and x.void_flag <> 1 
AND cv.buying_group > '' -- v1.2   
-- v1.2 AND dbo.f_cvo_get_buying_group(h.cust_code, CONVERT(varchar(10),DATEADD(DAY, x.date_doc - 693596, '01/01/1900'),121)) > '' -- v1.1


  
union  
  
-- 2 -- order lines  
select   
-- v1.2 dbo.f_cvo_get_buying_group(h.cust_code, CONVERT(varchar(10),DATEADD(DAY, x.date_doc - 693596, '01/01/1900'),121)) parent, -- v1.1
-- v1.2 dbo.f_cvo_get_buying_group_name	(dbo.f_cvo_get_buying_group(h.cust_code, CONVERT(varchar(10),DATEADD(DAY, x.date_doc - 693596, '01/01/1900'),121))) parent_name, -- v1.1  
cv.buying_group parent, -- v1.2  
dbo.f_cvo_get_buying_group_name	(cv.buying_group) parent_name, -- v1.2  
-- v1.1 r.parent,   
-- v1.1 m.customer_name as parent_name,    
h.cust_code,  
b.customer_name as customer_name,  
i.doc_ctrl_num,  
t.days_due as trm,  
case when h.type = 'I' then 'Invoice' else 'Credit' end as type,   
convert(varchar(12),dateadd(d,x.date_doc-639906,'1/1/1753'),101) as inv_date,
--convert(varchar(12), h.date_shipped, 101) as inv_date,  
-- START v1.4
-- v1.8 Start
sum( CASE WHEN c.free_frame = 1 THEN 0 ELSE 
		CASE WHEN cv.promo_id <> '' THEN ROUND(((d.curr_price - c.amt_disc) * d.shipped),2) ELSE CASE WHEN d.discount <> 0 THEN ROUND(((d.curr_price - c.amt_disc) * d.shipped),2) ELSE
		round(((CASE WHEN d.curr_price > c.list_price THEN d.curr_price ELSE c.list_price END) * d.shipped),2) END END END) as inv_tot, -- v1.7
sum( CASE WHEN c.free_frame = 1 THEN 0 ELSE 
	CASE WHEN cv.promo_id <> '' THEN ROUND(((d.curr_price - c.amt_disc) * d.shipped),2) ELSE CASE WHEN d.discount <> 0 THEN ROUND(((d.curr_price - c.amt_disc) * d.shipped),2) ELSE
round(((CASE WHEN d.curr_price > c.list_price THEN d.curr_price ELSE c.list_price END) * d.shipped),2) END END END ) as mer_tot,  -- v1.7
--sum( CASE WHEN c.free_frame = 1 THEN 0 ELSE round(((CASE WHEN d.curr_price > c.list_price THEN d.curr_price ELSE c.list_price END) * d.shipped),2) END) as inv_tot, -- v1.7
--sum(round((c.list_price * d.shipped),2)) as inv_tot,   
--sum( CASE WHEN c.free_frame = 1 THEN 0 ELSE round(((CASE WHEN d.curr_price > c.list_price THEN d.curr_price ELSE c.list_price END) * d.shipped),2) END ) as mer_tot,  -- v1.7
-- v1.8 End
--sum(round((c.list_price * d.shipped),2)) as mer_tot,    
-- END v1.4
0 as net_amt,  
0 as freight,  
0 as tax,   
-- START v1.4 
sum(d.Shipped * ROUND(curr_price -(curr_price * ((CASE WHEN d.curr_price > c.list_price THEN 0 ELSE d.discount END) / 100)),2)) as mer_disc,  
--sum(d.Shipped * ROUND(curr_price -(curr_price * (d.discount / 100)),2)) as mer_disc,  
sum(d.Shipped * ROUND(curr_price -(curr_price * ((CASE WHEN d.curr_price > c.list_price THEN 0 ELSE d.discount END) / 100)),2)) as inv_due,  
--sum(d.Shipped * ROUND(curr_price -(curr_price * (d.discount / 100)),2)) as inv_due,  
-- END v1.4
-- disc_perc = CASE WHEN round(d.discount,2) > 0 THEN round(d.discount/100,2) ELSE p.disc_perc END,  
-- START v1.4
-- v1.8 Start
disc_perc = CASE WHEN MAX(cv.promo_id) <> '' THEN 0 ELSE CASE WHEN SUM(d.discount) <> 0 THEN 0 ELSE
	CASE when SUM((CASE WHEN d.curr_price > c.list_price THEN d.curr_price ELSE c.list_price END)) = 0 then 0
	WHEN (CASE WHEN d.curr_price > c.list_price THEN 0 ELSE d.discount END) > 0 and (CASE WHEN d.curr_price > c.list_price THEN 0 ELSE p.disc_perc END) <> 0 then -- two levels of discount in play
		round(1 - (sum(d.shipped*round(curr_price-(curr_price*((CASE WHEN d.curr_price > c.list_price THEN 0 ELSE d.discount END)/100)),2)) 
		/
		sum(round(((CASE WHEN d.curr_price > c.list_price THEN d.curr_price ELSE c.list_price END) * d.shipped),2)) ), 2)
	WHEN (CASE WHEN d.curr_price > c.list_price THEN 0 ELSE d.discount END) > 0 AND (CASE WHEN d.curr_price > c.list_price THEN 0 ELSE p.disc_perc END) = 0 THEN 
		(CASE WHEN d.curr_price > c.list_price THEN 0 ELSE d.discount END)/100 
	ELSE (CASE WHEN d.curr_price > c.list_price THEN 0 ELSE p.disc_perc END) END END END,
--disc_perc = CASE 	when SUM((CASE WHEN d.curr_price > c.list_price THEN d.curr_price ELSE c.list_price END)) = 0 then 0
--	WHEN (CASE WHEN d.curr_price > c.list_price THEN 0 ELSE d.discount END) > 0 and (CASE WHEN d.curr_price > c.list_price THEN 0 ELSE p.disc_perc END) <> 0 then -- two levels of discount in play
--		round(1 - (sum(d.shipped*round(curr_price-(curr_price*((CASE WHEN d.curr_price > c.list_price THEN 0 ELSE d.discount END)/100)),2)) 
--		/
--		sum(round(((CASE WHEN d.curr_price > c.list_price THEN d.curr_price ELSE c.list_price END) * d.shipped),2)) ), 2)
--	WHEN (CASE WHEN d.curr_price > c.list_price THEN 0 ELSE d.discount END) > 0 AND (CASE WHEN d.curr_price > c.list_price THEN 0 ELSE p.disc_perc END) = 0 THEN 
--		(CASE WHEN d.curr_price > c.list_price THEN 0 ELSE d.discount END)/100 
--	ELSE (CASE WHEN d.curr_price > c.list_price THEN 0 ELSE p.disc_perc END) END, 
-- v1.8 End
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
-- END v1.4
-- START v1.0 - fix issue casued by 0 date_due
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
x.date_doc as xinv_date,
-- convert(int,datediff(dd,'1/1/1753',h.date_shipped) + 639906) as xinv_date,
1 as rec_type -- v1.0
from orders h (nolock)  
join orders_invoice i (nolock) on h.order_no =i.order_no and h.ext = i.order_ext  
join artrx x (nolock) on i.doc_ctrl_num = x.doc_ctrl_num  
join ord_list d (nolock) on h.order_no = d.order_no and h.ext = d.order_ext  
left join arnarel r (nolock) on h.cust_code = r.child  
left join arcust m (nolock)on r.parent = m.customer_code  
join arcust B (nolock)on h.cust_code = b.customer_code  
join Cvo_ord_list c (nolock) on  d.order_no =c.order_no and d.order_ext = c.order_ext and d.line_no = c.line_no  
join CVO_disc_percent p (nolock) on d.order_no = p.order_no and d.order_ext = p.order_ext and d.line_no = p.line_no  
join arterms t (nolock) on h.terms = t.terms_code  
JOIN cvo_orders_all cv (NOLOCK) -- v1.2
ON   h.order_no = cv.order_no  -- v1.2
AND  h.ext = cv.ext   -- v1.2
where d.shipped > 0  
and h.type = 'I'  
and h.terms not like 'INS%'   
and x.void_flag <> 1     --v2.0  
AND cv.buying_group > '' -- v1.2
-- v1.2 AND dbo.f_cvo_get_buying_group(h.cust_code, CONVERT(varchar(10),DATEADD(DAY, x.date_doc - 693596, '01/01/1900'),121)) > '' -- v1.1



group by cv.buying_group, m.customer_name, h.cust_code, b.customer_name, i.doc_ctrl_num, t.days_due, h.type, -- v1.2
-- START v1.4
x.date_doc, (CASE WHEN d.curr_price > c.list_price THEN 0 ELSE d.discount END), (CASE WHEN d.curr_price > c.list_price THEN 0 ELSE p.disc_perc END)  
--x.date_doc, d.discount, disc_perc  
-- END v1.4
  
  
  
union   
  
-- 3 -- cr order header  
select   
-- v1.2 dbo.f_cvo_get_buying_group(h.cust_code, CONVERT(varchar(10),DATEADD(DAY, x.date_doc - 693596, '01/01/1900'),121)) parent, -- v1.1
-- v1.2 dbo.f_cvo_get_buying_group_name	(dbo.f_cvo_get_buying_group(h.cust_code, CONVERT(varchar(10),DATEADD(DAY, x.date_doc - 693596, '01/01/1900'),121))) parent_name, -- v1.1  
cv.buying_group parent, -- v1.2  
dbo.f_cvo_get_buying_group_name	(cv.buying_group) parent_name, -- v1.2  
-- v1.1 r.parent,   
-- v1.1 m.customer_name as parent_name,    
h.cust_code,  
b.customer_name as customer_name,  
i.doc_ctrl_num,  
t.days_due as trm,  
case when h.type = 'I' then 'Invoice' else 'Credit' end as type, 
convert(varchar(12),dateadd(d,x.date_doc-639906,'1/1/1753'),101) as inv_date,
-- convert(varchar(12), h.date_shipped, 101) as inv_date,  
round((h.total_tax  + h.freight)  ,2) * -1  
 as inv_tot,  
0 as mer_tot,  
0 as net_amt,  
h.freight * -1 as freight,  
h.total_tax * -1 as tax,  
0 as mer_disc,  
round(h.total_tax  + h.freight ,2) * -1 as inv_due,  
0 as disc_perc,  
-- START v1.0 - fix issue casued by 0 date_due
CASE   x.date_due WHEN 0 THEN
	right(convert(varchar(12),dateadd(dd,(x.date_doc)-639906,'1/1/1753'),101),4)      
	+ '/'+    
	left(convert(varchar(12),dateadd(dd,(x.date_doc)-639906,'1/1/1753'),101),2) 
ELSE  
	right(convert(varchar(12),dateadd(dd,(x.date_due)-639906,'1/1/1753'),101),4)      
	+ '/'+    
	left(convert(varchar(12),dateadd(dd,(x.date_due)-639906,'1/1/1753'),101),2) 
END
-- END v1.0
as due_year_month,  
x.date_doc as xinv_date,
-- convert(int,datediff(dd,'1/1/1753',h.date_shipped) + 639906) as xinv_date,
1 as rec_type -- v1.0
from orders h (nolock)  
join orders_invoice i (nolock) on h.order_no =i.order_no and h.ext = i.order_ext  
--join artrx x (nolock) on i.doc_ctrl_num = x.doc_ctrl_num and x.trx_type = 2032  
join artrx x (nolock) on i.trx_ctrl_num = x.trx_ctrl_num
-- join ord_list d (nolock) on h.order_no = d.order_no and h.ext = d.order_ext  
left join arnarel r (nolock) on h.cust_code = r.child  
left join arcust m (nolock)on r.parent = m.customer_code  
join arcust B (nolock)on h.cust_code = b.customer_code  
--join Cvo_ord_list c (nolock) on  d.order_no =c.order_no and d.order_ext = c.order_ext and d.line_no = c.line_no  
--join CVO_disc_percent p (nolock) on d.order_no = p.order_no and d.order_ext = p.order_ext and d.line_no = p.line_no  
join arterms t (nolock) on h.terms = t.terms_code  
--join CVO_min_display_vw z (nolock) on z.order_no = d.order_no and z.order_ext = d.order_ext and d.display_line = z.min_line  
JOIN cvo_orders_all cv (NOLOCK) -- v1.2
ON   h.order_no = cv.order_no  -- v1.2
AND  h.ext = cv.ext   -- v1.2
where (h.freight <> 0 or h.total_tax <> 0)  
and h.type = 'C'  
-- v1.6 and h.terms not like 'INS%'   
and x.void_flag <> 1     
AND cv.buying_group > '' -- v1.2
-- v1.2 AND dbo.f_cvo_get_buying_group(h.cust_code, CONVERT(varchar(10),DATEADD(DAY, x.date_doc - 693596, '01/01/1900'),121)) > '' -- v1.1
-- START v1.3
and not exists (select 1 from cvo_debit_promo_customer_det where trx_ctrl_num = x.trx_ctrl_num) 
-- END v1.3

  
union  
  
--  4 -- cr order lines  
select   
-- v1.2 dbo.f_cvo_get_buying_group(h.cust_code, CONVERT(varchar(10),DATEADD(DAY, x.date_doc - 693596, '01/01/1900'),121)) parent, -- v1.1
-- v1.2 dbo.f_cvo_get_buying_group_name	(dbo.f_cvo_get_buying_group(h.cust_code, CONVERT(varchar(10),DATEADD(DAY, x.date_doc - 693596, '01/01/1900'),121))) parent_name, -- v1.1 
cv.buying_group parent, -- v1.2  
dbo.f_cvo_get_buying_group_name	(cv.buying_group) parent_name, -- v1.2   
-- v1.1 r.parent,   
-- v1.1 m.customer_name as parent_name,  
h.cust_code,  
b.customer_name as customer_name,  
i.doc_ctrl_num,  
t.days_due as trm,  
case when h.type = 'I' then 'Invoice' else 'Credit' end as type,  
convert(varchar(12),dateadd(d,x.date_doc-639906,'1/1/1753'),101) as inv_date,
--convert(varchar(12), h.date_shipped, 101)  as inv_date, 
-- START v1.4
sum(round(((CASE WHEN d.curr_price > c.list_price THEN d.curr_price ELSE c.list_price END) * d.cr_shipped),2)) * -1 as inv_tot,  
--sum(round((c.list_price * d.cr_shipped),2)) * -1 as inv_tot,  
sum(round(((CASE WHEN d.curr_price > c.list_price THEN d.curr_price ELSE c.list_price END) * d.cr_shipped),2)) * -1 as mer_tot,  
--sum(round((c.list_price * d.cr_shipped),2)) * -1 as mer_tot,  
-- END v1.4
0 as net_amt,  
0 as freight,  
0 as tax, 
-- START v1.4 
sum(d.cr_shipped * ROUND(curr_price -(curr_price * ((CASE WHEN d.curr_price > c.list_price THEN 0 ELSE d.discount END) / 100)),2,1)) * -1 as mer_disc,  
--sum(d.cr_shipped * ROUND(curr_price -(curr_price * (d.discount / 100)),2,1)) * -1 as mer_disc,  
sum(d.cr_shipped * ROUND(curr_price -(curr_price * ((CASE WHEN d.curr_price > c.list_price THEN 0 ELSE d.discount END) / 100)),2,1)) * -1 as inv_due,  
--sum(d.cr_shipped * ROUND(curr_price -(curr_price * (d.discount / 100)),2,1)) * -1 as inv_due,  
disc_perc = CASE 	when SUM((CASE WHEN d.curr_price > c.list_price THEN d.curr_price ELSE c.list_price END)) = 0 then 0
	WHEN (CASE WHEN d.curr_price > c.list_price THEN 0 ELSE d.discount END) > 0 and (CASE WHEN d.curr_price > c.list_price THEN 0 ELSE p.disc_perc END)  <> 0 then -- two levels of discount in play
		round(1 - (sum(d.cr_shipped*round(curr_price-(curr_price*((CASE WHEN d.curr_price > c.list_price THEN 0 ELSE d.discount END)/100)),2)) 
		/
		sum(round(((CASE WHEN d.curr_price > c.list_price THEN d.curr_price ELSE c.list_price END) * d.cr_shipped),2)) ), 2)
	WHEN (CASE WHEN d.curr_price > c.list_price THEN 0 ELSE d.discount END) > 0 AND (CASE WHEN d.curr_price > c.list_price THEN 0 ELSE p.disc_perc END)  = 0 THEN 
		(CASE WHEN d.curr_price > c.list_price THEN 0 ELSE d.discount END)/100 
	ELSE (CASE WHEN d.curr_price > c.list_price THEN 0 ELSE p.disc_perc END)  END,
/*
disc_perc = CASE 	when suM(c.list_price) = 0 then 0
	WHEN d.discount > 0 and p.disc_perc <> 0 then -- two levels of discount in play
		round(1 - (sum(d.cr_shipped*round(curr_price-(curr_price*(d.discount/100)),2)) 
		/
		sum(round((c.list_price * d.cr_shipped),2)) ), 2)
	WHEN D.DISCOUNT > 0 AND P.DISC_PERC = 0 THEN 
		d.discount/100 
	ELSE p.disc_perc END,
*/
-- END v1.4 
-- disc_perc = CASE WHEN d.discount > 0 THEN d.discount/100 ELSE p.disc_perc END,  
-- START v1.0 - fix issue casued by 0 date_due
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
x.date_doc as xinv_date,
-- convert(int,datediff(dd,'1/1/1753',h.date_shipped) + 639906) as xinv_date,
1 as rec_type -- v1.0
from orders h (nolock)  
join orders_invoice i (nolock) on h.order_no =i.order_no and h.ext = i.order_ext  
--join artrx x (nolock) on i.doc_ctrl_num = x.doc_ctrl_num and x.trx_type = 2032  
join artrx x (nolock) on i.trx_ctrl_num = x.trx_ctrl_num   
join ord_list d (nolock) on h.order_no = d.order_no and h.ext = d.order_ext  
left join arnarel r (nolock) on h.cust_code = r.child  
left join arcust m (nolock)on r.parent = m.customer_code  
join arcust B (nolock)on h.cust_code = b.customer_code  
join Cvo_ord_list c (nolock) on  d.order_no =c.order_no and d.order_ext = c.order_ext and d.line_no = c.line_no  
join CVO_disc_percent p (nolock) on d.order_no = p.order_no and d.order_ext = p.order_ext and d.line_no = p.line_no  
join arterms t (nolock) on h.terms = t.terms_code  
JOIN cvo_orders_all cv (NOLOCK) -- v1.2
ON   h.order_no = cv.order_no  -- v1.2
AND  h.ext = cv.ext   -- v1.2
where d.cr_shipped > 0  
and h.type = 'C'  
-- v1.6 and h.terms not like 'INS%'   
and x.void_flag <> 1     
AND d.part_no <> 'Credit Return Fee' 
AND cv.buying_group > '' -- v1.2
-- v1.2 AND dbo.f_cvo_get_buying_group(h.cust_code, CONVERT(varchar(10),DATEADD(DAY, x.date_doc - 693596, '01/01/1900'),121)) > '' -- v1.1
group by cv.buying_group, m.customer_name, h.cust_code, b.customer_name, i.doc_ctrl_num, t.days_due, x.date_due, h.type, -- v1.2
-- START v1.4
x.date_doc, (CASE WHEN d.curr_price > c.list_price THEN 0 ELSE d.discount END), (CASE WHEN d.curr_price > c.list_price THEN 0 ELSE p.disc_perc END)   
--x.date_doc, d.discount, disc_perc  
-- END v1.4
  
union  
  
-- 5 -- AR only records invoice  
select   
dbo.f_cvo_get_buying_group(h.customer_code, CONVERT(varchar(10),DATEADD(DAY, h.date_doc - 693596, '01/01/1900'),121)) parent, -- v1.1
dbo.f_cvo_get_buying_group_name	(dbo.f_cvo_get_buying_group(h.customer_code, CONVERT(varchar(10),DATEADD(DAY, h.date_doc - 693596, '01/01/1900'),121))) parent_name, -- v1.1  
-- v1.1 r.parent,   
-- v1.1 m.customer_name as parent_name, 
h.customer_code,  
b.customer_name as customer_name,  
h.doc_ctrl_num,  
t.days_due as trm,  
case when h.trx_type = 2031 then 'Invoice' else 'Credit' end as type,   
convert(varchar(12),dateadd(dd,h.date_doc - 639906,'1/1/1753'),101) as inv_date,  
case when d.sequence_id = 1 then round((d.unit_price * d.qty_shipped) + h.amt_tax  + h.amt_freight  ,2)  
      else round((d.unit_price * d.qty_shipped),2)  
end as inv_tot,  
round((d.unit_price * d.qty_shipped),2) as mer_tot,  
0 as net_amt,  
case   
when d.sequence_id  = 1 then h.amt_freight    
else 0  
end as freight,  
case   
when d.sequence_id  = 1 then h.amt_tax   
else 0  
end as tax,  
(d.unit_price * d.qty_shipped)- d.discount_amt as mer_disc,  
case when d.sequence_id = 1 then round((d.unit_price * d.qty_shipped)- d.discount_amt + h.amt_tax  + h.amt_freight  ,2)  
      else round((d.unit_price * d.qty_shipped)-d.discount_amt,2)  
end as inv_due,  
d.discount_prc/100, 
-- START v1.0 - fix issue casued by 0 date_due
CASE   h.date_due WHEN 0 THEN
	right(convert(varchar(12),dateadd(dd,(h.date_doc)-639906,'1/1/1753'),101),4)      
	+ '/'+    
	left(convert(varchar(12),dateadd(dd,(h.date_doc)-639906,'1/1/1753'),101),2) 
ELSE  
	right(convert(varchar(12),dateadd(dd,(h.date_due)-639906,'1/1/1753'),101),4)      
	+ '/'+    
	left(convert(varchar(12),dateadd(dd,(h.date_due)-639906,'1/1/1753'),101),2) 
END
-- END v1.0  
as due_year_month,  
h.date_doc as xinv_date,
1 as rec_type -- v1.0
from artrx_all h (nolock)  
join artrxcdt d (nolock) on h.trx_ctrl_num = d.trx_ctrl_num  
left join arnarel r (nolock) on h.customer_code = r.child  
left join arcust m (nolock)on r.parent = m.customer_code  
join arcust B (nolock)on h.customer_code = b.customer_code  
join arterms t (nolock) on h.terms_code = t.terms_code  
where (h.order_ctrl_num = '' or left(h.doc_desc,3) not in ('SO:', 'CM:'))  
and h.trx_type in (2031)  
and h.doc_ctrl_num not like 'FIN%'   
and h.doc_ctrl_num not like 'CB%'   
and h.terms_code not like 'INS%'   
and h.void_flag <> 1  
AND dbo.f_cvo_get_buying_group(h.customer_code, CONVERT(varchar(10),DATEADD(DAY, h.date_doc - 693596, '01/01/1900'),121)) > '' -- v1.1



   
  
union  
  
-- 6 -- AR only records credit  
select   
dbo.f_cvo_get_buying_group(h.customer_code, CONVERT(varchar(10),DATEADD(DAY, h.date_doc - 693596, '01/01/1900'),121)) parent, -- v1.1
dbo.f_cvo_get_buying_group_name	(dbo.f_cvo_get_buying_group(h.customer_code, CONVERT(varchar(10),DATEADD(DAY, h.date_doc - 693596, '01/01/1900'),121))) parent_name, -- v1.1  
-- v1.1 r.parent,   
-- v1.1 m.customer_name as parent_name,   
h.customer_code,  
b.customer_name as customer_name,  
h.doc_ctrl_num,  
t.days_due as trm,  
case when h.trx_type = 2031 then 'Invoice' else 'Credit' end as type,  
convert(varchar(12),dateadd(dd,h.date_doc - 639906,'1/1/1753'),101) as inv_date,  
case when d.sequence_id = 1 then case when h.recurring_flag = 2 then h.amt_tax*-1  
          when h.recurring_flag = 3 then h.amt_freight*-1  
          when h.recurring_flag = 4 then round(h.amt_tax + h.amt_freight,2)*-1  
          else round((d.unit_price * d.qty_returned) + h.amt_tax  + h.amt_freight  ,2)*-1 end  
            
      else round((d.unit_price * d.qty_returned),2)*-1  
end as inv_tot,  
case when h.recurring_flag < 2 then round((d.unit_price * d.qty_returned),2)*-1   
  else 0.0 end as mer_tot,  
0 as net_amt,  
case   
when d.sequence_id  = 1 and h.recurring_flag in (1,3,4) then h.amt_freight *-1 
else 0  
end as freight,  
case   
when d.sequence_id  = 1 and h.recurring_flag in (1,2,4) then h.amt_tax*-1  
else 0  
end as tax,  
case when h.recurring_flag < 2 then ((d.unit_price * d.qty_returned)-d.discount_amt)*-1   
  else 0.0 end as mer_disc,  
case when d.sequence_id = 1 then case when h.recurring_flag = 2 then h.amt_tax*-1  
          when h.recurring_flag = 3 then h.amt_freight*-1  
          when h.recurring_flag = 4 then round(h.amt_tax + h.amt_freight,2)*-1  
          else round((d.unit_price * d.qty_returned)-d.discount_amt + h.amt_tax  + h.amt_freight  ,2)*-1 end  
      else round((d.unit_price * d.qty_returned)-d.discount_amt,2)*-1  
end as inv_due,  
d.discount_prc/100,  
CASE h.date_due WHEN 0 THEN  
 SUBSTRING(CONVERT(varchar(10),dateadd(dd,h.date_doc - 639906,'1/1/1753'),101),7,4)  
 +'/'+ SUBSTRING(CONVERT(varchar(10),dateadd(dd,h.date_doc - 639906,'1/1/1753'),101),1,2)  
ELSE SUBSTRING(CONVERT(varchar(10),dateadd(dd,h.date_due - 639906,'1/1/1753'),101),7,4)  
 +'/'+ SUBSTRING(CONVERT(varchar(10),dateadd(dd,h.date_due - 639906,'1/1/1753'),101),1,2)  
END as due_year_month,  
h.date_doc as xinv_date,
1 as rec_type -- v1.0
from artrx_all h (nolock)  
join artrxcdt d (nolock) on h.trx_ctrl_num = d.trx_ctrl_num  
left join arnarel r (nolock) on h.customer_code = r.child  
left join arcust m (nolock)on r.parent = m.customer_code  
join arcust B (nolock)on h.customer_code = b.customer_code  
left join arterms t (nolock) on b.terms_code = t.terms_code   
where left(h.doc_desc,3) not in ('SO:', 'CM:')  
and h.trx_type in (2032)  
and h.doc_ctrl_num not like 'FIN%'   
and h.doc_ctrl_num not like 'CB%'   
and h.void_flag <> 1     --v2.0  
and ((recurring_flag < 2) or (recurring_flag > 1 and d.sequence_id = 1))  
AND dbo.f_cvo_get_buying_group(h.customer_code, CONVERT(varchar(10),DATEADD(DAY, h.date_doc - 693596, '01/01/1900'),121)) > '' -- v1.1
-- START v1.3
and not exists (select 1 from cvo_debit_promo_customer_det where trx_ctrl_num = h.trx_ctrl_num) 
-- END v1.3

union  
  
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
	xinv_date,
	1 as rec_type -- v1.0
from 
	CVO_BGLog_installment_source_vw (nolock)  

 
-- START v1.0
union  
  
--  7 -- cr fee lines  
select   
-- v1.2 dbo.f_cvo_get_buying_group(h.cust_code, CONVERT(varchar(10),DATEADD(DAY, x.date_doc - 693596, '01/01/1900'),121)) parent, -- v1.1
-- v1.2 dbo.f_cvo_get_buying_group_name	(dbo.f_cvo_get_buying_group(h.cust_code, CONVERT(varchar(10),DATEADD(DAY, x.date_doc - 693596, '01/01/1900'),121))) parent_name, -- v1.1  
cv.buying_group parent, -- v1.2  
dbo.f_cvo_get_buying_group_name	(cv.buying_group) parent_name, -- v1.2 
-- v1.1 r.parent,   
-- v1.1 m.customer_name as parent_name,    
h.cust_code,  
b.customer_name as customer_name,  
i.doc_ctrl_num,  
t.days_due as trm,  
case when h.type = 'I' then 'Invoice' else 'Credit' end as type,  
convert(varchar(12),dateadd(d,x.date_doc-639906,'1/1/1753'),101) as inv_date,
-- convert(varchar(12), h.date_shipped, 101)  as inv_date, 
-- START v1.4 
sum(d.cr_shipped * ROUND(curr_price -(curr_price * ((CASE WHEN d.curr_price > c.list_price THEN 0 ELSE d.discount END) / 100)),2,1)) * -1 as inv_tot,  
--sum(d.cr_shipped * ROUND(curr_price -(curr_price * (d.discount / 100)),2,1)) * -1 as inv_tot,  
-- END v1.4
0 as mer_tot,  
0 as net_amt,  
0 as freight,  
0 as tax,  
0 as mer_disc, 
-- START v1.4 
sum(d.cr_shipped * ROUND(curr_price -(curr_price * ((CASE WHEN d.curr_price > c.list_price THEN 0 ELSE d.discount END) / 100)),2,1)) * -1 as inv_due,  
--sum(d.cr_shipped * ROUND(curr_price -(curr_price * (d.discount / 100)),2,1)) * -1 as inv_due,  
-- END v1.4
0 as disc_perc,  
CASE MAX(x.date_due) WHEN 0 THEN
	right(convert(varchar(12),dateadd(dd,MAX(x.date_doc)-639906,'1/1/1753'),101),4)      
	+ '/'+    
	left(convert(varchar(12),dateadd(dd,MAX(x.date_doc)-639906,'1/1/1753'),101),2) 
ELSE  
	right(convert(varchar(12),dateadd(dd,MAX(x.date_due)-639906,'1/1/1753'),101),4)      
	+ '/'+    
	left(convert(varchar(12),dateadd(dd,MAX(x.date_due)-639906,'1/1/1753'),101),2) 
END
as due_year_month,  
x.date_doc as xinv_date,
-- convert(int,datediff(dd,'1/1/1753',h.date_shipped) + 639906) as xinv_date,
2 as rec_type 
from orders h (nolock)  
join orders_invoice i (nolock) on h.order_no =i.order_no and h.ext = i.order_ext  
join artrx x (nolock) on i.doc_ctrl_num = x.doc_ctrl_num and x.trx_type = 2032  
join ord_list d (nolock) on h.order_no = d.order_no and h.ext = d.order_ext  
left join arnarel r (nolock) on h.cust_code = r.child  
left join arcust m (nolock)on r.parent = m.customer_code  
join arcust B (nolock)on h.cust_code = b.customer_code  
join Cvo_ord_list c (nolock) on  d.order_no =c.order_no and d.order_ext = c.order_ext and d.line_no = c.line_no  
join CVO_disc_percent p (nolock) on d.order_no = p.order_no and d.order_ext = p.order_ext and d.line_no = p.line_no  
join arterms t (nolock) on h.terms = t.terms_code 
JOIN cvo_orders_all cv (NOLOCK) -- v1.2
ON   h.order_no = cv.order_no  -- v1.2
AND  h.ext = cv.ext   -- v1.2 
where d.cr_shipped > 0  
and h.type = 'C'  
and h.terms not like 'INS%'   
and x.void_flag <> 1     
AND d.part_no = 'Credit Return Fee' 
AND cv.buying_group > '' -- v1.2
-- v1.2 AND dbo.f_cvo_get_buying_group(h.cust_code, CONVERT(varchar(10),DATEADD(DAY, x.date_doc - 693596, '01/01/1900'),121)) > '' -- v1.1

group by cv.buying_group, m.customer_name, h.cust_code, b.customer_name, i.doc_ctrl_num, t.days_due, x.date_due, h.type,  -- v1.2
-- START v1.4
x.date_doc, (CASE WHEN d.curr_price > c.list_price THEN 0 ELSE d.discount END), (CASE WHEN d.curr_price > c.list_price THEN 0 ELSE p.disc_perc END) 
--x.date_doc, d.discount, disc_perc 
-- END v1.4
-- END v1.0

-- START v1.3
union

-- 8 -- cr debit promo tax line  
select   
cv.buying_group parent, -- v1.2  
dbo.f_cvo_get_buying_group_name	(cv.buying_group) parent_name, -- v1.2  
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
0 as disc_perc,  
CASE   x.date_due WHEN 0 THEN
	right(convert(varchar(12),dateadd(dd,(x.date_doc)-639906,'1/1/1753'),101),4)      
	+ '/'+    
	left(convert(varchar(12),dateadd(dd,(x.date_doc)-639906,'1/1/1753'),101),2) 
ELSE  
	right(convert(varchar(12),dateadd(dd,(x.date_due)-639906,'1/1/1753'),101),4)      
	+ '/'+    
	left(convert(varchar(12),dateadd(dd,(x.date_due)-639906,'1/1/1753'),101),2) 
END
as due_year_month,  
x.date_doc as xinv_date,
3 as rec_type -- v1.0

from 
(select distinct dd.trx_ctrl_num, co.order_no, co.ext, buying_group from  cvo_debit_promo_customer_det dd inner join  cvo_orders_all co on dd.order_no = co.order_no and dd.ext = co.ext) cv 
join artrx x (nolock) on cv.trx_ctrl_num = x.trx_ctrl_num
left join arnarel r (nolock) on r.child = x.customer_code
join arcust B (nolock) on b.customer_code  = x.customer_code
join arterms t (nolock) on b.terms_code = t.terms_code  
where (x.amt_tax <> 0) 
and x.trx_type = 2032
and x.terms_code not like 'INS%'   
and x.void_flag <> 1     
AND cv.buying_group > '' -- v1.2

  
union  
  
--  4 -- cr order lines - debit promos 
select   
cv.buying_group parent, -- v1.2  
dbo.f_cvo_get_buying_group_name	(cv.buying_group) parent_name, -- v1.2   
h.cust_code,  
b.customer_name as customer_name,  
xx.doc_ctrl_num,  
t.days_due as trm,  
'Credit' as type,  
convert(varchar(12),dateadd(d,x.date_doc-639906,'1/1/1753'),101) as inv_date,
--convert(varchar(12), h.date_shipped, 101)  as inv_date, 
-- START v1.4 
sum(round(((CASE WHEN d.curr_price > c.list_price THEN d.curr_price ELSE c.list_price END) * d.shipped),2)) * -1 as inv_tot,  
--sum(round((c.list_price * d.shipped),2)) * -1 as inv_tot,  
sum(round(((CASE WHEN d.curr_price > c.list_price THEN d.curr_price ELSE c.list_price END) * d.shipped),2)) * -1 as mer_tot,  
--sum(round((c.list_price * d.shipped),2)) * -1 as mer_tot,  
-- END v1.4
0 as net_amt,  
0 as freight,  
0 as tax,  
-- START v1.4
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
disc_perc = CASE 	when SUM((CASE WHEN d.curr_price > c.list_price THEN 0 ELSE d.discount END)) = 0 then 0
	WHEN (CASE WHEN d.curr_price > c.list_price THEN 0 ELSE d.discount END) > 0 and (CASE WHEN d.curr_price > c.list_price THEN 0 ELSE p.disc_perc END) <> 0 then -- two levels of discount in play
		round(1 - (sum(d.shipped*round(curr_price-(curr_price*((CASE WHEN d.curr_price > c.list_price THEN 0 ELSE d.discount END)/100)),2)) 
		/
		sum(round(((CASE WHEN d.curr_price > c.list_price THEN 0 ELSE (CASE WHEN d.curr_price > c.list_price THEN 0 ELSE d.discount END) END) * d.shipped),2)) ), 2)
	WHEN (CASE WHEN d.curr_price > c.list_price THEN 0 ELSE d.discount END) > 0 AND (CASE WHEN d.curr_price > c.list_price THEN 0 ELSE p.disc_perc END) = 0 THEN 
		(CASE WHEN d.curr_price > c.list_price THEN 0 ELSE d.discount END)/100 
	ELSE (CASE WHEN d.curr_price > c.list_price THEN 0 ELSE p.disc_perc END) END, 
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
-- END v1.4
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
x.date_doc as xinv_date,
3 as rec_type -- v1.0
from
cvo_debit_promo_customer_det dd 
inner join ord_list d (nolock) on d.order_no = dd.order_no and d.order_ext = dd.ext and d.line_no = dd.line_no

inner join orders h (nolock)  on h.order_no = dd.order_no and h.ext = dd.ext
join artrx xx on dd.trx_ctrl_num = xx.trx_ctrl_num
join orders_invoice i (nolock) on h.order_no =i.order_no and h.ext = i.order_ext  
join artrx x (nolock) on i.trx_ctrl_num = x.trx_ctrl_num   
left join arnarel r (nolock) on h.cust_code = r.child  
left join arcust m (nolock)on r.parent = m.customer_code  
join arcust B (nolock)on h.cust_code = b.customer_code  
join Cvo_ord_list c (nolock) on  d.order_no =c.order_no and d.order_ext = c.order_ext and d.line_no = c.line_no  
join CVO_disc_percent p (nolock) on d.order_no = p.order_no and d.order_ext = p.order_ext and d.line_no = p.line_no  
join arterms t (nolock) on h.terms = t.terms_code  
JOIN cvo_orders_all cv (NOLOCK) -- v1.2
ON   h.order_no = cv.order_no  -- v1.2
AND  h.ext = cv.ext   -- v1.2
where d.shipped > 0  
and h.terms not like 'INS%'   
and x.void_flag <> 1     
AND cv.buying_group > '' -- v1.2

group by cv.buying_group, m.customer_name, h.cust_code, b.customer_name, xx.doc_ctrl_num, t.days_due, x.date_due, h.type, -- v1.2
-- START v1.4
x.date_doc, (CASE WHEN d.curr_price > c.list_price THEN 0 ELSE d.discount END), (CASE WHEN d.curr_price > c.list_price THEN 0 ELSE p.disc_perc END)  
--x.date_doc, d.discount, disc_perc  
-- END v1.4
-- END v1.3 

-- v1.5 Start
UNION

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
h.date_doc as xinv_date,
1 as rec_type -- v1.0
from artrx_all h (nolock)  
left join arnarel r (nolock) on h.customer_code = r.child  
left join arcust m (nolock)on r.parent = m.customer_code  
join arcust B (nolock)on h.customer_code = b.customer_code  
where h.trx_type in (2061,2071)  
and h.doc_ctrl_num not like 'CB%'   
and h.terms_code not like 'INS%'   
and h.void_flag <> 1  
AND dbo.f_cvo_get_buying_group(h.customer_code, CONVERT(varchar(10),DATEADD(DAY, h.date_doc - 693596, '01/01/1900'),121)) > '' 

UNION

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
h.date_doc as xinv_date,
1 as rec_type -- v1.0
from artrx_all h (nolock)  
left join arnarel r (nolock) on h.customer_code = r.child  
left join arcust m (nolock)on r.parent = m.customer_code  
join arcust B (nolock)on h.customer_code = b.customer_code  
where h.trx_ctrl_num like 'CB%'   
and h.terms_code not like 'INS%'   
and h.void_flag <> 1  
AND dbo.f_cvo_get_buying_group(h.customer_code, CONVERT(varchar(10),DATEADD(DAY, h.date_doc - 693596, '01/01/1900'),121)) > '' 
-- v1.5 End

GO
GRANT REFERENCES ON  [dbo].[CVO_BGLog_source_vw2] TO [public]
GO
GRANT SELECT ON  [dbo].[CVO_BGLog_source_vw2] TO [public]
GO
GRANT INSERT ON  [dbo].[CVO_BGLog_source_vw2] TO [public]
GO
GRANT DELETE ON  [dbo].[CVO_BGLog_source_vw2] TO [public]
GO
GRANT UPDATE ON  [dbo].[CVO_BGLog_source_vw2] TO [public]
GO
