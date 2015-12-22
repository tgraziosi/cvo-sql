SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/*
CVO Credit by Style and Credits by SKU
August 2012 - TAG 
*/
/*
exec dbo.cvo_Style_defectives_sp '11/01/2012', '01/01/2013','11/01/2012', '01/01/2013'
"x_datefrom1=734503 and x_dateto1=734623 
and x_datefrom2=734503 and x_dateto2=734715 
and version=0 and vendor like '%comopt%' and brand like '%bcbg%'"
*/

CREATE procedure [dbo].[cvo_Style_defectives_sp] 
@datefrom1 datetime,
 @dateto1 datetime,
 @datefrom2 datetime,
 @dateto2 datetime
 
AS

--use cvo
--set nocount on

/**
Report 1:
Date range 1:  March 1st—May 31st
Date range 2:  Feb 1st—April 30th

Report 2:
Date range 1:  May 1st—May 31st
Date range 2:  April 1st—April 30th

**/

--declare
-- @datefrom1 datetime,
-- @dateto1 datetime,
-- @datefrom2 datetime,
-- @dateto2 datetime

--set @datefrom1='01/01/2012'
--set @dateto1='12/31/2012'
--set @datefrom2=@datefrom1
--set @dateto2=@dateto1 

declare		@JDateFrom1 int
declare		@JDateFrom2 int
declare		@JDateto1 int
declare		@JDateto2 int

set @jdateFrom1 = datediff(dd,'1/1/1950', convert(datetime, @datefrom1)) + 711858
set @jdateto1 = datediff(dd,'1/1/1950', convert(datetime, @dateto1)) + 711858
set @jdateFrom2 = datediff(dd,'1/1/1950', convert(datetime, @datefrom2)) + 711858
set @jdateto2 = datediff(dd,'1/1/1950', convert(datetime, @dateto2)) + 711858

-- begin of year
declare		@dateBegYear datetime
set @dateBegYear = '01/01/' + convert(varchar(4),year(@dateto1))
--select @datebegyear

-- Number of Months in Range 1
declare		@numMonths1 int
set @numMonths1 = datediff(d,@datefrom1,@dateto1)+1
--select @nummonths1

-- Number of Months in Range 2
declare		@numMonths2 int
set @numMonths2 = datediff(d,@datefrom2,@dateto2)+1
--select @nummonths2

IF(OBJECT_ID('tempdb.dbo.#cvo_credit_detail') is not null)  
drop table #cvo_credit_detail  

create table #CVO_credit_detail	-- detail work file
(
	vendor varchar(12),
	address_name varchar(40),
	part_no varchar(30),
	brand varchar(10),
	Model varchar(40),
	POMDate datetime,
	type_code varchar(10),
	ShipDate DATETIME,
	return_code varchar(10),
	reason varchar(40),
	Qty_ret decimal(20,0),
	qty_def decimal(20,0),
	cost decimal(20,8),
	ext_cost_ret decimal(20,8),
	ext_cost_def decimal(20,8),
	order_no int, 
	order_ext int
)

