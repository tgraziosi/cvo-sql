SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE view [dbo].[adrma_vw] 
-- 6/13/2012 - tag - add territory and region
-- select * from adrma_vw where date_entered >='1/1/2013' and cust_code = '015773'
-- 12/27/13 - tag - add buying group
as
select 
	o.order_no ,
	o.cust_code ,
	o.ship_to ,
	o.ship_to_name ,
	o.location ,
	isnull(o.cust_po,' ') cust_po ,
	-- fix for null values - 071613 - tag
	ltrim(rtrim(isnull(co.ra1,'')+' '+isnull(co.ra2,'')+' '+
	isnull(co.ra3,'')+' '+isnull(co.ra4,'')+' '+isnull(co.ra5,'')+' '+
	isnull(co.ra6,'')+' '+isnull(co.ra7,'')+' '+isnull(co.ra8,''))) as rma,
	o.attention,
	o.phone,
	o.terms,
	o.tax_id,
	o.routing,
	o.fob,
	o.cr_invoice_no,
	o.curr_key,
	o.total_amt_order,
	total_tax =o.tot_ord_tax ,
	freight=o.tot_ord_freight,
	o.total_invoice ,	
	o.invoice_no ,
	date_invoice = o.invoice_date ,
	o.date_entered ,
	date_sch_ship = o.sch_ship_date ,
	o.date_shipped ,
	o.status ,
	status_desc = 
		CASE o.status
			WHEN 'N' THEN 'Open'
			WHEN 'Q' THEN 'QC'
			WHEN 'R' THEN 'Ready/Posting'
			WHEN 'S' THEN 'Shipped/Invoice'
			WHEN 'T' THEN 'Shipped/Transferred'
			WHEN 'V' THEN 'Void'
			ELSE ''
		END, 
	o.who_entered,
	o.ext,
	o.orig_no,
	o.orig_ext,
	n.doc_ctrl_num,
	order_ctrl_num = convert(varchar(10), orig_no) + '-' + convert(varchar(10), orig_ext),
	-- tag
	o.ship_to_region as territory,
	o.salesperson,
	co.buying_group, -- 12/27/13 - tag
	x_order_no=o.order_no ,
	x_cr_invoice_no=o.cr_invoice_no,
	x_total_amt_order=o.total_amt_order,
	x_total_tax =o.tot_ord_tax ,
	x_freight=o.tot_ord_freight,
	x_total_invoice=o.total_invoice ,	
	x_invoice_no=o.invoice_no ,
	x_date_invoice = dbo.adm_get_pltdate_f(o.invoice_date),
	x_date_entered= dbo.adm_get_pltdate_f(o.date_entered),
	x_date_sch_ship = dbo.adm_get_pltdate_f(o.sch_ship_date),
	x_date_shipped= dbo.adm_get_pltdate_f(o.date_shipped),
	x_ext=o.ext,
	x_orig_no=o.orig_no,
	x_orig_ext=o.orig_ext
FROM
	orders o (nolock)
	left outer join cvo_orders_all co (nolock) on co.order_no = o.order_no and co.ext = o.ext -- for RA #'s
	left outer join orders_invoice n (nolock) on o.order_no = n.order_no and o.ext = n.order_ext
where o.type = 'C'
UNION
select 
	o.order_no,
	o.cust_code ,
	o.ship_to ,
	o.ship_to_name ,
	o.location ,
	o.cust_po ,
	' ' as RMA,
	o.attention,
	o.phone,
	o.terms,
	o.tax_id,
	o.routing,
	o.fob,
	' ',	--o.cr_invoice_no,
	o.curr_key,
	o.total_amt_order,
	total_tax = o.tot_ord_tax ,
	freight = o.tot_ord_freight,
	o.total_invoice ,	
	' ',	--o.invoice_no ,
	date_invoice = o.invoice_date ,
	o.date_entered ,
	date_sch_ship = o.sch_ship_date ,
	o.date_shipped ,
	o.status ,
	status_desc = 
		CASE o.status
			WHEN 'N' THEN 'Open'
			WHEN 'Q' THEN 'QC'
			WHEN 'R' THEN 'Ready/Posting'
			WHEN 'S' THEN 'Shipped/Invoice'
			WHEN 'T' THEN 'Shipped/Transferred'
			WHEN 'V' THEN 'Void'
			ELSE ''
		END, 
	o.who_entered,
	0,
	o.orig_no,
	o.orig_ext,
	' ' as doc_ctrl_num,
	order_ctrl_num = convert(varchar(10), order_no) + '-' + convert(varchar(10), ext),
	-- tag
	o.ship_to_region as territory,
	o.salesperson,
	'' as buying_group, -- 12/27/13 - tag
	x_order_no = o.order_no ,
	x_cr_invoice_no = o.cr_invoice_no,
	x_total_amt_order = o.total_amt_order,
	x_total_tax = o.tot_ord_tax ,
	x_freight = o.tot_ord_freight,
	x_total_invoice = o.total_invoice ,	
	x_invoice_no = 0,	--o.invoice_no ,
	x_date_invoice = dbo.adm_get_pltdate_f(o.invoice_date),
	x_date_entered= dbo.adm_get_pltdate_f(o.date_entered),
	x_date_sch_ship = dbo.adm_get_pltdate_f(o.sch_ship_date),
	x_date_shipped= dbo.adm_get_pltdate_f(o.date_shipped),
	x_ext = o.ext,
	x_orig_no = o.orig_no,
	x_orig_ext = o.orig_ext
FROM
	cvo_orders_all_hist o
WHERE
	o.type = 'C'



GO
GRANT REFERENCES ON  [dbo].[adrma_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[adrma_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[adrma_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[adrma_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[adrma_vw] TO [public]
GO
