SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[cvo_open_order_backorder_sp]
    @location VARCHAR(10) = '001',
    @option INT = 2,
    @incl_parts INT = 0
AS

-- 022315 - tag - add additional po info, backorders only
-- 8/3/2015 - only include line items where the part has <0 qty avl

/*
exec [cvo_open_order_backorder_sp] '001', 5, 0
*/

-- option = 1 - promos
-- option = 2 - order type
-- option = 3 - vendor
-- option = 4 - part_no


--declare @location varchar(10), @option int, @incl_parts int
--set @location = '001'
--set @option = 2
--set @incl_parts = 0



-- exec cvo_open_order_backorder_sp '001', 4, 0

SET NOCOUNT ON;

DECLARE @today DATETIME,
        @bo_hold VARCHAR(2);
SELECT @today = DATEADD(dd, DATEDIFF(dd, 0, GETDATE()), 0);
SELECT @bo_hold = 'STIH';

IF
(
    SELECT OBJECT_ID('tempdb..#type_code')
) IS NOT NULL
BEGIN
    DROP TABLE #type_code;
END;
CREATE TABLE #type_code
(
    type_code VARCHAR(10)
);
INSERT #type_code
VALUES
('frame');
INSERT #type_code
VALUES
('sun');
IF @incl_parts = 1
    INSERT #type_code
    VALUES
    ('parts');

-- select @type_code

-- open order lines

IF
(
    SELECT OBJECT_ID('tempdb..#ool')
) IS NOT NULL
BEGIN
    DROP TABLE #ool;
END;

SELECT ol.part_no,
       CASE
           WHEN @option = 1 THEN
               ISNULL(co.promo_id, '')
           WHEN @option = 2 THEN
               LEFT(o.user_category, 2)
           WHEN @option = 4 THEN
               LEFT(o.user_category, 2) -- ol.part_no
           WHEN @option = 5 THEN
                dbo.calculate_region_fn(o.ship_to_region)+o.ship_to_region+LEFT(o.user_category,2)
           ELSE
               ''
       END AS report_option,
       ol.location,
       ol.ordered - (ol.shipped + ISNULL(e.qty, 0)) open_ord_qty,
       CASE
           WHEN DATEDIFF(d, o.sch_ship_date, @today) < 0 THEN
               'Future'
           WHEN DATEDIFF(d, o.sch_ship_date, @today) = 0 THEN
               'Current'
           WHEN DATEDIFF(d, o.sch_ship_date, @today)
                BETWEEN 1 AND 21 THEN
               '1-21'
           WHEN DATEDIFF(d, o.sch_ship_date, @today)
                BETWEEN 22 AND 42 THEN
               '22-42'
           WHEN DATEDIFF(d, o.sch_ship_date, @today) > 42 THEN
               '43 +'
           ELSE
               'N/A'
       END AS DaysOverDue
INTO #ool
FROM inv_master inv (NOLOCK)
    INNER JOIN #type_code
        ON #type_code.type_code = inv.type_code
    INNER JOIN ord_list ol (NOLOCK)
        ON inv.part_no = ol.part_no
    INNER JOIN orders o (NOLOCK)
        ON o.order_no = ol.order_no
           AND o.ext = ol.order_ext
    LEFT OUTER JOIN CVO_orders_all co (NOLOCK)
        ON co.order_no = o.order_no
           AND co.ext = o.ext
    LEFT OUTER JOIN CVO_promotions p (NOLOCK)
        ON p.promo_id = co.promo_id
           AND p.promo_level = co.promo_level
    -- 3/4/15
    LEFT OUTER JOIN cvo_hard_allocated_vw e (NOLOCK)
        ON e.order_no = o.order_no
           AND e.order_ext = o.ext
           AND e.line_no = ol.line_no
           AND e.order_type = 's'
WHERE 1 = 1
      -- and inv.type_code = ('frame','sun')
      -- and ol.status in ('N','a') 
      AND
      (
          (
              o.status = 'a'
              AND (o.hold_reason = @bo_hold)
          )
          OR o.status = 'n'
      )
      AND ol.ordered > (ol.shipped + ISNULL(e.qty, 0))
      AND o.sch_ship_date < @today
      AND ol.location LIKE @location
      AND ol.part_type = 'p';


-- select * from #ool

IF
(
    SELECT OBJECT_ID('tempdb..#ool_summary')
) IS NOT NULL
BEGIN
    DROP TABLE #ool_summary;
END;

SELECT part_no,
       ISNULL(report_option, '') report_option,
       ISNULL(location, '') location,
       SUM(open_ord_qty) open_ord_qty,
       ISNULL(DaysOverDue, 0) daysoverdue
INTO #ool_summary
FROM #ool
GROUP BY part_no,
         report_option,
         location,
         daysoverdue;

CREATE NONCLUSTERED INDEX idx_ool
ON #ool_summary (
                    location ASC,
                    part_no ASC
                )
