SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




-- select * from cvo_brandunitsalesbymonth_vw

CREATE VIEW [dbo].[cvo_BrandUnitSalesByMonth_vw] AS
SELECT 
i.category AS Brand,
ia.field_2 AS Model,
i.type_code type,
ia.category_2 Gender,
MIN(ia.field_26) rel_date,
MIN(ia.field_28) pom_date,
DATEPART(yyyy,yyyymmdd) AS [year],
SUM(ISNULL((CASE a.x_month WHEN 1 THEN a.qnet END), 0)) AS jan,
SUM(ISNULL((CASE a.x_month WHEN 2 THEN a.qnet END), 0)) AS feb,
SUM(ISNULL((CASE a.x_month WHEN 3 THEN a.qnet END), 0)) AS mar,
SUM(ISNULL((CASE a.x_month WHEN 4 THEN a.qnet END), 0)) AS apr,
SUM(ISNULL(CASE a.x_month WHEN 5 THEN a.qnet END, 0)) AS may,
SUM(ISNULL(CASE a.x_month WHEN 6 THEN a.qnet END, 0)) AS jun,
SUM(ISNULL(CASE a.x_month WHEN 7 THEN a.qnet END, 0)) AS jul,
SUM(ISNULL(CASE a.x_month WHEN 8 THEN a.qnet END, 0)) AS aug,
SUM(ISNULL(CASE a.x_month WHEN 9 THEN a.qnet END, 0)) AS sep,
SUM(ISNULL(CASE a.x_month WHEN 10 THEN a.qnet END, 0)) AS oct,
SUM(ISNULL(CASE a.x_month WHEN 11 THEN a.qnet END, 0)) AS nov,
SUM(ISNULL(CASE a.x_month WHEN 12 THEN a.qnet END, 0))AS dec,
SUM(ISNULL(a.qnet,0)) AS Total
, location

FROM cvo_sbm_details a (NOLOCK)  
INNER JOIN inv_master i (NOLOCK) ON i.part_no = a.part_no
INNER JOIN inv_master_add ia (NOLOCK) ON ia.part_no = a.part_no
WHERE i.type_code IN ('frame','sun') 

GROUP BY i.category, ia.field_2, ia.category_2, i.type_code, DATEPART(yyyy,a.yyyymmdd), location
-- group by brand, model, type_code, datepart(yyyy,yyyymmdd)









GO

GRANT SELECT ON  [dbo].[cvo_BrandUnitSalesByMonth_vw] TO [public]
GO
