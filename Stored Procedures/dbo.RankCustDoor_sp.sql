SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		elabarbera
-- Create date: 7/1/2013
-- Description:	NEW Ranking Customer Door
-- EXEC RankCustDoor_sp '1/1/2015','6/30/2015','TRUE',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL
-- EXEC RankCustDoor_sp '1/1/2013','6/30/2013','TRUE','IZOD','IZX',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL
-- EXEC RankCustDoor_sp '1/1/2015','6/30/2015','TRUE'  -- This ONE
-- EXEC RankCustDoor_sp '7/1/2012','6/30/2013','TRUE','IZX','IZOD',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL
-- =============================================

-- CUSTOMER RANKING
-------- CREATED BY *Elizabeth LaBarbera*  7/1/2013
-- 7/27/2015 - fixed 'more than 1 returned' run-time error - tag

CREATE Procedure [dbo].[RankCustDoor_sp]

@DateFrom datetime,
@DateTo datetime,
@sf  varchar(5) = 'TRUE',
@col1 varchar(5) = NULL,
@col2 varchar(5) = NULL,
@col3 varchar(5) = NULL,
@col4 varchar(5) = NULL,
@col5 varchar(5) = NULL,
@col6 varchar(5) = NULL,
@col7 varchar(5) = NULL,
@col8 varchar(5) = NULL,
@col9 varchar(5) = NULL,
@col10 varchar(5) = NULL


AS
Begin
SET NOCOUNT ON


----  DECLARES
DECLARE @DateFromLY datetime                                    
DECLARE @DateToLY datetime

--DECLARE @DateFrom datetime                                    
--DECLARE @DateTo datetime		

--DECLARE @sf  varchar(100)
--DECLARE @col1 varchar(100)
--DECLARE @col2 varchar(100)
--DECLARE @col3 varchar(100)
--DECLARE @col4 varchar(100)
--DECLARE @col5 varchar(100)
--DECLARE @col6 varchar(100)
--DECLARE @col7 varchar(100)
--DECLARE @col8 varchar(100)
--DECLARE @col9 varchar(100)
--DECLARE @col10 varchar(100)

----  SETS
--SET @DateFrom = '1/1/2015'
--SET @DateTo = '6/30/2015'
SET @dateTo= dateadd(day,1,(dateadd(second,-1,@dateTo)))
SET @DateFromLY = dateadd(year,-1,@dateFrom)
SET @DateToLY = dateadd(Year,-1,@dateTo)
--SET @SF = 'TRUE' -- 'SF'
--SET @col1 = NULL
--SET @col2 = NULL
--SET @col3 = NULL
--SET @col4 = NULL
--SET @col5 = NULL
--SET @col6 = NULL
--SET @col7 = NULL
--SET @col8 = NULL
--SET @col9 = NULL
--SET @col10 = NULL
--  select @dateFrom, @dateto, @datefromly, @datetoly, @Col1, @col2, @col3, @col4, @col5, @col6, @col7, @col8, @col9, @col10


-- Lookup 0 & 9 affiliated Accounts
IF(OBJECT_ID('tempdb.dbo.#Rank_Aff') is not null)  
drop table #Rank_Aff  
select a.customer_code as from_cust, a.ship_to_code as shipto, a.affiliated_cust_code as to_cust
into #Rank_Aff
from armaster a (nolock) inner join
armaster b (nolock) on a.affiliated_cust_code = b.customer_code and a.ship_to_code = b.ship_to_code
where a.status_type <> 1 and a.address_type <> 9 
and a.affiliated_cust_code<> '' and a.affiliated_cust_code is not null
and b.status_type = 1 and b.address_type <> 9
-- Select * from #Rank_Aff  

-- Pull Customer INFO
IF(OBJECT_ID('tempdb.dbo.#RankCusts_S1') is not null)
drop table dbo.#RankCusts_S1
SELECT CASE WHEN T2.DOOR = 1 THEN 'Y' else '' end as Door,
t1.customer_code, ship_to_code, territory_code as Terr
, Address_name, addr2
, case when addr3 like '%, __ %' then '' else addr3 end as addr3
, case when addr4 like '%, __ %' then '' else addr4 end as addr4
, City, State, Postal_code, country_code, contact_name, contact_phone, tlx_twx
, case when contact_email is null then '' when contact_email like '%@cvoptical%' then '' else contact_email end as contact_email
, addr_sort1 as CustType
INTO #RankCusts_S1
FROM armaster t1 (nolock)
LEFT OUTER JOIN CVO_ARMASTER_ALL T2 ON T1.CUSTOMER_CODE = T2.CUSTOMER_CODE AND T1.SHIP_TO_CODE=T2.SHIP_TO
WHERE t1.ADDRESS_TYPE <>9
-- select * from #RankCusts_S1

