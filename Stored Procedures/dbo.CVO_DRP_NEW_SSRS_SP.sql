SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



-- =============================================
-- Author:, , ELABARBERA
-- Create date: JAN 2014
-- Description:, DRP NEW REBUILD
-- EXEC CVO_DRP_NEW_SSRS_SP 
-- =============================================
CREATE PROCEDURE [dbo].[CVO_DRP_NEW_SSRS_SP] 

AS
BEGIN

SET NOCOUNT ON;


DECLARE @TodayDayOfWeek INT                                        
DECLARE @EndOfPrevWeek DateTime                                        
DECLARE @StartOfPrevWeek4 DateTime                                        
DECLARE @StartOfPrevWeek12 DateTime                                        
DECLARE @StartOfPrevWeek26 DateTime                                        
DECLARE @StartOfPrevWeek52 DateTime                                         
DECLARE @location tinyint                        
DECLARE @ctrl int                              
DECLARE @locationName varchar(80) 

 SET @TodayDayOfWeek = datepart(dw, GetDate())                                       --get number of a current day (1-Monday, 2-Tuesday... 7-Sunday)
 SET @EndOfPrevWeek = DATEADD(ms, -3, DATEADD(dd, 1, DATEDIFF(dd, 0, GETDATE())))    --get the last day of the previous week (last Sunday)
 SET @StartOfPrevWeek4 = DATEADD(ms, +4, DATEADD(dd, -(28), @EndOfPrevWeek))         --get the first day of the previous week (the Monday before last)
 SET @StartOfPrevWeek12 = DATEADD(ms, +4, DATEADD(dd, -(84), @EndOfPrevWeek))        -- 12 Weeks
 SET @StartOfPrevWeek26 = DATEADD(ms, +4, DATEADD(dd, -(182), @EndOfPrevWeek))       -- 26
 SET @StartOfPrevWeek52 = DATEADD(ms, +4, DATEADD(dd, -(364), @EndOfPrevWeek))       -- 52
-- SELECT datepart(dw, GetDate()), @EndOfPrevWeek as EndPrWk, @StartOfPrevWeek4 as StPrevWk4
-- SELECT @EndOfPrevWeek, dateadd(dd,-49,@EndOfPrevWeek), dateadd(dd,-7,@EndOfPrevWeek)

IF(OBJECT_ID('tempdb.dbo.#weeks') is not null)
drop table #weeks 
CREATE TABLE #weeks
( startDate smalldatetime,
endDate datetime,
week tinyint )

Insert Into #weeks Values(@StartOfPrevWeek4, @EndOfPrevWeek, 4)
Insert Into #weeks Values(@StartOfPrevWeek12, @EndOfPrevWeek, 12)
Insert Into #weeks Values(@StartOfPrevWeek26, @EndOfPrevWeek, 26)
Insert Into #weeks Values(@StartOfPrevWeek52, @EndOfPrevWeek, 52)
--   select * from #Weeks

IF(OBJECT_ID('tempdb.dbo.#weeks2') is not null)
drop table #weeks2
CREATE TABLE #weeks2
(startDate smalldatetime,
endDate datetime,
week tinyint )

Insert Into #weeks2 Values(@StartOfPrevWeek4, @EndOfPrevWeek, 4)
Insert Into #weeks2 Values(@StartOfPrevWeek12, DateAdd(Minute,-1,@StartOfPrevWeek4), 12)
Insert Into #weeks2 Values(@StartOfPrevWeek26, DateAdd(Minute,-1,@StartOfPrevWeek12), 26)
Insert Into #weeks2 Values(@StartOfPrevWeek52, DateAdd(Minute,-1,@StartOfPrevWeek26), 52)
--   select * from #Weeks2


