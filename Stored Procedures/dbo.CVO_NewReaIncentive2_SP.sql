SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		Elizabeth LaBarbera
-- Create date: 12/4/2013
-- Description:	New & Reactivated Account Incentive ScoreCard  (by SHIPPED ) <>*<>*<>*<>*<>*<>*<>*<>*<>*<>
-- EXEC CVO_NewReaIncentive2_SP '1/1/2014','4/30/2014'
-- =============================================
CREATE PROCEDURE [dbo].[CVO_NewReaIncentive2_SP]

@DateFrom datetime,
@DateTo datetime

AS
BEGIN
	SET NOCOUNT ON;

--Declare @DateFrom datetime
--Declare @DateTo datetime
--Set @DateFrom = '1/1/2014'
--Set @DateTo = '4/30/14'
	Set @DateTo = DateAdd(Second, -1, DateAdd(D,1,@DateTo))
--  select @DateFrom, @DateTo, (dateadd(day,-1,dateadd(year,1,@DateFrom))), dateadd(year,-1,@DateFrom) , dateadd(day,-1,@DateFrom)

-- BUILD REP DATA
IF(OBJECT_ID('tempdb.dbo.#SlpInfo') is not null)  drop table dbo.#SlpInfo
SELECT dbo.calculate_Region_fn(Territory_code)Region,Territory_code as Terr, Salesperson_name as Salesperson, ISNULL(date_of_hire,'1/1/1950')date_of_hire, 
CASE WHEN date_of_hire between @DateFrom and dateadd(day,-1,dateadd(year,1,@DateFrom)) 	THEN datepart(year,dateadd(day,-1,dateadd(year,1,@DateFrom)))
	WHEN date_of_hire between dateadd(year,-1,@DateFrom) and dateadd(day,-1,@DateFrom) 	THEN datepart(year,dateadd(day,-1,@DateFrom))
	ELSE ISNULL(DATEPART(YEAR,DATE_OF_HIRE),datepart(year,dateadd(day,-1,@DateFrom))) END AS ClassOf, 
CASE WHEN date_of_hire between @DateFrom and (dateadd(day,-1,dateadd(year,1,@DateFrom))) THEN 'Newbie'
	WHEN date_of_hire between dateadd(year,-1,@DateFrom) and dateadd(day,-1,@DateFrom) THEN 'Rookie'
	WHEN Salesperson_name like '%DEFAULT%' or Salesperson_name like '%COMPANY%' THEN 'Empty' 
	WHEN date_of_hire > @DateFrom  THEN 'Newbie'
	ELSE 'VETERAN' end as Status
INTO #SlpInfo
FROM arsalesp Where Status_type = 1 and Territory_code not like '%00' and  salesperson_name <> 'Alanna Martin' order by Territory_code
--  select * from #SlpInfo


