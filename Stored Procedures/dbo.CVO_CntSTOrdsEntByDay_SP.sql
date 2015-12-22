SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO





-- =============================================
-- Author:		<elabarbera>
-- Create date: <9/24/2013>
-- Description:	<Count Entered Original ST Orders & Units by Day for Date Range>
-- EXEC CVO_CntSTOrdsEntByDay_SP '9/30/2013','10/6/2013'
-- =============================================
CREATE PROCEDURE [dbo].[CVO_CntSTOrdsEntByDay_SP]

@DateFrom Datetime,
@DateTo Datetime

AS
BEGIN
	SET NOCOUNT ON;

	--DECLARE @DateFrom datetime                                    
	--DECLARE @DateTo datetime		
	--SET @DateFrom = '10/14/2013'
	--SET @DateTo = '10/20/2013'
				SET @dateTo=dateadd(second,-1,@dateTo)
				SET @dateTo=dateadd(day,1,@dateTo)
		DECLARE @DateFromMTD datetime                                    
		DECLARE @DateToMTD datetime
		SET @DateFromMTD = DATEADD(month, DATEDIFF(month, 0, @DateTo), 0)
		SET @DateToMTD = DATEADD(MINUTE,-1,DATEADD(MONTH,1,DATEADD(month, DATEDIFF(month, 0, @DateTo), 0)))
-- select @DateFrom, @DateTo, @DateFromMTD, @DateToMTD

IF(OBJECT_ID('tempdb.dbo.#OrdersDet') is not null)  
drop table #OrdersDet  
select ship_to_region, Cust_code, convert(varchar(10),date_entered,101) date_entered, t1.order_no, user_category, who_entered, total_amt_order,
	isnull((select sum(ordered) from ord_list t11 join inv_master t12 on t11.part_no=t12.part_no 
		where t1.order_no=t11.order_no 	and t12.type_code in ('frame','sun') and t11.order_ext=0),0) as UnitCount,
Promo_id, Promo_Level
INTO #OrdersDet
 from orders_all (NOLOCK) t1
 join cvo_orders_all (nolock) t2 on t1.order_no=t2.order_no and t1.ext=t2.ext
where t1.ext=0
and user_category like 'st%'
and right(user_category,2) not in ('RB','TB','PM','FR') 
and Promo_id not in ('pc')
and status<>'v'
and void ='n'
and type='i'
and total_amt_order<>0
and date_entered between @DateFrom and @DateTo
-- select * from #ordersDet WHERE promo_id<>'' and UnitCount <5

IF(OBJECT_ID('tempdb.dbo.#OrdersDetMTD') is not null)  
drop table #OrdersDetMTD
select ship_to_region, Cust_code, convert(varchar(10),date_entered,101) date_entered, t1.order_no, user_category, who_entered, total_amt_order,
	isnull((select sum(ordered) from ord_list t11 join inv_master t12 on t11.part_no=t12.part_no 
		where t1.order_no=t11.order_no 	and t12.type_code in ('frame','sun') and t11.order_ext=0),0) as UnitCount,
Promo_id, Promo_Level
INTO #OrdersDetMTD
 from orders_all (NOLOCK) t1
 join cvo_orders_all (nolock) t2 on t1.order_no=t2.order_no and t1.ext=t2.ext
where t1.ext=0
and user_category like 'st%'
and right(user_category,2) not in ('RB','TB','PM','FR') 
and Promo_id not in ('pc')
and status<>'v'
and void ='n'
and type='i'
and total_amt_order<>0
and date_entered between @DateFromMTD and @DateToMTD
-- select * from #OrdersDetMTD where user_category='ST-SA'

IF(OBJECT_ID('tempdb.dbo.#TerrList') is not null)  
drop table #TerrList
SELECT DISTINCT TERRITORY_CODE as Terr into #TerrList FROM ARMASTER (NOLOCK) where territory_code is not null Order by Territory_code
-- select * from #TerrList

IF(OBJECT_ID('tempdb.dbo.#UniqueVisits') is not null)  
drop table #UniqueVisits
select distinct ISNULL(Date_entered,CONVERT(VARCHAR(10), @DateFrom, 101))Date_Entered, left(Terr,3)as 'Reg', Terr, Cust_code as Customer 
INTO #UniqueVisits
FROM #OrdersDet t1
FULL OUTER JOIN #TerrList T2 ON T1.ship_to_region=T2.Terr
--WHERE UnitCount >=5
group by date_entered, Terr, ship_to_region, Cust_code
order by date_entered desc, Terr, Cust_code
-- select * from #UniqueVisits   where Terr='30306' and date_entered='09/30/2013'

