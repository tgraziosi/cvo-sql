SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROC [dbo].[CVO_AC_Sales_SKU_sp] @WhereClause varchar(1024)='' 

AS

/****************************************************************************************
**  				Clear Vision
**  DATE		:	March 2012
**	CREATED BY	:   AM - Antler Consulting
**
**  DESCRIPTION	:	Procedure for explorer view
**		
**	Version		:   1.0
** 
**	exec [CVO_AC_Sales_SKU_sp] @whereclause = 'where date_shipped between '20120228' and '20120229'
*****************************************************************************************/

DECLARE
	@current_period_start_date	int,
	@current_period_end_date	int,
	@date_shipped_start 	varchar(8),
	@date_shipped_end 	varchar(8),
	@pos 			smallint,
	@pos0 			smallint,	
	@pos1 			smallint,
	@date_shipped_LYstart 	int,
	@date_shipped_LYend 	int



-- Start by using the current period as the date range. This will help if the user does not specify the date range during report run 

SELECT	@date_shipped_start = '19000101'
SELECT 	@date_shipped_end = '19000101'
SELECT	@current_period_end_date = period_end_date
	FROM	glco
SELECT	@current_period_start_date = period_start_date
	FROM	glprd
	WHERE	period_end_date = @current_period_end_date


if (charindex('date_shipped',@WhereClause) <> 0)

begin

	if (charindex('date_shipped BETWEEN',@WhereClause) <> 0)
	begin
		
		select @pos1 = charindex('date_shipped BETWEEN',@WhereClause) + 23
		select @date_shipped_start = substring(@WhereClause, @pos1,8)
		select @date_shipped_end   = convert(int,substring(@WhereClause, @pos1 + 14,8))
		select @WhereClause = replace (@WhereClause, substring(@whereclause, charindex('date_shipped BETWEEN',@WhereClause), 55), '1 = 1')
	end
/*
	else
	begin
		select @pos1 = charindex('date_shipped',@WhereClause)
		select @date_shipped_end = convert(int,substring(@WhereClause, @pos1 + 13,6))
		select @WhereClause = replace (@WhereClause, substring(@whereclause, charindex('date_shipped',@WhereClause), 19), '1 = 1')
	end
*/
end


if (@date_shipped_end = '19000101')
begin
		SELECT	@date_shipped_end = @current_period_end_date
end

if (@date_shipped_start = '19000101')
begin
	SELECT	@date_shipped_start = period_start_date
	FROM	glprd
	WHERE	period_end_date = @date_shipped_end
end

select @date_shipped_LYstart = datediff(dd,'1/1/1753',convert(datetime,DATEADD(Year,-1,CONVERT(VARCHAR(10),(dateadd(dd, @date_shipped_start - 693594, '12/30/1899')),101)))) +639906 

select @date_shipped_LYend = datediff(dd,'1/1/1753',convert(datetime,DATEADD(Year,-1,CONVERT(VARCHAR(10),(dateadd(dd, @date_shipped_end - 693594, '12/30/1899')),101)))) +639906 

create table #CVO_AC_sales_Style
(part_no varchar(30),
Brand varchar(30),
Model varchar(30),
[Current] varchar(3),
Watch varchar(3),
PlannedDate datetime,
DiscontinuedDate datetime,
OrderType varchar(2),
Gender varchar(20),
Vendor varchar(12),
UnitSoldTY decimal (18,2),
UnitSoldLY decimal (18,2),
TotCost decimal (18,2),
SalesAmtTY decimal (18,2),
SalesAmtLY decimal (18,2),
UnitsSoldwoCL decimal (18,2),
UnitsSoldwoCLLA decimal (18,2),
UnitsSoldRX decimal (18,2),
in_stock decimal (18,2),
po_on_order decimal (18,2),
qty_returned decimal (18,2),
QtyRetDef decimal (18,2),
customer_code varchar (8),
order_ctrl_num varchar (12),
backorder_qty decimal (18,2),
date_shipped int)




