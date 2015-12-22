SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE View [dbo].[inventory_add]
As

-- v1.0 CB 29/03/2011 CB 18.RDOCK Inventory - Excluded specified bins from available stock
-- v1.1 CB 16/06/2014 - Change to use view instead of function

select distinct	l.part_no, 
	l.location, 
	m.upc_code, 
	m.sku_no, 
	m.description, 
	case when (m.status='C' or m.status='V') then 0 else (l.in_stock + l.issued_mtd + p.produced_mtd - p.usage_mtd - s.sales_qty_mtd + r.recv_mtd + x.xfer_mtd - isnull(z.qty,0))end in_stock, -- v1.0 z.qty
	s.commit_ed + x.commit_ed commit_ed, 
	case when (m.status='C' or m.status='V') 
		then (0 - s.commit_ed - p.sch_alloc - x.commit_ed)
		else (l.in_stock + l.issued_mtd + p.produced_mtd - p.usage_mtd - s.sales_qty_mtd + r.recv_mtd + x.xfer_mtd - s.commit_ed - p.sch_alloc - x.commit_ed - isnull(z.qty,0)) -- v1.0 z.qty
		end available, 
	r.po_on_order, 
	p.sch_alloc, 
 	m.vendor, 
	m.category, 
	m.type_code, 
	m.uom, 
	m.buyer,
	l.status, 
	m.void, 
	m.obsolete,
	m.web_saleable_flag,
	price_a
from 	inv_master m (nolock)
join inv_list l (nolock) on (m.part_no = l.part_no) 
join inv_produce p (nolock) on (l.part_no = p.part_no and	l.location = p.location)
join inv_sales s (nolock) on (l.part_no = s.part_no and	l.location = s.location)
join inv_xfer x (nolock) on (l.part_no = x.part_no and	l.location = x.location) 
join inv_recv r (nolock) on (l.part_no = r.part_no and	l.location = r.location) 
join glco g(nolock) on 1=1
left outer join part_price pr(nolock) on ( m.part_no = pr.part_no and g.home_currency = pr.curr_key)
join locations loc (nolock) on (l.location = loc.location)
-- v1.0 Call function to return qty from excluded bins
LEFT JOIN dbo.f_get_excluded_bins_1_vw z on l.part_no = z.part_no	and l.location = z.location -- v1.1

GO
GRANT REFERENCES ON  [dbo].[inventory_add] TO [public]
GO
GRANT SELECT ON  [dbo].[inventory_add] TO [public]
GO
GRANT INSERT ON  [dbo].[inventory_add] TO [public]
GO
GRANT DELETE ON  [dbo].[inventory_add] TO [public]
GO
GRANT UPDATE ON  [dbo].[inventory_add] TO [public]
GO
