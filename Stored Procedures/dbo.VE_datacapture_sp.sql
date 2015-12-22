SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		elabarbera
-- Create date: 2/20/2013
-- Description:	Vision Expo Data Capture
-- EXEC VE_datacapture_sp
-- =============================================
CREATE PROCEDURE [dbo].[VE_datacapture_sp] 


AS
BEGIN

	SET NOCOUNT ON;

-- VISION EXPO EAST 5 YEAR TRACKER
-------- CREATED BY *Elizabeth LaBarbera*  2/6/2013

-- EAST
DECLARE @EP1From datetime
	DECLARE @EP1To datetime
DECLARE @EP2From datetime
	DECLARE @EP2To datetime
DECLARE @EP3From datetime
	DECLARE @EP3To datetime
DECLARE @EP4From datetime
	DECLARE @EP4To datetime
DECLARE @EP5From datetime
	DECLARE @EP5To datetime
-- WEST
DECLARE @WP1From datetime
	DECLARE @WP1To datetime
DECLARE @WP2From datetime
	DECLARE @WP2To datetime
DECLARE @WP3From datetime
	DECLARE @WP3To datetime
DECLARE @WP4From datetime
	DECLARE @WP4To datetime
DECLARE @WP5From datetime
	DECLARE @WP5To datetime
DECLARE @START datetime
	DECLARE @END datetime
DECLARE @JDateFrom int                                    
	DECLARE @JDateTo int

-- EAST
SET @EP1From = CASE WHEN  GETDATE() > ('3/1/' + CONVERT(VARCHAR,(DATEPART(YEAR, getdate() ))) ) THEN ('3/1/'+ CONVERT(VARCHAR,(DATEPART(YEAR, getdate() )))  ) ELSE ('3/1/'+ CONVERT(VARCHAR,(DATEPART(YEAR, DATEADD(YEAR, -1, GETDATE()) ))) ) END
SET @EP1To = DATEADD(MILLISECOND,-3,DATEADD(MONTH,5,@EP1From))
SET @EP2From = DATEADD(YEAR,-1,@EP1From)
SET @EP2To = DATEADD(YEAR,-1,@EP1To)
SET @EP3From = DATEADD(YEAR,-1,@EP2From)
SET @EP3To = DATEADD(YEAR,-1,@EP2To)
SET @EP4From = DATEADD(YEAR,-2,@EP2From)
SET @EP4To = DATEADD(YEAR,-2,@EP2To)
SET @EP5From = DATEADD(YEAR,-3,@EP2From)
SET @EP5To = DATEADD(YEAR,-3,@EP2To)
-- WEST
SET @WP1From = CASE WHEN  GETDATE() > ('8/1/' + CONVERT(VARCHAR,(DATEPART(YEAR, getdate() ))) ) THEN ('8/1/'+ CONVERT(VARCHAR,(DATEPART(YEAR, getdate() )))  ) ELSE ('8/1/'+ CONVERT(VARCHAR,(DATEPART(YEAR, DATEADD(YEAR, -1, GETDATE()) ))) ) END
SET @WP1To = DATEADD(MILLISECOND,-3,DATEADD(MONTH,6,@WP1From))
SET @WP2From = DATEADD(YEAR,-1,@WP1From)
SET @WP2To = DATEADD(YEAR,-1,@WP1To)
SET @WP3From = DATEADD(YEAR,-1,@WP2From)
SET @WP3To = DATEADD(YEAR,-1,@WP2To)
SET @WP4From = DATEADD(YEAR,-2,@WP2From)
SET @WP4To = DATEADD(YEAR,-2,@WP2To)
SET @WP5From = DATEADD(YEAR,-3,@WP2From)
SET @WP5To = DATEADD(YEAR,-3,@WP2To)

-- FULL RANGE
SET @START = CASE WHEN @WP5From < @EP5From THEN @WP5From ELSE @EP5From END
SET @END = CASE WHEN @EP1To > @WP1To THEN @EP1To ELSE @WP1To END

---- EAST PERIODS
--select @EP1From, @EP1To, @EP2From, @EP2To, @EP3From, @EP3To, @EP4From, @EP4To, @EP5From, @EP5To
---- WEST PERIODS
--select @WP1From, @WP1To, @WP2From, @WP2To, @WP3From, @WP3To, @WP4From, @WP4To, @WP5From, @WP5To
---- FULL RANGE
--SELECT @START, @END
 
-- Convert Dates to JULIAN
		set @JDATEFROM = datediff(day,'1/1/1950',convert(datetime,
		  convert(varchar( 8), (year(@START) * 10000) + (month(@START) * 100) + day(@START)))  ) + 711858

		set @JDATETO = datediff(day,'1/1/1950',convert(datetime,
		  convert(varchar( 8), (year(@END) * 10000) + (month(@END) * 100) + day(@END)))  ) + 711858
