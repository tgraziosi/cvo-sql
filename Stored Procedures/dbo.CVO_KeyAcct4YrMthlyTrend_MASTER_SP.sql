
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		elabarbera
-- Create date: 5/17/2013
-- Description:	Key Accounts 4 Yr Monthly Trend
-- exec CVO_KeyAcct4YrMthlyTrend_MASTER_SP
-- =============================================
CREATE PROCEDURE [dbo].[CVO_KeyAcct4YrMthlyTrend_MASTER_SP]

AS
BEGIN

	SET NOCOUNT ON;
declare @Date datetime
set @date = DATEADD(yy, DATEDIFF(yy,0,getdate()),0)

IF(OBJECT_ID('tempdb.dbo.#CY') is not null)  
drop table #CY
SELECT * INTO #CY FROM  (
SELECT distinct LEFT(TERRITORY_CODE,2)Region, TERRITORY_CODE as Terr, t1.Customer_code as CustNum, T1.ADDRESS_NAME, case when ADDR2 like 'use Global%' then 'Closed Lab ShipTo' else '' end as Note, CASE WHEN STATUS_TYPE = '1' THEN 'Open' ELSE 'Closed' end as Status, 
DATEPART(YEAR,getdate()) as Yr,
isnull((select sum(anet) from cvo_sbm_details t2 where t1.customer_code=t2.customer and yyyymmdd between @Date  and    DATEADD(SECOND, -1, DATEADD(MONTH, 1, @Date)) ),0) Jan,
isnull((select sum(anet) from cvo_sbm_details t2 where t1.customer_code=t2.customer and yyyymmdd between DATEADD(MONTH,1,@Date) and  DATEADD(SECOND, -1, DATEADD(MONTH, 2, @Date)) ),0) Feb,
isnull((select sum(anet) from cvo_sbm_details t2 where t1.customer_code=t2.customer and yyyymmdd between DATEADD(MONTH,2,@Date) and  DATEADD(SECOND, -1, DATEADD(MONTH, 3, @Date)) ),0) Mar,
isnull((select sum(anet) from cvo_sbm_details t2 where t1.customer_code=t2.customer and yyyymmdd between DATEADD(MONTH,3,@Date) and  DATEADD(SECOND, -1, DATEADD(MONTH, 4, @Date)) ),0) Apr,
isnull((select sum(anet) from cvo_sbm_details t2 where t1.customer_code=t2.customer and yyyymmdd between DATEADD(MONTH,4,@Date) and  DATEADD(SECOND, -1, DATEADD(MONTH, 5, @Date)) ),0) May,
isnull((select sum(anet) from cvo_sbm_details t2 where t1.customer_code=t2.customer and yyyymmdd between DATEADD(MONTH,5,@Date) and  DATEADD(SECOND, -1, DATEADD(MONTH, 6, @Date)) ),0) Jun,
isnull((select sum(anet) from cvo_sbm_details t2 where t1.customer_code=t2.customer and yyyymmdd between DATEADD(MONTH,6,@Date) and  DATEADD(SECOND, -1, DATEADD(MONTH, 7, @Date)) ),0) Jul,
isnull((select sum(anet) from cvo_sbm_details t2 where t1.customer_code=t2.customer and yyyymmdd between DATEADD(MONTH,7,@Date) and  DATEADD(SECOND, -1, DATEADD(MONTH, 8, @Date)) ),0) Aug,
isnull((select sum(anet) from cvo_sbm_details t2 where t1.customer_code=t2.customer and yyyymmdd between DATEADD(MONTH,8,@Date) and  DATEADD(SECOND, -1, DATEADD(MONTH, 9, @Date)) ),0) Sep,
isnull((select sum(anet) from cvo_sbm_details t2 where t1.customer_code=t2.customer and yyyymmdd between DATEADD(MONTH,9,@Date) and  DATEADD(SECOND, -1, DATEADD(MONTH, 10, @Date)) ),0) Oct,
isnull((select sum(anet) from cvo_sbm_details t2 where t1.customer_code=t2.customer and yyyymmdd between DATEADD(MONTH,10,@Date) and  DATEADD(SECOND, -1, DATEADD(MONTH, 11, @Date)) ),0) Nov,
isnull((select sum(anet) from cvo_sbm_details t2 where t1.customer_code=t2.customer and yyyymmdd between DATEADD(MONTH,11,@Date) and  DATEADD(SECOND, -1, DATEADD(MONTH, 12, @Date)) ),0) Dec,
isnull((select sum(anet) from cvo_sbm_details t2 where t1.customer_code=t2.customer and yyyymmdd between @Date and  DATEADD(SECOND, -1, DATEADD(MONTH, 12, @Date)) ),0) YTD
FROM ARMASTER t1
WHERE ADDR_SORT1='KEY ACCOUNT'
and address_type = 0
	UNION ALL
