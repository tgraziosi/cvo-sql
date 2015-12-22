SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		elabarbera
-- Create date: 3/13/2013
-- Description:	Territory RX Cycle Report
-- EXEC Territory_RX_Cycle_SSRS_SP '4/1/2014'
-- =============================================
CREATE PROCEDURE [dbo].[Territory_RX_Cycle_SSRS_SP] 
@DateTo datetime
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
--SETS
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

IF(OBJECT_ID('tempdb.dbo.#OrdersAll') is not null)
drop table dbo.#OrdersAll
SELECT * INTO #OrdersAll FROM (
SELECT DISTINCT t2.territory_code as Terr, cust_code, ship_to, t2.address_name, 

left(t2.postal_code,5)postal_code, contact_phone as phone, order_no, ext, invoice_no, invoice_date, date_shipped, date_entered, USER_CATEGORY, total_amt_order, (select sum(ordered) from ord_list t22 JOIN INV_MASTER T33 ON T22.PART_NO=T33.PART_NO where t1.order_no=t22.order_no and t1.ext=t22.order_ext and t22.order_ext=0 AND T33.TYPE_CODE IN ('SUN','FRAME'))Qty
from ORDERS_ALL t1
join armaster t2 on t1.cust_code=t2.customer_code and t1.ship_to=t2.ship_to_code
WHERE EXT=0
AND DATE_ENTERED BETWEEN @DateFrom AND @DateTo
--and date_entered between '1/1/2013' and '1/31/2013 23:59:59'
AND USER_CATEGORY LIKE '%RX%'
AND TYPE <> 'C'
AND STATUS <>'V'
--and status_type = 1
	union all
SELECT DISTINCT t2.territory_code as Terr, cust_code, ship_to, t2.address_name, left(t2.postal_code,5)postal_code, contact_phone as phone, order_no, ext, invoice_no, invoice_date, date_shipped, date_entered, USER_CATEGORY, total_amt_order, (select sum(ordered) from cvo_ord_list_hist t22 JOIN INV_MASTER T33 ON T22.PART_NO=T33.PART_NO where t1.order_no=t22.order_no and t1.ext=t22.order_ext and t22.order_ext=0 AND T33.TYPE_CODE IN ('SUN','FRAME'))Qty
from CVO_ORDERS_ALL_HIST t1
join armaster t2 on t1.cust_code=t2.customer_code and t1.ship_to=t2.ship_to_code
WHERE EXT=0
AND DATE_ENTERED BETWEEN @DateFrom AND @DateTo
--and date_entered between '1/1/2013' and '1/31/2013 23:59:59'
AND USER_CATEGORY LIKE '%RX%'
AND TYPE <> 'C'
AND STATUS ='V'
--and status_type = 1
  ) tmp
order by Terr, Cust_code, ship_to, date_entered desc 
-- select * from armaster where status_type='1' and address_type<>9 

IF(OBJECT_ID('tempdb.dbo.#RXCYC') is not null)
drop table dbo.#RXCYC
select CASE WHEN status_type = 1 THEN 'Open' ELSE 'Closed' end as status_type,
 territory_code, customer_code, ship_to_code, address_name, city, left(postal_code,5)postal_code, contact_phone as phone,