-- SELECT @Y5FR, @JDATEFROM, @Y1To, @JDATETO



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
--select @@rowcount
--select * from #Rank_Aff

-- Pull Customer#, Shipto#, Name, City, State, Zip 
IF(OBJECT_ID('tempdb.dbo.#RankCusts_S1') is not null)
drop table dbo.#RankCusts_S1
SELECT CASE WHEN T2.DOOR = 1 THEN 'Y' else '' end as Door,
t1.customer_code, ship_to_code, territory_code, Address_name, addr2, addr3, addr4, City, State, Postal_code, contact_phone, tlx_twx, contact_email  
INTO #RankCusts_S1
FROM armaster t1 (nolock)
LEFT OUTER JOIN CVO_ARMASTER_ALL T2 ON T1.CUSTOMER_CODE = T2.CUSTOMER_CODE AND T1.SHIP_TO_CODE=T2.SHIP_TO
WHERE t1.ADDRESS_TYPE <>9
-- select * from #RankCusts_S1

-- Get Designation Codes, into one field
IF(OBJECT_ID('tempdb.dbo.#RankCusts_S2A') is not null)
drop table dbo.#RankCusts_S2A
	;WITH C AS 
		( SELECT customer_code, code FROM cvo_cust_designation_codes (nolock) )
		select Distinct customer_code,
					STUFF ( ( SELECT '; ' + code 
					FROM cvo_cust_designation_codes (nolock)
					WHERE customer_code = C.customer_code
					FOR XML PATH ('') ), 1, 1, ''  ) AS NEW
	INTO #RankCusts_s2A
	FROM C
--select * from #RankCusts_S2A where customer_code='044423'

-- Add Designation to Customer Data
IF(OBJECT_ID('tempdb.dbo.#RankCusts_S2B') is not null)
drop table dbo.#RankCusts_S2B
Select T1.*, ISNULL(T2.NEW, '' ) as Designations
INTO #RankCusts_S2B
from #RankCusts_S1 t1
left outer join #RankCusts_S2A t2 on t1.customer_code=t2.customer_code
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
Select ISNULL(t2.code,'A') Status, Right(customer_code, 5) as MergeCust, T1.*
INTO #RankCusts_S3a
from #RankCusts_S2B t1
full outer join #Rank_Aff_All t2 on t1.customer_code=t2.cust
-- select * from #RankCusts_S2b where mergecust='10197'
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
-- select * from #RankCusts_S3c where status='a'
-- select distinct MergeCust, Ship_to_code from #RankCusts_S3c order by MergeCust, ship_to_code

-- CLEAN OUT EXTRA DUPLICATE 0 & 9
IF(OBJECT_ID('tempdb.dbo.#RankCusts_S3') is not null)
drop table dbo.#RankCusts_S3
select Max(ISNULL(Status,''))Status,			MergeCust, 
MAX(isnull(Door,''))Door,						MAX(isnull(customer_code,''))customer_code,		ship_to_code, 
MAX(isnull(territory_code,''))territory_code,	MAX(isnull(Address_name,''))Address_name,		MAX(isnull(addr2,''))addr2,
MAX(isnull(addr3,''))addr3,						MAX(isnull(addr4,''))addr4,	
MAX(isnull(City,''))City,						MAX(isnull(State,''))State,						MAX(isnull(Postal_code,''))Postal_code,
MAX(isnull(contact_phone,''))contact_phone,		MAX(isnull(tlx_twx,''))tlx_twx,					MAX(isnull(contact_email,''))contact_email,
MAX(isnull(Designations,''))Designations,		MAX(isnull(Parent,''))Parent
INTO #RankCusts_S3
FROM #RankCusts_S3c
group by MergeCust, Ship_to_code
order by MergeCust
-- select * from #RankCusts_S3
-- select * from #Rank_Aff where from_cust='010197'

-- Select Net Sales
IF(OBJECT_ID('tempdb.dbo.#Data') is not null)    drop table dbo.#Data
select right(customer,5)MergeCust, * into #Data from cvo_sbm_details where promo_id like 'VE%' and yyyymmdd between @Start and @End
-- select * from #Data where customer > 900000

