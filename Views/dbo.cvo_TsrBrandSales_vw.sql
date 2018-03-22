SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW [dbo].[cvo_TsrBrandSales_vw] AS 

SELECT ar.territory_code, i.category, 
-- s.month, s.x_month, 
	SUM(anet) Net_sales, SUM(qnet) Net_qty,
	COUNT(DISTINCT customer+ship_to) UC
FROM cvo_sbm_details s (NOLOCK)
JOIN armaster ar (NOLOCK) ON ar.customer_code = s.customer AND ar.ship_to_code = s.ship_to
JOIN inv_master i (NOLOCK) ON i.part_no = s.part_no
WHERE i.type_code IN ('frame','sun','acc')
AND yyyymmdd >= DATEADD(m,-12, GETDATE())

GROUP BY ar.territory_code,
         i.category

GO
GRANT SELECT ON  [dbo].[cvo_TsrBrandSales_vw] TO [public]
GO
