SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE procedure [dbo].[cvo_Style_sales_ssrs_sp]
@DateFrom1 datetime,
@DateTo1 datetime,

@DateFrom2 datetime,
@DateTo2 datetime,

@Version varchar(1)

As

-- exec cvo_style_sales_ssrs_sp '12/1/2013', '12/31/2013', '12/1/2013', '12/31/2013', 's'

-- v1.1 - 091713 - TAG - add 12 weeks usage from DRP
-- 080715 - add us vision to Large accounts

---- comment out live
--declare @DateFrom1 datetime
--	declare @DateTo1 datetime
--declare @DateFrom2 datetime
--	declare @DateTo2 datetime
--SET @DateFrom1 = '12/1/2013'
--	SET @DateTo1 = '12/31/2013'
--SET @DateFrom2 = '9/1/2013'
--	SET @DateTo2 = '12/31/2013'
--declare @Version varchar(1)
--	SET @Version = 's'
---- comment out above live
	
declare		@JDateFrom1 int
declare		@JDateTo1 int

declare		@JDateFrom2 int
declare		@JDateTo2 int

     Begin

Set @JDateFrom1 = dbo.adm_get_pltdate_f(@datefrom1)
Set @JDateTo1 = dbo.adm_get_pltdate_f(@dateto1)

Set @JDateFrom2 = dbo.adm_get_pltdate_f(@datefrom2)
Set @JDateTo2 = dbo.adm_get_pltdate_f(@dateto2)


-- begin of year
declare		@dateBegYear datetime
set @dateBegYear = '01/01/' + convert(varchar(4),year(@DateTo1))
--select @datebegyear

-- Number of Months in Range 1
declare		@numMonths1 int
set @numMonths1 = datediff(d,@DateFrom1,@DateTo1)+1 -- switch to days

--select @nummonths1

-- Number of Months in Range 2
declare		@numMonths2 int
set @numMonths2 = datediff(d,@DateFrom2,@DateTo2)+1 -- switch to days
--select @nummonths2


IF(OBJECT_ID('tempdb.dbo.#cvo_ac_salessum') is not null)  
drop table #cvo_ac_salessum

IF(OBJECT_ID('tempdb.dbo.#cvo_ac_sales1') is not null)  -- basis for groupings on Style based reports
drop table #cvo_ac_sales1

IF(OBJECT_ID('tempdb.dbo.#cvo_ac_sales2') is not null)  -- ""
drop table #cvo_ac_sales2

IF(OBJECT_ID('tempdb.dbo.#cvo_ac_sales3') is not null)  -- ""
drop table #cvo_ac_sales3

IF(OBJECT_ID('tempdb.dbo.#cvo_ac_sales_style') is not null)  
drop table #cvo_ac_sales_style  

create table #CVO_AC_sales_Style	-- detail work file
(
part_no		varchar(30),
UnitSoldCur		decimal (18,0),
UnitSoldHist	decimal (18,0),
TotCost			decimal (18,2),
SalesAmtCur		decimal (18,2),
SalesAmtHist	decimal (18,2),
UnitsOpen		decimal (18,0),  -- EL 123113 add OpenUnits
UnitsSoldwoCL	decimal (18,0),
UnitsSoldwoCLLA	decimal (18,0),
UnitsSoldRX		decimal (18,0),
Avail			decimal (18,0),
po_on_order		decimal (18,0),
qty_returned	decimal (18,0),
QtyRetDef		decimal (18,0),
customer_code	varchar (8),
order_ctrl_num	varchar (12),
OrderType		varchar (2),
backorder_qty	decimal (18,0),
source		    varchar (1),
Sales_OnlyCur	decimal (18,0),
Units_onlyCur	decimal (18,0),
e12_wu          decimal (18,0) -- tag 091713 - v1.1
)

