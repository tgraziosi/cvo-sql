SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/*
-- for backorder summary support
select * From cvo_open_order_detail_vw where location = '001' 
and daysoverdue not in ('future','current') and who_entered = 'backordr'
and alloc_qty = 0

select * from cvo_soft_alloc_det where order_no = 1835492
*/


CREATE view [dbo].[cvo_open_order_detail_vw] as
-- Open Order Details by SKU and availability
-- CVO - Tine Graziosi - 5/2012
-- v1.1 - tag - 062512 - added pom date and next po due date
-- v1.2 - tag - 062712 - changed aging buckets - 81
-- v1.3 - tag - 071712 - added customer type, vendor, and gender
-- v1.4 - tag - 12/27/2012 - performance updates
-- v1.5 - tag - 052813 - change confirm date -> inhouse_date
-- v1.6 - tag - 081913 - add net value of open qty
-- v1.7 - tag - 101513 - add order priority
-- v1.8 - tag - 031314 - add cust po
-- v1.9 - tag - 050417 - add qty in receiving

select 
i.category as brand, 
i.type_code as restype, 
ia.category_2 gender, --v1.3
ia.field_2 style, 
ol.part_no, 
i.vendor vendor, -- v1.3
ia.field_28 pom_date, --v1.1
--cia.description,
iav.qty_avl AS qty_avl,
iav.QcQty2 AS qty_Rec,
--(select top (1) qty_avl from cvo_item_avail_vw cia (nolock) where cia.part_no = ol.part_no
--	and cia.location = ol.location) qty_avl,
ol.location, 
--cia.in_stock, 
--cia.qty_commit, 
--cia.allocated, 
(select min (/*confirm_date*/inhouse_date) from releases r (nolock) where r.part_no = ol.part_no
	and r.location = ol.location and quantity>received and status='O') as NextPODueDate,
--cia.nextpoduedate,  -- v1.1
CAST(O.ORDER_NO as varchar(8)) order_no,
-- o.order_no, 
cast(o.ext as varchar(2)) ext, 
ol.line_no,
-- o.user_def_fld4 hs_order,
o.user_category,
o.hold_reason,
--hold_reason = case when o.hold_reason <> '' then o.hold_reason
--					when p.hold_reason <> '' then p.hold_reason 
--					else o.hold_reason end,
-- o.status,
o.cust_code,
o.ship_to,
o.ship_to_name,
o.cust_po,
o.ship_to_region Territory,
--v1.3
( SELECT top (1) addr_sort1 from arcust (nolock) where o.cust_code = customer_code )
-- and o.ship_to = ship_to_code)
as CustomerType,
o.date_entered,
o.sch_ship_date, 
-- line_no, 
ol.ordered-ol.shipped open_ord_qty,

ISNULL(ha.alloc_qty,0) alloc_qty,

--isnull( (select sum(qty) from tdc_soft_alloc_tbl (nolock)
--	where order_no = o.order_no and order_ext = o.ext 
--	and line_no = ol.line_no and location = ol.location), 0) alloc_qty,

ISNULL(sa.sa_qty_avail,0) sa_qty_avail,
ISNULL(sa.sa_qty_notavail,0) sa_qty_notavail,

--isnull((select sum(sa_stock)-sum(bo_stock) from cvo_get_soft_alloc_stock_vw sof (nolock)
--where sof.order_no = ol.order_no and sof.order_ext = ol.order_ext 
--and sof.line_no = ol.line_no and sof.part_no = ol.part_no), 0) sa_qty_avail,

--isnull((select sum(bo_stock) from cvo_get_soft_alloc_stock_vw sof (nolock)
--where sof.order_no = ol.order_no and sof.order_ext = ol.order_ext
--and sof.line_no = ol.line_no and sof.part_no = ol.part_no ), 0) sa_qty_notavail,
    

/*  - 062712 - tag - as per KM request (81)
1-21
22-42
43 +
*/

