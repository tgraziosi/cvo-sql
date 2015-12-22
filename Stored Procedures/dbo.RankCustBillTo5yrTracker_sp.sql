SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		elabarbera
-- Create date: 2/22/2013  -- Rebuilt 8/14/2013
-- Description:	5 Year Customer BILL TO Sales Tracker
-- EXEC RankCustBillTo5yrTracker_sp
-- =============================================
CREATE PROCEDURE [dbo].[RankCustBillTo5yrTracker_sp]

AS
BEGIN
	SET NOCOUNT ON;

-- 5 Year Customer Sales Tracker
DECLARE @PTo datetime	
DECLARE @PFrom datetime	
SET @PTo = DATEADD(MILLISECOND, -2,DATEADD(YEAR, DATEDIFF(YEAR, 0, GETDATE()) + 1, 0))
SET @PFrom = DATEADD(YEAR,-6,DATEADD(YEAR, DATEDIFF(YEAR, 0, GETDATE()) + 1, 0))
--SELECT @PFrom, @PTo

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

--Add ReClassify for Affiliation 
IF(OBJECT_ID('tempdb.dbo.#Rank_Aff_All') is not null)
drop table dbo.#Rank_Aff_All
select X.* INTO #Rank_Aff_All FROM
( select from_cust AS CUST,'I' as Code from #Rank_Aff     UNION
select to_cust AS CUST,'A' Code from #Rank_Aff ) X
--SELECT * FROM #Rank_Aff_All 

-- Pull Customer INFO
IF(OBJECT_ID('tempdb.dbo.#RankCusts_S1') is not null)
drop table dbo.#RankCusts_S1
SELECT DISTINCT CASE WHEN T2.DOOR = 1 THEN 'Y' else '' end as Door, 
ISNULL((select Code from #Rank_Aff_All t11 where t1.Customer_code=t11.Cust),case when status_type = 1 then 'A' ELSE 'I' end)'Status',
right(t1.customer_code,5)MCust, t1.customer_code, ship_to_code, territory_code as Terr, Address_name, City, State, Postal_code, country_code
INTO #RankCusts_S1
FROM armaster t1 (nolock)
LEFT OUTER JOIN CVO_ARMASTER_ALL (nolock) T2 ON T1.CUSTOMER_CODE = T2.CUSTOMER_CODE AND T1.SHIP_TO_CODE=T2.SHIP_TO
LEFT OUTER JOIN #Rank_Aff_All (nolock) T3 on t1.customer_code=t3.Cust
WHERE t1.ADDRESS_TYPE =0
order by MCust, Status
-- select distinct mcust, ship_to_code from #RankCusts_S1 

-- CLEAN OUT EXTRA DUPLICATE 0 & 9
IF(OBJECT_ID('tempdb.dbo.#Custs') is not null)
drop table dbo.#Custs
select MIN(isnull(Door,''))Door,				MIN(ISNULL(Status,''))Status,			MCust, 
MIN(isnull(customer_code,''))customer_code,		
MIN(isnull(terr,''))terr,						MIN(isnull(Address_name,''))Address_name,
MIN(isnull(City,''))City,						MIN(isnull(State,''))State,				MIN(isnull(Postal_code,''))Postal_code,
MIN(isnull(Country_code,''))Country
INTO #Custs
FROM #RankCusts_S1
group by MCust
order by MCust, Status
-- select * from #Custs

-- SOURCE SALES
IF(OBJECT_ID('tempdb.dbo.#SOURCE') is not null)
drop table dbo.#SOURCE
SELECT Right(customer,5)MCust, T2.*, DATEPART(YEAR,yyyymmdd)Yr
INTO #SOURCE
FROM cvo_sbm_details (nolock) t2
JOIN INV_MASTER (NOLOCK) INV ON T2.PART_NO=INV.PART_NO
Where yyyymmdd between  @PFrom and @Pto
-- Select * from #Source

-- FINAL
IF(OBJECT_ID('tempdb.dbo.#DATA') is not null)
drop table dbo.#DATA
select distinct t2.Status, t2.Door, t2.Terr, t1.MCust as Customer, t2.address_name, City, ISNULL(State,'')State, ISNULL(Postal_code,'')Postal_Code, Country,
ISNULL((select sum(anet) from #Source t11 where t1.MCust=t11.MCust and Yr = DATEPART(YEAR,@PTo)),0)'CY',
ISNULL((select sum(anet) from #Source t11 where t1.MCust=t11.MCust and Yr = DATEPART(YEAR,@PTo)-1),0)'PY',
ISNULL((select sum(anet) from #Source t11 where t1.MCust=t11.MCust and Yr = DATEPART(YEAR,@PTo)-2),0)'PYL1',
ISNULL((select sum(anet) from #Source t11 where t1.MCust=t11.MCust and Yr = DATEPART(YEAR,@PTo)-3),0)'PYL2',
ISNULL((select sum(anet) from #Source t11 where t1.MCust=t11.MCust and Yr = DATEPART(YEAR,@PTo)-4),0)'PYL3',
ISNULL((select sum(anet) from #Source t11 where t1.MCust=t11.MCust and Yr = DATEPART(YEAR,@PTo)-5),0)'PYL4'
INTO #DATA
 from #Source t1 
 join #Custs t2 on t1.MCust=t2.MCust
group by t2.Status, t2.Door, t2.Terr, t1.MCust, t2.address_name, City, State, Postal_code, Country
--
--
IF(OBJECT_ID('tempdb.dbo.#FINAL') is not null)
drop table dbo.#FINAL
Select DISTINCT Status AS Status_type, Door, Terr, Customer, address_name, City, State, Postal_Code, Country, CY, PY, PYL1, PYL2, PYL3, PYL4,

case when sum(PYL4)+SUM(CY)=0 then 0 when sum(pyL4) = 0 then 1 when sum(cy) = 0 then -1 else round( ( (sum(CY) - sum(pyL4)) / sum(pyL4) ),2) end as 'CYDiff', 

case when sum(PYL4) <0 and sum(PY) = 0 then 1 when sum(PYL4)+SUM(Py)=0 then 0 when sum(pyL4) = 0 then 1 when sum(Py) = 0 then -1 else round( ( (sum(Py) - sum(pyL4)) / sum(pyL4) ),2) end as 'LYDiff', 

CASE WHEN SUM(PYL4) > SUM(PYL3) AND SUM(PYL4) > SUM(PYL2) AND SUM(PYL4) > SUM(PYL1) AND SUM(PYL4) > SUM(PY) AND SUM(PYL4) > SUM(CY) THEN SUM(PYL4) 
	WHEN SUM(PYL3) > SUM(PYL2) AND SUM(PYL3) > SUM(PYL1) AND SUM(PYL3) > SUM(PY) AND SUM(PYL3) > SUM(CY) THEN SUM(PYL3) 
	WHEN SUM(PYL2) > SUM(PYL1) AND SUM(PYL2) > SUM(PY) AND SUM(PYL2) > SUM(CY) THEN SUM(PYL2)
	WHEN SUM(PYL1) > SUM(PY)  AND SUM(PYL1) > SUM(CY) THEN SUM(PYL1)
	WHEN SUM(PY) > SUM(CY) THEN SUM(PY)  ELSE SUM(CY) END AS 'MAXYR',
DATEPART(YEAR,@PTo) as 'DCY', 
DATEPART(YEAR,@PTo)-1 as 'DPY',
DATEPART(YEAR,@PTo)-2 as 'DPYL1',
DATEPART(YEAR,@PTo)-3 as 'DPYL2',
DATEPART(YEAR,@PTo)-4 as 'DPYL3',
DATEPART(YEAR,@PTo)-5 as 'DPYL4'
 INTO #FINAL
 FROM #Data
 GROUP BY Status, Door, Terr, Customer,address_name, City, State, Postal_Code, Country, CY, PY, PYL1, PYL2, PYL3, PYL4
 ORDER BY Terr, Customer

select 
Status_type, Door, Terr, Customer, address_name, City, State, Postal_Code, Country, round(CY,2)CY, round(PY,2)PY, round(PYL1,2)PYL1, round(PYL2,2)PYL2, round(PYL3,2)PYL3, round(PYL4,2)PYL4, CYDiff, LYDiff, 
Case when PY+MaxYr = 0 THEN 0 WHEN PY = 0 THEN -1 WHEN MaxYr = 0 then 0 ELSE Round(((PY-MaxYr)/MaxYr),2) END AS MaxDiff, 

round(MAXYR,2)MAXYR, DCY, DPY, DPYL1, DPYL2, DPYL3, DPYL4
--INTO CVO_RankCustBillTo5yrTracker_EL
from #FINAL

-- EXEC RankCustBillTo5yrTracker_sp

END
GO