CREATE CLUSTERED INDEX [#CVO_AC_sales_Style_ind01] ON [dbo].[#CVO_AC_sales_Style] 
(
	part_no ASC
)

IF(OBJECT_ID('tempdb.dbo.#cvo_ac_salesSum') is not null)  
drop table #cvo_ac_salesSum

CREATE TABLE #CVO_AC_SalesSum
(part_no		varchar(30),
Brand			varchar(30),
Model			varchar(30),
StyleStatus		varchar(10),
ReleaseDate		varchar(10),
NumMonthsCur	int,
NumMonthsHist	Int,
Gender			varchar(20),
Vendor			varchar(12),
EyeSize			decimal (18,2),
BMeasure		decimal (18,2),
ColorFam		varchar (3),
ColorName		varchar (50),
Material		varchar (50),
FrameCat		varchar (50),
TypeCode		varchar (50),
TotCost			decimal (18,2),
LandedCost		decimal (18,2),
Markup			decimal (18,2),
SalesAmtCur		decimal (18,2),
SalesAmtHist	decimal (18,2),
AvgSoldPrice	decimal (18,2),
salesdiffpct	decimal (18,0),
UnitSoldCur		decimal (18,0),
UnitSoldHist	decimal (18,0),
unitdiffpct		decimal (18,0),
UnitsOpen		decimal (18,0), -- EL 123113 add OpenUnits
UnitsSoldwoCL	decimal (18,0),
UnitsSoldwoCLLA decimal (18,0),
UnitsSoldRX		decimal (18,0),
Avail			decimal (18,0),
po_on_order		decimal (18,0),
qty_returned	decimal (18,0),
QtyRetDef		decimal (18,0),
backorder_qty	decimal (18,0),
x_datefrom1		int,
x_dateto1		int,
x_datefrom2		int,
x_dateto2		int,
version			int,
sales_onlycur	decimal (18,0),
units_onlycur	decimal (18,0)
, e12_wu          decimal (18,0) -- v1.1
)

CREATE CLUSTERED INDEX [#CVO_AC_salessum_ind01] ON [dbo].[#CVO_AC_salessum] 
(
	Brand ASC,
	Model ASC,
    part_no asc)

--001 This brings in the data from the current tables (non-Historical) for the current period selected in the report
--select ' ** starting range 1 from orders ** '
insert into #CVO_AC_sales_Style
(part_no,
UnitSoldCur,
UnitSoldHist,
TotCost,
SalesAmtCur,
SalesAmtHist,
UnitsOpen, -- EL 123113 add OpenUnits
UnitsSoldwoCL,
UnitsSoldwoCLLA,
UnitsSoldRX,
Avail,
Po_on_order,
qty_returned,
QtyRetDef,
Customer_code,
order_ctrl_num,
orderType,
backorder_qty,
source,
Sales_OnlyCur,
Units_onlyCur
, e12_wu --v1.1
)
select ol.part_no,
case when (x.date_applied between @JDateFrom1 and @JDateTo1) then
		isnull(ol.shipped,0) - isnull(ol.cr_shipped,0) 
	else 0 end as unitsoldcur,
case when (x.date_applied between @JDateFrom2 and @JDateTo2) then
		isnull(ol.shipped,0) - isnull(ol.cr_shipped,0) 
	else 0 end as UnitSoldHist,
case when (x.date_applied between @JDateFrom1 and @JDateTo1) then
	(isnull(l.std_cost,0) + isnull(l.std_ovhd_dolrs,0) + isnull(l.std_util_dolrs,0)) 
	* (isnull(ol.shipped,0)-isnull(ol.cr_shipped,0))
	else 0 end as TotCost,
case when (x.date_applied between @JDateFrom1 and @JDateTo1) then
	ISNULL(ROUND(ol.curr_price - (ol.curr_price * (ol.discount / 100)),2),0) 
	* (isnull(ol.shipped,0) - isnull(ol.cr_shipped,0))
	else 0 end as SalesAmtCur,
case when (x.date_applied between @JDateFrom2 and @JDateTo2) then
	ISNULL(ROUND(ol.curr_price - (ol.curr_price * (ol.discount / 100)),2),0) 
	* (isnull(ol.shipped,0) - isnull(ol.cr_shipped,0))
	else 0 end as SalesAmtHist,
0 as UnitsOpen, -- EL 123113 add OpenUnits
CASE when (x.date_applied between @JDateFrom1 and @JDateTo1) and o.user_category != 'ST-CL' 
	and o.cust_code != '045217' then
    isnull(ol.shipped,0) - ISNULL(ol.cr_shipped,0)
	else 0 END as UnitsSoldwoCL, 
CASE when (x.date_applied between @JDateFrom1 and @JDateTo1) and o.user_category != 'ST-CL' 
-- 080715 - add us vision to Large accounts
	and o.cust_code not in ('045217','044198','032683') then
    isnull(ol.shipped,0) - ISNULL(ol.cr_shipped,0)
	else 0 END as UnitsSoldwoCLLA,
CASE when (x.date_applied between @JDateFrom1 and @JDateTo1) 
	and (o.user_category LIKE 'RX%'
	and o.user_category not like '%-RB') then		-- Only Rx AND NO REBILLS
	ISNULL(ol.shipped,0) - ISNULL(ol.cr_shipped,0)
	else 0 END as UnitsSoldRX, 
0,0, -- drp values to fill in later
CASE when (x.date_applied between @JDateFrom1 and @JDateTo1 and o.type = 'C' 
		and ol.return_code not like '05%') THEN	-- 062712 - exclude rebills 
	ISNULL(ol.cr_shipped,0)
	ELSE 0 END as qty_returned,
CASE when (x.date_applied between @JDateFrom1 and @JDateTo1) and o.type = 'C' 
		   and r.return_desc like 'Warranty defect%' THEN 
	ISNULL(ol.cr_shipped,0)
	ELSE 0 END as QtyRetDef,
o.cust_code, 
o.order_no,
CASE
	WHEN o.user_category = 'ST-CL' THEN 'Cl'
	WHEN o.user_category like 'RX%' THEN 'Rx'
	ELSE ''
END as [Type],
0 as backorder_qty,
'i' as source,
case when (x.date_applied between @JDateFrom1 and @JDateTo1) then
	ISNULL(ROUND(ol.curr_price - (ol.curr_price * (ol.discount / 100)),2),0) 
	* isnull(ol.shipped,0)
	else 0 end as Sales_onlyCur,
case when (x.date_applied between @JDateFrom1 and @JDateTo1) then
		isnull(ol.shipped,0)
	else 0 end as units_onlyCur
	, 0 as e12_wu -- v1.1

from ord_list ol WITH (NOLOCK)
inner join orders_all o with (NOLOCK) on ol.order_no = o.order_no and o.ext = ol.order_ext
left outer join orders_invoice oi (nolock) on o.order_no = oi.order_no and o.ext = oi.order_ext
left outer join artrx x (nolock) on x.trx_ctrl_num = oi.trx_ctrl_num
inner join inv_list l with (NOLOCK) on ol.part_no = l.part_no and ol.location = l.location
LEFT join po_retcode r with (NOLOCK) on r.return_code = ol.return_code
inner join inv_master i (nolock) on ol.part_no = i.part_no
inner join inv_master_add a (nolock) on ol.part_no = a.part_no
WHERE 1=1
and ((x.date_applied between @JDateFrom1 and @JDateTo1) 
  or (x.date_applied between @JDateFrom2 and @JDateTo2))
and ( i.type_code in ('FRAME', 'SUN') )
and ( (a.field_28  >= @dateBegYear) or (a.field_28 is null and i.obsolete=0) )
-- pom date is in current year or null
and o.status = 'T'
and ol.shipped-ol.cr_shipped <> 0

-- unposted ar invoices

insert into #CVO_AC_sales_Style
(part_no,
UnitSoldCur,
UnitSoldHist,
TotCost,
SalesAmtCur,
SalesAmtHist,
UnitsOpen, -- EL 123113 add OpenUnits
UnitsSoldwoCL,
UnitsSoldwoCLLA,
UnitsSoldRX,
Avail,
Po_on_order,
qty_returned,
QtyRetDef,
Customer_code,
order_ctrl_num,
orderType,
backorder_qty,
source,
Sales_OnlyCur,
Units_onlyCur
,e12_wu -- v1.1
)
select ol.part_no,
case when (x.date_applied between @JDateFrom1 and @JDateTo1) then
		isnull(ol.shipped,0) - isnull(ol.cr_shipped,0) 
	else 0 end as unitsoldcur,
case when (x.date_applied between @JDateFrom2 and @JDateTo2) then
		isnull(ol.shipped,0) - isnull(ol.cr_shipped,0) 
	else 0 end as UnitSoldHist,
case when (x.date_applied between @JDateFrom1 and @JDateTo1) then
	(isnull(l.std_cost,0) + isnull(l.std_ovhd_dolrs,0) + isnull(l.std_util_dolrs,0)) 
	* (isnull(ol.shipped,0)-isnull(ol.cr_shipped,0))
	else 0 end as TotCost,
case when (x.date_applied between @JDateFrom1 and @JDateTo1) then
	ISNULL(ROUND(ol.curr_price - (ol.curr_price * (ol.discount / 100)),2),0) 
	* (isnull(ol.shipped,0) - isnull(ol.cr_shipped,0))
	else 0 end as SalesAmtCur,
case when (x.date_applied between @JDateFrom2 and @JDateTo2) then
	ISNULL(ROUND(ol.curr_price - (ol.curr_price * (ol.discount / 100)),2),0) 
	* (isnull(ol.shipped,0) - isnull(ol.cr_shipped,0))
	else 0 end as SalesAmtHist,
0 as UnitsOpen, -- EL 123113 add OpenUnits
CASE when (x.date_applied between @JDateFrom1 and @JDateTo1) and o.user_category != 'ST-CL' 
	and o.cust_code != '045217' then
    isnull(ol.shipped,0) - ISNULL(ol.cr_shipped,0)
	else 0 END as UnitsSoldwoCL, 
CASE when (x.date_applied between @JDateFrom1 and @JDateTo1) and o.user_category != 'ST-CL' 
-- 080715 - add us vision to Large accounts
	and o.cust_code not in ('045217','044198','032683') THEN -- costco, luxxotical, us vision
    isnull(ol.shipped,0) - ISNULL(ol.cr_shipped,0)
	else 0 END as UnitsSoldwoCLLA,
CASE when (x.date_applied between @JDateFrom1 and @JDateTo1) and o.user_category LIKE 'RX%' then		-- Only Rx
	ISNULL(ol.shipped,0) - ISNULL(ol.cr_shipped,0)
	else 0 END as UnitsSoldRX, 
0,0, -- drp values to fill in later
CASE when (x.date_applied between @JDateFrom1 and @JDateTo1) and o.type = 'C' THEN 
	ISNULL(ol.cr_shipped,0)
	ELSE 0 END as qty_returned,
CASE when (x.date_applied between @JDateFrom1 and @JDateTo1) and o.type = 'C' 
		   and r.return_desc like 'Warranty defect%' THEN 
	ISNULL(ol.cr_shipped,0)
	ELSE 0 END as QtyRetDef,
o.cust_code, 
o.order_no,
CASE
	WHEN o.user_category = 'ST-CL' THEN 'Cl'
	WHEN o.user_category like 'RX%' THEN 'Rx'
	ELSE ''
END as [Type],
0 as backorder_qty,
'u' as source,
case when (x.date_applied between @JDateFrom1 and @JDateTo1) then
	ISNULL(ROUND(ol.curr_price - (ol.curr_price * (ol.discount / 100)),2),0) 
	* isnull(ol.shipped,0)
	else 0 end as Sales_onlyCur,
case when (x.date_applied between @JDateFrom1 and @JDateTo1) then
		isnull(ol.shipped,0)
	else 0 end as units_onlyCur
, 0 as e12_wu -- v1.1

from ord_list ol WITH (NOLOCK)
inner join orders_all o with (NOLOCK) on ol.order_no = o.order_no and o.ext = ol.order_ext
left outer join orders_invoice oi (nolock) on o.order_no = oi.order_no and o.ext = oi.order_ext
left outer join arinpchg_all x (nolock) on x.trx_ctrl_num = oi.trx_ctrl_num
inner join inv_list l with (NOLOCK) on ol.part_no = l.part_no and ol.location = l.location
LEFT join po_retcode r with (NOLOCK) on r.return_code = ol.return_code
inner join inv_master i (nolock) on ol.part_no = i.part_no
inner join inv_master_add a (nolock) on ol.part_no = a.part_no
WHERE 1=1
and ((x.date_applied between @JDateFrom1 and @JDateTo1) 
  or (x.date_applied between @JDateFrom2 and @JDateTo2))
and ( i.type_code in ('FRAME', 'SUN') )
and ( (a.field_28  >= @dateBegYear) or (a.field_28 is null and i.obsolete=0) )
-- pom date is in current year or null
and o.status = 'T'
and ol.shipped-ol.cr_shipped <> 0


--select count(*) from #cvo_ac_sales_style

--add insert for just DRP quantities
--select ' ** starting range 1 DRP based data ** '

insert into #CVO_AC_sales_Style
(part_no,
UnitSoldCur,
UnitSoldHist,
TotCost,
SalesAmtCur,
SalesAmtHist,
UnitsOpen, -- EL 123113 add OpenUnits
UnitsSoldwoCL,
UnitsSoldwoCLLA,
UnitsSoldRX,
Avail,
Po_on_order,
qty_returned,
QtyRetDef,
Customer_code,
order_ctrl_num,
orderType,
backorder_qty,
source,
Sales_OnlyCur,
Units_onlyCur
, e12_wu -- v1.1
)
select drp.part_no,
0 as UnitSoldCur, 
0 as UnitSoldHist,
0 as TotCost, 
0 as SalesAmtCur, 
0 as SalesAmtHist,
0 as UnitsOpen, -- EL 123113 add OpenUnits
0 as UnitsSoldwoCL, 
0 as UnitsSoldwoCLLA,
0 as UnitsSoldRX,  
sum(isnull(drp.on_hand,0)) as Avail,
sum(drp.non_allocated_po + drp.allocated_po +
	drp.non_allocated_po2 + drp.allocated_po2 +
	drp.non_allocated_po3 + drp.allocated_po3 +
	drp.non_allocated_po4 + drp.allocated_po4 +
	drp.non_allocated_po5 + drp.allocated_po5 +
	drp.non_allocated_po6 + drp.allocated_po6) as po_on_order,
0 as Qty_returned,
0 as QtyRetDef,
'drp' as Customer_code,
0 as order_ctrl_num,
'' as OrderType,
sum(isnull(drp.backorder,0)) as backorder_qty,
'd' as source,
0,
0
,0 as e12_wu -- v1.1
from dpr_report drp (nolock), inv_master i (nolock), inv_master_add a (nolock)
where drp.part_no = i.part_no and i.part_no = a.part_no
and i.type_code in ('FRAME', 'SUN')
and ( (a.field_28  >= @dateBegYear) or (a.field_28 is null and i.obsolete=0) )
-- pom date is in current year or nullwhere 
and drp.location='001' and i.void <> 'V'
group by drp.part_no

--v1.1 - get 12 weeks usage from drp

insert into #CVO_AC_sales_Style
(part_no,
UnitSoldCur,
UnitSoldHist,
TotCost,
SalesAmtCur,
SalesAmtHist,
UnitsOpen, -- EL 123113 add OpenUnits
UnitsSoldwoCL,
UnitsSoldwoCLLA,
UnitsSoldRX,
Avail,
Po_on_order,
qty_returned,
QtyRetDef,
Customer_code,
order_ctrl_num,
orderType,
backorder_qty,
source,
Sales_OnlyCur,
Units_onlyCur
, e12_wu -- v1.1
)
select drp.part_no,
0 as UnitSoldCur, 
0 as UnitSoldHist,
0 as TotCost, 
0 as SalesAmtCur, 
0 as SalesAmtHist,
0 as UnitsOpen, -- EL 123113 add OpenUnits
0 as UnitsSoldwoCL, 
0 as UnitsSoldwoCLLA,
0 as UnitsSoldRX,  
0 as Avail,
0 as  po_on_order,
0 as Qty_returned,
0 as QtyRetDef,
'drp' as Customer_code,
0 as order_ctrl_num,
'' as OrderType,
0 as backorder_qty,
'u' as source,
0,
0
,sum(isnull(e12_wu,0)) as e12_wu -- v1.1
from dpr_report drp (nolock), inv_master i (nolock), inv_master_add a (nolock)
where drp.part_no = i.part_no and i.part_no = a.part_no
and i.type_code in ('FRAME', 'SUN')
and ( (a.field_28  >= @dateBegYear) or (a.field_28 is null and i.obsolete=0) )
-- pom date is in current year or nullwhere 
and drp.location='ALL' and i.void <> 'V'
group by drp.part_no

--select count(*) from #cvo_ac_sales_style

--Include data from the history tables for range 1

-- select ' ** starting range 1 from order history ** '

insert into #CVO_AC_sales_Style
(part_no,
UnitSoldCur,
UnitSoldHist,
TotCost,
SalesAmtCur,
SalesAmtHist,
UnitsOpen, -- EL 123113 add OpenUnits
UnitsSoldwoCL,
UnitsSoldwoCLLA,
UnitsSoldRX,
Avail,
Po_on_order,
qty_returned,
QtyRetDef,
Customer_code,
order_ctrl_num,
orderType,
backorder_qty,
source,
Sales_OnlyCur,
Units_onlyCur
, e12_wu -- v1.1
)

select ol.part_no,
case when (o.date_shipped between @datefrom1 and @dateto1) then
		isnull(ol.shipped,0) - isnull(ol.cr_shipped,0) 
	else 0 end as unitsoldcur,
case when (o.date_shipped between @datefrom2 and @dateto2) then
		isnull(ol.shipped,0) - isnull(ol.cr_shipped,0) 
	else 0 end as UnitSoldHist,
case when (o.date_shipped between @datefrom1 and @dateto1) then
	(isnull(l.std_cost,0) + isnull(l.std_ovhd_dolrs,0) + isnull(l.std_util_dolrs,0)) 
	* (isnull(ol.shipped,0)-isnull(ol.cr_shipped,0))
	else 0 end as TotCost,
case when (o.date_shipped between @datefrom1 and @dateto1) then
	ISNULL(ROUND(ol.curr_price - (ol.curr_price * (ol.discount / 100)),2),0) 
	* (isnull(ol.shipped,0) - isnull(ol.cr_shipped,0))
	else 0 end as SalesAmtCur,
case when (o.date_shipped between @datefrom2 and @dateto2) then
	ISNULL(ROUND(ol.curr_price - (ol.curr_price * (ol.discount / 100)),2),0) 
	* (isnull(ol.shipped,0) - isnull(ol.cr_shipped,0))
	else 0 end as SalesAmtHist,
0 as UnitsOpen, -- EL 123113 add OpenUnits
CASE when (o.date_shipped between @datefrom1 and @dateto1) and o.user_category != 'ST-CL' 
	and o.cust_code not in ('045217') then
   isnull(ol.shipped,0) - ISNULL(ol.cr_shipped,0)
	else 0 END as UnitsSoldwoCL, 
CASE when (o.date_shipped between @datefrom1 and @dateto1) and o.user_category != 'ST-CL' 
	and o.cust_code not in ('045217','044198','032683') then
    isnull(ol.shipped,0) - ISNULL(ol.cr_shipped,0)
	else 0 END as UnitsSoldwoCLLA,
CASE when (o.date_shipped between @datefrom1 and @dateto1) and o.user_category LIKE 'RX%' then		-- Only Rx
	ISNULL(ol.shipped,0) - ISNULL(ol.cr_shipped,0)
	else 0 END as UnitsSoldRX, 
0,0, -- drp values to fill in later
CASE when (o.date_shipped between @datefrom1 and @dateto1) and o.type = 'C' THEN 
	ISNULL(ol.cr_shipped,0)
	ELSE 0 END as qty_returned,
CASE when (o.date_shipped between @datefrom1 and @dateto1) and o.type = 'C' 
		   and r.return_desc like 'Warranty defect%' THEN 
	ISNULL(ol.cr_shipped,0)
	ELSE 0 END as QtyRetDef,
o.cust_code, 
o.order_no,
CASE
	WHEN o.user_category = 'ST-CL' THEN 'Cl'
	WHEN o.user_category like 'RX%' THEN 'Rx'
	ELSE ''
END as [Type],
0 as backorder_qty,
'h' as source,
case when (o.date_shipped between @datefrom1 and @dateto1) then
	ISNULL(ROUND(ol.curr_price - (ol.curr_price * (ol.discount / 100)),2),0) 
	* (isnull(ol.shipped,0) )
	else 0 end as Sale_onlyCur,
case when (o.date_shipped between @datefrom1 and @dateto1) then isnull(ol.shipped,0)  
	else 0 end as units_onlyCur
	, 0 as e12_wu -- v1.1

from
CVO_orders_all_hist o with (NOLOCK) 
inner join  CVO_ord_list_hist ol (nolock) on ol.order_no = o.order_no and o.ext = ol.order_ext
inner join inv_master i (nolock) on i.part_no = ol.part_no
inner join inv_master_add a (nolock) on i.part_no = a.part_no
inner join inv_list l with (NOLOCK) on i.part_no = l.part_no and ol.location = l.location
LEFT join po_retcode r with (NOLOCK) on r.return_code = ol.return_code 
Where 1=1
and ((o.date_shipped between @datefrom1 and @dateto1) or (o.date_shipped between @datefrom2 and @dateto2) )
and (i.type_code in ('FRAME', 'SUN') )
and ( (a.field_28  >= @dateBegYear) or (a.field_28 is null and i.obsolete=0) )
-- pom date is in current year or null
and o.status = 'T'

--select source, count(*) from #cvo_ac_sales_style group by source

--select * from #CVO_AC_sales_Style where part_no like 'bctic%'

-- -- -- EL ADDED BELOW to pull in Open Order Qty's
-- brings in the OPEN QTY's
insert into #CVO_AC_sales_Style
(part_no,
UnitSoldCur,
UnitSoldHist,
TotCost,
SalesAmtCur,
SalesAmtHist,
UnitsOpen, 
UnitsSoldwoCL,
UnitsSoldwoCLLA,
UnitsSoldRX,
Avail,
Po_on_order,
qty_returned,
QtyRetDef,
Customer_code,
order_ctrl_num,
orderType,
backorder_qty,
source,
Sales_OnlyCur,
Units_onlyCur
, e12_wu --v1.1
)
select ol.part_no,
0 as unitsoldcur,
0 as UnitSoldHist,
0 as TotCost,
0 as SalesAmtCur,
0 as SalesAmtHist,
ordered as UnitsOpen,
0 as UnitsSoldwoCL, 
0 as UnitsSoldwoCLLA,
0 as UnitsSoldRX, 
0,0, -- drp values to fill in later
0 as qty_returned,
0 as QtyRetDef,
o.cust_code, 
o.order_no,
CASE
	WHEN o.user_category = 'ST-CL' THEN 'Cl'
	WHEN o.user_category like 'RX%' THEN 'Rx'
	ELSE ''
END as [Type],
0 as backorder_qty,
'o' as source,
0 as Sales_onlyCur,
0 as units_onlyCur,
0 as e12_wu -- v1.1

from ord_list ol WITH (NOLOCK)
inner join orders_all o with (NOLOCK) on ol.order_no = o.order_no and o.ext = ol.order_ext
left outer join orders_invoice oi (nolock) on o.order_no = oi.order_no and o.ext = oi.order_ext
inner join inv_list l with (NOLOCK) on ol.part_no = l.part_no and ol.location = l.location
LEFT join po_retcode r with (NOLOCK) on r.return_code = ol.return_code
inner join inv_master i (nolock) on ol.part_no = i.part_no
inner join inv_master_add a (nolock) on ol.part_no = a.part_no
WHERE 1=1
and ( i.type_code in ('FRAME', 'SUN') )
and ( (a.field_28  >= @dateBegYear) or (a.field_28 is null and i.obsolete=0) )
and o.status not in ('T','V')
and type='I'
and o.cust_code not in ('045217','044198','032683')

-- --
-- --

insert into #CVO_AC_SalesSum
(part_no,
Brand,
Model,
StyleStatus,
ReleaseDate,
NumMonthsCur,
NumMonthsHist,
Gender,
Vendor,
EyeSize,
BMeasure,
ColorFam,
ColorName,
Material ,
FrameCat ,
TypeCode,
UnitSoldCur ,
UnitSoldHist ,
TotCost,
LandedCost ,
Markup ,
SalesAmtCur ,
SalesAmtHist ,
AvgSoldPrice ,
salesdiffpct ,
unitdiffpct ,
UnitsOpen,
UnitsSoldwoCL ,
UnitsSoldwoCLLA,
UnitsSoldRX ,
Avail ,
po_on_order,
qty_returned ,
QtyRetDef,
backorder_qty,
x_datefrom1,
x_dateto1,
x_datefrom2,
x_dateto2,
--version,
sales_onlycur,
units_onlycur
, e12_wu -- v1.1
)

select  
ss.part_no,
i.category as Brand,
CASE	-- FORCE WALTER TO COMBINE A&N VARIANTS 062712
	WHEN IA.FIELD_2 LIKE 'WALTER%' then 'WALTER'
	ELSE ia.field_2 
END as Model,
CASE
	WHEN ia.field_28 is NULL and ia.category_1 = 'Y' THEN 'Watch'
	WHEN ia.field_28 is NULL and (ia.category_1 <> 'Y' or ia.category_1 is null) 
		 and i.void = 'N' and i.obsolete = 0
		 and i.non_sellable_flag = 'N' then 'Current'
	WHEN ia.field_28 is not NULL THEN CONVERT(VARCHAR(10), ia.field_28, 101)
	else '' 
END as StyleStatus,
CONVERT(VARCHAR(10), ia.field_26, 101),
Nummonthscur = 
-- change to days instead of months
case
	when ia.field_26 >= @datefrom1 then datediff(d,ia.field_26,@dateto1)+1
	else @nummonths1
end,
NumMonthsHist = 
case
	when ia.field_26 >= @datefrom2 then datediff(d,ia.field_26,@dateto2)+1
	else @nummonths2
end,
--OrderType,
ia.category_2 as Gender,
i.Vendor,
ia.field_17 as EyeSize,
ia.field_20 as BMeasure,
ia.category_5 as ColorFam,
ia.field_3 as ColorName,
ia.field_10 as Material,
ia.field_11 as FrameCat,
i.type_code as TypeCode,
sum(ISNULL(UnitSoldCur,0)) as UnitSoldCur,
sum(ISNULL(UnitSoldHist,0)) as UnitSoldHist,
sum(isnull(TotCost,0)) as TotCost,
CASE
	WHEN Sum(ISNULL(UnitSoldCur,0)) = 0 or Sum(UnitSoldCur) IS NULL THEN 0
	ELSE CONVERT (decimal (18,2), Sum(isnull(TotCost,0))/Sum(isnull(UnitSoldCur,0)))
END as LandedCost,
CASE
	WHEN Sum(ISNULL(UnitSoldCur,0)) = 0 or SUM(ISNULL(TotCost,0)) = 0 or Sum(UnitSoldCur) IS NULL or SUM(TotCost) IS NULL THEN 0
	ELSE CONVERT (decimal (18,2), (Sum(SalesAmtCur)/Sum(UnitSoldCur))/(SUM(TotCost)/Sum(UnitSoldCur)))
END as MarkUp,
sum(SalesAmtCur) as SalesAmtCur,
sum(SalesAmtHist) as SalesAmtHist,
--CASE
--	WHEN Sum(ISNULL(UnitSoldCur,0)) = 0 or Sum(UnitSoldCur) IS NULL THEN 0
--	ELSE CONVERT (decimal (18,2), Sum(SalesAmtCur)/Sum(UnitSoldCur)) 
--END as AvgSoldPrice,
CASE
	WHEN Sum(ISNULL(Units_onlyCur,0)) = 0 or Sum(Units_onlyCur) IS NULL THEN 0
	ELSE CONVERT (decimal (18,2), Sum(Sales_onlyCur)/Sum(Units_onlyCur)) 
END as AvgSoldPrice,
CASE
	WHEN Sum(ISNULL(SalesAmtHist,0)) = 0 or Sum(SalesAmtHist) IS NULL THEN 0
	ELSE CONVERT (decimal (18,0), ((Sum(SalesAmtCur) - Sum(SalesAmtHist))/Sum(SalesAmtHist))*100)
END as salesdiffpct,
CASE
	WHEN Sum(ISNULL(UnitSoldHist,0)) = 0 or Sum(UnitSoldHist) IS NULL THEN 0
	ELSE CONVERT (decimal (18,0), ((sum(UnitSoldCur) - Sum(UnitSoldHist))/Sum(UnitSoldHist))*100)
END as unitdiffpct,
sum(UnitsOpen) as UnitsOpen,
sum(UnitsSoldwoCL) as UnitsSoldwoCL,
sum(UnitsSoldwoCLLA) as UnitsSoldwoCLLA,

sum(ss.UnitsSoldRX) as UnitsSoldRX,
sum(ss.avail) as Avail,
sum(ss.po_on_order) as po_on_order,

sum(qty_returned) as TotalQtyRet,
sum(QtyRetDef) as QtyRetDef,
sum(isnull(backorder_qty,0)) as BackOrderQty,
--customer_code
--order_ctrl_num,
--date_shipped
@jdatefrom1,
@jdateto1,
@jdatefrom2,
@jdateto2,
--@version,
sum(sales_onlycur) as sales_onlycur,
sum(units_onlycur) as units_onlycur
, sum(e12_wu) as e12_wu -- v1.1

from #CVO_AC_sales_Style ss (nolock), 
     inv_master i (nolock), 
     inv_master_add ia (nolock)
where 1=1
--and ss.part_no = drp.part_no and drp.location = '001'
and i.type_code in ('FRAME', 'SUN')
and i.part_no = ss.part_no and ia.part_no = ss.part_no
group by 

ss.part_no,
i.category,
ia.field_2,
CASE
	WHEN ia.field_28 is NULL and ia.category_1 = 'Y' THEN 'Watch'
	WHEN ia.field_28 is NULL and (ia.category_1 <> 'Y' or ia.category_1 is null) and i.void = 'N' and i.obsolete = 0
		 and i.non_sellable_flag = 'N' then 'Current'
	WHEN ia.field_28 is not NULL THEN CONVERT(VARCHAR(10), ia.field_28, 101)
	else '' 
END,
ia.field_26,
--OrderType,
ia.category_2,
i.Vendor,
ia.field_17 ,
ia.field_20 ,
ia.category_5 ,
ia.field_3 ,
ia.field_10 ,
ia.field_11 ,
i.type_code 


--select count(*) from #cvo_ac_salessum
--select * from #cvo_ac_salessum

if @version = 'd'
begin
	--This select statement provides  the data for the SKU level detail report
	select 
	part_no, 
	brand, 
	model, 
	vendor, 
	releasedate, 
	stylestatus, 
		CASE when GENDER like 'Female-%' then replace(gender,'Female','F')
		when gender like 'Male-%' then replace(gender,'Male','M')
		when gender like 'Unisex-%' then replace(gender,'Unisex','U')
		else isnull(gender,'') end as Gender,
		-- gender, 
	EyeSize, BMeasure, ColorFam, ColorName, Material, FrameCat, 
	UnitSoldCur, UnitSoldHist, 
    unitdiffpct, Backorder_qty, 
    UnitsOpen,
	(UnitsSoldwoCL + backorder_qty) as UnitSoldwoCLwBO, SalesAmtCur, SalesAmtHist, salesdiffpct
	,UnitsSoldwoCL ,UnitsSoldwoCLLA,
	case
		when nummonthscur<=0 then 0
	-- calc by day and back into the month figure
		else CONVERT (decimal (18,0), (UnitsSoldwoCLla) + backorder_Qty)/numMonthscur*30.42 
		end as SalesRate,
	--SalesRate,
	UnitsSoldRX,
	Avail,
	po_on_order,
	qty_returned ,
	QtyRetDef,
	x_datefrom1,
	x_datefrom2,
	x_dateto1, 
	x_dateto2,
	version
	from #CVO_AC_SalesSum
	where StyleStatus is not NULL
end

if @version = 'S'
Begin
	-- select * from #cvo_ac_salessum where nummonthscur = 0

	--This select statement provides the data for Style level report
	select 
	-- Current and Watch Syles
	Brand,
	Model,
	Vendor,
	CONVERT(VARCHAR(10), min(convert(datetime, ReleaseDate)), 101) Releasedate, 
		--CONVERT(VARCHAR(10), min(convert(datetime, ReleaseDate)), 101) Releasedate, 
	max(StyleStatus) StyleStatus,
	case when max(stylestatus) <> min(stylestatus) then 'Partial POM' end as P_POM,
	CASE
		When max(StyleStatus) = 'Current' Then 1
		When max(StyleStatus) = 'Watch' Then 2
		Else 3 End as OrderStyle,
	CASE when GENDER like 'Female-%' then replace(gender,'Female','F')
		when gender like 'Male-%' then replace(gender,'Male','M')
		when gender like 'Unisex-%' then replace(gender,'Unisex','U')
		else isnull(gender,'') end as Gender,
	TypeCode,
	CASE
		WHEN Sum(ISNULL(UnitSoldCur,0)) = 0 or Sum(UnitSoldCur) IS NULL THEN 0
		ELSE CONVERT (decimal (18,2), Sum(TotCost)/Sum(UnitSoldCur))
	END as LandedCost,
--	CASE
--		WHEN Sum(ISNULL(UnitSoldCur,0)) = 0 or Sum(UnitSoldCur) IS NULL THEN 0
--		ELSE CONVERT (decimal (18,2), Sum(SalesAmtCur)/Sum(UnitSoldCur)) 
--	END as AvgSoldPrice,
	CASE
		WHEN Sum(ISNULL(Units_OnlyCur,0)) = 0 or Sum(Units_onlyCur) IS NULL THEN 0
		ELSE CONVERT (decimal (18,2), Sum(Sales_onlyCur)/Sum(Units_onlyCur)) 
	END as AvgSoldPrice,
	CASE
		WHEN Sum(ISNULL(UnitSoldCur,0)) = 0 or SUM(ISNULL(TotCost,0)) = 0 or Sum(UnitSoldCur) IS NULL or SUM(TotCost) IS NULL THEN 0
		ELSE CONVERT (decimal (18,2), (Sum(SalesAmtCur)/Sum(UnitSoldCur))/(SUM(TotCost)/Sum(UnitSoldCur)))
	END as MarkUp,
	sum(UnitSoldCur) as UnitSoldCur,
	sum(UnitSoldHist) as UnitSoldHist,
	case 
		when max(nummonthscur) <=0 then 0
	-- work as days - > month
	-- 8/6/12 - change to UnitsSoldwoCLLA from UnitsSoldwoCL per JC request
		else CONVERT (int, (sum(UnitsSoldwoCLla) + sum(Backorder_qty))/max(numMonthscur)*30.42) 
	end as [Monthly Sales Rate],		
	case
		when max(nummonthshist) <=0 then 0
		else CONVERT (int, (sum(UnitSoldHist))/max(numMonthshist)*30.42)
	end as [Monthly SalesRate Hist],								
	CASE
		WHEN max(nummonthscur) <=0 or max(nummonthshist) <=0 or 
			 Sum(ISNULL(UnitSoldHist,0)) = 0 or Sum(UnitSoldHist) IS NULL THEN 0
		ELSE CONVERT (int, (  (((((sum(UnitsSoldwoCLla) )/max(numMonthscur)*30.42)) 
			- ((sum(UnitSoldHist))/max(numMonthshist)*30.42)) / ((sum(UnitSoldHist))/max(numMonthshist)*30.42)) *100)  )
	END as ratediffpct,																				
	sum(SalesAmtCur) as SalesAmtCur,
	sum(UnitsOpen) as UnitsOpen,
	sum(UnitsSoldwoCL) as [Units woCL],
	sum(UnitsSoldwoCLLA) as [Units woCLLA],
	sum(backorder_Qty) as [BackOrdered Qty],
	sum(UnitsSoldwoCLLA + backorder_qty) as [Units woCLLA wBO],
	sum(UnitsSoldwoCLLA + UnitsOpen) as [Units woCL LA wAllOpen],
	sum(UnitsSoldRX) as UnitsRX,
	sum(qty_returned) as [Qty Returned],
	sum(QtyRetDef) as [Returned Defective],
	sum(Avail) as Avail,
	case WHEN max(nummonthscur) <=0 or max(nummonthshist) <=0 or 
			  Sum(ISNULL(UnitsSoldwoCLla,0)) = 0 or Sum(UnitsSoldwoCLla) IS NULL THEN 0
		 when sum(unitssoldwoclla) <0 then 999
		 else convert (decimal (18,1), sum(Avail)/((SUM(UnitsSoldwoCLla))/max(numMonthscur)*30.42))
	end as [Months Available],
	sum(po_on_order) as [po on order],
    sum(e12_wu) as e12_wu, -- v1.1
	x_datefrom1,
	x_datefrom2,
	x_dateto1,
	x_dateto2,
	version 
	-- NEW CODE
--	Into #CVO_AC_SALES1
	from #CVO_AC_salessum 
	where 1=1
	-- and StyleStatus is not null
--	and StyleStatus in ('Watch', 'Current')
	group by Brand, Model, Gender,Vendor, TypeCode, -- StyleStatus,
	x_datefrom1,
	x_datefrom2, 
	x_dateto1,
	x_dateto2,
	version 

end


End												  

GO
GRANT EXECUTE ON  [dbo].[cvo_Style_sales_ssrs_sp] TO [public]
GO
