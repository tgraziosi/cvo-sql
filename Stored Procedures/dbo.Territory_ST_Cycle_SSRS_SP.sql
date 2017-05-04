SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


-- =============================================
-- Author:		elabarbera
-- Create date: 3/13/2013
-- Description:	Territory ST Cycle Report
-- EXEC Territory_ST_Cycle_SSRS_SP '04/30/2017' , '20201'
-- 033015 - add territory parameter for performance
-- =============================================
CREATE PROCEDURE [dbo].[Territory_ST_Cycle_SSRS_SP] @DateTo datetime, @Terr varchar(1000) = null
AS
BEGIN
	SET NOCOUNT ON;

-- Territory ST Cycle Report
--DECLARES
		DECLARE @DateFrom datetime                                    
--		DECLARE @DateTo datetime		
		DECLARE @JDateFrom int                                    
		DECLARE @JDateTo int		
		DECLARE @M1 datetime
		DECLARE @M2 datetime
		DECLARE @M3 datetime
		DECLARE @M4 datetime
		DECLARE @M5 datetime
		DECLARE @M6 datetime
		declare @territory varchar(1000)
--SETS
		select @territory = @terr
--		SET @DateTo = '3/5/2014'
		SET @DateFrom = DATEADD(Year,-1,DATEADD(dd,1,@DateTo))
			SET @dateTo=dateadd(second,-1,@dateTo)
			SET @dateTo=dateadd(day,1,@dateTo)
		SET @M1 = DateAdd(second,1,DateAdd(week,-4,@DateTo))
		SET @M2 = DateAdd(second,1,DateAdd(week,-8,@DateTo))
		SET @M3 = DateAdd(second,1,DateAdd(week,-12,@DateTo))
		SET @M4 = DateAdd(second,1,DateAdd(week,-16,@DateTo))
		SET @M5 = DateAdd(second,1,DateAdd(week,-20,@DateTo))
		SET @M6 = DateAdd(second,1,DateAdd(week,-24,@DateTo))
--select @DateFrom, @DateTo

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

IF(OBJECT_ID('tempdb.dbo.#OrdersAll') is not null)
drop table dbo.#OrdersAll
SELECT tmp.Terr ,
       tmp.cust_code ,
       tmp.ship_to ,
       tmp.address_name ,
       tmp.postal_code ,
       tmp.phone ,
       tmp.order_no ,
       tmp.ext ,
       tmp.invoice_no ,
       tmp.invoice_date ,
       tmp.date_shipped ,
       tmp.date_entered ,
       tmp.user_category ,
       tmp.total_amt_order ,
       tmp.Qty INTO #OrdersAll 
FROM (
SELECT DISTINCT t2.territory_code as Terr, cust_code, ship_to, t2.address_name, 
left(t2.postal_code,5)postal_code, contact_phone as phone, order_no, ext, invoice_no, invoice_date, date_shipped, date_entered, USER_CATEGORY, total_amt_order, (select sum(ordered) from ord_list t22 JOIN INV_MASTER T33 ON T22.PART_NO=T33.PART_NO where t1.order_no=t22.order_no and t1.ext=t22.order_ext and t22.order_ext=0 AND T33.TYPE_CODE IN ('SUN','FRAME'))Qty
from #territory t 
inner join armaster t2 on t.territory = t2.territory_code
inner join ORDERS_ALL t1 on t1.cust_code=t2.customer_code and t1.ship_to=t2.ship_to_code
WHERE who_entered <> 'backordr'
AND DATE_ENTERED BETWEEN @DateFrom AND @DateTo
--and date_entered between '1/1/2013' and '1/31/2013 23:59:59'
AND USER_CATEGORY NOT LIKE 'RX%'
AND TYPE = 'I'
AND STATUS <>'V'
--and status_type = 1
	union all
SELECT DISTINCT t2.territory_code as Terr, cust_code, ship_to, t2.address_name, left(t2.postal_code,5)postal_code, contact_phone as phone, order_no, ext, invoice_no, invoice_date, date_shipped, date_entered, USER_CATEGORY, total_amt_order, (select sum(ordered) from cvo_ord_list_hist t22 JOIN INV_MASTER T33 ON T22.PART_NO=T33.PART_NO where t1.order_no=t22.order_no and t1.ext=t22.order_ext and t22.order_ext=0 AND T33.TYPE_CODE IN ('SUN','FRAME'))Qty
from #territory t 
inner join armaster t2 on t2.territory_code = t.territory
inner join CVO_ORDERS_ALL_HIST t1 on t1.cust_code=t2.customer_code and t1.ship_to=t2.ship_to_code
WHERE who_entered <> 'backordr'
AND DATE_ENTERED BETWEEN @DateFrom AND @DateTo
--and date_entered between '1/1/2013' and '1/31/2013 23:59:59'
AND USER_CATEGORY NOT LIKE 'RX%'
AND TYPE = 'I'
AND STATUS ='V'
--and status_type = 1
  ) tmp
