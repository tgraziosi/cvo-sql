SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


-- =============================================
-- Author:		<elabarbera,,Elizabeth LaBarbera>
-- Create date: <12/5/2012,,>
-- Description:	<Count Entered Original ST Orders & Units by Day for Date Range,,>
-- =============================================
CREATE PROCEDURE [dbo].[SSRS_Count_ST_orders_byday]

@DateFrom Datetime,
@DateTo Datetime

AS
BEGIN
	SET NOCOUNT ON;

	--DECLARE @DateFrom datetime                                    
	--DECLARE @DateTo datetime		
	--SET @DateFrom = '1/1/2013'
	--SET @DateTo = '3/31/2013'
				SET @dateTo=dateadd(second,-1,@dateTo)
				SET @dateTo=dateadd(day,1,@dateTo)

IF(OBJECT_ID('tempdb.dbo.#OrdersDet') is not null)  
drop table #OrdersDet  
select ship_to_region, Cust_code, convert(varchar(10),date_entered,101) date_entered, order_no, user_category, who_entered, total_amt_order,
isnull((select sum(ordered) from ord_list t11 
	join inv_master t12 on t11.part_no=t12.part_no 
	where t1.order_no=t11.order_no 
	and t12.type_code in ('frame','sun') and ext=0),0) as UnitCount
INTO #OrdersDet
 from orders_all (NOLOCK) t1
where ext=0
and user_category like 'st%'
and right(user_category,2) not in ('RB','TB','PM') 
and status<>'v'
and void ='n'
and type='i'
and total_amt_order<>0
and date_entered between @DateFrom and @DateTo
order by t1.date_entered, t1.ship_to_region
-- select * from #ordersDet

IF(OBJECT_ID('tempdb.dbo.#OrdersSum') is not null)  
drop table #OrdersSum
select ship_to_region as 'Terr', Cust_code, Date_entered, count(cust_code) 'NumOrder',sum(UnitCount)'UnitCount'
INTO #OrdersSum
FROM #OrdersDet
group by ship_to_region, Cust_code, date_entered
-- select * from #ordersSum where terr=80625

select Terr, Date_entered, count(NumOrder)'NumOrders', sum(UnitCount)'UnitCount'
FROM #OrdersSum
where NumOrder>0
group by Terr, Date_entered
order by date_entered, Terr



END

GO
