SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE view [dbo].[cvo_credit_lines_vw] as
-- v1.1 - tag - add return code to detail of report
select 
	a.part_no ,
	c.vendor,
	a.part_no as credit_part_no,
	b.cust_code,									-- TMcGrady / AUG.2010
	m.customer_name,								-- TMcGrady / AUG.2010
	a.cr_shipped ,
-- v1.1
	a.reason_code,
--	a.return_code,
-- v1.1
	b.date_shipped,
	(select ISNULL((dbo.cvo_fn_ytd_sales (a.part_no)),0)) as ytd_sales, 
	(select ISNULL((dbo.cvo_fn_ytd_return_percent (a.part_no)),0)) as ytd_return_percent, 
	cast ((a.cr_shipped * a.cost) as decimal (20,8)) as ext_cost,
	a.order_no ,
	a.order_ext

from ord_list a (NOLOCK), orders b (NOLOCK), inv_master c (NOLOCK), inv_tran d (NOLOCK), arcust m (NOLOCK)
where a.order_no = b.order_no
and a.order_ext = b.ext
and b.type = 'c'
and a.part_no = c.part_no
and a.order_no = d.tran_no
and a.order_ext = d.tran_ext
and a.part_no = d.part_no
and b.cust_code = m.customer_code
and a.cr_shipped > 0
GO
GRANT SELECT ON  [dbo].[cvo_credit_lines_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[cvo_credit_lines_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[cvo_credit_lines_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[cvo_credit_lines_vw] TO [public]
GO
