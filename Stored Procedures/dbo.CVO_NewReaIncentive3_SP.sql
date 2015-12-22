SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		Tine Graziosi
-- Create date: 10/27/2014
-- Description:	New & Reactivated Account Incentive ScoreCard  (by SHIPPED ) <>*<>*<>*<>*<>*<>*<>*<>*<>*<>
-- EXEC CVO_NewReaIncentive3_SP '01/01/2015','03/31/2015'

--insert into cvo_new_reactive_temp1 
--EXEC  CVO_NewReaIncentive3_SP
--12/2/2014 - ADDED PARAMETER FOR DESIGNATION CODE WILCARD SEARCH
-- =============================================
CREATE PROCEDURE [dbo].[CVO_NewReaIncentive3_SP]

@DateFrom datetime  = null ,
@DateTo datetime  = null ,
@desig varchar(10) = null

AS
BEGIN
	SET NOCOUNT ON;

--Declare @DateFrom datetime
--Declare @DateTo datetime
--Set @DateFrom = '11/1/2013' 
--Set @DateTo = '10/27/2014'
if @datefrom is null select @datefrom = dateadd(dd,-1,dateadd(year,-1,datediff(dd,0,getdate()))) -- year - 1
if @dateto is null select @dateto = dateadd(dd,-1,datediff(dd,0,getdate())) -- today

Set @DateTo = DateAdd(Second, -1, DateAdd(D,1,@DateTo))
--  select @DateFrom, @DateTo, (dateadd(day,-1,dateadd(year,1,@DateFrom))), dateadd(year,-1,@DateFrom) , dateadd(day,-1,@DateFrom)

-- select @datefrom, @dateto
-- BUILD REP DATA
IF(OBJECT_ID('tempdb.dbo.#SlpInfo') is not null)  drop table dbo.#SlpInfo
SELECT dbo.calculate_Region_fn(Territory_code)Region,Territory_code as Terr, 
Salesperson_name as Salesperson, ISNULL(date_of_hire,'1/1/1950')date_of_hire, 
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
	ELSE 'VETERAN' 
	end as Status
INTO #SlpInfo
FROM arsalesp Where Status_type = 1 and Territory_code not like '%00' 
and  salesperson_name <> 'Alanna Martin' order by Territory_code
--  select * from #SlpInfo


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
-- and (order_ext=0 OR o.who_entered = 'outofstock')
and type_code in('sun','frame') and user_category not like 'rx%' and user_category not in ('ST-RB','DO')
GROUP BY ar.territory_code, DOOR, CUST_CODE, o.SHIP_TO, co.PROMO_ID,
 user_category, o.ORDER_NO, o.ext, o.STATUS, o.TYPE, ADDED_BY_DATE, date_shipped

-- select * from #Invoices   where cust_code = '012845' and type='i' and 
--
-- REACTIVATED -- -- PULL Last & 2nd Last ST Order
IF(OBJECT_ID('tempdb.dbo.#DATA') is not null)  drop table #DATA

Select ar.territory_code as Territory, ar.Customer_code, ship_to_code, car.DOOR, added_by_date,
-- SUM(S.NETSALES) YTDNET,

-- tag  -- Find the first ST qualified in the reporting period, and the previous one.  
-- Then find the difference between the two to see if it's going to be a new or reactivated customer.

--[FirstST_new] = 	(SELECT TOP 1 DATE_SHIPPED FROM #INVOICES t11 
--		WHERE Type='i' and QTY >=5 AND T11.CUST_CODE=ar.customer_code AND T11.SHIP_TO=ar.SHIP_TO_CODE 
--		and date_shipped >= @datefrom ORDER BY DATE_SHIPPED asc) ,

-- match to scorecard calculations

[FirstST_new] = (SELECT min(date_shipped) FROM #INVOICES inv 
	WHERE Type='i' and QTY >=5 
	and date_shipped >= @datefrom
	AND inv.CUST_CODE=ar.customer_code AND inv.SHIP_TO=ar.SHIP_TO_CODE) ,

--[LastST] = 
--	(SELECT TOP 1 DATE_SHIPPED FROM #INVOICES t11 
--		WHERE Type='i' and QTY >=5 AND T11.CUST_CODE=ar.customer_code AND T11.SHIP_TO=ar.SHIP_TO_CODE 
--		ORDER BY DATE_SHIPPED DESC) ,

[PrevST_new] = (select MAX(date_shipped) from #INVOICES t11 WHERE Type='i' 
	 and t11.date_shipped <
	  (SELECT min(inv.date_shipped) FROM #INVOICES inv 
		WHERE Type='i' and QTY >=5 
		and date_shipped >= @datefrom 
		AND inv.CUST_CODE=ar.customer_code AND inv.SHIP_TO=ar.SHIP_TO_CODE)
	  and QTY >=5 AND T11.CUST_CODE=ar.customer_code AND T11.SHIP_TO=ar.SHIP_TO_CODE)


