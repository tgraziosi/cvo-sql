SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




-- =============================================
-- Author:		elabarbera
-- Create date: 2/20/2013
-- Description:	Sun Presell 5 Yr Tracker
-- exec SSRS_SunPreSell2_sp '2013'
-- =============================================

CREATE PROCEDURE [dbo].[SSRS_SunPreSell2_sp] 

@Year varchar(4)
	
AS
BEGIN

	SET NOCOUNT ON;

-- SUN PRESELL 5 year Customer Tracker
--DECLARE @Year varchar(4)
--SET @Year = '2013'

DECLARE @PSFrom datetime
DECLARE @PSTo datetime
DECLARE @SunFrom datetime
DECLARE @SunTo datetime

SET @PSFrom = '9/1/'+@Year
SET @PSTo = DATEADD(MILLISECOND, -3, DATEADD(YEAR,1, @PSFrom))

SET @SunFrom = '1/1/'+@Year
SET @SunTo = DATEADD(MILLISECOND, -3, DATEADD(YEAR,1, @SunFrom))

-- select @PSFrom, @PSTo, @SunFrom, @SunTo

-- -- --  select * from inv_master
-- -- --
IF(OBJECT_ID('tempdb.dbo.#SunAll') is not null)  
drop table #SunAll
	SELECT * INTO #SunAll FROM (
-- HISTORY INVOICES SUNPS
select cust_code, t1.ship_to, type, t1.order_no, invoice_no, date_entered, date_shipped, upper(user_def_fld3) as Promo_id, user_def_fld9 as Promo_level, 
CASE WHEN TYPE = 'C' THEN 0 ELSE sum(ordered) END AS OrdQty, sum(shipped) ShipQty, sum(CR_Shipped) CRQty,
CASE WHEN TYPE = 'I' THEN 1 ELSE -1 END AS 'Cnt' 
from cvo_orders_all_hist (NOLOCK) t1
join cvo_ord_list_hist  (NOLOCK) t2 on t1.order_no=t2.order_no and t1.ext=t2.order_ext
JOIN INV_MASTER (NOLOCK) T3 ON T2.PART_NO=T3.PART_NO
where t1.status <> 'v'
and user_def_fld3 in ('SUNPS')
and t1.ext='0'
and t3.type_code in('frame','sun')
and date_shipped between DATEADD(YEAR,-4,@PSFrom) and @PSTo
group by  cust_code, t1.ship_to, type, t1.order_no, invoice_no, date_entered, date_shipped, user_def_fld3, user_def_fld9
	UNION ALL
-- LIVE INVOICES SUNPS
select cust_code, t1.ship_to, type, t1.order_no, CAST(invoice_no AS NVARCHAR), date_entered, date_shipped, upper(Promo_id), Promo_level, sum(ordered) OrdQty, sum(shipped) ShipQty, sum(CR_Shipped) CRQty,
CASE WHEN TYPE = 'I' THEN 1 ELSE -1 END AS 'Cnt' 
from orders_all  (NOLOCK) t1
join ord_list  (NOLOCK) t2 on t1.order_no=t2.order_no and t1.ext=t2.order_ext
join cvo_orders_all  (NOLOCK) t3 on t1.order_no=t3.order_no and t1.ext=t3.ext
JOIN INV_MASTER (NOLOCK) T4 ON T2.PART_NO=T4.PART_NO
where ( (t1.status <> 'v' and t1.ext='0') OR t1.who_entered = 'outofstock' )
and promo_id in ('SUNPS')
and t4.type_code in('frame','sun')
and date_entered between DATEADD(YEAR,-4,@PSFrom) and @PSTo
group by  cust_code, t1.ship_to, type, t1.order_no, invoice_no, date_entered, date_shipped, Promo_id, Promo_level
	UNION ALL
