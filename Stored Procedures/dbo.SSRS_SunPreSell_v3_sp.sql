SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		tgraziosi
-- Create date: 1/20/2015
-- Description:	Sun Presell 5 Yr Tracker
-- 2016 version - add order date to period info
-- exec SSRS_SunPreSell_v3_sp
-- =============================================

CREATE PROCEDURE [dbo].[SSRS_SunPreSell_v3_sp] @asofdate datetime = null
	
AS
BEGIN

	SET NOCOUNT ON;

-- DECLARE @asofdate DATETIME

if @asofdate is null  select @asofdate = getdate()

-- SUN PRESELL 5 year Customer Tracker
DECLARE @P1From datetime, @P1To datetime, @P2From datetime, @P2To datetime, 
		@P3From datetime, @P3To datetime, @P4From datetime, @P4To datetime,
		@P5From datetime, @P5To datetime

-- Orders Entered
SET @P1From = CASE WHEN  @asofdate > ('11/1/' + CONVERT(VARCHAR(4),(DATEPART(YEAR, @asofdate ))) ) 
				   THEN ('11/1/'+ CONVERT(VARCHAR(4),(DATEPART(YEAR, @asofdate )))  ) 
				   ELSE ('11/1/'+ CONVERT(VARCHAR(4),(DATEPART(YEAR, DATEADD(YEAR, -1, @asofdate) ))) ) END
SET @P1To = DATEADD(MILLISECOND, -3, DATEADD(YEAR,1, @P1From))

  -- Invoices Shipped
SET @P2From = dateadd(year,-1, @P1From)
SET @P2To = DATEADD(year, -1, @P1to)
SET @P3From = DATEADD(YEAR,-2, @P1From)
SET @P3To = DATEADD(YEAR,-2, @P1To)
SET @P4From = DATEADD(YEAR,-3, @P1From)
SET @P4To = DATEADD(YEAR,-3, @P1To)
SET @P5From = DATEADD(YEAR,-4, @P1From)
SET @P5To = DATEADD(YEAR,-4, @P1To)

-- select @P1From, @P1To, @P2From, @P2To, @P3From, @P3To, @P4From, @P4To, @P5From, @P5To

-- -- --  select * from inv_master
-- -- --
IF(OBJECT_ID('tempdb.dbo.#sunps') is not null)  drop table #sunps

-- HISTORY INVOICES
select cust_code, o.ship_to, o.type, o.order_no, invoice_no, date_entered, date_shipped, 
upper(user_def_fld3) as Promo_id, user_def_fld9 as Promo_level, 
CASE WHEN TYPE = 'C' THEN 0 ELSE sum(ordered) END AS OrdQty, sum(shipped) ShipQty, sum(CR_Shipped) CRQty,
CASE WHEN TYPE = 'I' THEN 1 ELSE -1 END AS Cnt
, period = case when date_shipped between @p2from and @p2to then datepart(year, @p2to)
			  when date_shipped between @p3from and @p3to then datepart(year, @p3to)
			  when date_shipped between @p4from and @p4to then datepart(year, @p4to)
			  when date_shipped between @p5from and @p5to then datepart(year, @p5to)
			  else '' end
into #sunps

from cvo_orders_all_hist (NOLOCK) o
join cvo_ord_list_hist  (NOLOCK) ol on o.order_no=ol.order_no and o.ext=ol.order_ext
JOIN INV_MASTER (NOLOCK) i ON ol.PART_NO=i.PART_NO
where o.status <> 'v'
and user_def_fld3 like '%SUNPS%' -- promo 
and o.ext=0
and date_shipped between @P5From and @P2To
and i.type_code in ('frame','sun')
group by  cust_code, o.ship_to, o.type, o.order_no, invoice_no, date_entered, date_shipped, 
	user_def_fld3, user_def_fld9

-- LIVE INVOICES
insert into #sunps
select cust_code, o.ship_to, o.type, o.order_no, CAST(invoice_no AS VARCHAR(12)), 
date_entered, date_shipped, upper(Promo_id) promo_id, Promo_level, 
sum(ordered) OrdQty, sum(shipped) ShipQty, sum(CR_Shipped) CRQty,
CASE WHEN TYPE = 'I' THEN 1 ELSE -1 END AS Cnt
, period = case when date_shipped between @p2from and @p2to then datepart(year, @p2to)
			  when date_shipped between @p3from and @p3to then datepart(year, @p3to)
			  when date_shipped between @p4from and @p4to then datepart(year, @p4to)
			  when date_shipped between @p5from and @p5to then datepart(year, @p5to)
			  else '' end 