--select * from #rankcusts_s3
--select * from #rankcusts_s4
create index[#rank_idx2] on #rankcusts_s3 (DOOR, MergeCust, ship_to_code asc)
create index[#rank_idx3] on #Data (MergeCust, ship_to asc)

-- Add Door Info to Sales Sub Table
IF(OBJECT_ID('tempdb.dbo.#SalesData') is not null)
drop table dbo.#SalesData
SELECT Door, t1.* INTO #SalesData FROM #Data t1
left outer join #RankCusts_S3 t2 on t1.MergeCust=t2.MergeCust and t1.ship_to=t2.ship_to_code
--  select * from #SalesData
--  select * from #rankcusts_s3
create index[#rank_idx4] on #SalesData (Door, MergeCust, ship_to asc)


--Customer / Ship To Sales
IF(OBJECT_ID('tempdb.dbo.#Final') is not null)
drop table dbo.#Final
select status, t2.MergeCust, t1.Door, t2.territory_code, t2.Customer_code, Ship_to_code, t2.address_name, t2.addr2, t2.addr3, t2.addr4, t2.city, t2.state, t2.postal_code, t2.contact_phone, t2.tlx_twx, LOWER(t2.contact_email)contact_email, t2.designations, t2.Parent,
ISNULL((select sum(anet) from #SalesData t11 where yyyymmdd between @EP1From and @EP1To and t11.MergeCust=t2.MergeCust and t11.ship_to=t2.ship_to_code),0) 'VEETY',
ISNULL((select sum(anet) from #SalesData t11 where yyyymmdd between @EP2From and @EP2To and t11.MergeCust=t2.MergeCust and t11.ship_to=t2.ship_to_code),0) 'VEE1YR',
ISNULL((select sum(anet) from #SalesData t11 where yyyymmdd between @EP3From and @EP3To and t11.MergeCust=t2.MergeCust and t11.ship_to=t2.ship_to_code),0) 'VEE2YR',
ISNULL((select sum(anet) from #SalesData t11 where yyyymmdd between @EP4From and @EP4To and t11.MergeCust=t2.MergeCust and t11.ship_to=t2.ship_to_code),0) 'VEE3YR',
ISNULL((select sum(anet) from #SalesData t11 where yyyymmdd between @EP5From and @EP5To and t11.MergeCust=t2.MergeCust and t11.ship_to=t2.ship_to_code),0) 'VEE4YR',
ISNULL((select sum(anet) from #SalesData t11 where yyyymmdd between @WP1From and @WP1To and t11.MergeCust=t2.MergeCust and t11.ship_to=t2.ship_to_code),0) 'VEWTY',
ISNULL((select sum(anet) from #SalesData t11 where yyyymmdd between @WP2From and @WP2To and t11.MergeCust=t2.MergeCust and t11.ship_to=t2.ship_to_code),0) 'VEW1YR',
ISNULL((select sum(anet) from #SalesData t11 where yyyymmdd between @WP3From and @WP3To and t11.MergeCust=t2.MergeCust and t11.ship_to=t2.ship_to_code),0) 'VEW2YR',
ISNULL((select sum(anet) from #SalesData t11 where yyyymmdd between @WP4From and @WP4To and t11.MergeCust=t2.MergeCust and t11.ship_to=t2.ship_to_code),0) 'VEW3YR',
ISNULL((select sum(anet) from #SalesData t11 where yyyymmdd between @WP5From and @WP5To and t11.MergeCust=t2.MergeCust and t11.ship_to=t2.ship_to_code),0) 'VEW4YR',
CONVERT(VARCHAR,(DATEPART(YEAR, @EP1From ))) as EP1Yr,
CONVERT(VARCHAR,(DATEPART(YEAR, @EP2From ))) as EP2Yr,
CONVERT(VARCHAR,(DATEPART(YEAR, @EP3From ))) as EP3Yr,
CONVERT(VARCHAR,(DATEPART(YEAR, @EP4From ))) as EP4Yr,
CONVERT(VARCHAR,(DATEPART(YEAR, @EP5From ))) as EP5Yr,
CONVERT(VARCHAR,(DATEPART(YEAR, @WP1From ))) as WP1Yr,
CONVERT(VARCHAR,(DATEPART(YEAR, @WP2From ))) as WP2Yr,
CONVERT(VARCHAR,(DATEPART(YEAR, @WP3From ))) as WP3Yr,
CONVERT(VARCHAR,(DATEPART(YEAR, @WP4From ))) as WP4Yr,
CONVERT(VARCHAR,(DATEPART(YEAR, @WP5From ))) as WP5Yr

INTO #Final
from #SalesData t1
full outer join #RankCusts_S3 t2 on t1.MergeCust=t2.MergeCust and t1.ship_to=t2.ship_to_code
group by status, t2.MergeCust, t1.Door, t2.territory_code, t2.Customer_code, t2.Ship_to_code, t2.address_name,t2.addr2, t2.addr3, t2.addr4, t2.city, t2.state, t2.postal_code, t2.contact_phone, t2.tlx_twx, t2.contact_email, t2.designations, t2.Parent
order by territory_code,sum(anet) desc

select * from #Final where (VEETY <> 0  OR VEE1YR <> 0   OR VEE2YR <> 0   OR VEE3YR <> 0   OR VEE4YR <> 0 AND
 VEWTY <> 0  OR VEW1YR <> 0   OR VEW2YR <> 0   OR VEW3YR <> 0   OR VEW4YR <> 0)
-- EXEC VE_datacapture_sp

END

GO
