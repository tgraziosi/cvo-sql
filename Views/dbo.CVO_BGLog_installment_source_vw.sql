SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

-- SELECT * FROM dbo.CVO_BGLog_installment_source_vw AS blisv WHERE blisv.cust_code = '052222' AND blisv.inv_date > '02/26/2017'


CREATE view [dbo].[CVO_BGLog_installment_source_vw] 

AS
-- v2.0 TM 04/27/2012 -	Ignore AR Records that are Voided
-- v2.5 CB 10/07/2013 - Issue #927 - Buying Group Switching
-- v2.7	CT 20/10/2014 - Issue #1367 - For Sales Orders and Credit Returns, if net price > list price, set list = net and discount = 0 and disc_perc = 0
-- v2.8 TG 11/1/2016 - Fix where there are 10 or more installments.  not getting into the terms installment correctly
-- v2.9 tg 3/23/17 - fix rounding on mer_disc and inv_due to match mer_tot and inv_tot

-- 6 AR Split only records  *** NEW ***

-- A --  invoice line 1 and H - freight and tax
select 
dbo.f_cvo_get_buying_group(o.cust_code, CONVERT(varchar(10),DATEADD(DAY,h.date_doc - 693596, '01/01/1900'),121)) parent, -- v2.5
-- v2.5 r.parent,    
dbo.f_cvo_get_buying_group_name	(dbo.f_cvo_get_buying_group(o.cust_code, CONVERT(varchar(10),DATEADD(DAY, h.date_doc - 693596, '01/01/1900'),121))) parent_name, -- v2.5
-- v2.6 m.customer_name as parent_name,
o.cust_code,
b.customer_name as customer_name,
h.doc_ctrl_num,
z.installment_days as trm,
-- tag - dont need to case it.
'Invoice' as type,
-- case when o.type = 'I' then 'Invoice' else 'Credit' end as type,
--datediff(dd,'1/1/1753',h.invoice_date) + 639906 as inv_date,
--convert(varchar(12), o.invoice_date, 101) as inv_date,
convert(varchar(12), dateadd(dd, h.date_doc - 639906, '1/1/1753'),101) as inv_date,
--case when d.line_no = 1 then round(round((c.list_price * d.shipped),2)*(z.installment_prc/100),2) + round((o.total_tax  + o.freight)*(z.installment_prc/100) ,2)
--      else round(round((c.list_price * d.shipped),2)*(z.installment_prc/100),2)
--end 
round((o.total_tax  + o.freight)* (z.installment_prc/100),2) as inv_tot,
--round(round((c.list_price * d.shipped),2)*(z.installment_prc/100),2) 
0 as mer_tot,
0 as net_amt,
--case 
--when d.line_no  = 1 then round(o.freight*(z.installment_prc/100)  ,2)
--else 0
--end 
round(o.freight*(z.installment_prc/100)  ,2)as freight,
--case 
--when d.line_no  = 1 then round(o.total_tax*(z.installment_prc/100)  ,2)
--else 0
--end 
round(o.total_tax*(z.installment_prc/100)  ,2) as tax,
--right(z.installment_days,2) as trm,
--round(round((d.price * d.shipped),2)*(z.installment_prc/100),2)  
0 as mer_disc,
--case when d.line_no = 1 then round( round((d.price * d.shipped),2)* (z.installment_prc/100),2)   + round((o.total_tax  + o.freight)* (z.installment_prc/100),2)   
--      else round(round((d.price * d.shipped),2)* (z.installment_prc/100) ,2)
--end 
round((o.total_tax  + o.freight)* (z.installment_prc/100),2)  as inv_due,
--p.disc_perc,
-- tag -- 042913 - don't care about discounts on freight and tax line
0 as disc_perc,
-- tag -- disc_perc = CASE WHEN d.discount > 0 THEN d.discount/100 ELSE p.disc_perc END,
--right(convert(varchar(12), dateadd(dd, datediff(dd, '1/1/1753', convert(varchar(12), dateadd(dd, h.date_doc - 639906, '1/1/1753'),101)) + 639906 + convert(int,right(m.terms_code,2)) - 639906, '1/1/1753'),101) ,4)

