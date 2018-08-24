SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[cvo_bt_order_log_sp] 
@startdate DATETIME, @enddate DATETIME

AS 

SET NOCOUNT ON

BEGIN

;WITH bt
AS
(
SELECT MAX(CASE WHEN (i.category = 'bt' OR col.add_polarized = 'y') AND i.type_code IN ('frame','sun') THEN ol.part_no ELSE '' END) frame,
       MAX(CASE WHEN col.is_polarized = 1 AND i.category = 'bt' AND i.type_code = 'lens' THEN ol.part_no ELSE '' END) lens,
       ol.order_no,
       ol.order_ext,
       o.user_category,
       SUM(ol.ordered) qty_ord
FROM dbo.ord_list ol (nolock)
    JOIN orders o (NOLOCK) ON o.order_no = ol.order_no AND o.ext = ol.order_ext
    JOIN dbo.CVO_ord_list col (nolock)
        ON col.order_no = ol.order_no
           AND col.order_ext = ol.order_ext
           AND col.line_no = ol.line_no
    JOIN dbo.inv_master i (nolock)
        ON i.part_no = ol.part_no
WHERE ol.status ='T' AND o.type = 'i'
      AND O.who_entered <> 'BACKORDR'
      AND i.type_code IN ('frame','sun','lens')
      AND
      (
      col.add_polarized = 'Y'
      OR
      (
      col.is_polarized = 1
      AND i.category = 'bt'
      AND i.type_code = 'lens'
      )
      OR i.category = 'bt'
      )
GROUP BY ol.order_no,
         ol.order_ext,
         o.user_category
HAVING MAX(CASE WHEN (i.category = 'bt' OR col.add_polarized = 'y') AND i.type_code IN ('frame','sun') THEN ol.part_no ELSE '' END) <> ''

)
SELECT CASE WHEN iframe.category = 'bt' AND iframe.part_no LIKE '%F1' AND ISNULL(bt.lens,'') <> '' THEN 'BT Readers'
            WHEN iframe.category = 'bt' THEN 'BT Plano'
            WHEN iframe.category <> 'BT' AND ISNULL(bt.lens,'') <> '' THEN 'Make it BT'
            ELSE ' ' END
            AS SalesType,
        IFRAME.category BRAND,
       bt.frame,
        frame.field_2 model,
        iframe.type_code,
       bt.lens,
        lens.description,
       bt.order_no,
       bt.order_ext,
       bt.user_category,
       BT.qty_ord,
       o.ship_to_name,
       o.date_entered,
       o.date_shipped,
       o.user_category,
       o.ship_to_region territory,
       o.salesperson,
       co.promo_id,
       co.promo_level
FROM bt
    JOIN dbo.orders o (NOLOCK)
        ON o.order_no = bt.order_no
           AND o.ext = bt.order_ext
    JOIN dbo.CVO_orders_all co (NOLOCK)
        ON co.order_no = o.order_no
           AND co.ext = o.ext
    JOIN inv_master_add frame (NOLOCK) ON frame.part_no = bt.frame
    JOIN inv_master iframe (NOLOCK) ON iframe.part_no = bt.frame
    LEFT OUTER JOIN inv_master lens (NOLOCK) ON lens.part_no = bt.lens
    WHERE o.status = 'T'
    AND RIGHT(o.user_category,2) <> 'RB'
    AND o.date_entered BETWEEN @startdate AND @enddate
    AND (iframe.category = 'bt' OR (iframe.category <> 'bt' AND ISNULL(lens.part_no,'') > ''))
    ;

    END
    
    GRANT EXECUTE ON cvo_bt_order_log_sp  TO public
GO
GRANT EXECUTE ON  [dbo].[cvo_bt_order_log_sp] TO [public]
GO
