SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE view [dbo].[CVO_CUSTOM_FRAME_AVAIL_vw]
AS

-- select * from cvo_custom_frame_avail_vw
select c.date_entered, c.sch_ship_date, c.allocation_date, c.order_no, c.order_ext, c.cust_code,
c.ship_to_name, c.frame, max(c.qty_avl_frame) qty_avl_frame,
max(c.temple_l) temple_l,
max(c.temple_l_avail) temple_l_avail,
max(c.temple_r) temple_r,
max(c.temple_r_avail) temple_r_avail

from
(
select ol.order_no, ol.order_ext, ol.line_no, ol.status, o.so_priority_code, ol.part_no frame, 
(select iv.qty_avl from cvo_item_avail_vw iv (nolock) where iv.part_no = ol.part_no and location = ol.location) as qty_avl_frame,
case WHEN ia.category_3 = 'TEMPLE-L' THEN OK.PART_NO ELSE '' END AS TEMPLE_L,
case when ia.category_3 = 'TEMPLE-L' THEN (select iv.qty_avl from cvo_item_avail_vw iv (nolock) where iv.part_no = ok.part_no and location = ol.location) ELSE 0 END as TEMPLE_L_AVAIL,
CASE WHEN IA.category_3 = 'TEMPLE-R' THEN OK.PART_NO ELSE '' END AS TEMPLE_R,
 ok.ordered, 
case when ia.category_3 = 'TEMPLE-R' THEN (select iv.qty_avl from cvo_item_avail_vw iv (nolock) where iv.part_no = ok.part_no and location = ol.location) ELSE 0 END as TEMPLE_R_AVAIL,
o.date_entered, o.sch_ship_date, co.allocation_date, o.cust_code, o.ship_to_name, ol.location
From ord_list ol (nolock) inner join cvo_ord_list col (nolock) on
ol.order_no = col.order_no and ol.order_ext = col.order_ext and ol.line_no = col.line_no
inner join ord_list_kit ok (nolock) on ol.order_no = ok.order_no and ol.order_Ext = ok.order_ext
	and col.line_no = ok.line_no
inner join orders o (nolock) on ol.order_no = o.order_no and ol.order_ext = o.ext
inner join cvo_orders_all co (nolock) on co.order_no = o.order_no and co.ext = o.ext
inner join inv_master_add ia (nolock) on oK.part_no = ia.part_no
where 1=1 
and ia.category_3 <> 'FRONT'
and ol.status <'r' and col.is_customized = 'S'
) as c
group by c.date_entered, c.sch_ship_date, c.allocation_date, c.order_no, c.order_ext, c.cust_code,
c.ship_to_name, c.frame


GO
GRANT REFERENCES ON  [dbo].[CVO_CUSTOM_FRAME_AVAIL_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[CVO_CUSTOM_FRAME_AVAIL_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[CVO_CUSTOM_FRAME_AVAIL_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[CVO_CUSTOM_FRAME_AVAIL_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[CVO_CUSTOM_FRAME_AVAIL_vw] TO [public]
GO
