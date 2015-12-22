SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE view [dbo].[cvo_SalesByCustomerType_vw] as
-- tag - 052312 - add salesperson and territory
-- tag - 082812 - address armaster at ship-to level
select 
b.addr_sort1,
b.salesperson_code,
b.territory_code,
a.customer, 
a.customer_name, 
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

from cvo_csbm_shipto a (nolock) left outer join armaster b (nolock) 
on a.customer = b.customer_code  and a.ship_to = b.ship_to_code

group by b.addr_sort1, b.salesperson_code, b.territory_code, a.customer, a.customer_name, a.year
GO
GRANT REFERENCES ON  [dbo].[cvo_SalesByCustomerType_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[cvo_SalesByCustomerType_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[cvo_SalesByCustomerType_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[cvo_SalesByCustomerType_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[cvo_SalesByCustomerType_vw] TO [public]
GO
