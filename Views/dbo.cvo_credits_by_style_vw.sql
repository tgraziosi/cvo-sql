SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[cvo_credits_by_style_vw] as
-- v1.1 - tag - add return code, description, order type to detail of report
select 
	i.vendor,
	ap.address_name,
	i.category as Brand,
	ia.field_2 as Model,
	i.part_no ,
	i.type_code,
	a.return_code,
	ar.date_applied as date_shipped,
	convert(varchar,dateadd(d,ar.DATE_APPLIED-711858,'1/1/1950'),101) as ShipDate, 
	reason = (select return_desc from po_retcode p (nolock) where a.return_code = p.return_code), 
	cr_shipped as CR_shipped ,
	cast ( (a.cr_shipped * a.cost) as decimal (20,8) )as ext_cost
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

--left outer join ord_list a (NOLOCK) on i.part_no = a.part_no
--inner join orders b (NOLOCK) on a.order_no = b.order_no and a.order_ext = b.ext
--inv_tran d (NOLOCK), 
--inner join arcust m (NOLOCK) on b.cust_code = m.customer_code and b.ship_to = m.ship_to_code
--where b.type = 'C' and b.status='T' and a.cr_shipped > 0
--and a.order_no = d.tran_no
--and a.order_ext = d.tran_ext
--and a.part_no = d.part_no

--and (i.vendor = 'counto')
--, a.return_code
--, ar.date_applied
GO
