SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		Tine Graziosi
-- Create date: 11/6/2014
-- Description:	New & Reactivated Customer
--   based on cvo_newreaincentive3_sp, but use for a specific customer to check
-- EXEC CVO_NewReaCust_SP 
-- insert into cvo_new_reactive_temp1 
-- EXEC  CVO_NewReaCust_SP '044641'
-- =============================================

CREATE PROCEDURE [dbo].[CVO_NewReaCust_SP]
@Customer varchar(12) ,
@ShipTo varchar(8) = '',
@DateFrom datetime  = null ,
@DateTo datetime  = null 

AS
BEGIN
	SET NOCOUNT ON;

--Declare @DateFrom datetime
--Declare @DateTo datetime
--declare @customer varchar(12)
--declare @shipto varchar(8)
--set @customer='044641'
--set @shipto = ''
--Set @DateFrom = '11/1/2013' 
--Set @DateTo = '10/27/2014'

if @datefrom is null select @datefrom = dateadd(dd,-1,dateadd(year,-1,datediff(dd,0,getdate()))) -- year - 1
if @dateto is null select @dateto = dateadd(dd,-1,datediff(dd,0,getdate())) -- today


Set @DateTo = DateAdd(Second, -1, DateAdd(D,1,@DateTo))
--  select @DateFrom, @DateTo, (dateadd(day,-1,dateadd(year,1,@DateFrom))), dateadd(year,-1,@DateFrom) , dateadd(day,-1,@DateFrom)

-- -- # STOCK ORDERS PER MONTH  
-- PULL DATA FOR ST SHIPPED ORDERS / CREDITS OVER 5PCS
IF(OBJECT_ID('tempdb.dbo.#Invoices') is not null)  
drop table #Invoices

SELECT o.TYPE, o.status, car.DOOR, ar.territory_code, o.CUST_CODE, o.SHIP_TO, 
co.Promo_ID, o.user_category, o.ORDER_NO, o.ext, 
CASE WHEN o.TYPE = 'I' THEN sum(ordered) ELSE sum(cr_shipped)*-1 END AS QTY,
CASE WHEN o.TYPE = 'I' THEN 1 ELSE -1 END AS cnt,
ADDED_BY_DATE,
dateadd(day, datediff(day,0, o.date_shipped), 0) date_shipped,
dateadd(mm, datediff(month, 0 , o.date_shipped), 0) period, 
month(date_shipped) as X_MONTH

into #invoices

FROM ORDERS_ALL (NOLOCK) o
JOIN ORD_LIST (NOLOCK) ol ON o.ORDER_NO = ol.ORDER_NO AND o.EXT=ol.ORDER_EXT
join inv_master (nolock) i on ol.part_no=i.part_no
JOIN ARMASTER (NOLOCK) ar ON o.CUST_CODE=ar.CUSTOMER_CODE AND o.SHIP_TO=ar.SHIP_TO_CODE
JOIN CVO_ARMASTER_ALL (NOLOCK) car ON o.CUST_CODE=car.CUSTOMER_CODE AND o.SHIP_TO=car.SHIP_TO
JOIN cvo_orders_all (NOLOCK) co ON o.ORDER_NO = co.ORDER_NO AND o.EXT=co.EXT
where o.status='t' and date_shipped <= @DateTo
AND TYPE='I' and o.who_entered <> 'backordr'
and type_code in('sun','frame') and user_category not like '%rx%' and user_category not in ('ST-RB','DO')
and ar.customer_code = @customer and ar.ship_to_code = @shipto
GROUP BY ar.territory_code, DOOR, CUST_CODE, o.SHIP_TO, co.PROMO_ID,
 user_category, o.ORDER_NO, o.ext, o.STATUS, o.TYPE, ADDED_BY_DATE, date_shipped

-- REACTIVATED -- -- PULL Last & 2nd Last ST Order
IF(OBJECT_ID('tempdb.dbo.#DATA') is not null)  drop table #DATA
Select ar.territory_code as Territory, ar.Customer_code, ship_to_code, car.DOOR, added_by_date,

