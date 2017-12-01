SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[cvo_open_order_detail_past_orders_sp] (@location VARCHAR(12) = null)
AS

SET NOCOUNT ON;

SET ANSI_WARNINGS OFF;

BEGIN


    SELECT ol.brand,
           ol.restype,
           ol.gender,
           ol.style,
           ol.part_no,
           ol.vendor,
           ol.pom_date,
           ol.qty_avl,
           ol.qty_Rec,
           ol.location,
           ol.NextPODueDate,
           ol.order_no,
           ol.ext,
           ol.line_no,
           ol.user_category,
           ol.hold_reason,
           ol.cust_code,
           ol.ship_to,
           ol.ship_to_name,
           ol.cust_po,
           ol.Territory,
           ol.CustomerType,
           ol.date_entered,
           ol.sch_ship_date,
           ol.open_ord_qty,
           ol.alloc_qty,
           ol.sa_qty_avail,
           ol.sa_qty_notavail,
           ol.DaysOverDue,
           ol.who_entered,
           ol.status,
           ol.bo_flg,
           ol.net_amt,
           ol.so_priority_code,
           ol.promo_id,
           ol.promo_level,
           ol.p_hold_reason,
           ol.allocation_date,
           ol.add_pattern,
           ol.ordered,
           consolidation_no = CAST(c.consolidation_no AS VARCHAR(10))
                              + ISNULL(
                                (
                                    SELECT ' Partial Hold'
                                    FROM dbo.cvo_masterpack_consolidation_det AS cmcd
                                        JOIN orders o
                                            ON o.order_no = cmcd.order_no
                                               AND o.ext = cmcd.order_ext
                                    WHERE cmcd.consolidation_no = c.consolidation_no
                                          AND ISNULL(o.status, 'n') < 'n'
                                ),
                                ''
                                      )
    FROM 
        (
            SELECT DISTINCT
                order_no,
                o.ext
            FROM orders o (NOLOCK)
            WHERE 1 = 1
                  AND o.location = ISNULL(@location, o.location )
                  AND DATEDIFF(d, o.sch_ship_date, GETDATE()) > 0
                  AND o.status IN ( 'n' )
                  AND o.so_priority_code <> 3
                  AND who_entered <> 'backordr'
                  AND RIGHT(user_category, 2) <> 'rb'
        ) oo
		JOIN cvo_open_order_detail_vw ol (NOLOCK)
            ON oo.order_no = ol.order_no
               AND oo.ext = ol.ext
        INNER JOIN CVO_orders_all co (NOLOCK)
            ON co.order_no = ol.order_no
               AND co.ext = ol.ext
        LEFT OUTER JOIN CVO_promotions p (NOLOCK)
            ON co.promo_id = p.promo_id
               AND co.promo_level = p.promo_level
        LEFT OUTER JOIN cvo_masterpack_consolidation_det c (NOLOCK)
            ON c.order_no = ol.order_no
               AND c.order_ext = ol.ext
    WHERE 1 = 1
          AND restype IN ( 'frame', 'sun', 'parts' )
          AND ol.qty_avl > 0; /*added 8/3/2015*/
-- order by brand, style, part_no

END;

GRANT EXECUTE ON cvo_open_order_detail_past_orders_sp TO PUBLIC;
GO
