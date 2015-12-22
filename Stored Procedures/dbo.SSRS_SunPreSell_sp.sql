SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


-- =============================================
-- Author:		elabarbera
-- Create date: 2/20/2013
-- Description:	Sun Presell 5 Yr Tracker
-- exec SSRS_SunPreSell_sp
-- =============================================

CREATE PROCEDURE [dbo].[SSRS_SunPreSell_sp] 
	
AS
BEGIN

	SET NOCOUNT ON;

-- SUN PRESELL 5 year Customer Tracker
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

-- Orders Entered
SET @P1From = CASE WHEN  GETDATE() > ('9/1/' + CONVERT(VARCHAR,(DATEPART(YEAR, getdate() ))) ) THEN ('9/1/'+ CONVERT(VARCHAR,(DATEPART(YEAR, getdate() )))  ) ELSE ('9/1/'+ CONVERT(VARCHAR,(DATEPART(YEAR, DATEADD(YEAR, -1, GETDATE()) ))) ) END
SET @P1To = DATEADD(MILLISECOND, -3, DATEADD(YEAR,1, @P1From))

  -- Invoices Shipped
SET @P2From = DATEADD(YEAR, DATEDIFF(YEAR, 0,DATEADD(YEAR, 0, @P1From)), 0)
SET @P2To = DATEADD(MILLISECOND, -3, DATEADD(YEAR, DATEDIFF(YEAR, 0, DATEADD(YEAR, 0, @P1From)) + 1, 0))
SET @P3From = DATEADD(YEAR,-1,@P2From)
SET @P3To = DATEADD(YEAR,-1,@P2To)
SET @P4From = DATEADD(YEAR,-2,@P2From)
SET @P4To = DATEADD(YEAR,-2,@P2To)
SET @P5From = DATEADD(YEAR,-3,@P2From)
SET @P5To = DATEADD(YEAR,-3,@P2To)
-- select @P1From, @P1To, @P2From, @P2To, @P3From, @P3To, @P4From, @P4To, @P5From, @P5To

-- -- --  select * from inv_master
-- -- --
IF(OBJECT_ID('tempdb.dbo.#sunps1') is not null)  
drop table #sunps1
	SELECT * INTO #sunps1 FROM (
-- HISTORY INVOICES
select cust_code, t1.ship_to, type, t1.order_no, invoice_no, date_entered, date_shipped, upper(user_def_fld3) as Promo_id, user_def_fld9 as Promo_level, 
CASE WHEN TYPE = 'C' THEN 0 ELSE sum(ordered) END AS OrdQty, sum(shipped) ShipQty, sum(CR_Shipped) CRQty,
CASE WHEN TYPE = 'I' THEN 1 ELSE -1 END AS 'Cnt' 
from cvo_orders_all_hist (NOLOCK) t1
join cvo_ord_list_hist  (NOLOCK) t2 on t1.order_no=t2.order_no and t1.ext=t2.order_ext
JOIN INV_MASTER (NOLOCK) T3 ON T2.PART_NO=T3.PART_NO
where t1.status <> 'v'
and user_def_fld3 like '%SUNPS%'
and t1.ext='0'
and t3.type_code in('frame','sun')
and date_shipped between @P5From and @P2To
and t3.type_code ='sun'
group by  cust_code, t1.ship_to, type, t1.order_no, invoice_no, date_entered, date_shipped, user_def_fld3, user_def_fld9
	UNION ALL