SELECT distinct LEFT(TERRITORY_CODE,2)Region, TERRITORY_CODE as Terr, t1.Customer_code as CustNum, T1.ADDRESS_NAME, case when ADDR2 like 'use Global%' then 'Closed Lab ShipTo' else '' end as Note, CASE WHEN STATUS_TYPE = '1' THEN 'Open' ELSE 'Closed' end as Status, 
(DATEPART(YEAR,getdate())-1) as Yr,
isnull((select sum(anet) from cvo_sbm_details t2 where t1.customer_code=t2.customer and yyyymmdd between DATEADD(YY,-1,@Date)				  and  DATEADD(YY,-1,DATEADD(SECOND, -1, DATEADD(MONTH, 1, @Date))) ),0) Jan,
isnull((select sum(anet) from cvo_sbm_details t2 where t1.customer_code=t2.customer and yyyymmdd between DATEADD(YY,-1,DATEADD(MONTH,1,@Date)) and  DATEADD(YY,-1,DATEADD(SECOND, -1, DATEADD(MONTH, 2, @Date))) ),0) Feb,
isnull((select sum(anet) from cvo_sbm_details t2 where t1.customer_code=t2.customer and yyyymmdd between DATEADD(YY,-1,DATEADD(MONTH,2,@Date)) and  DATEADD(YY,-1,DATEADD(SECOND, -1, DATEADD(MONTH, 3, @Date))) ),0) Mar,
isnull((select sum(anet) from cvo_sbm_details t2 where t1.customer_code=t2.customer and yyyymmdd between DATEADD(YY,-1,DATEADD(MONTH,3,@Date)) and  DATEADD(YY,-1,DATEADD(SECOND, -1, DATEADD(MONTH, 4, @Date))) ),0) Apr,
isnull((select sum(anet) from cvo_sbm_details t2 where t1.customer_code=t2.customer and yyyymmdd between DATEADD(YY,-1,DATEADD(MONTH,4,@Date)) and  DATEADD(YY,-1,DATEADD(SECOND, -1, DATEADD(MONTH, 5, @Date))) ),0) May,
isnull((select sum(anet) from cvo_sbm_details t2 where t1.customer_code=t2.customer and yyyymmdd between DATEADD(YY,-1,DATEADD(MONTH,5,@Date)) and  DATEADD(YY,-1,DATEADD(SECOND, -1, DATEADD(MONTH, 6, @Date))) ),0) Jun,
isnull((select sum(anet) from cvo_sbm_details t2 where t1.customer_code=t2.customer and yyyymmdd between DATEADD(YY,-1,DATEADD(MONTH,6,@Date)) and  DATEADD(YY,-1,DATEADD(SECOND, -1, DATEADD(MONTH, 7, @Date))) ),0) Jul,
isnull((select sum(anet) from cvo_sbm_details t2 where t1.customer_code=t2.customer and yyyymmdd between DATEADD(YY,-1,DATEADD(MONTH,7,@Date)) and  DATEADD(YY,-1,DATEADD(SECOND, -1, DATEADD(MONTH, 8, @Date))) ),0) Aug,
isnull((select sum(anet) from cvo_sbm_details t2 where t1.customer_code=t2.customer and yyyymmdd between DATEADD(YY,-1,DATEADD(MONTH,8,@Date)) and  DATEADD(YY,-1,DATEADD(SECOND, -1, DATEADD(MONTH, 9, @Date))) ),0) Sep,
isnull((select sum(anet) from cvo_sbm_details t2 where t1.customer_code=t2.customer and yyyymmdd between DATEADD(YY,-1,DATEADD(MONTH,9,@Date)) and  DATEADD(YY,-1,DATEADD(SECOND, -1, DATEADD(MONTH, 10, @Date))) ),0) Oct,
isnull((select sum(anet) from cvo_sbm_details t2 where t1.customer_code=t2.customer and yyyymmdd between DATEADD(YY,-1,DATEADD(MONTH,10,@Date)) and  DATEADD(YY,-1,DATEADD(SECOND, -1, DATEADD(MONTH, 11, @Date))) ),0) Nov,
isnull((select sum(anet) from cvo_sbm_details t2 where t1.customer_code=t2.customer and yyyymmdd between DATEADD(YY,-1,DATEADD(MONTH,11,@Date)) and  DATEADD(YY,-1,DATEADD(SECOND, -1, DATEADD(MONTH, 12, @Date))) ),0) Dec,
isnull((select sum(anet) from cvo_sbm_details t2 where t1.customer_code=t2.customer and yyyymmdd between DATEADD(YY,-1,@Date) and  DATEADD(YY,-1,DATEADD(SECOND, -1, DATEADD(MONTH, 12, @Date))) ),0) YTD
FROM ARMASTER t1
WHERE ADDR_SORT1='KEY ACCOUNT'
and address_type = 0
	UNION ALL
