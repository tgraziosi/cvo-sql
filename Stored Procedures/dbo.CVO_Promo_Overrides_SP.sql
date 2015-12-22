SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO





CREATE Procedure [dbo].[CVO_Promo_Overrides_SP]

--@PROMOID VARCHAR (20),
--@TERR VARCHAR (7),
--@OVERRIDEUSER VARCHAR (20),
--@ORDFROM DATETIME,
--@ORDTO DATETIME

AS
--DECLARE @PROMOID VARCHAR (20)
--DECLARE @TERR VARCHAR (7)
--DECLARE @OVERRIDEUSER VARCHAR (20)
--DECLARE @ORDFROM DATETIME
--DECLARE @ORDTO DATETIME
--SET @PROMOID = 'BEP'
--SET @TERR ='40454'
--SET @ORDFROM = '1/1/2012'
--SET @ORDTO = '1/31/2013'
--SET @ORDTO = DATEADD(DAY,1,DATEADD(SECOND,-1,@ORDTO))
--SET @OVERRIDEUSER = 'KMCGRORTY'

 --SELECT @promoid, @terr, @ordfrom, @ORDTO, @OVERRIDEUSER

-- created by elizabeth labarbera
IF(OBJECT_ID('tempdb.dbo.#CVO_Promo_Overrides') is not null)  
drop table #CVO_Promo_Overrides

select distinct ship_to_region AS Terr, Cust_code as Customer, t1.Order_no, t1.Status, Req_Ship_Date, Promo_ID, Promo_Level, CAST(sum(ordered) AS DECIMAL(12,0)) OrgPcsOrd, ISNULL(Moverride_date,'')OverrideDate, ISNULL(override_user,'')Override_User, ISNULL(failure_reason,'')Failure_Reason, ISNULL(lower(t1.note),'') Note
INTO #CVO_Promo_Overrides
from orders_all (nolock) t1
join cvo_orders_all (nolock) t2 on t1.order_no=t2.order_no and t1.ext=t2.ext
join ord_list (nolock) t3 on t1.order_no=t3.order_no and t1.ext=t3.order_ext
--join cvo_promo_override_audit (nolock) t4 on t1.order_no=t4.order_no and t1.ext=t4.order_ext
left outer join ( select order_no, max(override_date) Moverride_date from cvo_promo_override_audit group by order_no ) Ovr2 ON t1.order_no = Ovr2.order_no 
join cvo_promo_override_audit t4 on t1.order_no=t4.order_no and t1.ext=t4.order_ext and t4.override_date=Ovr2.Moverride_date and ovr2.order_no=t4.order_no

where t1.ext='0'
and t1.status <> 'v'
and promo_id is not null
and promo_id <> ''
and part_no not like '__z%'
and part_no not like '%case%'
--and t1.order_no ='1380500'
group by ship_to_region, cust_code, t1.order_no, t1.status, req_ship_date, promo_id, promo_level, Moverride_date, override_user, failure_reason, t1.note
order by promo_id, promo_level, req_ship_date, order_no
 
UPDATE #CVO_Promo_Overrides  SET failure_reason = REPLACE (failure_reason,'Order does not qualify for promotion - mimimum/maximum','Order - Min/Max')
UPDATE #CVO_Promo_Overrides  SET failure_reason = REPLACE (failure_reason,'Order does not qualify for promotion - order','Order - ')
UPDATE #CVO_Promo_Overrides  SET failure_reason = REPLACE (failure_reason,'Customer does not qualify for promotion - prior Sales Orders do','Cust - does')


IF(OBJECT_ID('dbo.CVO_Promo_Overrides_SSRS') is not null)  
drop table CVO_Promo_Overrides_SSRS
select * INTO CVO_Promo_Overrides_SSRS from #CVO_Promo_Overrides 
--WHERE PROMO_ID like @PROMOID
--AND TERR like @TERR
--AND OverrideDate BETWEEN @ORDFROM AND @ORDTO
--AND Override_User LIKE @OVERRIDEUSER

--  select * from CVO_Promo_Overrides_SSRS
--  EXEC CVO_Promo_Overrides_SP '%%','%%','%%','1/1/2012','1/10/2013'
--




GO