-- -- # STOCK ORDERS PER MONTH  
-- PULL DATA FOR ST SHIPPED ORDERS / CREDITS OVER 5PCS
IF(OBJECT_ID('tempdb.dbo.#Invoices') is not null)  
drop table #Invoices
SELECT * INTO #Invoices FROM (
--LIVE
SELECT distinct T1.TYPE, t1.status, DOOR, t3.territory_code, CUST_CODE, T1.SHIP_TO, Promo_ID, user_category, t1.ORDER_NO, t1.ext, 
CASE WHEN T1.TYPE = 'I' THEN sum(ordered) ELSE sum(cr_shipped)*-1 END AS 'QTY',
CASE WHEN T1.TYPE = 'I' THEN 1 ELSE -1 END AS 'COUNT',
ADDED_BY_DATE,
case when (select Convert(DateTime, DATEDIFF(DAY, 0, date_shipped)) from orders_all t11 where t1.order_no=t11.order_no and t11.ext=0) is null then (select Convert(DateTime, DATEDIFF(DAY, 0, date_shipped)) from orders_all t11 where t1.order_no=t11.order_no and t11.ext=1) else (select Convert(DateTime, DATEDIFF(DAY, 0, date_shipped)) from orders_all t11 where t1.order_no=t11.order_no and t11.ext=0) end as date_shipped,
--case when (select date_shipped from orders_all t11 where t1.order_no=t11.order_no and t11.ext=0) is null then (select date_shipped from orders_all t11 where t1.order_no=t11.order_no and t11.ext=1) else (select date_shipped from orders_all t11 where t1.order_no=t11.order_no and t11.ext=0) end as date_shipped,
CASE WHEN DATEADD(Month, 0, DATEADD(MONTH, DATEDIFF(MONTH, 0, DATEADD(MONTH, 0, (select date_shipped from orders_all t11 where t1.order_no=t11.order_no and t11.ext=0))), 0)) IS NULL THEN DATEADD(Month, 0, DATEADD(MONTH, DATEDIFF(MONTH, 0, DATEADD(MONTH, 0, (select date_shipped from orders_all t11 where t1.order_no=t11.order_no and t11.ext=1))), 0)) 
ELSE DATEADD(Month, 0, DATEADD(MONTH, DATEDIFF(MONTH, 0, DATEADD(MONTH, 0, (select date_shipped from orders_all t11 where t1.order_no=t11.order_no and t11.ext=0))), 0)) END as Period,
month(date_shipped) as X_MONTH
FROM ORDERS_ALL (NOLOCK) T1
JOIN ORD_LIST (NOLOCK) T2 ON T1.ORDER_NO = T2.ORDER_NO AND T1.EXT=T2.ORDER_EXT
join inv_master (nolock) IV on t2.part_no=IV.part_no
JOIN ARMASTER (NOLOCK) T3 ON T1.CUST_CODE=T3.CUSTOMER_CODE AND T1.SHIP_TO=T3.SHIP_TO_CODE
JOIN CVO_ARMASTER_ALL (NOLOCK) T4 ON T1.CUST_CODE=T4.CUSTOMER_CODE AND T1.SHIP_TO=T4.SHIP_TO
JOIN cvo_orders_all (NOLOCK) T5 ON T1.ORDER_NO = T5.ORDER_NO AND T1.EXT=T5.EXT
where t1.status not in ('t','v')
and date_shipped BETWEEN Dateadd(year,-2,@DateFrom) AND @DateTo
AND TYPE='I'
and (order_ext=0 OR t1.who_entered = 'outofstock')
and type_code in('sun','frame')
and user_category not like '%rx%'
and user_category <> 'ST-RB'
and user_category <> 'DO'
GROUP BY t3.territory_code, DOOR, CUST_CODE, T1.SHIP_TO, T5.PROMO_ID, user_category, t1.ORDER_NO, t1.ext, T1.STATUS, T1.TYPE, ADDED_BY_DATE, date_shipped

UNION ALL

