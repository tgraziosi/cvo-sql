SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[cvo_multiloc_cust_sales_sp] @t VARCHAR(1000) = null, @df DATETIME = null, @dt DATETIME = null

-- exec cvo_multiloc_cust_sales_sp '20201', '01/01/2016', '06/24/2016'

AS

BEGIN

DECLARE @terr VARCHAR(1000)
SELECT @terr = @t

DECLARE --@df DATETIME, @dt datetime, 
		--@date_option VARCHAR(20),
		@dfly DATETIME, @dtly DATETIME

--SELECT @date_option = @d

IF @df IS NULL OR @dt = NULL
BEGIN
 SELECT @df = cdrv.BeginDate, @dt = cdrv.EndDate 
 FROM dbo.cvo_date_range_vw AS cdrv
 WHERE period = 'Rolling 12 TY'
END

SELECT @dfly = DATEADD(YEAR,-1,@df), @dtly = DATEADD(YEAR,-1,@dt)
 
IF(OBJECT_ID('tempdb.dbo.#territory') is not null)  drop table #territory
CREATE TABLE #territory ([territory] VARCHAR(10),
						 [region] VARCHAR(3),
						 [r_id] INT,
						 [t_id] INT )

if @terr is null
begin
	insert #territory
	select distinct territory_code, dbo.calculate_region_fn(territory_code) region, 0, 0
	from armaster where territory_code is not NULL
    ORDER BY territory_code
end
else
begin
	INSERT INTO #territory ([territory],[region], [r_id], [t_id])
	SELECT distinct LISTITEM, dbo.calculate_region_fn(listitem) region, 0, 0 FROM dbo.f_comma_list_to_table(@terr)
	ORDER BY ListItem
END

-- SELECT * FROM dbo.cvo_date_range_vw AS cdrv

SELECT facts.code, facts.description, t.region, ar.territory_code, ar.customer_code, ar.ship_to_code, ar.address_name, 
CASE ar.status_type 
WHEN 1 then 'Active'
WHEN 2 THEN 'Inactive'
WHEN 3 THEN 'NoNewBus'
END AS Cust_Status, ar.addr_sort1 Customer_Type, facts.netsalesty, facts.netsalesly, facts.netsalesty-facts.netsalesly diff
, facts.NetsalesPY1, facts.NetsalesPY2, facts.NetsalesPY3
FROM
(
SELECT ccdc.code, ccdc.description, ccdc.customer_code, ISNULL(sbm.ship_to,'') ship_to, 
	SUM(CASE WHEN yyyymmdd BETWEEN @df AND @dt THEN anet ELSE 0 end) NetsalesTY,
	SUM(CASE WHEN yyyymmdd BETWEEN @dfly AND @dtly THEN anet ELSE 0 end) NetsalesLY
	-- add full year LY, + 2 more years back
	, SUM(CASE WHEN YEAR(yyyymmdd) = YEAR(@dt) - 1 THEN anet ELSE 0 END) NetsalesPY1
	, SUM(CASE WHEN YEAR(yyyymmdd) = YEAR(@dt) - 2 THEN anet ELSE 0 END) NetsalesPY2
	, SUM(CASE WHEN YEAR(yyyymmdd) = YEAR(@dt) - 3 THEN anet ELSE 0 END) NetsalesPY3

from dbo.cvo_cust_designation_codes ccdc (NOLOCK) 
JOIN armaster ar (NOLOCK) ON ar.customer_code = ccdc.customer_code
INNER JOIN #territory AS t ON t.territory = ar.territory_code
LEFT OUTER JOIN cvo_sbm_details sbm (NOLOCK) ON ar.customer_code = sbm.customer AND ar.ship_to_code = sbm.ship_to

WHERE ccdc.code LIKE 'M-%'
-- AND ((sbm.yyyymmdd BETWEEN @df AND @dt) OR (sbm.yyyymmdd BETWEEN @dfly AND @dtly))
AND ((sbm.yyyymmdd BETWEEN DATEADD(YEAR,-3,@dfly) AND @dt))

GROUP BY ccdc.code ,
         ccdc.description,
		 ccdc.customer_code, sbm.ship_to
) facts
INNER JOIN armaster ar ON ar.customer_code = facts.customer_code AND ar.ship_to_code = facts.ship_to
INNER JOIN #territory AS t ON t.territory = ar.territory_code

END

GO
GRANT EXECUTE ON  [dbo].[cvo_multiloc_cust_sales_sp] TO [public]
GO
