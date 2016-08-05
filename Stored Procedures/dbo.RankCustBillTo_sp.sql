SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



-- =============================================
-- Author:, , elabarbera
-- Create date: 7/1/2013
-- Description:, NEW Ranking Customer BILL TO
-- EXEC RankCustBillTo_sp '1/1/2015','03/31/2015','TRUE','bcbg,cvo,ch'
-- 12/5/2014 - tag - update RA figures to be only ra returns.  was including wty too
-- 12/19/14 - tag - update ra amounts to exclude RBs
-- -- SF STANDS FOR SUN FRAME ONLY DEFAULT IS ALL
-- =============================================

CREATE Procedure [dbo].[RankCustBillTo_sp]

@DateFrom datetime = null,
@DateTo datetime = null,
@sf  varchar(5) = 'TRUE',
@collection varchar(1000) = null

AS
Begin
SET NOCOUNT ON


-- --  DECLARES
DECLARE @DateFromTY datetime                                    
DECLARE @DateToTY datetime
DECLARE @DateFromLY datetime                    -- don't comment                
DECLARE @DateToLY datetime                        -- don't comment
--DECLARE @sf  varchar(100)


 ----  SETS
SET @DateFromTY = isnull(@datefrom,'1/1/2015')
SET @DateToTY = isnull(@dateto,getdate())


SET @DateToTY= dateadd(day,1,(dateadd(second,-1,@dateToTY)))   -- don't comment
SET @DateFromLY = dateadd(year,-1,@dateFromTY) -- don't comment
SET @DateToLY = dateadd(Year,-1,@dateToTY) -- don't comment
--SET @SF = 'TRUE' -- 'SF'


 --  select @dateFrom, @dateto, @datefromly, @datetoly, @collection


-- tag 090914 - use comma list for collections instead of multiple vars
CREATE TABLE #collection ([collection] VARCHAR(5))
if (@collection is null) 
 begin
  insert into #collection ([collection])
  select distinct kys from category where void ='n'
 end
else
begin
  INSERT INTO #collection ([collection])
  SELECT  LISTITEM FROM dbo.f_comma_list_to_table(@collection)
end

-- Lookup 0 & 9 affiliated Accounts
IF(OBJECT_ID('tempdb.dbo.#Rank_Aff') is not null)  drop table #Rank_Aff 
 
select a.customer_code as from_cust
	 , a.affiliated_cust_code as to_cust
into #Rank_Aff
from armaster a (nolock) 
inner join armaster b (nolock) on a.affiliated_cust_code = b.customer_code 
--where a.status_type <> 1 and a.address_type <> 9 
--and isnull(a.affiliated_cust_code,'') <> '' 
--and b.status_type = 1 and b.address_type <> 9
-- Select * from #Rank_Aff  
where a.address_type <> 9 
and isnull(a.affiliated_cust_code,'') <> '' 
and b.address_type <> 9
 -- Select * from #Rank_Aff  

-- Pull Customer INFO
IF(OBJECT_ID('tempdb.dbo.#RankCusts_S1') is not null) drop table dbo.#RankCusts_S1

SELECT t1.customer_code, Right(t1.customer_code,5) MergeCust
	, territory_code as Terr
	, Address_name, ISNULL(addr2,'')addr2
	, case when addr3 like '%, __ %' then '' else addr3 end as addr3
	, case when addr4 like '%, __ %' then '' else addr4 end as addr4
	, ISNULL(City,'')City, ISNULL(State,'')State, ISNULL(Postal_code,'')Postal_code, ISNULL(country_code,'')country_code, ISNULL(contact_name,'')contact_name, ISNULL(contact_phone,'')contact_phone, isnull(tlx_twx,'')tlx_twx, case when contact_email is null then '' when contact_email like '%@cvoptical%' then '' else contact_email end as contact_email, ISNULL(addr_sort1,'') as CustType, case when coop_eligible='' then 'N' else isnull(coop_eligible,'N') end as coop_eligible
	, isnull(ar30+AR60+AR90+AR120+AR150,0) PastDueAmt

