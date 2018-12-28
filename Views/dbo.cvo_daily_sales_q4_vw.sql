SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW [dbo].[cvo_daily_sales_q4_vw] AS 
SELECT ar.territory_code,
       s.yyyymmdd,
       qg.Q4_G1,
       qg.Q4_G2,
       SUM(s.anet) day_sales
FROM cvo_sbm_details s (nolock)
    JOIN armaster ar (nolock)
        ON ar.customer_code = s.customer
           AND ar.ship_to_code = s.ship_to
    JOIN dbo.cvo_q4_goal_2018 AS qg ON qg.territory = ar.territory_code
WHERE c_year = 2018
      AND c_month > 9
GROUP BY ar.territory_code,
         s.yyyymmdd,
         qg.Q4_G1,
         qg.Q4_G2
GO
GRANT SELECT ON  [dbo].[cvo_daily_sales_q4_vw] TO [public]
GO
