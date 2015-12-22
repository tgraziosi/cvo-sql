SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		elabarbera
-- Create date: 7/1/2013
-- Description:	NEW Ranking Customer Ship To
-- 12/5/2014 - update RA figures to only include RA's was including WTY
-- 12/5/2014 - tag change to make r12 period ending on the report ending date, not today
-- 12/19/14 - tag - return amounts should not include 'exc' returns (rebills)
-- EXEC RankCustShipTo_sp '1/1/2015','02/16/2015','TRUE'
-- =============================================

-- CUSTOMER RANKING
-------- CREATED BY *Elizabeth LaBarbera*  7/1/2013

CREATE Procedure [dbo].[RankCustShipTo_sp]

@DateFrom datetime,
@DateTo datetime,
@sf  varchar(5) = 'TRUE',
@collection varchar(1000) = null

AS
Begin
SET NOCOUNT ON

-- RUN LIVE FROM HERE

----  DECLARES
-- DECLARE @DateFrom datetime                                    
-- DECLARE @DateTo datetime		
DECLARE @DateFromLY datetime                                    
DECLARE @DateToLY datetime
--DECLARE @sf  varchar(100)
--declare @collection varchar(1024)

----  SETS
--SET @DateFrom = '1/1/2015'
--SET @DateTo = '02/16/2015'
	SET @dateTo= dateadd(day,1,(dateadd(second,-1,@dateTo)))
SET @DateFromLY = dateadd(year,-1,@dateFrom)
SET @DateToLY = dateadd(Year,-1,@dateTo)
--SET @SF = 'TRUE' -- TRUE FOR ALL FALSE FOR S/F


-- select @dateFrom, @dateto, @datefromly, @datetoly, @SF, @Collection

-- tag 090914 - use comma list for collections instead of multiple vars
CREATE TABLE #collection ([collection] VARCHAR(5))
if @collection is null
insert into #collection ([collection])
select distinct kys from category (nolock) where void = 'n'
else
INSERT INTO #collection ([collection])
SELECT  LISTITEM FROM dbo.f_comma_list_to_table(@collection)


-- Lookup 0 & 9 affiliated Accounts
IF(OBJECT_ID('tempdb.dbo.#Rank_Aff') is not null)  
drop table #Rank_Aff  
select a.customer_code as from_cust
-- , a.ship_to_code as shipto
   , a.affiliated_cust_code as to_cust
into #Rank_Aff
from armaster a (nolock) 
inner join armaster b (nolock) on a.affiliated_cust_code = b.customer_code -- and a.ship_to_code = b.ship_to_code
--where a.status_type <> 1 and a.address_type <> 9 
--and isnull(a.affiliated_cust_code,'') <> '' 
--and b.status_type = 1 and b.address_type <> 9
---- Select * from #Rank_Aff  
where a.address_type <> 9 
and isnull(a.affiliated_cust_code,'') <> '' 
and  b.address_type <> 9
-- Select * from #Rank_Aff where from_cust like '%14837'

-- Pull Customer INFO
IF(OBJECT_ID('tempdb.dbo.#RankCusts_S1') is not null)
drop table dbo.#RankCusts_S1
SELECT CASE WHEN T2.DOOR = 1 THEN 'Y' else '' end as Door,
t1.customer_code, right(t1.customer_code,5) mergecust, ship_to_code, territory_code as Terr, 
Address_name, addr2, case when addr3 like '%, __ %' then '' else addr3 end as addr3
, case when addr4 like '%, __ %' then '' else addr4 end as addr4
, City, State, Postal_code, country_code, contact_name, contact_phone, tlx_twx, case when contact_email is null then '' when contact_email like '%@cvoptical%' then '' else contact_email end as contact_email, addr_sort1 as CustType
INTO #RankCusts_S1
FROM armaster t1 (nolock)
LEFT OUTER JOIN CVO_ARMASTER_ALL T2 (nolock) ON T1.CUSTOMER_CODE = T2.CUSTOMER_CODE AND T1.SHIP_TO_CODE=T2.SHIP_TO
WHERE t1.ADDRESS_TYPE <>9
-- select * from #RankCusts_S1 where customer_code like '%14837'

