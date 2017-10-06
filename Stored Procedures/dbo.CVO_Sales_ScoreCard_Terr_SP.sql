SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		tine graziosi
-- Create date: 122014
-- Description:	Sales Territory/Salesperson ScoreCard (also for NSM  AWARDS)
-- EXEC CVO_Sales_ScoreCard_terr_SP '1/1/2016', '04/01/2016'
-- 7/29/2015 - new counts for retention pcts
-- =============================================
CREATE PROCEDURE [dbo].[CVO_Sales_ScoreCard_Terr_SP]

@DF datetime,
@DT datetime
--,@Terr varchar(1024) = null

AS
BEGIN
	SET NOCOUNT ON;
	SET ANSI_WARNINGS OFF;



declare @DateFrom datetime,
@DateTo datetime,
@Territory varchar(1024) 

-- uncomment for testing
--DECLARE @DF datetime, @DT datetime
--select @df = '01/01/2017', @dt = '09/29/2017'

SELECT @datefrom = @df, @dateto = @dt, @territory = null

IF(OBJECT_ID('tempdb.dbo.#Territory') is not null)  drop table dbo.#Territory

--declare @Territory varchar(1000)
--select  @Territory = null

create table #territory (territory varchar(8))

if @Territory is null
begin
 insert into #territory (territory)
 select distinct territory_code from armaster (nolock)
end
else
begin
 insert into #territory (territory)
 select listitem from dbo.f_comma_list_to_table(@Territory)
end

--Declare @DateFrom datetime
--Declare @DateTo datetime
--Set @DateFrom = '12/1/2013'
--Set @DateTo = '11/30/2014'
	Set @DateTo = DateAdd(Second, -1, DateAdd(D,1,@DateTo))
--  select @DateFrom, @DateTo, (dateadd(day,-1,dateadd(year,1,@DateFrom))), dateadd(year,-1,@DateFrom) , dateadd(day,-1,@DateFrom)

Declare @DateFromly datetime, @DateToly datetime
select @datefromly = dateadd(year,-1, @datefrom)
	 , @datetoly = dateadd(year,-1, @dateto)

declare @minBrandSales decimal(20,8), @numbrands int
select @minBrandSales = 750, @numbrands = 4

-- PULL ALL Territories
IF(OBJECT_ID('tempdb.dbo.#Terrs') is not null)  drop table dbo.#Terrs
select distinct 
dbo. calculate_Region_fn(armaster.territory_code)  as Region
,armaster.Territory_code as Terr
INTO #TERRS 
from #territory 
inner join ARmaster (NOLOCK) on armaster.territory_code = #territory.territory
WHERE armaster.Territory_code not like '%00' order by armaster.Territory_code
-- select * from #Terrs

