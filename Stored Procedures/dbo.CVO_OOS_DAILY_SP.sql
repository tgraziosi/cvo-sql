SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[CVO_OOS_DAILY_SP] 
AS
BEGIN
	SET NOCOUNT ON;
-- Out of Stock Report
IF(OBJECT_ID('tempdb.dbo.#T1') is not null)  
drop table #T1
select Type, T3.Category, t4.field_2 as Model, t4.field_3 as Color, 
(ISNULL(CAST(str(FIELD_17, 2, 0) AS VARCHAR(2)),'') + '/' + ISNULL(CAST(field_6 AS VARCHAR(2)),'') + '/' + ISNULL(CAST(field_8 AS VARCHAR(3)),'') ) as Size, t1.PART_NO, [Next PO Confirm Date], [Next PO Inhouse Date] as [Orig Next PO Inhouse Date],
CASE WHEN [Next PO Inhouse Date] < getdate() THEN DATEADD(wk, DATEDIFF(week,0,getdate()),7)
WHEN [Next PO Inhouse Date] >= DateAdd(Week,7,getdate()) THEN DATEADD(wk, DATEDIFF(week,0,getdate()),56)
ELSE ISNULL([Next PO Inhouse Date], DATEADD(wk, DATEDIFF(week,0,getdate()),56) ) END AS [Next PO Inhouse Date],
[Next PO],[Open Order Qty], t1.in_stock, Avail, getdate() as AsOfDate
INTO #T1
from cvo_out_of_stock_vw (nolock) t1
join inv_master (nolock) t3 on t1.part_no=t3.part_no
join inv_master_add (nolock) t4 on t3.part_no=t4.part_no 
JOIN CVO_ITEM_AVAIL_VW (NOLOCK) T5 ON T1.PART_NO=T5.PART_NO AND T1.LOCATION=T5.LOCATION
where avail <= -5
and t1.location='001'
and type_code in ('sun','frame')
and ISNULL((select sum(qty) from cvo_bin_inquiry_vw t11 where bin_no like 'ct%' and t1.part_no=t11.part_no AND t1.location=t11.location),0) !> -1*Avail
and ( field_28 > getdate() OR field_28 is NULL )
and t1.part_no not in (select part_no from inv_master_add where left(part_no,2)='ME' and field_2 between '0' and '99999')
and t1.part_no not in (select part_no from inv_master_add where left(part_no,2)='BC' and field_2 LIKE '%8%')
and T3.category not like 'UN'
and t1.part_no not like 'mexry%'
and t1.part_no not like 'IZ012%'
and t1.part_no not like 'IZ07%'
and t1.part_no not like 'IZX058%'
and t1.part_no not like 'IZX062%'
and t1.part_no not like 'IZX063%'
and t1.part_no not like 'IZX067%'
and t1.part_no not like 'IZ001%'
and t1.part_no not like 'IZ010%'
and t1.part_no not like 'IZ016%'
and t1.part_no not like 'IZ023%'
and t1.part_no not like 'IZ027%'
and t1.part_no not like 'IZ028%'
and t1.part_no not like 'IZ029%'
and t1.part_no not like 'IZ030%'
and t1.part_no not like 'IZ031%'
and t1.part_no not like 'IZ032%'
and t1.part_no not like 'IZ033%'
and t1.part_no not like 'IZ034%'
and t1.part_no not like 'IZ035%'
and t1.part_no not like 'IZ036%'
and t1.part_no not like 'IZ038%'
and t1.part_no not like 'IZ039%'
and t1.part_no not like 'IZ101%'
and t1.part_no not like 'IZ102%'
and t1.part_no not like 'IZ103%'
and t1.part_no not like 'IZ104%'
and t1.part_no not like 'IZ106%'
and t1.part_no not like 'IZ1300%'
and t1.part_no not like 'IZ1301%'
and t1.part_no not like 'IZ1302%'
and t1.part_no not like 'IZ1303%'
and t1.part_no not like 'IZ1304%'
and t1.part_no not like 'IZ1305%'
and t1.part_no not like 'IZ1306%'
and t1.part_no not like 'IZ201%'
and t1.part_no not like 'IZ202%'
and t1.part_no not like 'IZ203%'
and t1.part_no not like 'IZ204%'
and t1.part_no not like 'IZ205%'
and (Replen_qty_not_sa + ReplenQty) !> avail*-1
order by T3.Category, Type, t4.field_2, t4.field_3, t1.PART_NO
-- select * from #T1 where part_no = 'jm196gol5416'
-- --
-- -- CREATE A COPY OF YESTERDAYS REPORT
	IF (EXISTS
		(SELECT t.create_date FROM sys.tables t WHERE t.name = 'CVO_OutOfStock_DailyReport_OLD' and t.create_date < DateAdd(Day, Datediff(Day,0, GetDate() ), 0) ) )
	BEGIN
		IF(OBJECT_ID('CVO_OutOfStock_DailyReport_OLD') is not null)  
		drop table CVO_OutOfStock_DailyReport_OLD
		select * into CVO_OutOfStock_DailyReport_OLD from CVO_OutOfStock_DailyReport
--		select 'TABLE COPIED'
	END

-- -- CREATE TODAYS REPORT
IF(OBJECT_ID('CVO_OutOfStock_DailyReport') is not null)  
drop table CVO_OutOfStock_DailyReport
select *,
CASE WHEN [Next PO Inhouse Date] >= dateadd(week,8,getdate()) then 'RED'
WHEN [Next PO Inhouse Date] >= dateadd(week,6,getdate()) then 'ORANGE'
WHEN [Next PO Inhouse Date] >= dateadd(week,4,getdate()) then 'YELLOW'
ELSE '' END AS HIGHLIGHT
 INTO CVO_OutOfStock_DailyReport
 from #T1
 Order by Category, Type, Model, [Next PO Inhouse date]

-- -- SELECT CURRENT REPORT TO SCREEN
select * from CVO_OutOfStock_DailyReport
 
 -- select * from CVO_OutOfStock_DailyReport where TYPE = 'SUN'
END

GO
