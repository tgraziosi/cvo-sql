SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/* -- test -- 
select sum(total), [year] from cvo_bgsbm_vw group by [year]
select sum(anet), [year] from cvo_customer_sales_by_month group by [year]
*/
CREATE VIEW [dbo].[cvo_BGsbm_vw] AS
SELECT
CASE WHEN 
	m.addr_sort1 <> 'Buying Group' OR m.addr_sort1 IS NULL THEN 'NON-BG'
	ELSE ISNULL(r.parent,'NON-BG') END AS Parent, 
CASE WHEN
	m.addr_sort1 <> 'Buying Group' OR m.addr_sort1 IS NULL THEN 'NON-BG'
	ELSE ISNULL(m.customer_name,'NON-BG') END AS Parent_name, 
----case when r.parent is null then 'NONE'
---- else h.customer end as Customer,
----case when r.parent is null then 'NONE'
---- else b.customer_name end as customer_name,
COUNT(DISTINCT a.customer) NumMembers,
a.year,
SUM(ISNULL((CASE a.x_month WHEN 1 THEN a.anet END), 0)) AS jan,
SUM(ISNULL((CASE a.x_month WHEN 2 THEN a.anet END), 0)) AS feb,
SUM(ISNULL((CASE a.x_month WHEN 3 THEN a.anet END), 0)) AS mar,
SUM(ISNULL((CASE a.x_month WHEN 4 THEN a.anet END), 0)) AS apr,
SUM(ISNULL(CASE a.x_month WHEN 5 THEN a.anet END, 0)) AS may,
SUM(ISNULL(CASE a.x_month WHEN 6 THEN a.anet END, 0)) AS jun,
SUM(ISNULL(CASE a.x_month WHEN 7 THEN a.anet END, 0)) AS jul,
SUM(ISNULL(CASE a.x_month WHEN 8 THEN a.anet END, 0)) AS aug,
SUM(ISNULL(CASE a.x_month WHEN 9 THEN a.anet END, 0)) AS sep,
SUM(ISNULL(CASE a.x_month WHEN 10 THEN a.anet END, 0)) AS oct,
SUM(ISNULL(CASE a.x_month WHEN 11 THEN a.anet END, 0)) AS nov,
SUM(ISNULL(CASE a.x_month WHEN 12 THEN a.anet END, 0))AS dec,
SUM(ISNULL(a.anet,0)) AS Total

--yyyymmdd = cast(convert(varchar(2),h.[x_month])+'/1/'+convert(varchar(4),h.[year]) as datetime),
--sum(anet) as NetSales
FROM cvo_customer_sales_by_month_vw a (NOLOCK)
LEFT OUTER JOIN arnarel r (NOLOCK) ON a.customer = r.child
LEFT OUTER JOIN arcust m (NOLOCK)ON r.parent = m.customer_code 
LEFT OUTER JOIN arcust B (NOLOCK)ON a.customer = b.customer_code
--where m.addr_sort1 = 'Buying Group' or m.addr_sort1 is null
GROUP BY 
CASE WHEN 
	m.addr_sort1 <> 'Buying Group' OR m.addr_sort1 IS NULL THEN 'NON-BG'
	ELSE ISNULL(r.parent,'NON-BG') END, 
CASE WHEN
	m.addr_sort1 <> 'Buying Group' OR m.addr_sort1 IS NULL THEN 'NON-BG'
	ELSE ISNULL(m.customer_name,'NON-BG') END,
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