SELECT distinct LEFT(TERRITORY_CODE,2)Region, TERRITORY_CODE as Terr, t1.Customer_code as CustNum, T1.ADDRESS_NAME, case when ADDR2 like 'use Global%' then 'Closed Lab ShipTo' else '' end as Note, CASE WHEN STATUS_TYPE = '1' THEN 'Open' ELSE 'Closed' end as Status, 
(DATEPART(YEAR,getdate())-2) as Yr,
isnull((select sum(anet) from cvo_sbm_details t2 where t1.customer_code=t2.customer and yyyymmdd between DATEADD(YY,-2,@Date)				  and  DATEADD(YY,-2,DATEADD(SECOND, -1, DATEADD(MONTH, 1, @Date))) ),0) Jan,
isnull((select sum(anet) from cvo_sbm_details t2 where t1.customer_code=t2.customer and yyyymmdd between DATEADD(YY,-2,DATEADD(MONTH,1,@Date)) and  DATEADD(YY,-2,DATEADD(SECOND, -1, DATEADD(MONTH, 2, @Date))) ),0) Feb,
isnull((select sum(anet) from cvo_sbm_details t2 where t1.customer_code=t2.customer and yyyymmdd between DATEADD(YY,-2,DATEADD(MONTH,2,@Date)) and  DATEADD(YY,-2,DATEADD(SECOND, -1, DATEADD(MONTH, 3, @Date))) ),0) Mar,
isnull((select sum(anet) from cvo_sbm_details t2 where t1.customer_code=t2.customer and yyyymmdd between DATEADD(YY,-2,DATEADD(MONTH,3,@Date)) and  DATEADD(YY,-2,DATEADD(SECOND, -1, DATEADD(MONTH, 4, @Date))) ),0) Apr,
isnull((select sum(anet) from cvo_sbm_details t2 where t1.customer_code=t2.customer and yyyymmdd between DATEADD(YY,-2,DATEADD(MONTH,4,@Date)) and  DATEADD(YY,-2,DATEADD(SECOND, -1, DATEADD(MONTH, 5, @Date))) ),0) May,
isnull((select sum(anet) from cvo_sbm_details t2 where t1.customer_code=t2.customer and yyyymmdd between DATEADD(YY,-2,DATEADD(MONTH,5,@Date)) and  DATEADD(YY,-2,DATEADD(SECOND, -1, DATEADD(MONTH, 6, @Date))) ),0) Jun,
isnull((select sum(anet) from cvo_sbm_details t2 where t1.customer_code=t2.customer and yyyymmdd between DATEADD(YY,-2,DATEADD(MONTH,6,@Date)) and  DATEADD(YY,-2,DATEADD(SECOND, -1, DATEADD(MONTH, 7, @Date))) ),0) Jul,
isnull((select sum(anet) from cvo_sbm_details t2 where t1.customer_code=t2.customer and yyyymmdd between DATEADD(YY,-2,DATEADD(MONTH,7,@Date)) and  DATEADD(YY,-2,DATEADD(SECOND, -1, DATEADD(MONTH, 8, @Date))) ),0) Aug,
isnull((select sum(anet) from cvo_sbm_details t2 where t1.customer_code=t2.customer and yyyymmdd between DATEADD(YY,-2,DATEADD(MONTH,8,@Date)) and  DATEADD(YY,-2,DATEADD(SECOND, -1, DATEADD(MONTH, 9, @Date))) ),0) Sep,
isnull((select sum(anet) from cvo_sbm_details t2 where t1.customer_code=t2.customer and yyyymmdd between DATEADD(YY,-2,DATEADD(MONTH,9,@Date)) and  DATEADD(YY,-2,DATEADD(SECOND, -1, DATEADD(MONTH, 10, @Date))) ),0) Oct,
isnull((select sum(anet) from cvo_sbm_details t2 where t1.customer_code=t2.customer and yyyymmdd between DATEADD(YY,-2,DATEADD(MONTH,10,@Date)) and  DATEADD(YY,-2,DATEADD(SECOND, -1, DATEADD(MONTH, 11, @Date))) ),0) Nov,
isnull((select sum(anet) from cvo_sbm_details t2 where t1.customer_code=t2.customer and yyyymmdd between DATEADD(YY,-2,DATEADD(MONTH,11,@Date)) and  DATEADD(YY,-2,DATEADD(SECOND, -1, DATEADD(MONTH, 12, @Date))) ),0) Dec,
isnull((select sum(anet) from cvo_sbm_details t2 where t1.customer_code=t2.customer and yyyymmdd between DATEADD(YY,-2,@Date) and  DATEADD(YY,-2,DATEADD(SECOND, -1, DATEADD(MONTH, 12, @Date))) ),0) YTD
FROM ARMASTER t1
WHERE ADDR_SORT1='KEY ACCOUNT'
and address_type = 0
	UNION ALL