EXEC ("
insert into #CVO_AC_sales_Style
select ol.part_no,
i.category as Brand, 
a.field_2 as Model,
CASE
	WHEN i.VOID = 'N' AND i.OBSOLETE = 0 AND i.non_sellable_flag = 'N' THEN 'Yes'
	ELSE 'No'
END as [Current],
CASE
	WHEN a.category_1 = 'Y' THEN 'Yes'
	ELSE 'No'
END as Watch,
a.field_28 as PlannedDate,
a.datetime_1 as DiscontinuedDate,
CASE
	WHEN o.user_category = 'ST-CL' THEN 'Cl'
	WHEN o.user_category like 'RX%' THEN 'Rx'
	ELSE ''
END as [Type],
a.category_2 as Gender,
i.vendor,
CASE
	WHEN o.type = 'I' THEN ol.shipped
	ELSE ol.shipped*-1
END as UnitsSoldTY, 
0,
CASE
	WHEN o.type = 'I' THEN (ol.cost + ol.ovhd_dolrs + ol.util_dolrs) * ol.shipped
	ELSE (ol.cost + ol.ovhd_dolrs + ol.util_dolrs) * (-ol.shipped)
END as TotCost, 
CASE
	WHEN o.type = 'I' THEN ISNULL(ol.price,0)
	ELSE ISNULL(-ol.price,0)
END as SalesAmtTY, 
0,
CASE
	WHEN o.user_category = 'ST-CL' THEN 0		-- Excluding Closeouts
	WHEN o.cust_code = '045217' THEN 0		--Excluding Sales to Costco
	WHEN o.type = 'I' THEN ol.shipped
	ELSE ol.shipped*-1
END as UnitsSoldwoCL, 
CASE
	WHEN o.user_category = 'ST-CL' THEN 0		-- Excluding Closeouts
	WHEN o.cust_code = '045217' THEN 0		--Excluding Sales to Costco
	WHEN c.addr_sort1 in ('Distributor', 'Key Account') THEN 0		-- Excluding Large accounts
	WHEN o.type = 'I' THEN ol.shipped
	ELSE ol.shipped*-1
END as UnitsSoldwoCLLA, 
CASE
	WHEN o.user_category NOT LIKE 'RX%' THEN 0		-- Excluding Closeouts
	WHEN o.type = 'I' THEN ol.shipped
	ELSE ol.shipped*-1
END as UnitsSoldRX, 
inv.in_stock,
po_on_order,
CASE
	WHEN o.type = 'C' THEN ol.shipped
	ELSE 0
END,
CASE
	WHEN o.type = 'C' and r.return_desc like 'Warranty defect%' THEN ol.shipped
	ELSE 0
END as QtyRetDef,
o.cust_code, 
o.order_no, 
0,
o.date_shipped
from ord_list ol
inner join orders_all o on ol.order_no = o.order_no and o.ext = ol.order_ext
inner join inv_master i on ol.part_no = i.part_no
inner join inv_list l on i.part_no = l.part_no and ol.location = l.location
inner join inv_master_add a on a.part_no = i.part_no
inner join arcust c on o.cust_code = c.customer_code
inner join inventory inv on inv.part_no = l.part_no and inv.location = l.location
LEFT join po_retcode r on r.return_code = ol.return_code " 
+ @WhereClause + 
" and o.type_code in ('FRAME', 'SUN')
and datediff(dd,'1/1/1753',convert(datetime,o.date_shipped)) +639906 between " + @date_shipped_start + " and " + @date_shipped_end )


--Include data from the history tables
EXEC ("
insert into #CVO_AC_sales_Style
select ol.part_no,
i.category as Brand, 
a.field_2 as Model,
CASE
	WHEN i.VOID = 'N' AND i.OBSOLETE = 0 AND i.non_sellable_flag = 'N' THEN 'Yes'
	ELSE 'No'
END as [Current],
CASE
	WHEN a.category_1 = 'Y' THEN 'Yes'
	ELSE 'No'
END as Watch,
a.field_28 as PlannedDate,
a.datetime_1 as DiscontinuedDate,
CASE
	WHEN o.user_category = 'ST-CL' THEN 'Cl'
	WHEN o.user_category like 'RX%' THEN 'Rx'
	ELSE ''
END as [Type],
a.category_2 as Gender,
i.vendor,
CASE
	WHEN o.type = 'I' THEN ol.shipped
	ELSE ol.shipped*-1
END as UnitsSoldTY, 
0,
CASE
	WHEN o.type = 'I' THEN (ol.cost + ol.ovhd_dolrs + ol.util_dolrs) * ol.shipped
	ELSE (ol.cost + ol.ovhd_dolrs + ol.util_dolrs) * (-ol.shipped)
END as TotCost, 
CASE
	WHEN o.type = 'I' THEN ISNULL(ol.price,0)
	ELSE ISNULL(-ol.price,0)
END as SalesAmtTY, 
0,
CASE
	WHEN o.user_category = 'ST-CL' THEN 0		-- Excluding Closeouts
	WHEN o.cust_code = '045217' THEN 0		--Excluding Sales to Costco
	WHEN o.type = 'I' THEN ol.shipped
	ELSE ol.shipped*-1
END as UnitsSoldwoCL, 
CASE
	WHEN o.user_category = 'ST-CL' THEN 0		-- Excluding Closeouts
	WHEN o.cust_code = '045217' THEN 0		--Excluding Sales to Costco
	WHEN c.addr_sort1 in ('Distributor', 'Key Account') THEN 0		-- Excluding Large accounts
	WHEN o.type = 'I' THEN ol.shipped
	ELSE ol.shipped*-1
END as UnitsSoldwoCLLA, 
CASE
	WHEN o.user_category NOT LIKE 'RX%' THEN 0		-- Excluding Closeouts
	WHEN o.type = 'I' THEN ol.shipped
	ELSE ol.shipped*-1
END as UnitsSoldRX, 
inv.in_stock,
po_on_order,
CASE
	WHEN o.type = 'C' THEN ol.shipped
	ELSE 0
END,
CASE
	WHEN o.type = 'C' and r.return_desc like 'Warranty defect%' THEN ol.shipped
	ELSE 0
END as QtyRetDef,
o.cust_code, 
o.order_no, 
0,
o.date_shipped
from CVO_ord_list_hist ol
inner join CVO_orders_all_hist o on ol.order_no = o.order_no and o.ext = ol.order_ext
inner join inv_master i on ol.part_no = i.part_no
inner join inv_list l on i.part_no = l.part_no and ol.location = l.location
inner join inv_master_add a on a.part_no = i.part_no
inner join arcust c on o.cust_code = c.customer_code
inner join inventory inv on inv.part_no = l.part_no and inv.location = l.location
LEFT join po_retcode r on r.return_code = ol.return_code " 
+ @WhereClause + 
" and o.type_code in ('FRAME', 'SUN')
and datediff(dd,'1/1/1753',convert(datetime,o.date_shipped)) +639906 between " + @date_shipped_start + " and " + @date_shipped_end )

--Get Previous year information

EXEC ("
insert into #CVO_AC_sales_Style
select ol.part_no,
i.category as Brand, 
a.field_2 as Model,
CASE
	WHEN i.VOID = 'N' AND i.OBSOLETE = 0 AND i.non_sellable_flag = 'N' THEN 'Yes'
	ELSE 'No'
END as [Current],
CASE
	WHEN a.category_1 = 'Y' THEN 'Yes'
	ELSE 'No'
END as Watch,
a.field_28 as PlannedDate,
a.datetime_1 as DiscontinuedDate,
CASE
	WHEN o.user_category = 'ST-CL' THEN 'Cl'
	WHEN o.user_category like 'RX%' THEN 'Rx'
	ELSE ''
END as [Type],
a.category_2 as Gender,
i.vendor,
0,
CASE
	WHEN o.type = 'I' THEN ol.shipped
	ELSE ol.shipped*-1
END as UnitsSoldLY, 
CASE
	WHEN o.type = 'I' THEN (ol.cost + ol.ovhd_dolrs + ol.util_dolrs) * ol.shipped
	ELSE (ol.cost + ol.ovhd_dolrs + ol.util_dolrs) * (-ol.shipped)
END as TotCost, 
0,
CASE
	WHEN o.type = 'I' THEN ISNULL(ol.price,0)
	ELSE ISNULL(-ol.price,0)
END as SalesAmtLY, 
CASE
	WHEN o.user_category = 'ST-CL' THEN 0		-- Excluding Closeouts
	WHEN o.cust_code = '045217' THEN 0		--Excluding Sales to Costco
	WHEN o.type = 'I' THEN ol.shipped
	ELSE ol.shipped*-1
END as UnitsSoldwoCL, 
CASE
	WHEN o.user_category = 'ST-CL' THEN 0		-- Excluding Closeouts
	WHEN o.cust_code = '045217' THEN 0		--Excluding Sales to Costco
	WHEN c.addr_sort1 in ('Distributor', 'Key Account') THEN 0		-- Excluding Large accounts
	WHEN o.type = 'I' THEN ol.shipped
	ELSE ol.shipped*-1
END as UnitsSoldwoCLLA, 
CASE
	WHEN o.user_category NOT LIKE 'RX%' THEN 0		-- Excluding Closeouts
	WHEN o.type = 'I' THEN ol.shipped
	ELSE ol.shipped*-1
END as UnitsSoldRX, 
inv.in_stock,
po_on_order,
CASE
	WHEN o.type = 'C' THEN ol.shipped
	ELSE 0
END,
CASE
	WHEN o.type = 'C' and r.return_desc like 'Warranty defect%' THEN ol.shipped
	ELSE 0
END as QtyRetDef,
o.cust_code, 
o.order_no, 
0,
o.date_shipped
from ord_list ol
inner join orders_all o on ol.order_no = o.order_no and o.ext = ol.order_ext
inner join inv_master i on ol.part_no = i.part_no
inner join inv_list l on i.part_no = l.part_no and ol.location = l.location
inner join inv_master_add a on a.part_no = i.part_no
inner join arcust c on o.cust_code = c.customer_code
inner join inventory inv on inv.part_no = l.part_no and inv.location = l.location
LEFT join po_retcode r on r.return_code = ol.return_code " 
+ @WhereClause + 
" and o.type_code in ('FRAME', 'SUN')
and datediff(dd,'1/1/1753',convert(datetime,o.date_shipped)) +639906 between " + @date_shipped_LYstart + " and " + @date_shipped_LYend )

--Get previous year information from history tables
EXEC ("
insert into #CVO_AC_sales_Style
select ol.part_no,
i.category as Brand, 
a.field_2 as Model,
CASE
	WHEN i.VOID = 'N' AND i.OBSOLETE = 0 AND i.non_sellable_flag = 'N' THEN 'Yes'
	ELSE 'No'
END as [Current],
CASE
	WHEN a.category_1 = 'Y' THEN 'Yes'
	ELSE 'No'
END as Watch,
a.field_28 as PlannedDate,
a.datetime_1 as DiscontinuedDate,
CASE
	WHEN o.user_category = 'ST-CL' THEN 'Cl'
	WHEN o.user_category like 'RX%' THEN 'Rx'
	ELSE ''
END as [Type],
a.category_2 as Gender,
i.vendor,
0,
CASE
	WHEN o.type = 'I' THEN ol.shipped
	ELSE ol.shipped*-1
END as UnitsSoldLY, 
CASE
	WHEN o.type = 'I' THEN (ol.cost + ol.ovhd_dolrs + ol.util_dolrs) * ol.shipped
	ELSE (ol.cost + ol.ovhd_dolrs + ol.util_dolrs) * (-ol.shipped)
END as TotCost, 
0,
CASE
	WHEN o.type = 'I' THEN ISNULL(ol.price,0)
	ELSE ISNULL(-ol.price,0)
END as SalesAmtLY, 
CASE
	WHEN o.user_category = 'ST-CL' THEN 0		-- Excluding Closeouts
	WHEN o.cust_code = '045217' THEN 0		--Excluding Sales to Costco
	WHEN o.type = 'I' THEN ol.shipped
	ELSE ol.shipped*-1
END as UnitsSoldwoCL, 
CASE
	WHEN o.user_category = 'ST-CL' THEN 0		-- Excluding Closeouts
	WHEN o.cust_code = '045217' THEN 0		--Excluding Sales to Costco
	WHEN c.addr_sort1 in ('Distributor', 'Key Account') THEN 0		-- Excluding Large accounts
	WHEN o.type = 'I' THEN ol.shipped
	ELSE ol.shipped*-1
END as UnitsSoldwoCLLA, 
CASE
	WHEN o.user_category NOT LIKE 'RX%' THEN 0		-- Excluding Closeouts
	WHEN o.type = 'I' THEN ol.shipped
	ELSE ol.shipped*-1
END as UnitsSoldRX, 
inv.in_stock,
po_on_order,
CASE
	WHEN o.type = 'C' THEN ol.shipped
	ELSE 0
END,
CASE
	WHEN o.type = 'C' and r.return_desc like 'Warranty defect%' THEN ol.shipped
	ELSE 0
END as QtyRetDef,
o.cust_code, 
o.order_no, 
0,
o.date_shipped
from CVO_ord_list_hist ol
inner join CVO_orders_all_hist o on ol.order_no = o.order_no and o.ext = ol.order_ext
inner join inv_master i on ol.part_no = i.part_no
inner join inv_list l on i.part_no = l.part_no and ol.location = l.location
inner join inv_master_add a on a.part_no = i.part_no
inner join arcust c on o.cust_code = c.customer_code
inner join inventory inv on inv.part_no = l.part_no and inv.location = l.location
LEFT join po_retcode r on r.return_code = ol.return_code " 
+ @WhereClause + 
" and o.type_code in ('FRAME', 'SUN')
and datediff(dd,'1/1/1753',convert(datetime,o.date_shipped)) +639906 between " + @date_shipped_LYstart + " and " + @date_shipped_LYend )

/*

LEFT(CONVERT(VARCHAR(10),(dateadd(dd, h.date_shipped - 693594, '12/30/1899')),101),2) +
'/' +
SUBSTRING(CONVERT(VARCHAR(10),(dateadd(dd, h.date_shipped - 693594, '12/30/1899')),101),4,2) +
'/' +
RIGHT(CONVERT(VARCHAR(10),(dateadd(dd, h.date_shipped - 693594, '12/30/1899')),101), 4)

select RIGHT(CONVERT(VARCHAR(10),(dateadd(dd, h.date_shipped - 693594, '12/30/1899')),101), 4) - 1 from arinpchg_all h

datediff(d, '01/01/1753', convert(datetime, convert (varchar(2), accounting_month) 
+ '/' + convert (varchar(2), '01')  + '/' + convert (varchar(4), accounting_year))) + 639906

SELECT CONVERT(VARCHAR(10), SYSDATETIME(), 101) AS [MM/DD/YYYY]

*/

select 
part_no,
Brand,
Model,
CASE
	WHEN DiscontinuedDate is NULL and PlannedDate is NULL and Watch = 'Yes' THEN 'WATCH'
	WHEN DiscontinuedDate is NULL and PlannedDate is NULL and Watch = 'No' and [Current] = 'Yes' THEN 'Current'
	WHEN DiscontinuedDate is NULL and PlannedDate is not NULL THEN CONVERT(VARCHAR(10), PlannedDate, 101) 
	WHEN DiscontinuedDate is not NULL and PlannedDate is NULL THEN CONVERT(VARCHAR(10), DiscontinuedDate, 101) 
END as StyleStatus,
--OrderType,
Gender,
Vendor,
sum(UnitSoldTY) as UnitSoldTY,
sum(TotCost) as TotCost,
CASE
	WHEN Sum(UnitSoldTY) = 0 THEN 0
	ELSE Sum(TotCost)/Sum(UnitSoldTY) 
END as AvgCost,
sum(SalesAmtTY) as SalesAmtTY,
sum(SalesAmtLY) as SalesAmtLY,
CASE
	WHEN sum(UnitSoldTY) = 0 THEN 0
	ELSE Sum(SalesAmtTY)/Sum(UnitSoldTY) 
END as AvgSoldPrice,
CASE
	WHEN Sum(SalesAmtLY) = 0 THEN 0
	ELSE (Sum(SalesAmtTY) - Sum(SalesAmtLY)/Sum(SalesAmtLY))*100 
END as SalesDiff,
sum(UnitSoldTY) as UnitSoldTY,
sum(UnitSoldLY) as UnitSoldLY,
CASE
	WHEN sum(UnitSoldLY) = 0 THEN 0
	ELSE ((sum(UnitSoldTY) - sum(UnitSoldLY))/sum(UnitSoldLY))*100 
END as UnitDiff,
sum(UnitsSoldwoCL) as UnitsSoldwoCL,
sum(UnitsSoldwoCLLA) as UnitsSoldwoCLLA,
sum(UnitsSoldRX) as UnitsSoldRX,
in_stock,
po_on_order,
sum(qty_returned) as TotalQtyRet,
sum(QtyRetDef) as QtyRetDef
--customer_code
--order_ctrl_num,
--date_shipped
from #CVO_AC_sales_Style
group by part_no,Brand,Model,[Current],Watch,PlannedDate,DiscontinuedDate,Gender,Vendor,in_stock,po_on_order

DROP TABLE #CVO_AC_sales_Style
GO
GRANT EXECUTE ON  [dbo].[CVO_AC_Sales_SKU_sp] TO [public]
GO
