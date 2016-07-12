SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[cvo_ifp_rank_refresh_sp] @br VARCHAR(1024) = null, @days INT = 90

AS 
BEGIN

-- exec cvo_ifp_rank_refresh_sp 'as'

-- select * from cvo_ifp_rank

SET NOCOUNT ON
SET ANSI_WARNINGS OFF

DECLARE @d INT, @today datetime
SELECT @d = @days, @TODAY = GETDATE()



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


IF(OBJECT_ID('dbo.cvo_ifp_rank') is null)  
begin
 CREATE TABLE cvo_ifp_rank( id INT IDENTITY(1,1),
[brand] varchar(10)
, [style] varchar(40)
, [res_type] VARCHAR(10)
, [rel_date] DATETIME
, [pom_date] DATETIME
, [net_sales] float(8)
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
end

INSERT INTO cvo_ifp_rank
SELECT i.category brand, ia.field_2 style
, i.type_code res_type
, MIN(ISNULL(ia.field_26,'1/1/1949')) rel_date
, MAX(ISNULL(ia.field_28,'12/31/2099')) pom_date
, SUM(anet) net_sales
, TIER = 'X'
, ORDER_THRU_DATE = CAST(NULL AS DATETIME)
, last_upd_date = @today

FROM #brand b
JOIN inv_master i (NOLOCK) ON i.category = b.brand
JOIN inv_master_add ia (NOLOCK) ON ia.part_no = i.part_no
JOIN cvo_sbm_details sbm ON sbm.part_no = i.part_no
WHERE yyyymmdd > DATEADD(dd,-@d, @today)
AND i.type_code IN ('frame','sun')
AND ISNULL(ia.field_28,'12/31/2099') >= @today
GROUP BY i.category ,
         ia.field_2 ,
		 i.type_code,
         ia.field_28
ORDER BY brand asc, net_sales DESC

-- assign order thru date and tier based on threshold values in config

IF(OBJECT_ID('tempdb.dbo.#t') is not null)  drop table #t

SELECT  c.brand, c.tier, c.threshold, c.order_thru_date
, SUM(s.net_sales) brand_tot_sales
, tier_sales = CAST(c.threshold AS FLOAT)/100.00 * SUM(s.net_sales)
INTO #t
from #brand b
JOIN cvo_ifp_config c ON c.brand = b.brand
JOIN cvo_ifp_rank s ON s.brand = c.brand
WHERE tag = 'tier'
GROUP BY c.brand ,
         c.tier ,
         c.threshold,
		 c.order_thru_date


DECLARE @brand VARCHAR(10), @tier VARCHAR(1), @order_thru_date DATETIME, @tier_sales DECIMAL (20,8), @id INT, @net_sales DECIMAL (20,8)

select @brand = '', @tier = '', @tier_sales = -1

SELECT @brand = MIN(brand) FROM #t WHERE brand > @brand 
SELECT @tier = MIN(tier) FROM #t WHERE brand = @brand AND tier > @tier 
SELECT @tier_sales = tier_sales, @order_thru_date = order_thru_date FROM #t WHERE brand = @brand AND @tier = tier
SELECT @id = MIN(id) FROM cvo_ifp_rank WHERE brand = @brand AND tier = 'X'
SELECT @net_sales = net_sales FROM cvo_ifp_rank WHERE id = @id

WHILE @brand IS NOT NULL
begin

  WHILE @tier IS NOT NULL
	BEGIN

    WHILE ISNULL(@tier_sales,0) > 0 AND @id IS NOT null
	BEGIN
		BEGIN
			UPDATE cvo_ifp_rank
			SET tier = @tier, ORDER_THRU_DATE = @order_thru_date
			WHERE id = @id
		
			SELECT @tier_sales = @tier_sales  - @net_sales
			SELECT @id = MIN(id) FROM cvo_ifp_rank WHERE brand = @brand AND tier = 'X'
			SELECT @net_sales = net_sales FROM cvo_ifp_rank WHERE id = @id
			END
	END
    
	SELECT @tier = MIN(tier) FROM #t WHERE brand = @brand AND tier > @tier 
	SELECT @tier_sales = tier_sales,  @order_thru_date = order_thru_date FROM #t WHERE brand = @brand AND @tier = tier
	SELECT @id = MIN(id) FROM cvo_ifp_rank WHERE brand = @brand AND tier = 'X'
	SELECT @net_sales = net_sales FROM cvo_ifp_rank WHERE id = @id
	END

SELECT @tier = '', @tier_sales = -1
SELECT @brand = MIN(brand) FROM #t WHERE brand > @brand 
SELECT @tier = MIN(tier) FROM #t WHERE brand = @brand AND tier > @tier 
SELECT @tier_sales = tier_sales, @order_thru_date = order_thru_date FROM #t WHERE brand = @brand AND @tier = tier
SELECT @id = MIN(id) FROM cvo_ifp_rank WHERE brand = @brand AND tier = 'X'
SELECT @net_sales = net_sales FROM cvo_ifp_rank WHERE id = @id
end  

end

GO
GRANT EXECUTE ON  [dbo].[cvo_ifp_rank_refresh_sp] TO [public]
GO