-- BUILD REP DATA
IF(OBJECT_ID('tempdb.dbo.#Slp') is not null)  drop table dbo.#Slp
SELECT dbo.calculate_Region_fn(#territory.territory) Region
, #territory.Territory as Terr
, REPLACE(Salesperson_name,'DEFAULT','') as Salesperson
, ISNULL(date_of_hire,'1/1/1950') date_of_hire, 
CASE WHEN date_of_hire between @DateFrom and dateadd(day,-1,dateadd(year,1,@DateFrom)) 
		THEN datepart(year,dateadd(day,-1,dateadd(year,1,@DateFrom)))
	WHEN date_of_hire between dateadd(year,-1,@DateFrom) and dateadd(day,-1,@DateFrom) 	
		THEN datepart(year,dateadd(day,-1,@DateFrom))
	ELSE ISNULL(DATEPART(YEAR,DATE_OF_HIRE),datepart(year,dateadd(day,-1,@DateFrom))) 
	END AS ClassOf, 
CASE WHEN date_of_hire between @DateFrom and (dateadd(day,-1,dateadd(year,1,@DateFrom))) THEN 'Newbie'
	WHEN date_of_hire between dateadd(year,-1,@DateFrom) and dateadd(day,-1,@DateFrom) THEN 'Rookie'
	WHEN Salesperson_name like '%DEFAULT%' or Salesperson_name like '%COMPANY%' THEN 'Empty' 
	WHEN date_of_hire > @DateFrom  THEN 'Newbie'
	ELSE 'Veteran' end as Status
, isnull(x.prescouncil,0) PC
INTO #Slp
FROM #territory
inner join arsalesp on arsalesp.territory_code = #territory.territory
inner join cvo_territoryxref x on  #territory.territory = cast(x.territory_code as varchar(8))
Where Status_type = 1 and #territory.Territory not like '%00' 
	and Salesperson_name not in ('Marcella Smith', 'Alanna Martin') order by Territory
--  select * from #Slp

IF(OBJECT_ID('tempdb.dbo.#SlpInfo') is not null)  drop table dbo.#SlpInfo
select t1.Region, t1.Terr, 
ISNULL((select Top 1 Salesperson from #SLP t2 where t1.terr=t2.terr),(Terr+' DEFAULT')) as Salesperson,
ISNULL((select Top 1 date_of_hire from #SLP t2 where t1.terr=t2.terr),'1/1/1950') as date_of_hire,
ISNULL((select Top 1 ClassOf from #SLP t2 where t1.terr=t2.terr),'1950') as ClassOf,
ISNULL((select Top 1 Status from #SLP t2 where t1.terr=t2.terr),'Empty') as Status,
ISNULL((select Top 1 pc from #SLP t2 where t1.terr=t2.terr),0) as PC
, 0 as top9
-- , cast(0 as decimal(20,8)) as netty

INTO #SlpInfo from #Terrs t1
Where T1.Region is not null
-- select * from #SLPInfo

IF(OBJECT_ID('tempdb.dbo.#salesdata') is not null)  drop table dbo.#salesdata
IF(OBJECT_ID('tempdb.dbo.#brands') is not null)  drop table dbo.#brands
IF(OBJECT_ID('tempdb.dbo.#active') is not null)  drop table dbo.#active
IF(OBJECT_ID('tempdb.dbo.#door500') is not null)  drop table dbo.#door500

select ar.territory_code terr
, ar.customer_code customer
, ship_to_code = case when car.door = 0 then '' else ar.ship_to_code end
--, address_name = case when car.door = 1 then ar.address_name 
--		else (select customer_name from arcust (nolock) where customer_code = ar.customer_code) end 
--, car.door
, i.category brand
, sum(CASE WHEN sbm.yyyymmdd >= @datefrom THEN ISNULL(sbm.anet,0) ELSE 0 end) net_sales_ty
, SUM(CASE WHEN sbm.yyyymmdd <= @datetoly THEN ISNULL(sbm.anet,0) ELSE 0 end) net_sales_ly
into #salesdata
from #territory
inner join armaster ar (nolock) on ar.territory_code = #territory.territory
inner join cvo_armaster_all car (nolock) on car.customer_code = ar.customer_code and car.ship_to = ar.ship_to_code
inner join cvo_sbm_details sbm (nolock) on  sbm.customer = ar.customer_code  and sbm.ship_to = ar.ship_to_code 
inner join inv_master i (nolock) on  i.part_no  = sbm.part_no 
inner join inv_master_add ia (nolock) on ia.part_no = i.part_no
where 1=1
and (sbm.yyyymmdd between @datefrom and @dateto
or sbm.yyyymmdd between @datefromly and @DateToly)

GROUP by ar.territory_code, ar.customer_code, 
	case when car.door = 0 then '' else ar.ship_to_code end
	,  i.category

-- get rid of any rolled up customers not in this territory (i.e. 030774)
update s set terr = ar.territory_code
from #salesdata s
inner join armaster ar (nolock)
	on ar.customer_code = s.customer 
	and ar.ship_to_code = s.ship_to_code

delete from #salesdata
where not exists (select 1 from #territory where territory = #salesdata.terr)	

 -- select * from #salesdata

select terr, right(customer,5) customer, ship_to_code
--, address_name
, sum(net_sales_ty) net_sales
, SUM(net_sales_ly) net_sales_ly
into #active
from #salesdata
--where door = 1 
group by terr, right(customer,5) , ship_to_code
-- , address_name
having (sum(net_sales_ty) > 2400 and sum(net_sales_ty) > 0)
or (SUM(net_sales_ly) > 2400 AND SUM(net_sales_ly) > 0)

-- select * from #active

select terr, right(customer,5) customer, ship_to_code
--, address_name
, sum(net_sales_ty) net_sales
, sum(net_sales_ly) net_sales_ly
into #door500
from #salesdata
--where door = 1 
group by terr, right(customer,5) , ship_to_code
--, address_name
having ( sum(net_sales_ty) >= 500 and sum(net_sales_ty) > 0)
or ( SUM(net_sales_ly) >= 500  and sum(net_sales_ly) > 0)

;with brands as 
(select terr, right(customer,5) customer, ship_to_code
--, address_name
, brand, sum(net_sales_ty) net_sales
from #salesdata
--where door = 1
group by terr, right(customer,5) , ship_to_code
--, address_name
, brand
having @minbrandsales <=  sum(net_sales_ty) and sum(net_sales_ty) > 0.00
)
select terr, customer, ship_to_code
-- , address_name
, count(distinct brand) num_brands
into #brands
from brands
group by terr, customer, ship_to_code
--, address_name
having @numBrands <= count(distinct brand)

--select * from #salesdata where terr = 20225 order by customer

--select * from #brands where terr = 20225

-- BUILD PROGRAMS SUB REPORT
IF(OBJECT_ID('tempdb.dbo.#ProgramData') is not null)  drop table #ProgramData
IF(OBJECT_ID('tempdb.dbo.#Progsummary') is not null)  drop table #Progsummary
SELECT t.territory, o.order_no, o.ext, 
o.promo_id, o.promo_level, 
CASE WHEN ISNULL(p.season_program,0) = 1 THEN 'S' WHEN ISNULL(p.annual_program,0) = 1 THEN 'A' ELSE 'Z' END ProgType,
o.total_invoice
into #programdata
FROM  #territory t 
inner join cvo_adord_vw o (nolock) on t.territory = o.territory
JOIN cvo_promotions p ON p.promo_id = o.promo_id AND p.promo_level = o.promo_level
where 1=1
and isnull(o.promo_id,'') <> '' -- 10/31/2013
AND o.date_entered between @Datefrom and @dateto
AND ((o.who_entered <> 'backordr' and o.ext = 0) or o.who_entered = 'outofstock') 
-- AND o.who_entered <> 'backordr' 
and o.status <> 'V' 
and not exists (select 1 from cvo_promo_override_audit poa 
					where poa.order_no = o.order_no 
					and poa.order_ext = o.ext) 
and not exists (select 1 from orders r (nolock) 
					where r.total_invoice = o.total_invoice
					and r.orig_no = o.order_no and r.orig_ext = o.ext 
					and r.status = 't' and r.type = 'c')
					

UPDATE #programdata SET progtype = 'X' 
WHERE promo_id  IN ('pc','ff','rxe','rx1') 
	OR promo_level IN ('rx','try','free','pc')
	OR (promo_id = 've aspire' AND promo_level = 'custom')


-- select promo_id, promo_level, progtype, count(order_no) from #ProgramData group by promo_id, promo_level, progtype

select pd.territory
-- ,AnnualProg = sum(case when promo_id in ('AAP','APR','BEP','RCP','ROT64','FOD','SS','award') then 1 else 0 end)
,AnnualProg = SUM(CASE WHEN pd.progtype = 'A' THEN 1 ELSE 0 end)
--,SeasonalProg = sum(case when promo_id IN
-- ('ASPIRE','BOGO','DOR','ME','PURITI','IZOD','KIDS','SUN','sunps','ar','CH','CVO','BCBG', 'ET','SUN SPRING','IZOD CLEAR'
-- ,'BLUE','JMC','REVO') then 1 else 0 end)
,SeasonalProg = SUM(CASE WHEN pd.progtype = 'S' THEN 1 ELSE 0 end)
,rxeprog = sum(case when pd.promo_id in ('rxe') then 1 else 0 end)
,aspireprog = SUM(CASE WHEN pd.promo_id IN ('aspire') THEN 1 ELSE 0 END)
into #progsummary
from #programdata pd
group by pd.territory


-- BUILD STOCK ORDERS SUB REPORT


-- -- # STOCK ORDERS PER MONTH  
-- PULL DATA FOR ST SHIPPED ORDERS / CREDITS OVER 5PCS
IF(OBJECT_ID('tempdb.dbo.#Invoices') is not null)  drop table #Invoices
-- Orders
SELECT o.TYPE, 
o.status, car.DOOR,
ar.territory_code, 
CUST_CODE,
ship_to = case when car.door = 1 then o.SHIP_TO else '' end,
cust_key = cust_code + case when car.door = 1 then o.SHIP_TO else '' end, 
Promo_ID, 
user_category, o.ORDER_NO, o.ext, 
QTY = sum(ol.qty),
sum(total_amt_order-total_discount) ord_value,
ADDED_BY_DATE,
o.date_entered,
dateadd(day, datediff(day,0, o.date_shipped), 0) date_shipped,
dateadd(mm, datediff(month, 0 , o.date_shipped), 0) period, 
month(date_shipped) as X_MONTH

into #invoices

FROM #territory
JOIN ARMASTER (NOLOCK) ar on #territory.territory = ar.territory_code
inner JOIN CVO_ARMASTER_ALL (NOLOCK) car ON car.CUSTomer_CODE=ar.CUSTOMER_CODE AND car.SHIP_TO=ar.SHIP_TO_code
inner join ORDERS_ALL (NOLOCK) o ON o.CUST_CODE=ar.CUSTOMER_CODE AND o.SHIP_TO=ar.SHIP_TO_CODE
inner JOIN cvo_orders_all (NOLOCK) co ON o.ORDER_NO = co.ORDER_NO AND o.EXT=co.EXT
-- inner JOIN ORD_LIST (NOLOCK) ol ON o.ORDER_NO = ol.ORDER_NO AND o.EXT=ol.ORDER_EXT
-- inner join inv_master (nolock) i on ol.part_no=i.part_no
inner join
(select ol.order_no, ol.order_ext, sum(ol.shipped) qty from ord_list ol (nolock)
inner join inv_master (nolock) i on ol.part_no=i.part_no
where type_code in ('frame','sun')
group by order_no, order_ext ) as ol on ol.order_no = o.order_no and ol.order_ext = o.ext

where o.status = 't'
and o.date_shipped <= @dateto
AND TYPE='I'
and o.who_entered <> 'backordr'
-- and type_code in('sun','frame')
and user_category like 'ST%' and right(user_category,2) not in ('RB','TB')
-- and (total_amt_order - total_discount) <> 0 
-- and user_category not in ( 'ST-RB', 'DO')
GROUP BY ar.territory_code, DOOR, CUST_CODE, o.SHIP_TO, co.PROMO_ID, user_category, 
o.ORDER_NO, o.ext, o.STATUS, o.TYPE, ADDED_BY_DATE, date_entered, date_shipped

-- credits
insert into #invoices
SELECT o.TYPE, 
o.status, 
car.DOOR,
ar.territory_code, 
CUST_CODE, 
ship_to = case when car.door = 1 then o.SHIP_TO else '' end, 
cust_key = cust_code + case when car.door = 1 then o.SHIP_TO else '' end, 
Promo_ID, 
user_category, o.ORDER_NO, o.ext, 
QTY = -1*sum(ol.qty),
-1*sum(total_amt_order-total_discount) ord_value,
ADDED_BY_DATE,
o.date_entered,
dateadd(day, datediff(day,0, o.date_shipped), 0) date_shipped,
dateadd(mm, datediff(month, 0 , o.date_shipped), 0) period, 
month(date_shipped) as X_MONTH
FROM #territory
JOIN ARMASTER (NOLOCK) ar on #territory.territory = ar.territory_code
inner JOIN CVO_ARMASTER_ALL (NOLOCK) car ON car.CUSTomer_CODE=ar.CUSTOMER_CODE AND car.SHIP_TO=ar.SHIP_TO_code
inner join ORDERS_ALL (NOLOCK) o ON o.CUST_CODE=ar.CUSTOMER_CODE AND o.SHIP_TO=ar.SHIP_TO_CODE
inner JOIN cvo_orders_all (NOLOCK) co ON o.ORDER_NO = co.ORDER_NO AND o.EXT=co.EXT
inner JOIN
(select order_no, order_ext, sum(cr_shipped) qty
from ORD_LIST (NOLOCK) ol 
inner join inv_master (nolock) i on ol.part_no=i.part_no
where type_code in('sun','frame')
group by order_no, order_ext ) as ol on ol.order_no = o.order_no and ol.order_ext = o.ext

where o.status = 't'
and o.date_shipped <= @dateto
AND TYPE='C'
and o.who_entered <> 'backordr'

and exists ( select 1 from ord_list ol 
	where ol.order_no = o.order_no and ol.order_ext = o.ext and ol.return_code like '06%')
GROUP BY ar.territory_code, DOOR, CUST_CODE, o.SHIP_TO, co.PROMO_ID, user_category, 
o.ORDER_NO, o.ext, o.STATUS, o.TYPE, ADDED_BY_DATE, date_entered, date_shipped


-- select * from #Invoices   where territory_code = 20299

-- Pull Unique Custs Orders by Month >=5pcs
IF(OBJECT_ID('tempdb.dbo.#InvStCount') is not null)  
drop table #InvStCount
select 
territory_code, 
count(distinct cust_key) STOrds,
sum(isnull(ord_value,0)) ord_value,
X_MONTH
INTO #InvStCount
from #Invoices 
where 1=1
and date_shipped BETWEEN @DateFrom and @DateTo
and (ord_value) <> 0 
group by territory_code, cust_key, X_MONTH
having sum(qty) >= 5
--order by territory_code, X_Month, cust_code
-- select * from #InvStCount order by territory_code, cust_code

-- REACTIVATED -- -- PULL Last & 2nd Last ST Order
IF(OBJECT_ID('tempdb.dbo.#DATA') is not null)  drop table #DATA

Select  t1.territory_code as Territory
, t1.Customer_code, ship_to_code, 
T2.DOOR, added_by_date,
SUM(anet) YTDNET,
-- FirstSTNew
LastST = (SELECT min(date_shipped) FROM #INVOICES inv 
	WHERE Type='i' and QTY >=5 
	and date_shipped >= @datefrom
	AND inv.CUST_CODE=T1.customer_code AND inv.SHIP_TO=T1.SHIP_TO_CODE) ,
-- PrevstNew
[2ndLastST]	= (select MAX(date_shipped) from #INVOICES t11 WHERE Type='i' 
	 and t11.date_shipped <
	  (SELECT min(inv.date_shipped) FROM #INVOICES inv 
		WHERE Type='i' and QTY >=5 
		and date_shipped >= @datefrom 
		AND inv.CUST_CODE=T1.customer_code AND inv.SHIP_TO=T1.SHIP_TO_CODE)
	  and QTY >=5 AND T11.CUST_CODE=T1.customer_code AND T11.SHIP_TO=T1.SHIP_TO_CODE)
INTO #DATA
from armaster t1 (NOLOCK)
join cvo_armaster_all t2 (nolock) on t1.customer_code=t2.customer_code and t1.ship_to_code=t2.ship_to
join cvo_sbm_details t3 on right(t3.customer,5)=right(t1.customer_code,5) and t3.ship_to=t1.ship_to_code
inner join #territory on #territory.territory = t1.territory_code
 WHERE t1.address_type <> 9 and T2.door = 1
-- AND yyyymmdd BETWEEN @DateFrom AND @DateTo
GROUP BY t1.territory_code, t1.customer_code, ship_to_code, t2.door, added_by_date
-- select * from #Data WHERE CUSTOMER_CODE = '047859'
-- select * from #INVOICES WHERE CUST_CODE = '047859' ORDER BY DATE_SHIPPED DESC

IF(OBJECT_ID('tempdb.dbo.#DATA2') is not null)  drop table #DATA2

SELECT T1.Territory ,
       T1.customer_code ,
       T1.ship_to_code ,
       T1.door ,
       T1.added_by_date ,
       T1.YTDNET ,
       T1.LastST ,
       T1.[2ndLastST], 
CASE WHEN DATEDIFF(D,isnull([2ndLastST],lastst),LastST) > 365 AND LastST > @DateFrom 
	AND added_by_date < @DateFrom    
	THEN 'REA' ELSE '' 
	END AS STAT,
CASE WHEN DATEDIFF(D,isnull([2ndLastST],lastst),LastST) > 365 AND LastST > @DateFrom 
	AND added_by_date < @DateFrom  
	THEN ISNULL(Month(LastST),1) else '' 
	end as X_MONTH
INTO #DATA2 FROM #DATA T1 

 -- select stat,* from #Data2 where stat <> ''

-- FINAL FOR ST COUNT & REA COUNT
IF(OBJECT_ID('tempdb.dbo.#STREAD') is not null)  drop table #STREAD
SELECT tmp.Territory ,
       tmp.NumStOrds ,
       tmp.ord_value ,
       tmp.NumRea INTO #STREAD 
FROM (
 select Territory_code as Territory
 , COUNT(STOrds)NumStOrds
 , sum(ord_value) ord_value
 , 0 as NumRea
  from #InvStCount 
  where stOrds <>  0 
  group by Territory_code, X_MONTH
 UNION ALL
 select Territory, 0 as NumStOrds, 0 as ord_value, count(Door)NumRea from #Data2 where 
 STAT='REA' Group by Territory  ) tmp
 Order by Territory
 
IF(OBJECT_ID('tempdb.dbo.#STREA') is not null)  drop table #STREA
Select Territory, SUM(NumStOrds)NumStOrds, sum(ord_value) ord_value, SUM(NumRea)NumRea 
INTO #STREA 
from #STREAD 
group by Territory
-- Select * from #STREA

-- BUILD TERRITORY SALES

IF(OBJECT_ID('tempdb.dbo.#t1') is not null)  drop table #t1

select T.Terr, 
return_code, 
user_category, 
sum(anet) NETTY, 
sum(asales) Gross, 
sum(areturns) Ret,
case when return_code = '' then sum(areturns) end as RetSA,
case when user_category like 'RX%' and right(user_category,2) not in ('RB','TB') then sum(anet) end as RX
into #t1
 from #Terrs T
 left outer join armaster T2 on t.Terr=t2.territory_code
 left outer join cvo_sbm_details t1 on t1.customer=t2.customer_code and t1.ship_to=t2.ship_to_code
 where yyyymmdd between @DateFrom and @DateTo
group by T.Terr, return_code, user_category
order by T.Terr, user_category, return_code

update #slpinfo set #slpinfo.top9  = case when r.top9 <= 9 then 1 else 0 end
-- , #slpinfo.netty = r.netty
from #slpinfo 
 inner join 
 (select rr.terr ,  rr.netty, Row_Number() over ( order by rr.netty desc ) as top9
 from 
 (select #t1.terr, sum(#t1.netty) netty from #t1 
 inner join cvo_territoryxref x on #t1.Terr=cast(x.territory_code as varchar(8))
 inner join #slpinfo s on s.terr = #t1.terr
 where isnull(x.prescouncil,0) = 0 and s.[status] = 'Veteran' and x.[status] = 1
 group by #t1.terr) as rr
 ) as r 
 on r.terr = #slpinfo.terr

-- select * from #slpinfo

-- SELECT * FROM #T1 where Terr in ('40449','30315')

IF(OBJECT_ID('tempdb.dbo.#TerrSales') is not null)  drop table #TerrSales

select T.Terr, 
ISNULL(sum(netty),0) NetSTY, 
ISNULL(g_sales.netsly,0) netsly,
ISNULL(g_sales.netsty_goal,0) netsty_goal,
ISNULL(sum(gross),0) Gross, 
ISNULL(sum(ret),0) Ret, 
ISNULL(sum(retSA),0) RetSa, 
ISNULL(sum(rx),0) RX 
-- add sales goal for the year ending @dateto
, TerrGoal = ISNULL((SELECT SUM(ISNULL(goal_amt,0)) FROM dbo.CVO_Territory_goal g 
					WHERE t.terr = g.territory_code AND g.yyear = YEAR(@dateto)),0)
INTO #TerrSales 
from #Terrs T
left outer join #t1 t1 on T.Terr=T1.Terr
left outer join
(select ar.territory_code
    , SUM(case when yyyymmdd between @datefromly and @datetoly then isnull(ANET,0) else 0 end) netsly
    , SUM(case when yyyymmdd between @datefrom and @dateto 
						 and t11.part_no not like 'AS%' then isnull(ANET,0) else 0 end) netsty_goal
	from cvo_sbm_details t11 join armaster ar on t11.customer=ar.customer_code and t11.ship_to=ar.ship_to_code 
	where 1=1
		AND (yyyymmdd between @datefromly and @datetoly
		or   yyyymmdd between @datefrom and @dateto)
		group by ar.territory_code
) g_sales on g_sales.territory_code = t.terr
group by T.Terr, T1.Terr, g_sales.netsly, g_sales.netsty_goal

-- select * from #TerrSales Order by Terr

-- FINAL SELECT
IF(OBJECT_ID('tempdb.dbo.#FINAL') is not null)  drop table #FINAL

SELECT T1.Region ,
       T1.Terr ,
       T1.Salesperson ,
       T1.date_of_hire ,
       T1.ClassOf ,
       T1.Status ,
       T1.PC ,
       T1.top9	, 
  Active = ISNULL((SELECT Count(Customer) FROM #active t3 WHERE T1.TERR=T3.TERR AND t3.net_sales > 2400 ) ,0) ,
  ReActive = ISNULL((SELECT sum(NumRea) FROM #STREA T5 WHERE T1.TERR=T5.Territory),0) ,
  New =   ISNULL((SELECT Count(Customer_code) 
		  FROM #Data2 t6 WHERE  t1.Terr=t6.territory 
			and ( (added_by_date >= @DateFrom and isnull(LastST,0) >= @DateFrom)
			or (lastst    >= @datefrom and isnull([2ndlastst],0)=0)) ), 0) ,

  STOrds = ISNULL((SELECT sum(NumSTOrds) FROM #STREA T5 WHERE T1.TERR=T5.Territory),0),
  ord_value = isnull((select sum(ord_value) from #strea where t1.terr = #strea.territory), 0),
  isnull(ps.AnnualProg,0) AnnualProg,
  isnull(ps.SeasonalProg,0) SeasonalProg,  
  isnull(ps.RXEProg,0) RXEProg,  
  ISNULL(ps.aspireprog,0) AspireProg,
  --ISNULL((SELECT COUNT(Order_no) from #ProgramData T4 where t1.terr=t4.territory 	and promo_id in ('AAP','APR','BEP','RCP','ROT64','FOD','SS') ),0)AnnualProg,
  --ISNULL((SELECT COUNT(Order_no) from #ProgramData T4 where t1.terr=t4.territory 	and promo_id in ('BOGO','DOR','ME','PURITI','IZOD','KIDS','SUN','sunps','T3','CH','CVO','BCBG', 'ET', 'SUN SPRING', 'IZOD CLEAR'  ) ),0)SeasonalProg,  
  --ISNULL((SELECT COUNT(Order_no) from #ProgramData T4 where t1.terr=t4.territory 	and promo_id in ('RXE') ),0)RXEProg,  
  
  ISNULL((SELECT count(Customer) FROM #Brands T2 WHERE T1.TERR=T2.TERR),0)[4Brands],
  -- ISNULL((SELECT SUM(NETSTY)-SUM(NETSLY) FROM #TerrSales T3 WHERE T1.TERR=T3.TERR ),0)IncreaseDol,
  IncreaseDol = t.netsty - t.netsly,
  IncreasePct = 
	CASE WHEN t.netsly = 0 THEN 1
			WHEN t.netsly < 0 THEN (t.netsty - t.netsly)/ (t.netsly * -1)
			ELSE (t.netsty - t.netsly) / t.netsly END,
  RXPct = CASE WHEN t.netsty = 0 THEN 0
				else t.rx/ t.netsty END,
  GrossSTY = t.gross,
  RetSRATY = t.retsa,
  RetPct = CASE WHEN t.gross = 0 AND t.retsa = 0 THEN 0
				WHEN t.gross = 0 THEN 0 
				ELSE t.retsa/t.gross END
                
  --ISNULL((SELECT CASE WHEN SUM(NETSLY) = 0 THEN 1 
		--			  WHEN SUM(NETSLY) < 0 THEN ((SUM(NETSTY)-SUM(NETSLY))/-SUM(NETSLY))
		--			  ELSE ((SUM(NETSTY)-SUM(NETSLY))/SUM(NETSLY)) END 
		--		 from #TerrSales T3 WHERE T1.TERR=T3.TERR),0)IncreasePct,
    --ISNULL((SELECT CASE WHEN sum(NETSTY) = 0 THEN 0 
				--	  ELSE sum(RX)/sum(NETSTY) END 
				-- from #TerrSales T3 WHERE T1.TERR=T3.TERR),0) RXPct,
  --  ISNULL((SELECT sum(Gross) from #TerrSales T3 WHERE T1.TERR=T3.TERR),0)GrossSTY,
  --ISNULL((SELECT sum(RetSa) from #TerrSales T3 WHERE T1.TERR=T3.TERR),0)RetSRATY,
  --  ISNULL((SELECT CASE WHEN sum(Gross) = 0 AND sum(RetSa) = 0 THEN 0 
		--				ELSE sum(RetSa)/sum(Gross) END 
		--		 from #TerrSales T3 WHERE T1.TERR=T3.TERR),0)RetPct,
  
  , ISNULL((SELECT Count(Customer) FROM #door500 T3 WHERE T1.TERR=T3.TERR AND T3.net_sales > 500),0) Door500

  --ISNULL((SELECT SUM(NETSTY) FROM #TerrSales T3 WHERE T1.TERR=T3.TERR ),0)NetsTY,
  --ISNULL((SELECT SUM(RX) FROM #TerrSales T3 WHERE T1.TERR=T3.TERR ),0)RXs,
  --ISNULL((SELECT SUM(NETSLY) FROM #TerrSales T3 WHERE T1.TERR=T3.TERR ),0)NetsLY
  , t.NetsTY 
  , t.netsty_goal
  , RXs = t.rx
  , ISNULL(t.NetSLY, 0) NetSLY
  , ISNULL(t.TerrGoal,0) TerrGoal
  , TerrGoalPCT = CASE WHEN ISNULL(t.terrgoal,0) = 0 THEN 0
					ELSE ISNULL(t.netsty_goal,0) / t.terrgoal END
  -- 7/29/2015 - new counts for retention pcts
  , activeretaincnt = ISNULL( (SELECT COUNT(customer) FROM #active a WHERE a.terr = t1.terr
								-- AND a.net_sales > a.net_sales_ly
								AND a.net_sales > 2400 AND a.net_sales_ly > 2400
								),0)
  , door500retaincnt = ISNULL( (SELECT COUNT(customer) FROM #door500 a WHERE a.terr = t1.terr
								-- AND a.net_sales > a.net_sales_ly
								AND a.net_sales >=500 AND a.net_sales_ly >=500
								),0)
  , activeretainvalue = ISNULL( ( SELECT SUM(net_sales) - SUM(net_sales_ly) FROM #active a WHERE a.terr = t1.Terr
								AND a.net_sales > 2400 AND a.net_sales_ly > 2400
								),0)
  , door500retainvalue = ISNULL( ( SELECT SUM(net_sales) - SUM(net_sales_ly) FROM #door500 a WHERE a.terr = t1.Terr
								AND a.net_sales >=500 AND a.net_sales_ly >=500
								),0)
                    
INTO #FINAL
FROM #SlpInfo T1
LEFT OUTER JOIN #terrsales t ON t.terr = t1.terr
left outer join #progsummary ps on ps.territory = t1.terr
-- select * from #final

select 
       #FINAL.Region ,
	   #FINAL.Terr ,

	   #FINAL.Salesperson ,
       #FINAL.date_of_hire ,
       #FINAL.ClassOf ,
	   #FINAL.Status ,
       #FINAL.PC ,
	   #FINAL.top9 ,
       #FINAL.Active ,
       #FINAL.ReActive ,
       #FINAL.New ,
       #FINAL.STOrds ,
       #FINAL.ord_value ,
       #FINAL.AnnualProg ,
       #FINAL.SeasonalProg ,
       #FINAL.RXEProg ,
       #FINAL.AspireProg ,
       #FINAL.[4Brands] ,
       #FINAL.IncreaseDol ,
       #FINAL.IncreasePct ,
       #FINAL.RXPct ,
       #FINAL.GrossSTY ,
       #FINAL.RetSRATY ,
       #FINAL.RetPct ,
       #FINAL.Door500 ,
       #FINAL.NetSTY ,
       #FINAL.netsty_goal ,
       #FINAL.RXs ,
       #FINAL.NetSLY ,
       #FINAL.TerrGoal ,
       #FINAL.TerrGoalPCT ,
       #FINAL.activeretaincnt ,
       #FINAL.door500retaincnt ,
       #FINAL.activeretainvalue ,
       #FINAL.door500retainvalue 
, veteran_status =  case when [status] = 'Veteran' THEN
					 case when pc = 1 then 'PC'
						when top9 = 1 then 'Top 9'
						else 'Other'
					 END
					ELSE '' END
from #FINAL
-- Order by Terr

-- EXEC CVO_Sales_ScoreCard_terr_SP '1/1/2015', '12/31/2015'
--SELECT * FROM #active where terr = 30302
--SELECT * FROM #door500

--SELECT *
----SUM(net_sales) - SUM(net_sales_ly) 
--FROM #active a WHERE a.terr = 30302
--AND a.net_sales > 2400 AND a.net_sales_ly > 2400

END

--SELECT SUM(anet), x_month, year, ship_to
-- FROM cvo_sbm_details WHERE customer = '032056' AND YEAR IN (2014, 2015) 
-- GROUP BY X_MONTH, YEAR, ship_to
 
-- SELECT * FROM dbo.armaster WHERE customer_code = '032056'

--SELECT * FROM #data2 AS s WHERE (s.Territory='20203' and stat='rea') OR s.customer_code = '013853'

GO