INTO #DATA
from armaster ar (NOLOCK)
join cvo_armaster_all car (nolock) on ar.customer_code=car.customer_code and ar.ship_to_code=car.ship_to
-- join cvo_rad_shipto s (nolock)  on right(s.customer,5)=right(ar.customer_code,5) and s.ship_to=ar.ship_to_code
 WHERE ar.address_type <> 9 and car.door=1
-- AND yyyymmdd BETWEEN @DateFrom AND @DateTo
group by ar.territory_code, ar.customer_code, ar.ship_to_code, car.door, ar.added_by_date
--  select * from #Data where customer_code = '047859' order by territory, customer_code 

IF(OBJECT_ID('tempdb.dbo.#DATA2') is not null)  drop table #DATA2
SELECT T1.*, 

CASE WHEN DATEDIFF(D,[PrevSt_new],FirstSt_new) > 365 AND FirstSt_new > @DateFrom 
			AND added_by_date < @DateFrom  AND isnull([PrevSt_new],0) <> 0  
	 THEN 'REA' ELSE '' END AS STAT_new,

CASE WHEN DATEDIFF(D,[prevst_new],firstst_new) > 365 AND Firstst_new > @DateFrom 
			AND added_by_date < @DateFrom  
	 THEN ISNULL(Month(prevst_new),1) 
	 else '' end as X_MONTH_new
INTO #DATA2 FROM #DATA T1 
--  select * from #Data2 where customer_code like '047859'
-- select * from #Data2 where STAT='REA'

IF(OBJECT_ID('tempdb.dbo.#DATA3') is not null)  drop table #DATA3
select t2.*, t1.* INTO #DATA3 FROM (
SELECT Territory, Customer_code, ship_to_code, Case when Door=1 then 'Y' else '' end as Door, 
added_by_date, 

firstst_new, prevst_new, stat_new as StatusType 
FROM  #Data2 T5 where Door='1' and STAT_new='REA'  
UNION ALL
SELECT Territory, Customer_code, ship_to_code, Case when Door=1 then 'Y' else '' end as Door, 
added_by_date, 

firstst_new, prevst_new, 'NEW' as StatusType FROM #Data2 t5 
WHERE   (added_by_date >= @DateFrom and firstst_new >= @DateFrom ) 
	OR (firstst_new >= @DateFrom  and isnull(prevst_new,0) = 0)
  ) t1
  FULL OUTER join #SlpInfo t2 on t1.Territory=t2.Terr

-- Get Designation Codes, into one field  (Where Designations date range is in report date range
IF(OBJECT_ID('tempdb.dbo.#desig') is not null)
drop table dbo.#desig
      ;WITH C AS 
            ( SELECT customer_code, code FROM cvo_cust_designation_codes (nolock) )
            select Distinct customer_code,
                              STUFF ( ( SELECT '; ' + code
                              FROM cvo_cust_designation_codes (nolock)
                              WHERE customer_code = C.customer_code
                              and isnull(start_date,@dateto) <= @dateto
				              and isnull(end_date,@dateto) >= @dateto
                              FOR XML PATH ('') ), 1, 1, ''  ) AS designations
      INTO #desig
      FROM C

-- Get Primary for each Customer
IF(OBJECT_ID('tempdb.dbo.#Primary') is not null)
drop table dbo.#Primary
SELECT CUSTOMER_CODE, CODE, START_DATE, END_DATE 
INTO #Primary 
FROM cvo_cust_designation_codes (nolock)  
WHERE PRIMARY_FLAG=1
and start_date <= @DateTo and isnull(end_date,@dateto) >= @dateto 

-- select * from #Primary

if isnull(@desig,'*ALL*') = '*ALL*'
begin
 Select distinct d.*
 , ISNULL(ltrim(rtrim(de.designations)), '' ) as Designations
 , ISNULL(p.code, '' ) as PriDesig
 from #DATA3 d
 left outer join #desig de on de.customer_code = d.customer_code
 left outer join #primary p on p.customer_code = d.customer_code
 where 1=1
 and isnull(Terr,'') <> ''
 order by Terr
end
else
begin
 Select distinct d.*
 , ISNULL(ltrim(rtrim(de.designations)), '' ) as Designations
 , ISNULL(p.code, '' ) as PriDesig
 from #DATA3 d
 left outer join #desig de on de.customer_code = d.customer_code
 left outer join #primary p on p.customer_code = d.customer_code
 where 1=1
 and isnull(Terr,'') <> '' 
 and   de.designations like '%'+isnull(@desig,'')+'%'
 order by Terr
end


-- EXEC CVO_NewReaIncentive3_SP '1/1/2014','11/1/2014'
-- tempdb..sp_help #data3


END

GO
GRANT EXECUTE ON  [dbo].[CVO_NewReaIncentive3_SP] TO [public]
GO
