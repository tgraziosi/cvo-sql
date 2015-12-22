SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*
select * from cvo_product_defectives_vw where brand = 'bcbg'
*/

create view [dbo].[cvo_product_defectives_vw] as 

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
--into #tag_test
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
			
union all

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
		
union all

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

union all

--- receeipts

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

GO
GRANT REFERENCES ON  [dbo].[cvo_product_defectives_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[cvo_product_defectives_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[cvo_product_defectives_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[cvo_product_defectives_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[cvo_product_defectives_vw] TO [public]
GO
