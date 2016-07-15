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

-- exec cvo_ifp_rank_refresh_sp 'bcbg', 'frame', null, 3, 1
-- SELECT * fROM CVO_IFP_CONFIG
-- select * from cvo_ifp_rank where res_type <> 'sun' and brand = 'bcbg'

SET NOCOUNT ON
SET ANSI_WARNINGS OFF

DECLARE @m INT, @today DATETIME, @asof DATETIME
SELECT @m = @months, @TODAY = GETDATE(), @asof = @asofdate

IF @asofdate IS NULL 
SELECT @asof = ENDdate FROM dbo.cvo_date_range_vw WHERE period = 'Last Month'
ELSE
SELECT @asof = @asofdate

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
, i.type_code res_type
, MIN(ISNULL(ia.field_26,'1/1/1949')) rel_date
, MAX(ISNULL(ia.field_28,'12/31/2099')) pom_date
, SUM(ISNULL(CASE WHEN sbm.X_MONTH = MONTH(DATEADD(month,-2,@asof)) THEN qnet ELSE 0 END,0)) m3_qnet
, SUM(ISNULL(CASE WHEN sbm.X_MONTH = MONTH(DATEADD(month,-1,@asof)) THEN qnet ELSE 0 END,0)) m2_qnet
, SUM(ISNULL(CASE WHEN sbm.X_MONTH = MONTH(DATEADD(month, 0,@asof)) THEN qnet ELSE 0 END,0)) m1_qnet
, SUM(ISNULL(qnet,0)) net_qty
, @months AS months_of_sales
, TIER = CASE WHEN i.type_code = 'frame' THEN 'F' else 'S' end
, ORDER_THRU_DATE = CAST(NULL AS DATETIME)
, last_upd_date = @asof
INTO #ifp
FROM #brand b
JOIN inv_master i (NOLOCK) ON i.category = b.brand
JOIN inv_master_add ia (NOLOCK) ON ia.part_no = i.part_no
LEFT OUTER JOIN cvo_sbm_details sbm ON sbm.part_no = i.part_no
	AND yyyymmdd BETWEEN DATEADD(month,-@m, @asof) AND @asof
	AND location = '001'
WHERE 1=1 
AND i.type_code = @rs
AND ISNULL(ia.field_28,'12/31/2099') >= @today
-- AND ISNULL(yyyymmdd,@asof) between DATEADD(month,-@m, @asof) AND @asof
AND i.void = 'N'
GROUP BY i.category ,
         ia.field_2 ,
		 i.type_code,
         ia.field_28
-- ORDER BY CASE WHEN @rs = 'sun' THEN i.type_code ELSE i.category END asc, SUM(ISNULL(qnet,0)) DESC

IF @debug = 1 SELECT * FROM #ifp -- WHERE brand IN (SELECT brand FROM #brand) ORDER BY style

IF @debug = 1 SELECT * FROM #brand -- WHERE brand IN (SELECT brand FROM #brand) ORDER BY style

-- cover the styles that are newly released and don't have @months of sales yet
UPDATE R SET net_qty = ROUND(CASE WHEN DATEDIFF(MONTH,rel_date, last_upd_date) <> 0 
								  THEN (net_qty / DATEDIFF(MONTH,rel_date, last_upd_date)) * @months 
								  ELSE net_qty END,0)
FROM #ifp r
WHERE DATEDIFF(MONTH,REL_DATE,last_upd_date) < @months
AND ORDER_THRU_DATE IS NULL

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
       i.res_type ,
       i.rel_date ,
       i.pom_date ,
       i.m3_qnet ,
       i.m2_qnet ,
       i.m1_qnet ,
	   i.net_qty ,
	   i.months_of_sales ,
       i.TIER ,
       i.ORDER_THRU_DATE ,
       i.last_upd_date FROM #ifp AS i
ORDER BY CASE WHEN @rs = 'sun' THEN i.res_type ELSE brand END asc, i.net_qty DESC

-- assign order thru date and tier based on threshold values in config

IF(OBJECT_ID('tempdb.dbo.#t') is not null)  drop table #t

SELECT  c.brand, c.tier, c.threshold, c.order_thru_date
, SUM(s.net_qty) brand_tot_qty
, tier_qty = CAST(c.threshold AS FLOAT)/100.00 * SUM(s.net_qty)

