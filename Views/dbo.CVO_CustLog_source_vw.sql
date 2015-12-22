SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- select * from cvo_custlog_source_vw where cust_code in ('032137')
  
CREATE view [dbo].[CVO_CustLog_source_vw] as  
-- select  * From cvo_bglog_source_vw where DOC_CTRL_NUM = 'inv0388976'
-- select * From cvo_bglog_source_vw where inv_date between '04/01/2013' and '04/10/2013'
-- v2.0 TM 04/27/2012 - Ignore AR Records that are Voided  
-- tag - 072712 - ar only credit's - dont qualify on the terms, as it doesn't matter  
-- tag - 1/3/2012 - fix so that mixed discount orders dont merge  
-- v2.1 CT 13/02/2013 - Change to return additional field of ndd containing credit return fees
-- v2.2 CB 26/02/2013 - View not including tax and freight only credits
-- v2.3 CB 21/03/2013 - Freight and tax not showing on std AR credit memo
-- v2.4 CT 21/03/2013 - Remove ndd filed, stop credit return fee lines being included in data returned

-- v2.5 CB 10/07/2013 - Issue #927 - Buying Group Switching
-- v2.6 CB 18/09/2013 - Issue #927 - Buying Group Switching - RB Orders set to and from BGs
 
-- 1 -- order h  - freight and tax
-- tag - don't even look for detail lines... dont need them
select   
case when isnull(cv.buying_group,'') = '' then h.cust_code 
     else cv.buying_group end as  parent, -- v2.6  
dbo.f_cvo_get_buying_group_name	(
case when isnull(cv.buying_group,'') = '' then h.cust_code else cv.buying_group end) as parent_name, -- v2.6 
h.cust_code,  
b.customer_name as customer_name,  
i.doc_ctrl_num,  
t.days_due as trm,  
'Invoice' as type,
convert(varchar(12),dateadd(d,x.date_doc-639906,'1/1/1753'),101) as inv_date,
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
from orders h (nolock)  
join orders_invoice i (nolock) on h.order_no =i.order_no and h.ext = i.order_ext  
join artrx x (nolock) on i.trx_ctrl_num = x.trx_ctrl_num  
left join arnarel r (nolock) on h.cust_code = r.child  
left join arcust m (nolock)on r.parent = m.customer_code  
join arcust B (nolock)on h.cust_code = b.customer_code  
join arterms t (nolock) on  h.terms = t.terms_code  
JOIN cvo_orders_all cv (NOLOCK) -- v2.6
ON   h.order_no = cv.order_no  -- v2.6
AND  h.ext = cv.ext   -- v2.6
where (h.freight <> 0 or h.total_tax <> 0)  
and h.type = 'I'  
and h.terms not like 'INS%'   
and x.void_flag <> 1     --v2.0  
-- AND cv.buying_group > '' -- v2.6


union  
  
-- 2 -- order lines  
select   
case when isnull(cv.buying_group,'') = '' then h.cust_code else cv.buying_group end as  parent, -- v2.6  
dbo.f_cvo_get_buying_group_name	(
case when isnull(cv.buying_group,'') = '' then h.cust_code else cv.buying_group end) as parent_name, -- v2.6 
h.cust_code,  
b.customer_name as customer_name,  
i.doc_ctrl_num,  
t.days_due as trm,  
'Invoice' as type,
convert(varchar(12),dateadd(dd,(x.date_doc)-639906,'1/1/1753'),101) as inv_date,
sum(round((c.list_price * d.shipped),2)) as inv_tot,  
sum(round((c.list_price * d.shipped),2)) as mer_tot,  
0 as net_amt,  
0 as freight,  
0 as tax,  
sum(d.Shipped * ROUND(curr_price -(curr_price * (d.discount / 100)),2)) as mer_disc,  
sum(d.Shipped * ROUND(curr_price -(curr_price * (d.discount / 100)),2)) as inv_due,  
disc_perc = CASE 	when suM(c.list_price) = 0 then 0
	WHEN d.discount > 0 and p.disc_perc <> 0 then -- two levels of discount in play
		round(1 - (sum(d.shipped*round(curr_price-(curr_price*(d.discount/100)),2)) 
		/
		sum(round((c.list_price * d.shipped),2)) ), 2)
	WHEN D.DISCOUNT > 0 AND P.DISC_PERC = 0 THEN 
		d.discount/100 
	ELSE p.disc_perc END,  
