SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO




CREATE view [dbo].[CVO_BGLog_installment_source_vw] 

AS
-- v2.0 TM 04/27/2012 -	Ignore AR Records that are Voided
-- v2.5 CB 10/07/2013 - Issue #927 - Buying Group Switching
-- v2.7	CT 20/10/2014 - Issue #1367 - For Sales Orders and Credit Returns, if net price > list price, set list = net and discount = 0 and disc_perc = 0
-- v2.8 CB 25/04/2018 - Add in view for promo discount list and override
-- v2.9 CB 27/04/2018 - Use new table for bg data rather than functions

-- 6 AR Split only records  *** NEW ***

-- A --  invoice line 1 and H - freight and tax
select 
bgl.parent, 
-- v2.9 dbo.f_cvo_get_buying_group(o.cust_code, CONVERT(varchar(10),DATEADD(DAY,h.date_doc - 693596, '01/01/1900'),121)) parent, -- v2.5
-- v2.5 r.parent,    
bgl.parent_name, -- v2.9 dbo.f_cvo_get_buying_group_name	(dbo.f_cvo_get_buying_group(o.cust_code, CONVERT(varchar(10),DATEADD(DAY, h.date_doc - 693596, '01/01/1900'),121))) parent_name, -- v2.5
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
join cvo_artermsd_installment z (nolock) on h.terms_code = z.terms_code and convert(int,right(h.doc_ctrl_num,1)) = z.sequence_id
-- join CVO_min_display_vw q (nolock) on q.order_no = d.order_no and q.order_ext = d.order_ext and d.display_line = q.min_line
JOIN cvo_ar_bg_list bgl (NOLOCK) ON bgl.doc_ctrl_num = h.doc_ctrl_num AND bgl.customer_code = h.customer_code -- v3.3
where (o.freight <> 0 or o.total_tax <> 0)
and o.type = 'I'
--and i.doc_ctrl_num in ('INV0215446')
--where h.order_ctrl_num = ''
and h.terms_code like 'INS%' 
and h.trx_type in (2031)
and h.doc_ctrl_num not like 'FIN%' 
and h.doc_ctrl_num not like 'CB%'
and h.void_flag <> 1					--v2.0 
-- v2.9 AND dbo.f_cvo_get_buying_group(o.cust_code, CONVERT(varchar(10),DATEADD(DAY,h.date_doc - 693596, '01/01/1900'),121)) > '' -- v2.5

UNION all

-- B -- Invoice and All Lines without header
select 
bgl.parent, -- v2.9 dbo.f_cvo_get_buying_group(o.cust_code, CONVERT(varchar(10),DATEADD(DAY,h.date_doc - 693596, '01/01/1900'),121)) parent, -- v2.5
-- v2.5 r.parent,     
bgl.parent_name, -- v2.9 dbo.f_cvo_get_buying_group_name	(dbo.f_cvo_get_buying_group(o.cust_code, CONVERT(varchar(10),DATEADD(DAY, h.date_doc - 693596, '01/01/1900'),121))) parent_name, -- v2.5
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
CASE WHEN (MAX(ISNULL(ld.list,0)) = 0) THEN -- v2.8
	CASE WHEN ISNULL(qv.net_only,'N') = 'N' THEN 
	CASE WHEN MAX(cv.promo_id) > '' THEN SUM(ROUND((d.curr_price - c.amt_disc) * d.shipped,2)) ELSE
		sum(round(((CASE WHEN d.curr_price > c.list_price THEN d.curr_price ELSE c.list_price END) * d.shipped) * (z.installment_prc/100),2)) END
	ELSE SUM(ROUND(d.curr_price * d.shipped,2)) END -- v2.8	
ELSE sum(d.Shipped * ROUND((d.curr_price - (d.curr_price * ((CASE WHEN d.curr_price > c.list_price THEN 0 ELSE d.discount END) / 100))) * (z.installment_prc/100),2)) END -- v2.8
as inv_tot,
--sum(round(round((d.curr_price * d.shipped),2)*(z.installment_prc/100) ,2)) as inv_tot,
CASE WHEN (MAX(ISNULL(ld.list,0)) = 0) THEN -- v2.8
	CASE WHEN ISNULL(qv.net_only,'N') = 'N' THEN -- v2.8
	CASE WHEN MAX(cv.promo_id) > '' THEN SUM(ROUND((d.curr_price - c.amt_disc) * d.shipped,2)) ELSE
		sum(round(((CASE WHEN d.curr_price > c.list_price THEN d.curr_price ELSE c.list_price END) * d.shipped) * (z.installment_prc/100),2)) END
	ELSE SUM(ROUND(d.curr_price * d.shipped,2)) END	-- v2.8
