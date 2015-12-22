SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




-- =============================================
-- Author:		elabarbera
-- Create date: 5/15/2013
-- Description:	Navy Weekly A/R Tracking Chart
-- EXEC CVO_Navy_ARWklyChart_SP '7/1/2013', '7/29/2013'
-- =============================================
CREATE PROCEDURE [dbo].[CVO_Navy_ARWklyChart_SP]

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
				
/*  Code to create and populate source Navy Info
CREATE TABLE CVO_NAVY_INFO (
customer_code varchar(10),
ship_to_code varchar(10),
store int,
storelist varchar(10),
locname varchar(60) )

GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, VIEW DEFINITION ON CVO_NAVY_INFO TO PUBLIC

INSERT INTO CVO_NAVY_INFO (CUSTOMER_CODE, SHIP_TO_CODE, STORE, STORELIST, LOCNAME)
select '016499', '','16','A/B','Little Creek' UNION ALL
select '016505', '','310','D','San Diego Hospital' UNION ALL
select '016507', '','34','B','Oceana' UNION ALL
select '016509', '','393','B/C','Whidbey ' UNION ALL
select '016516', '','407','C','Bangor Main Store' UNION ALL
select '023779', '','409','C','Everett Main' UNION ALL
select '026208', '','398','D','Bremerton Main' UNION ALL
select '016500', '0305','343','B','San Diego Main' UNION ALL
select '030774', '0014','238','D','Beaufort Hospital' UNION ALL
select '030774', '0015','191','C/D','Pensacola Main' UNION ALL
select '030774', '0016','169','A','Mayport Main' UNION ALL
select '030774', '0017','272','C','Corpus Christi' UNION ALL
select '030774', '0018','164','A','Jacksonville' UNION ALL
select '030774', '0022','730','C','Belle Chasse' UNION ALL
select '030774', '0023','265','C','Orlando' UNION ALL
select '030774', '0029','335','C','Port Hueneme' UNION ALL
select '030774', '0033','390','D','Monterey' UNION ALL
select '030774', '0035','366','B','Lemoore' UNION ALL
select '030774', '0036','437','A/B','Pearl Harbor' UNION ALL
select '030774', '0038','440','C/D','Guam' UNION ALL
select '030774', '0039','700','B','Yoko Japan' UNION ALL
select '030774', '0043','103','D','Annapolis' UNION ALL
select '030774', '0044','745','B','Bethesda' UNION ALL
select '030774', '0045','263','B','Memphis' UNION ALL
select '030774', '0046','29','D','Portsmouth Hospital' UNION ALL
select '041495', '','10','A','Norfolk Main' UNION ALL
select '041815', '','292','B','North Island' 
*/

IF(OBJECT_ID('tempdb.dbo.#NavyNums') is not null)
drop table dbo.#NavyNums
select * into #NavyNums from (
SELECT distinct T2.TERRITORY_CODE AS Terr, t1.Store, t1.Customer_code as Customer, t1.ship_to_code as Ship_to, t2.Address_name as CustomerName, t1.StoreList,
t3.order_no, t3.ext, date_shipped, 
DATEADD(DAY, DATEDIFF(DAY, -1, DATEADD(d,7-DATEPART(dw,date_shipped),date_shipped)), -1) WkEnd,
TYPE,
CASE WHEN TYPE='I' THEN sum(shipped) ELSE 0 END AS Shipped, 
CASE WHEN TYPE='I' THEN (sum(ordered)-sum(shipped))ELSE 0 END AS BO, 
CASE WHEN TYPE='I' THEN sum(ordered) ELSE 0 END AS Ordered,
CASE WHEN TYPE='C' THEN sum(cr_shipped) ELSE 0 END AS Returned
FROM cvo_navy_info T1
JOIN armaster T2 ON T1.CUSTOMER_CODE=T2.CUSTOMER_CODE AND T1.SHIP_TO_CODE=T2.SHIP_TO_CODE
join orders_all T3 ON T1.CUSTOMER_CODE=T3.CUST_CODE AND T1.SHIP_TO_CODE=T3.SHIP_TO
join ord_list T4 on t3.order_no=t4.order_no and t3.ext=t4.order_ext
join inv_master t5 on t4.part_no=t5.part_no
where t5.type_code in ('frame','sun')
-- and date_shipped between DATEADD(YEAR, -1, DATEADD(YEAR, DATEDIFF(YEAR, 0, GETDATE()), 0) ) and DATEADD(MILLISECOND, -3,DATEADD(YEAR, DATEDIFF(YEAR, 0, GETDATE()) + 1, 0))
and date_shipped between @DateFrom and @DateTo
and t3.status='t'
group by T2.TERRITORY_CODE, t1.Store, t1.Customer_code, t1.ship_to_code, t2.Address_name, t1.StoreList,date_shipped, t3.order_no, t3.ext, TYPE
	UNION ALL
