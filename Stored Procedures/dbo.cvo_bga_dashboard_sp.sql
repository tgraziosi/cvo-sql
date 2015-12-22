SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[cvo_bga_dashboard_sp] 
	@datefrom DATETIME = NULL, @dateto DATETIME = NULL

-- exec cvo_bga_dashboard_sp '1/1/2015', '10/31/2015'

AS

SET NOCOUNT ON
SET ANSI_WARNINGS OFF

-- for testing
--DECLARE @datefrom DATETIME, @dateto DATETIME
--SELECT @datefrom = '1/1/2015', @dateto = '11/30/2015'

DECLARE @datetoty DATETIME, @datetoly DATETIME, @r12startty DATETIME, @r12startly DATETIME

IF @dateto IS NULL SELECT @dateto = DATEADD(dd,0,DATEDIFF(dd,0,GETDATE()))
IF @datefrom IS NULL SELECT @datefrom = DATEADD(YEAR,-1,DATEADD(DAY,1,@dateto))

SELECT  @datetoty = @dateto, @datetoly = @datefrom
SELECT @r12startty = DATEADD(yy, -1, DATEADD(dd,1, @datetoty)), @r12startly = DATEADD(yy, -1, DATEADD(dd,1, @datetoly))


IF ( OBJECT_ID('tempdb.dbo.#pri') IS NOT NULL ) DROP TABLE #pri; 
IF ( OBJECT_ID('tempdb.dbo.#bga_sales') IS NOT NULL ) DROP TABLE #bga_sales; 
IF ( OBJECT_ID('tempdb.dbo.#nr') IS NOT NULL ) DROP TABLE #nr; 
IF ( OBJECT_ID('tempdb.dbo.#newrea') IS NOT NULL ) DROP TABLE #newrea; 

CREATE TABLE #newrea
( region VARCHAR(3),
terr VARCHAR(5),
salesperson VARCHAR(50),
date_of_hire DATETIME,
classof VARCHAR(10),
status VARCHAR(20),
territory VARCHAR(8),
customer_code VARCHAR(8),
ship_to_code VARCHAR(8),
door CHAR(1),
added_by_date DATETIME,
firstst_new DATETIME NULL,
prevst_new DATETIME NULL,
statustype VARCHAR(10),
designations VARCHAR(50),
pridesig VARCHAR(10)
)
CREATE TABLE #nr
(pridesig VARCHAR(10),
num_cust INT,
period int
)

SELECT    customer_code ,
            RIGHT(customer_code, 5) MergeCust ,
            code ,
            start_date ,
            end_date
INTO #pri
  FROM      cvo_cust_designation_codes (NOLOCK)
  WHERE     primary_flag = 1
            AND ISNULL(start_date, @DateToty) <= @DateToty
            AND ISNULL(end_date, @DateToty)   >= @DateToty

-- get new and reactivated count for TY and LY R12 periods
INSERT #newrea
        ( region ,
          terr ,
          salesperson ,
          date_of_hire ,
          classof ,
          status ,
          territory ,
          customer_code ,
          ship_to_code ,
          door ,
          added_by_date ,
          firstst_new ,
          prevst_new ,
          statustype ,
          designations ,
          pridesig
        )
EXEC cvo_newreaincentive3_sp @r12startty, @datetoty

INSERT #nr (pridesig, num_cust, period)
SELECT pridesig, COUNT(customer_code), DATEPART(YEAR, @datetoty)
FROM #newrea
GROUP BY pridesig

TRUNCATE TABLE #newrea
INSERT #newrea
        ( region ,
          terr ,
          salesperson ,
          date_of_hire ,
          classof ,
          status ,
          territory ,
          customer_code ,
          ship_to_code ,
          door ,
          added_by_date ,
          firstst_new ,
          prevst_new ,
          statustype ,
          designations ,
          pridesig
        )
EXEC cvo_newreaincentive3_sp @r12startly, @datetoly

INSERT #nr (pridesig, num_cust, period)
SELECT pridesig, COUNT(customer_code), DATEPART(YEAR, @datetoly)
FROM #newrea
GROUP BY pridesig

-- ytd sales ty and ly

