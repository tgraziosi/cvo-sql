SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/*
select * from cvo_product_defectives_vw where brand = 'bcbg'
exec cvo_product_defectives_sp @brand=N'BCBG,CVO', @vendor=N'eri001,counto',
@datefrom=N'01/01/2012 00:00', @dateto=N'12/31/2012 23:59'

exec cvo_product_defectives_sp '10/1/2012','1/9/2013'
*/


CREATE procedure [dbo].[cvo_product_defectives_sp]
--@brand varchar(1000),
--@vendor varchar(1000),
@DateFrom datetime,
@DateTo datetime

as 

--declare @datefrom datetime
--declare @dateto datetime
--set @datefrom = '10/1/2012'
--set @dateto = '12/31/2012'

declare		@JDateFrom int
declare		@JDateto int

set @jdateFrom = datediff(dd,'1/1/1950', convert(datetime, @datefrom)) + 711858
set @jdateto = datediff(dd,'1/1/1950', convert(datetime, @dateto)) + 711858

--select @jdatefrom, @jdateto, @brand, @vendor, @datefrom, @dateto

-- credits and sales first 

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
	isnull((select return_desc from po_retcode p (nolock) where a.return_code = p.return_code),'Sales') as reason, 
	a.cr_shipped as Qty_ret ,
	case when left(a.return_code,2) = '04' then cr_shipped else 0 end as qty_def,
	a.cost,
	cast ( (a.cr_shipped * a.cost) as decimal (20,8) )as ext_cost_ret,
	case when left(a.return_code,2) = '04' then 
		cast ( (a.cr_shipped * a.cost) as decimal (20,8) ) else 0 end as ext_cost_def,
	0 as rct_qty_hist,
	case when left(b.user_category,2) = 'rx' then shipped else 0 end as Sales_rx_qty_hist,
	case when left(b.user_category,2) <> 'rx' then shipped else 0 end as Sales_st_qty_hist,
	a.order_no, a.order_ext
	
into #temp

from ord_list a (nolock)
	inner join orders b (nolock) on a.order_no = b.order_no and a.order_ext = b.ext
	inner join inv_master i (nolock) on a.part_no = i.part_no
	inner join inv_master_add ia (nolock) on i.part_no = ia.part_no
	left outer join apmaster ap (nolock) on i.vendor = ap.vendor_code
	inner join orders_invoice oi on b.order_no = oi.order_no and b.ext = oi.order_ext
	inner join artrx ar on oi.trx_ctrl_num = ar.trx_ctrl_num
where i.type_code in ('frame','sun','parts')
	and b.status='t' and (a.cr_shipped >0 or a.shipped > 0) 
	and exists (select * from inv_tran (nolock) where a.order_no = tran_no and
			a.order_ext = tran_ext and a.line_no = tran_line)
    --and i.category in (@brand) 
    --and i.vendor = @vendor
	and (ar.date_applied between @jdatefrom and @jdateto)
		
insert into #temp
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
	isnull((select return_desc from po_retcode p (nolock) where a.return_code = p.return_code),'Sales') as reason, 
	cr_shipped as Qty_ret ,
	case when left(a.return_code,2) = '04' then cr_shipped else 0 end as qty_def,
	a.cost,
	cast ( (a.cr_shipped * a.cost) as decimal (20,8) )as ext_cost_ret,
	case when left(a.return_code,2) = '04' then 
		cast ( (a.cr_shipped * a.cost) as decimal (20,8) ) else 0 end as ext_cost_def,
	0 as rct_qty_hist,	
	case when left(b.user_category,2) = 'rx' then shipped else 0 end as Sales_rx_qty_hist,
	case when left(b.user_category,2) <> 'rx' then shipped else 0 end as Sales_st_qty_hist,
	a.order_no, a.order_ext
from ord_list a (nolock)
inner join orders b (nolock) on a.order_no = b.order_no and a.order_ext = b.ext
inner join inv_master i (nolock) on a.part_no = i.part_no
inner join inv_master_add ia (nolock) on i.part_no = ia.part_no
left outer join apmaster ap (nolock) on i.vendor = ap.vendor_code
inner join orders_invoice oi on b.order_no = oi.order_no and b.ext = oi.order_ext
inner join arinpchg ar on oi.trx_ctrl_num = ar.trx_ctrl_num

