SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[cvo_desig_sales_by_week_sp] 
  @startdate DATETIME 
, @enddate DATETIME
, @desig VARCHAR(10)

AS 

BEGIN

SET NOCOUNT ON
SET ANSI_WARNINGS OFF

-- SELECT @startdate = '1/1/2015', @enddate = '12/31/2015', @desig = 'rx5'

DECLARE @sd DATETIME, @ed DATETIME, @d VARCHAR(10)
SELECT @sd = @startdate, @ed = @enddate, @d = @desig

IF ( OBJECT_ID('tempdb.dbo.#sales') IS NOT NULL ) DROP TABLE dbo.#sales;

SELECT ar.territory_code
, ar.customer_code, ar.ship_to_code
, SUM(s.anet) Net_Sales
, DATEPART(WEEK, s.yyyymmdd) week_num
, s.c_year
INTO #sales
FROM 
dbo.cvo_cust_designation_codes d
JOIN arcust ar ON ar.customer_code = d.customer_code
JOIN cvo_sbm_details s ON ar.customer_code = s.customer AND ar.ship_to_code = ar.ship_to_code
WHERE d.code = @d AND ISNULL(d.start_date,@ed) <= @ed  AND ISNULL(d.end_date,@ed) >= @ed
AND s.yyyymmdd BETWEEN @sd AND @ed
GROUP BY DATEPART(WEEK, s.yyyymmdd) ,
         ar.territory_code ,
         ar.customer_code ,
         ar.ship_to_code ,
         s.c_year

SELECT terr.region,
	   #sales.territory_code ,
       #sales.customer_code ,
       #sales.ship_to_code ,
	   ar.address_name,
       #sales.Net_Sales ,
       #sales.week_num ,
       #sales.c_year,
	   Week_starts.week_start,
	   designations.desig AllDesigs,
	   p.code PrimaryDesig

FROM #sales
INNER JOIN
(SELECT DISTINCT week_num, c_year, 
DATEADD(WEEK, week_num - 1, DATEADD(dd, 1 - DATEPART(dw, '1/1/' + CONVERT(VARCHAR(4),c_year)), '1/1/' + CONVERT(VARCHAR(4),c_year))) week_start
FROM #sales) Week_starts
ON Week_starts.c_year = #sales.c_year AND Week_starts.week_num = #sales.week_num
INNER JOIN armaster ar ON ar.customer_code = #sales.customer_code AND ar.ship_to_code = #sales.ship_to_code
INNER JOIN (SELECT DISTINCT territory_code, dbo.calculate_region_fn(territory_code) Region
			FROM arterr) terr ON terr.territory_code = #sales.territory_code
LEFT OUTER JOIN ( SELECT  distinct RIGHT(customer_code, 5) MergeCust ,
                            STUFF(( SELECT  DISTINCT '; ' + code
                                    FROM    cvo_cust_designation_codes (NOLOCK) cc
                                    WHERE   cc.customer_code = c.customer_code
											AND ISNULL(start_date, @ed) <= @ed
                                            AND ISNULL(end_date, @ed) >= @ed
                                    FOR XML PATH('')
                                    ), 1, 1, '') desig
                    FROM      dbo.cvo_cust_designation_codes (NOLOCK) c
                ) AS designations ON designations.MergeCust = RIGHT(ar.customer_code,5)
LEFT OUTER JOIN ( SELECT  distinct RIGHT(customer_code, 5) MergeCust ,
                            code ,
                            start_date ,
                            end_date
                    FROM      cvo_cust_designation_codes (NOLOCK)
                    WHERE     primary_flag = 1
                            AND ISNULL(start_date, @ed) <= @ed
                            AND ( ISNULL(end_date, @ed) >= @ed )
                ) AS p ON p.MergeCust = RIGHT(ar.customer_code, 5)
	  
END
GO
GRANT EXECUTE ON  [dbo].[cvo_desig_sales_by_week_sp] TO [public]
GO