ELSE sum(d.Shipped * ROUND((d.curr_price - (d.curr_price * ((CASE WHEN d.curr_price > c.list_price THEN 0 ELSE d.discount END) / 100))) * (z.installment_prc/100),2)) END -- v2.8
as mer_tot,
--sum(round(round((d.curr_price * d.shipped),2)*(z.installment_prc/100) ,2)) as mer_tot,
-- END v2.7
0 as net_amt,
0 as freight,
0 as tax,
--right(z.installment_days,2) as trm,
--sum(round(round((d.curr_price * d.shipped)*(1-(d.discount/100)),2)*(z.installment_prc/100) ,2)) as mer_disc,
--sum(round(round((d.curr_price * d.shipped)*(1-(d.discount/100)),2)*(z.installment_prc/100) ,2)) as inv_due,
-- START v2.7
sum(d.Shipped * ROUND((d.curr_price - (d.curr_price * ((CASE WHEN d.curr_price > c.list_price THEN 0 ELSE d.discount END) / 100))) * (z.installment_prc/100),2)) as mer_disc,
--sum(d.Shipped * ROUND((d.curr_price - (d.curr_price * (d.discount / 100))) * (z.installment_prc/100),2)) as mer_disc,
sum(d.Shipped * ROUND((d.curr_price - (d.curr_price * ((CASE WHEN d.curr_price > c.list_price THEN 0 ELSE d.discount END) / 100))) * (z.installment_prc/100),2)) as inv_due,
--sum(d.Shipped * ROUND((d.curr_price - (d.curr_price * (d.discount / 100))) * (z.installment_prc/100),2)) as inv_due,
-- END v2.7
--p.disc_perc,
--disc_perc = CASE WHEN max(d.discount) > 0 THEN max(d.discount/100) ELSE p.disc_perc END,
-- START v2.7
CASE WHEN (MAX(ISNULL(ld.list,0)) = 0) THEN -- v2.8
	CASE WHEN ISNULL(qv.net_only,'N') = 'N' THEN -- v2.8
	CASE WHEN MAX(cv.promo_id) > '' THEN 0 ELSE
		CASE WHEN (CASE WHEN d.curr_price > c.list_price THEN 0 ELSE d.discount END) > 0 THEN (CASE WHEN d.curr_price > c.list_price THEN 0 ELSE d.discount END)/100 ELSE (CASE WHEN d.curr_price > c.list_price THEN 0 ELSE p.disc_perc END) END END
	ELSE 0 END -- v2.8
	ELSE 0 END -- v2.8
as disc_perc,
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
join cvo_artermsd_installment z (nolock) on h.terms_code = z.terms_code and convert(int,right(h.doc_ctrl_num,1)) = z.sequence_id
JOIN cvo_orders_all cv (NOLOCK) ON cv.order_no = o.order_no AND cv.ext = o.ext
LEFT JOIN dbo.cvo_bg_contact_pricing_check_vw qv ON o.cust_code = qv.customer_key AND d.part_no = qv.part_no  -- v2.8
LEFT JOIN dbo.cvo_promo_discount_vw ld (NOLOCK) ON cv.promo_id = ld.promo_id AND cv.promo_level = ld.promo_level  -- v2.8
JOIN cvo_ar_bg_list bgl (NOLOCK) ON bgl.doc_ctrl_num = h.doc_ctrl_num AND bgl.customer_code = h.customer_code -- v3.3
where 
d.shipped > 0
and o.type = 'I'
and h.terms_code like 'INS%' 
and h.trx_type in (2031)
and h.doc_ctrl_num not like 'FIN%' 
and h.doc_ctrl_num not like 'CB%' 
and h.void_flag <> 1					--v2.0
-- v2.9 AND dbo.f_cvo_get_buying_group(o.cust_code, CONVERT(varchar(10),DATEADD(DAY,h.date_doc - 693596, '01/01/1900'),121)) > '' -- v2.5
-- START v2.7
group by bgl.parent, bgl.parent_name, -- v2.9
o.cust_code, b.customer_name, h.doc_ctrl_num, z.installment_days, o.type, h.date_due,h.date_doc, (CASE WHEN d.curr_price > c.list_price THEN 0 ELSE d.discount END), (CASE WHEN d.curr_price > c.list_price THEN 0 ELSE disc_perc END), z.installment_prc
,qv.net_only -- v2.8
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