-- PULL Part_no Information
IF(OBJECT_ID('tempdb.dbo.#InvInfo') is not null)  
drop table #InvInfo
select distinct t1.part_no, t1.location, category as Collection, field_2 as Style, t2.description, field_26 as ReleaseDate, field_28 as POM, datetime_2 as Watch,
CASE WHEN (FIELD_26 <=GETDATE() AND FIELD_28 IS NULL) OR (FIELD_26 <=GETDATE() AND FIELD_28 >GETDATE()) THEN 'Active' else 'InActive' end as [Status],
-- CASE WHEN obsolete = 1 THEN 'InActive' else 'Active' end as [Status],  -- OLD Version
 Vendor, t5.description as CntryOfOrgin, LeadTime, Type_code, CATEGORY_3 AS Part_Type,
cmdty_code Material, category_2 Gender, case when lead_time = 0 then leadtime else lead_time end as PartLeadTime, 
t1.std_cost FCost, (t1.std_cost + t1.Std_ovhd_dolrs + t1.std_util_dolrs) LCost 
INTO #InvInfo
FROM inv_list t1 (nolock)
join inv_master t2 (nolock) on t1.part_no=t2.part_no
join inv_master_add t3 (nolock) on t1.part_no=t3.part_no
left join (Select vendor_code, MAX(ISNULL(lead_time,0))LeadTime From apmaster_all (nolock) Group By vendor_code) T4 on t2.vendor = T4.vendor_code         
join gl_country t5 (nolock) on t2.country_code=t5.country_code
where t1.location in (select * from DPR_locations) and t2.void <> 'v' and t1.void <> 'v' AND category <> 'corp' 
order by Category, field_2, t1.part_no


-- OPEN ORDERS/CREDITS
IF(OBJECT_ID('tempdb.dbo.#OPENORDS') is not null) drop table #OPENORDS
SELECT Cust_code as Customer, O.Ship_to, address_name as Customer_name, part_no, ISNULL(Promo_id,'')Promo_id, ISNULL(promo_level,'')Promo_level,
case 
 when OL.return_code like '04%' then 'DEF'
 else '' END as return_code,
user_category, OL.location,
datepart(month,date_entered)c_month,
datepart(year,date_entered)c_year,
datepart(month,date_entered)x_month,
datename(month,date_entered)month,
datepart(year,date_entered)year,
case O.type when 'i' then 
case isnull(cl.is_amt_disc,'n') when 'y' then round (ol.ordered * ol.curr_price,2) - round(ol.ordered*isnull(cl.amt_disc,0),2)
else round(ol.ordered*ol.curr_price,2) - round(ol.ordered*(ol.curr_price*(ol.discount/100.00)),2) 
end else 0 end as asales,
case o.type when 'c' then round(ol.cr_ordered * ol.curr_price,2) - round(ol.cr_ordered * (ol.curr_price * (ol.discount/100.00)),2)
else 0 end as areturns,
case when o.type = 'i' then ol.ordered else 0 end as qsales,
case when o.type = 'c' then ol.cr_ordered else 0 end as qreturns,
case when o.type = 'i' then ol.ordered else 0 end - case when o.type = 'c' then ol.cr_ordered else 0 end as qnet,
round((ol.ordered-ol.cr_ordered) * (ol.cost+ol.ovhd_dolrs+ol.util_dolrs),2) as csales,
round((ol.ordered-ol.cr_ordered) * cl.list_price,2) as lsales,
NULL as DateShipped,
date_entered as DateOrdered,
isnull(ol.return_code,'') as orig_return_code,
case WHEN (o.type = 'i' and USER_CATEGORY IN ('DO','RX-RB','ST-CL','ST-PR','ST-RB')) OR (o.type = 'C' and OL.return_code like '04%') THEN 'EXC'   ELSE '' END AS EXC
INTO #OPENORDS
FROM orders o (nolock)
inner join cvo_orders_all co (nolock) on co.order_no = o.order_no and co.ext = o.ext
inner join ord_list ol (nolock) on ol.order_no = o.order_no and ol.order_ext = o.ext
left outer join cvo_ord_list cl (nolock) on cl.order_no = ol.order_no and cl.order_ext = ol.order_ext and cl.line_no = ol.line_no
JOIN armaster AR (NOLOCK) on O.cust_code=AR.customer_code and O.ship_to=AR.ship_to_code
WHERE O.STATUS NOT IN ('T','V') 
AND (TYPE = 'I' OR (TYPE = 'C' AND DATE_ENTERED > DATEADD(dd, -5, DATEDIFF(dd, 0, GETDATE()) ) ) )
Order by date_entered desc, cust_code
-- select * from #OPENORDS 
-- select * from #OPENORDS where part_no='BC804HOR5818'

