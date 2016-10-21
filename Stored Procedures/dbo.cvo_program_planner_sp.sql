SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[cvo_program_planner_sp] 
@asofyear INT = null,
@terr VARCHAR(1000) = NULL
AS

-- exec cvo_program_planner_sp 2016, '20201,20202'

SET NOCOUNT ON 
BEGIN


DECLARE @year INT
SELECT @year = @asofyear

IF @year IS NULL
SELECT @year = DATEPART(YEAR, GETDATE())

-- SELECT @asofyear
IF(OBJECT_ID('tempdb.dbo.#territory') is not null)  drop table #territory
CREATE TABLE #territory ([territory] VARCHAR(10),
						 [region] VARCHAR(3) )

if @terr is null
begin
	insert #territory
	select distinct territory_code, dbo.calculate_region_fn(territory_code) region
	from armaster where territory_code is not NULL
    ORDER BY territory_code
end
else
begin
	INSERT INTO #territory ([territory],[region])
	SELECT distinct LISTITEM, dbo.calculate_region_fn(listitem) region FROM dbo.f_comma_list_to_table(@terr)
	ORDER BY ListItem
END


SELECT t.region, ar.territory_code, ar.customer_code, AR.address_name, ar.ship_to_code, ar.city,
SBM.qty_sold, net_sales.net_sales, UPPER(SBM.promo_id) promo_id, SBM.year

FROM #territory AS t
JOIN armaster ar ON ar.territory_code = t.territory
LEFT OUTER JOIN
(SELECT sbm.customer, sbm.ship_to, sbm.year, SUM(sbm.anet) net_sales
FROM dbo.cvo_sbm_details sbm
WHERE sbm.year BETWEEN @year - 1 AND @year
GROUP BY sbm.customer ,
         sbm.ship_to ,
         sbm.year
) net_sales ON net_sales.customer = ar.customer_code
		AND net_sales.ship_to = ar.ship_to_code

LEFT OUTER JOIN
(SELECT sbm.customer, sbm.ship_to, p.promo_id, sbm.year, SUM(qnet) qty_sold
FROM cvo_promotions p
LEFT OUTER JOIN cvo_sbm_details sbm
ON sbm.promo_id = p.promo_id AND sbm.promo_level = p.promo_level 
WHERE p.season_program = 1
AND sbm.year BETWEEN @year - 1 AND @year
GROUP BY sbm.customer, sbm.ship_to,
		 p.promo_id ,
         SBM.year
) SBM ON ar.customer_code = sbm.customer AND ar.ship_to_code = sbm.ship_to
	AND SBM.year = net_sales.year

WHERE ar.address_type IN (0,1) AND ar.status_type = 1

END

GO
GRANT EXECUTE ON  [dbo].[cvo_program_planner_sp] TO [public]
GO
