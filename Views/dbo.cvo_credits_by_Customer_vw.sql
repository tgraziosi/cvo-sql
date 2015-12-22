SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

-- select * from cvo_credits_by_Customer_vw

CREATE view [dbo].[cvo_credits_by_Customer_vw] as
-- v1.1 - tag - add return code, description, order type to detail of report
select * from (
select 
-- top 100
	m.territory_code,
	m.salesperson_code,
	m.customer_code,
	m.ship_to_code,									
	m.address_name,								
	a.part_no ,
	c.category as collection,
	ia.field_2 as Style,
	c.type_code,
	ia.field_28 as pom_date,
-- tag - 100112
	CASE 
	WHEN c.type_code in ('FRAME','SUN','PARTS') THEN
		CASE
		WHEN (IA.FIELD_28 IS NULL or ia.field_28 > getdate()) THEN '' 
		else dbo.f_cvo_get_pom_tl_status(c.category,ia.field_2,ia.field_3, b.date_entered)
		end
	ELSE '' END as TL,
	CASE 
	WHEN c.type_code in ('FRAME','SUN','PARTS') THEN
		CASE
		WHEN (IA.FIELD_28 IS NULL or ia.field_28 > getdate()) THEN '' 
		else dbo.f_cvo_get_pom_tl_status(c.category,ia.field_2,ia.field_3, dateadd(m,-1,b.date_entered))
		end
	ELSE '' END as PP_TL,
		CASE 
	WHEN c.type_code in ('FRAME','SUN','PARTS') THEN
		CASE
		WHEN (IA.FIELD_28 IS NULL or ia.field_28 > getdate()) THEN '' 
		else dbo.f_cvo_get_pom_tl_status(c.category,ia.field_2,ia.field_3, dateadd(m,-2,b.date_entered))
		end
	ELSE '' END as PP2_TL,
	c.vendor,
	a.cr_shipped ,
--	ROUND((a.curr_price - (a.curr_price * (a.discount / 100))) ,2) as UnitPrice,
	isnull(a.cr_Shipped * ROUND((a.curr_price - (a.curr_price * (a.discount / 100))) ,2), 0) as ExtendedAmt,
	a.return_code,
	reason = (select return_desc from po_retcode p (nolock) where a.return_code = p.return_code), 
	b.date_shipped as date_shipped,
--	(select ISNULL((dbo.cvo_fn_ytd_sales_cat (a.part_no,'RX')),0)) as ytd_sales_RX, 
--	(select ISNULL((dbo.cvo_fn_ytd_sales_cat (a.part_no,'ST')),0)) as ytd_sales_ST, 
--	(select ISNULL((dbo.cvo_fn_ytd_return_percent (a.part_no)),0)) as ytd_return_percent, 
--	cast ((a.cr_shipped * a.cost) as decimal (20,8)) as ext_cost,
	b.date_entered,
	convert(varchar, b.invoice_no) invoice_no,
	a.order_no ,
	a.order_ext
from ord_list a (NOLOCK)
inner join orders b (NOLOCK)
on a.order_no = b.order_no and a.order_ext = b.ext
inner join orders_invoice oi (nolock) on b.order_no = oi.order_no and b.ext = oi.order_ext
inner join artrx ar (nolock) on oi.trx_ctrl_num = ar.trx_ctrl_num
inner join inv_master c (NOLOCK) on a.part_no = c.part_no 
inner join inv_master_add ia (nolock) on c.part_no = ia.part_no
--inv_tran d (NOLOCK), 
inner join armaster m (NOLOCK)
on b.cust_code = m.customer_code and b.ship_to = m.ship_to_code
and b.type = 'C' and b.status='T' and a.cr_shipped > 0
--and a.order_no = d.tran_no
--and a.order_ext = d.tran_ext
--and a.part_no = d.part_no
and ( exists (select * from inv_tran (nolock) where a.order_no = tran_no and
		a.order_ext = tran_ext and a.part_no = part_no)
--and (a.part_no like 'ch221%' or a.part_no like 'ch961%' or a.part_no like 'ch962%')
	or left(a.return_code,2) in ('05') )
UNION ALL
	select 
-- top 100
	m.territory_code,
	m.salesperson_code,
	m.customer_code,
	m.ship_to_code,									
	m.address_name,								
	a.part_no ,
	c.category as collection,
	ia.field_2 as Style,
	c.type_code,
	ia.field_28 as pom_date,
-- tag - 100112
	CASE 
	WHEN c.type_code in ('FRAME','SUN','PARTS') THEN
		CASE
		WHEN (IA.FIELD_28 IS NULL or ia.field_28 > getdate()) THEN '' 
		else dbo.f_cvo_get_pom_tl_status(c.category,ia.field_2,ia.field_3, b.date_entered)
		end
	ELSE '' END as TL,
	CASE 
	WHEN c.type_code in ('FRAME','SUN','PARTS') THEN
		CASE
		WHEN (IA.FIELD_28 IS NULL or ia.field_28 > getdate()) THEN '' 
		else dbo.f_cvo_get_pom_tl_status(c.category,ia.field_2,ia.field_3, dateadd(m,-1,b.date_entered))
		end
	ELSE '' END as PP_TL,
		CASE 
	WHEN c.type_code in ('FRAME','SUN','PARTS') THEN
		CASE
		WHEN (IA.FIELD_28 IS NULL or ia.field_28 > getdate()) THEN '' 
		else dbo.f_cvo_get_pom_tl_status(c.category,ia.field_2,ia.field_3, dateadd(m,-2,b.date_entered))
		end
	ELSE '' END as PP2_TL,
	c.vendor,
	a.cr_shipped ,
--	ROUND((a.curr_price - (a.curr_price * (a.discount / 100))) ,2) as UnitPrice,
	isnull(a.cr_Shipped * ROUND((a.curr_price - (a.curr_price * (a.discount / 100))) ,2), 0) as ExtendedAmt,
	a.return_code,
	reason = (select return_desc from po_retcode p (nolock) where a.return_code = p.return_code), 
	b.date_shipped as date_shipped,
--	(select ISNULL((dbo.cvo_fn_ytd_sales_cat (a.part_no,'RX')),0)) as ytd_sales_RX, 
--	(select ISNULL((dbo.cvo_fn_ytd_sales_cat (a.part_no,'ST')),0)) as ytd_sales_ST, 
--	(select ISNULL((dbo.cvo_fn_ytd_return_percent (a.part_no)),0)) as ytd_return_percent, 
--	cast ((a.cr_shipped * a.cost) as decimal (20,8)) as ext_cost,
	b.date_entered,
	convert(varchar, b.invoice_no) invoice_no,
	a.order_no ,
	a.order_ext
from CVO_ord_list_HIST a (NOLOCK)
inner join CVO_orders_ALL_HIST b (NOLOCK)
on a.order_no = b.order_no and a.order_ext = b.ext
inner join inv_master c (NOLOCK) on a.part_no = c.part_no 
inner join inv_master_add ia (nolock) on c.part_no = ia.part_no
inner join armaster m (NOLOCK)
on b.cust_code = m.customer_code and b.ship_to = m.ship_to_code
and b.type = 'C' and b.status='T' and a.cr_shipped > 0
)tmp

GO
GRANT SELECT ON  [dbo].[cvo_credits_by_Customer_vw] TO [public]
GO