IF(OBJECT_ID('tempdb.dbo.#History') is not null)                          
drop table #History
SELECT distinct Part_no, Type, Qty,DateShipped, DateOrdered, Location, Week, EXC, Loc INTO #History From (
-- SHIPPED   
select t1.part_no, 
CASE WHEN T1.QSALES <> 0 THEN 'I' ELSE 'C' END AS Type,
(sum(t1.qsales) + -1*sum(t1.qreturns)) QTY,
yyyymmdd as DateShipped,
DateOrdered as DateOrdered,
location,
(select week from #weeks2 t2 WHERE t1.DateOrdered between startdate and enddate) Week,
case WHEN (Asales > 0 and USER_CATEGORY IN ('DO','RX-RB','ST-CL','ST-PR','ST-RB')) OR (areturns>0 and orig_return_code like '04%') THEN 'EXC' 
WHEN orig_return_code = '' then ''
ELSE '' end as EXC,
user_category, return_code, orig_return_code, 'S' as Loc
FROM cvo_sbm_details (nolock) T1
WHERE DateOrdered >= (Select MIN(startdate) From #weeks)  and location in (select * from DPR_locations)
GROUP BY T1.PART_NO, QSALES, YYYYMMDD, DateOrdered, location, return_code, user_category, orig_return_code, asales,areturns
UNION ALL
-- OPEN
select t1.part_no, 
CASE WHEN T1.QSALES <> 0 THEN 'I' ELSE 'C' END AS Type,
(sum(t1.qsales) + -1*sum(t1.qreturns)) QTY,
DateShipped,
DateOrdered as DateOrdered,
location,
(select week from #weeks2 t2 WHERE t1.DateOrdered between startdate and enddate) Week,
'' AS EXC,
user_category, return_code, orig_return_code, 'o' as Loc
FROM #OPENORDS (nolock) T1
WHERE location in (select * from DPR_locations)
GROUP BY T1.PART_NO, QSALES, DateShipped, DateOrdered, location, Exc, user_category, return_code, orig_return_code
)tmp
/*
select * from #history  where loc='o'
select * from #history  where part_no='ETNARGOL5117'
select sum(qty) from #history  where part_no='ETIRSBRO4716' and exc=''
*/


-- PULL FIRST 11 WEEKS ACTUAL
IF(OBJECT_ID('tempdb.dbo.#ALLDATA') is not null)     drop table #ALLDATA
SELECT * INTO #ALLDATA FROM (
SELECT DISTINCT ISNULL([category:1],'NOHS')Category, ISNULL(SUNPS,'')SUNPS, T1.PART_NO,
CAST(ISNULL((select SUM(QTY) FROM #HISTORY T12 WHERE T1.PART_NO=T12.PART_NO AND T1.LOCATION=T12.LOCATION AND EXC=''
AND DateOrdered between DATEADD(MS,+3,DATEADD(dd,-7,@EndOfPrevWeek)) AND @EndOfPrevWeek),0)AS decimal(4,0)) as ActW1,
CAST(ISNULL((select SUM(QTY) FROM #HISTORY T12 WHERE T1.PART_NO=T12.PART_NO AND T1.LOCATION=T12.LOCATION AND EXC=''
AND DateOrdered between DATEADD(MS,+3,DATEADD(dd,-14,@EndOfPrevWeek)) AND dateadd(dd,-7,@EndOfPrevWeek)),0)AS decimal(4,0)) as ActW2,
CAST(ISNULL((select SUM(QTY) FROM #HISTORY T12 WHERE T1.PART_NO=T12.PART_NO AND T1.LOCATION=T12.LOCATION  AND EXC=''
AND DateOrdered between DATEADD(MS,+3,DATEADD(dd,-21,@EndOfPrevWeek)) AND dateadd(dd,-14,@EndOfPrevWeek)),0)AS decimal(4,0)) as ActW3,
CAST(ISNULL((select SUM(QTY) FROM #HISTORY T12 WHERE T1.PART_NO=T12.PART_NO AND T1.LOCATION=T12.LOCATION  AND EXC=''
AND DateOrdered between DATEADD(MS,+3,DATEADD(dd,-28,@EndOfPrevWeek)) AND dateadd(dd,-21,@EndOfPrevWeek)),0)AS decimal(4,0)) as ActW4,
CAST(ISNULL((select SUM(QTY) FROM #HISTORY T12 WHERE T1.PART_NO=T12.PART_NO AND T1.LOCATION=T12.LOCATION  AND EXC=''
AND DateOrdered between DATEADD(MS,+3,DATEADD(dd,-35,@EndOfPrevWeek)) AND dateadd(dd,-28,@EndOfPrevWeek)),0)AS decimal(4,0)) as ActW5,
CAST(ISNULL((select SUM(QTY) FROM #HISTORY T12 WHERE T1.PART_NO=T12.PART_NO AND T1.LOCATION=T12.LOCATION  AND EXC=''
AND DateOrdered between DATEADD(MS,+3,DATEADD(dd,-42,@EndOfPrevWeek)) AND dateadd(dd,-35,@EndOfPrevWeek)),0)AS decimal(4,0)) as ActW6,
CAST(ISNULL((select SUM(QTY) FROM #HISTORY T12 WHERE T1.PART_NO=T12.PART_NO AND T1.LOCATION=T12.LOCATION  AND EXC=''
AND DateOrdered between DATEADD(MS,+3,DATEADD(dd,-49,@EndOfPrevWeek)) AND dateadd(dd,-42,@EndOfPrevWeek)),0)AS decimal(4,0)) as ActW7,
CAST(ISNULL((select SUM(QTY) FROM #HISTORY T12 WHERE T1.PART_NO=T12.PART_NO AND T1.LOCATION=T12.LOCATION  AND EXC=''
AND DateOrdered between DATEADD(MS,+3,DATEADD(dd,-56,@EndOfPrevWeek)) AND dateadd(dd,-49,@EndOfPrevWeek)),0)AS decimal(4,0)) as ActW8,
CAST(ISNULL((select SUM(QTY) FROM #HISTORY T12 WHERE T1.PART_NO=T12.PART_NO AND T1.LOCATION=T12.LOCATION  AND EXC=''
AND DateOrdered between DATEADD(MS,+3,DATEADD(dd,-63,@EndOfPrevWeek)) AND dateadd(dd,-56,@EndOfPrevWeek)),0)AS decimal(4,0)) as ActW9,
CAST(ISNULL((select SUM(QTY) FROM #HISTORY T12 WHERE T1.PART_NO=T12.PART_NO AND T1.LOCATION=T12.LOCATION  AND EXC=''
AND DateOrdered between DATEADD(MS,+3,DATEADD(dd,-70,@EndOfPrevWeek)) AND dateadd(dd,-63,@EndOfPrevWeek)),0)AS decimal(4,0)) as ActW10,
CAST(ISNULL((select SUM(QTY) FROM #HISTORY T12 WHERE T1.PART_NO=T12.PART_NO AND T1.LOCATION=T12.LOCATION  AND EXC=''
AND DateOrdered between DATEADD(MS,+3,DATEADD(dd,-77,@EndOfPrevWeek)) AND dateadd(dd,-70,@EndOfPrevWeek)),0)AS decimal(4,0)) as ActW11,

CAST(ISNULL((select SUM(QTY) FROM #HISTORY T12 WHERE T1.PART_NO=T12.PART_NO AND T1.LOCATION=T12.LOCATION AND EXC='' AND WEEK IN (4))/4,0)AS decimal(4,0)) as wk4,
CAST(ISNULL((select SUM(QTY) FROM #HISTORY T12 WHERE T1.PART_NO=T12.PART_NO AND T1.LOCATION=T12.LOCATION AND EXC='' AND WEEK IN (4,12))/12,0)AS decimal(4,0)) as wk12,
CAST(ISNULL((select SUM(QTY) FROM #HISTORY T12 WHERE T1.PART_NO=T12.PART_NO AND T1.LOCATION=T12.LOCATION AND EXC='' AND WEEK IN (4,12,26))/26,0)AS decimal(4,0)) as wk26,
CAST(ISNULL((select SUM(QTY) FROM #HISTORY T12 WHERE T1.PART_NO=T12.PART_NO AND T1.LOCATION=T12.LOCATION AND EXC='' AND WEEK IN (4,12,26,52))/52,0)AS decimal(4,0)) as wk52,
T1.LOCATION,
'EXC' AS TYPE
 FROM #HISTORY T1
 JOIN DRP_DATA T2 ON T1.PART_NO=T2.PART_NO AND T1.LOCATION=T2.LOCATION
 left outer join cvo_hs_inventory_Everything t3 on t1.part_no=t3.SKU
UNION ALL
SELECT DISTINCT ISNULL([category:1],'NOHS')Category, ISNULL(SUNPS,'')SUNPS, T1.PART_NO,
CAST(ISNULL((select SUM(QTY) FROM #HISTORY T12 WHERE T1.PART_NO=T12.PART_NO AND T1.LOCATION=T12.LOCATION 
AND DateOrdered between DATEADD(MS,+3,DATEADD(dd,-7,@EndOfPrevWeek)) AND @EndOfPrevWeek),0)AS decimal(4,0)) as ActW1,
CAST(ISNULL((select SUM(QTY) FROM #HISTORY T12 WHERE T1.PART_NO=T12.PART_NO AND T1.LOCATION=T12.LOCATION 
AND DateOrdered between DATEADD(MS,+3,DATEADD(dd,-14,@EndOfPrevWeek)) AND dateadd(dd,-7,@EndOfPrevWeek)),0)AS decimal(4,0)) as ActW2,
CAST(ISNULL((select SUM(QTY) FROM #HISTORY T12 WHERE T1.PART_NO=T12.PART_NO AND T1.LOCATION=T12.LOCATION 
AND DateOrdered between DATEADD(MS,+3,DATEADD(dd,-21,@EndOfPrevWeek)) AND dateadd(dd,-14,@EndOfPrevWeek)),0)AS decimal(4,0)) as ActW3,
CAST(ISNULL((select SUM(QTY) FROM #HISTORY T12 WHERE T1.PART_NO=T12.PART_NO AND T1.LOCATION=T12.LOCATION 
AND DateOrdered between DATEADD(MS,+3,DATEADD(dd,-28,@EndOfPrevWeek)) AND dateadd(dd,-21,@EndOfPrevWeek)),0)AS decimal(4,0)) as ActW4,
CAST(ISNULL((select SUM(QTY) FROM #HISTORY T12 WHERE T1.PART_NO=T12.PART_NO AND T1.LOCATION=T12.LOCATION 
AND DateOrdered between DATEADD(MS,+3,DATEADD(dd,-35,@EndOfPrevWeek)) AND dateadd(dd,-28,@EndOfPrevWeek)),0)AS decimal(4,0)) as ActW5,
CAST(ISNULL((select SUM(QTY) FROM #HISTORY T12 WHERE T1.PART_NO=T12.PART_NO AND T1.LOCATION=T12.LOCATION 
AND DateOrdered between DATEADD(MS,+3,DATEADD(dd,-42,@EndOfPrevWeek)) AND dateadd(dd,-35,@EndOfPrevWeek)),0)AS decimal(4,0)) as ActW6,
CAST(ISNULL((select SUM(QTY) FROM #HISTORY T12 WHERE T1.PART_NO=T12.PART_NO AND T1.LOCATION=T12.LOCATION 
AND DateOrdered between DATEADD(MS,+3,DATEADD(dd,-49,@EndOfPrevWeek)) AND dateadd(dd,-42,@EndOfPrevWeek)),0)AS decimal(4,0)) as ActW7,
CAST(ISNULL((select SUM(QTY) FROM #HISTORY T12 WHERE T1.PART_NO=T12.PART_NO AND T1.LOCATION=T12.LOCATION 
AND DateOrdered between DATEADD(MS,+3,DATEADD(dd,-56,@EndOfPrevWeek)) AND dateadd(dd,-49,@EndOfPrevWeek)),0)AS decimal(4,0)) as ActW8,
CAST(ISNULL((select SUM(QTY) FROM #HISTORY T12 WHERE T1.PART_NO=T12.PART_NO AND T1.LOCATION=T12.LOCATION
AND DateOrdered between DATEADD(MS,+3,DATEADD(dd,-63,@EndOfPrevWeek)) AND dateadd(dd,-56,@EndOfPrevWeek)),0)AS decimal(4,0)) as ActW9,
CAST(ISNULL((select SUM(QTY) FROM #HISTORY T12 WHERE T1.PART_NO=T12.PART_NO AND T1.LOCATION=T12.LOCATION
AND DateOrdered between DATEADD(MS,+3,DATEADD(dd,-70,@EndOfPrevWeek)) AND dateadd(dd,-63,@EndOfPrevWeek)),0)AS decimal(4,0)) as ActW10,
CAST(ISNULL((select SUM(QTY) FROM #HISTORY T12 WHERE T1.PART_NO=T12.PART_NO AND T1.LOCATION=T12.LOCATION
AND DateOrdered between DATEADD(MS,+3,DATEADD(dd,-77,@EndOfPrevWeek)) AND dateadd(dd,-70,@EndOfPrevWeek)),0)AS decimal(4,0)) as ActW11,

CAST(ISNULL((select SUM(QTY) FROM #HISTORY T12 WHERE T1.PART_NO=T12.PART_NO AND T1.LOCATION=T12.LOCATION AND WEEK IN (4))/4,0)AS decimal(4,0)) as wk4,
CAST(ISNULL((select SUM(QTY) FROM #HISTORY T12 WHERE T1.PART_NO=T12.PART_NO AND T1.LOCATION=T12.LOCATION AND WEEK IN (4,12))/12,0)AS decimal(4,0)) as wk12,
CAST(ISNULL((select SUM(QTY) FROM #HISTORY T12 WHERE T1.PART_NO=T12.PART_NO AND T1.LOCATION=T12.LOCATION AND WEEK IN (4,12,26))/26,0)AS decimal(4,0)) as wk26,
CAST(ISNULL((select SUM(QTY) FROM #HISTORY T12 WHERE T1.PART_NO=T12.PART_NO AND T1.LOCATION=T12.LOCATION AND WEEK IN (4,12,26,52))/52,0)AS decimal(4,0)) as wk52,
T1.LOCATION,
'ALL' AS TYPE
 FROM #HISTORY T1
 JOIN DRP_DATA T2 ON T1.PART_NO=T2.PART_NO AND T1.LOCATION=T2.LOCATION
 left outer join cvo_hs_inventory_Everything t3 on t1.part_no=t3.SKU )tmp
ORDER BY part_no, LOCATION, TYPE
-- select * from #history where part_no='BC804HOR5818'
-- select * from #AllData where part_no='BC804HOR5818'

-- -- -- 
IF(OBJECT_ID('tempdb.dbo.#RelDateRev') is not null)     drop table #RelDateRev
select * into #RelDateRev from (
select I.part_no, field_26 as RelDate,
CASE WHEN FIELD_26 < '1/1/2009' then FIELD_26
WHEN field_26 <='1/15/2012'
THEN isnull((select top 1 date_entered from cvo_orders_all_hist O join cvo_ord_list_hist OL on o.order_no=ol.order_no and o.ext=ol.order_ext where IA.part_no=OL.Part_no order by date_entered asc ), FIELD_26)
WHEN field_26 > '1/15/2012' 
THEN ISNULL((select top 1 date_entered from orders_all O join ord_list OL on o.order_no=ol.order_no and o.ext=ol.order_ext where IA.part_no=OL.Part_no order by date_entered asc ),FIELD_26)
ELSE field_26 END AS AdjRel_1stOrd
from inv_master_add (nolock) IA
JOIN inv_master I on I.part_no=ia.part_no
Where type_code in ('sun','frame') 
) tmp
Order by Part_no
-- select * from #RelDateRev where part_no = 'ETNARGOL5117'

-- -- -- 

IF(OBJECT_ID('tempdb.dbo.#ALLDATA2') is not null)     drop table #ALLDATA2
SELECT Category, SUNPS, t1.PART_NO,
ActW1, ActW2, ActW3, ActW4, ActW5, ActW6, ActW7, ActW8, ActW9, ActW10, ActW11, 

(Coalesce(ActW1,0) + Coalesce(ActW2,0) + Coalesce(ActW3,0) + Coalesce(ActW4,0) + Coalesce(ActW5,0) + Coalesce(ActW6,0) + Coalesce(ActW7,0) + Coalesce(ActW8,0) + Coalesce(ActW9,0) + Coalesce(ActW10,0) + Coalesce(ActW11,0) )SubTotal,
Case
When AdjRel_1stOrd  between DATEADD(MS,+3,DATEADD(dd,-77,@EndOfPrevWeek)) AND dateadd(dd,-70,@EndOfPrevWeek)then 11
When AdjRel_1stOrd  between DATEADD(MS,+3,DATEADD(dd,-70,@EndOfPrevWeek)) AND dateadd(dd,-63,@EndOfPrevWeek)then 10
When AdjRel_1stOrd  between DATEADD(MS,+3,DATEADD(dd,-63,@EndOfPrevWeek)) AND dateadd(dd,-56,@EndOfPrevWeek)then 9
When AdjRel_1stOrd  between DATEADD(MS,+3,DATEADD(dd,-56,@EndOfPrevWeek)) AND dateadd(dd,-49,@EndOfPrevWeek)then 8
When AdjRel_1stOrd  between DATEADD(MS,+3,DATEADD(dd,-49,@EndOfPrevWeek)) AND dateadd(dd,-42,@EndOfPrevWeek)then 7
When AdjRel_1stOrd  between DATEADD(MS,+3,DATEADD(dd,-42,@EndOfPrevWeek)) AND dateadd(dd,-35,@EndOfPrevWeek)then 6
When AdjRel_1stOrd  between DATEADD(MS,+3,DATEADD(dd,-35,@EndOfPrevWeek)) AND dateadd(dd,-28,@EndOfPrevWeek)then 5
When AdjRel_1stOrd  between DATEADD(MS,+3,DATEADD(dd,-28,@EndOfPrevWeek)) AND dateadd(dd,-21,@EndOfPrevWeek)then 4
When AdjRel_1stOrd  between DATEADD(MS,+3,DATEADD(dd,-21,@EndOfPrevWeek)) AND dateadd(dd,-14,@EndOfPrevWeek)then 3
When AdjRel_1stOrd  between DATEADD(MS,+3,DATEADD(dd,-14,@EndOfPrevWeek)) AND dateadd(dd,-7,@EndOfPrevWeek)then 2
When AdjRel_1stOrd  between DATEADD(MS,+3,DATEADD(dd,-7,@EndOfPrevWeek)) AND @EndOfPrevWeek then 1
Else 999 End as NumWks, AdjRel_1stOrd, @EndOfPrevWeek as EndOfPrevWeek,
wk4, wk12, wk26, wk52, LOCATION, TYPE
INTO #ALLDATA2
FROM #ALLDATA T1
join #RelDateRev t2 on t1.part_no=t2.part_no

-- Style 30 Day & 90 Day Units Sold -- Ranking 30 day & 90 Day
IF(OBJECT_ID('tempdb.dbo.#StyleUR') is not null)     drop table #StyleUR
select * INTO #StyleUR from (
select category as Collection, field_2 as Style, sum(qnet)Sold, 30 as UnitsSold,
Rank() OVER (PARTITION by category order by sum(qnet) DESC) as Ranking
 from cvo_sbm_details t1
join inv_master I on t1.part_no=I.part_no
join inv_master_add IA on i.part_no=ia.part_no
where type_code in ('sun','frame') and yyyymmdd between dateadd(d,-30,getdate()) and getdate()
group by category, field_2
UNION ALL 
select category, field_2, sum(qnet)Sold, 90 as UnitsSold,
Rank() OVER (PARTITION by category order by sum(qnet) DESC) as Ranking
 from cvo_sbm_details t1
join inv_master I on t1.part_no=I.part_no
join inv_master_add IA on i.part_no=ia.part_no
where type_code in ('sun','frame') and  yyyymmdd between dateadd(d,-90,getdate()) and getdate()
group by category, field_2 ) tmp
order by Collection, Style
--  select * from #StyleUR
-- select * from #invinfo


-- -- --

IF(OBJECT_ID('DRP_DATA_NEW') is not null)     drop table DRP_DATA_NEW
SELECT i.part_no, i.location, Collection, Style, description, i.ReleaseDate, POM, Watch, Status, Vendor, CntryOfOrgin, LeadTime, Type_code, Part_type, Material, Gender, PartLeadTime, FCost, LCost,
ISNULL((select Sold from #StyleUR t1 where UnitsSold=30 and t1.collection=I.collection and t1.Style=I.Style),0)[1MSold],
ISNULL((select Sold from #StyleUR t1 where UnitsSold=90 and t1.collection=I.collection and t1.Style=I.Style),0)[3MSold],
ISNULL((select Ranking from #StyleUR t1 where UnitsSold=30 and t1.collection=I.collection and t1.Style=I.Style),0)[1MRank],
ISNULL((select Ranking from #StyleUR t1 where UnitsSold=90 and t1.collection=I.collection and t1.Style=I.Style),0)[3MRank],
ISNULL((select MAX(Ranking) from #StyleUR t1 where UnitsSold=30 and t1.collection=I.collection),0)[1MRankMax],
ISNULL((select MAX(Ranking) from #StyleUR t1 where UnitsSold=90 and t1.collection=I.collection),0)[3MRankMax],
ISNULL(ActW1, 0)ActW1, ISNULL(ActW2, 0)ActW2, ISNULL(ActW3, 0)ActW3, ISNULL(ActW4, 0)ActW4, ISNULL(ActW5, 0)ActW5, ISNULL(ActW6, 0)ActW6, ISNULL(ActW7, 0)ActW7, ISNULL(ActW8, 0)ActW8, ISNULL(ActW9, 0)ActW9, ISNULL(ActW10, 0)ActW10, ISNULL(ActW11, 0)ActW11,
ISNULL(SubTotal,0)SubTotal, 
CASE WHEN (select sum(Subtotal) from #AllData2 T2 where d.part_no=t2.part_no and d.location=t2.location and t2.type='ALL') <> (select sum(Subtotal) from #AllData2 T2 where d.part_no=t2.part_no and d.location=t2.location and t2.type='EXC') THEN 'DIFF' ELSE '' END AS TypeDiff,
ISNULL(NumWks,0)NumWks, case when Numwks = 0 OR NumWks IS NULL then 0 else (Subtotal/Numwks) end as AvgWk,
 ISNULL(AdjRel_1stOrd,0)AdjRel_1stOrd,
ISNULL(wk4,0)wk4,
ISNULL(wk12,0)wk12,
ISNULL(wk26,0)wk26,
ISNULL(wk52,0)wk52,
ISNULL(TYPE,'ALL')TYPE,

'-99' as av20end, 99 as e12_WU, 199 as e24_WU, 299 as e52_WU

INTO DRP_DATA_NEW
FROM #ALLDATA2 D
FULL OUTER JOIN #InvInfo I on D.part_no=I.part_no and D.location=I.location
oRDER BY I.PART_NO, i.LOCATION

-- EXEC CVO_DRP_NEW_SSRS_SP 
/*

select * from drp_data_new   order by Collection, Style, part_no

select * from drp_data_new   where ActW1 <> 0
*/
END

GO