-- tag  -- Find the first ST qualified in the reporting period, and the previous one.  
-- Then find the difference between the two to see if it's going to be a new or reactivated customer.

[FirstST_new] = 	(SELECT TOP 1 DATE_SHIPPED FROM #INVOICES t11 
		WHERE Type='i' and QTY >=5 AND T11.CUST_CODE=ar.customer_code AND T11.SHIP_TO=ar.SHIP_TO_CODE 
		and date_shipped >= @datefrom ORDER BY DATE_SHIPPED asc) ,
[LastST] = 
	(SELECT TOP 1 DATE_SHIPPED FROM #INVOICES t11 
		WHERE Type='i' and QTY >=5 AND T11.CUST_CODE=ar.customer_code AND T11.SHIP_TO=ar.SHIP_TO_CODE 
		ORDER BY DATE_SHIPPED DESC) ,
[PrevST_new] = 
	(select date_shipped from (SELECT TOP 1 DATE_SHIPPED, 
		row_number() OVER (order by DATE_SHIPPED desc) as rownum 
		FROM #INVOICES t11 WHERE Type='i' and date_shipped < 
		( select top 1 date_shipped from #invoices inv where type = 'i' and qty >=5 
			and inv.cust_code = ar.customer_code and inv.ship_to = ar.ship_to_code
			and date_shipped >= @datefrom
				order by date_shipped asc)
		 and QTY >=5 AND 
		T11.CUST_CODE=ar.customer_code AND T11.SHIP_TO=ar.SHIP_TO_CODE 
		ORDER BY DATE_SHIPPED DESC) as tbl  Where rownum = 1),
[2ndLastST] = 
	(select date_shipped from (SELECT TOP 1 DATE_SHIPPED, 
		row_number() OVER (order by DATE_SHIPPED desc) as rownum 
		FROM #INVOICES t11 WHERE Type='i' and date_shipped < @DateFrom and QTY >=5 AND 
		T11.CUST_CODE=ar.customer_code AND T11.SHIP_TO=ar.SHIP_TO_CODE 
		ORDER BY DATE_SHIPPED DESC)as tbl  Where rownum = 1)
INTO #DATA
from armaster ar (NOLOCK)
join cvo_armaster_all car (nolock) on ar.customer_code=car.customer_code and ar.ship_to_code=car.ship_to
 WHERE ar.address_type <> 9 and car.door=1
and ar.customer_code = @customer and ar.ship_to_code = @shipto
group by ar.territory_code, ar.customer_code, ar.ship_to_code, car.door, ar.added_by_date
--  select * from #Data where customer_code = '047859' order by territory, customer_code 

IF(OBJECT_ID('tempdb.dbo.#DATA2') is not null)  drop table #DATA2
SELECT T1.*, 
CASE WHEN DATEDIFF(D,[PrevSt_new],FirstSt_new) > 365 AND FirstSt_new > @DateFrom 
			AND added_by_date < @DateFrom  AND isnull([PrevSt_new],0) <> 0  
	 THEN 'REA' 
	 when (added_by_date >= @DateFrom and firstst_new >= @DateFrom ) 
		OR (firstst_new >= @DateFrom  and isnull(prevst_new,0) = 0)
	 then 'NEW'
	 ELSE '' END AS STAT_new,
CASE WHEN DATEDIFF(D,[prevst_new],firstst_new) > 365 AND Firstst_new > @DateFrom 
			AND added_by_date < @DateFrom  
	 THEN ISNULL(Month(prevst_new),1) 
	 else '' end as X_MONTH_new
INTO #DATA2 FROM #DATA T1 
--  select * from #Data2 where customer_code like '047859'
-- select * from #Data2 where STAT='REA'

select stat_new status_Type,
 customer_code, 
 ship_to_code,
 firstst_new,
 prevst_new
from #data2


END
GO
GRANT EXECUTE ON  [dbo].[CVO_NewReaCust_SP] TO [public]
GO
