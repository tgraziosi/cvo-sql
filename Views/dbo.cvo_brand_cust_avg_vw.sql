SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW [dbo].[cvo_brand_cust_avg_vw] 
AS 

-- 11/29/2016 - tag - Use to plot brand progress by week by quarter (release date) and quartile (percentile rank of brand)

SELECT buwt.brand, buwt.type_code, buwt.wkno, 
AVG(buwt.num_cust) avg_cust, 'Q'+CAST(s.qtr AS CHAR(1)) qtr,  s.tile

FROM dbo.cvo_brand_units_week_tbl AS buwt
JOIN 
(SELECT brand, model, rel_date, 
DATEPART(quarter,rel_date) qtr, 
MAX(wkno) tot_weeks, 
SUM(num_cust) tot_cust, 
NTILE(4) OVER (PARTITION BY brand ORDER BY SUM(num_cust) ) AS tile
 FROM [dbo].[cvo_brand_units_week_tbl]
 GROUP BY brand ,
          MODEL,
		  rel_date
HAVING MAX(wkno) >=52
) s ON s.brand = buwt.brand AND s.MODEL = buwt.MODEL AND s.rel_date = buwt.rel_date

WHERE wkno <=52
GROUP BY buwt.brand ,
		 buwt.type_code,
         buwt.wkno ,
         s.qtr ,
         s.tile
-- ORDER BY brand, qtr, tile, wkno

GO
GRANT REFERENCES ON  [dbo].[cvo_brand_cust_avg_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[cvo_brand_cust_avg_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[cvo_brand_cust_avg_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[cvo_brand_cust_avg_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[cvo_brand_cust_avg_vw] TO [public]
GO
