SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[cvo_bt_order_log_sp] @startdate DATETIME, @enddate DATETIME

AS 

SET NOCOUNT ON

-- exec cvo_bt_order_log_sp '1/1/2018','12/31/2018'

DECLARE @sdate DATETIME, @edate DATETIME
SELECT @sdate = @startdate, @edate = @enddate

BEGIN

;WITH bt
AS
(
SELECT CASE WHEN i.type_code = 'lens' THEN ol.part_no END lens,
       CASE WHEN i.type_code IN ('frame','sun') THEN ol.part_no end frame,
       ol.order_no,
       ol.order_ext,
       ol.ordered qty_ord,
       CASE WHEN col.add_polarized = 'Y' AND i.category <> 'BT' AND i.type_code IN ('frame','sun')
                    AND EXISTS (SELECT 1 FROM inv_master ii JOIN dbo.ord_list ool ON ii.part_no = ool.part_no 
                                WHERE ii.category = 'bt' AND ii.type_code = 'lens' AND ool.order_no = col.order_no AND col.order_ext = o.ext) THEN 'MIB'
            WHEN col.is_polarized = 1 AND i.category = 'bt' AND i.type_code = 'lens' AND i.description LIKE '%reader%' THEN 'Lens-Reader'
            WHEN col.is_polarized = 1 AND i.category = 'bt' AND i.type_code = 'lens' /*AND i.description LIKE '%plano%'*/ THEN 'Lens-Plano'
            WHEN i.category = 'bt' AND 'F1' = RIGHT(i.part_no,2)  THEN 'BTF1'
            WHEN i.category = 'BT' THEN 'BT'
            END AS line_type
FROM dbo.ord_list ol (nolock)
    JOIN orders o (NOLOCK) ON o.order_no = ol.order_no AND o.ext = ol.order_ext
    JOIN dbo.CVO_ord_list col (nolock)
        ON col.order_no = ol.order_no
           AND col.order_ext = ol.order_ext
           AND col.line_no = ol.line_no
    JOIN dbo.inv_master i (nolock)
        ON i.part_no = ol.part_no
WHERE ol.status ='T' AND o.type = 'i'
      AND RIGHT(o.user_category,2) <> 'RB'
      AND O.who_entered <> 'BACKORDR'
      AND i.type_code IN ('frame','sun','lens')
      AND
      ( -- request for polarized lens
      col.add_polarized = 'Y'
      OR
      ( -- BT lens
      col.is_polarized = 1
      AND i.category = 'bt'
      AND i.type_code = 'lens'
      )
      OR i.category = 'bt' -- BT frame w/lens
      )
      AND o.date_entered BETWEEN @sdate AND @edate

         
)
SELECT sum(CASE WHEN bt.line_type = 'lens-plano' THEN bt.qty_ord ELSE 0 END) num_lens_plano,
       SUM(CASE WHEN bt.line_type = 'lens-reader' THEN bt.qty_ord ELSE 0 END) num_lens_reader,
       SUM(CASE WHEN bt.line_type = 'MIB' THEN bt.qty_ord ELSE 0 END) num_MIB,
       SUM(CASE WHEN BT.line_type = 'BTF1' THEN bt.qty_ord ELSE 0 END) NUM_BTF1,
       SUM(CASE WHEN bt.line_type = 'bt' THEN bt.qty_ord ELSE 0 END) num_bt,
       bt.order_no,
       bt.order_ext,
       SUM(BT.qty_ord) qty_ord,
       o.ship_to_name,
       o.date_entered,
       o.date_shipped,
       o.user_category,
       o.ship_to_region territory,
       o.salesperson,
       ISNULL(co.promo_id,'') promo_id,
       ISNULL(co.promo_level,'') promo_level,
       REPLACE(FRAME_PARTS.FRAME_PARTS,'(1)','') FRAME_PARTS,
       REPLACE(LENS_PARTS.LENS_PARTS,'(1)','') LENS_PARTS
FROM bt
    JOIN dbo.orders o (NOLOCK)
        ON o.order_no = bt.order_no
           AND o.ext = bt.order_ext
    JOIN dbo.CVO_orders_all co (NOLOCK)
        ON co.order_no = o.order_no
           AND co.ext = o.ext
    LEFT OUTER JOIN inv_master_add frame (NOLOCK) ON frame.part_no = bt.frame
    LEFT OUTER JOIN inv_master iframe (NOLOCK) ON iframe.part_no = bt.frame
    LEFT OUTER JOIN inv_master lens (NOLOCK) ON lens.part_no = bt.lens
    LEFT OUTER JOIN 
    ( SELECT DISTINCT bt.order_no, bt.order_ext,
        STUFF(( SELECT '; '+ bt2.FRAME + '('+CAST(COUNT(bt2.frame) AS VARCHAR(4))+')' FROM BT BT2 WHERE BT2.ORDER_NO = BT.ORDER_NO AND BT2.ORDER_EXT = BT.order_ext GROUP BY bt2.frame
        FOR XML PATH('')
        ),1,1,'') FRAME_PARTS
        FROM BT  )
        AS FRAME_PARTS ON FRAME_PARTS.order_no = bt.order_no AND FRAME_PARTS.order_ext = bt.order_ext
    LEFT OUTER JOIN 
    ( SELECT DISTINCT bt.order_no, bt.order_ext,
        STUFF(( SELECT '; '+ bt2.LENS + '('+CAST(COUNT(bt2.lens) AS VARCHAR(4))+')' FROM BT BT2 WHERE BT2.ORDER_NO = BT.ORDER_NO AND BT2.ORDER_EXT = BT.order_ext GROUP BY BT2.lens
        FOR XML PATH('')
        ),1,1,'') LENS_PARTS
        FROM BT  )
        AS LENS_PARTS ON LENS_PARTS.order_no = bt.order_no AND LENS_PARTS.order_ext = bt.order_ext
    GROUP BY bt.order_no,
             bt.order_ext,
             o.ship_to_name,
             o.date_entered,
             o.date_shipped,
             o.user_category,
             o.ship_to_region,
             o.salesperson,
             co.promo_id,
             co.promo_level,
             FRAME_PARTS.FRAME_PARTS,
             LENS_PARTS.LENS_PARTS
    HAVING (sum(CASE WHEN bt.line_type = 'lens-plano' THEN bt.qty_ord ELSE 0 END)+
            SUM(CASE WHEN bt.line_type = 'lens-reader' THEN bt.qty_ord ELSE 0 END)+
            SUM(CASE WHEN bt.line_type = 'MIB' THEN bt.qty_ord ELSE 0 END)+
            SUM(CASE WHEN bt.line_type = 'btF1' THEN bt.qty_ord ELSE 0 END)+
            SUM(CASE WHEN bt.line_type = 'bt' THEN bt.qty_ord ELSE 0 END)) > 0
    ;

    END
    
    GRANT EXECUTE ON cvo_bt_order_log_sp  TO public





GO
GRANT EXECUTE ON  [dbo].[cvo_bt_order_log_sp] TO [public]
GO