SELECT distinct T1.TYPE, t1.status, DOOR, t3.territory_code, CUST_CODE, T1.SHIP_TO, Promo_ID, user_category, t1.ORDER_NO, t1.ext, 
CASE WHEN T1.TYPE = 'I' THEN sum(ordered) ELSE sum(cr_shipped)*-1 END AS 'QTY',
CASE WHEN T1.TYPE = 'I' THEN 1 ELSE -1 END AS 'COUNT',
ADDED_BY_DATE,
case when (select Convert(DateTime, DATEDIFF(DAY, 0, date_shipped)) from orders_all t11 where t1.order_no=t11.order_no and t11.ext=0) is null then (select Convert(DateTime, DATEDIFF(DAY, 0, date_shipped)) from orders_all t11 where t1.order_no=t11.order_no and t11.ext=1) else (select Convert(DateTime, DATEDIFF(DAY, 0, date_shipped)) from orders_all t11 where t1.order_no=t11.order_no and t11.ext=0) end as date_shipped,
--case when (select date_shipped from orders_all t11 where t1.order_no=t11.order_no and t11.ext=0) is null then (select date_shipped from orders_all t11 where t1.order_no=t11.order_no and t11.ext=1) else (select date_shipped from orders_all t11 where t1.order_no=t11.order_no and t11.ext=0) end as date_shipped,
CASE WHEN DATEADD(Month, 0, DATEADD(MONTH, DATEDIFF(MONTH, 0, DATEADD(MONTH, 0, (select date_shipped from orders_all t11 where t1.order_no=t11.order_no and t11.ext=0))), 0)) IS NULL THEN DATEADD(Month, 0, DATEADD(MONTH, DATEDIFF(MONTH, 0, DATEADD(MONTH, 0, (select date_shipped from orders_all t11 where t1.order_no=t11.order_no and t11.ext=1))), 0)) 
ELSE DATEADD(Month, 0, DATEADD(MONTH, DATEDIFF(MONTH, 0, DATEADD(MONTH, 0, (select date_shipped from orders_all t11 where t1.order_no=t11.order_no and t11.ext=0))), 0)) END as Period,
month(date_shipped) as X_MONTH
FROM ORDERS_ALL (NOLOCK) T1
JOIN ORD_LIST (NOLOCK) T2 ON T1.ORDER_NO = T2.ORDER_NO AND T1.EXT=T2.ORDER_EXT
join inv_master (nolock) IV on t2.part_no=IV.part_no
JOIN ARMASTER (NOLOCK) T3 ON T1.CUST_CODE=T3.CUSTOMER_CODE AND T1.SHIP_TO=T3.SHIP_TO_CODE
JOIN CVO_ARMASTER_ALL (NOLOCK) T4 ON T1.CUST_CODE=T4.CUSTOMER_CODE AND T1.SHIP_TO=T4.SHIP_TO
JOIN cvo_orders_all (NOLOCK) T5 ON T1.ORDER_NO = T5.ORDER_NO AND T1.EXT=T5.EXT
where t1.status='t'
and date_shipped BETWEEN Dateadd(year,-2,@DateFrom) AND @DateTo
AND TYPE='I'
and (order_ext=0 OR t1.who_entered = 'outofstock')
and type_code in('sun','frame')
and user_category not like '%rx%'
and user_category <> 'ST-RB'
and user_category <> 'DO'
GROUP BY t3.territory_code, DOOR, CUST_CODE, T1.SHIP_TO, T5.PROMO_ID, user_category, t1.ORDER_NO, t1.ext, T1.STATUS, T1.TYPE, ADDED_BY_DATE, date_shipped
) AS tmp
-- select * from #Invoices   where cust_code = '012845' and type='i' and 
--2041078

-- Pull Unique Custs Orders by Month >=5pcs
IF(OBJECT_ID('tempdb.dbo.#InvStCount') is not null)  
drop table #InvStCount
select distinct territory_code, cust_code, sum(count) STOrds, X_MONTH
INTO #InvStCount
from #Invoices 
where qty>=5
and date_shipped BETWEEN @DateFrom and @DateTo
group by territory_code, cust_code, X_MONTH
having sum(count) >0
--order by territory_code, X_Month, cust_code
-- select * from #InvStCount order by territory_code, cust_code

-- Pull Unique Custs Orders by Month >=5pcs DETAIL
IF(OBJECT_ID('tempdb.dbo.#InvStD') is not null)  
drop table #InvStD
select distinct territory_code, cust_code, ship_to, date_shipped, X_MONTH
INTO #InvStD
from #Invoices 
where qty>=5
and type='i'
--and date_shipped BETWEEN @DateFrom and @DateTo
group by territory_code, cust_code, ship_to, date_shipped, X_MONTH
-- select * from #InvStD   where cust_code = '930896'