--right(convert(varchar(12), dateadd(dd, (h.date_doc + convert(int,right(z.installment_days,2)))- 639906, '1/1/1753'),101),4) 
--+ '/'+
--left(convert(varchar(12), dateadd(dd, datediff(dd, '1/1/1753', convert(varchar(12), dateadd(dd, h.date_doc - 639906, '1/1/1753'),101)) + 639906 + convert(int,right(z.installment_days,2)) - 639906, '1/1/1753'),101) ,2)
CASE h.date_due WHEN 0 THEN
	SUBSTRING(CONVERT(varchar(10),dateadd(dd,h.date_doc - 639906,'1/1/1753'),101),7,4)
	+'/'+ SUBSTRING(CONVERT(varchar(10),dateadd(dd,h.date_doc - 639906,'1/1/1753'),101),1,2)
ELSE	SUBSTRING(CONVERT(varchar(10),dateadd(dd,h.date_due - 639906,'1/1/1753'),101),7,4)
	+'/'+ SUBSTRING(CONVERT(varchar(10),dateadd(dd,h.date_due - 639906,'1/1/1753'),101),1,2)
END as due_year_month,
--
--right(convert(varchar(12), dateadd(dd, (h.date_due )- 639906, '1/1/1753'),101),4)  
--+ '/'+
--left(convert(varchar(12), dateadd(dd, (h.date_due ) - 639906, '1/1/1753'),101),2)
--as due_year_month,
h.date_doc as xinv_date

from artrx_all h (nolock)
join orders_invoice i (nolock) on i.doc_ctrl_num = left(h.doc_ctrl_num, charindex('-',h.doc_ctrl_num)-1)
join orders o (nolock) on o.order_no =i.order_no and o.ext = i.order_ext
-- join ord_list d (nolock) on o.order_no = d.order_no and o.ext = d.order_ext
left join arnarel r (nolock) on o.cust_code = r.child
left join arcust m (nolock) on r.parent = m.customer_code
join arcust B (nolock) on o.cust_code = b.customer_code
-- join Cvo_ord_list c (nolock) on  d.order_no =c.order_no and d.order_ext = c.order_ext and d.line_no = c.line_no
-- join CVO_disc_percent p (nolock) on d.order_no = p.order_no and d.order_ext = p.order_ext and d.line_no = p.line_no
-- 11/1/2016 - change doc control num - join cvo_artermsd_installment z (nolock) on h.terms_code = z.terms_code and convert(int,right(h.doc_ctrl_num,1)) = z.sequence_id
join cvo_artermsd_installment z (nolock) on h.terms_code = z.terms_code and 
		CAST(REPLACE(RIGHT(h.doc_ctrl_num, CHARINDEX('-', REVERSE(h.doc_ctrl_num)) ),'-','') AS int)  = z.sequence_id
-- join CVO_min_display_vw q (nolock) on q.order_no = d.order_no and q.order_ext = d.order_ext and d.display_line = q.min_line
where (o.freight <> 0 or o.total_tax <> 0)
and o.type = 'I'
--and i.doc_ctrl_num in ('INV0215446')
--where h.order_ctrl_num = ''
AND 0 < CHARINDEX('-',h.doc_ctrl_num)
and h.terms_code like 'INS%' 
and h.trx_type in (2031)
and h.doc_ctrl_num not like 'FIN%' 
and h.doc_ctrl_num not like 'CB%'
and h.void_flag <> 1					--v2.0 
AND dbo.f_cvo_get_buying_group(o.cust_code, CONVERT(varchar(10),DATEADD(DAY,h.date_doc - 693596, '01/01/1900'),121)) > '' -- v2.5

union

