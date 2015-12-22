SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Tine Graziosi
-- Create date: 6/24/2015
-- Description:	Kids Program Planner - 2015 edition
-- EXEC KidsPP_ssrs_2015_sp
-- =============================================
CREATE PROCEDURE [dbo].[KidsPP_ssrs_2015_sp] 
	
AS
BEGIN
	SET NOCOUNT ON;

-- Kids 4 Year Program Planner

DECLARE @P1From DATETIME
    , @P1To DATETIME
	, @P2From DATETIME
	, @P2To DATETIME
	, @P3From DATETIME
	, @P3To DATETIME
	, @P4From datetime
	, @P4To DATETIME
	, @P5From datetime
	, @P5To datetime

	
Select @P1From = DATEADD(YEAR, DATEDIFF(YEAR, 0,DATEADD(YEAR, 0, GETDATE())), 0)
	,  @P1To =   DATEADD(MILLISECOND, -3, DATEADD(YEAR, DATEDIFF(YEAR, 0, DATEADD(YEAR, 0, GETDATE())) + 1, 0))
	,  @P2From = DATEADD(YEAR,-1,@P1From)
	,  @P3From = DATEADD(YEAR,-2,@P1From)
	,  @P4From = DATEADD(YEAR,-3,@P1From)
	,  @P5From = DATEADD(YEAR,-4,@P1From)

--  select @P1From AS '1', @P1To AS '2', @P2From AS '3', @P2To AS '4', @P3From AS '5', @P3To AS '6', @P4From AS '7', @P4To AS '8', @P5From AS '9', @P5To AS '10'

-- Lookup 0 & 9 affiliated Accounts
IF(OBJECT_ID('tempdb.dbo.#Aff') is not null)  
drop table #Aff 
select a.customer_code as from_cust, a.ship_to_code as shipto, a.affiliated_cust_code as to_cust
into #Aff
from armaster a (nolock) inner join
armaster b (nolock) on a.affiliated_cust_code = b.customer_code and a.ship_to_code = b.ship_to_code
where a.status_type <> 1 and a.address_type <> 9 
and a.affiliated_cust_code<> '' and a.affiliated_cust_code is not null
and b.status_type = 1 and b.address_type <> 9
--select @@rowcount
--select * from #Aff

-- Pull Customer#, Shipto#, Name, Addr, City, State, Zip, Phone, Fax, Contact
IF(OBJECT_ID('tempdb.dbo.#Cust1') is not null)
drop table dbo.#Cust1
SELECT customer_code, ship_to_code, territory_code, Address_name, addr2, addr3, addr4, City, State, Postal_code, country_code, contact_phone, tlx_twx, 
case when contact_email ='REFUSED' then '' 
	WHEN contact_email like '%@cvoptical.com%' then '' 
	WHEN contact_email is null then '' 
	ELSE contact_email end as contact_email, 
contact_name  
INTO #Cust1
FROM armaster t1 (nolock)
WHERE ADDRESS_TYPE <>9
and status_type='1'
--select * from #RankCusts_S1

