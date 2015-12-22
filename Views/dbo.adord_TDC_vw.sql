SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO





/* tag 11/30/2011 - New view for WMS oriented order data*/
/* tag 2/21/2012 - added date printed and date transferred */
/* tag 4/16/12 - added megasys order number */
/* tag 08/16/13 - add customer type per LM request */
/* tag 09/03/2013 - add back order flag */

CREATE VIEW [dbo].[adord_TDC_vw]
AS
SELECT 
--sortkey = tdco.tdc_status + ado.status,
sortkey = ado.status_desc,
tdco.TDC_status, 
tdcs.Description, 
ado.status, 
ado.status_desc, 
ado.order_no, 
ado.ext, 
ado.user_category,
ado.shipped_flag,
-- 0 = ALLOW BACK ORDER, 1 = SC, 2 = ALLOW PARTIAL
case when o.back_ord_flag = 0 then 'AB'
    when o.back_ord_flag = 1 then 'SC'
    when o.back_ord_flag = 2 then 'AP'
    end as bo_flg,
-- 08/19/2013 - tag - per SS request - v1.6 
ado.date_sch_ship, 
ado.date_entered,            
isnull((select sum(ordered) as qty_ord
	from dbo.ord_list with (nolock)
	where (order_no = ado.order_no) and (order_ext = ado.ext)
	group by order_no), 0) as qty_ord,
isnull((select sum(shipped) as qty_shp
	from dbo.ord_list with (nolock)
	where (order_no = ado.order_no) and (order_ext = ado.ext)
	group by order_no), 0) as qty_shp,

isnull((select sum(bo_stock) from cvo_get_soft_alloc_stock_vw sof (nolock)
where sof.order_no = ado.order_no and sof.order_ext = ado.ext ), 0) qty_BO,

isnull((select sum(sa_stock)-sum(bo_stock) from cvo_get_soft_alloc_stock_vw sof (nolock)
where sof.order_no = ado.order_no and sof.order_ext = ado.ext ), 0) qty_sof,


ISNULL((SELECT SUM(qty) AS qty_alc
       FROM   dbo.tdc_soft_alloc_tbl WITH (NOLOCK)
       WHERE (order_no = ado.order_no) AND (order_ext = ado.ext) 
       AND (location = ado.location) AND (order_type = 'S') AND (lot_ser <> 'CDOCK') AND 
        (bin_no <> 'CDOCK')), 0) AS qty_alloc,
isnull((select sum(quantity) as qty_pck
		from dbo.tdc_dist_item_pick with (nolock)
		where (order_no = ado.order_no) and (order_ext = ado.ext) 
		and ([function] = 'S')
		group by order_no), 0) as qty_picked,
isnull((select sum(pack_qty) as qty_pak
		from dbo.tdc_carton_detail_tx with (nolock)
		WHERE (order_no = ado.order_no) AND (order_ext = ado.ext)
		group by order_no), 0) as qty_packed,
isnull(tdco.total_cartons,0) as total_cartons, 
ado.who_entered, 
ado.routing, 
ado.cust_code, 
ado.ship_to, 
ado.ship_to_name,
isnull(o.sold_to,'') as Global_ship_to,
isnull(o.sold_to_addr1,'') as Global_name,
o.date_printed,
o.date_transfered, 
ado.date_shipped, 
ado.date_invoice, 
ado.invoice_no, 
ado.total_amt_order,
isnull(ar.addr_sort1,'') cust_type, -- tag 081613 - per LM request
isnull(o.user_def_fld4,'') MS_order_no
FROM  dbo.adord_vw ado (nolock) INNER JOIN tdc_order tdco (nolock) ON 
    ado.order_no = tdco.Order_no AND ado.ext = tdco.Order_ext
INNER JOIN 	tdc_status_list tdcs (nolock) on tdcs.Code = tdco.TDC_status
inner join 	orders_all o (nolock) on o.order_no = ado.order_no and o.ext = ado.ext
inner join armaster ar (nolock) on ar.customer_code = ado.cust_code and ar.ship_to_code = ado.ship_to
where ado.status < 'V'




GO
GRANT REFERENCES ON  [dbo].[adord_TDC_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[adord_TDC_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[adord_TDC_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[adord_TDC_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[adord_TDC_vw] TO [public]
GO
