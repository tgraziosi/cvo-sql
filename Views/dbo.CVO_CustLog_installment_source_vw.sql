SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


CREATE view [dbo].[CVO_CustLog_installment_source_vw] 

AS
--v2.0 TM 04/27/2012 -	Ignore AR Records that are Voided
-- v2.5 CB 10/07/2013 - Issue #927 - Buying Group Switching

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
'Invoice' as type,
convert(varchar(12), dateadd(dd, h.date_doc - 639906, '1/1/1753'),101) as inv_date,
round((o.total_tax  + o.freight)* (z.installment_prc/100),2) as inv_tot,
0 as mer_tot,
0 as net_amt,
round(o.freight*(z.installment_prc/100)  ,2)as freight,
round(o.total_tax*(z.installment_prc/100)  ,2) as tax,
0 as mer_disc,
round((o.total_tax  + o.freight)* (z.installment_prc/100),2)  as inv_due,
0 as disc_perc,
CASE h.date_due WHEN 0 THEN
	SUBSTRING(CONVERT(varchar(10),dateadd(dd,h.date_doc - 639906,'1/1/1753'),101),7,4)
	+'/'+ SUBSTRING(CONVERT(varchar(10),dateadd(dd,h.date_doc - 639906,'1/1/1753'),101),1,2)
ELSE	SUBSTRING(CONVERT(varchar(10),dateadd(dd,h.date_due - 639906,'1/1/1753'),101),7,4)
	+'/'+ SUBSTRING(CONVERT(varchar(10),dateadd(dd,h.date_due - 639906,'1/1/1753'),101),1,2)
END as due_year_month,
h.date_doc as xinv_date

from artrx_all h (nolock)
join orders_invoice i (nolock) on i.doc_ctrl_num = 
    left(h.doc_ctrl_num, 
    isnull(nullif(charindex('-',h.doc_ctrl_num)-1, -1), len(h.doc_ctrl_num)))

join orders o (nolock) on o.order_no =i.order_no and o.ext = i.order_ext
left join arnarel r (nolock) on o.cust_code = r.child
left join arcust m (nolock) on r.parent = m.customer_code
join arcust B (nolock) on o.cust_code = b.customer_code
join cvo_artermsd_installment z (nolock) on h.terms_code = z.terms_code and convert(int,right(h.doc_ctrl_num,1)) = z.sequence_id
where (o.freight <> 0 or o.total_tax <> 0)
and o.type = 'I'
and h.terms_code like 'INS%' 
and h.trx_type in (2031)
and h.doc_ctrl_num not like 'FIN%' 
and h.doc_ctrl_num not like 'CB%'
and h.void_flag <> 1					--v2.0 
-- AND dbo.f_cvo_get_buying_group(o.cust_code, CONVERT(varchar(10),DATEADD(DAY,h.date_doc - 693596, '01/01/1900'),121)) > '' -- v2.5


union

-- B -- Invoice and All Lines without header
select 
dbo.f_cvo_get_buying_group(o.cust_code, CONVERT(varchar(10),DATEADD(DAY,h.date_doc - 693596, '01/01/1900'),121)) parent, -- v2.5
dbo.f_cvo_get_buying_group_name	(dbo.f_cvo_get_buying_group(o.cust_code, CONVERT(varchar(10),DATEADD(DAY, h.date_doc - 693596, '01/01/1900'),121))) parent_name, -- v2.5
o.cust_code
,
b.customer_name as customer_name,
h.doc_ctrl_num,
z.installment_days as trm,
case when o.type = 'I' then 'Invoice' else 'Credit' end as type
,
convert(varchar(10), dateadd(dd, h.date_doc - 639906, '1/1/1753'),101) as inv_date,
sum(round((c.list_price * d.shipped) * (z.installment_prc/100),2)) as inv_tot,
sum(round((c.list_price * d.shipped) * (z.installment_prc/100),2)) as mer_tot,
0 as net_amt,
0 as freight,
0 as tax,
sum(d.Shipped * ROUND((d.curr_price - (d.curr_price * (d.discount / 100))) * (z.installment_prc/100),2)) as mer_disc,
sum(d.Shipped * ROUND((d.curr_price - (d.curr_price * (d.discount / 100))) * (z.installment_prc/100),2)) as inv_due,
disc_perc = CASE WHEN d.discount > 0 THEN d.discount/100 ELSE p.disc_perc END,
CASE h.date_due WHEN 0 THEN
	SUBSTRING(CONVERT(varchar(10),dateadd(dd,h.date_doc - 639906,'1/1/1753'),101),7,4)
	+'/'+ SUBSTRING(CONVERT(varchar(10),dateadd(dd,h.date_doc - 639906,'1/1/1753'),101),1,2)
ELSE	SUBSTRING(CONVERT(varchar(10),dateadd(dd,h.date_due - 639906,'1/1/1753'),101),7,4)
	+'/'+ SUBSTRING(CONVERT(varchar(10),dateadd(dd,h.date_due - 639906,'1/1/1753'),101),1,2)
END as due_year_month,
h.date_doc as xinv_date
from artrx_all h (nolock)
join orders_invoice i (nolock) on i.doc_ctrl_num = 
    left(h.doc_ctrl_num, 
    isnull(nullif(charindex('-',h.doc_ctrl_num)-1, -1), len(h.doc_ctrl_num)))
join orders o (nolock) on o.order_no =i.order_no and o.ext = i.order_ext
join ord_list d (nolock) on o.order_no = d.order_no and o.ext = d.order_ext
left join arnarel r (nolock) on o.cust_code = r.child
left join arcust m (nolock) on r.parent = m.customer_code
join arcust B (nolock) on o.cust_code = b.customer_code
join Cvo_ord_list c (nolock) on  d.order_no =c.order_no and d.order_ext = c.order_ext and d.line_no = c.line_no
join CVO_disc_percent p (nolock) on d.order_no = p.order_no and d.order_ext = p.order_ext and d.line_no = p.line_no
join cvo_artermsd_installment z (nolock) on h.terms_code = z.terms_code and convert(int,right(h.doc_ctrl_num,1)) = z.sequence_id
where 
d.shipped > 0
and h.terms_code like 'INS%' 
and h.trx_type in (2031)
and h.doc_ctrl_num not like 'FIN%' 
and h.doc_ctrl_num not like 'CB%' 
and h.void_flag <> 1					--v2.0
-- AND dbo.f_cvo_get_buying_group(o.cust_code, CONVERT(varchar(10),DATEADD(DAY,h.date_doc - 693596, '01/01/1900'),121)) > '' -- v2.5

group by r.parent, m.customer_name, o.cust_code, b.customer_name, h.doc_ctrl_num, z.installment_days, o.type, h.date_due,h.date_doc, d.discount, disc_perc, z.installment_prc


GO
GRANT REFERENCES ON  [dbo].[CVO_CustLog_installment_source_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[CVO_CustLog_installment_source_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[CVO_CustLog_installment_source_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[CVO_CustLog_installment_source_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[CVO_CustLog_installment_source_vw] TO [public]
GO