right(convert(varchar(12),dateadd(dd,max(x.date_due)-639906,'1/1/1753'),101),4)    
+ '/'+  
left(convert(varchar(12),dateadd(dd,max(x.date_due)-639906,'1/1/1753'),101),2)  
as due_year_month,  
x.date_doc as xinv_date
from orders h (nolock)  
join orders_invoice i (nolock) on h.order_no =i.order_no and h.ext = i.order_ext  
join arterms t (nolock) on h.terms = t.terms_code  
join artrx x (nolock) on i.doc_ctrl_num = x.doc_ctrl_num  
left join arnarel r (nolock) on h.cust_code = r.child  
left join arcust m (nolock)on r.parent = m.customer_code  
join arcust B (nolock)on h.cust_code = b.customer_code  
join ord_list d (nolock) on h.order_no = d.order_no and h.ext = d.order_ext  
join Cvo_ord_list c (nolock) on  d.order_no =c.order_no and d.order_ext = c.order_ext and d.line_no = c.line_no  
join CVO_disc_percent p (nolock) on d.order_no = p.order_no and d.order_ext = p.order_ext and d.line_no = p.line_no 
JOIN cvo_orders_all cv (NOLOCK) -- v2.6
ON   h.order_no = cv.order_no  -- v2.6
AND  h.ext = cv.ext   -- v2.6 
where d.shipped > 0  
and h.type = 'I'  
and h.terms not like 'INS%'   
and x.void_flag <> 1     --v2.0  
-- AND cv.buying_group > '' -- v2.6
group by cv.buying_group, m.customer_name, h.cust_code, b.customer_name, i.doc_ctrl_num, -- v2.6
t.days_due, h.type, x.date_doc, d.discount, disc_perc  


  
union   
  
-- 3 -- cr order header  - tax and freight portion
select   

case when isnull(cv.buying_group,'') = '' then h.cust_code else cv.buying_group end as  parent, -- v2.6  
dbo.f_cvo_get_buying_group_name	(
case when isnull(cv.buying_group,'') = '' then h.cust_code else cv.buying_group end) as parent_name, -- v2.6 
h.cust_code,  
b.customer_name as customer_name,  
i.doc_ctrl_num,  
t.days_due as trm,  
'Credit' as type,
convert(varchar(12),dateadd(dd,(x.date_doc)-639906,'1/1/1753'),101) as inv_date,
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
from orders h (nolock)  
join orders_invoice i (nolock) on h.order_no =i.order_no and h.ext = i.order_ext  
join artrx x (nolock) on i.doc_ctrl_num = x.doc_ctrl_num and x.trx_type = 2032  
left join arnarel r (nolock) on h.cust_code = r.child  
left join arcust m (nolock)on r.parent = m.customer_code  
join arcust B (nolock)on h.cust_code = b.customer_code  
join arterms t (nolock) on h.terms = t.terms_code  
JOIN cvo_orders_all cv (NOLOCK) -- v2.6
ON   h.order_no = cv.order_no  -- v2.6
AND  h.ext = cv.ext   -- v2.6
where (h.freight <> 0 or h.total_tax <> 0)  
and h.type = 'C'  
and h.terms not like 'INS%'   
and x.void_flag <> 1     --v2.0  
-- AND cv.buying_group > '' -- v2.6
  
union  
  --  4 -- cr order lines  
select   

case when isnull(cv.buying_group,'') = '' then h.cust_code else cv.buying_group end as  parent, -- v2.6  
dbo.f_cvo_get_buying_group_name	(
case when isnull(cv.buying_group,'') = '' then h.cust_code else cv.buying_group end) as parent_name, -- v2.6 
h.cust_code,  
b.customer_name as customer_name,  
i.doc_ctrl_num,  
t.days_due as trm,  
'Credit' as type,
convert(varchar(12),dateadd(dd,(x.date_doc)-639906,'1/1/1753'),101) as inv_date,
sum(round((c.list_price * d.cr_shipped),2)) * -1 as inv_tot,  
sum(round((c.list_price * d.cr_shipped),2)) * -1 as mer_tot,  
0 as net_amt,  
0 as freight,  
0 as tax,  
sum(d.cr_shipped * ROUND(curr_price -(curr_price * (d.discount / 100)),2,1)) * -1 as mer_disc,  
sum(d.cr_shipped * ROUND(curr_price -(curr_price * (d.discount / 100)),2,1)) * -1 as inv_due,  
disc_perc = CASE WHEN sum(c.list_price) = 0 then 0 
	when d.discount > 0 and p.disc_perc <> 0 then -- two levels of discount in play
		round(1 - (sum(d.cr_shipped*round(curr_price-(curr_price*(d.discount/100)),2)) 
		/
		sum(round((c.list_price * d.cr_shipped),2)) ), 2)
	WHEN D.DISCOUNT > 0 AND P.DISC_PERC = 0 THEN 
		d.discount/100 
	ELSE p.disc_perc END,    
