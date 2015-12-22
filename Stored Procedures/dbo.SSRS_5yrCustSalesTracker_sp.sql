SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


-- =============================================
-- Author:		elabarbera
-- Create date: 2/22/2013
-- Description:	5 Year Master Customer Sales Tracker
-- =============================================
CREATE PROCEDURE [dbo].[SSRS_5yrCustSalesTracker_sp] 

-- exec SSRS_5yrCustSalesTracker_sp

AS
BEGIN
	SET NOCOUNT ON;

-- 5 Year Customer Sales Tracker
DECLARE @P1From datetime	
	DECLARE @P1To datetime	
DECLARE @P2From datetime	
	DECLARE @P2To datetime	
DECLARE @P3From datetime	
	DECLARE @P3To datetime	
DECLARE @P4From datetime	
	DECLARE @P4To datetime	
DECLARE @P5From datetime	
	DECLARE @P5To datetime	
DECLARE @P6From datetime	
	DECLARE @P6To datetime	
	
SET @P1From = DATEADD(YEAR, DATEDIFF(YEAR, 0, GETDATE()), 0)
	SET @P1To = DATEADD(MILLISECOND, -3, DATEADD(YEAR, DATEDIFF(YEAR, 0, GETDATE()) + 1, 0))
SET @P2From = DATEADD(YEAR,-1,@P1From)
	Set @P2To = DATEADD(YEAR,-1,@P1To)
SET @P3From = DATEADD(YEAR,-2,@P1From)
	Set @P3To = DATEADD(YEAR,-2,@P1To)
SET @P4From = DATEADD(YEAR,-3,@P1From)
	Set @P4To = DATEADD(YEAR,-3,@P1To)
SET @P5From = DATEADD(YEAR,-4,@P1From)
	Set @P5To = DATEADD(YEAR,-4,@P1To)
SET @P6From = DATEADD(YEAR,-5,@P1From)
	Set @P6To = DATEADD(YEAR,-5,@P1To)
-- SELECT @P1FROM, @P1TO, @P2FROM, @P2TO, @P3FROM, @P3TO, @P4FROM, @P4TO, @P5FROM, @P5TO, @P6FROM, @P6TO

IF(OBJECT_ID('tempdb.dbo.#DataPull') is not null)  
drop table #DataPull
-- select * from cvo_rad_shipto
SELECT distinct right(Customer,5) MCust, Customer, ship_to,
isnull((select sum(ANET) from CVO_CSBM_SHIPTO t11 where t1.customer=t11.customer and t1.ship_to=t11.ship_to and  yyyymmdd between @P1From and @P1To),0) as 'CY', 
isnull((select sum(ANET) from CVO_CSBM_SHIPTO t11 where t1.customer=t11.customer and t1.ship_to=t11.ship_to and  yyyymmdd between @P2From and @P2To),0) as 'PY',
isnull((select sum(ANET) from CVO_CSBM_SHIPTO t11 where t1.customer=t11.customer and t1.ship_to=t11.ship_to and  yyyymmdd between @P3From and @P3To),0) as 'PYL1',
isnull((select sum(ANET) from CVO_CSBM_SHIPTO t11 where t1.customer=t11.customer and t1.ship_to=t11.ship_to and  yyyymmdd between @P4From and @P4To),0) as 'PYL2',
isnull((select sum(ANET) from CVO_CSBM_SHIPTO t11 where t1.customer=t11.customer and t1.ship_to=t11.ship_to and  yyyymmdd between @P5From and @P5To),0) as 'PYL3',
isnull((select sum(ANET) from CVO_CSBM_SHIPTO t11 where t1.customer=t11.customer and t1.ship_to=t11.ship_to and  yyyymmdd between @P6From and @P6To),0) as 'PYL4',
Datepart(year,@P1From) as 'DCY', 
Datepart(year,@P2From) as 'DPY',
Datepart(year,@P3From) as 'DPYL1',
Datepart(year,@P4From) as 'DPYL2',
Datepart(year,@P5From) as 'DPYL3',
Datepart(year,@P6From) as 'DPYL4'
INTO #DataPull
FROM CVO_CSBM_SHIPTO (nolock) t1
order by Customer
-- select * from #DataPull

