SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/* tag 11/30/2011 - New view for WMS oriented order data*/
/* tag 2/21/2012 - added date printed and date transferred */
/* tag 4/16/12 - added megasys order number */
/* tag 08/16/13 - add customer type per LM request */
/* tag 09/03/2013 - add back order flag */
-- tag - 032917 - add promo and level

CREATE VIEW [dbo].[adord_TDC_vw]
AS
    SELECT 
--sortkey = tdco.tdc_status + ado.status,
            sortkey = ado.status_desc ,
            tdco.TDC_status ,
            tdcs.Description ,
            ado.status ,
            ado.status_desc ,
            ado.order_no ,
            ado.ext ,
            ado.user_category ,
            ado.shipped_flag ,
-- 0 = ALLOW BACK ORDER, 1 = SC, 2 = ALLOW PARTIAL
            CASE WHEN o.back_ord_flag = 0 THEN 'AB'
                 WHEN o.back_ord_flag = 1 THEN 'SC'
                 WHEN o.back_ord_flag = 2 THEN 'AP'
            END AS bo_flg ,
-- 08/19/2013 - tag - per SS request - v1.6 
            ado.date_sch_ship ,
            ado.date_entered ,
            ISNULL(( SELECT SUM(ordered) AS qty_ord
                     FROM   dbo.ord_list WITH ( NOLOCK )
                     WHERE  ( order_no = ado.order_no )
                            AND ( order_ext = ado.ext )
                     GROUP BY order_no
                   ), 0) AS qty_ord ,
            ISNULL(( SELECT SUM(shipped) AS qty_shp
                     FROM   dbo.ord_list WITH ( NOLOCK )
                     WHERE  ( order_no = ado.order_no )
                            AND ( order_ext = ado.ext )
                     GROUP BY order_no
                   ), 0) AS qty_shp ,
            ISNULL(( SELECT SUM(bo_stock)
                     FROM   cvo_get_soft_alloc_stock_vw sof ( NOLOCK )
                     WHERE  sof.order_no = ado.order_no
                            AND sof.order_ext = ado.ext
                   ), 0) qty_BO ,
            ISNULL(( SELECT SUM(sa_stock) - SUM(bo_stock)
                     FROM   cvo_get_soft_alloc_stock_vw sof ( NOLOCK )
                     WHERE  sof.order_no = ado.order_no
                            AND sof.order_ext = ado.ext
                   ), 0) qty_sof ,
            ISNULL(( SELECT SUM(qty) AS qty_alc
                     FROM   dbo.tdc_soft_alloc_tbl WITH ( NOLOCK )
                     WHERE  ( order_no = ado.order_no )
                            AND ( order_ext = ado.ext )
                            AND ( location = ado.location )
                            AND ( order_type = 'S' )
                            AND ( lot_ser <> 'CDOCK' )
                            AND ( bin_no <> 'CDOCK' )
                   ), 0) AS qty_alloc ,
            ISNULL(( SELECT SUM(quantity) AS qty_pck
                     FROM   dbo.tdc_dist_item_pick WITH ( NOLOCK )
                     WHERE  ( order_no = ado.order_no )
                            AND ( order_ext = ado.ext )
                            AND ( [function] = 'S' )
                     GROUP BY order_no
                   ), 0) AS qty_picked ,
            ISNULL(( SELECT SUM(pack_qty) AS qty_pak
                     FROM   dbo.tdc_carton_detail_tx WITH ( NOLOCK )
                     WHERE  ( order_no = ado.order_no )
                            AND ( order_ext = ado.ext )
                     GROUP BY order_no
                   ), 0) AS qty_packed ,
            ISNULL(tdco.total_cartons, 0) AS total_cartons ,
            ado.who_entered ,
            ado.routing ,
            ado.cust_code ,
            ado.ship_to ,
            ado.ship_to_name ,
            ISNULL(o.sold_to, '') AS Global_ship_to ,
            ISNULL(o.sold_to_addr1, '') AS Global_name ,
            o.date_printed ,
            o.date_transfered ,
            ado.date_shipped ,
            ado.date_invoice ,
            ado.invoice_no ,
            ado.total_amt_order ,
            ISNULL(ar.addr_sort1, '') cust_type , -- tag 081613 - per LM request
            ISNULL(o.user_def_fld4, '') MS_order_no ,
            ISNULL(co.promo_id, '') promo_id ,
            ISNULL(co.promo_level, '') promo_level
    FROM    dbo.adord_vw ado ( NOLOCK )
            INNER JOIN TDC_ORDER tdco ( NOLOCK ) ON ado.order_no = tdco.Order_no
                                                    AND ado.ext = tdco.Order_ext
            INNER JOIN TDC_STATUS_LIST tdcs ( NOLOCK ) ON tdcs.Code = tdco.TDC_status
            INNER JOIN orders_all o ( NOLOCK ) ON o.order_no = ado.order_no
                                                  AND o.ext = ado.ext
            JOIN dbo.CVO_orders_all AS co ( NOLOCK ) ON co.order_no = ado.order_no
                                                        AND co.ext = ado.ext
            INNER JOIN armaster ar ( NOLOCK ) ON ar.customer_code = ado.cust_code
                                                 AND ar.ship_to_code = ado.ship_to
    WHERE   ado.status < 'V';





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