WITH (SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF)
ON [PRIMARY];

IF
(
    SELECT OBJECT_ID('tempdb..#cia')
) IS NOT NULL
BEGIN
    DROP TABLE #cia;
END;
WITH ool
AS (SELECT DISTINCT
           part_no,
           location
    FROM #ool_summary)
SELECT i.category AS brand,
       ia.field_2 AS style,
       i.type_code AS restype,
       ia.category_2 AS gender,
       i.part_no,
       ia.field_28 AS pom_date, --v1.1
                                -- 0 as qty_avl,
       cia.qty_avl AS qty_avl,
       cia.QcQty2 AS qty_rec,   -- add rdock qty 5/4/17
       ool.location,
       r.NextPO,
       r.nextpoonorder,
       r.NextPODueDate,
       r.shipvia,
       r.plrecd,
       i.vendor,
       CASE
           WHEN @option = 3 THEN
               i.vendor
           ELSE
               ''
       END AS report_option
INTO #cia
FROM ool
    INNER JOIN inv_master i (NOLOCK)
        ON ool.part_no = i.part_no
    INNER JOIN inv_master_add ia (NOLOCK)
        ON ool.part_no = ia.part_no
    -- 8/3/2015
    INNER JOIN dbo.cvo_item_avail_vw cia (NOLOCK)
        ON cia.location = ool.location
           AND cia.part_no = i.part_no
    LEFT OUTER JOIN
    (
        SELECT TOP (100) PERCENT
               i.category brand,
               ia.field_2 style,
               rr.po_no NextPO,
               rr.part_no,
               rr.quantity - rr.received nextpoonorder,
               ISNULL(rr.inhouse_date, rr.confirm_date) NextPODueDate,
               rr.location,
               shipvia = CASE
                             WHEN pp.ship_via_method = 2 THEN
                                 'BOAT'
                             WHEN pp.ship_via_method = 1 THEN
                                 'AIR'
                             ELSE
                                 ''
                         END,
               plrecd = CASE
                            WHEN pp.plrecd = 1 THEN
                                'Yes-L'
                            WHEN pa.expedite_flag = 1 THEN
                                'Yes-H'
                            ELSE
                                'No'
                        END,
               ROW_NUMBER() OVER (PARTITION BY rr.part_no,
                                               ISNULL(rr.inhouse_date, rr.confirm_date)
                                  ORDER BY rr.part_no,
                                           rr.po_no,
                                           pp.plrecd DESC,
                                           ISNULL(rr.inhouse_date, rr.confirm_date)
                                 ) AS po_rank
        FROM releases (NOLOCK) rr
            INNER JOIN pur_list (NOLOCK) pp
                ON pp.po_no = rr.po_no
                   AND pp.line = rr.po_line
            INNER JOIN purchase (NOLOCK) pa
                ON pa.po_no = rr.po_no
            INNER JOIN inv_master (NOLOCK) i
                ON i.part_no = rr.part_no
            INNER JOIN inv_master_add (NOLOCK) ia
                ON ia.part_no = rr.part_no
        WHERE rr.quantity > rr.received
              AND rr.status = 'O'
              AND rr.location = @location
              AND ISNULL(rr.inhouse_date, rr.confirm_date) =
              (
                  SELECT MIN(ISNULL(inhouse_date, confirm_date))
                  FROM releases (NOLOCK)
                  WHERE part_no = rr.part_no
                        AND location = rr.location
                        AND quantity > received
                        AND status = 'O'
              )
        ORDER BY i.category,
                 ia.field_2,
                 ISNULL(rr.inhouse_date, rr.confirm_date)
    ) AS r
        ON r.part_no = ool.part_no
           AND r.location = ool.location
           AND r.po_rank = 1;

CREATE NONCLUSTERED INDEX idx_cia
ON #cia (
            location ASC,
            part_no ASC
        )
WITH (SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF)
ON [PRIMARY];

-- select * From #cia

SELECT #cia.brand,
       #cia.style,
       #cia.restype,
       #cia.gender,
       #cia.part_no,
       #cia.pom_date,
       #cia.qty_avl,
       #cia.qty_rec,
       #cia.location,
       #cia.NextPO,
       #cia.NextPODueDate,
       #cia.nextpoonorder,
       #cia.shipvia,
       #cia.plrecd,
       #cia.vendor,
       CASE
           WHEN #cia.report_option <> '' THEN
               #cia.report_option
           ELSE
               ool.report_option
       END AS report_option,
       ool.open_ord_qty,
       ool.daysoverdue
FROM #cia
    LEFT OUTER JOIN #ool_summary ool
        ON #cia.part_no = ool.part_no
           AND #cia.location = ool.location
-- 8/3/2015
WHERE #cia.qty_avl < 0;




GO
GRANT EXECUTE ON  [dbo].[cvo_open_order_backorder_sp] TO [public]
GO