(SELECT TOP 1 order_no FROM #OrdersAll T11 WHERE T1.customer_code=T11.CUST_CODE AND T1.SHIP_TO_CODE=T11.SHIP_TO  ORDER BY date_shipped desc) 'Ord#',
(SELECT TOP 1 date_entered FROM #OrdersAll T11 WHERE T1.customer_code=T11.CUST_CODE AND T1.SHIP_TO_CODE=T11.SHIP_TO  ORDER BY date_shipped desc) 'LastVisitDate',
(SELECT TOP 1 user_category FROM #OrdersAll T11 WHERE T1.customer_code=T11.CUST_CODE AND T1.SHIP_TO_CODE=T11.SHIP_TO  ORDER BY date_shipped desc) 'Type',
(SELECT TOP 1 total_amt_order FROM #OrdersAll T11 WHERE T1.customer_code=T11.CUST_CODE AND T1.SHIP_TO_CODE=T11.SHIP_TO  ORDER BY date_shipped desc) 'OrdAmt',
(SELECT TOP 1 qty FROM #OrdersAll T11 WHERE T1.customer_code=T11.CUST_CODE AND T1.SHIP_TO_CODE=T11.SHIP_TO  ORDER BY date_shipped desc) 'Qty',
ISNULL((SELECT SUM(ANET) FROM CVO_SBM_details T2 WHERE T1.CUSTOMER_CODE=T2.CUSTOMER AND T1.SHIP_TO_CODE=T2.SHIP_TO and T2.YYYYMMDD BETWEEN @DateFrom AND @DateTo AND user_category  LIKE '%RX%' ),0) RXSales12,
ISNULL((SELECT SUM(ANET) FROM CVO_SBM_details T2 WHERE T1.CUSTOMER_CODE=T2.CUSTOMER AND T1.SHIP_TO_CODE=T2.SHIP_TO and T2.YYYYMMDD BETWEEN @DateFrom AND @DateTo),0) NetSales12,
CASE
	WHEN (SELECT TOP 1 date_entered FROM #OrdersAll T11 WHERE T1.customer_code=T11.CUST_CODE AND T1.SHIP_TO_CODE=T11.SHIP_TO ORDER BY date_shipped desc) >=@M1 THEN 1
	WHEN (SELECT TOP 1 date_entered FROM #OrdersAll T11 WHERE T1.customer_code=T11.CUST_CODE AND T1.SHIP_TO_CODE=T11.SHIP_TO ORDER BY date_shipped desc) >=@M2 THEN 2
	WHEN (SELECT TOP 1 date_entered FROM #OrdersAll T11 WHERE T1.customer_code=T11.CUST_CODE AND T1.SHIP_TO_CODE=T11.SHIP_TO ORDER BY date_shipped desc) >=@M3 THEN 3
	WHEN (SELECT TOP 1 date_entered FROM #OrdersAll T11 WHERE T1.customer_code=T11.CUST_CODE AND T1.SHIP_TO_CODE=T11.SHIP_TO ORDER BY date_shipped desc) >=@M4 THEN 4
	WHEN (SELECT TOP 1 date_entered FROM #OrdersAll T11 WHERE T1.customer_code=T11.CUST_CODE AND T1.SHIP_TO_CODE=T11.SHIP_TO ORDER BY date_shipped desc) >=@M5 THEN 5
	WHEN (SELECT TOP 1 date_entered FROM #OrdersAll T11 WHERE T1.customer_code=T11.CUST_CODE AND T1.SHIP_TO_CODE=T11.SHIP_TO ORDER BY date_shipped desc) >=@M6 THEN 6
	WHEN (SELECT TOP 1 date_entered FROM #OrdersAll T11 WHERE T1.customer_code=T11.CUST_CODE AND T1.SHIP_TO_CODE=T11.SHIP_TO ORDER BY date_shipped desc) >= DateAdd(second,1,DateAdd(week,-28,@DateTo))THEN 7
	WHEN (SELECT TOP 1 date_entered FROM #OrdersAll T11 WHERE T1.customer_code=T11.CUST_CODE AND T1.SHIP_TO_CODE=T11.SHIP_TO ORDER BY date_shipped desc) >= DateAdd(second,1,DateAdd(week,-32,@DateTo))THEN 8
	WHEN (SELECT TOP 1 date_entered FROM #OrdersAll T11 WHERE T1.customer_code=T11.CUST_CODE AND T1.SHIP_TO_CODE=T11.SHIP_TO ORDER BY date_shipped desc) >= DateAdd(second,1,DateAdd(week,-36,@DateTo))THEN 9
	WHEN (SELECT TOP 1 date_entered FROM #OrdersAll T11 WHERE T1.customer_code=T11.CUST_CODE AND T1.SHIP_TO_CODE=T11.SHIP_TO ORDER BY date_shipped desc) >= DateAdd(second,1,DateAdd(week,-42,@DateTo))THEN 10
	WHEN (SELECT TOP 1 date_entered FROM #OrdersAll T11 WHERE T1.customer_code=T11.CUST_CODE AND T1.SHIP_TO_CODE=T11.SHIP_TO ORDER BY date_shipped desc) >= DateAdd(second,1,DateAdd(week,-48,@DateTo))THEN 11
	WHEN (SELECT TOP 1 date_entered FROM #OrdersAll T11 WHERE T1.customer_code=T11.CUST_CODE AND T1.SHIP_TO_CODE=T11.SHIP_TO ORDER BY date_shipped desc) >= DateAdd(second,1,DateAdd(week,-52,@DateTo))THEN 12	
	ELSE 13 END AS M,
case 
	WHEN (SELECT TOP 1 date_entered FROM #OrdersAll T11 WHERE T1.customer_code=T11.CUST_CODE AND T1.SHIP_TO_CODE=T11.SHIP_TO ORDER BY date_shipped desc) >=@M2 THEN 1
	WHEN (SELECT TOP 1 date_entered FROM #OrdersAll T11 WHERE T1.customer_code=T11.CUST_CODE AND T1.SHIP_TO_CODE=T11.SHIP_TO ORDER BY date_shipped desc) >=@M4 THEN 2
	WHEN (SELECT TOP 1 date_entered FROM #OrdersAll T11 WHERE T1.customer_code=T11.CUST_CODE AND T1.SHIP_TO_CODE=T11.SHIP_TO ORDER BY date_shipped desc) >=@M6 THEN 3
	ELSE 4 END AS R
	  
INTO #RXCYC
from armaster T1
--where status_type=1
--and 
where address_type <>9
group by status_type, territory_code, customer_code, ship_to_code, address_name, city, postal_code,contact_phone

SELECT * FROM #RXcyc ORDER BY TERRITORY_CODE, R, M

END
GO
