SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[cvo_FramePurchase_sp]
@asofdate datetime = null,
@MthsToReport INT = NULL,
@terr VARCHAR(1000) = NULL,
@Cust VARCHAR(8000) = NULL

AS 
BEGIN

-- exec cvo_FramePurchase_sp

IF @asofdate IS NULL SELECT @asofdate = DATEADD(day,0,DATEDIFF(DAY,0,GETDATE()))
IF @mthstoreport IS NULL SELECT @MthsToReport = 12

-- SELECT @asofyear
IF(OBJECT_ID('tempdb.dbo.#territory') is not null)  drop table #territory
CREATE TABLE #territory ([territory] VARCHAR(10),
						 [region] VARCHAR(3) )

if @terr is null
begin
	insert #territory
	select distinct territory_code, dbo.calculate_region_fn(territory_code) region
	from armaster where territory_code is not NULL
end
else
begin
	INSERT INTO #territory ([territory],[region])
	SELECT distinct LISTITEM, dbo.calculate_region_fn(listitem) region FROM dbo.f_comma_list_to_table(@terr)
END

IF(OBJECT_ID('tempdb.dbo.#Cust') is not null)  drop table #Cust
CREATE TABLE #cust (customer_code VARCHAR(10), territory_code VARCHAR(10) )

if @Cust is null
begin
	insert #Cust
	select distinct customer_code, ar.territory_code
	from armaster ar
	JOIN #territory AS t ON t.territory = ar.territory_code
end
else
begin
	INSERT INTO #cust (customer_code, territory_code)
	SELECT distinct LISTITEM, ar.territory_code
	FROM dbo.f_comma_list_to_table(@cust)
	JOIN armaster ar ON ar.customer_code = listitem
	ORDER BY ListItem
END


SELECT ar.territory_code, ar.customer_code, ar.ship_to_code, ar.address_name, 
 LTRIM(RTRIM(ISNULL(designations.desig,'<None>'))) desig,
 i.category, ia.field_2 style,
 i.part_no, sbm.c_year, sbm.c_month, SUM(qnet) net_qty
FROM #territory AS t
JOIN #cust AS c ON c.territory_code = t.territory
JOIN armaster ar on ar.customer_code = c.customer_code
LEFT OUTER JOIN cvo_sbm_details sbm ON ar.customer_code = sbm.customer AND ar.ship_to_code = sbm.ship_to
JOIN inv_master i ON i.part_no = sbm.part_no 
JOIN inv_master_add ia ON ia.part_no = i.part_no
LEFT OUTER JOIN ( SELECT    c.customer_code ,
                            STUFF(( SELECT  '; ' + code
                                    FROM    cvo_cust_designation_codes (NOLOCK)
                                    WHERE   customer_code = c.customer_code
                                            AND ISNULL(start_date, @asofdate) <= @asofdate
                                            AND ISNULL(end_date, @asofdate) >= @asofdate
											AND code LIKE 'M-%'
                                    FOR
                                    XML PATH('')
                                    ), 1, 1, '') desig
                    FROM      dbo.cvo_cust_designation_codes (NOLOCK) c
				 ) AS designations ON designations.customer_code = ar.customer_code
WHERE sbm.yyyymmdd >= DATEADD(MONTH,-@MthsToReport,@asofdate)
AND i.type_code IN ('frame','sun')
    
GROUP BY ar.territory_code ,
         ar.customer_code ,
         ar.ship_to_code ,
         ar.address_name ,
		 designations.desig,
         i.category ,
		 ia.field_2,
         i.part_no ,
         sbm.c_year ,
         sbm.c_month

END

GO
GRANT EXECUTE ON  [dbo].[cvo_FramePurchase_sp] TO [public]
GO
