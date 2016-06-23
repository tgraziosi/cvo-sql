SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[cvo_desig_rebate_tracker_sp] @sdate DATETIME, @edate DATETIME, @terr VARCHAR(1024) = null
AS 
BEGIN

-- exec cvo_desig_rebate_tracker_sp '1/1/2016', '5/1/2016'


-- DECLARE @sdate DATETIME, @edate DATETIME, @today DATETIME, @terr VARCHAR(1024)

DECLARE @progyear INT, @today datetime

SELECT @today = GETDATE()
IF @sdate IS NULL OR @edate IS NULL
SELECT @sdate = begindate, @edate = enddate
FROM dbo.cvo_date_range_vw AS cdrv WHERE period = 'year to date'

SELECT @progyear = YEAR(@edate)

 DECLARE @territory VARCHAR(1024)
 SELECT @territory = @terr

IF ( OBJECT_ID('tempdb.dbo.#terr') IS NOT NULL ) DROP TABLE #terr; 

CREATE TABLE #terr ( terr VARCHAR(8),
					 region VARCHAR(3) )

IF ( @territory IS NULL )
    BEGIN
        INSERT  INTO #terr ( terr, region )
                SELECT DISTINCT territory_code, dbo.calculate_region_fn(territory_code) 
					FROM    dbo.armaster
                WHERE   1=1;
    END;
ELSE
    BEGIN
        INSERT  INTO #terr ( terr, region )
                SELECT  ListItem, dbo.calculate_region_fn(listitem)
                FROM    dbo.f_comma_list_to_table(@territory);
    END;

-- merge cust list

--SELECT merge_cust
--FROM 
--(SELECT DISTINCT ar.customer_code, RIGHT(ar.customer_code,5) merge_cust
--FROM armaster ar 
--) AS xx
--GROUP BY xx.merge_cust
--HAVING COUNT(xx.customer_code) > 1   

SELECT cdr.progyear, cdr.interval ,cdr.code, facts.description, cdr.goal1, cdr.rebatepct1, cdr.goal2, cdr.rebatepct2 , cdr.RRLess, 
	ar.past_due, cust.mergecust ,
                 t.region ,
                 t.terr territory_code ,
        		 cust.address_name,
				 cust.contact_email,
                 facts.grosssales ,
                 facts.netsales ,
                 facts.rareturns ,
                 facts.start_date ,
                 facts.desig_grosssales ,
                 facts.desig_netsales ,
                 facts.desig_rareturns, 
	desig_RAretpct = CASE WHEN facts.desig_grosssales = 0 THEN 0 ELSE facts.desig_rareturns/facts.desig_grosssales end,
	RAretpct = CASE WHEN facts.grosssales = 0 THEN 0 ELSE facts.rareturns/facts.grosssales END,
	NeedForGoal1 = cdr.goal1 - facts.desig_netsales,
	NeedForGoal1RA = (CASE WHEN cdr.rrless = 0 THEN 0 ELSE facts.rareturns/cdr.rrless END) - cdr.goal1,
	NeedForGoal2 = cdr.goal2 - facts.desig_netsales,
	RebatePotential = facts.desig_netsales * cdr.rebatepct1 + facts.desig_netsales * cdr.rebatepct2

FROM 
dbo.cvo_designation_rebates AS cdr
LEFT OUTER JOIN
(
SELECT RIGHT(ccdc.customer_code,5) mergecust,
ccdc.code, ccdc.description, ccdc.start_date,
SUM(asales) grosssales,
SUM(anet) netsales, 
SUM(CASE WHEN sbm.return_code = '' THEN sbm.areturns ELSE 0 END) rareturns,
SUM(CASE WHEN yyyymmdd >= ISNULL(ccdc.start_date,yyyymmdd) THEN asales ELSE 0 end) desig_grosssales,
SUM(CASE WHEN yyyymmdd >= ISNULL(ccdc.start_date,yyyymmdd) THEN anet ELSE 0 end) desig_netsales,
SUM(CASE WHEN yyyymmdd >= ISNULL(ccdc.start_date,yyyymmdd) AND sbm.return_code = '' THEN sbm.areturns ELSE 0 end) desig_rareturns
from
( SELECT DISTINCT cdc.code desig_code, cdc.description
FROM 
dbo.cvo_designation_codes AS cdc
WHERE cdc.rebate = 'Y'
) dr
JOIN dbo.cvo_cust_designation_codes AS ccdc ON ccdc.code = dr.desig_code
LEFT OUTER JOIN cvo_sbm_details sbm ON sbm.customer = ccdc.customer_code 

WHERE 1=1 
AND ccdc.primary_flag = 1 AND ISNULL(ccdc.end_date,@today) >= @today
AND sbm.yyyymmdd BETWEEN @sdate AND @edate

GROUP BY RIGHT(ccdc.customer_code,5) ,
         ccdc.code ,
         ccdc.description ,
         ccdc.start_date
         ) AS facts 
ON cdr.code = facts.code AND cdr.progyear = @progyear

JOIN 
(SELECT RIGHT(customer_code,5) mergecust, MIN(customer_name) address_name, MAX(contact_email) contact_email, territory_code
FROM arcust GROUP BY RIGHT(customer_code, 5) ,
                     territory_code
) AS cust ON cust.mergecust = facts.mergecust

JOIN #terr t ON t.terr = cust.territory_code

LEFT OUTER JOIN
(SELECT RIGHT(cust_code,5) mergecust, past_due = SUM(ar30+ar60+ar90+ar120+ar150)
FROM dbo.SSRS_ARAging_Temp
GROUP BY RIGHT(cust_code, 5)
) AS ar ON ar.mergecust = cust.mergecust

WHERE cdr.progyear = @progyear
AND t.region IS NOT NULL

-- SELECT * FROM dbo.cvo_designation_codes AS ccdc

END

GO
GRANT EXECUTE ON  [dbo].[cvo_desig_rebate_tracker_sp] TO [public]
GO
