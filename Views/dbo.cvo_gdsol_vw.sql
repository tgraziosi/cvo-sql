SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


-- SELECT * FROM cvo_gdsol_vw WHERE allocation_date BETWEEN '01/31/2015' AND GETDATE() and ordered < 0

CREATE VIEW [dbo].[cvo_gdsol_vw]
AS
    SELECT TOP 100 PERCENT
            dbo.adodl_vw.order_no ,
            dbo.adodl_vw.order_ext ,
            dbo.adodl_vw.line_no ,
            dbo.adodl_vw.location ,
            dbo.adodl_vw.part_no ,
            dbo.adodl_vw.description ,
            dbo.adodl_vw.uom ,
			ordered = CASE WHEN orders.type = 'i' THEN ord_list.ordered ELSE ord_list.cr_ordered * -1 END,
			-- dbo.adodl_vw.ordered ,
            shipped = CASE WHEN orders.type = 'i' THEN ord_list.shipped ELSE ord_list.cr_shipped * -1 END,
			-- dbo.adodl_vw.shipped ,
            dbo.adodl_vw.price ,
            Ext_Price = CASE WHEN orders.type = 'i' THEN dbo.adodl_vw.ext_price ELSE dbo.adodl_vw.price * ord_list.cr_shipped * -1 END,
			-- dbo.adodl_vw.Ext_Price ,
            dbo.ord_list.status ,
            dbo.orders.sch_ship_date ,
            dbo.orders.req_ship_date ,
            dbo.orders.forwarder_key ,
			allocation_date = ISNULL(co.allocation_date, DATEADD(d,DATEDIFF(d,0,orders.date_entered),0) ),
			dbo.orders.date_shipped,
			dbo.orders.who_entered,
			co.promo_id,
			dbo.orders.user_category,
            x_req_ship_date = ( DATEDIFF(DAY, '01/01/1900',
                                         dbo.orders.req_ship_date) + 693596 )
            + ( DATEPART(hh, dbo.orders.req_ship_date) * .01 + DATEPART(mi,
                                                              dbo.orders.req_ship_date)
                * .0001 + DATEPART(ss, dbo.orders.req_ship_date) * .000001 ) ,
            x_sch_ship_date = ( DATEDIFF(DAY, '01/01/1900',
                                         dbo.orders.sch_ship_date) + 693596 )
            + ( DATEPART(hh, dbo.orders.sch_ship_date) * .01 + DATEPART(mi,
                                                              dbo.orders.sch_ship_date)
                * .0001 + DATEPART(ss, dbo.orders.sch_ship_date) * .000001 ), 
			x_allocation_date = ( DATEDIFF(DAY, '01/01/1900',
                                         ISNULL(co.allocation_date,orders.date_entered)) + 693596 )
            + ( DATEPART(hh, ISNULL(co.allocation_date,orders.date_entered)) * .01 + DATEPART(mi,
                                                              co.allocation_date)
                * .0001 + DATEPART(ss, ISNULL(co.allocation_date, orders.date_entered)) * .000001 ),
			x_date_shipped = ( DATEDIFF(DAY, '01/01/1900',
                                         orders.date_shipped) + 693596 )
            + ( DATEPART(hh, orders.date_shipped) * .01 + DATEPART(mi,
                                                              orders.date_shipped)
                * .0001 + DATEPART(ss, orders.date_shipped) * .000001 )
		
   
    FROM    dbo.adodl_vw
            LEFT OUTER JOIN dbo.orders (NOLOCK) ON dbo.adodl_vw.order_no = dbo.orders.order_no
                                                   AND dbo.adodl_vw.order_ext = dbo.orders.ext
            LEFT OUTER JOIN dbo.ord_list (NOLOCK) ON 
													 --dbo.adodl_vw.ordered > dbo.ord_list.shipped
                                                     -- AND 
													 dbo.adodl_vw.order_no = dbo.ord_list.order_no
                                                     AND dbo.adodl_vw.order_ext = dbo.ord_list.order_ext
                                                     AND dbo.adodl_vw.line_no = dbo.ord_list.line_no
			LEFT OUTER JOIN dbo.cvo_orders_all co (NOLOCK) ON co.ext = orders.ext AND co.order_no = orders.order_no
    ORDER BY dbo.adodl_vw.order_no DESC ,
            dbo.adodl_vw.order_ext ,
            dbo.adodl_vw.line_no
    UNION ALL
    SELECT  t1.order_no ,
            t1.order_ext ,
            t1.line_no ,
            t1.location ,
            t1.part_no ,
            t1.description ,
            t1.uom ,
            t1.ordered ,
            t1.shipped ,
            t1.price ,
            ( t1.shipped * t1.price ) AS ext_price ,
            t1.status ,
            t2.sch_ship_date ,
            t2.req_ship_date ,
            t2.forwarder_key ,
			t2.sch_ship_date,
			t2.date_shipped,
			t2.who_entered,
			'' AS promo_id,
			'ST' AS user_category,
            x_req_ship_date = 1 ,
            x_sch_ship_date = 1,
			x_allocation_date = 1,
			x_date_shipped = 1
    FROM    cvo_ord_list_hist t1 ( NOLOCK )
            JOIN CVO_orders_all_Hist t2 ( NOLOCK ) ON t1.order_no = t2.order_no;





GO
GRANT REFERENCES ON  [dbo].[cvo_gdsol_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[cvo_gdsol_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[cvo_gdsol_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[cvo_gdsol_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[cvo_gdsol_vw] TO [public]
GO