SELECT distinct T2.TERRITORY_CODE AS Terr, t1.Store, t1.Customer_code as Customer, t1.ship_to_code as Ship_to, t2.Address_name as CustomerName, t1.StoreList,
t3.order_no, t3.ext, date_shipped, 
DATEADD(DAY, DATEDIFF(DAY, -1, DATEADD(d,7-DATEPART(dw,date_shipped),date_shipped)), -1) WkEnd,
TYPE,
CASE WHEN TYPE='I' THEN sum(shipped) ELSE 0 END AS Shipped, 
CASE WHEN TYPE='I' THEN (sum(ordered)-sum(shipped))ELSE 0 END AS BO, 
CASE WHEN TYPE='I' THEN sum(ordered) ELSE 0 END AS Ordered,
CASE WHEN TYPE='C' THEN sum(cr_shipped) ELSE 0 END AS Returned
FROM cvo_navy_info T1
JOIN armaster T2 ON T1.CUSTOMER_CODE=T2.CUSTOMER_CODE AND T1.SHIP_TO_CODE=T2.SHIP_TO_CODE
join cvo_orders_all_hist T3 ON T1.CUSTOMER_CODE=T3.CUST_CODE AND T1.SHIP_TO_CODE=T3.SHIP_TO
join cvo_ord_list_hist T4 on t3.order_no=t4.order_no and t3.ext=t4.order_ext
join inv_master t5 on t4.part_no=t5.part_no
where t5.type_code in ('frame','sun')
--and date_shipped between DATEADD(YEAR, -1, DATEADD(YEAR, DATEDIFF(YEAR, 0, GETDATE()), 0) ) and DATEADD(MILLISECOND, -3,DATEADD(YEAR, DATEDIFF(YEAR, 0, GETDATE()) + 1, 0))
and date_shipped between @DateFrom and @DateTo
and t3.status='t'
group by T2.TERRITORY_CODE, t1.Store, t1.Customer_code, t1.ship_to_code, t2.Address_name, t1.StoreList,date_shipped, t3.order_no, t3.ext, TYPE
)tmp
--  select * from #NavyNums where wKeND<'1/15/2012'

select distinct t3.Territory_code as Terr, t2.Store, t2.Customer_code as Customer, t2.Ship_to_code as Ship_to, t3.Address_name as CustomerName, t2.StoreList, 
ISNULL(WkEnd, DATEADD(DAY, DATEDIFF(DAY, -1, DATEADD(d,7-DATEPART(dw,@DateFrom),@DateFrom)), -1) )WkEnd,
ISNULL(DATEPART(YEAR,WkEnd), DATEPART(YEAR,getdate()))Yr,
ISNULL(CONVERT(VARCHAR(25),DATEADD(dd,-(DAY(WkEnd)-1),WkEnd),101),CONVERT(VARCHAR(25),DATEADD(dd,-(DAY(getdate())-1),getdate()),101))Mth,
sum(shipped) Shipped,
sum(BO) BO,
sum(Ordered) Ordered,
sum(Returned)*-1 Returned
from #NavyNums t1
right outer join cvo_navy_info t2 on t1.Customer=t2.customer_code and t1.ship_to=t2.ship_to_code
join armaster t3 on t2.customer_code=t3.customer_code and t2.ship_to_code=t3.ship_to_code
group by t3.Territory_code, t2.Store, Customer, t2.customer_code, Ship_to, t2.ship_to_code, t3.Address_name, t2.StoreList, WkEnd
order by t2.Customer_code, t2.Ship_to_code, WkEnd

-- select * from cvo_navy_info
-- EXEC CVO_Navy_ARWklyChart_SP '7/1/2013', '7/27/2013'

END




GO
GRANT EXECUTE ON  [dbo].[CVO_Navy_ARWklyChart_SP] TO [public]
GO
