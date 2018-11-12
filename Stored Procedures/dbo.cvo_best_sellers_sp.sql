SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[cvo_best_sellers_sp] @sdate DATETIME = null, @edate DATETIME = null, @r_option INT = null

AS 
BEGIN

DECLARE @today DATETIME

IF @sdate IS NULL OR @edate IS NULL
SELECT @sdate = BeginDate,
       @edate = EndDate
FROM dbo.cvo_date_range_vw AS drv
WHERE Period = 'Last Month';

SELECT @today = GETDATE();

IF @r_option IS NULL SELECT @r_option = 0;

WITH r
AS (SELECT t.territory_code,
           CASE
               WHEN @r_option = 0 THEN
                   'ALL'
               ELSE
                   dbo.calculate_region_fn(t.territory_code)
           END region
    FROM dbo.arterr t)
SELECT r.region,
       imrv.CollectionName,
       imrv.PrimaryDemo_Web,
       imrv.PrimaryDemographic,
       imrv.RES_type,
       imrv.model,
       MAX(imrv.specialty_fit) specialty_fit,
       SUM(s.qnet) net_qty,
       RANK() OVER (PARTITION BY r.region,
                                 imrv.CollectionName,
                                 imrv.PrimaryDemo_web,
                                 imrv.RES_type
                    ORDER BY SUM(s.qnet) DESC
                   ) rank_num
FROM dbo.cvo_inv_master_r2_tbl AS imrv (nolock)
    JOIN dbo.cvo_sbm_details s (nolock)
        ON s.part_no = imrv.part_no
    JOIN dbo.armaster ar (nolock)
        ON ar.customer_code = s.customer
           AND ar.ship_to_code = s.ship_to
    JOIN r
        ON r.territory_code = ar.territory_code
WHERE ISNULL(imrv.pom_date, @today) >= @today
      AND s.yyyymmdd
      BETWEEN @sdate AND @edate
      AND imrv.Collection NOT IN ('ge','ls','sp')
      AND model <> 'colorful'
GROUP BY r.region,
         imrv.CollectionName,
         imrv.PrimaryDemo_Web,
         imrv.PrimaryDemographic,
         imrv.RES_type,
         imrv.model;

END;

GRANT EXECUTE ON dbo.cvo_best_sellers_sp TO PUBLIC


GO
GRANT EXECUTE ON  [dbo].[cvo_best_sellers_sp] TO [public]
GO