-- B -- Invoice and All Lines without header
select 
dbo.f_cvo_get_buying_group(o.cust_code, CONVERT(varchar(10),DATEADD(DAY,h.date_doc - 693596, '01/01/1900'),121)) parent, -- v2.5
-- v2.5 r.parent,     
dbo.f_cvo_get_buying_group_name	(dbo.f_cvo_get_buying_group(o.cust_code, CONVERT(varchar(10),DATEADD(DAY, h.date_doc - 693596, '01/01/1900'),121))) parent_name, -- v2.5
-- v2.6 m.customer_name as parent_name,
o.cust_code,
b.customer_name as customer_name,
h.doc_ctrl_num,
z.installment_days as trm,
case when o.type = 'I' then 'Invoice' else 'Credit' end as type,
--datediff(dd,'1/1/1753',h.invoice_date) + 639906 as inv_date,
--convert(varchar(12), o.invoice_date, 101) as inv_date,
convert(varchar(12), dateadd(dd, h.date_doc - 639906, '1/1/1753'),101) as inv_date,
-- START v2.7
sum(round(((CASE WHEN d.curr_price > c.list_price THEN d.curr_price ELSE c.list_price END) * d.shipped) * (z.installment_prc/100),2)) as inv_tot,
--sum(round(round((d.curr_price * d.shipped),2)*(z.installment_prc/100) ,2)) as inv_tot,
sum(round(((CASE WHEN d.curr_price > c.list_price THEN d.curr_price ELSE c.list_price END) * d.shipped) * (z.installment_prc/100),2)) as mer_tot,
--sum(round(round((d.curr_price * d.shipped),2)*(z.installment_prc/100) ,2)) as mer_tot,
-- END v2.7
0 as net_amt,
0 as freight,
0 as tax,
--right(z.installment_days,2) as trm,
--sum(round(round((d.curr_price * d.shipped)*(1-(d.discount/100)),2)*(z.installment_prc/100) ,2)) as mer_disc,
--sum(round(round((d.curr_price * d.shipped)*(1-(d.discount/100)),2)*(z.installment_prc/100) ,2)) as inv_due,
-- START v2.7
-- 2.9
sum(ROUND(d.Shipped * (d.curr_price - (d.curr_price * ((CASE WHEN d.curr_price > c.list_price THEN 0 ELSE d.discount END) / 100))) * (z.installment_prc/100),2)) as mer_disc,
--sum(d.Shipped * ROUND((d.curr_price - (d.curr_price * (d.discount / 100))) * (z.installment_prc/100),2)) as mer_disc,
sum(ROUND(d.Shipped * (d.curr_price - (d.curr_price * ((CASE WHEN d.curr_price > c.list_price THEN 0 ELSE d.discount END) / 100))) * (z.installment_prc/100),2)) as inv_due,
--sum(d.Shipped * ROUND((d.curr_price - (d.curr_price * (d.discount / 100))) * (z.installment_prc/100),2)) as inv_due,
-- END v2.7
-- 2.9
--p.disc_perc,
--disc_perc = CASE WHEN max(d.discount) > 0 THEN max(d.discount/100) ELSE p.disc_perc END,
-- START v2.7
CASE WHEN (CASE WHEN d.curr_price > c.list_price THEN 0 ELSE d.discount END) > 0 THEN (CASE WHEN d.curr_price > c.list_price THEN 0 ELSE d.discount END)/100 ELSE (CASE WHEN d.curr_price > c.list_price THEN 0 ELSE p.disc_perc END) END
AS disc_perc,
--disc_perc = CASE WHEN d.discount > 0 THEN d.discount/100 ELSE p.disc_perc END,
-- END v2.7
--right(convert(varchar(12), dateadd(dd, datediff(dd, '1/1/1753', h.date_doc) + 639906 + convert(int,right(m.terms_code,2)) - 639906, '1/1/1753'),101) ,4)
--right(convert(varchar(12), dateadd(dd, (h.date_doc + convert(int,right(z.installment_days,2)))- 639906, '1/1/1753'),101),4) 
--+ '/'+
--left(convert(varchar(12), dateadd(dd, datediff(dd, '1/1/1753', h.date_doc) + 639906 + convert(int,right(z.installment_days,2)) - 639906, '1/1/1753'),101) ,2)
CASE h.date_due WHEN 0 THEN
	SUBSTRING(CONVERT(varchar(10),dateadd(dd,h.date_doc - 639906,'1/1/1753'),101),7,4)
	+'/'+ SUBSTRING(CONVERT(varchar(10),dateadd(dd,h.date_doc - 639906,'1/1/1753'),101),1,2)