SELECT S.customer ,
       RIGHT(S.customer,5) mergecust ,
       S.ship_to ,
       SUM(anet) net_sales ,
	   SUM(CASE WHEN s.return_code = '' THEN areturns ELSE 0 END) ra_returns,
       S.year ,
       'YTD' AS source
INTO #bga_sales
FROM #pri
JOIN dbo.cvo_sbm_details s ON s.customer = #pri.customer_code
WHERE 1=1
AND (s.yyyymmdd BETWEEN CONVERT(DATETIME,'1/1/'+CONVERT(VARCHAR(4),YEAR(@datetoty))) AND @datetoty)
OR  (s.yyyymmdd BETWEEN CONVERT(DATETIME,'1/1/'+CONVERT(VARCHAR(4),YEAR(@datetoly))) AND @datetoly)
GROUP BY s.customer ,
         s.ship_to ,
         s.year

-- Sales during primary designation period

INSERT #bga_sales
SELECT S.customer ,
       RIGHT(s.customer,5) mergecust ,
       S.ship_to ,
       SUM(anet) net_sales ,
	   SUM(CASE WHEN s.return_code = '' THEN areturns ELSE 0 END) ra_returns,
       S.year,
       'DNS' AS source -- designation net sales
FROM #pri
LEFT OUTER JOIN
cvo_sbm_details s ON s.customer = #pri.customer_code
WHERE 1=1
AND (s.yyyymmdd <= ISNULL(#pri.END_date, @datetoty))
GROUP BY RIGHT(s.customer, 5) ,
         s.customer ,
         s.ship_to ,
         s.year


/*
SELECT customer ,
       #bga_sales.mergecust ,
       ship_to ,
       net_sales ,
	   ra_returns ,
       year ,
       source ,
       customer_code ,
       #pri.MergeCust ,
       CASE WHEN #pri.code LIKE 'I-%' THEN 'IECP' ELSE #pri.code END AS code ,
	   d.description desig_desc,
       start_date ,
       end_date
	   , m.progyear
	   , m.member_cnt
	   , #nr.num_cust num_newrea
 FROM #bga_sales 
 JOIN #pri ON #pri.customer_code = #bga_sales.customer
 LEFT OUTER JOIN dbo.cvo_designation_rebates m ON m.code = #pri.code AND m.progyear = #bga_sales.year
 LEFT OUTER JOIN #nr ON #nr.pridesig = #pri.code AND #nr.period = #bga_sales.year
 LEFT OUTER JOIN dbo.cvo_designation_codes d ON d.code= #pri.code
  ORDER BY customer, YEAR DESC
 */

 --DECLARE @dateto DATETIME, @ty INTEGER, @ly integer
 --SELECT  @dateto = '11/30/2015'
 --SELECT  @ty = DATEPART(YEAR,@dateto)
	--	,@ly = DATEPART(YEAR,@dateto) - 1

 -- Membership info
 -- # locations with accounts $500 +, developing, and active
 -- TY
 SELECT #pri.code
	, section = 'Membership'
	, item = 'YTD' + CAST(b.year AS VARCHAR(4) )
    , sum(CASE WHEN b.net_sales >= 500 THEN 1 ELSE 0 end) num_custs
	, sum(CASE WHEN b.net_sales between 500 AND 2400 THEN 1 ELSE 0 end) num_developing_custs
	, sum(CASE WHEN b.net_sales >= 2400  THEN 1 ELSE 0 end) num_active_custs
	, m.member_cnt
	
 FROM #bga_sales b
 JOIN #pri ON #pri.customer_code = b.customer
 JOIN cvo_designation_rebates m ON m.code = #pri.code
 WHERE 1=1 AND source = 'YTD' 
 GROUP BY 'YTD' + CAST(b.year AS VARCHAR(4)) ,
          #pri.code ,
          m.member_cnt
 ORDER BY #PRI.CODE, item

SELECT #pri.code
	, section = 'Current Members Historical Sales'
	, item = CAST(b.year AS VARCHAR(4) )
    , sum(b.net_sales) Net_Sales
 FROM #bga_sales b
 JOIN #pri ON #pri.customer_code = b.customer
 JOIN cvo_designation_rebates m ON m.code = #pri.code
 WHERE 1=1 AND source = 'DNS' 
 GROUP BY CAST(b.year AS VARCHAR(4)) ,
          #pri.code 
 ORDER BY #pri.code, item

GO
