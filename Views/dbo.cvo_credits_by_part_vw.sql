SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE view [dbo].[cvo_credits_by_part_vw] as
-- v1.1 - tag - add return code, description, order type to detail of report
select 
	i.vendor,
	ap.address_name,
	i.part_no ,
	i.type_code,
	a.return_code,
	ar.date_applied as date_shipped,
	reason = (select return_desc from po_retcode p (nolock) where a.return_code = p.return_code), 
	sum(a.cr_shipped) as CR_shipped ,
	cast (sum(a.cr_shipped * a.cost) as decimal (20,8)) as ext_cost,
	(select isnull((dbo.cvo_fn_ytd_rcts(i.part_no)),0)) as ytd_rcts,
	(select ISNULL((dbo.cvo_fn_ytd_sales_cat (i.part_no,'RX')),0)) as ytd_sales_RX, 
	(select ISNULL((dbo.cvo_fn_ytd_sales_cat (i.part_no,'ST')),0)) as ytd_sales_ST, 
	(select isnull((dbo.cvo_fn_ytd_defects(i.part_no)),0)) as ytd_defects,
	(select ISNULL((dbo.cvo_fn_ytd_defect_percent (i.part_no)),0)) as ytd_defect_percent,
	(select isnull((dbo.cvo_fn_ytd_returns(i.part_no)),0)) as ytd_returns,
	(select ISNULL((dbo.cvo_fn_ytd_return_percent (i.part_no)),0)) as ytd_return_percent
from inv_master i (nolock)
left outer join ord_list a (NOLOCK)
on i.part_no = a.part_no
inner join orders b (NOLOCK)
on a.order_no = b.order_no and a.order_ext = b.ext
--inv_tran d (NOLOCK), 
inner join arcust m (NOLOCK)
on b.cust_code = m.customer_code and b.ship_to = m.ship_to_code
left outer join apmaster ap  (nolock)
on i.vendor = ap.vendor_code
inner join orders_invoice oi on b.order_no = oi.order_no and b.ext = oi.order_ext
inner join artrx ar on oi.trx_ctrl_num = ar.trx_ctrl_num
where b.type = 'C' and b.status='T' and a.cr_shipped > 0
--and a.order_no = d.tran_no
--and a.order_ext = d.tran_ext
--and a.part_no = d.part_no

and exists (select * from inv_tran (nolock) where a.order_no = tran_no and
		a.order_ext = tran_ext and i.part_no = part_no)
--and (i.vendor = 'counto')
group by i.vendor, ap.address_name, i.part_no, i.type_code, a.return_code, ar.date_applied
GO
GRANT SELECT ON  [dbo].[cvo_credits_by_part_vw] TO [public]
GO