SELECT distinct LEFT(TERRITORY_CODE,2)Region, TERRITORY_CODE as Terr, t1.Customer_code as CustNum, T1.ADDRESS_NAME, case when ADDR2 like 'use Global%' then 'Closed Lab ShipTo' else '' end as Note, CASE WHEN STATUS_TYPE = '1' THEN 'Open' ELSE 'Closed' end as Status, 
(DATEPART(YEAR,getdate())-3) as Yr,
isnull((select sum(anet) from cvo_sbm_details t2 where t1.customer_code=t2.customer and yyyymmdd between DATEADD(YY,-3,@Date)				  and  DATEADD(YY,-3,DATEADD(SECOND, -1, DATEADD(MONTH, 1, @Date))) ),0) '01-Jan',
isnull((select sum(anet) from cvo_sbm_details t2 where t1.customer_code=t2.customer and yyyymmdd between DATEADD(YY,-3,DATEADD(MONTH,1,@Date)) and  DATEADD(YY,-3,DATEADD(SECOND, -1, DATEADD(MONTH, 2, @Date))) ),0) '02-Feb',
isnull((select sum(anet) from cvo_sbm_details t2 where t1.customer_code=t2.customer and yyyymmdd between DATEADD(YY,-3,DATEADD(MONTH,2,@Date)) and  DATEADD(YY,-3,DATEADD(SECOND, -1, DATEADD(MONTH, 3, @Date))) ),0) '03-Mar',
isnull((select sum(anet) from cvo_sbm_details t2 where t1.customer_code=t2.customer and yyyymmdd between DATEADD(YY,-3,DATEADD(MONTH,3,@Date)) and  DATEADD(YY,-3,DATEADD(SECOND, -1, DATEADD(MONTH, 4, @Date))) ),0) '04-Apr',
isnull((select sum(anet) from cvo_sbm_details t2 where t1.customer_code=t2.customer and yyyymmdd between DATEADD(YY,-3,DATEADD(MONTH,4,@Date)) and  DATEADD(YY,-3,DATEADD(SECOND, -1, DATEADD(MONTH, 5, @Date))) ),0) '05-May',
isnull((select sum(anet) from cvo_sbm_details t2 where t1.customer_code=t2.customer and yyyymmdd between DATEADD(YY,-3,DATEADD(MONTH,5,@Date)) and  DATEADD(YY,-3,DATEADD(SECOND, -1, DATEADD(MONTH, 6, @Date))) ),0) '06-Jun',
isnull((select sum(anet) from cvo_sbm_details t2 where t1.customer_code=t2.customer and yyyymmdd between DATEADD(YY,-3,DATEADD(MONTH,6,@Date)) and  DATEADD(YY,-3,DATEADD(SECOND, -1, DATEADD(MONTH, 7, @Date))) ),0) '07-Jul',
isnull((select sum(anet) from cvo_sbm_details t2 where t1.customer_code=t2.customer and yyyymmdd between DATEADD(YY,-3,DATEADD(MONTH,7,@Date)) and  DATEADD(YY,-3,DATEADD(SECOND, -1, DATEADD(MONTH, 8, @Date))) ),0) '08-Aug',
isnull((select sum(anet) from cvo_sbm_details t2 where t1.customer_code=t2.customer and yyyymmdd between DATEADD(YY,-3,DATEADD(MONTH,8,@Date)) and  DATEADD(YY,-3,DATEADD(SECOND, -1, DATEADD(MONTH, 9, @Date))) ),0) '09-Sep',
isnull((select sum(anet) from cvo_sbm_details t2 where t1.customer_code=t2.customer and yyyymmdd between DATEADD(YY,-3,DATEADD(MONTH,9,@Date)) and  DATEADD(YY,-3,DATEADD(SECOND, -1, DATEADD(MONTH, 10, @Date))) ),0) '10-Oct',
isnull((select sum(anet) from cvo_sbm_details t2 where t1.customer_code=t2.customer and yyyymmdd between DATEADD(YY,-3,DATEADD(MONTH,10,@Date)) and  DATEADD(YY,-3,DATEADD(SECOND, -1, DATEADD(MONTH, 11, @Date))) ),0) '11-Nov',
isnull((select sum(anet) from cvo_sbm_details t2 where t1.customer_code=t2.customer and yyyymmdd between DATEADD(YY,-3,DATEADD(MONTH,11,@Date)) and  DATEADD(YY,-3,DATEADD(SECOND, -1, DATEADD(MONTH, 12, @Date))) ),0) '12-Dec',
isnull((select sum(anet) from cvo_sbm_details t2 where t1.customer_code=t2.customer and yyyymmdd between DATEADD(YY,-3,@Date) and  DATEADD(YY,-3,DATEADD(SECOND, -1, DATEADD(MONTH, 12, @Date))) ),0) TYD
FROM ARMASTER t1
WHERE ADDR_SORT1='KEY ACCOUNT'
and address_type = 0
	) TMP ORDER BY Terr, custnum,Yr DESC

SELECT * FROM #CY T1
WHERE  EXISTS (select custnum from #CY T2 WHERE T1.CUSTNUM=T2.CUSTNUM GROUP BY custnum HAVING sum(YTD) <> 0) 


END


GO

GRANT EXECUTE ON  [dbo].[CVO_KeyAcct4YrMthlyTrend_MASTER_SP] TO [public]
GO
