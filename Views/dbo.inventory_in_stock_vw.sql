SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE view [dbo].[inventory_in_stock_vw] as

-- v1.0 CB 29/03/2011 CB 18.RDOCK Inventory - Excluded specified bins from available stock
-- v1.1 CB 16/06/2014 - Change to use view instead of function

select 
l.part_no, 
l.location,
case when (m.status='C' or m.status='V') then 0 else (l.in_stock + l.issued_mtd + p.produced_mtd - p.usage_mtd - s.sales_qty_mtd + r.recv_mtd + x.xfer_mtd - isnull(z.qty,0))end in_stock -- v1.0 z.qty
from inv_list l (nolock)
join inv_master m (nolock) on m.part_no = l.part_no
join inv_produce p (nolock) on p.part_no = m.part_no and p.location = l.location
join inv_sales s (nolock) on s.part_no = m.part_no and s.location = l.location
join inv_xfer x (nolock) on x.part_no = m.part_no and x.location = l.location
join inv_recv r (nolock) on r.part_no = m.part_no and r.location = l.location
-- v1.0 Call function to return qty from excluded bins
LEFT JOIN dbo.f_get_excluded_bins_1_vw z on l.part_no = z.part_no and l.location = z.location -- v1.1
GO
GRANT REFERENCES ON  [dbo].[inventory_in_stock_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[inventory_in_stock_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[inventory_in_stock_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[inventory_in_stock_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[inventory_in_stock_vw] TO [public]
GO