-- LIVE INVOICES
select cust_code, t1.ship_to, type, t1.order_no, CAST(invoice_no AS NVARCHAR), date_entered, date_shipped, upper(Promo_id), Promo_level, sum(ordered) OrdQty, sum(shipped) ShipQty, sum(CR_Shipped) CRQty,
CASE WHEN TYPE = 'I' THEN 1 ELSE -1 END AS 'Cnt' 
from orders_all  (NOLOCK) t1
join ord_list  (NOLOCK) t2 on t1.order_no=t2.order_no and t1.ext=t2.order_ext
join cvo_orders_all  (NOLOCK) t3 on t1.order_no=t3.order_no and t1.ext=t3.ext
JOIN INV_MASTER (NOLOCK) T4 ON T2.PART_NO=T4.PART_NO
where t1.status <> 'v'
and promo_id like '%SUNPS%'
and (t1.ext='0' OR (t1.ext='1' and t1.who_entered='OutOfStock'))
and t4.type_code in('frame','sun')
and date_shipped between @P5From and @P2To
and t4.type_code ='sun'
group by  cust_code, t1.ship_to, type, t1.order_no, invoice_no, date_entered, date_shipped, Promo_id, Promo_level
) tmp
-- select * from #sunps1

IF(OBJECT_ID('tempdb.dbo.#sunps2') is not null)  
drop table #sunps2
-- Current Year Open Orders
select T4.TERRITORY_CODE AS Terr, cust_code, t1.ship_to, type, t1.order_no, CAST(invoice_no AS NVARCHAR) invoice_no, date_entered, date_shipped, upper(Promo_id)Promo_id, Promo_level, sum(ordered) OrdQty, sum(shipped) ShipQty, sum(CR_Shipped) CRQty,
CASE WHEN TYPE = 'I' THEN 1 ELSE -1 END AS 'Cnt' 
into #sunps2
from orders_all  (NOLOCK) t1
join ord_list  (NOLOCK) t2 on t1.order_no=t2.order_no and t1.ext=t2.order_ext
join cvo_orders_all  (NOLOCK) t3 on t1.order_no=t3.order_no and t1.ext=t3.ext
JOIN ARMASTER  (NOLOCK) T4 ON T1.CUST_CODE=T4.CUSTOMER_CODE AND T1.SHIP_TO=T4.SHIP_TO_CODE
JOIN inv_master (nolock) t5 on t2.part_no=t5.part_no
where t1.status <> 'v'
and promo_id like '%SUNPS%'
and (t1.ext='0' OR (t1.ext='1' and t1.who_entered='OutOfStock'))
and date_entered between @P1From and @P1To
and type_code ='sun'
group by  T4.TERRITORY_CODE, cust_code, t1.ship_to, type, t1.order_no, invoice_no, date_entered, date_shipped, Promo_id, Promo_level
-- select * from #sunps2

-- select * from #sunps1 where cust_code = 018482
-- select * from #sunps2 where cust_code = 018482
IF(OBJECT_ID('tempdb.dbo.#sunps') is not null)  
drop table #sunps
SELECT DISTINCT CASE WHEN t1.status_type = '1' THEN 'Act' WHEN t1.status_type = '2' THEN 'Inact' ELSE 'NoNewBus' end as Status, t1.territory_code as Terr, customer_code, ship_to_code, t1.address_name, t1.addr2, 
case when addr3 like '%, __ %' then '' else addr3 end as addr3, city, state, postal_code, country_code, contact_phone, tlx_twx, 
CASE WHEN t1.contact_email IS NULL or t1.contact_email LIKE '%@CVOPTICAL.COM' OR t1.contact_email = 'REFUSED' THEN '' ELSE lower(t1.contact_email) end AS contact_email,

