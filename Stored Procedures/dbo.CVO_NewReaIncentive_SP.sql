SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



-- =============================================
-- Author:		Elizabeth LaBarbera
-- Create date: 12/4/2013
-- Description:	Dec 2013 New & Reactivated Account Incentive ScoreCard
-- EXEC CVO_NewReaIncentive_SP
-- =============================================
CREATE PROCEDURE [dbo].[CVO_NewReaIncentive_SP]

AS
BEGIN
	SET NOCOUNT ON;

Declare @DateFrom datetime
Declare @DateTo datetime
Set @DateFrom = '1/16/2014'
Set @DateTo = '2/28/2014'
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
FROM arsalesp Where Status_type = 1 and Territory_code not like '%00' order by Territory_code
--  select * from #SlpInfo


-- -- # STOCK ORDERS PER MONTH  
-- PULL DATA FOR ST SHIPPED ORDERS / CREDITS OVER 5PCS
IF(OBJECT_ID('tempdb.dbo.#Invoices') is not null)  
drop table #Invoices
SELECT * INTO #Invoices FROM (
--LIVE
SELECT distinct T1.TYPE, DOOR, t3.territory_code, CUST_CODE, T1.SHIP_TO, Promo_ID, user_category, t1.ORDER_NO, 
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
and DATE_SHIPPED BETWEEN DateAdd(year,-2,@DateFrom) AND @DateTo
--AND TYPE='I'
and (order_ext=0 OR t1.who_entered = 'outofstock')
and type_code in('sun','frame')
and user_category not like '%rx%'
and user_category <> 'ST-RB'
and user_category <> 'DO'
GROUP BY t3.territory_code, DOOR, CUST_CODE, T1.SHIP_TO, T5.PROMO_ID, user_category, t1.ORDER_NO, T1.STATUS, T1.TYPE, ADDED_BY_DATE, date_shipped

	UNION ALL
-- HISTORY
SELECT distinct T1.TYPE, DOOR, t3.territory_code, CUST_CODE, T1.SHIP_TO, user_def_fld3 as Promo_ID, user_category, t1.ORDER_NO, 
CASE WHEN T1.TYPE = 'I' THEN sum(ordered) ELSE sum(cr_shipped)*-1 END AS 'QTY',
CASE WHEN T1.TYPE = 'I' THEN 1 ELSE -1 END AS 'COUNT',
ADDED_BY_DATE,
case when (select Convert(DateTime, DATEDIFF(DAY, 0, date_shipped)) from orders_all t11 where t1.order_no=t11.order_no and t11.ext=0) is null then (select Convert(DateTime, DATEDIFF(DAY, 0, date_shipped)) from orders_all t11 where t1.order_no=t11.order_no and t11.ext=1) else (select Convert(DateTime, DATEDIFF(DAY, 0, date_shipped)) from orders_all t11 where t1.order_no=t11.order_no and t11.ext=0) end as date_shipped,
--case when (select date_shipped from CVO_orders_all_HIST t11 where t1.order_no=t11.order_no and t11.ext=0) is null then (select date_shipped from orders_all t11 where t1.order_no=t11.order_no and t11.ext=1) else (select date_shipped from cvo_orders_all_hist t11 where t1.order_no=t11.order_no and t11.ext=0) end as date_shipped,

CASE WHEN DATEADD(Month, 0, DATEADD(MONTH, DATEDIFF(MONTH, 0, DATEADD(MONTH, 0, (select date_shipped from cvo_orders_all_hist t11 where t1.order_no=t11.order_no and t11.ext=0))), 0)) IS NULL THEN DATEADD(Month, 0, DATEADD(MONTH, DATEDIFF(MONTH, 0, DATEADD(MONTH, 0, (select date_shipped from cvo_orders_all_hist t11 where t1.order_no=t11.order_no and t11.ext=1))), 0)) 
ELSE DATEADD(Month, 0, DATEADD(MONTH, DATEDIFF(MONTH, 0, DATEADD(MONTH, 0, (select date_shipped from cvo_orders_all_hist t11 where t1.order_no=t11.order_no and t11.ext=0))), 0)) END as Period,
month(date_shipped) as X_MONTH
FROM CVO_ORDERS_ALL_HIST (NOLOCK) T1
JOIN CVO_ORD_LIST_HIST (NOLOCK) T2 ON T1.ORDER_NO = T2.ORDER_NO AND T1.EXT=T2.ORDER_EXT
join inv_master (nolock) IV on t2.part_no=IV.part_no
JOIN ARMASTER (NOLOCK) T3 ON T1.CUST_CODE=T3.CUSTOMER_CODE AND T1.SHIP_TO=T3.SHIP_TO_CODE
JOIN CVO_ARMASTER_ALL (NOLOCK) T4 ON T1.CUST_CODE=T4.CUSTOMER_CODE AND T1.SHIP_TO=T4.SHIP_TO
where t1.status='t'
and DATE_SHIPPED BETWEEN DateAdd(year,-2,@DateFrom) AND @DateTo
--AND TYPE='I'
and order_ext=0
and type_code in('sun','frame')
and user_category not like '%rx%'
and user_category <> 'ST-RB'
and user_category <> 'DO'
GROUP BY t3.territory_code, DOOR, CUST_CODE, T1.SHIP_TO, user_def_fld3, user_category, t1.ORDER_NO, T1.STATUS, T1.TYPE, ADDED_BY_DATE, date_shipped
) AS tmp
-- select * from #Invoices where cust_code = '040764' and type='i' and 



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
-- select * from #InvStCount