--Add ReClassify for Affiliation 
IF(OBJECT_ID('tempdb.dbo.#Aff_All') is not null)
drop table dbo.#Aff_All
select X.* INTO #Aff_All FROM
( select from_cust AS CUST,'I' as Code from #Aff    UNION
select to_cust AS CUST,'A' Code from #Aff ) X
--SELECT * FROM #Aff_All 

-- Add 0/9 Statu to Customer Data
IF(OBJECT_ID('tempdb.dbo.#Cust2') is not null)
drop table dbo.#Cust2
Select ISNULL(t2.code,'A') Status, Right(customer_code, 5) as MergeCust, T1.*
INTO #Cust2
from #Cust1 t1
full outer join #Aff_All t2 on t1.customer_code=t2.cust
-- select * from #Cust1
-- select * from #Cust2

-- Dedup out 0/9 Customers
IF(OBJECT_ID('tempdb.dbo.#Cust3') is not null)
drop table dbo.#Cust3
SELECT MergeCust, ship_to_code,
MIN(isnull(Status,'')) Status,
MIN(isnull(territory_code,'')) Terr, 
MIN(isnull(Address_name,'')) Name, 
MIN(isnull(addr2,'')) Addr2, 
case when MIN(isnull(addr3,''))  like '%, __ %' then '' else MIN(isnull(addr3,''))  end as Addr3,
MIN(isnull(City,'')) City, 
MIN(isnull(State,'')) State, 
MIN(isnull(Postal_code,'')) Zip,
MIN(isnull(country_code,'')) Cntry, 
MIN(isnull(contact_phone,'')) Phone, 
MIN(isnull(tlx_twx,'')) Fax, 
MIN(isnull(contact_email,'')) Email, 
MIN(isnull(contact_name,'')) Contact
into #Cust3 from #Cust2 GROUP BY MergeCust, ship_to_code


IF(OBJECT_ID('tempdb.dbo.#SUBFINAL') is not null)  
drop table #SUBFINAL

SELECT RIGHT(s.customer,5) mcust, s.ship_to

, yr = CASE WHEN yyyymmdd >= @P1From THEN 'CY'
		  WHEN yyyymmdd >= @p2from THEN 'PY1'
		  WHEN yyyymmdd >= @p3from THEN 'PY2'
		  WHEN yyyymmdd >= @p4from THEN 'PY3'
		  WHEN yyyymmdd >= @p5from THEN 'PY4'
		  ELSE 'xxx' end
, kidtype = CASE 
			WHEN i.category = 'OP' AND ia.category_2 LIKE '%adult%' THEN '3OP Ad'
			WHEN i.category = 'JC' AND ia.category_2 LIKE '%adult%' THEN '4JC Ad'
			WHEN ia.category_2 LIKE '%child%' AND i.category NOT IN ( 'FP','DD' ) THEN '1Kids'
			WHEN ia.category_2 LIKE '%child%'  AND i.category IN ( 'FP','DD' ) THEN '2Pedi'

			ELSE 'xx' end
, SUM(anet) NetSales

INTO #SUBFINAL
FROM
inv_master i (NOLOCK)
INNER JOIN inv_master_add ia (NOLOCK) ON ia.part_no = i.part_no
INNER JOIN cvo_sbm_details s (NOLOCK) ON s.part_no = i.part_no
WHERE 1=1
AND (ia.category_2 like '%child%' OR i.category IN ('op','jc') )
AND s.YYYYMMDD BETWEEN  @P4From and @P1To 
GROUP BY RIGHT(s.customer,5), s.ship_to, ia.category_2, i.category,
CASE WHEN yyyymmdd >= @P1From THEN 'CY'
		  WHEN yyyymmdd >= @p2from THEN 'PY1'
		  WHEN yyyymmdd >= @p3from THEN 'PY2'
		  WHEN yyyymmdd >= @p4from THEN 'PY3'
		  WHEN yyyymmdd >= @p5from THEN 'PY4'
		  ELSE 'xxx' END,
CASE  		WHEN i.category = 'OP' AND ia.category_2 LIKE '%adult%' THEN '3OP Ad'
			WHEN i.category = 'JC' AND ia.category_2 LIKE '%adult%' THEN '4JC Ad'
			WHEN ia.category_2 LIKE '%child%' AND i.category NOT IN ( 'FP','DD' ) THEN '1Kids'
			WHEN ia.category_2 LIKE '%child%'  AND i.category IN ( 'FP','DD' ) THEN '2Pedi'

			ELSE 'xx' end
          
-- get number of programs sold

INSERT INTO #SUBFINAL (mcust,
ship_to,
yr,
kidtype,
NetSales) 
SELECT RIGHT(s.customer,5) mcust, s.ship_to

, yr = CASE WHEN yyyymmdd >= @P1From THEN 'CY'
		  WHEN yyyymmdd >= @p2from THEN 'PY1'
		  WHEN yyyymmdd >= @p3from THEN 'PY2'
		  WHEN yyyymmdd >= @p4from THEN 'PY3'
		  WHEN yyyymmdd >= @p5from THEN 'PY4'
		  ELSE 'xxx' end
, kidtype = '5#Pgms'

, COUNT(DISTINCT s.promo_id) NetSales

FROM
cvo_sbm_details s (NOLOCK) 
WHERE 1=1
AND s.promo_id IN ('kids','bts') AND s.isbo = 0
AND s.YYYYMMDD BETWEEN  @P4From and @P1To 
GROUP BY RIGHT(s.customer,5), s.ship_to, s.promo_id,
CASE WHEN yyyymmdd >= @P1From THEN 'CY'
		  WHEN yyyymmdd >= @p2from THEN 'PY1'
		  WHEN yyyymmdd >= @p3from THEN 'PY2'
		  WHEN yyyymmdd >= @p4from THEN 'PY3'
		  WHEN yyyymmdd >= @p5from THEN 'PY4'
		  ELSE 'xxx' END


SELECT T2.terr, t2.mergecust Cust, t2.ship_to_code ShipTo
, t2.Name, t2.addr2, t2.addr3, t2.city, t2.state, t2.zip, t2.cntry
, t2.phone, t2.fax, lower(t2.email)email, t2.Contact, 
yr,
kidtype,
Netsales
, maxyr = CASE WHEN s.maxyr = 1 AND netsales <> 0 AND kidtype <> '5#Pgms' THEN 1 ELSE 0 END 

FROM
(SELECT mcust ,
        ship_to ,
        yr ,
        kidtype ,
        SUM(NetSales) NetSales
		,Row_Number() over(partition by mcust, ship_to, kidtype ORDER BY SUM(netsales) desc ) AS maxyr
		FROM #SUBFINAL
		WHERE kidtype NOT in ('xx')
		GROUP BY mcust, ship_to, yr, kidtype
) s
JOIN #Cust3 T2 (nolock) ON s.Mcust=t2.MergeCust and s.ship_to=t2.ship_to_code



END

-- SELECT * FROM #SUBFINAL

--SELECT s.customer, s.ship_to, COUNT(DISTINCT s.promo_id), c_year FROM cvo_sbm_details s 
--WHERE s.promo_id IN ('kids','bts')
--GROUP BY s.customer, s.ship_to, s.X_MONTH, s.c_year


--SELECT * FROM cvo_sbm_details WHERE customer = '037343' AND promo_id IN ('bts','kids')
GO
