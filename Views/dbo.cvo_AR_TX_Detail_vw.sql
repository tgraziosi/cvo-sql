SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




CREATE view [dbo].[cvo_AR_TX_Detail_vw]
as 

select 
t2.salesperson_code as Salesperson, 
t2.territory_code as Territory, 
t2.customer_code as Cust_code, 
t2.ship_to_code as Ship_to, 
t2.order_ctrl_num,
t2.gl_trx_id,
t1.doc_ctrl_num,
t1.trx_ctrl_num,
t1.date_posted,
-- convert(varchar,dateadd(d,t1.date_posted-711858,'1/1/1950'),101) AS DatePosted,
t1.date_applied,
-- convert(varchar,dateadd(d,t1.DATE_APPLIED-711858,'1/1/1950'),101) AS DateApplied,
CASE WHEN t1.trx_type = '2031' THEN 'Invoice' ELSE 'Credit' END as type,
CASE 
	WHEN t1.trx_type = '2031' THEN (t2.amt_net - (t2.amt_freight+t2.amt_tax)) 
	ELSE case when t2.recurring_flag < 2 then (t2.amt_net - (t2.amt_freight+t2.amt_tax)) * -1 else 0 end
 END as Total_Sales_Amount,

t2.doc_desc,
t1.location_code,
t1.item_code,
left(t1.line_desc,60) as line_desc,
case when t1.trx_type = '2031' then t1.qty_shipped
	else t1.qty_returned*-1
end as QTY,
--t1.unit_price,
CASE t1.trx_type
	when '2031' then t1.extended_price
	else case when t2.recurring_flag < 2 then t1.extended_price * -1 else 0 end
end as Extended_price,
-- 02/12/13 - tag - add discount amount
case t1.trx_type when '2031' then t1.discount_amt 
	else case when t2.recurring_flag < 2 then t1.discount_amt * -1 else 0 end
end as Discount_amt,
t1.trx_type, 
t1.gl_rev_acct,
left(t1.gl_rev_acct,4) as NaturalAccount,
'POSTED' as Posted
--,* 
from artrxcdt t1 (nolock),
artrx t2 (nolock)
where 
t1.trx_type in ('2031','2032') and
t1.trx_ctrl_num = t2.trx_ctrl_num 
AND t2.DOC_DESC NOT LIKE 'CONVERTED%'
AND t2.doc_desc NOT LIKE '%NONSALES%'
and t2.doc_desc not like 'Freight Credit' -- 2/28
and t2.doc_ctrl_num not like ('CRMX%') -- 2/28
AND t2.doc_ctrl_num NOT LIKE 'CB%'
AND t2.doc_ctrl_num NOT LIKE 'FIN%'
and t2.void_flag = 0

union all

select 
t2.salesperson_code as Salesperson, 
t2.territory_code as Territory, 
t2.customer_code as Cust_code, 
t2.ship_to_code as Ship_to, 
t2.order_ctrl_num,
'' as gl_trx_id,
t1.doc_ctrl_num,
t1.trx_ctrl_num,
0 as Date_Posted,
--convert(varchar,dateadd(d,t2.date_posted-711858,'1/1/1950'),101) AS DatePosted,
t2.date_applied,
-- convert(varchar,dateadd(d,t2.DATE_APPLIED-711858,'1/1/1950'),101) AS DateApplied,
CASE WHEN t1.trx_type = '2031' THEN 'Invoice' ELSE 'Credit' END as type,
CASE 
	WHEN t1.trx_type = '2031' THEN (t2.amt_net - (t2.amt_freight+t2.amt_tax)) 
	ELSE case when t2.recurring_flag < 2 then (t2.amt_net - (t2.amt_freight+t2.amt_tax)) * -1 else 0 end
 END as Total_Sales_Amount,

t2.doc_desc,
t1.location_code,
t1.item_code,
left(t1.line_desc,60) as Line_desc,
t1.qty_shipped,
--t1.unit_price,
CASE t1.trx_type
	when '2031' then t1.extended_price
	else case when t2.recurring_flag < 2 then t1.extended_price * -1 else 0 end
end as Extended_price,
-- 02/12/13 - tag - add discount amount
case t1.trx_type when '2031' then t1.discount_amt 
	else case when t2.recurring_flag < 2 then t1.discount_amt * -1 else 0 end
end as Discount_amt,
t1.trx_type, 
t1.gl_rev_acct,
left(t1.gl_rev_acct,4) as NaturalAccount,
'UNPOSTED' as Posted
--,* 
from arinpcdt t1 (nolock),
arinpchg t2 (nolock)
where 
t1.trx_type in ('2031','2032') and
t1.trx_ctrl_num = t2.trx_ctrl_num 
AND t2.DOC_DESC NOT LIKE 'CONVERTED%'
AND t2.doc_desc NOT LIKE '%NONSALES%'
and t2.doc_desc not like 'Freight Credit' -- 2/28
and t2.doc_ctrl_num not like ('CRMX%') -- 2/28
AND t2.doc_ctrl_num NOT LIKE 'CB%'
AND t2.doc_ctrl_num NOT LIKE 'FIN%'




GO
GRANT REFERENCES ON  [dbo].[cvo_AR_TX_Detail_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[cvo_AR_TX_Detail_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[cvo_AR_TX_Detail_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[cvo_AR_TX_Detail_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[cvo_AR_TX_Detail_vw] TO [public]
GO
