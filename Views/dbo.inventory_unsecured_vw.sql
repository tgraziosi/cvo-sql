SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE View [dbo].[inventory_unsecured_vw]
As

-- v1.0 CB 29/03/2011 CB 18.RDOCK Inventory - Excluded specified bins from available stock
-- v1.1 CB 16/06/2014 - Change to use view instead of function

select 
l.part_no, 
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
case when (m.status='C' or m.status='V') then 0 else (l.in_stock + l.issued_mtd + p.produced_mtd - p.usage_mtd - s.sales_qty_mtd + r.recv_mtd + x.xfer_mtd - isnull(z.qty,0))end in_stock, -- v1.0 z.qty
l.hold_qty, 
l.min_stock, 
l.max_stock, 
l.min_order, 
s.qty_alloc, 
s.commit_ed, 
r.po_on_order, 
m.vendor, 
--l.issued_mtd, 
--l.issued_ytd, 
l.rank_class,
--r.recv_mtd, 
--r.recv_ytd, 
m.category, 
m.type_code, 
--p.usage_mtd, 
--p.usage_ytd, 
--s.sales_qty_mtd, 
--s.sales_qty_ytd, 
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
IsNull(pr.price_a, 0) price_a,
IsNull(pr.price_b, 0) price_b, 
IsNull(pr.price_c, 0) price_c, 
IsNull(pr.price_d, 0) price_d, 
IsNull(pr.price_e, 0) price_e, 
IsNull(pr.price_f, 0) price_f, 
IsNull(pr.qty_a, 0) qty_a, 
IsNull(pr.qty_b, 0) qty_b, 
IsNull(pr.qty_c, 0) qty_c, 
IsNull(pr.qty_d, 0) qty_d, 
IsNull(pr.qty_e, 0) qty_e, 
IsNull(pr.qty_f, 0) qty_f,
m.labor, 
p.qty_scheduled, 
--p.produced_mtd, 
--p.produced_ytd, 
m.uom, 
--s.sales_amt_mtd, 
--s.sales_amt_ytd, 
IsNull(pr.promo_type, 'N') promo_type, 
IsNull(pr.promo_rate, 0) promo_rate, 
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
case when l.note is null or ltrim(l.note) = '' then m.note else l.note end note, 
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
isnull(l.qc_qty,0) qc_qty,
x.commit_ed xfer_commit_ed,   
--x.xfer_mtd,   
--x.xfer_ytd,
isnull(mtd.issued_qty,0) issued_mtd,
isnull(mtd.produced_qty,0) produced_mtd,
isnull(mtd.usage_qty,0) usage_mtd,
isnull(mtd.sales_qty,0) sales_qty_mtd,
isnull(mtd.sales_amt,0) sales_amt_mtd,
isnull(mtd.recv_qty,0) recv_mtd,
isnull(mtd.xfer_qty,0) xfer_mtd,
isnull(ytd.issued_qty,0) issued_ytd,
isnull(ytd.produced_qty,0) produced_ytd,
isnull(ytd.usage_qty,0) usage_ytd,
isnull(ytd.sales_qty,0) sales_qty_ytd,
isnull(ytd.sales_amt,0) sales_amt_ytd,
isnull(ytd.recv_qty,0) recv_ytd,
isnull(ytd.xfer_qty,0) xfer_ytd,
loc.organization_id
from inv_list l (nolock)
join inv_master m (nolock) on m.part_no = l.part_no
join inv_produce p (nolock) on p.part_no = m.part_no and p.location = l.location
join inv_sales s (nolock) on s.part_no = m.part_no and s.location = l.location
join inv_xfer x (nolock) on x.part_no = m.part_no and x.location = l.location
join inv_recv r (nolock) on r.part_no = m.part_no and r.location = l.location
join glco g (nolock) on 1=1
left outer join part_price pr (nolock) on pr.part_no = m.part_no and pr.curr_key = g.home_currency
join (select period from dbo.adm_inv_mtd_cal_f()) as c(period)  on 1=1
left outer join adm_inv_mtd mtd (nolock) on mtd.part_no = l.part_no and mtd.location = l.location and mtd.period = c.period
left outer join (
  select part_no,location,sum(issued_qty),sum(produced_qty),sum(usage_qty),sum(sales_qty),
    sum(sales_amt), sum(recv_qty), sum(xfer_qty)
  from adm_inv_mtd m (nolock),
   adm_inv_mtd_cal_f() c 
  where m.period between c.fiscal_start and c.period
  group by part_no,location) as ytd(part_no,location,issued_qty,produced_qty,usage_qty,sales_qty,
    sales_amt, recv_qty, xfer_qty) on ytd.part_no = l.part_no and ytd.location = l.location
join locations_all loc (nolock) on l.location = loc.location
-- v1.0 Call function to return qty from excluded bins
LEFT JOIN dbo.f_get_excluded_bins_1_vw z on l.part_no = z.part_no and l.location = z.location -- v1.1

GO
GRANT REFERENCES ON  [dbo].[inventory_unsecured_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[inventory_unsecured_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[inventory_unsecured_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[inventory_unsecured_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[inventory_unsecured_vw] TO [public]
GO