CREATE CLUSTERED INDEX [#cvo_credit_detail_ind01] ON [dbo].[#cvo_credit_detail] 
(
	part_no ASC
)


insert into #cvo_credit_detail
(	vendor ,
	address_name ,
	part_no ,
	brand ,
	Model ,
	pomdate,
	type_code ,
	ShipDate ,
	return_code ,
	reason ,
	Qty_ret ,
	qty_def ,
	cost ,
	ext_cost_ret ,
	ext_cost_def, 
	order_no,
	order_ext
)
select 
	i.vendor,
	ap.address_name,
	i.part_no ,
	i.category as Brand,
	ia.field_2 as Model,
	ia.field_28 as POMDate,
	i.type_code,
	convert(datetime,dateadd(d,ar.DATE_APPLIED-711858,'1/1/1950'),101) as ShipDate, 
	a.return_code,
	reason = (select return_desc from po_retcode p (nolock) where a.return_code = p.return_code), 
	a.cr_shipped as Qty_ret ,
	case when left(a.return_code,2) = '04' then cr_shipped else 0 end as qty_def,
	a.cost,
	cast ( (a.cr_shipped * a.cost) as decimal (20,8) )as ext_cost_ret,
	case when left(a.return_code,2) = '04' then 
		cast ( (a.cr_shipped * a.cost) as decimal (20,8) ) else 0 end as ext_cost_def,
	a.order_no, a.order_ext
--into #tag_test
from ord_list a (nolock)
	inner join orders b (nolock) on a.order_no = b.order_no and a.order_ext = b.ext
	inner join inv_master i (nolock) on a.part_no = i.part_no
	inner join inv_master_add ia (nolock) on i.part_no = ia.part_no
	left outer join apmaster ap (nolock) on i.vendor = ap.vendor_code
	inner join orders_invoice oi on b.order_no = oi.order_no and b.ext = oi.order_ext
	inner join artrx ar on oi.trx_ctrl_num = ar.trx_ctrl_num
where i.type_code in ('frame','sun','parts')
	and b.type = 'c' and b.status='t' and a.cr_shipped >0
	and exists (select * from inv_tran (nolock) where a.order_no = tran_no and
			a.order_ext = tran_ext and a.line_no = tran_line)
	and ((ar.date_applied between @jdatefrom1 and @jdateto1))
--
--tempdb..sp_help #tag_test
-- unposted ar invoices

insert into #cvo_credit_detail
(	vendor ,
	address_name ,
	part_no ,
	brand ,
	Model ,
	pomdate,
	type_code ,
	ShipDate ,
	return_code ,
	reason ,
	Qty_ret ,
	qty_def ,
	cost ,
	ext_cost_ret ,
	ext_cost_def, 
	order_no,
	order_ext
)
select 
	i.vendor,
	ap.address_name,
	i.part_no ,
	i.category as Brand,
	ia.field_2 as Model,
	ia.field_28 as pomdate,
	i.type_code,
	convert(varchar,dateadd(d,ar.DATE_APPLIED-711858,'1/1/1950'),101) as ShipDate, 
	a.return_code,
	reason = (select return_desc from po_retcode p (nolock) where a.return_code = p.return_code), 
	cr_shipped as Qty_ret ,
	case when left(a.return_code,2) = '04' then cr_shipped else 0 end as qty_def,
	a.cost,
	cast ( (a.cr_shipped * a.cost) as decimal (20,8) )as ext_cost_ret,
	case when left(a.return_code,2) = '04' then 
		cast ( (a.cr_shipped * a.cost) as decimal (20,8) ) else 0 end as ext_cost_def,
	a.order_no, a.order_ext
from ord_list a (nolock)
inner join orders b (nolock) on a.order_no = b.order_no and a.order_ext = b.ext
inner join inv_master i (nolock) on a.part_no = i.part_no
inner join inv_master_add ia (nolock) on i.part_no = ia.part_no
left outer join apmaster ap (nolock) on i.vendor = ap.vendor_code
inner join orders_invoice oi on b.order_no = oi.order_no and b.ext = oi.order_ext
inner join arinpchg ar on oi.trx_ctrl_num = ar.trx_ctrl_num

where i.type_code in ('frame','sun','parts')
and b.type = 'c' and b.status='t' and a.cr_shipped >0
and exists (select * from inv_tran (nolock) where a.order_no = tran_no and
		a.order_ext = tran_ext and a.line_no = tran_line)
and ((ar.date_applied between @jdatefrom1 and @jdateto1) )

-- Historical data for date range 1 and 2

insert into #cvo_credit_detail
(	vendor ,
	address_name ,
	part_no ,
	brand ,
	Model ,
	pomdate,
	type_code ,
	ShipDate ,
	return_code ,
	reason ,
	Qty_ret ,
	qty_def ,
	cost ,
	ext_cost_ret ,
	ext_cost_def, 
	order_no,
	order_ext
)
select 
	i.vendor,
	ap.address_name,
	i.part_no ,
	i.category as Brand,
	ia.field_2 as Model,
	ia.field_28 as pomdate,
	i.type_code,
	b.date_shipped as ShipDate,
	isnull(a.return_code,'06-13'),
	reason = 
		(select return_desc from po_retcode p (nolock) 
		  where p.return_code = isnull(a.return_code,'06-13')), 
	cr_shipped as Qty_ret ,
	case when left(isnull(a.return_code,'06-13'),2) = '04' then cr_shipped else 0 end as qty_def,
	a.cost,
	cast ( (a.cr_shipped * a.cost) as decimal (20,8) )as ext_cost_ret,
	case when left(a.return_code,2) = '04' then 
		cast ( (a.cr_shipped * a.cost) as decimal (20,8) ) else 0 end as ext_cost_def,
	a.order_no, a.order_ext
from cvo_ord_list_hist a (nolock)
inner join cvo_orders_all_hist b (nolock) on a.order_no = b.order_no and a.order_ext = b.ext
inner join inv_master i (nolock) on a.part_no = i.part_no
inner join inv_master_add ia (nolock) on i.part_no = ia.part_no
left outer join apmaster ap (nolock) on i.vendor = ap.vendor_code
where i.type_code in ('frame','sun','parts')
and b.type = 'c' and b.status='t' and a.cr_shipped >0
and ((b.date_shipped  between @datefrom1 and @dateto1))


IF(OBJECT_ID('tempdb.dbo.#cvo_credit_summary') is not null)  
drop table #cvo_credit_summary

CREATE TABLE #cvo_credit_summary
(vendor varchar(10), 
address_name varchar(40), 
part_no varchar(30),
brand varchar(10), 
model varchar(20), 
pomdate datetime,
type_code varchar(10), 
QtyReturned decimal(20,0), 
QtyDefect decimal(20,0),
ExtCostRet decimal(20,8),
ExtCostdef decimal(20,8),
[rct_qty_hist] decimal(20,8),
[Sales_rx_qty_hist] decimal(20,8),
[Sales_st_qty_hist] decimal(20,8)
)


CREATE CLUSTERED INDEX [#cvo_credit_summary_ind01] ON [dbo].[#cvo_credit_summary] 
(part_no ASC)

insert into #CVO_Credit_summary
(vendor, address_name, 
part_no, brand, model, pomdate, type_code, 
QtyReturned, 
QtyDefect,
ExtCostRet,
ExtCostdef,
rct_qty_hist,
Sales_rx_qty_hist,
Sales_st_qty_hist
)
select vendor, address_name, 
part_no, brand, model, pomdate, type_code, 
-- return_code, reason, 
sum(qty_ret) as QtyReturned,
sum(qty_def) as QtyDefect,
sum(ext_cost_ret) as ExtCostRet,
sum(ext_cost_def) as ExtCostdef,
0,0,0
from #cvo_credit_detail
group by vendor, address_name, 
part_no, brand, model, pomdate, type_code

-- select * from #cvo_credit_summary

IF(OBJECT_ID('tempdb..#cvo_sales_detail') is not null)  
drop table #cvo_sales_detail

create table #cvo_sales_detail
( part_no varchar(30),
sales_rx_qty_hist decimal(20,8),
sales_st_qty_hist decimal(20,8)
)
CREATE CLUSTERED INDEX [#cvo_sales_detail_ind01] ON [dbo].[#cvo_sales_detail] 
(part_no ASC)

insert into #cvo_sales_detail
(part_no,
sales_rx_qty_hist,
sales_st_qty_hist
)
select a.part_no, case when left(b.user_category,2)='RX' then sum(isnull(a.shipped,0)) else 0 end,
				  case when left(b.user_category,2)='ST' then sum(isnull(a.shipped,0)) else 0 end
from ord_list a (nolock) 
	inner join #cvo_credit_summary ccs (nolock) on ccs.part_no = a.part_no
	inner join orders_all b (NOLOCK) on	(a.order_no = b.order_no and a.order_ext = b.ext)
	where a.part_type = 'P' and right(b.user_category,2) <>'RB'
					and b.type = 'I'and b.status = 'T'
					and b.date_shipped between @datefrom2 and @dateto2
group by a.part_no, b.user_category
union
select a.part_no, case when left(b.user_category,2) = 'RX' then sum(isnull(a.shipped,0)) else 0 end,
				case when left(b.user_category,2) = 'ST' then sum(isnull(a.shipped,0)) else 0 end
from cvo_ord_list_hist a (nolock) 
	inner join #cvo_credit_summary ccs (nolock) on ccs.part_no = a.part_no
	inner join cvo_orders_all_hist b (NOLOCK) on	(a.order_no = b.order_no and a.order_ext = b.ext)
	where a.part_type = 'P' and right(b.user_category,2) <>'RB'
						and b.type = 'I'and b.status = 'T'
						and b.date_shipped between @datefrom2 and @dateto2
group by a.part_no, b.user_category

;with cte as
(select a.part_no, sum(isnull(a.quantity,0)) history_value from receipts a(nolock) group by a.part_no)
update cs  set cs.rct_qty_hist = isnull(cte.history_value,0) 
from #cvo_credit_summary cs, cte where cs.part_no = cte.part_no

;with cte as
(select a.part_no, sum(isnull(a.sales_rx_qty_hist,0)) history_value from 
#cvo_sales_detail a(nolock) group by a.part_no)
update cs set cs.sales_rx_qty_hist = isnull(cte.history_value,0) 
from #cvo_credit_summary cs, cte where cs.part_no = cte.part_no

;with cte as
(select a.part_no, sum(isnull(a.sales_st_qty_hist,0)) history_value from 
#cvo_sales_detail a(nolock) group by a.part_no)
update cs  set sales_st_qty_hist = isnull(cte.history_value,0) 
from #cvo_credit_summary cs, cte where cs.part_no = cte.part_no

-- finally, report time...

select cd.vendor, 
cd.address_name, 
--cd.part_no , 
cd.brand , 
cd.model , 
case when cd.pomdate > @dateto1 then null else cd.pomdate end as pomdate,
cd.type_code , 
cd.return_code ,
cd.reason ,
sum(cd.qty_ret) qty_ret,
sum(cd.qty_def) qty_def,
sum(cd.ext_cost_ret) ext_cost_ret,
sum(cd.ext_cost_def) ext_cost_def,
cs.rct_qty_hist ,
cs.sales_rx_qty_hist ,
cs.sales_st_qty_hist 

from #cvo_credit_detail cd, #cvo_credit_summary cs
where cd.vendor = cs.vendor and cd.part_no = cs.part_no
group by 
cd.vendor, 
cd.address_name, 
--cd.part_no, 
cd.brand, 
cd.model, 
cd.pomdate,
cd.type_code, 
cd.return_code,
cd.reason,
cs.rct_qty_hist,
cs.sales_rx_qty_hist,
cs.sales_st_qty_hist

GO
GRANT EXECUTE ON  [dbo].[cvo_Style_defectives_sp] TO [public]
GO