where i.type_code in ('frame','sun','parts')
and b.status='t' and (a.cr_shipped >0 or a.shipped> 0)
and exists (select * from inv_tran (nolock) where a.order_no = tran_no and
		a.order_ext = tran_ext and a.line_no = tran_line)
	--and i.category = @brand and i.vendor = @vendor
	and (ar.date_applied between @jdatefrom and @jdateto)
		

insert into #temp
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
	isnull((select return_desc from po_retcode p (nolock) 
		  where p.return_code = isnull(a.return_code,'06-13')),'Sales') as reason, 
	cr_shipped as Qty_ret ,
	case when left(isnull(a.return_code,'06-13'),2) = '04' then cr_shipped else 0 end as qty_def,
	a.cost,
	cast ( (a.cr_shipped * a.cost) as decimal (20,8) )as ext_cost_ret,
	case when left(a.return_code,2) = '04' then 
		cast ( (a.cr_shipped * a.cost) as decimal (20,8) ) else 0 end as ext_cost_def,
	0 as rct_qty_hist,
	case when left(b.user_category,2) = 'rx' then shipped else 0 end as Sales_rx_qty_hist,
	case when left(b.user_category,2) <> 'rx' then shipped else 0 end as Sales_st_qty_hist,
	a.order_no, a.order_ext
from cvo_ord_list_hist a (nolock)
inner join cvo_orders_all_hist b (nolock) on a.order_no = b.order_no and a.order_ext = b.ext
inner join inv_master i (nolock) on a.part_no = i.part_no
inner join inv_master_add ia (nolock) on i.part_no = ia.part_no
left outer join apmaster ap (nolock) on i.vendor = ap.vendor_code
where i.type_code in ('frame','sun','parts')
and b.status='t' and (a.cr_shipped >0 or a.shipped > 0)
--and i.category = @brand and i.vendor = @vendor
and (b.date_shipped between @datefrom and @dateto)



--- receipts
insert into #temp
select 
	i.vendor,
	ap.address_name,
	i.part_no ,
	i.category as Brand,
	ia.field_2 as Model,
	ia.field_28 as POMDate,
	i.type_code,
	convert(varchar,recv_date,101) as ShipDate, 
	'' as return_code,
	reason = 'Receipt',
	0 as Qty_ret ,
	0 as qty_def,
	0 as cost,
	0 as ext_cost_ret,
	0 as ext_cost_def,
	a.quantity as rct_qty_hist,
	0 as Sales_rx_qty_hist,
	0 as Sales_st_qty_hist,
	a.po_no as order_no, 
	0 as order_ext
--into #tag_test
from receipts a (nolock)
	inner join inv_master i (nolock) on a.part_no = i.part_no
	inner join inv_master_add ia (nolock) on i.part_no = ia.part_no
	left outer join apmaster ap (nolock) on i.vendor = ap.vendor_code
where i.type_code in ('frame','sun','parts')
	and a.quantity >0
	--and i.category = @brand and i.vendor = @vendor
and (a.recv_date between @datefrom and @dateto)

;with cte as (select distinct part_no from #temp where qty_def <> 0)
select vendor, address_name, #temp.PART_NO, Brand, MOdel, POMDate, TYPE_CODE, 
isnull(RETURN_CODE,'') return_code, reason, sum(QTY_RET) qty_ret, sum(qty_def) QTY_DEF, COST, sum(EXT_COST_RET) ext_cost_Ret, 
sum(ext_cost_def) EXT_COST_DEF, sum(rct_qty_hist) rct_qty_hist, sum(sales_rx_qty_hist) Sales_rx_qty_hist,
sum(sales_st_qty_hist) Sales_st_qty_hist 
from #temp, cte where #temp.part_no = cte.part_no
group by VENDOR, ADDRESS_NAME, #temp.PART_NO, BRAND, MODEL, POMDATE, TYPE_CODE, 
RETURN_CODE, REASON, cost


GO
