SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



-- =============================================
-- Author:		elabarbera
-- Create date: 4/9/2013
-- Description:	April 2013 Spring in the Money - SO Program
-- EXEC ssrs_STOrdProg_sp '4/1/2013', '4/30/2013'
-- =============================================
CREATE PROCEDURE [dbo].[ssrs_STOrdProg_sp] 

@From datetime, @To datetime

AS
BEGIN
	SET NOCOUNT ON;

-- April 2013 "Spring in the Money" Stock Order Program Review

--DECLARE @From datetime
--DECLARE @To datetime
--SET @From = '04/01/2013'
--SET @To = '04/30/2013 23:59:59'
		SET @To=dateadd(second,-1,@To)
		SET @To=dateadd(day,1,@To)

IF(OBJECT_ID('tempdb.dbo.#SOProg_STDET2') is not null)  
drop table #SOProg_STDET2
SELECT distinct T1.TYPE, DOOR, t3.territory_code, CUST_CODE, T1.SHIP_TO, Promo_ID, user_category, t1.ORDER_NO, 
CASE WHEN T1.TYPE = 'I' THEN sum(ordered) ELSE sum(cr_shipped)*-1 END AS 'QTY',
CASE WHEN T1.TYPE = 'I' THEN 1 ELSE -1 END AS 'COUNT',
DATE_ENTERED,
case when (select date_shipped from orders_all t11 where t1.order_no=t11.order_no and t11.ext=0) is null then (select date_shipped from orders_all t11 where t1.order_no=t11.order_no and t11.ext=1) else (select date_shipped from orders_all t11 where t1.order_no=t11.order_no and t11.ext=0) end as date_shipped
INTO #SOProg_STDET2
FROM ORDERS_ALL (NOLOCK) T1
JOIN ORD_LIST (NOLOCK) T2 ON T1.ORDER_NO = T2.ORDER_NO AND T1.EXT=T2.ORDER_EXT
join inv_master (nolock) IV on t2.part_no=IV.part_no
JOIN ARMASTER (NOLOCK) T3 ON T1.CUST_CODE=T3.CUSTOMER_CODE AND T1.SHIP_TO=T3.SHIP_TO_CODE
JOIN CVO_ARMASTER_ALL (NOLOCK) T4 ON T1.CUST_CODE=T4.CUSTOMER_CODE AND T1.SHIP_TO=T4.SHIP_TO
JOIN cvo_orders_all (NOLOCK) T5 ON T1.ORDER_NO = T5.ORDER_NO AND T1.EXT=T5.EXT
where date_entered BETWEEN @From AND @To
and DATE_SHIPPED BETWEEN @From AND @To
and t1.status='t' 
AND TYPE='I'
and order_ext=0
and type_code in('sun','frame')
and user_category not like '%rx%'
and user_category not in ('st-pm', 'st-rb', 'st-tb', 'do')
and (promo_id not in ('BEP') or promo_id is null)
GROUP BY t3.territory_code, DOOR, CUST_CODE, T1.SHIP_TO, T5.PROMO_ID, user_category, t1.ORDER_NO, T1.STATUS, T1.TYPE, DATE_ENTERED
--  select * from #SOProg_STDET2 where qty>=5

IF(OBJECT_ID('tempdb.dbo.#SOProg_AllCusts') is not null)  
drop table #SOProg_AllCusts
select t2.door,
t1.territory_code,
t1.customer_code as Cust_code,
t1.ship_to_code as Ship_to
into #SOProg_AllCusts
from armaster t1 (nolock)
join cvo_armaster_all t2 (nolock) on t1.customer_code=t2.customer_code and t1.ship_to_code=t2.ship_to
where t1.address_type <> 9
and t2.door=1
-- select * from #SOProg_AllCusts

IF(OBJECT_ID('tempdb.dbo.#SOProg_STCnt') is not null)  
drop table #SOProg_STCnt
select distinct Door, territory_code as Terr, cust_code, ship_to,
( isnull((select sum(count) from #SOProg_STDET2 t2 where t1.cust_code=t2.cust_code AND t1.SHIP_TO=t2.SHIP_TO AND t2.DOOR=1 and qty>=5),0) + isnull((select sum(count) from #SOProg_STDET2 t2 where t1.cust_code=t2.cust_code AND t2.DOOR=0 and qty>=5),0))CntAll,
CASE WHEN (select top 1 order_no from #SOProg_STDET2 t2 where t1.cust_code=t2.cust_code AND t2.DOOR=0 and qty>=5 order by cust_code, qty desc) IS NULL
	THEN (select top 1 order_no from #SOProg_STDET2 t2 where t1.cust_code=t2.cust_code AND t1.SHIP_TO=t2.SHIP_TO AND t2.DOOR=1 and qty>=5 order by cust_code, qty desc)
	ELSE (select top 1 order_no from #SOProg_STDET2 t2 where t1.cust_code=t2.cust_code AND t2.DOOR=0 and qty>=5 order by cust_code, qty desc)
	END AS ValidOrdNo
INTO #SOProg_STCnt
FROM  #SOProg_AllCusts T1
order by terr, cust_code, ship_to
-- select * from  #SOProg_STCnt


IF(OBJECT_ID('tempdb.dbo.#SOProg_TerCnt') is not null)  
drop table #SOProg_TerCnt
select distinct Terr, count(Cust_code) NumStOrds
into #SOProg_TerCnt
from #SOProg_STCnt
where CntAll >0
group by Terr
--  SELECT * FROM #SOProg_TerCnt

-- SUMMARY by Territory
  select Terr, NumSTOrds, 
  CASE WHEN NumSTOrds >= '60' THEN 'Level3'
	WHEN NumSTOrds >= '52' THEN 'Level2'
	WHEN NumSTOrds >= '44' THEN 'Level1'
	ELSE 'YetToQualify' end as 'LevelAcheived',
  CASE WHEN NumSTOrds >= '60' THEN '1000'
	WHEN NumSTOrds >= '52' THEN '750'
	WHEN NumSTOrds >= '44' THEN '500'
	ELSE '0' end as 'BonusPayout'
	FROM #SOProg_TerCnt order by Terr

END



GO
