SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/* -- test -- 
select sum(total), [year] from cvo_bgsbm_vw group by [year]
select sum(anet), [year] from cvo_customer_sales_by_month group by [year]
*/
CREATE view [dbo].[cvo_BGsbm_vw] as
select
case when 
	m.addr_sort1 <> 'Buying Group' or m.addr_sort1 is null then 'NON-BG'
	else isnull(r.parent,'NON-BG') end as Parent, 
case when
	m.addr_sort1 <> 'Buying Group' or m.addr_sort1 is null then 'NON-BG'
	else isnull(m.customer_name,'NON-BG') end as Parent_name, 
----case when r.parent is null then 'NONE'
---- else h.customer end as Customer,
----case when r.parent is null then 'NONE'
---- else b.customer_name end as customer_name,
count(distinct a.customer) NumMembers,
a.year,
sum(isnull((case a.x_month when 1 then a.anet end), 0)) as jan,
sum(isnull((case a.x_month when 2 then a.anet end), 0)) as feb,
sum(isnull((case a.x_month when 3 then a.anet end), 0)) as mar,
sum(isnull((case a.x_month when 4 then a.anet end), 0)) as apr,
sum(isnull(case a.x_month when 5 then a.anet end, 0)) as may,
sum(isnull(case a.x_month when 6 then a.anet end, 0)) as jun,
sum(isnull(case a.x_month when 7 then a.anet end, 0)) as jul,
sum(isnull(case a.x_month when 8 then a.anet end, 0)) as aug,
sum(isnull(case a.x_month when 9 then a.anet end, 0)) as sep,
sum(isnull(case a.x_month when 10 then a.anet end, 0)) as oct,
sum(isnull(case a.x_month when 11 then a.anet end, 0)) as nov,
sum(isnull(case a.x_month when 12 then a.anet end, 0))as dec,
sum(isnull(a.anet,0)) as Total

--yyyymmdd = cast(convert(varchar(2),h.[x_month])+'/1/'+convert(varchar(4),h.[year]) as datetime),
--sum(anet) as NetSales
from cvo_customer_sales_by_month a (nolock)
left outer join arnarel r (nolock) on a.customer = r.child
left outer join arcust m (nolock)on r.parent = m.customer_code 
left outer join arcust B (nolock)on a.customer = b.customer_code
--where m.addr_sort1 = 'Buying Group' or m.addr_sort1 is null
group by 
case when 
	m.addr_sort1 <> 'Buying Group' or m.addr_sort1 is null then 'NON-BG'
	else isnull(r.parent,'NON-BG') end, 
case when
	m.addr_sort1 <> 'Buying Group' or m.addr_sort1 is null then 'NON-BG'
	else isnull(m.customer_name,'NON-BG') end,
--m.addr_sort1,
--r.parent,
--m.customer_name,
--isnull(r.parent,'NONE'),
--isnull(m.customer_name,'NONE'),
----case when r.parent is null then 'NONE'
-- else h.customer end,
--case when r.parent is null then 'NONE'
-- else b.customer_name end,
a.[year]
GO
GRANT REFERENCES ON  [dbo].[cvo_BGsbm_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[cvo_BGsbm_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[cvo_BGsbm_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[cvo_BGsbm_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[cvo_BGsbm_vw] TO [public]
GO