right(convert(varchar(12),dateadd(dd,max(x.date_due)-639906,'1/1/1753'),101),4)    
+ '/'+  
left(convert(varchar(12),dateadd(dd,max(x.date_due)-639906,'1/1/1753'),101),2)  
as due_year_month, 
x.date_doc as xinv_date
from orders h (nolock)  
join orders_invoice i (nolock) on h.order_no =i.order_no and h.ext = i.order_ext  
join artrx x (nolock) on i.doc_ctrl_num = x.doc_ctrl_num and x.trx_type = 2032  
left join arnarel r (nolock) on h.cust_code = r.child  
left join arcust m (nolock)on r.parent = m.customer_code  
join arcust B (nolock)on h.cust_code = b.customer_code  
join ord_list d (nolock) on h.order_no = d.order_no and h.ext = d.order_ext  
join Cvo_ord_list c (nolock) on  d.order_no =c.order_no and d.order_ext = c.order_ext and d.line_no = c.line_no  
join CVO_disc_percent p (nolock) on d.order_no = p.order_no and d.order_ext = p.order_ext and d.line_no = p.line_no  
join arterms t (nolock) on h.terms = t.terms_code  
JOIN cvo_orders_all cv (NOLOCK) -- v2.6
ON   h.order_no = cv.order_no  -- v2.6
AND  h.ext = cv.ext   -- v2.6
where d.cr_shipped > 0  
and h.type = 'C'  
and h.terms not like 'INS%'   
and x.void_flag <> 1     --v2.0 
AND d.part_no <> 'Credit Return Fee' -- v2.4 
-- AND cv.buying_group > '' -- v2.6

group by cv.buying_group, m.customer_name, h.cust_code, b.customer_name, i.doc_ctrl_num, t.days_due, x.date_due, h.type, -- v2.6 
x.date_doc, d.discount, disc_perc  
  
union  
  
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
d.discount_prc/100,  
SUBSTRING(convert(varchar(12),dateadd(dd,h.date_due - 639906,'1/1/1753'),101),7,4)  
+ '/'+  
SUBSTRING(convert(varchar(12),dateadd(dd,h.date_due - 639906,'1/1/1753'),101),1,2)  
as due_year_month,  
h.date_doc as xinv_date
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
and h.void_flag <> 1     --v2.0  
-- AND dbo.f_cvo_get_buying_group(h.customer_code, CONVERT(varchar(10),DATEADD(DAY, h.date_doc - 693596, '01/01/1900'),121)) > '' -- v2.5
  
union  
  
-- 6 -- AR only records credit  
select   
dbo.f_cvo_get_buying_group(h.customer_code, CONVERT(varchar(10),DATEADD(DAY, h.date_doc - 693596, '01/01/1900'),121)) parent, -- v2.5
dbo.f_cvo_get_buying_group_name	(dbo.f_cvo_get_buying_group(h.customer_code, CONVERT(varchar(10),DATEADD(DAY, h.date_doc - 693596, '01/01/1900'),121))) parent_name, -- v2.5
h.customer_code,  
b.customer_name as customer_name,  
h.doc_ctrl_num,  
t.days_due as trm,  
'Credit' as type,
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
h.date_doc as xinv_date
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
--AND dbo.f_cvo_get_buying_group(h.customer_code, CONVERT(varchar(10),DATEADD(DAY, h.date_doc - 693596, '01/01/1900'),121)) > '' -- v2.5

union  
  
-- 6 AR Split only records  *** NEW ***  
select   
case when parent = '' then cust_code else parent end as parent,     
case when parent_name = '' then customer_name else parent_name end as parent_name,                
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
from CVO_CustLog_installment_source_vw (nolock)  

GO
GRANT REFERENCES ON  [dbo].[CVO_CustLog_source_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[CVO_CustLog_source_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[CVO_CustLog_source_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[CVO_CustLog_source_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[CVO_CustLog_source_vw] TO [public]
GO