ISNULL((SELECT SUM(CNT) FROM #SUNPS2 T11 WHERE T1.customer_code=T11.CUST_CODE AND T1.ship_to_code=T11.SHIP_TO AND date_entered BETWEEN @P1From AND @P1To),0) 'CurrYrInv',
ISNULL((SELECT (SUM(OrdQty)-sum(CRQty)) FROM #SUNPS2 T11 WHERE T1.customer_code=T11.CUST_CODE AND T1.ship_to_code=T11.SHIP_TO AND date_entered BETWEEN @P1From AND @P1To),0) 'CurrYrUnits',

ISNULL((SELECT SUM(CNT) FROM #SUNPS1 T11 WHERE T1.customer_code=T11.CUST_CODE AND T1.ship_to_code=T11.SHIP_TO AND DATE_SHIPPED BETWEEN @P2From AND @P2To),0) 'PrYrInv',
ISNULL((SELECT (SUM(OrdQty)-sum(CRQty)) FROM #SUNPS1 T11 WHERE T1.customer_code=T11.CUST_CODE AND T1.ship_to_code=T11.SHIP_TO AND DATE_SHIPPED BETWEEN @P2From AND @P2To),0) 'PrYrUnits',

ISNULL((SELECT SUM(CNT) FROM #SUNPS1 T11 WHERE T1.customer_code=T11.CUST_CODE AND T1.ship_to_code=T11.SHIP_TO AND DATE_SHIPPED BETWEEN @P3From AND @P3To),0) 'PrYrL1Inv',
ISNULL((SELECT (SUM(OrdQty)-sum(CRQty)) FROM #SUNPS1 T11 WHERE T1.customer_code=T11.CUST_CODE AND T1.ship_to_code=T11.SHIP_TO AND DATE_SHIPPED BETWEEN @P3From AND @P3To),0) 'PrYrL1Units',

ISNULL((SELECT SUM(CNT) FROM #SUNPS1 T11 WHERE T1.customer_code=T11.CUST_CODE AND T1.ship_to_code=T11.SHIP_TO AND DATE_SHIPPED BETWEEN @P4From AND @P4To),0) 'PrYrL2Inv',
ISNULL((SELECT (SUM(OrdQty)-sum(CRQty)) FROM #SUNPS1 T11 WHERE T1.customer_code=T11.CUST_CODE AND T1.ship_to_code=T11.SHIP_TO AND DATE_SHIPPED BETWEEN @P4From AND @P4To),0) 'PrYrL2Units',

ISNULL((SELECT SUM(CNT) FROM #SUNPS1 T11 WHERE T1.customer_code=T11.CUST_CODE AND T1.ship_to_code=T11.SHIP_TO AND DATE_SHIPPED BETWEEN @P5From AND @P5To),0) 'PrYrL3Inv',
ISNULL((SELECT (SUM(OrdQty)-sum(CRQty)) FROM #SUNPS1 T11 WHERE T1.customer_code=T11.CUST_CODE AND T1.ship_to_code=T11.SHIP_TO AND DATE_SHIPPED BETWEEN @P5From AND @P5To),0) 'PrYrL3Units',
datepart(year,@P1To) as Curr,
datepart(year,@P2To) as PrYr,
datepart(year,@P3To) as PrYL1,
datepart(year,@P4To) as prYL2,
datepart(year,@P5To) as prYL3
INTO #SUNPS
 FROM armaster t1 
 left outer join #SUNPS1 T2 on t1.customer_code=t2.cust_code and t1.ship_to_code=t2.ship_to
 left outer join #SUNPS2 T3 on t1.customer_code=t3.cust_code and t1.ship_to_code=t3.ship_to
 where address_type <>9
 order by t1.territory_code, customer_code, ship_to_code
 
select t1.*, 
(convert(decimal(10,2),(select sum(CurryrUnits+PrYrUnits+PrYrL1Units+PrYrL2Units+PrYrL3Units) from #sunps t11 where t1.customer_code=t11.customer_code and t1.ship_to_code=t11.ship_to_code))) AllYrs,  
(convert(decimal(10,2),(select sum(PrYrUnits+PrYrL1Units+PrYrL2Units+PrYrL3Units) from #sunps t11 where t1.customer_code=t11.customer_code and t1.ship_to_code=t11.ship_to_code))) PY  
FROM #sunps t1
where (select sum(CurryrUnits+PrYrUnits+PrYrL1Units+PrYrL2Units+PrYrL3Units) from #sunps t11 where t1.customer_code=t11.customer_code and t1.ship_to_code=t11.ship_to_code) <> 0



END


GO
