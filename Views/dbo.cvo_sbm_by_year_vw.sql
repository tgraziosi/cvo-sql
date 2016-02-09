SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW [dbo].[cvo_sbm_by_year_vw] AS 
SELECT year, SUM(anet) netsales
FROM cvo_sbm_details s
JOIN armaster ar ON ar.customer_code = s.customer AND ar.ship_to_code = s.ship_to
-- WHERE ar.territory_code IN (90911, 90999)
GROUP BY year
-- ORDER BY YEAR
GO
GRANT REFERENCES ON  [dbo].[cvo_sbm_by_year_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[cvo_sbm_by_year_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[cvo_sbm_by_year_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[cvo_sbm_by_year_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[cvo_sbm_by_year_vw] TO [public]
GO
