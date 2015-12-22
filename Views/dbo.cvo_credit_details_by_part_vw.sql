SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[cvo_credit_details_by_part_vw] as
-- v1.1 - tag - add return code, description, order type to detail of report
select 
	i.vendor,
	ap.address_name,
	i.category as Brand,
	ia.field_2 as Model,
	i.part_no ,
	i.type_code,
	ar.date_applied as date_shipped,
	convert(varchar,dateadd(d,ar.DATE_APPLIED-711858,'1/1/1950'),101) as ShipDate, 
	a.return_code,
	reason = (select return_desc from po_retcode p (nolock) where a.return_code = p.return_code), 
	cr_shipped as Qty_ret ,
	case when left(a.return_code,2) = '04' then cr_shipped else 0 end as qty_def,
	cast ( (a.cr_shipped * a.cost) as decimal (20,8) )as ext_cost,
	a.order_no, a.order_ext
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
--group by i.vendor, ap.address_name, i.category, ia.field_2 , i.type_code


GO
GRANT SELECT ON  [dbo].[cvo_credit_details_by_part_vw] TO [public]
GO
