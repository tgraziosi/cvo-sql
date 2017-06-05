SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE view [dbo].[cvo_OpenPickRpt_vw] as
-- select * from cvo_OpenPickRpt_vw
select
o.order_no,
o.ext order_ext,
o.user_category as type,
c.carton_no,
c.status as carton_status,
ol.qty_ord,
ol.qty_shp,
ISNULL(alc.qty_alloc,0) qty_alloc,
ISNULL(pck.qty_picked,0) qty_picked,		   
ISNULL(pack.qty_packed,0) qty_packed,
--case when m.pack_no is null then 'NO' else 'YES' end as is_Mast_pack,
isnull(m.pack_no,'')pack_no,
c.station_id,
c.order_type,
c.carrier_code,
o.sch_ship_date,
o.cust_code,
o.ship_to ship_to_no,
isnull(o.sold_to,'') as Global_ship_to,   -- eladd
o.ship_to_name name,
o.date_printed,  -- eladd
c.last_modified_date,
replace(c.modified_by,'CVOPTICAL\','') AS modified_by,
-- RIGHT(c.modified_by, LEN(c.modified_by)-CHARINDEX('10',c.modified_by,1) -10) AS modified_by,
o.salesperson,
o.ship_to_region AS Territory,
o.total_amt_order - o.tot_ord_disc as total_amt_order,
ISNULL(CO.COMMENTS,'')Comments,
isnull(addr_sort1,'') Customer_type,
case when o.status = 'n' and convert(varchar(10), date_entered, 108) <= '16:00:00'
    and date_entered <= dateadd(DD,-1,getdate()) then 'NEW'
    when o.status = 'p' and date_printed <= dateadd(DD,-1,getdate()) then 'OPEN/PRINT'
    when o.status = 'q' and sch_ship_date <= dateadd(DD,-1,getdate()) then 'OPEN/PICK'
    ELSE '' END AS AGE,
o.status,
tsc.stage_error

from  orders_all o (nolock) 
join armaster ar (nolock) on ar.customer_code = o.cust_code and ar.ship_to_code = o.ship_to
LEFT OUTER JOIN dbo.tdc_carton_tx AS c ON  c.order_no = o.order_no AND c.order_ext = o.ext
left outer join tdc_master_pack_ctn_tbl m (nolock) on m.carton_no = c.carton_no
left outer JOIN cvo_OpenPickRptComments co (NOLOCK) ON CO.ORDER_NO=O.ORDER_NO AND CO.ORDER_EXT=O.EXT
LEFT OUTER JOIN dbo.tdc_stage_carton AS tsc	   ON tsc.carton_no = c.carton_no
LEFT OUTER JOIN 
(select order_no, order_ext, SUM(ordered) as qty_ord, SUM(shipped) AS qty_shp
	from dbo.ord_list with (nolock)
	group by order_no, order_ext
) ol ON ol.order_no = o.order_no AND ol.order_ext = o.ext
LEFT OUTER JOIN
(SELECT order_no, order_ext, SUM(qty) AS qty_alloc
	   FROM   dbo.tdc_soft_alloc_tbl WITH (NOLOCK)
	   GROUP BY order_no, order_ext
) alc ON alc.order_no = o.order_no AND alc.order_ext = o.ext
LEFT OUTER JOIN
(select order_no, order_ext, SUM(quantity) as qty_picked
		from dbo.tdc_dist_item_pick with (nolock)
		group by order_no, order_ext
) pck ON pck.order_no = o.order_no AND pck.order_ext = o.ext
LEFT OUTER JOIN
(select order_no, order_ext, SUM(pack_qty) as qty_packed
		from dbo.tdc_carton_detail_tx with (nolock)
		GROUP BY order_no, order_ext
) pack ON pack.order_no = o.order_no AND pack.order_ext = o.ext

--where ( c.status < 'T' OR c.status='X' ) and
where o.status in ('P')
and ISNULL(c.last_modified_date,DATEADD(D, DATEDIFF(D,0,GETDATE()),-1)) < DATEADD(D, DATEDIFF(D,0,GETDATE()) ,0)

-- select * from cvo_OpenPickRpt_vw order by last_modified_date







GO
