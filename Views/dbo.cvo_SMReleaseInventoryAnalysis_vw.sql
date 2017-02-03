SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[cvo_SMReleaseInventoryAnalysis_vw]
AS

-- select * from cvo_smreleaseinventoryanalysis_vw where style = 'sandee'
 --	SELECT * FROM dbo.cvo_item_avail_vw AS iav2 WHERE iav2.Style = 'sandee' AND location = '001'

	--SELECT * FROM inventory WHERE part_no = 'SMSANDPUR4814' AND location = '001'

SELECT  sm.Brand ,
        sm.ResType ,
        sm.PartType ,
        sm.Style ,
        sm.part_no ,
        sm.description ,
        sm.location ,
        sm.in_stock ,
        sm.SOF ,
        sm.ReserveQty ,
		sm.Non_alloc,
		sm.qcqty2 QCQty,
        sm.QOH ,
        sm.future_ord_qty ,
        sm.addl_order_qty_projected ,
        sm.total_ord_qty_projection ,
        sm.rx_safety_stock ,
        sm.QOH_less_rx_ss ,
        sm.po_on_order ,
		final_QOH = 
		sm.in_stock-sm.total_ord_qty_projection-sm.rx_safety_stock+sm.po_on_order,
        sm.ReleaseDate ,
        sm.Gender ,
        sm.Material ,
        sm.vendor ,
        sm.Color_desc,
		sm.shipped_0120,
		sm.num_orders
		FROM
(
    SELECT  Brand ,
            ResType ,
            PartType ,
            Style ,
            iav.part_no ,
            description ,
            iav.location ,
            iav.in_stock in_stock ,
			iav.qcqty2, 
            iav.SOF ,
            iav.ReserveQty ,
			iav.Non_alloc,
			ISNULL(s.shipped_0120,0) shipped_0120,
            iav.qty_avl + iav.qcqty2 + iav.Non_alloc + ISNULL(s.shipped_0120,0) QOH ,
            future_ord_qty ,
            addl_order_qty_projected = ROUND(SOF * n.num_orders , 0) - iav.SOF,
            total_ord_qty_projection = ROUND(SOF * n.num_orders , 0) ,
            rx_safety_stock = CAST(.25 * ROUND(SOF *  n.num_orders, 0)  AS INT) ,
            QOH_less_rx_ss = (iav.qcqty2 + iav.qty_avl + iav.Non_alloc + ISNULL(s.shipped_0120,0)) 
							 - CAST(.25 * ROUND(SOF * n.num_orders, 0) AS INT) ,
			ISNULL(rel.po_on_order,0)+ISNULL(p.qty_ocean,0)- ISNULL(s.shipped_0120,0) po_on_order ,
            ReleaseDate ,
            Gender ,
            Material ,
            vendor ,
            Color_desc,
			n.num_orders
    FROM    cvo_item_avail_vw iav
            CROSS JOIN ( SELECT ROUND(1200.00 / COUNT(DISTINCT o.order_no),2)  num_orders
                         FROM   ord_list ol
								JOIN cvo_orders_all o ON o.order_no = ol.order_no AND o.ext = ol.order_ext
                                JOIN inv_master i ON i.part_no = ol.part_no
                         WHERE  i.category = 'sm'
                                AND i.type_code IN ( 'frame', 'sun' )
                                AND ol.status < 't'
								AND o.promo_id = 'sm'
								AND o.promo_level NOT LIKE '%pc%'
                       ) n
            LEFT OUTER JOIN ( SELECT    r.part_no ,
                                        r.location ,
                                        SUM(r.quantity - r.received ) po_on_order
                              FROM      releases r
                                        JOIN dbo.purchase_all AS pa ON pa.po_key = r.po_key AND pa.location = r.location

                              WHERE     1 = 1
-- AND r.inhouse_date < '2/28/2016' 
                                        AND pa.user_category IN ( 'frame-1',
                                                              'frame-2',
                                                              'frame-3' )
                                        AND quantity > received
                                        AND r.status = 'O'
                              GROUP BY  r.part_no ,
                                        r.location
                            ) rel ON rel.part_no = iav.part_no
                                     AND rel.location = iav.location
			LEFT OUTER JOIN
            ( SELECT part_no, '001' location, SUM(qty_ocean) qty_ocean
					 FROM cvo_sm_po_ocean_tbl 
					 GROUP BY part_no
			) p ON p.part_no = iav.part_no AND p.location = iav.location
			LEFT OUTER JOIN
            ( SELECT part_no, '001' location, SUM(shipped_0120) shipped_0120
					 FROM cvo_sm_0120_ship
					 GROUP BY part_no
			) s ON s.part_no = iav.part_no AND s.location = iav.location
    WHERE   iav.location = '001'
            AND iav.Brand = 'sm'
            AND iav.ResType IN ( 'frame', 'sun' )
			) sm

     


GO
GRANT REFERENCES ON  [dbo].[cvo_SMReleaseInventoryAnalysis_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[cvo_SMReleaseInventoryAnalysis_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[cvo_SMReleaseInventoryAnalysis_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[cvo_SMReleaseInventoryAnalysis_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[cvo_SMReleaseInventoryAnalysis_vw] TO [public]
GO