-- HISTORY INVOICES SUN
select cust_code, t1.ship_to, type, t1.order_no, invoice_no, date_entered, date_shipped, upper(user_def_fld3) as Promo_id, user_def_fld9 as Promo_level, 
CASE WHEN TYPE = 'C' THEN 0 ELSE sum(ordered) END AS OrdQty, sum(shipped) ShipQty, sum(CR_Shipped) CRQty,
CASE WHEN TYPE = 'I' THEN 1 ELSE -1 END AS 'Cnt' 
from cvo_orders_all_hist (NOLOCK) t1
join cvo_ord_list_hist  (NOLOCK) t2 on t1.order_no=t2.order_no and t1.ext=t2.order_ext
JOIN INV_MASTER (NOLOCK) T3 ON T2.PART_NO=T3.PART_NO
where t1.status <> 'v'
and user_def_fld3 in ('SUN')
and t1.ext='0'
and t3.type_code in('frame','sun')
and date_shipped between dateadd(year,-4,@SunFrom) and @SunTo
group by  cust_code, t1.ship_to, type, t1.order_no, invoice_no, date_entered, date_shipped, user_def_fld3, user_def_fld9
	UNION ALL
-- LIVE INVOICES SUN
select cust_code, t1.ship_to, type, t1.order_no, CAST(invoice_no AS NVARCHAR), date_entered, date_shipped, upper(Promo_id), Promo_level, sum(ordered) OrdQty, sum(shipped) ShipQty, sum(CR_Shipped) CRQty,
CASE WHEN TYPE = 'I' THEN 1 ELSE -1 END AS 'Cnt' 
from orders_all  (NOLOCK) t1
join ord_list  (NOLOCK) t2 on t1.order_no=t2.order_no and t1.ext=t2.order_ext
join cvo_orders_all  (NOLOCK) t3 on t1.order_no=t3.order_no and t1.ext=t3.ext
JOIN INV_MASTER (NOLOCK) T4 ON T2.PART_NO=T4.PART_NO
where ( (t1.status <> 'v' and t1.ext='0') OR t1.who_entered = 'outofstock' )
and promo_id in ('SUN')
and t4.type_code in('frame','sun')
and date_shipped between dateadd(year,-4,@SunFrom) and @SunTo
group by  cust_code, t1.ship_to, type, t1.order_no, invoice_no, date_entered, date_shipped, Promo_id, Promo_level
	UNION ALL
-- HISTORY INVOICES SUN
select cust_code, t1.ship_to, type, t1.order_no, invoice_no, date_entered, date_shipped, upper(user_def_fld3) as Promo_id, user_def_fld9 as Promo_level, 
CASE WHEN TYPE = 'C' THEN 0 ELSE sum(ordered) END AS OrdQty, sum(shipped) ShipQty, sum(CR_Shipped) CRQty,
CASE WHEN TYPE = 'I' THEN 1 ELSE -1 END AS 'Cnt' 
from cvo_orders_all_hist (NOLOCK) t1
join cvo_ord_list_hist  (NOLOCK) t2 on t1.order_no=t2.order_no and t1.ext=t2.order_ext
JOIN INV_MASTER (NOLOCK) T3 ON T2.PART_NO=T3.PART_NO
where t1.status <> 'v'
and user_def_fld3 in ('SUN SPRING')
and t1.ext='0'
and t3.type_code in('frame','sun')
and date_shipped between dateadd(year,-4,@SunFrom) and @SunTo
group by  cust_code, t1.ship_to, type, t1.order_no, invoice_no, date_entered, date_shipped, user_def_fld3, user_def_fld9
	UNION ALL
-- LIVE INVOICES SUN
select cust_code, t1.ship_to, type, t1.order_no, CAST(invoice_no AS NVARCHAR), date_entered, date_shipped, upper(Promo_id), Promo_level, sum(ordered) OrdQty, sum(shipped) ShipQty, sum(CR_Shipped) CRQty,
CASE WHEN TYPE = 'I' THEN 1 ELSE -1 END AS 'Cnt' 
from orders_all  (NOLOCK) t1
join ord_list  (NOLOCK) t2 on t1.order_no=t2.order_no and t1.ext=t2.order_ext
join cvo_orders_all  (NOLOCK) t3 on t1.order_no=t3.order_no and t1.ext=t3.ext
JOIN INV_MASTER (NOLOCK) T4 ON T2.PART_NO=T4.PART_NO
where ( (t1.status <> 'v' and t1.ext='0') OR t1.who_entered = 'outofstock' )
and promo_id in ('SUN SPRING')
and t4.type_code in('frame','sun')
and date_shipped between dateadd(year,-4,@SunFrom) and @SunTo
group by  cust_code, t1.ship_to, type, t1.order_no, invoice_no, date_entered, date_shipped, Promo_id, Promo_level

) tmp
-- select * from #SunAll


