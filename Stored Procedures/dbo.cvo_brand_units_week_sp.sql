SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[cvo_brand_units_week_sp] (@coll VARCHAR(10) = null)

AS 

-- exec cvo_brand_units_week_sp null

SET NOCOUNT ON;

-- drop table cvo_brand_units_week_tbl

IF ( OBJECT_ID('dbo.cvo_brand_units_week_tbl') IS NULL )
    BEGIN
        CREATE TABLE dbo.cvo_brand_units_week_tbl
            (
              brand VARCHAR(10) ,
              MODEL VARCHAR(40) ,
              rel_date DATETIME ,
              type_code VARCHAR(10) ,
              rel_date_wk INT ,
              first_sale_wk INT ,
              wkno BIGINT ,
              num_cust INT ,
              net_qty FLOAT(8) ,
              st_qty FLOAT(8) ,
              rx_qty FLOAT(8),
			  ret_qty FLOAT(8),
			  cl_qty FLOAT(8),
			  asofdate datetime
            );
		CREATE INDEX idx_brand_units_week 
		ON dbo.cvo_brand_units_week_tbl
		(brand ASC, model ASC, wkno ASC);
    END;

TRUNCATE TABLE cvo_brand_units_week_tbl;

;WITH cte AS 
(SELECT i.category brand, IA.FIELD_2 MODEL, MIN(ia.field_26) rel_date, i.type_code,
MIN(yyyymmdd) first_brand_sale,
ar.customer_code + CASE WHEN car.door = 1 THEN '-'+ar.ship_to_code ELSE '' END AS customer,
SUM(qnet) net_qty, 
SUM(CASE WHEN sbm.user_category NOT LIKE 'rx%' THEN qnet ELSE 0 END) st_qty, 
SUM(CASE WHEN sbm.user_category LIKE 'rx%' THEN qnet ELSE 0 END) rx_qty,
SUM(CASE WHEN sbm.return_code <> 'exc' THEN qreturns ELSE 0 END) ret_qty,
SUM(CASE WHEN sbm.iscl=1 THEN qnet ELSE 0 END) cl_qty
FROM cvo_sbm_details sbm
JOIN dbo.CVO_armaster_all AS car ON car.ship_to = sbm.ship_to AND car.customer_code = sbm.customer
JOIN ARMASTER AR ON AR.customer_code = car.customer_code AND AR.ship_to_code = car.ship_to
JOIN inv_master i ON i.part_no = sbm.part_no
JOIN dbo.inv_master_add AS ia ON ia.part_no = i.part_no
WHERE yyyymmdd >= DATEADD (YEAR,-2,GETDATE())
AND ia.field_26 >= DATEADD(YEAR,-2,GETDATE())
AND i.category = CASE WHEN @coll IS NULL THEN i.category ELSE @coll end
AND i.type_code IN ('frame','sun')
AND ISNULL(ia.field_32,'') NOT IN ('hvc','retail','specialord')
GROUP BY ar.customer_code + CASE WHEN car.door = 1 THEN '-'+ar.ship_to_code ELSE '' END ,
         i.category ,
         ia.field_2 ,
		 i.type_code
)

INSERT INTO dbo.cvo_brand_units_week_tbl
        ( brand ,
          MODEL ,
          rel_date ,
          type_code ,
          rel_date_wk ,
          first_sale_wk ,
          wkno ,
          num_cust ,
          net_qty ,
          st_qty ,
          rx_qty ,
		  ret_qty, 
		  cl_qty,
          asofdate
        )
SELECT cte.brand ,
       cte.MODEL ,
	   CONVERT(DATETIME,cte.rel_date,110) rel_date,
	   cte.type_code ,
	   CAST(CAST (DATEPART(YEAR,cte.rel_date) AS VARCHAR(4)) 
			+RIGHT('00'+CAST(DATEPART(week,cte.rel_date) AS VARCHAR(2)),2) AS INT) AS rel_date_wk ,

	   CAST(CAST (DATEPART(YEAR,cte.first_brand_sale) AS VARCHAR(4)) 
			+RIGHT('00'+CAST(DATEPART(week,cte.first_brand_sale) AS VARCHAR(2)),2) AS INT) AS first_sale_wk,

	   ROW_NUMBER() OVER(PARTITION BY model ORDER BY model,    CAST(CAST (DATEPART(YEAR,cte.first_brand_sale) AS VARCHAR(4)) 
			+RIGHT('00'+CAST(DATEPART(week,cte.first_brand_sale) AS VARCHAR(2)),2) AS INT)) AS wkno,

       COUNT(DISTINCT cte.customer) num_cust,
       SUM(cte.net_qty) net_qty ,
       SUM(cte.st_qty) st_qty ,
       SUM(cte.rx_qty) rx_qty ,
	   SUM(cte.ret_qty) ret_qty,
	   SUM(cte.cl_qty) cl_qty,
	   GETDATE()

	   FROM cte
	   GROUP BY cte.brand ,
                cte.MODEL ,
                cte.rel_date ,
				cte.type_code,
				CAST(CAST (DATEPART(YEAR,cte.first_brand_sale) AS VARCHAR(4)) 
			+RIGHT('00'+CAST(DATEPART(week,cte.first_brand_sale) AS VARCHAR(2)),2) AS INT)
  
	   ORDER BY cte.brand, cte.MODEL, wkno




GO