IF(OBJECT_ID('tempdb.dbo.#CustFinal') is not null)  
drop table #CustFinal
SELECT distinct MCust as Cust, ship_to,
ISNULL(sum(CY),0)CY, isnull(sum(PY),0)PY, isnull(sum(pyL1),0)'PYL1', isnull(sum(pyL2),0)'PYL2', isnull(sum(pyL3),0)'PYL3', isnull(sum(pyL4),0)'PYL4', 

case when sum(PYL3)+SUM(CY)=0 then 0 when sum(pyL3) = 0 then 1 when sum(cy) = 0 then -1 else round( ( (sum(CY) - sum(pyL3)) / sum(pyL3) ),2) end as 'CYDiff', 

case when sum(PYL3) <0 and sum(PY) = 0 then 1 when sum(PYL3)+SUM(Py)=0 then 0 when sum(pyL3) = 0 then 1 when sum(Py) = 0 then -1 else round( ( (sum(Py) - sum(pyL3)) / sum(pyL3) ),2) end as 'LYDiff', 

CASE WHEN SUM(PYL4) > SUM(PYL3) AND SUM(PYL4) > SUM(PYL2) AND SUM(PYL4) > SUM(PYL1) AND SUM(PYL4) > SUM(PY) AND SUM(PYL4) > SUM(CY) THEN SUM(PYL4) 
	WHEN SUM(PYL3) > SUM(PYL2) AND SUM(PYL3) > SUM(PYL1) AND SUM(PYL3) > SUM(PY) AND SUM(PYL3) > SUM(CY) THEN SUM(PYL3) 
	WHEN SUM(PYL2) > SUM(PYL1) AND SUM(PYL2) > SUM(PY) AND SUM(PYL2) > SUM(CY) THEN SUM(PYL2)
	WHEN SUM(PYL1) > SUM(PY)  AND SUM(PYL1) > SUM(CY) THEN SUM(PYL1)
	WHEN SUM(PY) > SUM(CY) THEN SUM(PY)  ELSE SUM(CY) END AS 'MAXYR',
DCY,DPY,DPYL1'DPYL1',DPYL2'DPYL2',DPYL3 'DPYL3', DPYL4 'DPYL4'
INTO #CustFinal FROM #DataPull 
GROUP BY MCust, ship_to, DCY,DPY,DPYL1,DPYL2,DPYL3,DPYL4
-- select * from #CustFinal

IF(OBJECT_ID('tempdb.dbo.#CustInfo') is not null)  
drop table #CustInfo
select Territory_code as Terr, right(customer_code,5)Mcust, customer_code, ship_to_code, address_name, City, State, Postal_code, Status_type, added_by_date
into #CustInfo
from armaster (nolock) t2 
where address_type<>9 
group by Territory_code, customer_code, ship_to_code, address_name, City, State, Postal_code, Status_type, added_by_date
order by added_by_date
;
WITH T AS ( SELECT ROW_NUMBER() OVER(PARTITION BY Mcust, ship_to_code ORDER BY Status_type, added_by_date )  AS rnum,*  FROM #CustInfo ) 
DELETE FROM T WHERE rnum>1
-- select * from #CustInfo where Mcust='14645'

SELECT Terr, Cust, Ship_to, round(CY,2)CY, round(PY,2)PY, round(PYL1,2)PYL1, round(PYL2,2)PYL2, round(PYL3,2)PYL3, round(PYL4,2)PYL4, round(CYDiff,2)CYDiff, round(LYDiff,2)LYDiff, round(MAXYR,2)MAXYR, DCY, DPY, DPYL1, DPYL2, DPYL3, DPYL4, address_name, City, State, Postal_code, Status_type
FROM  #CustFinal t1
JOIN #CustInfo t2 on t1.Cust=t2.MCust and t1.ship_to=t2.ship_to_code
order by terr, Cust, ship_to, CY desc, PY, PYL1

END





GO
