SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE view [dbo].[cvo_bin_alloc_vw] as 

Select 
a.part_no,
c.description, 
c.type_code,
e.group_code,
a.bin_no, 
a.order_no,
a.order_ext,
a.line_no,
b.user_category as order_type,
b.sch_ship_date,
a.qty as allocated,
d.qty as bin_qty,
e.maximum_level,
b.status,
isnull(f.promo_id,'') as promo,
b.ship_to_name
, a.location -- added 12/1/15
--sum(a.qty) as allocated,  
--d.qty as bin_qty,
--count(a.order_no) as Num_orders

from tdc_soft_alloc_tbl a (nolock), 
orders b (nolock), 
inv_master c (nolock), 
lot_bin_stock d (nolock), 
tdc_bin_master e (nolock),
cvo_orders_all f (nolock)


where 
--a.bin_no like 'f%' 
a.order_no <>0
and a.order_no = b.order_no
and a.order_ext = b.ext
and a.order_no = f.order_no
and a.order_ext = f.ext
--and b.user_category like 'st%'
--and a.bin_no in (select bin_no from tdc_bin_replenishment)
and a.part_no = c.part_no
--and c.type_code in ('frame','sun','pop')
--and d.location = '001'
--and e.location = '001' 
and d.part_no = a.part_no
and d.location = e.location
and b.location = d.location -- tag - 06/12/2012
and d.bin_no = a.bin_no
and e.bin_no = a.bin_no

--group by a.part_no, c.description, e.group_code, c.type_code, a.bin_no, a.order_no, d.qty
--having sum(a.qty) >=10
--order by sum(a.qty) desc

--select top 1 * from orders_all











GO
GRANT REFERENCES ON  [dbo].[cvo_bin_alloc_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[cvo_bin_alloc_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[cvo_bin_alloc_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[cvo_bin_alloc_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[cvo_bin_alloc_vw] TO [public]
GO
