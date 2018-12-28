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
AS (SELECT t.territory_code, 'ALL' region
    FROM dbo.arterr t
    WHERE dbo.calculate_region_fn(t.territory_code) NOT IN ('800','900')
    UNION ALL
    SELECT t.territory_code, dbo.calculate_region_fn(t.territory_code) region
    FROM dbo.arterr t
    WHERE dbo.calculate_region_fn(t.territory_code) NOT IN ('800','900')
    )
SELECT r.region,
       imrv.CollectionName CollectionName,
       CASE WHEN imrv.RES_type = 'Sun' THEN imrv.RES_type 
            WHEN imrv.Collection = 'OP' AND imrv.PrimaryDemographic = 'kids' THEN imrv.PrimaryDemo_Web
            ELSE imrv.PrimaryDemographic END PrimaryDemographic,
       imrv.RES_type,
       imrv.model,
       CASE WHEN imrv.res_type = 'sun' THEN imrv.PrimaryDemographic ELSE MAX(REPLACE(imrv.specialty_fit,' ','')) END specialty_fit,
       SUM(s.qnet) net_qty,
       row_number() OVER (PARTITION BY r.region,
                                 imrv.CollectionName + CASE WHEN imrv.RES_type = 'SUN' AND imrv.Collectionname IN('Steve madden','revo') THEN imrv.PrimaryDemographic ELSE '' END,
                                 CASE
                                 WHEN imrv.res_type = 'SUN' AND imrv.collectionname <> 'revo' THEN 'SUN' 
                                 WHEN imrv.collectionname IN ('dilli dalli') THEN 'pediatric'
                                 WHEN imrv.CollectionName IN ('steve madden','blutech') AND imrv.PrimaryDemographic IN ('boys','girls') THEN 'kids'
                                 ELSE imrv.PrimaryDemographic end,
                                 imrv.RES_type
                    ORDER BY SUM(s.qnet) DESC
                   ) rank_num,
        CASE WHEN (imrv.PrimaryDemographic = 'women' AND imrv.res_type <> 'sun') OR (imrv.RES_type = 'sun' AND imrv.CollectionName < 'revo') THEN 1
        WHEN (imrv.PrimaryDemographic = 'men' AND imrv.RES_type <> 'sun')  OR (imrv.RES_type = 'sun' AND imrv.CollectionName >= 'revo') THEN 2
        ELSE 3 END list_num
FROM dbo.cvo_inv_master_r2_tbl AS imrv (nolock)
    JOIN dbo.cvo_sbm_details s (nolock)
        ON s.part_no = imrv.part_no
    JOIN dbo.armaster ar (nolock)
        ON ar.customer_code = s.customer
           AND ar.ship_to_code = s.ship_to
    JOIN r
        ON r.territory_code = ar.territory_code
WHERE ISNULL(imrv.pom_date, @edate) >= @edate
      AND s.yyyymmdd
      BETWEEN @sdate AND @edate
      AND imrv.Collection NOT IN ('ge','ls','sp','fn')
      AND model <> 'colorful'
      AND NOT EXISTS (SELECT 1 FROM dbo.cvo_part_attributes pa 
        WHERE attribute IN ('HV','HVC','retail','costco','SpecialOrd') AND pa.part_no = imrv.part_no)
      AND NOT (imrv.collection IN ('izod','izx') AND imrv.PrimaryDemographic IN ('boys','girls'))
GROUP BY CASE
         WHEN imrv.RES_type = 'Sun' THEN
         imrv.RES_type
         WHEN imrv.Collection = 'OP'
         AND imrv.PrimaryDemographic = 'kids' THEN
         imrv.PrimaryDemo_Web
         ELSE
         imrv.PrimaryDemographic
         END,
         CASE
         WHEN imrv.PrimaryDemographic = 'women'
         OR imrv.RES_type = 'sun' THEN
         1
         WHEN imrv.PrimaryDemographic = 'men' THEN
         2
         ELSE
         3
         END,
         r.region,
         imrv.CollectionName,
         imrv.RES_type,
         imrv.model,
         imrv.PrimaryDemographic
HAVING SUM(s.qnet) > 0

END;

GRANT EXECUTE ON dbo.cvo_best_sellers_sp TO PUBLIC







GO
GRANT EXECUTE ON  [dbo].[cvo_best_sellers_sp] TO [public]
GO