IF(OBJECT_ID('tempdb.dbo.#UniqueVisitsMTD') is not null)  
drop table #UniqueVisitsMTD
select distinct ISNULL(Date_entered,CONVERT(VARCHAR(10), @DateFrom, 101))Date_Entered, left(Terr,3)as 'Reg', convert(varchar(10),t2.Terr,101)Terr, Cust_code as Customer 
INTO #UniqueVisitsMTD
FROM #OrdersDetMTD t1
FULL OUTER JOIN #TerrList T2 ON T1.ship_to_region=T2.Terr
--WHERE UnitCount >=5
group by date_entered, Terr, ship_to_region, Cust_code
order by date_entered desc, Terr, Cust_code
-- select * from #UniqueVisitsMTD

IF(OBJECT_ID('tempdb.dbo.#D') is not null)  
drop table #D
select date_entered, reg, terr, Count(Customer) UniqueVisits
into #D
from #UniqueVisits t1
group by date_entered, reg, terr

IF(OBJECT_ID('tempdb.dbo.#DMTD') is not null)  
drop table #DMTD
select date_entered, reg, terr, Count(Customer) UniqueVisits
into #DMTD
from #UniqueVisitsMTD t1
group by date_entered, reg, terr
-- select * from #D
-- select * from #DMTD

IF(OBJECT_ID('tempdb.dbo.#E') is not null)  
drop table #E
select ISNULL(Date_entered,convert(varchar(10),@DateFrom,101))Date_entered, ISNULL(Reg,left(t2.Terr,3))Reg, T2.Terr, ISNULL(UniqueVisits,0)UniqueVisits,
(select count(order_no) from #OrdersDet t2 where unitCount>=5 and t1.date_entered=t2.date_entered and t1.terr=t2.ship_to_region) NumOrders,
(select isnull(CAST(sum(UnitCount)as decimal(20,0) ),0) from #OrdersDet t2 where unitCount>=5 and t1.date_entered=t2.date_entered and t1.terr=t2.ship_to_region) UnitCount,
(select count(promo_ID) from #OrdersDet t2 where promo_id <> '' and unitCount>=5 and t1.date_entered=t2.date_entered and t1.terr=t2.ship_to_region) Programs,
(select count(order_no) from #OrdersDet t2 where unitCount<5 and t1.date_entered=t2.date_entered and t1.terr=t2.ship_to_region) NumOrdLess5Units
INTO #E
 from #TerrList T2
 LEFT OUTER JOIN #D t1 on t2.Terr=T1.Terr
 
IF(OBJECT_ID('tempdb.dbo.#EMTD') is not null)  
drop table #EMTD
select 'MTD' as Date_entered, ISNULL(Reg,left(t2.Terr,3))Reg, convert(varchar(10),t2.Terr,101)Terr,  ISNULL(UniqueVisits,0)UniqueVisits,
(select count(order_no) from #OrdersDetMTD t2 where unitCount>=5 and t1.date_entered=t2.date_entered and t1.terr=t2.ship_to_region) NumOrders,
(select isnull(CAST(sum(UnitCount)as decimal(20,0) ),0) from #OrdersDetMTD t2 where unitCount>=5 and t1.date_entered=t2.date_entered and t1.terr=t2.ship_to_region) UnitCount,
(select count(promo_ID) from #OrdersDetMTD t2 where promo_id <> '' and unitCount>=5 and t1.date_entered=t2.date_entered and t1.terr=t2.ship_to_region) Programs,
(select count(order_no) from #OrdersDetMTD t2 where unitCount<5 and t1.date_entered=t2.date_entered and t1.terr=t2.ship_to_region) NumOrdLess5Units
INTO #EMTD
 from #TerrList T2
 LEFT OUTER JOIN #DMTD t1 on t2.Terr=T1.Terr
 
-- pull all dates in week
IF(OBJECT_ID('tempdb.dbo.#alldates') is not null)  
drop table #alldates
;with #alldates as
(  select @DateFrom DateVal
union
all
select DateVal + 1
from #alldates
where DateVal + 1 <= @DateTo  )
--select DateVal from #alldates;

-- -- FINAL
--select * into cvo_stord_eltest from (
select * from #E
  UNION ALL
select * from #EMTD
  UNION ALL
select convert(varchar(10),DateVal,101) date_entered, '202' as Reg, '20201' as Terr, 0 as UniqueVisits, 0 as NumOrders, 0 as UnitCount, 0 as Programs, 0 as NumOrdLess5Units
  from #alldates  -- ) tmp
order by Date_entered, Terr


END



GO