-- REACTIVATED -- -- PULL Last & 2nd Last ST Order
IF(OBJECT_ID('tempdb.dbo.#DATA') is not null)  drop table #DATA
Select Distinct t1.territory_code as Territory, t1.Customer_code, ship_to_code, T2.DOOR, added_by_date,
SUM(NETSALES)YTDNET,
CASE WHEN SHIP_TO_CODE='' THEN
	ISNULL((SELECT TOP 1 DATE_SHIPPED FROM #INVOICES t11 WHERE Type='i' and QTY >=5 AND T11.CUST_CODE=T1.customer_code ORDER BY DATE_SHIPPED DESC),'1/1/2000' )
	ELSE
	ISNULL((SELECT TOP 1 DATE_SHIPPED FROM #INVOICES t11 WHERE Type='i' and QTY >=5 AND T11.CUST_CODE=T1.customer_code AND T11.SHIP_TO=T1.SHIP_TO_CODE ORDER BY DATE_SHIPPED DESC),'1/1/2000' ) end AS 'LastST',

CASE WHEN SHIP_TO_CODE='' THEN 
	ISNULL((select date_shipped from (SELECT TOP 1 DATE_SHIPPED, row_number() OVER (order by DATE_SHIPPED desc) as rownum FROM #INVOICES t11 WHERE Type='i' and date_shipped < @DateFrom and QTY >=5 AND T11.CUST_CODE=T1.customer_code ORDER BY DATE_SHIPPED DESC)as tbl  Where rownum = 1),'1/1/2000' )
	ELSE
	ISNULL((select date_shipped from (SELECT TOP 1 DATE_SHIPPED, row_number() OVER (order by DATE_SHIPPED desc) as rownum FROM #INVOICES t11 WHERE Type='i' and date_shipped < @DateFrom and QTY >=5 AND T11.CUST_CODE=T1.customer_code AND T11.SHIP_TO=T1.SHIP_TO_CODE ORDER BY DATE_SHIPPED DESC)as tbl  Where rownum = 1),'1/1/2000' ) END AS '2ndLastST'
INTO #DATA
from armaster t1 (NOLOCK)
join cvo_armaster_all t2 (nolock) on t1.customer_code=t2.customer_code and t1.ship_to_code=t2.ship_to
join cvo_rad_shipto t3 on right(t3.customer,5)=right(t1.customer_code,5) and t3.ship_to=t1.ship_to_code
 WHERE t1.address_type <> 9 and T2.door=1
AND yyyymmdd BETWEEN @DateFrom AND @DateTo
group by t1.territory_code, t1.customer_code, ship_to_code, t2.door, added_by_date
--  select * from #Data order by territory, customer_code

IF(OBJECT_ID('tempdb.dbo.#DATA2') is not null)  drop table #DATA2
SELECT T1.*, 
CASE WHEN DATEDIFF(D,[2ndLastST],LastST) > 365 AND LastST > @DateFrom AND added_by_date < @DateFrom  AND [2ndLastST] <> '1/1/2000'  --DateAdd(year,-1,[2ndLastST]) --AND YTDNET >= '250'
	THEN 'REA' ELSE '' END AS STAT,
CASE WHEN DATEDIFF(D,[2ndLastST],LastST) > 365 AND LastST > @DateFrom AND added_by_date < @DateFrom  --DateAdd(year,-1,[2ndLastST])
	THEN ISNULL(Month(LastST),1) else '' end as X_MONTH
INTO #DATA2 FROM #DATA T1 
--  select * from #Data where customer_code like '030896'
-- select * from #Data2 where STAT='REA'

IF(OBJECT_ID('tempdb.dbo.#DATA3') is not null)  drop table #DATA3
select t2.*, t1.* INTO #DATA3 FROM (
SELECT Territory, Customer_code, ship_to_code, Case when Door=1 then 'Y' else '' end as Door, added_by_date, YTDNET, LastST, [2ndLastST], 'REA' as StatusType FROM  #Data2 T5 where Door='1' and STAT='REA'  
UNION ALL
SELECT Territory, Customer_code, ship_to_code, Case when Door=1 then 'Y' else '' end as Door, added_by_date, YTDNET, LastST, [2ndLastST], 'NEW' as StatusType FROM #Data2 t5 
WHERE   (added_by_date >= @DateFrom and LastST >= @DateFrom ) OR (LastST >= @DateFrom  and [2ndLastST] = '1/1/2000')
  ) t1
  FULL OUTER join #SlpInfo t2 on t1.Territory=t2.Terr

 select * from #DATA3 where Terr is not null order by Terr

-- EXEC CVO_NewReaIncentive2_SP '1/1/2014','4/30/2014'

END
GO
