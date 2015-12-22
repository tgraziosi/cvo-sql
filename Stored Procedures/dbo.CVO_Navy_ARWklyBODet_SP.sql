SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



-- =============================================
-- Author:		elabarbera
-- Create date: 5/22/2013
-- Description:	Navy Weekly A/R BO Detail
-- EXEC CVO_Navy_ARWklyBODet_SP '6/1/2013', '6/19/2013'
-- =============================================
CREATE PROCEDURE [dbo].[CVO_Navy_ARWklyBODet_SP]

@DateFrom datetime,
@DateTo datetime

AS
BEGIN
	SET NOCOUNT ON;
	SET DATEFIRST 6

-- RUN CODE FROM HERE

		--DECLARE @DateFrom datetime                                    
		--DECLARE @DateTo datetime
		--SET @DATEFROM = '1/1/2013'
		--SET @DATETO = '6/19/2013'		
				SET @dateTo=dateadd(second,-1,@dateTo)
				SET @dateTo=dateadd(day,1,@dateTo)

IF(OBJECT_ID('tempdb.dbo.#NavyNums') is not null)
drop table dbo.#NavyNums
select * into #NavyNums from (
SELECT distinct T2.TERRITORY_CODE AS Terr, t1.Store, t1.Customer_code as Customer, t1.ship_to_code as Ship_to, t2.Address_name as CustomerName, t1.StoreList,
t3.order_no, t3.ext, date_shipped, 
DATEADD(DAY, DATEDIFF(DAY, -1, DATEADD(d,7-DATEPART(dw,date_shipped),date_shipped)), -1) WkEnd,
(sum(ordered)-sum(shipped)) BONum, t4.part_no
FROM cvo_navy_info T1
JOIN armaster T2 ON T1.CUSTOMER_CODE=T2.CUSTOMER_CODE AND T1.SHIP_TO_CODE=T2.SHIP_TO_CODE
join orders_all T3 ON T1.CUSTOMER_CODE=T3.CUST_CODE AND T1.SHIP_TO_CODE=T3.SHIP_TO
join ord_list T4 on t3.order_no=t4.order_no and t3.ext=t4.order_ext
join inv_master t5 on t4.part_no=t5.part_no
where t5.type_code in ('frame','sun')
-- and date_shipped between DATEADD(YEAR, -1, DATEADD(YEAR, DATEDIFF(YEAR, 0, GETDATE()), 0) ) and DATEADD(MILLISECOND, -3,DATEADD(YEAR, DATEDIFF(YEAR, 0, GETDATE()) + 1, 0))
and date_shipped between @DateFrom and @DateTo
and t3.status='t'
and type='i'
group by T2.TERRITORY_CODE, t1.Store, t1.Customer_code, t1.ship_to_code, t2.Address_name, t1.StoreList,date_shipped, t3.order_no, t3.ext, t4.part_no, type
having (sum(ordered)-sum(shipped))>0
	UNION ALL
SELECT distinct T2.TERRITORY_CODE AS Terr, t1.Store, t1.Customer_code as Customer, t1.ship_to_code as Ship_to, t2.Address_name as CustomerName, t1.StoreList,
t3.order_no, t3.ext, date_shipped, 
DATEADD(DAY, DATEDIFF(DAY, -1, DATEADD(d,7-DATEPART(dw,date_shipped),date_shipped)), -1) WkEnd,
(sum(ordered)-sum(shipped)) BONum, t4.part_no
FROM cvo_navy_info T1
JOIN armaster T2 ON T1.CUSTOMER_CODE=T2.CUSTOMER_CODE AND T1.SHIP_TO_CODE=T2.SHIP_TO_CODE
join cvo_orders_all_hist T3 ON T1.CUSTOMER_CODE=T3.CUST_CODE AND T1.SHIP_TO_CODE=T3.SHIP_TO
join cvo_ord_list_hist T4 on t3.order_no=t4.order_no and t3.ext=t4.order_ext
join inv_master t5 on t4.part_no=t5.part_no
where t5.type_code in ('frame','sun')
-- and date_shipped between DATEADD(YEAR, -1, DATEADD(YEAR, DATEDIFF(YEAR, 0, GETDATE()), 0) ) and DATEADD(MILLISECOND, -3,DATEADD(YEAR, DATEDIFF(YEAR, 0, GETDATE()) + 1, 0))
and date_shipped between @DateFrom and @DateTo
and t3.status='t'
and type='i'
group by T2.TERRITORY_CODE, t1.Store, t1.Customer_code, t1.ship_to_code, t2.Address_name, t1.StoreList,date_shipped, t3.order_no, t4.part_no, t3.ext, TYPE
having (sum(ordered)-sum(shipped))>0
)tmp
--  select * from #NavyNums where wKeND<'1/15/2012'

select distinct Terr, Store, Customer, Ship_to, CustomerName, StoreList, WkEnd, DATEPART(YEAR,WkEnd)Yr,Part_no,sum(BONum) BONum
from #NavyNums
group by Terr, Store, Customer,  Ship_to, CustomerName, StoreList, WkEnd, part_no
order by Customer, Ship_to, WkEnd


END



GO
GRANT EXECUTE ON  [dbo].[CVO_Navy_ARWklyBODet_SP] TO [public]
GO
