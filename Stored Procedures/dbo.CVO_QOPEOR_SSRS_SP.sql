SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		ELABARBERA
-- Create date: 5/17/2013
-- Description:	LISTS FOR QOP AND EOR ORDER FORMS
-- EXEC CVO_QOPEOR_SSRS_SP
-- =============================================
CREATE PROCEDURE [dbo].[CVO_QOPEOR_SSRS_SP]

AS
BEGIN

	SET NOCOUNT ON;
DECLARE @setdate datetime
SET @setdate=GETDATE()
--SET @setdate= '12/31/2013'   -- uncomment to use a set date
	
declare @numberOfColumns int
declare @QOPStart datetime
declare @QOPEnd datetime
declare @EORDate datetime
SET @numberOfColumns = 3
SET @QOPStart = dateadd(month,-24,dateadd(m, datediff(m, 0, @setdate), 0))
SET @QOPEnd =   dateadd(month,-9,dateadd(second, -1,dateadd(m, datediff(m, 0, dateadd(m, 1, @setdate)), 0)))
SET @EORDate =  dateadd(month,-24,dateadd(m, datediff(m, 0, @setdate), 0))
-- select @QOPStart QOPStart, @QOPEnd QOPEND, @EORDate EORDate

IF(OBJECT_ID('tempdb.dbo.#Data') is not null)  
drop table #Data
select * INTO #Data from (
select 'QOP' as Prog, Brand, style, part_no, pom_date, 
case when gender LIKE '%CHILD%' THEN 'Kids' 
	when gender = 'FEMALE-ADULT' THEN 'Womens' 
	else 'Mens' end as Gender, 
Avail, ReserveQty, case when ReserveQty >5 then Avail else (case when Avail<=5 then 0 else avail-5 End) end as  TrueAvail
 from cvo_items_discontinue_vw where pom_date between @QOPStart and @QOPEnd and Avail >=1 and type in ('frame') 
UNION ALL
select 'EOR' as Prog, Brand, style, part_no, pom_date, 
case when gender LIKE '%CHILD%' THEN 'Kids' 
	when gender = 'FEMALE-ADULT' THEN 'Womens' 
	else 'Mens' end as Gender, Avail, ReserveQty, Avail as TrueAvail
from cvo_items_discontinue_vw where pom_date < @EORDate and Avail >=1 and type in ('frame')  )tmp 
order by Prog, gender, brand, style, part_no

delete from #data where TrueAvail=0

delete from #Data where part_no in (select I.part_no from inv_master I (nolock) join inv_master_add IA (nolock) on i.part_no = ia.part_no  where field_32 in ('HVC','RETAIL'))  

update #Data set Prog ='EOR' where part_no in (select part_no from #data where style in  (select style from #data group by brand, style having count(Style)=1 ) and prog='QOP')

--delete from #Data where part_no in (select distinct Part_no from (select distinct part_no from orders_all t1 join ord_list t2 on t1.order_no=t2.order_no and t1.ext=t2.order_ext where cust_code='045217' and type <> 'v' union all select distinct part_no from cvo_orders_all_hist t1 join cvo_ord_list_hist t2 on t1.order_no=t2.order_no and t1.ext=t2.order_ext where cust_code='045217' and type <> 'v' ) tmp )

IF(OBJECT_ID('tempdb.dbo.#Num') is not null)  
drop table #Num
SELECT DISTINCT PROG, GENDER, BRAND, STYLE, row_number() over(order by Prog, Gender, brand, style) AS Num INTO #Num FROM #DATA group by PROG, GENDER, BRAND, STYLE ORDER BY PROG, GENDER, BRAND, STYLE

-- select * from #data
-- select * from #Num

--select CASE WHEN Num%2=0 THEN 0 ELSE 1 END as Col, * from #Data t1 join #num t2 on t1.prog=t2.prog and t1.brand=t2.brand and t1.style=t2.style
select ((Num+ @numberOfColumns - 1) % @numberOfColumns + 1) as Col, 
t1.Prog, t1.Brand, t1.Style, t1.part_no, t1.pom_date, 
 t1.Gender,
 t1.Avail, t1.ReserveQty, 
 t1.TrueAvail as TrueAvail_2,
 CASE WHEN t1.TrueAvail > 100 THEN '100+' ELSE convert(varchar(20),convert(int,t1.TrueAvail)) END AS TrueAvail
 from #Data t1 join #num t2 on t1.prog=t2.prog and t1.gender=t2.gender and t1.brand=t2.brand and t1.style=t2.style order by Prog, Gender, Brand, Style

END
GO