order by Terr, Cust_code, ship_to, date_entered desc 
-- select * from armaster where status_type='1' and address_type<>9 

IF(OBJECT_ID('tempdb.dbo.#STCYC') is not null)
drop table dbo.#STCYC

select CASE WHEN status_type = 1 THEN 'Open' ELSE 'Closed' end as status_type,
 territory_code, customer_code, ship_to_code, address_name, city, left(postal_code,5)postal_code, contact_phone as phone,
(SELECT TOP 1 order_no FROM #OrdersAll T11 WHERE T1.customer_code=T11.CUST_CODE AND T1.SHIP_TO_CODE=T11.SHIP_TO and t11.qty >=5 ORDER BY date_shipped desc) 'Ord#',
(SELECT TOP 1 date_entered FROM #OrdersAll T11 WHERE T1.customer_code=T11.CUST_CODE AND T1.SHIP_TO_CODE=T11.SHIP_TO and t11.qty >=5 ORDER BY date_shipped desc) 'LastVisitDate',
(SELECT TOP 1 user_category FROM #OrdersAll T11 WHERE T1.customer_code=T11.CUST_CODE AND T1.SHIP_TO_CODE=T11.SHIP_TO and t11.qty >=5 ORDER BY date_shipped desc) 'Type',
(SELECT TOP 1 total_amt_order FROM #OrdersAll T11 WHERE T1.customer_code=T11.CUST_CODE AND T1.SHIP_TO_CODE=T11.SHIP_TO and t11.qty >=5 ORDER BY date_shipped desc) 'OrdAmt',
(SELECT TOP 1 qty FROM #OrdersAll T11 WHERE T1.customer_code=T11.CUST_CODE AND T1.SHIP_TO_CODE=T11.SHIP_TO and t11.qty >=5 ORDER BY date_shipped desc) 'Qty',

ISNULL((SELECT SUM(ANET) FROM CVO_SBM_details T2 WHERE T1.CUSTOMER_CODE=T2.CUSTOMER AND T1.SHIP_TO_CODE=T2.SHIP_TO and T2.YYYYMMDD BETWEEN @DateFrom AND @DateTo),0) NetSales12,

CASE
	WHEN (SELECT TOP 1 date_entered FROM #OrdersAll T11 WHERE T1.customer_code=T11.CUST_CODE AND T1.SHIP_TO_CODE=T11.SHIP_TO and t11.qty >=5 ORDER BY date_shipped desc) >=@M1 THEN 1
	WHEN (SELECT TOP 1 date_entered FROM #OrdersAll T11 WHERE T1.customer_code=T11.CUST_CODE AND T1.SHIP_TO_CODE=T11.SHIP_TO and t11.qty >=5 ORDER BY date_shipped desc) >=@M2 THEN 2
	WHEN (SELECT TOP 1 date_entered FROM #OrdersAll T11 WHERE T1.customer_code=T11.CUST_CODE AND T1.SHIP_TO_CODE=T11.SHIP_TO and t11.qty >=5 ORDER BY date_shipped desc) >=@M3 THEN 3
	WHEN (SELECT TOP 1 date_entered FROM #OrdersAll T11 WHERE T1.customer_code=T11.CUST_CODE AND T1.SHIP_TO_CODE=T11.SHIP_TO and t11.qty >=5 ORDER BY date_shipped desc) >=@M4 THEN 4
	WHEN (SELECT TOP 1 date_entered FROM #OrdersAll T11 WHERE T1.customer_code=T11.CUST_CODE AND T1.SHIP_TO_CODE=T11.SHIP_TO and t11.qty >=5 ORDER BY date_shipped desc) >=@M5 THEN 5
	WHEN (SELECT TOP 1 date_entered FROM #OrdersAll T11 WHERE T1.customer_code=T11.CUST_CODE AND T1.SHIP_TO_CODE=T11.SHIP_TO and t11.qty >=5 ORDER BY date_shipped desc) >=@M6 THEN 6
	WHEN (SELECT TOP 1 date_entered FROM #OrdersAll T11 WHERE T1.customer_code=T11.CUST_CODE AND T1.SHIP_TO_CODE=T11.SHIP_TO and t11.qty >=5 ORDER BY date_shipped desc) >= DateAdd(second,1,DateAdd(week,-28,@DateTo))THEN 7
	WHEN (SELECT TOP 1 date_entered FROM #OrdersAll T11 WHERE T1.customer_code=T11.CUST_CODE AND T1.SHIP_TO_CODE=T11.SHIP_TO and t11.qty >=5 ORDER BY date_shipped desc) >= DateAdd(second,1,DateAdd(week,-32,@DateTo))THEN 8
	WHEN (SELECT TOP 1 date_entered FROM #OrdersAll T11 WHERE T1.customer_code=T11.CUST_CODE AND T1.SHIP_TO_CODE=T11.SHIP_TO and t11.qty >=5 ORDER BY date_shipped desc) >= DateAdd(second,1,DateAdd(week,-36,@DateTo))THEN 9
	WHEN (SELECT TOP 1 date_entered FROM #OrdersAll T11 WHERE T1.customer_code=T11.CUST_CODE AND T1.SHIP_TO_CODE=T11.SHIP_TO and t11.qty >=5 ORDER BY date_shipped desc) >= DateAdd(second,1,DateAdd(week,-42,@DateTo))THEN 10
	WHEN (SELECT TOP 1 date_entered FROM #OrdersAll T11 WHERE T1.customer_code=T11.CUST_CODE AND T1.SHIP_TO_CODE=T11.SHIP_TO and t11.qty >=5 ORDER BY date_shipped desc) >= DateAdd(second,1,DateAdd(week,-48,@DateTo))THEN 11
	WHEN (SELECT TOP 1 date_entered FROM #OrdersAll T11 WHERE T1.customer_code=T11.CUST_CODE AND T1.SHIP_TO_CODE=T11.SHIP_TO and t11.qty >=5 ORDER BY date_shipped desc) >= DateAdd(second,1,DateAdd(week,-52,@DateTo))THEN 12	
	ELSE 13 END AS M,
case 
	WHEN (SELECT TOP 1 date_entered FROM #OrdersAll T11 WHERE T1.customer_code=T11.CUST_CODE AND T1.SHIP_TO_CODE=T11.SHIP_TO and t11.qty >=5 ORDER BY date_shipped desc) >=@M2 THEN 1
	WHEN (SELECT TOP 1 date_entered FROM #OrdersAll T11 WHERE T1.customer_code=T11.CUST_CODE AND T1.SHIP_TO_CODE=T11.SHIP_TO and t11.qty >=5 ORDER BY date_shipped desc) >=@M4 THEN 2
	WHEN (SELECT TOP 1 date_entered FROM #OrdersAll T11 WHERE T1.customer_code=T11.CUST_CODE AND T1.SHIP_TO_CODE=T11.SHIP_TO and t11.qty >=5 ORDER BY date_shipped desc) >=@M6 THEN 3
	ELSE 4 END AS R
	  
INTO #STCYC
from #territory AS t
JOIN armaster T1 ON t.territory = t1.territory_code
--where status_type=1
--and 
where address_type <>9
group by status_type, territory_code, customer_code, ship_to_code, address_name, city, postal_code,contact_phone


SELECT * FROM #stcyc ORDER BY TERRITORY_CODE, R, M

END


GO