ELSE	SUBSTRING(CONVERT(varchar(10),dateadd(dd,h.date_due - 639906,'1/1/1753'),101),7,4)
	+'/'+ SUBSTRING(CONVERT(varchar(10),dateadd(dd,h.date_due - 639906,'1/1/1753'),101),1,2)
END as due_year_month,
--right(convert(varchar(12), dateadd(dd, (h.date_due )- 639906, '1/1/1753'),101),4)  
--+ '/'+
--left(convert(varchar(12), dateadd(dd, (h.date_due ) - 639906, '1/1/1753'),101),2)
--as due_year_month,
h.date_doc as xinv_date
from artrx_all h (nolock)
join orders_invoice i (nolock) on i.doc_ctrl_num = left(h.doc_ctrl_num, charindex('-',h.doc_ctrl_num)-1)
join orders o (nolock) on o.order_no =i.order_no and o.ext = i.order_ext
join ord_list d (nolock) on o.order_no = d.order_no and o.ext = d.order_ext
left join arnarel r (nolock) on o.cust_code = r.child
left join arcust m (nolock) on r.parent = m.customer_code
join arcust B (nolock) on o.cust_code = b.customer_code
join Cvo_ord_list c (nolock) on  d.order_no =c.order_no and d.order_ext = c.order_ext and d.line_no = c.line_no
join CVO_disc_percent p (nolock) on d.order_no = p.order_no and d.order_ext = p.order_ext and d.line_no = p.line_no
join cvo_artermsd_installment z (nolock) on h.terms_code = z.terms_code and
	CAST(REPLACE(RIGHT(h.doc_ctrl_num, CHARINDEX('-', REVERSE(h.doc_ctrl_num)) ),'-','') AS int)  = z.sequence_id
where 
d.shipped > 0
and o.type = 'I'
AND 0 < CHARINDEX('-',h.doc_ctrl_num)
and h.terms_code like 'INS%' 
and h.trx_type in (2031)
and h.doc_ctrl_num not like 'FIN%' 
and h.doc_ctrl_num not like 'CB%' 
and h.void_flag <> 1					--v2.0
AND dbo.f_cvo_get_buying_group(o.cust_code, CONVERT(varchar(10),DATEADD(DAY,h.date_doc - 693596, '01/01/1900'),121)) > '' -- v2.5
-- START v2.7
group by r.parent, m.customer_name, o.cust_code, b.customer_name, h.doc_ctrl_num, z.installment_days, o.type, h.date_due,h.date_doc, (CASE WHEN d.curr_price > c.list_price THEN 0 ELSE d.discount END), (CASE WHEN d.curr_price > c.list_price THEN 0 ELSE disc_perc END), z.installment_prc
--group by r.parent, m.customer_name, o.cust_code, b.customer_name, h.doc_ctrl_num, z.installment_days, o.type, h.date_due,h.date_doc, d.discount, disc_perc, z.installment_prc
-- END v2.7






GO
GRANT REFERENCES ON  [dbo].[CVO_BGLog_installment_source_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[CVO_BGLog_installment_source_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[CVO_BGLog_installment_source_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[CVO_BGLog_installment_source_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[CVO_BGLog_installment_source_vw] TO [public]
GO
