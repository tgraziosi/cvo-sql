SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[cvo_ifp_rank_refresh_sp]
@br VARCHAR(1024) = null, 
@rs VARCHAR(10) ,
@asofdate DATETIME = null, 
@months INT = 3, 
@debug INT = 0

AS 
BEGIN

-- exec cvo_ifp_rank_refresh_sp 'rr', 'frame', null, 3, 1
-- SELECT * fROM CVO_IFP_CONFIG
-- select * from cvo_ifp_rank where brand = 'rr'
SET NOCOUNT ON
SET ANSI_WARNINGS OFF

DECLARE @m INT, @today DATETIME, @asof DATETIME
SELECT @m = @months, @TODAY = GETDATE(), @asof = @asofdate
DECLARE @p1s DATETIME, @p1e DATETIME, @p2s DATETIME, @p2e DATETIME, @p3s DATETIME, @p3e DATETIME

IF @asofdate IS NULL 
SELECT @asof = ENDdate FROM dbo.cvo_date_range_vw WHERE period = 'Last Month'
ELSE
SELECT @asof = @asofdate

SELECT @p1s = DATEADD(m,-1,DATEADD(d,1,@asof))
SELECT @p1e = DATEADD(HOUR,23,@asof)

SELECT @p2s = DATEADD(m,-1,@p1s)
SELECT @p2e = DATEADD(HOUR,23,DATEADD(d,-1,@p1s))

SELECT @p3s = DATEADD(m,-1,@p2s)
SELECT @p3e = DATEADD(HOUR,23,DATEADD(d,-1,@p2s))

IF @debug = 1 SELECT @asof, @p1s, @p1e, @p2s, @p2e, @p3s, @p3e


-- SELECT * FROM dbo.cvo_date_range_vw AS drv


CREATE TABLE #brand ([brand] VARCHAR(20))
IF @br IS NULL 
BEGIN
	INSERT INTO #brand ( brand )
	SELECT DISTINCT kys FROM category WHERE void = 'N'
END
else
BEGIN
	INSERT INTO #brand ([brand])
	SELECT  LISTITEM FROM dbo.f_comma_list_to_table(@br)
END

BEGIN
	INSERT INTO #brand ([brand])
	SELECT  LISTITEM FROM dbo.f_comma_list_to_table(@rs)
END

--IF @DEBUG = 1 SELECT * FROM #brand AS b

-- drop table dbo.cvo_ifp_rank

IF(OBJECT_ID('dbo.cvo_ifp_rank') is null)  
begin
 CREATE TABLE cvo_ifp_rank( id INT IDENTITY(1,1),
[brand] varchar(10)
, [style] varchar(40)
, [res_type] VARCHAR(10)
, [rel_date] DATETIME
, [pom_date] DATETIME
, [m3_net] FLOAT
, [m2_net] FLOAT
, [m1_net] float
, [net_qty] FLOAT
, [months_of_sales] int
, [TIER] varchar(1)
, [ORDER_THRU_DATE] DATETIME
, last_upd_date datetime )
CREATE UNIQUE CLUSTERED INDEX [idx_ifp_rank] ON [dbo].[cvo_ifp_rank]
(	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)

end