INTO #RankCusts_S1
FROM armaster t1 (nolock)
LEFT OUTER JOIN CVO_ARMASTER_ALL T2 ON T1.CUSTOMER_CODE = T2.CUSTOMER_CODE AND T1.SHIP_TO_CODE=T2.SHIP_TO
left outer join ssrs_araging_temp ar on t1.customer_code = ar.cust_code
WHERE t1.ADDRESS_TYPE = 0
-- select * from #RankCusts_S1

-- Get Designation Codes, into one field  (Where Designations date range is in report date range
IF(OBJECT_ID('tempdb.dbo.#RankCusts_S2A') is not null)
drop table dbo.#RankCusts_S2A
      --;WITH C AS 
      --      ( SELECT customer_code, code FROM cvo_cust_designation_codes (nolock) )
            select c.customer_code, Right(c.customer_code,5) MergeCust, 
                   STUFF ( ( SELECT '; ' + code
                              FROM cvo_cust_designation_codes (nolock)
                              WHERE customer_code = C.customer_code
                              AND isnull(START_DATE,@dateto) <= @DATETO and isnull(end_date,@dateto) >= @dateto
                             FOR XML PATH ('') ), 1, 1, ''  ) AS NEW
			INTO #RankCusts_s2A
	  		from cvo_cust_designation_codes (nolock) c
			group by c.customer_code

      --FROM C

delete  from #RankCusts_s2A where NEW IS NULL
-- select * from #RankCusts_s2A

-- Get Primary for each Customer
IF(OBJECT_ID('tempdb.dbo.#Primary') is not null) drop table dbo.#Primary
SELECT CUSTOMER_CODE, Right(customer_code,5)MergeCust, CODE, START_DATE, END_DATE 
INTO #Primary 
FROM cvo_cust_designation_codes (nolock)  WHERE PRIMARY_FLAG = 1
and isnull(start_date,@dateto) <= @DateTo and (isnull(end_date,@dateto) >= @DateTo)
-- select * from #Primary

-- Add Designation & Primary to Customer Data
IF(OBJECT_ID('tempdb.dbo.#RankCusts_S2B') is not null) drop table dbo.#RankCusts_S2B
Select T1.*, ISNULL(T2.NEW, '' ) as Designations, ISNULL(t3.code, '' ) as PriDesig, 
	ISNULL(t3.Start_Date,'')Start_date, ISNULL(t3.End_Date,'')End_Date
INTO #RankCusts_S2B
from #RankCusts_S1 t1
left outer join #RankCusts_S2A t2 on t2.MergeCust=t1.MergeCust
left outer join #Primary t3 on t3.MergeCust=t1.MergeCust
--select * from #RankCusts_S2B

--Add ReClassify for Affiliation 
IF(OBJECT_ID('tempdb.dbo.#Rank_Aff_All') is not null) drop table dbo.#Rank_Aff_All
select X.* INTO #Rank_Aff_All FROM
( select from_cust AS CUST,'I' as Code from #Rank_Aff
  UNION
  select to_cust AS CUST,'A' Code from #Rank_Aff 
) X
--SELECT * FROM #Rank_Aff_All 

-- Add 0/9 Statu to Customer Data
IF(OBJECT_ID('tempdb.dbo.#RankCusts_S3a') is not null) drop table dbo.#RankCusts_S3a
Select ISNULL(t2.code,(select case when status_type = 1 then 'A' else 'I' end 
						from armaster (nolock) t11 where t1.customer_code=t11.customer_code and t11.ship_to_code = '') ) Status, T1.*
INTO #RankCusts_S3a
from #RankCusts_S2B t1
full outer join #Rank_Aff_All t2 on t1.customer_code=t2.cust

-- select * from #RankCusts_S3a

-- add in Parent &/or BG
IF(OBJECT_ID('tempdb.dbo.#RankCusts_S3c') is not null) drop table dbo.#RankCusts_S3c
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
select MIN(ISNULL(Status,''))Status
, MergeCust
, MIN(isnull(customer_code,''))customer_code
, MIN(isnull(terr,''))terr
, MIN(isnull(Address_name,''))Address_name, MIN(isnull(addr2,''))addr2
, MIN(isnull(addr3,''))addr3, MIN(isnull(addr4,''))addr4 
, MIN(isnull(City,''))City, MIN(isnull(State,''))State, MIN(isnull(Postal_code,''))Postal_code
, MIN(isnull(Country_code,''))Country
, MIN(isnull(contact_name,''))contact_name
, MIN(isnull(contact_phone,''))contact_phone
, MIN(isnull(tlx_twx,''))tlx_twx
, MIN(isnull(contact_email,''))contact_email
, MIN(isnull(Designations,''))Designations
, MIN(isnull(PriDesig,''))PriDesig
, MIN(Start_date)Start_date,MIN(end_date)End_date
, MIN(isnull(Parent,''))Parent 
, MIN(isnull(CustType,''))CustType
, MIN(isnull(coop_eligible,''))coop_eligible
, MIN(isnull(pastdueamt,0)) pastdueamt

INTO #RankCusts_S3
FROM #RankCusts_S3c
group by MergeCust
order by MergeCust
-- select * from #RankCusts_S3

-- SOURCE SALES
IF(OBJECT_ID('tempdb.dbo.#SOURCE') is not null) drop table dbo.#SOURCE
SELECT Right(customer,5)MergeCust, T2.*
, CASE WHEN yyyymmdd between @DateFromTY and @DatetoTY THEN 'TY' ELSE 'LY' END AS 'TYLY'
INTO #SOURCE
FROM cvo_sbm_details (nolock) t2
inner JOIN INV_MASTER (NOLOCK) INV ON T2.PART_NO=INV.PART_NO
inner join #collection on inv.category = #collection.[collection]
Where (yyyymmdd between @DateFromTY and @DatetoTY OR yyyymmdd between @DateFromLY and @DatetoLY)
-- Where (yyyymmdd between @DateFromly and @Dateto)
AND ( (@SF = 'TRUE' AND TYPE_CODE like ('%')) 
	OR (@SF = 'SUN' AND TYPE_CODE = ('SUN')) 
	OR (@SF = 'FRAME' AND TYPE_CODE = ('FRAME')) 
	OR (@SF = 'SF' AND TYPE_CODE IN ('SUN','FRAME'))  )

SET ANSI_WARNINGS OFF

-- DATA
IF(OBJECT_ID('tempdb.dbo.#Data') is not null) drop table dbo.#data
select  
Status, t1.MergeCust as Customer, Terr, Address_name
, addr2, addr3, addr4, City, State, Postal_code
, Country, contact_name, contact_phone, tlx_twx, contact_email, 
pastdueamt,
-- SALES
CASE WHEN TYLY = 'TY' THEN ISNULL(SUM(ANET),0) ELSE 0 END AS NetSTY,
CASE WHEN TYLY <> 'TY' THEN ISNULL(SUM(ANET),0) ELSE 0 END AS NetSLY,

CASE WHEN TYLY = 'TY' THEN ISNULL(SUM(LSales),0) ELSE 0 END AS ListSTY,
CASE WHEN TYLY <> 'TY' THEN ISNULL(SUM(LSales),0) ELSE 0 END AS ListSLY,

CASE WHEN TYLY = 'TY' AND user_category LIKE 'RX%' THEN ISNULL(SUM(ANET),0) ELSE 0 END AS NetSRXTY,
CASE WHEN TYLY <> 'TY' AND user_category LIKE 'RX%' THEN ISNULL(SUM(ANET),0) ELSE 0 END AS NetSRXLY,

CASE WHEN TYLY = 'TY' AND user_category NOT LIKE 'RX%' THEN ISNULL(SUM(ANET),0) ELSE 0 END AS NetSSTTY,
CASE WHEN TYLY <> 'TY' AND user_category NOT LIKE 'RX%' THEN ISNULL(SUM(ANET),0) ELSE 0 END AS NetSSTLY,

CASE WHEN TYLY = 'TY' and return_code <> 'EXC' THEN -1*ISNULL(SUM(areturns),0) ELSE 0 END AS RetSTY,
CASE WHEN TYLY <> 'TY' and return_code <> 'EXC' THEN -1*ISNULL(SUM(areturns),0) ELSE 0 END AS RetSLY,

CASE WHEN TYLY = 'TY' and return_code /*<> 'EXC'*/ = '' THEN -1*ISNULL(SUM(areturns),0) ELSE 0 END AS RetSRaTY,
CASE WHEN TYLY <> 'TY' and return_code /*<> 'EXC'*/ = '' THEN -1*ISNULL(SUM(areturns),0) ELSE 0 END AS RetSRaLY,

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

CASE WHEN TYLY = 'TY' and return_code <> 'EXC' THEN -1*ISNULL(SUM(qreturns),0) ELSE 0 END AS RetUTY,
CASE WHEN TYLY <> 'TY' and return_code <> 'EXC' THEN -1*ISNULL(SUM(qreturns),0) ELSE 0 END AS RetULY,

CASE WHEN TYLY = 'TY' and return_code /*<> 'EXC'*/ = '' THEN -1*ISNULL(SUM(qreturns),0) ELSE 0 END AS RetURaTY,
CASE WHEN TYLY <> 'TY' and return_code /*<> 'EXC'*/ = '' THEN -1*ISNULL(SUM(qreturns),0) ELSE 0 END AS RetURaLY,

CASE WHEN TYLY = 'TY' AND user_category LIKE 'RX%' THEN -1*ISNULL(SUM(qreturns),0) ELSE 0 END AS RetURXTY,
CASE WHEN TYLY <> 'TY' AND user_category LIKE 'RX%' THEN -1*ISNULL(SUM(qreturns),0) ELSE 0 END AS RetURXLY,

CASE WHEN TYLY = 'TY' AND user_category NOT LIKE 'RX%' THEN -1*ISNULL(SUM(qreturns),0) ELSE 0 END AS RetUSTTY,
CASE WHEN TYLY <> 'TY' AND user_category NOT LIKE 'RX%' THEN -1*ISNULL(SUM(qreturns),0) ELSE 0 END AS RetUSTLY,

CASE WHEN TYLY = 'TY' THEN ISNULL(SUM(qsales),0) ELSE 0 END AS GrossUTY,
CASE WHEN TYLY <> 'TY' THEN ISNULL(SUM(qsales),0) ELSE 0 END AS GrossULY,

CASE WHEN TYLY = 'TY' AND promo_id <> 'BEP' THEN ISNULL(SUM(qsales),0) ELSE 0 END AS GrossNoBepUTY,
CASE WHEN TYLY <> 'TY' AND promo_id <> 'BEP' THEN ISNULL(SUM(qsales),0) ELSE 0 END AS GrossNoBepULY,

CASE WHEN TYLY = 'TY' and yyyymmdd between start_date and (case when end_date ='1/1/1900' then getdate() else end_date end) THEN ISNULL(SUM(ANET),0) ELSE 0 END AS DesigNetSTY,

--
ISNULL(Designations, '' )ActiveDesignation, ISNULL(PriDesig, '' ) CurrentPrimary,
 Start_date as PriStart, end_date as PriEnd, ISNULL(Parent, '' )PARENT, 
 ISNULL(CustType, '' )CustType, ISNULL(Coop_eligible, 'N' )Coop_Eligible
INTO #DATA
FROM #RankCusts_S3 t1
left outer join #Source t2 on t1.MergeCust=t2.MergeCust
GROUP BY Status, t1.MergeCust, Terr, Address_name, addr2, addr3, addr4, City, State, Postal_code, Country, contact_name, contact_phone, tlx_twx, contact_email, Designations, PriDesig, start_date, end_date, Parent, CustType, TYLY, user_category, promo_id, return_code, coop_eligible, pastdueamt, yyyymmdd


-- PULL PRIOR 3 YEARS DATA

DECLARE @PrYr1From datetime
DECLARE @PrYr1To datetime
SET @PrYr1From = DATEADD(YEAR, DATEDIFF(YEAR, 0, DATEADD(YEAR, -1, @DateFromTY)), 0)
SET @PrYr1To = DATEADD(MILLISECOND, -3, DATEADD(YEAR, DATEDIFF(YEAR, 0, DATEADD(YEAR, -1, @DateTo)) + 1, 0))

IF(OBJECT_ID('tempdb.dbo.#P3YRDATA') is not null) drop table dbo.#P3YRDATA

SELECT C_YEAR as YEAR, RIGHT(Customer,5)Customer, sum(ANET)NET 
INTO #P3YRDATA
FROM cvo_sbm_details sbm (nolock)
join inv_master inv (nolock) on sbm.part_no = inv.part_no
join #collection on inv.category = #collection.[collection]
WHERE yyyymmdd between dateadd(yy,-2,@PrYr1From) AND @PrYr1To 
Group by C_YEAR, Customer 


-- PULL Rolling 12 Numbers

IF(OBJECT_ID('tempdb.dbo.#R12DATA') is not null) drop table dbo.#R12DATA

select right(CUSTOMER,5)Customer, 
CASE WHEN promo_id <> 'BEP' THEN ISNULL(SUM(asales),0) ELSE 0 END AS GrossNoBepSTY_R12,
CASE WHEN return_code /*<> 'EXC'*/ = '' THEN -1*ISNULL(SUM(areturns),0) ELSE 0 END AS RetSRaTY_R12, 
CASE WHEN promo_id <> 'BEP' AND TYPE_CODE IN('SUN','FRAME') THEN ISNULL(SUM(qsales),0) ELSE 0 END AS GrossNoBepUTY_R12,
CASE WHEN return_code /*<> 'EXC'*/ = '' AND TYPE_CODE IN('SUN','FRAME') THEN -1*ISNULL(SUM(qreturns),0) ELSE 0 END AS RetURaTY_R12,
case when yyyymmdd between DATEADD(YEAR,-2,DATEADD(dd, 1, DATEDIFF(dd, 0, @DateTo))) and dateadd(year,-1,@DateTo) THEN 'LY' else 'TY' end as Years, yyyymmdd
INTO #R12DATA
from cvo_sbm_details t1 (nolock)
inner join inv_master t2 (nolock) on t1.part_no=t2.part_no
where yyyymmdd between DATEADD(YEAR,-2,DATEADD(dd, 1, DATEDIFF(dd, 0, @DateTo))) and @DateTo
GROUP BY CUSTOMER, PROMO_ID, RETURN_CODE, TYPE_CODE, yyyymmdd
ORDER BY CUSTOMER
-- select distinct yyyymmdd from #R12DATA where years='LY' order by yyyymmdd

IF(OBJECT_ID('tempdb.dbo.#R12') is not null) drop table dbo.#R12
SELECT CUSTOMER, 
SUM(RetSRaTY_R12)RetSRaTY_R12, 
SUM(GrossNoBepSTY_R12)GrossNoBepSTY_R12, 
SUM(RetURaTY_R12)RetURaTY_R12, 
SUM(GrossNoBepUTY_R12)GrossNoBepUTY_R12  , Years
INTO #R12 FROM #R12DATA
group by CUSTOMER, Years
-- select * from #R12


IF(OBJECT_ID('tempdb.dbo.#coopdata') is not null)  drop table dbo.#coopdata
CREATE TABLE [dbo].[#coopdata](
[territory_code] [varchar](8) NULL,
[salesperson_code] [varchar](8) NULL,
[customer_code] [varchar](5) NULL,
[customer_name] [varchar](40) NULL,
[coop_threshold_amount] [decimal](20, 8) NULL,
[coop_cust_rate] [decimal](20, 8) NULL,
[desig_code] [varchar](10) NULL,
[yyear] [int] NOT NULL,
[coop_sales] [decimal](38, 8) NOT NULL,
[coop_earned] [decimal](38, 6) NULL,
[coop_redeemed] [float] NOT NULL
) ON [PRIMARY]

INSERT INTO #coopdata EXEC cvo_coop_status_sp
-- SELECT * FROM #COOPDATA

-- PULL RXE DATA
IF(OBJECT_ID('tempdb.dbo.#RXEFREIGHT') is not null)  drop table #RXEFREIGHT
-- Free Freight Invoices
select t1.ORDER_NO, t1.EXT, Right(t1.CUST_CODE,5)Cust_code, T1.SHIP_TO, DATE_ENTERED, t1.date_shipped, t1.WHO_ENTERED, FREIGHT_ALLOW_TYPE, SOLD_TO, sum(shipped)Shipped, TOTAL_AMT_ORDER, tot_ord_freight, 
(select sum(t12.weight_ea) from ord_list t12 (nolock) 
	where t1.order_no=t12.order_no and t1.ext=t12.order_ext group by t12.order_no, t12.order_ext)
	OrdWeight,
weight as CtnWeight, CS_DIM_WEIGHT, freight_charge, 
ship_to_country_cd, ship_to_zip, routing, promo_id,
(SELECT TOP 1 CODE FROM CVO_CUST_DESIGNATION_CODES CD WHERE CODE IN ('RXE','RX3','RX5','GPN-RXE') -- 7/26/16 - add GPN-RXE 
	AND (isnull(END_DATE,@dateto) >= @DateTo) AND T1.CUST_CODE = CD.CUSTOMER_CODE ORDER BY START_DATE DESC)Designation,
dbo.f_cvo_FreightRateLookup(ROUTING, LEFT(SHIP_TO_ZIP,5), CS_DIM_WEIGHT ) as UnchargedRates,
rxDesig = CASE WHEN t3.promo_level = '5' THEN 'rx5' ELSE 'rx3' end
INTO #RXEFREIGHT
FROM orders_all t1 (nolock)
inner JOIN CVO_ARMASTER_ALL T2 (NOLOCK) ON T1.CUST_CODE=T2.CUSTOMER_CODE AND T1.SHIP_TO=T2.SHIP_TO
inner JOIN cvo_orders_all t3 (NOLOCK) on t1.order_no=t3.order_no and t1.ext=t3.ext
inner join tdc_carton_tx t4 (nolock) on t1.order_no=t4.order_no and t1.ext=t4.order_ext
inner join ord_list t5 (nolock) on t1.order_no=t5.order_no and t1.ext=t5.order_ext
inner join inv_master t6 (nolock) on t5.part_no=t6.part_no
where type_code in ('frame','sun')
and t1.status = 't'
and t1.routing not in ('hold','slp')
and t1.routing not like '3_%'
and t1.date_shipped between @DateFromTY and @DateToTY
AND  TYPE='I'
AND t1.tot_ord_freight=0
AND t3.PROMO_ID IN ('RXE','RX3','RX5')
--and t1.cust_code ='043161'  and promo_id like 'rx%'
GROUP BY t1.ORDER_NO, t1.EXT, t1.CUST_CODE, T1.SHIP_TO, DATE_ENTERED, t1.DATE_SHIPPED, t1.who_entered, FREIGHT_ALLOW_TYPE, ROUTING,SOLD_TO, TOTAL_AMT_ORDER, tot_ord_freight, freight_charge,
weight, ship_to_country_cd, ship_to_zip, routing, promo_id, CS_DIM_WEIGHT, freight_charge,
CASE WHEN t3.promo_level = '5' THEN 'rx5' ELSE 'rx3' end
ORDER BY DATE_ENTERED DESC
-- select * from #RXEFREIGHT


IF(OBJECT_ID('tempdb.dbo.#FinalData1') is not null)  drop table dbo.#FinalData1
SELECT Status, t1.Customer, Terr, Address_name, addr2, addr3, addr4, City, State, Postal_code, Country, contact_name, contact_phone, tlx_twx, contact_email, 
-- SALES
round(SUM(NetSTY),2) NetSTY, 
round(SUM(NetSLY),2) NetSLY, 
SUM(ListSTY)ListSTY,
SUM(ListSLY)ListSLY,
SUM(DesigNetSTY)DesigNetSTY,
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
ActiveDesignation, CurrentPrimary, PriStart, PriEnd, RTRIM(LTRIM(Parent))Parent, CustType, coop_eligible,
(select ISNULL(sum(coop_earned),0) from #coopdata T3 WHERE T1.CUSTOMER=T3.CUSTOMER_CODE AND t3.yyear = datepart(year,@DateTo)) COOP_Earned,
(select ISNULL(sum(COOP_REDEEMED),0) from #coopdata T3 WHERE T1.CUSTOMER=T3.CUSTOMER_CODE AND t3.yyear = datepart(year,@DateTo)) COOP_ReDeemed,
pastdueamt, -- ISNULL((SELECT TOP 1 (AR60+AR90+AR120+AR150) FROM SSRS_ARAging_Temp t4 where t1.customer=right(t4.cust_code,5) ),0) PastDueAmt,
(SELECT ISNULL(SUM(RetSRaTY_R12),0) FROM #R12 T2 WHERE T1.CUSTOMER=T2.CUSTOMER AND T2.Years='TY') RetSRaTY_R12, 
(SELECT ISNULL(SUM(GrossNoBepSTY_R12),0) FROM #R12 T2 WHERE T1.CUSTOMER=T2.CUSTOMER AND T2.Years='TY') GrossNoBepSTY_R12, 
(SELECT ISNULL(SUM(RetURaTY_R12),0) FROM #R12 T2 WHERE T1.CUSTOMER=T2.CUSTOMER AND T2.Years='TY') RetURaTY_R12, 
(SELECT ISNULL(SUM(GrossNoBepUTY_R12),0) FROM #R12 T2 WHERE T1.CUSTOMER=T2.CUSTOMER AND T2.Years='TY') GrossNoBepUTY_R12, 

(SELECT ISNULL(SUM(RetSRaTY_R12),0) FROM #R12 T2 WHERE T1.CUSTOMER=T2.CUSTOMER AND T2.Years='LY') RetSRaLY_R12, 
(SELECT ISNULL(SUM(GrossNoBepSTY_R12),0) FROM #R12 T2 WHERE T1.CUSTOMER=T2.CUSTOMER AND T2.Years='LY') GrossNoBepSLY_R12 


INTO #FinalData1
FROM #DATA T1
GROUP BY status, t1.customer, Terr, address_name, addr2, addr3, addr4, city, state, postal_code, country, contact_name, contact_phone, tlx_twx, contact_email, ActiveDesignation, CurrentPrimary, PriStart, PriEnd, Parent, CustType, coop_eligible, pastdueamt

-- select * from #FinalData1 where customer = '10087'    order by Customer


IF(OBJECT_ID('tempdb.dbo.#LastST2') is not null)  drop table #LastST2
select distinct right(cust_code,5)Cust,
(select TOP 1 last_st_ord_date from CVO_Carbi B where a.cust_code = b.cust_code order by last_st_ord_date)last_st_ord_date INTO #LastST2 from cvo_carbi A 
-- 13,165
IF(OBJECT_ID('tempdb.dbo.#LastST') is not null)  drop table #LastST
select distinct Cust,
(select TOP 1 last_st_ord_date from #LastST2 B where a.Cust = b.Cust order by last_st_ord_date)last_st_ord_date INTO #LastST from #LastST2 A 
-- select * from #LastST
-- 13,121

-- -- -- -- 
-- IF(OBJECT_ID('RankCustBillTo_ELBKU') is not null)  drop table RankCustBillTo_ELBKU
SELECT Status, t1.Customer, Terr, 
ISNULL((select TOP 1 salesperson_name from arsalesp AR where t1.Terr = AR.territory_code and AR.status_type=1),(Terr + ' Default')) as SLP,
Address_name, addr2, addr3, addr4, City, State, Postal_code, Country, contact_name, contact_phone, tlx_twx, contact_email, NetSTY, NetSLY, ListSTY, ListSLY, DesigNetSTY, NetSRXTY, NetSRXLY, NetSSTTY, NetSSTLY, RetSTY, RetSLY, RetSRaTY, RetSRaLY, RetSRXTY, RetSRXLY, RetSSTTY, RetSSTLY, GrossSTY, GrossSLY, GrossNoBepSTY, GrossNoBepSLY, NetUTY, NetULY, NetURXTY, NetURXLY, NetUSTTY, NetUSTLY, RetUTY, RetULY, RetURaTY, RetURaLY, RetURXTY, RetURXLY, RetUSTTY, RetUSTLY, GrossUTY, GrossULY, GrossNoBepUTY, GrossNoBepULY, RetSRaTY_R12, GrossNoBepSTY_R12, RetSRaLY_R12, GrossNoBepSLY_R12, 
RetURaTY_R12, GrossNoBepUTY_R12, ActiveDesignation, CurrentPrimary, PriStart, PriEnd, Parent, CustType, coop_eligible, COOP_Earned, COOP_ReDeemed, PastDueAmt,Interval,
ISNULL(t2.Goal1,0)Goal1,ISNULL(t2.RebatePct1,0)RebatePct1,ISNULL(goal2,0)goal2, isnull(rebatepct2,0)rebatepct2, ISNULL(goal3,0)goal3, ISNULL(rebatepct3,0)rebatepct3, ISNULL(PrimaryOnly,'')PrimaryOnly, ISNULL(CurrentlyOnly,'')CurrentlyOnly, ISNULL(RRLess,0.25)RRLess, COOPOvr,
(select TOP 1 price_code from armaster t11 (nolock) where t1.customer=right(t11.customer_code,5) and t11.address_type=0 order by right(t11.customer_code,5), status_type, t11.customer_code )PriceCode,
CASE when (select count(*) from c_quote t12 where right(customer_key,5)=Customer) > 0 THEN 'Y' else 'N' end as ContrPrcing,

Case when Goal1>DesigNetSTY THEN Goal1-DesigNetSTY
 when Goal2>DesigNetSTY THEN Goal2-DesigNetSTY
 ELSE 0 end as DolToNextRebate,
 
Case when DesigNetSTY>=Goal2 THEN DesigNetSTY * RebatePct2 
 when DesigNetSTY>=Goal1 THEN DesigNetSTY * RebatePct1
 ELSE 0 end as RebateEarned,
 
ISNULL(( select  COUNT(order_no) from #RXEFREIGHT RX WHERE t1.Customer=RX.Cust_code AND  (who_entered ='outofstock' OR ext=0) AND RxDesig='RX3'),0 )RX3NumOrds,
ISNULL(( select  SUM(UnChargedRates) from #RXEFREIGHT RX WHERE t1.Customer=RX.Cust_code AND  (who_entered ='outofstock' OR ext=0) AND RxDesig='RX3'),0 )RX3Saved,
ISNULL(( select  COUNT(order_no) from #RXEFREIGHT RX WHERE t1.Customer=RX.Cust_code AND  (who_entered ='outofstock' OR ext=0) AND RxDesig='RX5'),0 )RX5NumOrds,
ISNULL(( select  SUM(UnChargedRates) from #RXEFREIGHT RX WHERE t1.Customer=RX.Cust_code AND  (who_entered ='outofstock' OR ext=0) AND RxDesig='RX5'),0 )RX5Saved,
ISNULL(( select sum(NET) from #P3YRDATA PY WHERE t1.Customer=PY.Customer and Year = datepart(year,@PrYr1To)),0 ) PrYr1,
ISNULL(( select sum(NET) from #P3YRDATA PY WHERE t1.Customer=PY.Customer and Year = datepart(year,dateadd(year,-1,@PrYr1To)) ),0 ) PrYr2,
ISNULL(( select sum(NET) from #P3YRDATA PY WHERE t1.Customer=PY.Customer and Year = datepart(year,dateadd(year,-2,@PrYr1To)) ),0 ) PrYr3,
datepart(year,@PrYr1To) as PrYr1Name,
datepart(year,dateadd(year,-1,@PrYr1To)) as PrYr2Name,
datepart(year,dateadd(year,-2,@PrYr1To)) as PrYr3Name,
t3.last_st_ord_date
-- INTO RankCustBillTo_ELBKU
FROM #FinalData1 T1
LEFT OUTER JOIN CVO_DESIGNATION_REBATES T2 ON T1.CurrentPrimary=t2.code and ProgYear = DatePart(Year,@DateTo)
LEFT OUTER JOIN #LastSt t3 on t1.Customer=t3.Cust
ORDER BY Terr, NetSTY DESC

-- EXEC RankCustBillTo_sp '1/1/2013','3/31/2013', 'TRUE'
-- EXEC RankCustBillTo_sp '1/1/2014','3/31/2014', 'TRUE'

END



GO
GRANT EXECUTE ON  [dbo].[RankCustBillTo_sp] TO [public]
GO