IF(OBJECT_ID('tempdb.dbo.#sun') is not null)  
drop table #sun
SELECT DISTINCT CASE WHEN t1.status_type = '1' THEN 'Act' WHEN t1.status_type = '2' THEN 'Inact' ELSE 'NoNewBus' end as Status, t1.territory_code as Terr, customer_code, ship_to_code, t1.address_name, t1.addr2, 
case when addr3 like '%, __ %' then '' else addr3 end as addr3, city, state, postal_code, country_code, contact_phone, tlx_twx, 
CASE WHEN t1.contact_email IS NULL or t1.contact_email LIKE '%@CVOPTICAL.COM' OR t1.contact_email = 'REFUSED' THEN '' ELSE lower(t1.contact_email) end AS contact_email,

ISNULL((SELECT SUM(CNT) FROM #SunAll T11 WHERE T1.customer_code=T11.CUST_CODE AND T1.ship_to_code=T11.SHIP_TO and Promo_ID = 'SUNPS' AND date_entered BETWEEN @PSFrom AND @PSTo),0) 'PSY1Ords',
ISNULL((SELECT (SUM(OrdQty)-sum(CRQty)) FROM #SunAll T11 WHERE T1.customer_code=T11.CUST_CODE AND T1.ship_to_code=T11.SHIP_TO and Promo_ID = 'SUNPS' AND date_entered BETWEEN @PSFrom AND @PSTo),0) 'PSY1Units',

ISNULL((SELECT SUM(CNT) FROM #SunAll T11 WHERE T1.customer_code=T11.CUST_CODE AND T1.ship_to_code=T11.SHIP_TO and Promo_ID = 'SUNPS' AND date_entered BETWEEN DATEADD(YEAR,-1,@PSFrom) AND DATEADD(YEAR,-1,@PSTo)),0) 'PSY2Ords',
ISNULL((SELECT (SUM(OrdQty)-sum(CRQty)) FROM #SunAll T11 WHERE T1.customer_code=T11.CUST_CODE AND T1.ship_to_code=T11.SHIP_TO and Promo_ID = 'SUNPS' AND date_entered BETWEEN DATEADD(YEAR,-1,@PSFrom) AND DATEADD(YEAR,-1,@PSTo)),0) 'PSY2Units',

ISNULL((SELECT SUM(CNT) FROM #SunAll T11 WHERE T1.customer_code=T11.CUST_CODE AND T1.ship_to_code=T11.SHIP_TO and Promo_ID = 'SUNPS' AND date_entered BETWEEN DATEADD(YEAR,-2,@PSFrom) AND DATEADD(YEAR,-2,@PSTo)),0) 'PSY3Ords',
ISNULL((SELECT (SUM(OrdQty)-sum(CRQty)) FROM #SunAll T11 WHERE T1.customer_code=T11.CUST_CODE AND T1.ship_to_code=T11.SHIP_TO and Promo_ID = 'SUNPS' AND date_entered BETWEEN DATEADD(YEAR,-2,@PSFrom) AND DATEADD(YEAR,-2,@PSTo)),0) 'PSY3Units',

ISNULL((SELECT SUM(CNT) FROM #SunAll T11 WHERE T1.customer_code=T11.CUST_CODE AND T1.ship_to_code=T11.SHIP_TO and Promo_ID = 'SUNPS' AND date_entered BETWEEN DATEADD(YEAR,-3,@PSFrom) AND DATEADD(YEAR,-3,@PSTo)),0) 'PSY4Ords',
ISNULL((SELECT (SUM(OrdQty)-sum(CRQty)) FROM #SunAll T11 WHERE T1.customer_code=T11.CUST_CODE AND T1.ship_to_code=T11.SHIP_TO and Promo_ID = 'SUNPS' AND date_entered BETWEEN DATEADD(YEAR,-3,@PSFrom) AND DATEADD(YEAR,-3,@PSTo)),0) 'PSY4Units',

ISNULL((SELECT SUM(CNT) FROM #SunAll T11 WHERE T1.customer_code=T11.CUST_CODE AND T1.ship_to_code=T11.SHIP_TO and Promo_ID = 'SUNPS' AND date_entered BETWEEN DATEADD(YEAR,-4,@PSFrom) AND DATEADD(YEAR,-4,@PSTo)),0) 'PSY5Ords',
ISNULL((SELECT (SUM(OrdQty)-sum(CRQty)) FROM #SunAll T11 WHERE T1.customer_code=T11.CUST_CODE AND T1.ship_to_code=T11.SHIP_TO and Promo_ID = 'SUNPS' AND date_entered BETWEEN DATEADD(YEAR,-4,@PSFrom) AND DATEADD(YEAR,-4,@PSTo)),0) 'PSY5Units',

@PSFrom as PSFrom,
@PSTo as PSTo,

ISNULL((SELECT SUM(CNT) FROM #SunAll T11 WHERE T1.customer_code=T11.CUST_CODE AND T1.ship_to_code=T11.SHIP_TO and Promo_ID = 'SUN' AND date_entered BETWEEN @SunFrom AND @SunTo),0) 'SunY1Ords',
ISNULL((SELECT (SUM(OrdQty)-sum(CRQty)) FROM #SunAll T11 WHERE T1.customer_code=T11.CUST_CODE AND T1.ship_to_code=T11.SHIP_TO and Promo_ID = 'SUN' AND date_entered BETWEEN @SunFrom AND @SunTo),0) 'SunY1Units',

ISNULL((SELECT SUM(CNT) FROM #SunAll T11 WHERE T1.customer_code=T11.CUST_CODE AND T1.ship_to_code=T11.SHIP_TO and Promo_ID = 'SUN' AND date_entered BETWEEN DATEADD(YEAR,-1,@SunFrom) AND DATEADD(YEAR,-1,@SunTo)),0) 'SunY2Ords',
ISNULL((SELECT (SUM(OrdQty)-sum(CRQty)) FROM #SunAll T11 WHERE T1.customer_code=T11.CUST_CODE AND T1.ship_to_code=T11.SHIP_TO and Promo_ID = 'SUN' AND date_entered BETWEEN DATEADD(YEAR,-1,@SunFrom) AND DATEADD(YEAR,-1,@SunTo)),0) 'SunY2Units',

ISNULL((SELECT SUM(CNT) FROM #SunAll T11 WHERE T1.customer_code=T11.CUST_CODE AND T1.ship_to_code=T11.SHIP_TO and Promo_ID = 'SUN' AND date_entered BETWEEN DATEADD(YEAR,-2,@SunFrom) AND DATEADD(YEAR,-2,@SunTo)),0) 'SunY3Ords',
ISNULL((SELECT (SUM(OrdQty)-sum(CRQty)) FROM #SunAll T11 WHERE T1.customer_code=T11.CUST_CODE AND T1.ship_to_code=T11.SHIP_TO and Promo_ID = 'SUN' AND date_entered BETWEEN DATEADD(YEAR,-2,@SunFrom) AND DATEADD(YEAR,-2,@SunTo)),0) 'SunY3Units',

ISNULL((SELECT SUM(CNT) FROM #SunAll T11 WHERE T1.customer_code=T11.CUST_CODE AND T1.ship_to_code=T11.SHIP_TO and Promo_ID = 'SUN' AND date_entered BETWEEN DATEADD(YEAR,-3,@SunFrom) AND DATEADD(YEAR,-3,@SunTo)),0) 'SunY4Ords',
ISNULL((SELECT (SUM(OrdQty)-sum(CRQty)) FROM #SunAll T11 WHERE T1.customer_code=T11.CUST_CODE AND T1.ship_to_code=T11.SHIP_TO and Promo_ID = 'SUN' AND date_entered BETWEEN DATEADD(YEAR,-3,@SunFrom) AND DATEADD(YEAR,-3,@SunTo)),0) 'SunY4Units',

ISNULL((SELECT SUM(CNT) FROM #SunAll T11 WHERE T1.customer_code=T11.CUST_CODE AND T1.ship_to_code=T11.SHIP_TO and Promo_ID = 'SUN' AND date_entered BETWEEN DATEADD(YEAR,-4,@SunFrom) AND DATEADD(YEAR,-4,@SunTo)),0) 'SunY5Ords',
ISNULL((SELECT (SUM(OrdQty)-sum(CRQty)) FROM #SunAll T11 WHERE T1.customer_code=T11.CUST_CODE AND T1.ship_to_code=T11.SHIP_TO and Promo_ID = 'SUN' AND date_entered BETWEEN DATEADD(YEAR,-4,@SunFrom) AND DATEADD(YEAR,-4,@SunTo)),0) 'SunY5Units',

-- Sun Spring
ISNULL((SELECT SUM(CNT) FROM #SunAll T11 WHERE T1.customer_code=T11.CUST_CODE AND T1.ship_to_code=T11.SHIP_TO and Promo_ID = 'SUN SPRING' AND date_entered BETWEEN @SunFrom AND @SunTo),0) 'SunSPY1Ords',
ISNULL((SELECT (SUM(OrdQty)-sum(CRQty)) FROM #SunAll T11 WHERE T1.customer_code=T11.CUST_CODE AND T1.ship_to_code=T11.SHIP_TO and Promo_ID = 'SUN SPRING' AND date_entered BETWEEN @SunFrom AND @SunTo),0) 'SunSPY1Units',

ISNULL((SELECT SUM(CNT) FROM #SunAll T11 WHERE T1.customer_code=T11.CUST_CODE AND T1.ship_to_code=T11.SHIP_TO and Promo_ID = 'SUN SPRING' AND date_entered BETWEEN DATEADD(YEAR,-1,@SunFrom) AND DATEADD(YEAR,-1,@SunTo)),0) 'SunSPY2Ords',
ISNULL((SELECT (SUM(OrdQty)-sum(CRQty)) FROM #SunAll T11 WHERE T1.customer_code=T11.CUST_CODE AND T1.ship_to_code=T11.SHIP_TO and Promo_ID = 'SUN SPRING' AND date_entered BETWEEN DATEADD(YEAR,-1,@SunFrom) AND DATEADD(YEAR,-1,@SunTo)),0) 'SunSPY2Units',

ISNULL((SELECT SUM(CNT) FROM #SunAll T11 WHERE T1.customer_code=T11.CUST_CODE AND T1.ship_to_code=T11.SHIP_TO and Promo_ID = 'SUN SPRING' AND date_entered BETWEEN DATEADD(YEAR,-2,@SunFrom) AND DATEADD(YEAR,-2,@SunTo)),0) 'SunSPY3Ords',
ISNULL((SELECT (SUM(OrdQty)-sum(CRQty)) FROM #SunAll T11 WHERE T1.customer_code=T11.CUST_CODE AND T1.ship_to_code=T11.SHIP_TO and Promo_ID = 'SUN SPRING' AND date_entered BETWEEN DATEADD(YEAR,-2,@SunFrom) AND DATEADD(YEAR,-2,@SunTo)),0) 'SunSPY3Units',

ISNULL((SELECT SUM(CNT) FROM #SunAll T11 WHERE T1.customer_code=T11.CUST_CODE AND T1.ship_to_code=T11.SHIP_TO and Promo_ID = 'SUN SPRING' AND date_entered BETWEEN DATEADD(YEAR,-3,@SunFrom) AND DATEADD(YEAR,-3,@SunTo)),0) 'SunSPY4Ords',
ISNULL((SELECT (SUM(OrdQty)-sum(CRQty)) FROM #SunAll T11 WHERE T1.customer_code=T11.CUST_CODE AND T1.ship_to_code=T11.SHIP_TO and Promo_ID = 'SUN SPRING' AND date_entered BETWEEN DATEADD(YEAR,-3,@SunFrom) AND DATEADD(YEAR,-3,@SunTo)),0) 'SunSPY4Units',

ISNULL((SELECT SUM(CNT) FROM #SunAll T11 WHERE T1.customer_code=T11.CUST_CODE AND T1.ship_to_code=T11.SHIP_TO and Promo_ID = 'SUN SPRING' AND date_entered BETWEEN DATEADD(YEAR,-4,@SunFrom) AND DATEADD(YEAR,-4,@SunTo)),0) 'SunSPY5Ords',
ISNULL((SELECT (SUM(OrdQty)-sum(CRQty)) FROM #SunAll T11 WHERE T1.customer_code=T11.CUST_CODE AND T1.ship_to_code=T11.SHIP_TO and Promo_ID = 'SUN SPRING' AND date_entered BETWEEN DATEADD(YEAR,-4,@SunFrom) AND DATEADD(YEAR,-4,@SunTo)),0) 'SunSPY5Units',

@SunFrom as SunFrom,
@SunTo as SunTo

INTO #SUN
 FROM armaster t1 
 left outer join #SUNALL T2 on t1.customer_code=t2.cust_code and t1.ship_to_code=t2.ship_to
  where address_type <>9
 order by t1.territory_code, customer_code, ship_to_code
 
select * from #SUN

END
GO