case when datediff(d,o.sch_ship_date,getdate()) < 0 then 'Future'
	 when datediff(d,o.sch_ship_date,getdate()) = 0 then 'Current'
--	 when datediff(d,o.sch_ship_date,getdate()) between 1  and 30 then '1-30'
--	 when datediff(d,o.sch_ship_date,getdate()) between 31 and 60 then '31-60'
--	 when datediff(d,o.sch_ship_date,getdate()) between 61 and 90 then '61-90'
--	 when datediff(d,o.sch_ship_date,getdate()) >90 then 'Over 90'
--	 when datediff(d,o.sch_ship_date,getdate()) between 1  and 30 then '1-30'
	 when datediff(d,o.sch_ship_date,getdate()) between 1 and 21 then '1-21'
	 when datediff(d,o.sch_ship_date,getdate()) between 22 and 42 then '22-42'
	 when datediff(d,o.sch_ship_date,getdate()) >42 then '43 +'
	 else 'N/A'
end as DaysOverDue,
o.who_entered,
o.status, -- 10/23/2012 - for ssrs
-- 0 = ALLOW BACK ORDER, 1 = SC, 2 = ALLOW PARTIAL
case when o.back_ord_flag = 0 then 'AB'
    when o.back_ord_flag = 1 then 'SC'
    when o.back_ord_flag = 2 then 'AP'
    end as bo_flg,
-- 08/19/2013 - tag - per SS request - v1.6
(ol.ordered-ol.shipped) * ROUND(ol.curr_price - (ol.curr_price * (ol.discount / 100)),2) as net_amt,
-- v1.7 - 101513
so_priority_code
, co.promo_id, co.promo_level, p.hold_reason p_hold_reason
, co.allocation_date
, co.add_pattern -- 1/18/2017 - for Lilian - on size patterns for some styles
, ol.ordered

From
 orders o (nolock)
 inner join cvo_orders_all co (nolock) on co.order_no = o.order_no and co.ext = o.ext
 INNER JOIN ord_list ol (nolock)  on  ol.order_no = o.order_no and ol.order_ext = o.ext 
 INNER JOIN dbo.cvo_item_avail_vw (NOLOCK) AS iav ON iav.location = ol.location AND iav.part_no = ol.part_no
 inner join inv_master i (nolock) on i.part_no = ol.part_no
 inner join inv_master_add ia (nolock) on ia.part_no = ol.part_no
 left outer join cvo_promotions p (nolock) on p.promo_id = co.promo_id and p.promo_level = co.promo_level
 
 LEFT OUTER JOIN 
 (select order_no, order_ext, line_no, SUM(qty) alloc_qty
 FROM tdc_soft_alloc_tbl (nolock)
 GROUP BY order_no, order_ext, line_no
 ) ha ON ha.line_no = ol.line_no AND ha.order_ext = ol.order_ext AND ha.order_no = ol.order_no

 LEFT OUTER join
(select sof.order_no, sof.order_ext, sof.line_no, SUM(sa_stock)-sum(bo_stock) sa_qty_avail, SUM(bo_stock) sa_qty_notavail
FROM cvo_get_soft_alloc_stock_vw sof (nolock)
GROUP BY sof.order_no, sof.order_ext, sof.line_no
) sa ON sa.line_no = ol.line_no AND sa.order_no = ol.order_no AND sa.order_ext = ol.order_ext

where 1=1
-- cvo_item_avail_vw cia (nolock)
and o.status < 'R' 
and ol.ordered > ol.shipped

-- and ol.part_no = cia.part_no AND ol.location = cia.location

--and cia.qty_avl<=0

--and not exists (select * from tdc_soft_alloc_tbl (nolock) where part_no = ol.part_no and
--order_no = ol.order_no and order_ext = ol.order_ext and line_no = ol.line_no)
--and cia.style = 'portia'






















GO
GRANT REFERENCES ON  [dbo].[cvo_open_order_detail_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[cvo_open_order_detail_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[cvo_open_order_detail_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[cvo_open_order_detail_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[cvo_open_order_detail_vw] TO [public]
GO
