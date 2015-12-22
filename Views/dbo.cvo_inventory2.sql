SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE VIEW [dbo].[cvo_inventory2]  
AS  
-- Based on inventory without the mtd and ytd figures  
SELECT  l.part_no,   
		l.location,   
		m.upc_code,   
		m.sku_no,   
		m.sku_code,  
		l.bin_no,   
		m.description,   
		r.cost,   
		l.avg_cost,   
		r.last_cost,   
		l.avg_direct_dolrs,   
		l.avg_ovhd_dolrs,   
		l.avg_util_dolrs,   
		CASE WHEN (m.status = 'C' OR m.status = 'V') THEN 0 ELSE 
			(l.in_stock + l.issued_mtd + p.produced_mtd - p.usage_mtd - s.sales_qty_mtd + r.recv_mtd + x.xfer_mtd - ISNULL(z.qty,0)) END in_stock,  
		l.hold_qty,   
		l.min_stock,   
		l.max_stock,   
		l.min_order,   
		s.qty_alloc,   
		s.commit_ed,   
		r.po_on_order,   
		m.vendor,   
		m.category,   
		m.type_code,   
		p.sch_alloc,   
		p.sch_date,   
		s.last_order_qty,   
		r.last_recv_date,   
		l.lead_time,   
		l.status,   
		m.freight_class,   
		m.cubic_feet,   
		m.weight_ea,   
		s.oe_on_order,   
		s.oe_order_date,   
		ISNULL(pr.price_a, 0) price_a,  
		ISNULL(pr.price_b, 0) price_b,   
		ISNULL(pr.price_c, 0) price_c,   
		ISNULL(pr.price_d, 0) price_d,   
		ISNULL(pr.price_e, 0) price_e,   
		ISNULL(pr.price_f, 0) price_f,   
		ISNULL(pr.qty_a, 0) qty_a,   
		ISNULL(pr.qty_b, 0) qty_b,   
		ISNULL(pr.qty_c, 0) qty_c,   
		ISNULL(pr.qty_d, 0) qty_d,   
		ISNULL(pr.qty_e, 0) qty_e,   
		ISNULL(pr.qty_f, 0) qty_f,  
		m.labor,   
		p.qty_scheduled,   
		m.uom,   
		ISNULL(pr.promo_type, 'N') promo_type,   
		ISNULL(pr.promo_rate, 0) promo_rate,   
		pr.promo_date_expires,   
		pr.promo_date_entered,   
		m.account,   
		m.comm_type,   
		l.qty_year_end,   
		l.qty_month_end,   
		l.qty_physical,   
		l.entered_who,   
		l.entered_date,   
		m.void,   
		m.void_who,   
		m.void_date,   
		l.std_cost,   
		l.std_labor,   
		l.std_direct_dolrs,   
		l.std_ovhd_dolrs,   
		l.std_util_dolrs,   
		m.taxable,   
		l.setup_labor,   
		m.lb_tracking,   
		m.rpt_uom,   
		l.freight_unit,   
		m.qc_flag,   
		m.conv_factor,   
		CASE WHEN l.note IS NULL OR LTRIM(l.note) = '' THEN m.note ELSE l.note END note,   
		l.cycle_date,   
		m.cycle_type,   
		p.hold_mfg,   
		s.hold_ord,   
		r.hold_rcv,   
		x.hold_xfr,   
		m.inv_cost_method,  
		m.buyer,  
		l.acct_code,  
		m.allow_fractions,  
		m.tax_code,  
		m.obsolete,  
		m.serial_flag,  
		l.eoq,  
		x.transit,  
		m.cfg_flag,  
		m.web_saleable_flag,  
		l.dock_to_stock,  
		l.order_multiple,  
		l.po_uom,  
		l.so_uom,  
		m.non_sellable_flag,  
		ISNULL(l.qc_qty,0) qc_qty,  
		x.commit_ed xfer_commit_ed,     
		loc.organization_id,  
		ISNULL(replen.qty,0) replen_qty, 
		CASE WHEN (m.status = 'C' OR m.status = 'V') THEN 0 ELSE 
			(l.in_stock + l.issued_mtd + p.produced_mtd - p.usage_mtd - s.sales_qty_mtd + r.recv_mtd + x.xfer_mtd) END cvo_in_stock,
		CASE WHEN (m.status = 'C' OR m.status = 'V') THEN 0 ELSE 
			(l.in_stock + l.issued_mtd + p.produced_mtd - p.usage_mtd - s.sales_qty_mtd + r.recv_mtd + x.xfer_mtd - ISNULL(z1.qty,0)) END in_stock_inc_non_allocating 
FROM	inv_list l (NOLOCK)  
JOIN	inv_master m (NOLOCK) 
ON		m.part_no = l.part_no  
JOIN	inv_produce p (NOLOCK) 
ON		p.part_no = m.part_no 
AND		p.location = l.location  
JOIN	inv_sales s (NOLOCK) 
ON		s.part_no = m.part_no 
AND		s.location = l.location  
JOIN	inv_xfer x (NOLOCK) 
ON		x.part_no = m.part_no 
AND		x.location = l.location  
JOIN	inv_recv r (NOLOCK) 
ON		r.part_no = m.part_no 
AND		r.location = l.location  
JOIN	glco g (NOLOCK) ON 1=1  
LEFT OUTER JOIN part_price pr (NOLOCK) 
ON		pr.part_no = m.part_no 
AND		pr.curr_key = g.home_currency  
JOIN	locations_all loc (NOLOCK) 
ON		l.location = loc.location  
LEFT JOIN dbo.f_get_excluded_bins_1_vw z 
ON		l.part_no = z.part_no 
AND		l.location = z.location 
LEFT JOIN dbo.cvo_replenishment_qty replen 
ON		l.location = replen.location 
AND		l.part_no = replen.part_no   
LEFT JOIN dbo.f_get_excluded_bins_4_vw z1 
ON		l.part_no = z1.part_no 
AND		l.location = z1.location 


GO
GRANT REFERENCES ON  [dbo].[cvo_inventory2] TO [public]
GO
GRANT SELECT ON  [dbo].[cvo_inventory2] TO [public]
GO
GRANT INSERT ON  [dbo].[cvo_inventory2] TO [public]
GO
GRANT DELETE ON  [dbo].[cvo_inventory2] TO [public]
GO
GRANT UPDATE ON  [dbo].[cvo_inventory2] TO [public]
GO