-- Pull Unique Custs Orders by Month >=5pcs DETAIL
IF(OBJECT_ID('tempdb.dbo.#InvStD') is not null)  
drop table #InvStD
select distinct territory_code, cust_code, ship_to, Date_shipped, X_MONTH
INTO #InvStD
from #Invoices 
where qty>=5
and type='i'
--and date_shipped BETWEEN @DateFrom and @DateTo
group by territory_code, cust_code, ship_to, Date_shipped, X_MONTH
-- select * from #InvStD   where cust_code = '040764'



-- REACTIVATED -- -- PULL Last & 2nd Last ST Order
IF(OBJECT_ID('tempdb.dbo.#DATA') is not null)  drop table #DATA
Select Distinct t1.territory_code as Territory, t1.Customer_code, ship_to_code, T2.DOOR, added_by_date,
/*SUM(anet)NET,*/
CASE WHEN SHIP_TO_CODE='' THEN
	ISNULL((SELECT TOP 1 DATE_SHIPPED FROM #InvStD t11 WHERE T11.CUST_CODE=T1.customer_code ORDER BY DATE_SHIPPED DESC),DateAdd(year,-2,@DateFrom) )
	ELSE
	ISNULL((SELECT TOP 1 DATE_SHIPPED FROM #InvStD t11 WHERE T11.CUST_CODE=T1.customer_code AND T11.SHIP_TO=T1.SHIP_TO_CODE ORDER BY DATE_SHIPPED DESC),DateAdd(year,-2,@DateFrom) ) end AS 'LastST',

CASE WHEN SHIP_TO_CODE='' THEN 
	ISNULL((select date_shipped from (SELECT TOP 2 DATE_SHIPPED, row_number() OVER (order by DATE_SHIPPED desc) as rownum FROM #InvStD t11 WHERE T11.CUST_CODE=T1.customer_code ORDER BY DATE_SHIPPED DESC)as tbl  Where rownum = 2),DateAdd(year,-2,@DateFrom) )
	ELSE
	ISNULL((select date_shipped from (SELECT TOP 2 DATE_SHIPPED, row_number() OVER (order by DATE_SHIPPED desc) as rownum FROM #InvStD t11 WHERE T11.CUST_CODE=T1.customer_code AND T11.SHIP_TO=T1.SHIP_TO_CODE ORDER BY DATE_SHIPPED DESC)as tbl  Where rownum = 2),DateAdd(year,-2,@DateFrom) ) END AS '2ndLastST'
INTO #DATA
from armaster t1 (NOLOCK)
join cvo_armaster_all t2 (nolock) on t1.customer_code=t2.customer_code and t1.ship_to_code=t2.ship_to
/*join CVO_SBM_DETAILS t3 on t3.customer=t1.customer_code and t3.ship_to=t1.ship_to_code*/
 WHERE t1.address_type <> 9 and T2.door=1
/*AND yyyymmdd BETWEEN @DateFrom AND @DateTo*/
group by t1.territory_code, t1.customer_code, ship_to_code, t2.door, added_by_date
-- select * from #Data where Territory = '30335' and lastST > '12/16/2013' and 2ndLastST

IF(OBJECT_ID('tempdb.dbo.#DATA2') is not null)  drop table #DATA2
SELECT T1.*, 
--DATEDIFF(D,[2ndLastST],LastST)Days
CASE WHEN DATEDIFF(D,[2ndLastST],LastST) > 365 AND LastST >= @DateFrom AND added_by_date < DateAdd(year,-1,@DateFrom) -- AND YTDNET >= '250'
	THEN 'REA' ELSE '' END AS STAT,
CASE WHEN DATEDIFF(D,[2ndLastST],LastST) > 365 AND LastST >= @DateFrom AND added_by_date < DateAdd(year,-1,@DateFrom)
	THEN ISNULL(Month(LastST),1) else '' end as X_MONTH
INTO #DATA2 FROM #DATA T1 
-- select * from #Data2 where Territory = '30335' and lastST > '12/16/2013' 
-- select * from #Data2 where added_by_date >= '11/1/2013' and LastST >= '11/1/2013'



-- FINAL FOR ST COUNT & REA COUNT
IF(OBJECT_ID('tempdb.dbo.#STREAD') is not null)  drop table #STREAD
SELECT * INTO #STREAD FROM (
 select DISTINCT Territory_code as Territory, COUNT(STOrds)NumStOrds, '' NumRea from #InvStCount where stOrds <>  0 group by Territory_code, X_MONTH
 UNION ALL
 select DISTINCT Territory, '' NumStOrds, count(Door)NumRea from #Data2 where STAT='REA' Group by Territory  ) tmp
 Order by Territory
 
IF(OBJECT_ID('tempdb.dbo.#STREA') is not null)  drop table #STREA
Select distinct Territory, SUM(NumStOrds)NumStOrds, SUM(NumRea)NumRea INTO #STREA from #STREAD group by Territory
-- Select * from #STREA

SELECT T1.*,
  ISNULL((SELECT sum(NumRea) FROM #STREA T5 WHERE T1.TERR=T5.Territory),0)ReActive,
  ISNULL((SELECT Count(Customer_code) FROM #Data2 t6 WHERE LastST >= @DateFrom and STAT<>'REA'   and [2ndLastST] <= DateAdd(year,-1,@DateFrom)  and t1.terr=t6.territory),0)New  
--INTO CVO_SalesScoreCard_SSRS
FROM #SlpInfo T1

/*
SELECT * FROM #Data2 t6 WHERE LastST >= '12/16/2013' and added_by_date >= '12/16/2013'
SELECT * FROM #Data2 t6 WHERE LastST >= '12/16/2013' and STAT<>'REA'   and [2ndLastST] <= '12/16/2012'  order by added_by_date   and added_by_date >= '12/16/2013'

*/



END


GO
