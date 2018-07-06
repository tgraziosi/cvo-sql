SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[cvo_slp_line_list_sp] (@terr VARCHAR(10))
AS
BEGIN

    DECLARE @loc VARCHAR(10);
    SELECT @loc = '001';

    -- EXEC dbo.cvo_slp_line_list_sp @terr = '20206' -- varchar(10)


    SELECT i.category AS Collection,
           i.part_no AS ItemCode,
           ia.field_2 AS Model,
           i.type_code AS Type,
           i.cmdty_code AS Material,
           ia.category_2 AS demographic,
           pp.price_a AS ListPrice,
           CONVERT(VARCHAR(12), ia.field_26, 101) AS ReleaseDate,
           ia.field_3 AS Color,
           LEFT(ia.field_17, 2) + '/' + ia.field_6 + '/' + ia.field_8 AS Size,
           ISNULL(ia.field_23, '') AS Sun_Lens_Color, -- 11/21/2016 - add for suns
           i.upc_code,
           i.part_no,
           qoh.qty_avl_001,
           qoh.qty_avl_slp
    FROM

    -- get the current skus

    (
    SELECT q.part_no,
           SUM(qty_avl_001) qty_avl_001,
           SUM(qty_avl_slp) qty_avl_slp
    FROM
    (
    SELECT i.part_no,
           (inv.in_stock - inv.commit_ed) qty_avl_001,
           0 qty_avl_slp
    FROM dbo.inv_master AS i WITH
        (NOLOCK)
        INNER JOIN dbo.inv_master_add AS ia WITH
        (NOLOCK)
            ON i.part_no = ia.part_no
        INNER JOIN dbo.cvo_inventory2 inv
        (NOLOCK)
            ON inv.part_no = i.part_no
               AND inv.location = @loc
    WHERE ia.field_26 < GETDATE() + 30
          AND (i.type_code IN ( 'sun', 'frame' ))
          AND (ISNULL(ia.field_28, GETDATE()) > GETDATE())
          -- tag - 082312 - exclude voided items
          AND i.void <> 'V'

    UNION ALL

    -- get the rep inventory
    SELECT inv.part_no,
           0 AS qty_avl_001,
           SUM(qty) qty_avl_slp
    FROM dbo.cvo_sc_addr_vw
        (NOLOCK) slp
        INNER JOIN dbo.lot_bin_stock inv
        (NOLOCK)
            ON inv.location = slp.location
    WHERE slp.territory_code = @terr

    GROUP BY inv.part_no
    ) q

    GROUP BY q.part_no
    ) qoh

        JOIN dbo.inv_master i
        (NOLOCK)
            ON i.part_no = qoh.part_no
        JOIN dbo.inv_master_add ia
        (NOLOCK)
            ON ia.part_no = i.part_no
        JOIN dbo.part_price AS pp
        (NOLOCK)
            ON pp.part_no = i.part_no;

END;

GRANT EXECUTE ON cvo_slp_line_list_sp TO PUBLIC;



GO
GRANT EXECUTE ON  [dbo].[cvo_slp_line_list_sp] TO [public]
GO