ELSE
BEGIN
	DELETE FROM dbo.cvo_ifp_rank 
	WHERE EXISTS (SELECT 1 FROM #brand b WHERE b.brand = cvo_ifp_rank.brand)
		  AND cvo_ifp_rank.res_type = @rs
end

-- INSERT INTO cvo_ifp_rank
SELECT i.category brand, ia.field_2 style
, @rs res_type
, MIN(ISNULL(ia.field_26,'1/1/1949')) rel_date
, MAX(ISNULL(ia.field_28,'12/31/2099')) pom_date
, SUM(ISNULL(CASE WHEN yyyymmdd BETWEEN @p3s AND @p3e THEN qnet ELSE 0 END,0)) m3_qnet
, SUM(ISNULL(CASE WHEN yyyymmdd BETWEEN @p2s AND @p2e THEN qnet ELSE 0 END,0)) m2_qnet
, SUM(ISNULL(CASE WHEN yyyymmdd BETWEEN @p1s AND @p1e THEN qnet ELSE 0 END,0)) m1_qnet
, SUM(ISNULL(qnet,0)) net_qty
, @months AS months_of_sales
, TIER = CASE WHEN IA.CATEGORY_2 LIKE '%CHILD%' THEN 'K'
	WHEN i.type_code = 'FRAME' THEN 'F' 
	WHEN I.TYPE_CODE = 'SUN' THEN 'S'
	ELSE 'Z' end
, ORDER_THRU_DATE = CAST(NULL AS DATETIME)
, last_upd_date = @asof
, DATEDIFF(MONTH,MIN(ISNULL(ia.field_26,'1/1/1949')),@asof) rel_months

INTO #ifp
FROM #brand b
JOIN inv_master i (NOLOCK) ON i.category = b.brand 
JOIN inv_master_add ia (NOLOCK) ON ia.part_no = i.part_no AND ISNULL(ia.field_32,'') NOT IN ('hvc','retail')	
LEFT OUTER JOIN cvo_sbm_details sbm ON sbm.part_no = i.part_no
	AND yyyymmdd BETWEEN @p3s AND @p1e
	AND location = '001'
WHERE 1=1 

-- AND ISNULL(yyyymmdd,@asof) between DATEADD(month,-@m, @asof) AND @asof
AND i.void = 'N'
AND ((@rs = 'KIDS' AND ia.category_2 LIKE '%child%' AND i.type_code IN ('FRAME','SUN')) 
		OR (i.type_code = @rs AND @RS <> 'KIDS' AND IA.CATEGORY_2 NOT LIKE '%CHILD%' ))

GROUP BY CASE WHEN IA.CATEGORY_2 LIKE '%CHILD%' THEN 'K'
         WHEN i.type_code = 'FRAME' THEN 'F'
         WHEN i.TYPE_CODE = 'SUN' THEN 'S'
         ELSE 'Z'
         END ,
         i.category ,
         IA.field_2 

HAVING MAX(ISNULL(ia.field_28,'12/31/2099')) >= @today
AND MIN(ISNULL(ia.field_26,'1/1/1949')) <= @today -- don't pick up future releases

		 
-- ORDER BY CASE WHEN @rs = 'SUN' THEN i.type_code ELSE i.category END asc, SUM(ISNULL(qnet,0)) DESC

IF @debug = 1 SELECT * FROM #ifp -- WHERE brand IN (SELECT brand FROM #brand) ORDER BY style

IF @debug = 1 SELECT * FROM #brand -- WHERE brand IN (SELECT brand FROM #brand) ORDER BY style

-- cover the styles that are newly released and don't have @months of sales yet
UPDATE R SET 
net_qty = CASE WHEN rel_months = 0 THEN 0 
	 WHEN rel_months = 1 THEN ROUND(m1_qnet * @months,0)
	 WHEN rel_months = 2 THEN ROUND((m1_qnet + m2_qnet)/2*@months,2)
	 ELSE net_qty end

, TIER = CASE WHEN rel_months<2 THEN 'N' ELSE r.TIER end

FROM #ifp AS r
WHERE rel_months < @months
AND ORDER_THRU_DATE IS NULL


-- assign order thru date and tier based on threshold values in config

IF(OBJECT_ID('tempdb.dbo.#t') is not null)  drop table #t

SELECT  c.brand, c.tier, c.threshold, c.order_thru_date
, count(s.style) brand_tot_qty
, tier_qty = CAST(ROUND(CAST(c.threshold AS FLOAT)/100.00 * count(s.style),0) AS INT)

INTO #t
from #brand b
JOIN cvo_ifp_config c ON c.brand = b.brand
JOIN #ifp s ON s.brand = c.brand OR s.res_type = b.brand
WHERE tag = 'tier'
AND s.tier <> 'N'

--AND s.res_type IN (SELECT r.res_type FROM #res_type r)
GROUP BY c.brand ,
         c.tier ,
         c.threshold,
		 c.order_thru_date

IF @debug = 1 SELECT * FROM #t

DECLARE @brand VARCHAR(10), @tier VARCHAR(1), @order_thru_date DATETIME
		, @tier_qty int, @id INT, @net_qty DECIMAL (20,8)

-- First do Frames

IF @RS = 'FRAME'
BEGIN
select @brand = '', @tier = '', @tier_qty = -1
SELECT @brand = MIN(brand) FROM #t WHERE brand > @brand
SELECT @tier = MIN(tier) FROM #t WHERE brand = @brand AND tier > @tier 
SELECT @tier_qty = tier_qty, @order_thru_date = order_thru_date FROM #t WHERE brand = @brand AND @tier = tier

WHILE @brand IS NOT NULL
BEGIN

-- mark the POM styles as RED/C
UPDATE s SET tier = 'C' ,order_thru_date = (SELECT TOP 1 order_thru_date FROM #t WHERE brand = @brand AND tier = 'C')
FROM #ifp s
WHERE s.TIER = 'F' AND s.pom_date <> '12/31/2099' AND brand = @brand

UPDATE #t SET tier_qty = tier_qty - @@ROWCOUNT
WHERE #t.brand = @brand AND #t.tier = 'C'

  SELECT @tier_qty = tier_qty, @order_thru_date = order_thru_date FROM #t WHERE brand = @brand AND @tier = tier

  WHILE @tier IS NOT NULL AND @tier_qty > 0
  BEGIN

	;WITH s AS 
	(SELECT TOP (@tier_qty) * 
		FROM #ifp AS i
		WHERE brand = @brand AND tier = 'F'
		ORDER BY i.net_qty DESC)
	UPDATE s SET s.TIER = @tier, s.ORDER_THRU_DATE = @order_thru_date
	
	SELECT @tier = MIN(tier) FROM #t WHERE brand = @brand AND tier > @tier 
	SELECT @tier_qty = tier_qty,  @order_thru_date = order_thru_date FROM #t WHERE brand = @brand AND @tier = tier
  END
	SELECT @brand = MIN(brand) FROM #t WHERE brand > @brand
	SELECT @tier = MIN(tier) FROM #t WHERE brand = @brand 
	SELECT @tier_qty = tier_qty,  @order_thru_date = order_thru_date FROM #t WHERE brand = @brand AND @tier = tier
END
END

-- Now do Suns

IF @RS = 'SUN'
BEGIN

-- mark the POM styles as RED/C
UPDATE s SET tier = 'C' ,order_thru_date = (SELECT TOP 1 order_thru_date FROM #t WHERE brand = 'SUN' AND tier = 'C')
FROM #ifp s
WHERE s.TIER = 'S' AND s.pom_date <> '12/31/2099'

UPDATE #t SET tier_qty = tier_qty - @@ROWCOUNT
WHERE #t.brand = 'SUN' AND #t.tier = 'C'

select @BRAND = 'SUN', @tier = '', @tier_qty = -1
SELECT @tier = MIN(tier) FROM #t WHERE brand = @BRAND AND tier > @tier 
SELECT @tier_qty = tier_qty, @order_thru_date = order_thru_date FROM #t WHERE brand = @brand AND @tier = tier



WHILE @tier IS NOT NULL
BEGIN
	IF @tier_qty > 0
	begin
	;WITH s AS 
	(SELECT TOP (@tier_qty) * 
		FROM #ifp AS i
		WHERE i.res_type = @brand AND tier = 'S'
		ORDER BY i.net_qty DESC)
	UPDATE s SET s.TIER = @tier, s.ORDER_THRU_DATE = @order_thru_date
	end

	SELECT @tier = MIN(tier) FROM #t WHERE brand = @BRAND AND tier > @tier 
	SELECT @tier_qty = tier_qty,  @order_thru_date = order_thru_date FROM #t WHERE brand = @brand AND @tier = tier
END
END

IF @RS = 'KIDS'
BEGIN

-- mark the POM styles as RED/C
UPDATE s SET tier = 'C' ,order_thru_date = (SELECT TOP 1 order_thru_date FROM #t WHERE brand = 'KIDS' AND tier = 'C')
FROM #ifp s
WHERE s.TIER = 'K' AND s.pom_date <> '12/31/2099'

UPDATE #t SET tier_qty = tier_qty - @@ROWCOUNT
WHERE #t.brand = 'KIDS' AND #t.tier = 'C'

select @BRAND = 'KIDS', @tier = '', @tier_qty = -1
SELECT @tier = MIN(tier) FROM #t WHERE brand = @BRAND AND tier > @tier 
SELECT @tier_qty = tier_qty, @order_thru_date = order_thru_date FROM #t WHERE brand = @brand AND @tier = tier



WHILE @tier IS NOT NULL
BEGIN
	IF @tier_qty > 0
	begin
	;WITH s AS 
	(SELECT TOP (@tier_qty) * 
		FROM #ifp AS i
		WHERE i.res_type = @brand AND tier = 'K'
		ORDER BY i.net_qty DESC)
	UPDATE s SET s.TIER = @tier, s.ORDER_THRU_DATE = @order_thru_date
	end

	SELECT @tier = MIN(tier) FROM #t WHERE brand = @BRAND AND tier > @tier 
	SELECT @tier_qty = tier_qty,  @order_thru_date = order_thru_date FROM #t WHERE brand = @brand AND @tier = tier
END
END

INSERT dbo.cvo_ifp_rank
        ( brand ,
          style ,
          res_type ,
          rel_date ,
          pom_date ,
          m3_net ,
          m2_net ,
          m1_net ,
          net_qty ,
		  months_of_sales,
          TIER ,
          ORDER_THRU_DATE ,
          last_upd_date
        )
SELECT i.brand ,
       i.style ,
       --i.res_type ,
	   UPPER(@rs),
       i.rel_date ,
       i.pom_date ,
       i.m3_qnet ,
       i.m2_qnet ,
       i.m1_qnet ,
	   ROUND(i.net_qty,0) net_qty ,
	   i.months_of_sales ,
       i.TIER ,
       i.ORDER_THRU_DATE ,
       i.last_upd_date FROM #ifp AS i
ORDER BY CASE WHEN @RS = 'FRAME' THEN i.brand
			  ELSE @rs END asc,
		 i.tier asc,
	     CASE WHEN i.tier IN ('a','b','c') THEN i.net_qty ELSE i.m1_qnet END DESC


SELECT distinct       id ,
                      brand ,
                      style ,
                      res_type ,
                      rel_date ,
                      pom_date ,
                      m3_net ,
                      m2_net ,
                      m1_net ,
                      net_qty ,
                      months_of_sales ,
                      TIER ,
                      ORDER_THRU_DATE ,
                      last_upd_date
FROM            cvo_ifp_rank


--SELECT @id = MIN(id) FROM cvo_ifp_rank WHERE brand = @brand AND res_type = @res_type AND tier = 'F'
--SELECT @net_qty = net_qty FROM cvo_ifp_rank WHERE id = @id

--WHILE @brand IS NOT NULL
--begin

--  WHILE @tier IS NOT NULL
--	BEGIN

--    WHILE ISNULL(@tier_qty,0) > 0 AND @id IS NOT null
--	BEGIN
--		BEGIN
--			UPDATE cvo_ifp_rank
--			SET tier = @tier, ORDER_THRU_DATE = @order_thru_date
--			WHERE id = @id
		
--			SELECT @tier_qty = @tier_qty  - @net_qty
--			SELECT @id = MIN(id) FROM cvo_ifp_rank WHERE brand = @brand AND res_type = @res_type AND tier = 'F'
--			SELECT @net_qty = net_qty FROM cvo_ifp_rank WHERE id = @id
--			END
--	END
    
--	SELECT @tier = MIN(tier) FROM #t WHERE brand = @brand AND tier > @tier 
--	SELECT @tier_qty = tier_qty,  @order_thru_date = order_thru_date FROM #t WHERE brand = @brand AND @tier = tier
--	SELECT @id = MIN(id) FROM cvo_ifp_rank WHERE brand = @brand AND res_type = @res_type AND tier = 'F'
--	SELECT @net_qty = net_qty FROM cvo_ifp_rank WHERE id = @id
--	END

--SELECT @tier = '', @tier_qty = -1
--SELECT @brand = MIN(brand) FROM #t WHERE brand > @brand 
--SELECT @tier = MIN(tier) FROM #t WHERE brand = @brand AND tier > @tier 
--SELECT @tier_qty = tier_qty, @order_thru_date = order_thru_date FROM #t WHERE brand = @brand AND @tier = tier
--SELECT @id = MIN(id) FROM cvo_ifp_rank WHERE brand = @brand AND res_type = @res_type AND tier = 'F'
--SELECT @net_qty = net_qty FROM cvo_ifp_rank WHERE id = @id
--end  

---- Now do Suns

--select @tier = '', @tier_qty = -1, @res_type = 'SUN', @brand = 'SUN'

--SELECT @tier = MIN(tier) FROM #t WHERE tier > @tier AND brand = @brand
--SELECT @tier_qty = tier_qty, @order_thru_date = order_thru_date FROM #t WHERE brand = @brand AND @tier = tier
--SELECT @id = MIN(id) FROM cvo_ifp_rank WHERE res_type = @RES_TYPE AND tier = 'S'
--SELECT @net_qty = net_qty FROM cvo_ifp_rank WHERE id = @id

--IF @debug = 1 SELECT ' starting SUNs', @tier, @tier_qty, @id, @net_qty

--WHILE @tier IS NOT NULL
--	BEGIN

--    WHILE ISNULL(@tier_qty,0) > 0 AND @id IS NOT null
--	BEGIN
--		BEGIN
--			UPDATE cvo_ifp_rank
--			SET tier = @tier, ORDER_THRU_DATE = @order_thru_date
--			WHERE id = @id
		
--			SELECT @tier_qty = @tier_qty  - @net_qty
--			SELECT @id = MIN(id) FROM cvo_ifp_rank WHERE RES_TYPE = @RES_TYPE AND tier = 'S'
--			SELECT @net_qty = net_qty FROM cvo_ifp_rank WHERE id = @id
--			END
--	END
    
--	SELECT @tier = MIN(tier) FROM #t WHERE brand = @brand AND tier > @tier 
--	SELECT @tier_qty = tier_qty,  @order_thru_date = order_thru_date FROM #t WHERE brand = @brand AND @tier = tier
--	SELECT @id = MIN(id) FROM cvo_ifp_rank WHERE RES_TYPE = @RES_TYPE AND tier = 'S'
--	SELECT @net_qty = net_qty FROM cvo_ifp_rank WHERE id = @id

--	IF @debug = 1 SELECT ' next SUNs', @tier, @tier_qty, @id, @net_qty

--	END

end








GO
GRANT EXECUTE ON  [dbo].[cvo_ifp_rank_refresh_sp] TO [public]
GO