-- Get Designation Codes, into one field  (Where Designations date range is in report date range
IF(OBJECT_ID('tempdb.dbo.#RankCusts_S2A') is not null)
drop table dbo.#RankCusts_S2A
      ;WITH C AS 
            ( SELECT customer_code, code FROM cvo_cust_designation_codes (nolock) )
            select Distinct customer_code,
                              STUFF ( ( SELECT '; ' + code
                              FROM cvo_cust_designation_codes (nolock)
                              WHERE customer_code = C.customer_code
                              AND (START_DATE IS NULL or START_DATE <= @DATETO)
                              AND (END_DATE IS NULL or END_DATE >= @DATETO)
                              FOR XML PATH ('') ), 1, 1, ''  ) AS NEW
      INTO #RankCusts_s2A
      FROM C

-- Get Primary for each Customer
IF(OBJECT_ID('tempdb.dbo.#Primary') is not null)
drop table dbo.#Primary
SELECT CUSTOMER_CODE, CODE, START_DATE, END_DATE INTO #Primary FROM cvo_cust_designation_codes (nolock)  WHERE PRIMARY_FLAG=1
-- select * from #Primary

-- Add Designation & Primary to Customer Data
IF(OBJECT_ID('tempdb.dbo.#RankCusts_S2B') is not null)
drop table dbo.#RankCusts_S2B
Select T1.*, ISNULL(T2.NEW, '' ) as Designations, ISNULL(t3.code, '' ) as PriDesig
INTO #RankCusts_S2B
from #RankCusts_S1 t1
left outer join #RankCusts_S2A t2 on t1.customer_code=t2.customer_code
left outer join #Primary t3 on t1.customer_code=t3.customer_code
--select * from #RankCusts_S2B

--Add ReClassify for Affiliation 
IF(OBJECT_ID('tempdb.dbo.#Rank_Aff_All') is not null)
drop table dbo.#Rank_Aff_All
select X.* INTO #Rank_Aff_All FROM
( select from_cust AS CUST,'I' as Code from #Rank_Aff     UNION
select to_cust AS CUST,'A' Code from #Rank_Aff ) X
--SELECT * FROM #Rank_Aff_All 

-- Add 0/9 Statu to Customer Data
IF(OBJECT_ID('tempdb.dbo.#RankCusts_S3a') is not null)
drop table dbo.#RankCusts_S3a
-- 7/27/15 - fix 'more than 1 returned' error -- tag
Select ISNULL(t2.code,(SELECT TOP 1
 case when status_type = 1 then 'A' else 'I' end 
 FROM armaster (nolock) t11 
 WHERE t1.customer_code=t11.customer_code and t1.ship_to_code = t11.ship_to_code) ) Status,
 Right(customer_code, 5) as MergeCust, T1.*
INTO #RankCusts_S3a
from #RankCusts_S2B t1
full outer join #Rank_Aff_All t2 on t1.customer_code=t2.cust
-- select * from #RankCusts_S3a

-- add in Parent &/or BG
IF(OBJECT_ID('tempdb.dbo.#RankCusts_S3c') is not null)
drop table dbo.#RankCusts_S3c
select t1.*, 
case when t1.customer_code=t2.parent then '' else t2.parent end as Parent 
INTO #RankCusts_S3c
from #RankCusts_S3a t1
right outer join artierrl (nolock) t2 on t1.customer_code=t2.rel_cust
where t1.customer_code is not null
-- select * from #RankCusts_S3c 

-- CLEAN OUT EXTRA DUPLICATE 0 & 9
IF(OBJECT_ID('tempdb.dbo.#RankCusts_S3') is not null)
drop table dbo.#RankCusts_S3
select MIN(ISNULL(Status,''))Status,			MergeCust, 
MIN(isnull(Door,''))Door,						MIN(isnull(customer_code,''))customer_code,	ISNULL(ship_to_code,'') ship_to_code, 
MIN(isnull(terr,''))terr,						MIN(isnull(Address_name,''))Address_name,	MIN(isnull(addr2,''))addr2,
MIN(isnull(addr3,''))addr3,						MIN(isnull(addr4,''))addr4,	
MIN(isnull(City,''))City,						MIN(isnull(State,''))State,				MIN(isnull(Postal_code,''))Postal_code,
MIN(isnull(Country_code,''))Country,			MIN(isnull(contact_name,''))contact_name,
MIN(isnull(contact_phone,''))contact_phone,		MIN(isnull(tlx_twx,''))tlx_twx,			MIN(isnull(contact_email,''))contact_email,
MIN(isnull(Designations,''))Designations,		MIN(isnull(PriDesig,''))PriDesig,		MIN(isnull(Parent,''))Parent,	MIN(isnull(CustType,''))CustType
INTO #RankCusts_S3
FROM #RankCusts_S3c
group by MergeCust, ISNULL(ship_to_code,'')
order by MergeCust
-- select * from #RankCusts_S3

-- SOURCE SALES
IF(OBJECT_ID('tempdb.dbo.#SOURCE') is not null)
drop table dbo.#SOURCE
SELECT Right(customer,5)MergeCust
, T2.*
, CASE WHEN yyyymmdd between @DateFrom and @Dateto THEN 'TY' ELSE 'LY' END AS 'TYLY'
INTO #SOURCE
FROM cvo_sbm_details (nolock) t2
JOIN INV_MASTER (NOLOCK) INV ON T2.PART_NO=INV.PART_NO
Where (yyyymmdd between @DateFrom and @Dateto OR yyyymmdd between @DateFromLY and @DatetoLY)
	AND ( (@SF = 'TRUE' AND TYPE_CODE like ('%')) 
OR (@SF = 'SUN' AND TYPE_CODE = ('SUN')) 
OR (@SF = 'FRAME' AND TYPE_CODE = ('FRAME')) 
OR (@SF = 'SF' AND TYPE_CODE IN ('SUN','FRAME'))  )
	AND ( (@col1 is null and category like '%') OR ( @col1 is not null and ( category = @col1 OR category = @col2 
OR category = @col3 OR category = @col4 OR category = @col5 OR category = @col6 OR category = @col7 OR category = @col8 OR category = @col9 OR category = @col10 ) ) )
-- SELECT distinct customer, ship_to,TYLY, user_category, promo_id, return_code, sum(anet)NET FROM #SOURCE where Customer like '%18739' and yyyymmdd between '7/1/2012' and '6/30/2013' group by customer, ship_to,TYLY, user_category, promo_id, return_code
-- SELECT sum(anet) FROM #SOURCE where Customer like '%18739' and TYLY = 'TY'

-- DATA
IF(OBJECT_ID('tempdb.dbo.#Data') is not null)
drop table dbo.#data
select  
Status, t1.MergeCust as Customer
, ship_to_code as ShipTo
, Terr
, Door
, Address_name
, addr2
, addr3
, addr4
, City
, State, Postal_code, Country, contact_name, contact_phone, tlx_twx, contact_email, 
-- SALES
CASE WHEN TYLY = 'TY' THEN ISNULL(SUM(ANET),0) ELSE 0 END AS NetSTY,
CASE WHEN TYLY <> 'TY' THEN ISNULL(SUM(ANET),0) ELSE 0 END AS NetSLY,

CASE WHEN TYLY = 'TY' AND user_category LIKE 'RX%' THEN ISNULL(SUM(ANET),0) ELSE 0 END AS NetSRXTY,
CASE WHEN TYLY <> 'TY' AND user_category LIKE 'RX%' THEN ISNULL(SUM(ANET),0) ELSE 0 END AS NetSRXLY,

CASE WHEN TYLY = 'TY' AND user_category NOT LIKE 'RX%' THEN ISNULL(SUM(ANET),0) ELSE 0 END AS NetSSTTY,
CASE WHEN TYLY <> 'TY' AND user_category NOT LIKE 'RX%' THEN ISNULL(SUM(ANET),0) ELSE 0 END AS NetSSTLY,

CASE WHEN TYLY = 'TY' THEN -1*ISNULL(SUM(areturns),0) ELSE 0 END AS RetSTY,
CASE WHEN TYLY <> 'TY' THEN -1*ISNULL(SUM(areturns),0) ELSE 0 END AS RetSLY,

CASE WHEN TYLY = 'TY' and return_code <> 'EXC' THEN -1*ISNULL(SUM(areturns),0) ELSE 0 END AS RetSRaTY,
CASE WHEN TYLY <> 'TY' and return_code <> 'EXC' THEN -1*ISNULL(SUM(areturns),0) ELSE 0 END AS RetSRaLY,

CASE WHEN TYLY = 'TY' AND user_category LIKE 'RX%' THEN -1*ISNULL(SUM(areturns),0) ELSE 0 END AS RetSRXTY,
CASE WHEN TYLY <> 'TY' AND user_category LIKE 'RX%' THEN -1*ISNULL(SUM(areturns),0) ELSE 0 END AS RetSRXLY,

CASE WHEN TYLY = 'TY' AND user_category NOT LIKE 'RX%' THEN -1*ISNULL(SUM(areturns),0) ELSE 0 END AS RetSSTTY,
CASE WHEN TYLY <> 'TY' AND user_category NOT LIKE 'RX%' THEN -1*ISNULL(SUM(areturns),0) ELSE 0 END AS RetSSTLY,

CASE WHEN TYLY = 'TY' THEN ISNULL(SUM(asales),0) ELSE 0 END AS GrossSTY,
CASE WHEN TYLY <> 'TY' THEN ISNULL(SUM(asales),0) ELSE 0 END AS GrossSLY,

CASE WHEN TYLY = 'TY' AND promo_id <> 'BEP' THEN ISNULL(SUM(asales),0) ELSE 0 END AS GrossNoBepSTY,
CASE WHEN TYLY <> 'TY' AND promo_id <> 'BEP' THEN ISNULL(SUM(asales),0) ELSE 0 END AS GrossNoBepSLY,
-- UNITS
CASE WHEN TYLY = 'TY' THEN ISNULL(SUM(qnet),0) ELSE 0 END AS NetUTY,
CASE WHEN TYLY <> 'TY' THEN ISNULL(SUM(qnet),0) ELSE 0 END AS NetULY,

CASE WHEN TYLY = 'TY' AND user_category LIKE 'RX%' THEN ISNULL(SUM(qnet),0) ELSE 0 END AS NetURXTY,
CASE WHEN TYLY <> 'TY' AND user_category LIKE 'RX%' THEN ISNULL(SUM(qnet),0) ELSE 0 END AS NetURXLY,

CASE WHEN TYLY = 'TY' AND user_category NOT LIKE 'RX%' THEN ISNULL(SUM(qnet),0) ELSE 0 END AS NetUSTTY,
CASE WHEN TYLY <> 'TY' AND user_category NOT LIKE 'RX%' THEN ISNULL(SUM(qnet),0) ELSE 0 END AS NetUSTLY,

CASE WHEN TYLY = 'TY' THEN -1*ISNULL(SUM(qreturns),0) ELSE 0 END AS RetUTY,
CASE WHEN TYLY <> 'TY' THEN -1*ISNULL(SUM(qreturns),0) ELSE 0 END AS RetULY,

CASE WHEN TYLY = 'TY' and return_code <> 'EXC' THEN -1*ISNULL(SUM(qreturns),0) ELSE 0 END AS RetURaTY,
CASE WHEN TYLY <> 'TY' and return_code <> 'EXC' THEN -1*ISNULL(SUM(qreturns),0) ELSE 0 END AS RetURaLY,

CASE WHEN TYLY = 'TY' AND user_category LIKE 'RX%' THEN -1*ISNULL(SUM(qreturns),0) ELSE 0 END AS RetURXTY,
CASE WHEN TYLY <> 'TY' AND user_category LIKE 'RX%' THEN -1*ISNULL(SUM(qreturns),0) ELSE 0 END AS RetURXLY,

CASE WHEN TYLY = 'TY' AND user_category NOT LIKE 'RX%' THEN -1*ISNULL(SUM(qreturns),0) ELSE 0 END AS RetUSTTY,
CASE WHEN TYLY <> 'TY' AND user_category NOT LIKE 'RX%' THEN -1*ISNULL(SUM(qreturns),0) ELSE 0 END AS RetUSTLY,

CASE WHEN TYLY = 'TY' THEN ISNULL(SUM(qsales),0) ELSE 0 END AS GrossUTY,
CASE WHEN TYLY <> 'TY' THEN ISNULL(SUM(qsales),0) ELSE 0 END AS GrossULY,

CASE WHEN TYLY = 'TY' AND promo_id <> 'BEP' THEN ISNULL(SUM(qsales),0) ELSE 0 END AS GrossNoBepUTY,
CASE WHEN TYLY <> 'TY' AND promo_id <> 'BEP' THEN ISNULL(SUM(qsales),0) ELSE 0 END AS GrossNoBepULY,
--
ISNULL(Designations, '' )ActiveDesignation, ISNULL(PriDesig, '' ) CurrentPrimary, ISNULL(Parent, '' )PARENT, ISNULL(CustType, '' )CustType
INTO #DATA
FROM #RankCusts_S3 t1
left outer join #Source t2 on t1.MergeCust=t2.MergeCust and t1.ship_to_code=t2.ship_to
GROUP BY Status, t1.MergeCust, ship_to_code, Terr, Door, Address_name, addr2, addr3, addr4, City, State, Postal_code, Country, contact_name, contact_phone, tlx_twx, contact_email, Designations, PriDesig, Parent, CustType, TYLY, user_category, promo_id, return_code
-- select * from #Data where Customer='18739' AND NETsTY <>0
-- select * from #Data

-- FINAL SELECT
SELECT Status, Customer, ShipTo, Terr, Door, Address_name, addr2, addr3, addr4, City, State, Postal_code, Country, contact_name, contact_phone, tlx_twx, contact_email, 
-- SALES
CASE WHEN door='y' and ShipTo<>''	THEN ISNULL(sum(NetSTY),0)    	WHEN door<>'y' and ShipTo<>''	THEN 0	
ELSE ( (select ISNULL(sum(NetSTY),0) from #Data T11 where t1.Customer=t11.Customer and t11.door='y' and t11.ShipTo='') + (select ISNULL(sum(NetSTY),0) from #Data T11 where t1.Customer=t11.Customer and t11.door<>'y' and t11.ShipTo<>'')) END AS 'NetSTY', 

CASE WHEN Door='Y' and ShipTo<>''	THEN ISNULL(sum(NetSLY),0)    	WHEN Door<>'Y' and ShipTo<>''	THEN 0	
ELSE ( (select ISNULL(sum(NetSLY),0) from #Data T11 where t1.Customer=t11.Customer and t11.Door='Y' and t11.ShipTo='') + (select ISNULL(sum(NetSLY),0) from #Data T11 where t1.Customer=t11.Customer and t11.Door<>'Y' and t11.ShipTo<>'')) END AS 'NetSLY', 

CASE WHEN Door='Y' and ShipTo<>''	THEN ISNULL(sum(NetSRXTY),0)    	WHEN Door<>'Y' and ShipTo<>''	THEN 0	
ELSE ( (select ISNULL(sum(NetSRXTY),0) from #Data T11 where t1.Customer=t11.Customer and t11.Door='Y' and t11.ShipTo='') + (select ISNULL(sum(NetSRXTY),0) from #Data T11 where t1.Customer=t11.Customer and t11.Door<>'Y' and t11.ShipTo<>'')) END AS 'NetSRXTY', 

CASE WHEN Door='Y' and ShipTo<>''	THEN ISNULL(sum(NetSRXLY),0)    	WHEN Door<>'Y' and ShipTo<>''	THEN 0	
ELSE ( (select ISNULL(sum(NetSRXLY),0) from #Data T11 where t1.Customer=t11.Customer and t11.Door='Y' and t11.ShipTo='') + (select ISNULL(sum(NetSRXLY),0) from #Data T11 where t1.Customer=t11.Customer and t11.Door<>'Y' and t11.ShipTo<>'')) END AS 'NetSRXLY', 

CASE WHEN Door='Y' and ShipTo<>''	THEN ISNULL(sum(NetSSTTY),0)    	WHEN Door<>'Y' and ShipTo<>''	THEN 0	
ELSE ( (select ISNULL(sum(NetSSTTY),0) from #Data T11 where t1.Customer=t11.Customer and t11.Door='Y' and t11.ShipTo='') + (select ISNULL(sum(NetSSTTY),0) from #Data T11 where t1.Customer=t11.Customer and t11.Door<>'Y' and t11.ShipTo<>'')) END AS 'NetSSTTY', 

CASE WHEN Door='Y' and ShipTo<>''	THEN ISNULL(sum(NetSSTLY),0)    	WHEN Door<>'Y' and ShipTo<>''	THEN 0	
ELSE ( (select ISNULL(sum(NetSSTLY),0) from #Data T11 where t1.Customer=t11.Customer and t11.Door='Y' and t11.ShipTo='') + (select ISNULL(sum(NetSSTLY),0) from #Data T11 where t1.Customer=t11.Customer and t11.Door<>'Y' and t11.ShipTo<>'')) END AS 'NetSSTLY', 

CASE WHEN Door='Y' and ShipTo<>''	THEN ISNULL(sum(RetSTY),0)    	WHEN Door<>'Y' and ShipTo<>''	THEN 0	
ELSE ( (select ISNULL(sum(RetSTY),0) from #Data T11 where t1.Customer=t11.Customer and t11.Door='Y' and t11.ShipTo='') + (select ISNULL(sum(RetSTY),0) from #Data T11 where t1.Customer=t11.Customer and t11.Door<>'Y' and t11.ShipTo<>'')) END AS 'RetSTY', 

CASE WHEN Door='Y' and ShipTo<>''	THEN ISNULL(sum(RetSLY),0)    	WHEN Door<>'Y' and ShipTo<>''	THEN 0	
ELSE ( (select ISNULL(sum(RetSLY),0) from #Data T11 where t1.Customer=t11.Customer and t11.Door='Y' and t11.ShipTo='') + (select ISNULL(sum(RetSLY),0) from #Data T11 where t1.Customer=t11.Customer and t11.Door<>'Y' and t11.ShipTo<>'')) END AS 'RetSLY', 

CASE WHEN Door='Y' and ShipTo<>''	THEN ISNULL(sum(RetSRaTY),0)    	WHEN Door<>'Y' and ShipTo<>''	THEN 0	
ELSE ( (select ISNULL(sum(RetSRaTY),0) from #Data T11 where t1.Customer=t11.Customer and t11.Door='Y' and t11.ShipTo='') + (select ISNULL(sum(RetSRaTY),0) from #Data T11 where t1.Customer=t11.Customer and t11.Door<>'Y' and t11.ShipTo<>'')) END AS 'RetSRaTY', 

CASE WHEN Door='Y' and ShipTo<>''	THEN ISNULL(sum(RetSRaLY),0)    	WHEN Door<>'Y' and ShipTo<>''	THEN 0	
ELSE ( (select ISNULL(sum(RetSRaLY),0) from #Data T11 where t1.Customer=t11.Customer and t11.Door='Y' and t11.ShipTo='') + (select ISNULL(sum(RetSRaLY),0) from #Data T11 where t1.Customer=t11.Customer and t11.Door<>'Y' and t11.ShipTo<>'')) END AS 'RetSRaLY', 

CASE WHEN Door='Y' and ShipTo<>''	THEN ISNULL(sum(RetSRXTY),0)    	WHEN Door<>'Y' and ShipTo<>''	THEN 0	
ELSE ( (select ISNULL(sum(RetSRXTY),0) from #Data T11 where t1.Customer=t11.Customer and t11.Door='Y' and t11.ShipTo='') + (select ISNULL(sum(RetSRXTY),0) from #Data T11 where t1.Customer=t11.Customer and t11.Door<>'Y' and t11.ShipTo<>'')) END AS 'RetSRXTY', 

CASE WHEN Door='Y' and ShipTo<>''	THEN ISNULL(sum(RetSRXLY),0)    	WHEN Door<>'Y' and ShipTo<>''	THEN 0	
ELSE ( (select ISNULL(sum(RetSRXLY),0) from #Data T11 where t1.Customer=t11.Customer and t11.Door='Y' and t11.ShipTo='') + (select ISNULL(sum(RetSRXLY),0) from #Data T11 where t1.Customer=t11.Customer and t11.Door<>'Y' and t11.ShipTo<>'')) END AS 'RetSRXLY', 

CASE WHEN Door='Y' and ShipTo<>''	THEN ISNULL(sum(RetSSTTY),0)    	WHEN Door<>'Y' and ShipTo<>''	THEN 0	
ELSE ( (select ISNULL(sum(RetSSTTY),0) from #Data T11 where t1.Customer=t11.Customer and t11.Door='Y' and t11.ShipTo='') + (select ISNULL(sum(RetSSTTY),0) from #Data T11 where t1.Customer=t11.Customer and t11.Door<>'Y' and t11.ShipTo<>'')) END AS 'RetSSTTY', 

CASE WHEN Door='Y' and ShipTo<>''	THEN ISNULL(sum(RetSSTLY),0)    	WHEN Door<>'Y' and ShipTo<>''	THEN 0	
ELSE ( (select ISNULL(sum(RetSSTLY),0) from #Data T11 where t1.Customer=t11.Customer and t11.Door='Y' and t11.ShipTo='') + (select ISNULL(sum(RetSSTLY),0) from #Data T11 where t1.Customer=t11.Customer and t11.Door<>'Y' and t11.ShipTo<>'')) END AS 'RetSSTLY', 

CASE WHEN Door='Y' and ShipTo<>''	THEN ISNULL(sum(GrossSTY),0)    	WHEN Door<>'Y' and ShipTo<>''	THEN 0	
ELSE ( (select ISNULL(sum(GrossSTY),0) from #Data T11 where t1.Customer=t11.Customer and t11.Door='Y' and t11.ShipTo='') + (select ISNULL(sum(GrossSTY),0) from #Data T11 where t1.Customer=t11.Customer and t11.Door<>'Y' and t11.ShipTo<>'')) END AS 'GrossSTY', 

CASE WHEN Door='Y' and ShipTo<>''	THEN ISNULL(sum(GrossSLY),0)    	WHEN Door<>'Y' and ShipTo<>''	THEN 0	
ELSE ( (select ISNULL(sum(GrossSLY),0) from #Data T11 where t1.Customer=t11.Customer and t11.Door='Y' and t11.ShipTo='') + (select ISNULL(sum(GrossSLY),0) from #Data T11 where t1.Customer=t11.Customer and t11.Door<>'Y' and t11.ShipTo<>'')) END AS 'GrossSLY', 

CASE WHEN Door='Y' and ShipTo<>''	THEN ISNULL(sum(GrossNoBepSTY),0)    	WHEN Door<>'Y' and ShipTo<>''	THEN 0	
ELSE ( (select ISNULL(sum(GrossNoBepSTY),0) from #Data T11 where t1.Customer=t11.Customer and t11.Door='Y' and t11.ShipTo='') + (select ISNULL(sum(GrossNoBepSTY),0) from #Data T11 where t1.Customer=t11.Customer and t11.Door<>'Y' and t11.ShipTo<>'')) END AS 'GrossNoBepSTY', 

CASE WHEN Door='Y' and ShipTo<>''	THEN ISNULL(sum(GrossNoBepSLY),0)    	WHEN Door<>'Y' and ShipTo<>''	THEN 0	
ELSE ( (select ISNULL(sum(GrossNoBepSLY),0) from #Data T11 where t1.Customer=t11.Customer and t11.Door='Y' and t11.ShipTo='') + (select ISNULL(sum(GrossNoBepSLY),0) from #Data T11 where t1.Customer=t11.Customer and t11.Door<>'Y' and t11.ShipTo<>'')) END AS 'GrossNoBepSLY', 

-- UNITS
CASE WHEN Door='Y' and ShipTo<>''	THEN ISNULL(sum(NetUTY),0)    	WHEN Door<>'Y' and ShipTo<>''	THEN 0	
ELSE ( (select ISNULL(sum(NetUTY),0) from #Data T11 where t1.Customer=t11.Customer and t11.Door='Y' and t11.ShipTo='') + (select ISNULL(sum(NetUTY),0) from #Data T11 where t1.Customer=t11.Customer and t11.Door<>'Y' and t11.ShipTo<>'')) END AS 'NetUTY', 

CASE WHEN Door='Y' and ShipTo<>''	THEN ISNULL(sum(NetULY),0)    	WHEN Door<>'Y' and ShipTo<>''	THEN 0	
ELSE ( (select ISNULL(sum(NetULY),0) from #Data T11 where t1.Customer=t11.Customer and t11.Door='Y' and t11.ShipTo='') + (select ISNULL(sum(NetULY),0) from #Data T11 where t1.Customer=t11.Customer and t11.Door<>'Y' and t11.ShipTo<>'')) END AS 'NetULY', 

CASE WHEN Door='Y' and ShipTo<>''	THEN ISNULL(sum(NetURXTY),0)    	WHEN Door<>'Y' and ShipTo<>''	THEN 0	
ELSE ( (select ISNULL(sum(NetURXTY),0) from #Data T11 where t1.Customer=t11.Customer and t11.Door='Y' and t11.ShipTo='') + (select ISNULL(sum(NetURXTY),0) from #Data T11 where t1.Customer=t11.Customer and t11.Door<>'Y' and t11.ShipTo<>'')) END AS 'NetURXTY', 

CASE WHEN Door='Y' and ShipTo<>''	THEN ISNULL(sum(NetURXLY),0)    	WHEN Door<>'Y' and ShipTo<>''	THEN 0	
ELSE ( (select ISNULL(sum(NetURXLY),0) from #Data T11 where t1.Customer=t11.Customer and t11.Door='Y' and t11.ShipTo='') + (select ISNULL(sum(NetURXLY),0) from #Data T11 where t1.Customer=t11.Customer and t11.Door<>'Y' and t11.ShipTo<>'')) END AS 'NetURXLY', 

CASE WHEN Door='Y' and ShipTo<>''	THEN ISNULL(sum(NetUSTTY),0)    	WHEN Door<>'Y' and ShipTo<>''	THEN 0	
ELSE ( (select ISNULL(sum(NetUSTTY),0) from #Data T11 where t1.Customer=t11.Customer and t11.Door='Y' and t11.ShipTo='') + (select ISNULL(sum(NetUSTTY),0) from #Data T11 where t1.Customer=t11.Customer and t11.Door<>'Y' and t11.ShipTo<>'')) END AS 'NetUSTTY', 

CASE WHEN Door='Y' and ShipTo<>''	THEN ISNULL(sum(NetUSTLY),0)    	WHEN Door<>'Y' and ShipTo<>''	THEN 0	
ELSE ( (select ISNULL(sum(NetUSTLY),0) from #Data T11 where t1.Customer=t11.Customer and t11.Door='Y' and t11.ShipTo='') + (select ISNULL(sum(NetUSTLY),0) from #Data T11 where t1.Customer=t11.Customer and t11.Door<>'Y' and t11.ShipTo<>'')) END AS 'NetUSTLY', 

CASE WHEN Door='Y' and ShipTo<>''	THEN ISNULL(sum(RetUTY),0)    	WHEN Door<>'Y' and ShipTo<>''	THEN 0	
ELSE ( (select ISNULL(sum(RetUTY),0) from #Data T11 where t1.Customer=t11.Customer and t11.Door='Y' and t11.ShipTo='') + (select ISNULL(sum(RetUTY),0) from #Data T11 where t1.Customer=t11.Customer and t11.Door<>'Y' and t11.ShipTo<>'')) END AS 'RetUTY', 

CASE WHEN Door='Y' and ShipTo<>''	THEN ISNULL(sum(RetULY),0)    	WHEN Door<>'Y' and ShipTo<>''	THEN 0	
ELSE ( (select ISNULL(sum(RetULY),0) from #Data T11 where t1.Customer=t11.Customer and t11.Door='Y' and t11.ShipTo='') + (select ISNULL(sum(RetULY),0) from #Data T11 where t1.Customer=t11.Customer and t11.Door<>'Y' and t11.ShipTo<>'')) END AS 'RetULY', 

CASE WHEN Door='Y' and ShipTo<>''	THEN ISNULL(sum(RetURaTY),0)    	WHEN Door<>'Y' and ShipTo<>''	THEN 0	
ELSE ( (select ISNULL(sum(RetURaTY),0) from #Data T11 where t1.Customer=t11.Customer and t11.Door='Y' and t11.ShipTo='') + (select ISNULL(sum(RetURaTY),0) from #Data T11 where t1.Customer=t11.Customer and t11.Door<>'Y' and t11.ShipTo<>'')) END AS 'RetURaTY', 

CASE WHEN Door='Y' and ShipTo<>''	THEN ISNULL(sum(RetURaLY),0)    	WHEN Door<>'Y' and ShipTo<>''	THEN 0	
ELSE ( (select ISNULL(sum(RetURaLY),0) from #Data T11 where t1.Customer=t11.Customer and t11.Door='Y' and t11.ShipTo='') + (select ISNULL(sum(RetURaLY),0) from #Data T11 where t1.Customer=t11.Customer and t11.Door<>'Y' and t11.ShipTo<>'')) END AS 'RetURaLY', 

CASE WHEN Door='Y' and ShipTo<>''	THEN ISNULL(sum(RetURXTY),0)    	WHEN Door<>'Y' and ShipTo<>''	THEN 0	
ELSE ( (select ISNULL(sum(RetURXTY),0) from #Data T11 where t1.Customer=t11.Customer and t11.Door='Y' and t11.ShipTo='') + (select ISNULL(sum(RetURXTY),0) from #Data T11 where t1.Customer=t11.Customer and t11.Door<>'Y' and t11.ShipTo<>'')) END AS 'RetURXTY', 

CASE WHEN Door='Y' and ShipTo<>''	THEN ISNULL(sum(RetURXLY),0)    	WHEN Door<>'Y' and ShipTo<>''	THEN 0	
ELSE ( (select ISNULL(sum(RetURXLY),0) from #Data T11 where t1.Customer=t11.Customer and t11.Door='Y' and t11.ShipTo='') + (select ISNULL(sum(RetURXLY),0) from #Data T11 where t1.Customer=t11.Customer and t11.Door<>'Y' and t11.ShipTo<>'')) END AS 'RetURXLY', 

CASE WHEN Door='Y' and ShipTo<>''	THEN ISNULL(sum(RetUSTTY),0)    	WHEN Door<>'Y' and ShipTo<>''	THEN 0	
ELSE ( (select ISNULL(sum(RetUSTTY),0) from #Data T11 where t1.Customer=t11.Customer and t11.Door='Y' and t11.ShipTo='') + (select ISNULL(sum(RetUSTTY),0) from #Data T11 where t1.Customer=t11.Customer and t11.Door<>'Y' and t11.ShipTo<>'')) END AS 'RetUSTTY', 

CASE WHEN Door='Y' and ShipTo<>''	THEN ISNULL(sum(RetUSTLY),0)    	WHEN Door<>'Y' and ShipTo<>''	THEN 0	
ELSE ( (select ISNULL(sum(RetUSTLY),0) from #Data T11 where t1.Customer=t11.Customer and t11.Door='Y' and t11.ShipTo='') + (select ISNULL(sum(RetUSTLY),0) from #Data T11 where t1.Customer=t11.Customer and t11.Door<>'Y' and t11.ShipTo<>'')) END AS 'RetUSTLY', 
 
CASE WHEN Door='Y' and ShipTo<>''	THEN ISNULL(sum(GrossUTY),0)    	WHEN Door<>'Y' and ShipTo<>''	THEN 0	
ELSE ( (select ISNULL(sum(GrossUTY),0) from #Data T11 where t1.Customer=t11.Customer and t11.Door='Y' and t11.ShipTo='') + (select ISNULL(sum(GrossUTY),0) from #Data T11 where t1.Customer=t11.Customer and t11.Door<>'Y' and t11.ShipTo<>'')) END AS 'GrossUTY', 

CASE WHEN Door='Y' and ShipTo<>''	THEN ISNULL(sum(GrossULY),0)    	WHEN Door<>'Y' and ShipTo<>''	THEN 0	
ELSE ( (select ISNULL(sum(GrossULY),0) from #Data T11 where t1.Customer=t11.Customer and t11.Door='Y' and t11.ShipTo='') + (select ISNULL(sum(GrossULY),0) from #Data T11 where t1.Customer=t11.Customer and t11.Door<>'Y' and t11.ShipTo<>'')) END AS 'GrossULY', 

CASE WHEN Door='Y' and ShipTo<>''	THEN ISNULL(sum(GrossNoBepUTY),0)    	WHEN Door<>'Y' and ShipTo<>''	THEN 0	
ELSE ( (select ISNULL(sum(GrossNoBepUTY),0) from #Data T11 where t1.Customer=t11.Customer and t11.Door='Y' and t11.ShipTo='') + (select ISNULL(sum(GrossNoBepUTY),0) from #Data T11 where t1.Customer=t11.Customer and t11.Door<>'Y' and t11.ShipTo<>'')) END AS 'GrossNoBepUTY', 

CASE WHEN Door='Y' and ShipTo<>''	THEN ISNULL(sum(GrossNoBepULY),0)    	WHEN Door<>'Y' and ShipTo<>''	THEN 0	
ELSE ( (select ISNULL(sum(GrossNoBepULY),0) from #Data T11 where t1.Customer=t11.Customer and t11.Door='Y' and t11.ShipTo='') + (select ISNULL(sum(GrossNoBepULY),0) from #Data T11 where t1.Customer=t11.Customer and t11.Door<>'Y' and t11.ShipTo<>'')) END AS 'GrossNoBepULY', 


--ISNULL((select sum(asales) from cvo_sbm_details t11 where t1.customer=right(t11.customer,5) and yyyymmdd between DATEADD(YEAR,-1,DATEADD(Day, 0, DATEDIFF(Day, 0, GetDate()))) and DATEADD(Day, -1, DATEDIFF(Day, 0, GetDate())) and promo_id <> 'BEP'),0) GrossSNoBep_R12,
--(-1*ISNULL((select sum(areturns) from cvo_sbm_details t11 where t1.customer=right(t11.customer,5) and yyyymmdd between DATEADD(YEAR,-1,DATEADD(Day, 0, DATEDIFF(Day, 0, GetDate()))) and DATEADD(Day, -1, DATEDIFF(Day, 0, GetDate())) and return_code <> 'EXC'),0)) RetSRa_R12,

--ISNULL((select sum(Qsales) from cvo_sbm_details t11 where t1.customer=right(t11.customer,5) and yyyymmdd between DATEADD(YEAR,-1,DATEADD(Day, 0, DATEDIFF(Day, 0, GetDate()))) and DATEADD(Day, -1, DATEDIFF(Day, 0, GetDate())) and promo_id <> 'BEP'),0) GrossUNoBep_R12,
--(-1*ISNULL((select sum(Qreturns) from cvo_sbm_details t11 where t1.customer=right(t11.customer,5) and yyyymmdd between DATEADD(YEAR,-1,DATEADD(Day, 0, DATEDIFF(Day, 0, GetDate()))) and DATEADD(Day, -1, DATEDIFF(Day, 0, GetDate())) and return_code <> 'EXC'),0)) RetURa_R12,

ActiveDesignation, CurrentPrimary, RTRIM(LTRIM(Parent))Parent, CustType
FROM #DATA T1
Where Door='Y'
GROUP BY status, customer, SHIPTO, Terr, Door, address_name, addr2, addr3, addr4, city, state, postal_code, country, contact_name, contact_phone, tlx_twx, contact_email, ActiveDesignation, CurrentPrimary, Parent, CustType
ORDER BY Terr, SUM(NetSTY) DESC
-- EXEC RankCustDoor_sp '1/1/2012','12/30/2012'

End
GO