INTO #t
from #brand b
JOIN cvo_ifp_config c ON c.brand = b.brand
JOIN #ifp s ON s.brand = c.brand OR s.res_type = b.brand
WHERE tag = 'tier'
--AND s.res_type IN (SELECT r.res_type FROM #res_type r)
GROUP BY c.brand ,
         c.tier ,
         c.threshold,
		 c.order_thru_date

IF @debug = 1 SELECT * FROM #t

DECLARE @brand VARCHAR(10), @tier VARCHAR(1), @order_thru_date DATETIME
		, @tier_qty DECIMAL (20,8), @id INT, @net_qty DECIMAL (20,8)
		, @res_type VARCHAR(8)

-- First do Frames

select @brand = '', @tier = '', @tier_qty = -1, @res_type = 'FRAME'

SELECT @brand = MIN(brand) FROM #t WHERE brand > @brand
SELECT @tier = MIN(tier) FROM #t WHERE brand = @brand AND tier > @tier 
SELECT @tier_qty = tier_qty, @order_thru_date = order_thru_date FROM #t WHERE brand = @brand AND @tier = tier
SELECT @id = MIN(id) FROM cvo_ifp_rank WHERE brand = @brand AND res_type = @res_type AND tier = 'F'
SELECT @net_qty = net_qty FROM cvo_ifp_rank WHERE id = @id

WHILE @brand IS NOT NULL
begin

  WHILE @tier IS NOT NULL
	BEGIN

    WHILE ISNULL(@tier_qty,0) > 0 AND @id IS NOT null
	BEGIN
		BEGIN
			UPDATE cvo_ifp_rank
			SET tier = @tier, ORDER_THRU_DATE = @order_thru_date
			WHERE id = @id
		
			SELECT @tier_qty = @tier_qty  - @net_qty
			SELECT @id = MIN(id) FROM cvo_ifp_rank WHERE brand = @brand AND res_type = @res_type AND tier = 'F'
			SELECT @net_qty = net_qty FROM cvo_ifp_rank WHERE id = @id
			END
	END
    
	SELECT @tier = MIN(tier) FROM #t WHERE brand = @brand AND tier > @tier 
	SELECT @tier_qty = tier_qty,  @order_thru_date = order_thru_date FROM #t WHERE brand = @brand AND @tier = tier
	SELECT @id = MIN(id) FROM cvo_ifp_rank WHERE brand = @brand AND res_type = @res_type AND tier = 'F'
	SELECT @net_qty = net_qty FROM cvo_ifp_rank WHERE id = @id
	END

SELECT @tier = '', @tier_qty = -1
SELECT @brand = MIN(brand) FROM #t WHERE brand > @brand 
SELECT @tier = MIN(tier) FROM #t WHERE brand = @brand AND tier > @tier 
SELECT @tier_qty = tier_qty, @order_thru_date = order_thru_date FROM #t WHERE brand = @brand AND @tier = tier
SELECT @id = MIN(id) FROM cvo_ifp_rank WHERE brand = @brand AND res_type = @res_type AND tier = 'F'
SELECT @net_qty = net_qty FROM cvo_ifp_rank WHERE id = @id
end  

-- Now do Suns

select @tier = '', @tier_qty = -1, @res_type = 'SUN', @brand = 'sun'

SELECT @tier = MIN(tier) FROM #t WHERE tier > @tier AND brand = @brand
SELECT @tier_qty = tier_qty, @order_thru_date = order_thru_date FROM #t WHERE brand = @brand AND @tier = tier
SELECT @id = MIN(id) FROM cvo_ifp_rank WHERE res_type = @RES_TYPE AND tier = 'S'
SELECT @net_qty = net_qty FROM cvo_ifp_rank WHERE id = @id

IF @debug = 1 SELECT ' starting suns', @tier, @tier_qty, @id, @net_qty

WHILE @tier IS NOT NULL
	BEGIN

    WHILE ISNULL(@tier_qty,0) > 0 AND @id IS NOT null
	BEGIN
		BEGIN
			UPDATE cvo_ifp_rank
			SET tier = @tier, ORDER_THRU_DATE = @order_thru_date
			WHERE id = @id
		
			SELECT @tier_qty = @tier_qty  - @net_qty
			SELECT @id = MIN(id) FROM cvo_ifp_rank WHERE RES_TYPE = @RES_TYPE AND tier = 'S'
			SELECT @net_qty = net_qty FROM cvo_ifp_rank WHERE id = @id
			END
	END
    
	SELECT @tier = MIN(tier) FROM #t WHERE brand = @brand AND tier > @tier 
	SELECT @tier_qty = tier_qty,  @order_thru_date = order_thru_date FROM #t WHERE brand = @brand AND @tier = tier
	SELECT @id = MIN(id) FROM cvo_ifp_rank WHERE RES_TYPE = @RES_TYPE AND tier = 'S'
	SELECT @net_qty = net_qty FROM cvo_ifp_rank WHERE id = @id

	IF @debug = 1 SELECT ' next suns', @tier, @tier_qty, @id, @net_qty

	END

end



GO
GRANT EXECUTE ON  [dbo].[cvo_ifp_rank_refresh_sp] TO [public]
GO
