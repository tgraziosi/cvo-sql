SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- SELECT * fROM DBO.F_CVO_CALC_WEEKLY_USAGE_custtype('O','C','bcbg','Key Account') WHERE PART_NO LIKE 'bcb985%' and location = 'visionwork'
-- 8/1/2017 - update to include items with no orders or shipments yet
-- 8/31/2017 - use 

CREATE FUNCTION [dbo].[f_cvo_calc_weekly_usage_custtype]
    (
        @usg_option  CHAR(1) = 'o',
        @type_option CHAR(1) = 'C',      -- C or T - Collection or Type
        @type        VARCHAR(20) = NULL, -- pass null to report all type_codes or collections
        @custtype    VARCHAR(40) = NULL  -- pass null to report all customer types
    )
RETURNS TABLE
AS
    RETURN
        (
            SELECT
                custtype,
                part_no,
                @usg_option                                usg_option,
                DATEADD(dd, DATEDIFF(dd, 0, GETDATE()), 0) ASofdate,
                CAST(SUM(   CASE
                                WHEN bucket <= 4
                                    THEN
                                    qty_shipped
                                ELSE
                                    0
                            END
                        ) / 4 AS INT)                      e4_wu,
                CAST(SUM(   CASE
                                WHEN bucket <= 12
                                    THEN
                                    qty_shipped
                                ELSE
                                    0
                            END
                        ) / 12 AS INT)                     e12_wu,
                CAST(SUM(   CASE
                                WHEN bucket <= 26
                                    THEN
                                    qty_shipped
                                ELSE
                                    0
                            END
                        ) / 26 AS INT)                     e26_wu,
                CAST(SUM(   CASE
                                WHEN bucket <= 52
                                    THEN
                                    qty_shipped
                                ELSE
                                    0
                            END
                        ) / 52 AS INT)                     e52_wu,
                CAST(SUM(   CASE
                                WHEN bucket <= 4
                                    THEN
                                    subs_qty
                                ELSE
                                    0
                            END
                        ) AS INT)                          subs_w4,
                CAST(SUM(   CASE
                                WHEN bucket <= 12
                                    THEN
                                    subs_qty
                                ELSE
                                    0
                            END
                        ) AS INT)                          subs_w12,
                CAST(SUM(   CASE
                                WHEN bucket <= 4
                                    THEN
                                    promo_qty
                                ELSE
                                    0
                            END
                        ) AS INT)                          promo_w4,
                CAST(SUM(   CASE
                                WHEN bucket <= 12
                                    THEN
                                    promo_qty
                                ELSE
                                    0
                            END
                        ) AS INT)                          promo_w12,
                CAST(SUM(   CASE
                                WHEN bucket <= 4
                                    THEN
                                    rx_qty
                                ELSE
                                    0
                            END
                        ) AS INT)                          rx_w4,
                CAST(SUM(   CASE
                                WHEN bucket <= 12
                                    THEN
                                    rx_qty
                                ELSE
                                    0
                            END
                        ) AS INT)                          rx_w12,
                CAST(SUM(   CASE
                                WHEN bucket <= 4
                                    THEN
                                    ret_qty
                                ELSE
                                    0
                            END
                        ) AS INT)                          ret_w4,
                CAST(SUM(   CASE
                                WHEN bucket <= 12
                                    THEN
                                    ret_qty
                                ELSE
                                    0
                            END
                        ) AS INT)                          ret_w12,
                CAST(SUM(   CASE
                                WHEN bucket <= 4
                                    THEN
                                    wty_Qty
                                ELSE
                                    0
                            END
                        ) AS INT)                          wty_w4,
                CAST(SUM(   CASE
                                WHEN bucket <= 12
                                    THEN
                                    wty_Qty
                                ELSE
                                    0
                            END
                        ) AS INT)                          wty_w12,
                CAST(SUM(   CASE
                                WHEN bucket <= 4
                                    THEN
                                    gross_qty
                                ELSE
                                    0
                            END
                        ) AS INT)                          gross_w4,
                CAST(SUM(   CASE
                                WHEN bucket <= 12
                                    THEN
                                    gross_qty
                                ELSE
                                    0
                            END
                        ) AS INT)                          gross_w12
            FROM
                (
                    SELECT
                            la.custtype custtype,
                            part_no     = i.part_no,
                            subs_qty    = 0, -- ISNULL( subs.quantity, 0) ,
                            promo_qty   = CASE
                                              WHEN ISNULL(promo_id, '') > ''
                                                  THEN
                                                  CASE
                                                      WHEN type = 'i'
                                                          THEN
                                                          CASE
                                                              WHEN @usg_option = 's'
                                                                  THEN
                                                                  ISNULL(shipped, 0)
                                                              ELSE
                                                                  ISNULL(ordered, 0)
                                                          END
                                                      ELSE
                                                          CASE
                                                              WHEN @usg_option = 's'
                                                                  THEN
                                                                  ISNULL(cr_shipped, 0)
                                                              ELSE
                                                                  ISNULL(cr_ordered, 0)
                                                          END * -1
                                                  END
                                              ELSE
                                                  0
                                          END,
                                             -- rx qty is based on sales only, no returns -- 032017
                            rx_qty      = CASE
                                              WHEN ISNULL(o.user_category, 'ST') LIKE 'RX%'
                                                   AND type = 'i'
                                                  THEN
                                                  CASE
                                                      WHEN @usg_option = 'S'
                                                          THEN
                                                          ISNULL(shipped, 0)
                                                      ELSE
                                                          ISNULL(ordered, 0)
                                                  END
                                              ELSE
                                                  0
                                          END,
                            ret_qty     = 0,
                            wty_Qty     = 0,
                            qty_shipped = CASE
                                              WHEN type = 'i'
                                                  THEN
                                                  CASE
                                                      WHEN @usg_option = 's'
                                                          THEN
                                                          ISNULL(shipped, 0)
                                                      ELSE
                                                          ISNULL(ordered, 0)
                                                  END
                                              ELSE
                                                  CASE
                                                      WHEN @usg_option = 's'
                                                          THEN
                                                          ISNULL(cr_shipped, 0)
                                                      ELSE
                                                          ISNULL(cr_ordered, 0)
                                                  END * -1
                                          END,
                            gross_qty   = CASE
                                              WHEN type = 'i'
                                                  THEN
                                                  CASE
                                                      WHEN @usg_option = 's'
                                                          THEN
                                                          ISNULL(shipped, 0)
                                                      ELSE
                                                          ISNULL(ordered, 0)
                                                  END
                                              ELSE
                                                  0
                                          END,
                                             -- 1/5/2017 - for credits use the date_entered not the allocation date
                            bucket      = CASE
                                              WHEN CASE
                                                       WHEN @usg_option = 'S'
                                                           THEN
                                                           o.date_shipped
                                                       ELSE
                                                           CASE
                                                               WHEN o.type = 'I'
                                                                   THEN
                                                                   ISNULL(co.allocation_date, o.date_entered)
                                                               ELSE
                                                                   o.date_entered
                                                           END
                                                   END >= DATEADD(WEEK, -4, DATEADD(dd, DATEDIFF(dd, 0, GETDATE()), 0))
                                                  THEN
                                                  4
                                              WHEN CASE
                                                       WHEN @usg_option = 'S'
                                                           THEN
                                                           o.date_shipped
                                                       ELSE
                                                           CASE
                                                               WHEN o.type = 'I'
                                                                   THEN
                                                                   ISNULL(co.allocation_date, o.date_entered)
                                                               ELSE
                                                                   o.date_entered
                                                           END
                                                   END >= DATEADD(WEEK, -12, DATEADD(dd, DATEDIFF(dd, 0, GETDATE()), 0))
                                                  THEN
                                                  12
                                              WHEN CASE
                                                       WHEN @usg_option = 'S'
                                                           THEN
                                                           o.date_shipped
                                                       ELSE
                                                           CASE
                                                               WHEN o.type = 'I'
                                                                   THEN
                                                                   ISNULL(co.allocation_date, o.date_entered)
                                                               ELSE
                                                                   o.date_entered
                                                           END
                                                   END >= DATEADD(WEEK, -26, DATEADD(dd, DATEDIFF(dd, 0, GETDATE()), 0))
                                                  THEN
                                                  26
                                              WHEN CASE
                                                       WHEN @usg_option = 'S'
                                                           THEN
                                                           o.date_shipped
                                                       ELSE
                                                           CASE
                                                               WHEN o.type = 'I'
                                                                   THEN
                                                                   ISNULL(co.allocation_date, o.date_entered)
                                                               ELSE
                                                                   o.date_entered
                                                           END
                                                   END >= DATEADD(WEEK, -52, DATEADD(dd, DATEDIFF(dd, 0, GETDATE()), 0))
                                                  THEN
                                                  52
                                              ELSE
                                                  99
                                          END
                    FROM
                            (
                                SELECT DISTINCT
                                       addr_sort1 custtype
                                FROM
                                       armaster (NOLOCK)
                                WHERE
                                       addr_sort1 = CASE
                                                        WHEN @custtype IS NULL
                                                            THEN
                                                            addr_sort1
                                                        ELSE
                                                            @custtype
                                                    END
                            )                  la
                        JOIN
                            armaster           ar (NOLOCK)
                                ON ar.addr_sort1 = la.custtype
                        LEFT OUTER JOIN
                            orders             o (NOLOCK)
                                ON o.cust_code = ar.customer_code
                                   AND o.ship_to = ar.ship_to_code
                        LEFT OUTER JOIN
                            dbo.CVO_orders_all co (NOLOCK)
                                ON co.ext = o.ext
                                   AND co.order_no = o.order_no
                        LEFT OUTER JOIN
                            ord_list           ol (NOLOCK)
                                ON ol.order_no = o.order_no
                                   AND ol.order_ext = o.ext
                        JOIN
                            inv_master         i (NOLOCK)
                                ON i.part_no = ol.part_no
                        JOIN
                            dbo.inv_list       AS il (NOLOCK)
                                ON il.location = ol.location
                                   AND il.part_no = ol.part_no
                    WHERE
                            (
                                (
                                    @type_option = 't'
                                    AND i.type_code = ISNULL(@type, i.type_code)
                                )
                                OR
                                    (
                                        @type_option = 'c'
                                        AND i.category = ISNULL(@type, i.category)
                                    )
                            )
                            AND 'V' <> ISNULL(o.status, 'Z')
                            AND
                                (
                                    (CASE
                                         WHEN @usg_option = 's'
                                             THEN
                                             ISNULL(o.date_shipped, DATEADD(dd, DATEDIFF(dd, 0, GETDATE()), 0))
                                         ELSE
                                             ISNULL(
                                                       co.allocation_date,
                                                       ISNULL(o.date_entered, DATEADD(dd, DATEDIFF(dd, 0, GETDATE()), 0))
                                                   )
                                     END
                                    )
                            BETWEEN DATEADD(WEEK, -52, DATEADD(dd, DATEDIFF(dd, 0, GETDATE()), 0)) AND DATEADD(
                                                                                                                  dd,
                                                                                                                  DATEDIFF(
                                                                                                                              dd,
                                                                                                                              0,
                                                                                                                              GETDATE()
                                                                                                                          ),
                                                                                                                  0
                                                                                                              )
                                    AND ISNULL(o.who_entered, 'No Orders') <> (CASE
                                                                                   WHEN @usg_option = 's'
                                                                                       THEN
                                                                                       ''
                                                                                   ELSE
                                                                                       'BACKORDR'
                                                                               END
                                                                              )
                                )
                    UNION ALL
                    -- old part number
                    SELECT
                            ar.addr_sort1 custtype,
                            part_no       = LTRIM(RTRIM(SUBSTRING(
                                                                     data, CHARINDEX(': ', data, 1) + 2,
                                                                     CHARINDEX('replaced', data, 1) - CHARINDEX(':', data, 1) - 2
                                                                 )
                                                       )
                                                 ),
                            subs_qty      = -CAST(quantity AS DECIMAL(20, 8)),
                            promo_qty     = 0,
                            rx_qty        = 0,
                            ret_Qty       = 0,
                            wty_qty       = 0,
                            qty_shipped   = 0,
                            gross_qty     = 0,
                            bucket        = CASE
                                                WHEN t.tran_date >= DATEADD(WEEK, -4, DATEADD(dd, DATEDIFF(dd, 0, GETDATE()), 0))
                                                    THEN
                                                    4
                                                WHEN t.tran_date >= DATEADD(WEEK, -12, DATEADD(dd, DATEDIFF(dd, 0, GETDATE()), 0))
                                                    THEN
                                                    12
                                                WHEN t.tran_date >= DATEADD(WEEK, -26, DATEADD(dd, DATEDIFF(dd, 0, GETDATE()), 0))
                                                    THEN
                                                    26
                                                WHEN t.tran_date >= DATEADD(WEEK, -52, DATEADD(dd, DATEDIFF(dd, 0, GETDATE()), 0))
                                                    THEN
                                                    52
                                                ELSE
                                                    99
                                            END
                    FROM
                            inv_master       i (NOLOCK)
                        JOIN
                            tdc_log (NOLOCK) t
                                ON t.part_no = i.part_no
                        INNER JOIN
                            CVO_orders_all   co (NOLOCK)
                                ON co.order_no = t.tran_no
                                   AND co.ext = t.tran_ext
                        INNER JOIN
                            orders           o (NOLOCK)
                                ON o.order_no = co.order_no
                                   AND o.ext = co.ext
                        JOIN
                            armaster         ar (NOLOCK)
                                ON ar.customer_code = o.cust_code
                                   AND ar.ship_to_code = o.ship_to
                        JOIN
                            (
                                SELECT DISTINCT
                                       addr_sort1 custtype
                                FROM
                                       armaster (NOLOCK)
                                WHERE
                                       addr_sort1 = CASE
                                                        WHEN @custtype IS NULL
                                                            THEN
                                                            addr_sort1
                                                        ELSE
                                                            @custtype
                                                    END
                            )                la
                                ON la.custtype = ar.addr_sort1
                    WHERE
                            t.trans = 'SUBSTITUTE PROCESSING'
                            AND t.tran_date >= DATEADD(WEEK, -52, DATEADD(dd, DATEDIFF(dd, 0, GETDATE()), 0))
                            AND
                                (
                                    (
                                        @type_option = 't'
                                        AND i.type_code = ISNULL(@type, i.type_code)
                                    )
                                    OR
                                        (
                                            @type_option = 'c'
                                            AND i.category = ISNULL(@type, i.category)
                                        )
                                )
                    UNION ALL
                    -- new part number
                    SELECT
                            ar.addr_sort1 custtype,
                            i.part_no,
                            subs_qty      = CAST(quantity AS DECIMAL(20, 8)),
                            promo_qty     = 0,
                            rx_qty        = 0,
                            ret_qty       = 0,
                            wty_qty       = 0,
                            qty_shipped   = 0,
                            gross_qty     = 0,
                            bucket        = CASE
                                                WHEN t.tran_date >= DATEADD(WEEK, -4, DATEADD(dd, DATEDIFF(dd, 0, GETDATE()), 0))
                                                    THEN
                                                    4
                                                WHEN t.tran_date >= DATEADD(WEEK, -12, DATEADD(dd, DATEDIFF(dd, 0, GETDATE()), 0))
                                                    THEN
                                                    12
                                                WHEN t.tran_date >= DATEADD(WEEK, -26, DATEADD(dd, DATEDIFF(dd, 0, GETDATE()), 0))
                                                    THEN
                                                    26
                                                WHEN t.tran_date >= DATEADD(WEEK, -52, DATEADD(dd, DATEDIFF(dd, 0, GETDATE()), 0))
                                                    THEN
                                                    52
                                                ELSE
                                                    99
                                            END
                    FROM
                            inv_master       i (NOLOCK)
                        JOIN
                            tdc_log (NOLOCK) t
                                ON t.part_no = i.part_no
                        INNER JOIN
                            CVO_orders_all   co (NOLOCK)
                                ON co.order_no = t.tran_no
                                   AND co.ext = t.tran_ext
                        INNER JOIN
                            orders           o (NOLOCK)
                                ON o.order_no = co.order_no
                                   AND o.ext = co.ext
                        JOIN
                            armaster         ar (NOLOCK)
                                ON ar.customer_code = o.cust_code
                                   AND ar.ship_to_code = o.ship_to
                        JOIN
                            (
                                SELECT DISTINCT
                                       addr_sort1 custtype
                                FROM
                                       armaster (NOLOCK)
                                WHERE
                                       addr_sort1 = CASE
                                                        WHEN @custtype IS NULL
                                                            THEN
                                                            addr_sort1
                                                        ELSE
                                                            @custtype
                                                    END
                            )                la
                                ON la.custtype = ar.addr_sort1
                    WHERE
                            t.trans = 'SUBSTITUTE PROCESSING'
                            AND t.tran_date >= DATEADD(WEEK, -52, DATEADD(dd, DATEDIFF(dd, 0, GETDATE()), 0))
                            AND
                                (
                                    (
                                        @type_option = 't'
                                        AND i.type_code = ISNULL(@type, i.type_code)
                                    )
                                    OR
                                        (
                                            @type_option = 'c'
                                            AND i.category = ISNULL(@type, i.category)
                                        )
                                )
                    UNION ALL
                    -- 12/28/2016 FOR SbS
                    SELECT
                            ar.addr_sort1 custtype,
                            s.part_no,
                            subs_qty      = 0,
                            promo_qty     = 0,
                            rx_qty        = 0,
                            ret_qty       = SUM(   CASE
                                                       WHEN s.return_code <> 'EXC'
                                                           THEN
                                                           s.qreturns
                                                       ELSE
                                                           0
                                                   END
                                               ),
                            wty_qty       = SUM(   CASE
                                                       WHEN s.return_code = 'WTY'
                                                           THEN
                                                           s.qreturns
                                                       ELSE
                                                           0
                                                   END
                                               ),
                            qty_shipped   = 0,
                            gross_qty     = 0,
                            bucket        = CASE
                                                WHEN s.yyyymmdd >= DATEADD(WEEK, -4, DATEADD(dd, DATEDIFF(dd, 0, GETDATE()), 0))
                                                    THEN
                                                    4
                                                WHEN s.yyyymmdd >= DATEADD(WEEK, -12, DATEADD(dd, DATEDIFF(dd, 0, GETDATE()), 0))
                                                    THEN
                                                    12
                                                ELSE
                                                    99
                                            END
                    FROM
                            inv_master      i (NOLOCK)
                        JOIN
                            cvo_sbm_details s (NOLOCK)
                                ON s.part_no = i.part_no
                        JOIN
                            armaster        ar
                                ON ar.customer_code = s.customer
                                   AND ar.ship_to_code = s.ship_to
                        JOIN
                            (
                                SELECT DISTINCT
                                       addr_sort1 custtype
                                FROM
                                       armaster (NOLOCK)
                                WHERE
                                       addr_sort1 = CASE
                                                        WHEN @custtype IS NULL
                                                            THEN
                                                            addr_sort1
                                                        ELSE
                                                            @custtype
                                                    END
                            )               la
                                ON la.custtype = ar.addr_sort1
                    WHERE
                            (
                                (
                                    @type_option = 't'
                                    AND i.type_code = ISNULL(@type, i.type_code)
                                )
                                OR
                                    (
                                        @type_option = 'c'
                                        AND i.category = ISNULL(@type, i.category)
                                    )
                            )
                            AND s.yyyymmdd >= DATEADD(WEEK, -12, DATEADD(dd, DATEDIFF(dd, 0, GETDATE()), 0))
                    GROUP BY
                            CASE
                                WHEN s.yyyymmdd >= DATEADD(WEEK, -4, DATEADD(dd, DATEDIFF(dd, 0, GETDATE()), 0))
                                    THEN
                                    4
                                WHEN s.yyyymmdd >= DATEADD(WEEK, -12, DATEADD(dd, DATEDIFF(dd, 0, GETDATE()), 0))
                                    THEN
                                    12
                                ELSE
                                    99
                            END,
                            ar.addr_sort1,
                            s.part_no
                ) usage
            WHERE
                usage.custtype IS NOT NULL
                AND usage.part_no IS NOT NULL
            GROUP BY
                usage.custtype,
                usage.part_no
        );
GO