from orders_all  (NOLOCK) o
join ord_list  (NOLOCK) ol on o.order_no=ol.order_no and o.ext=ol.order_ext
join cvo_orders_all  (NOLOCK) co on o.order_no=co.order_no and o.ext=co.ext
JOIN INV_MASTER (NOLOCK) i ON ol.PART_NO=i.PART_NO
where o.status <> 'v'
and promo_id like '%SUNPS%'
AND promo_level IN ('1','2','3')
AND (o.who_entered <> 'backordr')
-- and (o.ext=0 OR (o.ext>0 and o.who_entered='OutOfStock'))
and date_shipped between @P5From and @P2To
and i.type_code in ('frame','sun')
-- and right(o.user_category,2) not in ('rb','tb')
and not exists (select 1 from cvo_promo_override_audit poa where poa.order_no = o.order_no and poa.order_ext = o.ext) 

group by  cust_code, o.ship_to, o.type, o.order_no, invoice_no, date_entered, date_shipped, Promo_id, Promo_level

-- select * from #sunps

-- Current Year Open Orders

insert into #sunps
select cust_code, o.ship_to, type, o.order_no, CAST(invoice_no AS VARCHAR(12)), 
date_entered, date_shipped, upper(Promo_id) promo_id, Promo_level, 
sum(ordered) OrdQty, sum(shipped) ShipQty, sum(CR_Shipped) CRQty,
CASE WHEN TYPE = 'I' THEN 1 ELSE -1 END AS Cnt
, period = datepart(year, @asofdate)

from orders_all  (NOLOCK) o
join ord_list  (NOLOCK) ol on o.order_no=ol.order_no and o.ext=ol.order_ext
join cvo_orders_all  (NOLOCK) co on o.order_no=co.order_no and o.ext=co.ext
JOIN inv_master (nolock) i on ol.part_no=i.part_no
where o.status <> 'v'
and promo_id like '%SUNPS%'
AND (o.who_entered <> 'backordr')
-- and (o.ext='0' OR (o.ext>0 and o.who_entered='OutOfStock'))
and date_entered between @P1From and @P1To
and type_code in ('sun','frame')
-- and right(o.user_category,2) not in ('rb','tb')
and not exists (select 1 from cvo_promo_override_audit poa where poa.order_no = o.order_no and poa.order_ext = o.ext) 
group by  cust_code, o.ship_to, type, o.order_no, invoice_no, date_entered, date_shipped, Promo_id, Promo_level

-- Final Select

-- select * from #sunps  where cust_code = '045134'

select Status = CASE WHEN t1.status_type = '1' THEN 'Act' 
					 WHEN t1.status_type = '2' THEN 'Inact' 
					 ELSE 'NoNewBus' end
, t1.territory_code as Terr, customer_code, ship_to_code, t1.address_name, t1.addr2
, case when addr3 like '%, __ %' then '' else addr3 end as addr3
, city, state, postal_code, country_code, contact_phone, tlx_twx
, contact_email = CASE WHEN t1.contact_email IS NULL or t1.contact_email LIKE '%@CVOPTICAL.COM' OR t1.contact_email = 'REFUSED' 
			THEN '' ELSE lower(t1.contact_email) end 
, t2.period
, t2.date_entered
, case when t2.Inv_cnt < 0 then 0 else t2.inv_cnt end as Inv_cnt
, case when t2.inv_cnt < 0 then 0 else t2.inv_qty end as Inv_qty

 FROM 
 (select cust_code, case when car.door = 0 then '' else s.ship_to end as ship_to, period
  , sum(isnull(cnt,0)) Inv_cnt
  , sum(isnull(ordqty,0)-isnull(crqty,0)) Inv_qty
  , MIN(s.date_entered) date_entered
  from #sunps s
  inner join cvo_armaster_all car on car.customer_code = s.cust_code and car.ship_to = s.ship_to
  group by cust_code, case when car.door = 0 then '' else s.ship_to end, period
  having sum(isnull(cnt,0)) >=0 ) as t2
 inner join armaster t1 on t1.customer_code=t2.cust_code and t1.ship_to_code=t2.ship_to
 WHERE inv_qty <> 0 and inv_cnt <> 0

--select t1.*, 
--(convert(decimal(10,2),(select sum(CurryrUnits+PrYrUnits+PrYrL1Units+PrYrL2Units+PrYrL3Units) from #sunps t11 where t1.customer_code=t11.customer_code and t1.ship_to_code=t11.ship_to_code))) AllYrs,  
--(convert(decimal(10,2),(select sum(PrYrUnits+PrYrL1Units+PrYrL2Units+PrYrL3Units) from #sunps t11 where t1.customer_code=t11.customer_code and t1.ship_to_code=t11.ship_to_code))) PY  
--FROM #sunps t1
--where (select sum(CurryrUnits+PrYrUnits+PrYrL1Units+PrYrL2Units+PrYrL3Units) from #sunps t11 where t1.customer_code=t11.customer_code and t1.ship_to_code=t11.ship_to_code) <> 0



END



GO