-- Get Designation Codes, into one field  (Where Designations date range is in report date range
IF(OBJECT_ID('tempdb.dbo.#RankCusts_S2A') is not null)
drop table dbo.#RankCusts_S2A
      --;WITH C AS 
      --      ( SELECT customer_code, code FROM cvo_cust_designation_codes (nolock) )
            select right(customer_code,5) mergecust,
                              STUFF ( ( SELECT distinct '; ' + code
                              FROM cvo_cust_designation_codes (nolock)
                              WHERE right(customer_code,5) = right(C.customer_code,5)
                              and isnull(start_date,@dateto) <= @dateto
							  -- AND (START_DATE IS NULL or START_DATE <= @DATETO)
                              and isnull(end_date,@dateto) >=@dateto
							  -- AND (END_DATE IS NULL or END_DATE >=@DATETO)
                              FOR XML PATH ('') ), 1, 1, ''  ) AS NEW
			INTO #RankCusts_s2A
			from cvo_cust_designation_codes (nolock) c
			group by right(customer_code,5)
      -- FROM C

-- select * From #rankcusts_s2a where mergecust like '14837'

-- Get Primary for each Customer
IF(OBJECT_ID('tempdb.dbo.#Primary') is not null) drop table dbo.#Primary
SELECT right(customer_code,5) mergecust, CODE, START_DATE, END_DATE 
INTO #Primary 
FROM cvo_cust_designation_codes (nolock)  
WHERE PRIMARY_FLAG=1
and isnull(start_date,@dateto) <= @DateTo and (isnull(end_date,@dateto) >= @DateTo)

-- select * from #Primary where mergecust = '014837'

-- Add Designation & Primary to Customer Data
IF(OBJECT_ID('tempdb.dbo.#RankCusts_S2B') is not null) drop table dbo.#RankCusts_S2B
Select T1.*, ISNULL(T2.NEW, '' ) as Designations, ISNULL(t3.code, '' ) as PriDesig
INTO #RankCusts_S2B
from #RankCusts_S1 t1
left outer join #RankCusts_S2A t2 on t1.mergecust=t2.mergecust
left outer join #Primary t3 on t1.mergecust=t3.mergecust
--select * from #RankCusts_S2B where mergecust = '14837'
-- select * from #RankCusts_S1 where mergecust = '14837'

--Add ReClassify for Affiliation 
IF(OBJECT_ID('tempdb.dbo.#Rank_Aff_All') is not null)
drop table dbo.#Rank_Aff_All
select X.cust, x.code
INTO #Rank_Aff_All 
FROM
( select from_cust AS CUST,'I' as Code from #Rank_Aff 
  UNION
  select to_cust AS CUST,'A' Code from #Rank_Aff ) as X
--SELECT * FROM #Rank_Aff_All where cust like '%14837%'

-- Add 0/9 Statu to Customer Data
IF(OBJECT_ID('tempdb.dbo.#RankCusts_S3a') is not null)
drop table dbo.#RankCusts_S3a
Select 
ISNULL(t2.code,(select top 1 case when status_type = 1 then 'A' else 'I' end from armaster (nolock) t11 where t1.customer_code=t11.customer_code and t1.ship_to_code=t11.ship_to_code) ) Status,
 -- Right(customer_code, 5) as MergeCust, 
 T1.*
INTO #RankCusts_S3a
from #RankCusts_S2B t1
full outer join #Rank_Aff_All t2 on t1.customer_code=t2.cust
-- select * from #RankCusts_S3a where customer_code like '%14837%'

-- add in Parent &/or BG
IF(OBJECT_ID('tempdb.dbo.#RankCusts_S3c') is not null) drop table dbo.#RankCusts_S3c
select t1.*, 
case when t1.customer_code=t2.parent then '' else t2.parent end as Parent 
INTO #RankCusts_S3c
from #RankCusts_S3a t1
right outer join artierrl (nolock) t2 on t1.customer_code=t2.rel_cust where t1.customer_code is not null
-- select * from #RankCusts_S3c 

-- CLEAN OUT EXTRA DUPLICATE 0 & 9
IF(OBJECT_ID('tempdb.dbo.#RankCusts_S3') is not null)
drop table dbo.#RankCusts_S3
select MIN(ISNULL(Status,''))Status,			MergeCust, 
MIN(isnull(Door,''))Door,						MIN(isnull(customer_code,''))customer_code,		ship_to_code, 
MIN(isnull(terr,''))terr,						MIN(isnull(Address_name,''))Address_name,	MIN(isnull(addr2,''))addr2,
MIN(isnull(addr3,''))addr3,						MIN(isnull(addr4,''))addr4,	
MIN(isnull(City,''))City,						MIN(isnull(State,''))State,				MIN(isnull(Postal_code,''))Postal_code,
MIN(isnull(Country_code,''))Country,			MIN(isnull(contact_name,''))contact_name,
MIN(isnull(contact_phone,''))contact_phone,		MIN(isnull(tlx_twx,''))tlx_twx,			MIN(isnull(contact_email,''))contact_email,
MIN(isnull(Designations,''))Designations,		MIN(isnull(PriDesig,''))PriDesig,		MIN(isnull(Parent,''))Parent,	MIN(isnull(CustType,''))CustType
INTO #RankCusts_S3
FROM #RankCusts_S3c
group by MergeCust, Ship_to_code
order by MergeCust
-- select * from #RankCusts_S3 where mergecust like '14837'

-- SOURCE SALES
IF(OBJECT_ID('tempdb.dbo.#SOURCE') is not null) drop table dbo.#SOURCE
SELECT Right(customer,5) MergeCust, T2.*, 
-- CASE WHEN yyyymmdd between @DateFrom and @Dateto THEN 'TY' ELSE 'LY' END AS 'TYLY'
CASE WHEN yyyymmdd >= @DateFrom THEN 'TY' ELSE 'LY' END AS TYLY

INTO #SOURCE
FROM inv_master (nolock) inv
join cvo_sbm_details (nolock) t2 on T2.PART_NO=INV.PART_NO
join #collection on inv.category = #collection.[collection]

Where ( (@SF = 'TRUE' AND TYPE_CODE like ('%')) 
OR (@SF = 'SUN' AND TYPE_CODE = ('SUN')) 
OR (@SF = 'FRAME' AND TYPE_CODE = ('FRAME')) 
OR (@SF = 'SF' AND TYPE_CODE IN ('SUN','FRAME'))  )
and (yyyymmdd between @DateFrom and @Dateto OR yyyymmdd between @DateFromLY and @DatetoLY)

--AND ( (@col1 is null and category like '%') OR ( @col1 is not null and ( category = @col1 OR category = @col2 
--	OR category = @col3 OR category = @col4 OR category = @col5 OR category = @col6 OR category = @col7 OR category = @col8 OR category = @col9 OR category = @col10 ) ) )
-- SELECT distinct customer, ship_to,TYLY, user_category, promo_id, return_code, sum(anet)NET FROM #SOURCE where Customer like '%18739' and yyyymmdd between '7/1/2012' and '6/30/2013' group by customer, ship_to,TYLY, user_category, promo_id, return_code
-- SELECT * FROM #SOURCE where mergecust like '14837' yyyymmdd between '1/1/2013' and '12/31/2013'

-- DATA
IF(OBJECT_ID('tempdb.dbo.#Data') is not null)
drop table dbo.#data
select  
Status, t1.MergeCust as Customer, ship_to_code as ShipTo, Terr, Door, Address_name, addr2, addr3, addr4, City, State, Postal_code, Country, contact_name, contact_phone, tlx_twx, contact_email, 
-- SALES
CASE WHEN TYLY = 'TY' THEN ISNULL(SUM(ANET),0) ELSE 0.00 END AS NetSTY,
CASE WHEN TYLY = 'LY' THEN ISNULL(SUM(ANET),0) ELSE 0.00 END AS NetSLY,

CASE WHEN TYLY = 'TY' AND user_category LIKE 'RX%' THEN ISNULL(SUM(ANET),0.00) ELSE 0.00 END AS NetSRXTY,
CASE WHEN TYLY = 'LY' AND user_category LIKE 'RX%' THEN ISNULL(SUM(ANET),0.00) ELSE 0.00 END AS NetSRXLY,

CASE WHEN TYLY = 'TY' AND user_category NOT LIKE 'RX%' THEN ISNULL(SUM(ANET),0.00) ELSE 0.00 END AS NetSSTTY,
CASE WHEN TYLY = 'LY' AND user_category NOT LIKE 'RX%' THEN ISNULL(SUM(ANET),0.00) ELSE 0.00 END AS NetSSTLY,

CASE WHEN TYLY = 'TY' and return_code <> 'EXC' THEN -1*ISNULL(SUM(areturns),0.00) ELSE 0.00 END AS RetSTY,
CASE WHEN TYLY = 'LY' and return_code <> 'EXC' THEN -1*ISNULL(SUM(areturns),0.00) ELSE 0.00 END AS RetSLY,

CASE WHEN TYLY = 'TY' and return_code = '' THEN -1*ISNULL(SUM(areturns),0.00) ELSE 0 END AS RetSRaTY,
CASE WHEN TYLY = 'LY' and return_code = '' THEN -1*ISNULL(SUM(areturns),0.00) ELSE 0 END AS RetSRaLY,

CASE WHEN TYLY = 'TY' AND user_category LIKE 'RX%' THEN -1*ISNULL(SUM(areturns),0) ELSE 0 END AS RetSRXTY,
CASE WHEN TYLY = 'LY' AND user_category LIKE 'RX%' THEN -1*ISNULL(SUM(areturns),0) ELSE 0 END AS RetSRXLY,

CASE WHEN TYLY = 'TY' AND user_category NOT LIKE 'RX%' THEN -1*ISNULL(SUM(areturns),0) ELSE 0 END AS RetSSTTY,
CASE WHEN TYLY = 'LY' AND user_category NOT LIKE 'RX%' THEN -1*ISNULL(SUM(areturns),0) ELSE 0 END AS RetSSTLY,

CASE WHEN TYLY = 'TY' THEN ISNULL(SUM(asales),0) ELSE 0 END AS GrossSTY,
CASE WHEN TYLY = 'LY' THEN ISNULL(SUM(asales),0) ELSE 0 END AS GrossSLY,

CASE WHEN TYLY = 'TY' AND promo_id <> 'BEP' THEN ISNULL(SUM(asales),0) ELSE 0 END AS GrossNoBepSTY,
CASE WHEN TYLY = 'LY' AND promo_id <> 'BEP' THEN ISNULL(SUM(asales),0) ELSE 0 END AS GrossNoBepSLY,
-- UNITS
CASE WHEN TYLY = 'TY' THEN ISNULL(SUM(qnet),0) ELSE 0 END AS NetUTY,
CASE WHEN TYLY = 'LY' THEN ISNULL(SUM(qnet),0) ELSE 0 END AS NetULY,

CASE WHEN TYLY = 'TY' AND user_category LIKE 'RX%' THEN ISNULL(SUM(qnet),0) ELSE 0 END AS NetURXTY,
CASE WHEN TYLY = 'LY' AND user_category LIKE 'RX%' THEN ISNULL(SUM(qnet),0) ELSE 0 END AS NetURXLY,

CASE WHEN TYLY = 'TY' AND user_category NOT LIKE 'RX%' THEN ISNULL(SUM(qnet),0) ELSE 0 END AS NetUSTTY,
CASE WHEN TYLY = 'LY' AND user_category NOT LIKE 'RX%' THEN ISNULL(SUM(qnet),0) ELSE 0 END AS NetUSTLY,

CASE WHEN TYLY = 'TY' and return_code <> 'EXC' THEN -1*ISNULL(SUM(qreturns),0) ELSE 0 END AS RetUTY,
CASE WHEN TYLY = 'LY' and return_code <> 'EXC' THEN -1*ISNULL(SUM(qreturns),0) ELSE 0 END AS RetULY,

--CASE WHEN TYLY = 'TY' and return_code <> 'EXC' THEN -1*ISNULL(SUM(qreturns),0) ELSE 0 END AS RetURaTY,
--CASE WHEN TYLY = 'LY' and return_code <> 'EXC' THEN -1*ISNULL(SUM(qreturns),0) ELSE 0 END AS RetURaLY,
CASE WHEN TYLY = 'TY' and return_code = '' THEN -1*ISNULL(SUM(qreturns),0) ELSE 0 END AS RetURaTY,
CASE WHEN TYLY = 'LY' and return_code = '' THEN -1*ISNULL(SUM(qreturns),0) ELSE 0 END AS RetURaLY,

CASE WHEN TYLY = 'TY' AND user_category LIKE 'RX%' THEN -1*ISNULL(SUM(qreturns),0) ELSE 0 END AS RetURXTY,
CASE WHEN TYLY = 'LY' AND user_category LIKE 'RX%' THEN -1*ISNULL(SUM(qreturns),0) ELSE 0 END AS RetURXLY,

CASE WHEN TYLY = 'TY' AND user_category NOT LIKE 'RX%' THEN -1*ISNULL(SUM(qreturns),0) ELSE 0 END AS RetUSTTY,
CASE WHEN TYLY = 'LY' AND user_category NOT LIKE 'RX%' THEN -1*ISNULL(SUM(qreturns),0) ELSE 0 END AS RetUSTLY,

CASE WHEN TYLY = 'TY' THEN ISNULL(SUM(qsales),0) ELSE 0 END AS GrossUTY,
CASE WHEN TYLY = 'LY' THEN ISNULL(SUM(qsales),0) ELSE 0 END AS GrossULY,

CASE WHEN TYLY = 'TY' AND promo_id <> 'BEP' THEN ISNULL(SUM(qsales),0) ELSE 0 END AS GrossNoBepUTY,
CASE WHEN TYLY = 'LY' AND promo_id <> 'BEP' THEN ISNULL(SUM(qsales),0) ELSE 0 END AS GrossNoBepULY,
--
ISNULL(Designations, '' )ActiveDesignation, ISNULL(PriDesig, '' ) CurrentPrimary, ISNULL(Parent, '' )PARENT, ISNULL(CustType, '' )CustType
INTO #DATA
FROM #RankCusts_S3 t1
left outer join #Source t2 on t1.MergeCust=t2.MergeCust and t1.ship_to_code=t2.ship_to
GROUP BY Status, t1.MergeCust, ship_to_code, Terr, Door, Address_name, addr2, addr3, addr4, City, State, Postal_code, Country, contact_name, contact_phone, tlx_twx, contact_email, Designations, PriDesig, Parent, CustType, TYLY, user_category, promo_id, return_code
-- select * from #Data where Customer='14837' AND NETsTY <>0

-- select sum(NetsTY), SUM(NetSLY) from #Data 

-- PULL Rolling 12 Numbers
IF(OBJECT_ID('tempdb.dbo.#R12DATA') is not null)
drop table dbo.#R12DATA
select DISTINCT right(CUSTOMER,5)Customer, SHIP_TO, 
CASE WHEN promo_id <> 'BEP' THEN ISNULL(SUM(asales),0) ELSE 0 END AS GrossNoBepSTY_R12,
-- CASE WHEN return_code <> 'EXC' THEN -1*ISNULL(SUM(areturns),0) ELSE 0 END AS RetSRaTY_R12, 
CASE WHEN return_code = '' THEN -1*ISNULL(SUM(areturns),0) ELSE 0 END AS RetSRaTY_R12, 
CASE WHEN promo_id <> 'BEP' and type_code in ('frame','sun') THEN ISNULL(SUM(qsales),0) ELSE 0 END AS GrossNoBepUTY_R12,
CASE WHEN return_code = '' and type_code in ('frame','sun') THEN -1*ISNULL(SUM(qreturns),0) ELSE 0 END AS RetURaTY_R12 
-- added 12/8/2014 - to match to bill-to report
,case when yyyymmdd <= dateadd(year,-1,@DateTo) THEN 'LY' else 'TY' end as Years
, yyyymmdd
INTO #R12DATA
from cvo_sbm_details sbm (nolock)
left outer join inv_master i (nolock) on i.part_no = sbm.part_no
-- 12/5/2014 - tag change to make r12 period ending on the report ending date, not today
where yyyymmdd between DATEADD(YEAR,-2,DATEADD(dd, 1, DATEDIFF(dd, 0, @DateTo))) and @DateTo
--where yyyymmdd between DATEADD(YEAR,-1,DATEADD(dd, 1, DATEDIFF(dd, 0, GETDATE()))) and --getdate()
GROUP BY CUSTOMER, SHIP_TO, PROMO_ID, RETURN_CODE, type_code, yyyymmdd
ORDER BY CUSTOMER, SHIP_TO

IF(OBJECT_ID('tempdb.dbo.#R12') is not null)
drop table dbo.#R12
SELECT DISTINCT CUSTOMER, SHIP_TO, SUM(RetSRaTY_R12)RetSRaTY_R12, SUM(GrossNoBepSTY_R12)GrossNoBepSTY_R12, SUM(RetURaTY_R12)RetURaTY_R12, SUM(GrossNoBepUTY_R12)GrossNoBepUTY_R12  , years
INTO #R12 FROM #R12DATA
group by CUSTOMER, SHIP_TO, years

-- PULL PRIOR 3 YEARS DATA
DECLARE @PrYr1From datetime
DECLARE @PrYr1To datetime
SET @PrYr1From = DATEADD(YEAR, DATEDIFF(YEAR, 0, DATEADD(YEAR, -1, @DateFrom)), 0)
SET @PrYr1To = DATEADD(MILLISECOND, -3, DATEADD(YEAR, DATEDIFF(YEAR, 0, DATEADD(YEAR, -1, @DateTo)) + 1, 0))
IF(OBJECT_ID('tempdb.dbo.#P3YRDATA') is not null)
drop table dbo.#P3YRDATA
SELECT DISTINCT sbm.C_YEAR as [YEAR], RIGHT(sbm.Customer,5)Customer, sbm.ship_to as ShipTo, sum(sbm.ANET)NET 
INTO #P3YRDATA
FROM cvo_sbm_details sbm (nolock) 
join inv_master inv (nolock) on sbm.part_no = inv.part_no
join #collection on inv.category = #collection.[collection]
WHERE yyyymmdd between dateadd(yy,-2,@PrYr1From) AND @PrYr1To 
Group by C_YEAR, Customer, ship_to 

-- FINAL SELECT
SELECT Status, t1.Customer, ShipTo, Terr, Door, Address_name, addr2, addr3, addr4, City, State, Postal_code, Country, contact_name, contact_phone, tlx_twx, contact_email, 
-- SALES
SUM(NetSTY)NetSTY, 
SUM(NetSLY)NetSLY, 
SUM(NetSRXTY)NetSRXTY, 
SUM(NetSRXLY)NetSRXLY, 
SUM(NetSSTTY)NetSSTTY, 
SUM(NetSSTLY)NetSSTLY, 
SUM(RetSTY)RetSTY, 
SUM(RetSLY)RetSLY, 
SUM(RetSRaTY)RetSRaTY, 
SUM(RetSRaLY)RetSRaLY, 
SUM(RetSRXTY)RetSRXTY, 
SUM(RetSRXLY)RetSRXLY, 
SUM(RetSSTTY)RetSSTTY, 
SUM(RetSSTLY)RetSSTLY, 
SUM(GrossSTY)GrossSTY, 
SUM(GrossSLY)GrossSLY, 
SUM(GrossNoBepSTY)GrossNoBepSTY, 
SUM(GrossNoBepSLY)GrossNoBepSLY, 
-- UNITS
SUM(NetUTY)NetUTY, 
SUM(NetULY)NetULY, 
SUM(NetURXTY)NetURXTY, 
SUM(NetURXLY)NetURXLY, 
SUM(NetUSTTY)NetUSTTY, 
SUM(NetUSTLY)NetUSTLY, 
SUM(RetUTY)RetUTY, 
SUM(RetULY)RetULY, 
SUM(RetURaTY)RetURaTY, 
SUM(RetURaLY)RetURaLY, 
SUM(RetURXTY)RetURXTY, 
SUM(RetURXLY)RetURXLY, 
SUM(RetUSTTY)RetUSTTY, 
SUM(RetUSTLY)RetUSTLY, 
SUM(GrossUTY)GrossUTY, 
SUM(GrossULY)GrossULY, 
SUM(GrossNoBepUTY)GrossNoBepUTY, 
SUM(GrossNoBepULY)GrossNoBepULY, 

ISNULL(SUM(RetSRaTY_R12),0)RetSRaTY_R12,
ISNULL(SUM(GrossNoBepSTY_R12),0)GrossNoBepSTY_R12,
ISNULL(SUM(RetURaTY_R12),0)RetURaTY_R12,
ISNULL(SUM(GrossNoBepUTY_R12),0)GrossNoBepUTY_R12,

ActiveDesignation, CurrentPrimary, RTRIM(LTRIM(Parent))Parent, CustType,
(select TOP 1 Address_name from #Data T12 where t1.customer=t12.customer and t12.shipTo='') m_Address_name,
(select TOP 1 City from #Data T12 where t1.customer=t12.customer and t12.shipTo='') m_City,
(select TOP 1 State from #Data T12 where t1.customer=t12.customer and t12.shipTo='') m_State,
(select TOP 1 Postal_code from #Data T12 where t1.customer=t12.customer and t12.shipTo='') m_Postal_code,

ISNULL(( select sum(NET) from #P3YRDATA PY WHERE t1.Customer=PY.Customer and t1.shipto=py.shipto and Year = datepart(year,@PrYr1To)),0 ) PrYr1,
ISNULL(( select sum(NET) from #P3YRDATA PY WHERE t1.Customer=PY.Customer and t1.shipto=py.shipto and Year = datepart(year,dateadd(year,-1,@PrYr1To)) ),0 ) PrYr2,
ISNULL(( select sum(NET) from #P3YRDATA PY WHERE t1.Customer=PY.Customer and t1.shipto=py.shipto and Year = datepart(year,dateadd(year,-2,@PrYr1To)) ),0 ) PrYr3,
datepart(year,@PrYr1To) as PrYr1Name,
datepart(year,dateadd(year,-1,@PrYr1To)) as PrYr2Name,
datepart(year,dateadd(year,-2,@PrYr1To)) as PrYr3Name

FROM #DATA T1
left outer JOIN #R12 T2 ON T1.CUSTOMER=T2.CUSTOMER and T1.SHIPTO=T2.SHIP_TO and t2.years = 'TY'
-- where t1.customer like '%14837%'
GROUP BY status, t1.customer, SHIPTO, Terr, Door, address_name, addr2, addr3, addr4, city, state, postal_code, country, contact_name, contact_phone, tlx_twx, contact_email, ActiveDesignation, CurrentPrimary, Parent, CustType
ORDER BY Terr, SUM(NetSTY) DESC

-- EXEC RankCustShipTo_sp '7/22/2013','07/21/2014','TRUE' 

End
GO
GRANT EXECUTE ON  [dbo].[RankCustShipTo_sp] TO [public]
GO
