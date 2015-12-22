SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE view [dbo].[cvo_OpenPickRpt_vw] as
-- select * from cvo_OpenPickRpt_vw
select
c.order_no,
c.order_ext,
o.user_category as type,
c.carton_no,
c.status as carton_status,
isnull((select sum(ordered) as qty_ord
	from dbo.ord_list with (nolock)
	where (order_no = c.order_no) and (order_ext = c.order_ext)
	group by order_no), 0) as qty_ord,
isnull((select sum(shipped) as qty_shp
	from dbo.ord_list with (nolock)
	where (order_no = c.order_no) and (order_ext = c.order_ext)
	group by order_no), 0) as qty_shp,

ISNULL((SELECT SUM(qty) AS qty_alc
	   FROM   dbo.tdc_soft_alloc_tbl WITH (NOLOCK)
	   WHERE (order_no = c.order_no) AND (order_ext = c.order_ext) AND (location = o.location) AND (order_type = 'S') AND (lot_ser <> 'CDOCK') AND 
		(bin_no <> 'CDOCK') OR
		(order_no = c.order_no) AND (order_ext = c.order_ext) AND 
		(location = o.location) AND (order_type = 'S') 
	   GROUP BY order_no), 0) AS qty_alloc,
					   
isnull((select sum(quantity) as qty_pck
		from dbo.tdc_dist_item_pick with (nolock)
		where (order_no = c.order_no) and (order_ext = c.order_ext) 
		and ([function] = 'S')
		group by order_no), 0) as qty_picked,
isnull((select sum(pack_qty) as qty_pak
		from dbo.tdc_carton_detail_tx with (nolock)
		WHERE (order_no = c.order_no) AND (order_ext = c.order_ext)
		group by order_no), 0) as qty_packed,

--case when m.pack_no is null then 'NO' else 'YES' end as is_Mast_pack,
isnull(m.pack_no,'')pack_no,
c.station_id,
c.order_type,
c.carrier_code,
o.sch_ship_date,
c.cust_code,
c.ship_to_no,
isnull(o.sold_to,'') as Global_ship_to,   -- eladd
c.name,
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
o.status

from tdc_carton_tx c (nolock)
left outer join tdc_master_pack_ctn_tbl m (nolock) on m.carton_no = c.carton_no
join orders_all o (nolock) on o.order_no = c.order_no and o.ext = c.order_ext
join armaster ar (nolock) on ar.customer_code = c.cust_code and ar.ship_to_code = c.ship_to_no
left outer JOIN cvo_OpenPickRptComments co (NOLOCK) ON CO.ORDER_NO=O.ORDER_NO AND CO.ORDER_EXT=O.EXT

--where ( c.status < 'T' OR c.status='X' ) and
where o.status in ('P')
and c.last_modified_date < DATEADD(D, DATEDIFF(D,0,GETDATE()) ,0)

-- select * from cvo_OpenPickRpt_vw order by last_modified_date






GO
