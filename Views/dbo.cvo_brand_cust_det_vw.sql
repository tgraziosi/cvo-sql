SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create VIEW [dbo].[cvo_brand_cust_det_vw] 
AS 

SELECT buwt.brand ,
       buwt.MODEL ,
       buwt.rel_date ,
       buwt.type_code ,
       buwt.rel_date_wk ,
       buwt.first_sale_wk ,
       buwt.wkno ,
       buwt.num_cust ,
       buwt.net_qty ,
       buwt.st_qty ,
       buwt.rx_qty ,
       buwt.asofdate
	   , s.tot_weeks, s.tot_cust, s.qtr,  s.tile
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

GO
GRANT REFERENCES ON  [dbo].[cvo_brand_cust_det_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[cvo_brand_cust_det_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[cvo_brand_cust_det_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[cvo_brand_cust_det_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[cvo_brand_cust_det_vw] TO [public]
GO
