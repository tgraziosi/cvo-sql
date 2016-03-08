
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE VIEW [dbo].[cvo_SalesByCustomerType_vw] AS
-- tag - 052312 - add salesperson and territory
-- tag - 082812 - address armaster at ship-to level
SELECT 
b.addr_sort1,
b.salesperson_code,
b.territory_code,
a.customer, 
a.customer_name, 
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

FROM dbo.cvo_sbm_details a (NOLOCK) LEFT OUTER JOIN armaster b (NOLOCK) 
ON a.customer = b.customer_code  AND a.ship_to = b.ship_to_code

GROUP BY b.addr_sort1, b.salesperson_code, b.territory_code, a.customer, a.customer_name, a.year

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
