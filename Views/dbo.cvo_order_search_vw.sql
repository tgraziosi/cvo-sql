SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- select * From cvo_order_search_vw

CREATE view [dbo].[cvo_order_search_vw] as 
select 
o.order_no, o.ext, 
o.terms,
o.status,
isnull(o.hold_reason,'') hold_reason,
o.routing,
o.freight_allow_type,
o.cust_code,
o.ship_to,
o.req_ship_date,
o.sch_ship_date,
co.allocation_date,
co.promo_id,
co.promo_level,
i.category collection,
ia.field_2 model,
i.type_code,
ol.part_no,
ia.field_26 release_date


from orders o (nolock)
inner join cvo_orders_all co (nolock) on co.order_no = o.order_no and co.ext = o.ext
inner join ord_list ol (nolock) on ol.order_no = o.order_no and ol.order_ext = o.ext
inner join inv_master i (nolock) on i.part_no = ol.part_no
inner join inv_master_add ia (nolock) on i.part_no = ia.part_no
where o.status < 'r'



GO
GRANT REFERENCES ON  [dbo].[cvo_order_search_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[cvo_order_search_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[cvo_order_search_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[cvo_order_search_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[cvo_order_search_vw] TO [public]
GO
