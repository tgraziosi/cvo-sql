SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- SELECT * fROM DBO.F_CVO_CALC_WEEKLY_USAGE_COLL('O','SM') WHERE PART_NO LIKE 'SMFANT%'
-- 8/1/2017 - update to include items with no orders or shipments yet

CREATE FUNCTION [dbo].[f_cvo_calc_weekly_usage_coll]
(
    @usg_option CHAR(1) = 'o',
    @coll VARCHAR(20) = NULL -- pass null to report all collections
)
RETURNS TABLE
AS
RETURN
(
    SELECT
        location,
        part_no,
        @usg_option usg_option,
        DATEADD(dd, DATEDIFF(dd, 0, GETDATE()), 0) ASofdate,
        e4_wu = CAST(SUM(   CASE
                                WHEN bucket <= 4 THEN
                                    qty_shipped
                                ELSE
                                    0
                            END
                        ) / 4 AS INT),
        e12_wu = CAST(SUM(   CASE
                                 WHEN bucket <= 12 THEN
                                     qty_shipped
                                 ELSE
                                     0
                             END
                         ) / 12 AS INT),
        e26_wu = CAST(SUM(   CASE
                                 WHEN bucket <= 26 THEN
                                     qty_shipped
                                 ELSE
                                     0
                             END
                         ) / 26 AS INT),
        e52_wu = CAST(SUM(   CASE
                                 WHEN bucket <= 52 THEN
                                     qty_shipped
                                 ELSE
                                     0
                             END
                         ) / 52 AS INT),
        subs_w4 = CAST(SUM(   CASE
                                  WHEN bucket <= 4 THEN
                                      subs_qty
                                  ELSE
                                      0
                              END
                          ) AS INT),
        subs_w12 = CAST(SUM(   CASE
                                   WHEN bucket <= 12 THEN
                                       subs_qty
                                   ELSE
                                       0
                               END
                           ) AS INT),
        promo_w4 = CAST(SUM(   CASE
                                   WHEN bucket <= 4 THEN
                                       promo_qty
                                   ELSE
                                       0
                               END
                           ) AS INT),
        promo_w12 = CAST(SUM(   CASE
                                    WHEN bucket <= 12 THEN
                                        promo_qty
                                    ELSE
                                        0
                                END
                            ) AS INT),
        rx_w4 = CAST(SUM(   CASE
                                WHEN bucket <= 4 THEN
                                    rx_qty
                                ELSE
                                    0
                            END
                        ) AS INT),
        rx_w12 = CAST(SUM(   CASE
                                 WHEN bucket <= 12 THEN
                                     rx_qty
                                 ELSE
                                     0
                             END
                         ) AS INT),
        ret_w4 = CAST(SUM(   CASE
                                 WHEN bucket <= 4 THEN
                                     ret_qty
                                 ELSE
                                     0
                             END
                         ) AS INT),
        ret_w12 = CAST(SUM(   CASE
                                  WHEN bucket <= 12 THEN
                                      ret_qty
                                  ELSE
                                      0
                              END
                          ) AS INT),
        wty_w4 = CAST(SUM(   CASE
                                 WHEN bucket <= 4 THEN
                                     wty_Qty
                                 ELSE
                                     0
                             END
                         ) AS INT),
        wty_w12 = CAST(SUM(   CASE
                                  WHEN bucket <= 12 THEN
                                      wty_Qty
                                  ELSE
                                      0
                              END
                          ) AS INT),
        gross_w4 = CAST(SUM(   CASE
                                   WHEN bucket <= 4 THEN
                                       gross_qty
                                   ELSE
                                       0
                               END
                           ) AS INT),
        gross_w12 = CAST(SUM(   CASE
                                    WHEN bucket <= 12 THEN
                                        gross_qty
                                    ELSE
                                        0
                                END
                            ) AS INT)
    FROM
    (
        SELECT
            ISNULL(ol.location, '001') location,
            part_no = i.part_no,
            subs_qty = 0, -- ISNULL( subs.quantity, 0) ,
            promo_qty = CASE
                            WHEN ISNULL(promo_id, '') > '' THEN
                                CASE
                                    WHEN type = 'i' THEN
                                        CASE
                                            WHEN @usg_option = 's' THEN
                                                ISNULL(shipped, 0)
                                            ELSE
                                                ISNULL(ordered, 0)
                                        END
                                    ELSE
                                        CASE
                                            WHEN @usg_option = 's' THEN
                                                ISNULL(cr_shipped, 0)
                                            ELSE
                                                ISNULL(cr_ordered, 0)
                                        END * -1
                                END
                            ELSE
                                0
                        END,
                          -- rx qty is based on sales only, no returns -- 032017
            rx_qty = CASE
                         WHEN ISNULL(o.user_category, 'ST') LIKE 'RX%'
                              AND type = 'i' THEN
                             CASE
                                 WHEN @usg_option = 'S' THEN
                                     ISNULL(shipped, 0)
                                 ELSE
                                     ISNULL(ordered, 0)
                             END
                         ELSE
                             0
                     END,
            ret_qty = 0,
            wty_Qty = 0,
            qty_shipped = CASE
                              WHEN type = 'i' THEN
                                  CASE
                                      WHEN @usg_option = 's' THEN
                                          ISNULL(shipped, 0)
                                      ELSE
                                          ISNULL(ordered, 0)
                                  END
                              ELSE
                                  CASE
                                      WHEN @usg_option = 's' THEN
                                          ISNULL(cr_shipped, 0)
                                      ELSE
                                          ISNULL(cr_ordered, 0)
                                  END * -1
                          END,
            gross_qty = CASE
                            WHEN type = 'i' THEN
                                CASE
                                    WHEN @usg_option = 's' THEN
                                        ISNULL(shipped, 0)
                                    ELSE
                                        ISNULL(ordered, 0)
                                END
                            ELSE
                                0
                        END,
                          -- 1/5/2017 - for credits use the date_entered not the allocation date
            bucket = CASE
                         WHEN CASE
                                  WHEN @usg_option = 'S' THEN
                                      o.date_shipped
                                  ELSE
                                      CASE
                                          WHEN o.type = 'I' THEN
                                              ISNULL(co.allocation_date, o.date_entered)
                                          ELSE
                                              o.date_entered
                                      END
                              END >= DATEADD(WEEK, -4, DATEADD(dd, DATEDIFF(dd, 0, GETDATE()), 0)) THEN
                             4
                         WHEN CASE
                                  WHEN @usg_option = 'S' THEN
                                      o.date_shipped
                                  ELSE
                                      CASE
                                          WHEN o.type = 'I' THEN
                                              ISNULL(co.allocation_date, o.date_entered)
                                          ELSE
                                              o.date_entered
                                      END
                              END >= DATEADD(WEEK, -12, DATEADD(dd, DATEDIFF(dd, 0, GETDATE()), 0)) THEN
                             12
                         WHEN CASE
                                  WHEN @usg_option = 'S' THEN
                                      o.date_shipped
                                  ELSE
                                      CASE
                                          WHEN o.type = 'I' THEN
                                              ISNULL(co.allocation_date, o.date_entered)
                                          ELSE
                                              o.date_entered
                                      END
                              END >= DATEADD(WEEK, -26, DATEADD(dd, DATEDIFF(dd, 0, GETDATE()), 0)) THEN
                             26
                         WHEN CASE
                                  WHEN @usg_option = 'S' THEN
                                      o.date_shipped
                                  ELSE
                                      CASE
                                          WHEN o.type = 'I' THEN
                                              ISNULL(co.allocation_date, o.date_entered)
                                          ELSE
                                              o.date_entered
                                      END
                              END >= DATEADD(WEEK, -52, DATEADD(dd, DATEDIFF(dd, 0, GETDATE()), 0)) THEN
                             52
                         ELSE
                             99
                     END
        FROM
            inv_master i (NOLOCK)
            LEFT OUTER JOIN ord_list ol (NOLOCK)
                ON ol.part_no = i.part_no
            LEFT OUTER JOIN orders o (NOLOCK)
                ON o.order_no = ol.order_no
                   AND o.ext = ol.order_ext
            LEFT OUTER JOIN dbo.CVO_orders_all co (NOLOCK)
                ON co.ext = o.ext
                   AND co.order_no = o.order_no
        WHERE
            i.category = ISNULL(@coll, i.category)
            AND 'V' <> ISNULL(o.status, 'X')
            -- AND o.date_entered >= DATEADD(WEEK, -52, DATEADD(dd, DATEDIFF(dd, 0, GETDATE()), 0))
            AND (CASE
                     WHEN @usg_option = 's' THEN
                         ISNULL(o.date_shipped, DATEADD(dd, DATEDIFF(dd, 0, GETDATE()), 0))
                     ELSE
                         ISNULL(co.allocation_date, ISNULL(o.date_entered, DATEADD(dd, DATEDIFF(dd, 0, GETDATE()), 0)))
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
                                                           WHEN @usg_option = 's' THEN
                                                               ''
                                                           ELSE
                                                               'BACKORDR'
                                                       END
                                                      )
        UNION ALL
        -- old part number
        SELECT
            t.location,
            part_no = LTRIM(RTRIM(SUBSTRING(
                                               data,
                                               CHARINDEX(': ', data, 1) + 2,
                                               CHARINDEX('replaced', data, 1) - CHARINDEX(':', data, 1) - 2
                                           )
                                 )
                           ),
            subs_qty = -CAST(quantity AS DECIMAL(20, 8)),
            promo_qty = 0,
            rx_qty = 0,
            ret_Qty = 0,
            wty_qty = 0,
            qty_shipped = 0,
            gross_qty = 0,
            bucket = CASE
                         WHEN t.tran_date >= DATEADD(WEEK, -4, DATEADD(dd, DATEDIFF(dd, 0, GETDATE()), 0)) THEN
                             4
                         WHEN t.tran_date >= DATEADD(WEEK, -12, DATEADD(dd, DATEDIFF(dd, 0, GETDATE()), 0)) THEN
                             12
                         WHEN t.tran_date >= DATEADD(WEEK, -26, DATEADD(dd, DATEDIFF(dd, 0, GETDATE()), 0)) THEN
                             26
                         WHEN t.tran_date >= DATEADD(WEEK, -52, DATEADD(dd, DATEDIFF(dd, 0, GETDATE()), 0)) THEN
                             52
                         ELSE
                             99
                     END
        FROM
            inv_master i (NOLOCK)
            JOIN tdc_log (NOLOCK) t
                ON t.part_no = i.part_no
        --INNER JOIN cvo_orders_all co ON co.order_no = t.tran_no AND co.ext = t.tran_ext
        --INNER JOIN orders o ON o.order_no = co.order_no AND o.ext = co.ext
        WHERE
            t.trans = 'SUBSTITUTE PROCESSING'
            AND t.tran_date >= DATEADD(WEEK, -52, DATEADD(dd, DATEDIFF(dd, 0, GETDATE()), 0))
            AND i.category = ISNULL(@coll, i.category)
        UNION ALL
        -- new part number
        SELECT
            t.location,
            i.part_no,
            subs_qty = CAST(quantity AS DECIMAL(20, 8)),
            promo_qty = 0,
            rx_qty = 0,
            ret_qty = 0,
            wty_qty = 0,
            qty_shipped = 0,
            gross_qty = 0,
            bucket = CASE
                         WHEN t.tran_date >= DATEADD(WEEK, -4, DATEADD(dd, DATEDIFF(dd, 0, GETDATE()), 0)) THEN
                             4
                         WHEN t.tran_date >= DATEADD(WEEK, -12, DATEADD(dd, DATEDIFF(dd, 0, GETDATE()), 0)) THEN
                             12
                         WHEN t.tran_date >= DATEADD(WEEK, -26, DATEADD(dd, DATEDIFF(dd, 0, GETDATE()), 0)) THEN
                             26
                         WHEN t.tran_date >= DATEADD(WEEK, -52, DATEADD(dd, DATEDIFF(dd, 0, GETDATE()), 0)) THEN
                             52
                         ELSE
                             99
                     END
        FROM
            inv_master i (NOLOCK)
            JOIN tdc_log (NOLOCK) t
                ON t.part_no = i.part_no
        --INNER JOIN cvo_orders_all co ON co.order_no = t.tran_no AND co.ext = t.tran_ext
        --INNER JOIN orders o ON o.order_no = co.order_no AND o.ext = co.ext
        WHERE
            t.trans = 'SUBSTITUTE PROCESSING'
            AND t.tran_date >= DATEADD(WEEK, -52, DATEADD(dd, DATEDIFF(dd, 0, GETDATE()), 0))
            AND i.category = ISNULL(@coll, i.category)
        UNION ALL
        -- 12/28/2016 FOR SbS
        SELECT
            s.location,
            s.part_no,
            subs_qty = 0,
            promo_qty = 0,
            rx_qty = 0,
            ret_qty = SUM(   CASE
                                 WHEN s.return_code <> 'EXC' THEN
                                     s.qreturns
                                 ELSE
                                     0
                             END
                         ),
            wty_qty = SUM(   CASE
                                 WHEN s.return_code = 'WTY' THEN
                                     s.qreturns
                                 ELSE
                                     0
                             END
                         ),
            qty_shipped = 0,
            gross_qty = 0,
            bucket = CASE
                         WHEN s.yyyymmdd >= DATEADD(WEEK, -4, DATEADD(dd, DATEDIFF(dd, 0, GETDATE()), 0)) THEN
                             4
                         WHEN s.yyyymmdd >= DATEADD(WEEK, -12, DATEADD(dd, DATEDIFF(dd, 0, GETDATE()), 0)) THEN
                             12
                         ELSE
                             99
                     END
        FROM
            inv_master i
            JOIN cvo_sbm_details s
                ON s.part_no = i.part_no
        WHERE
            i.category = ISNULL(@coll, i.category)
            AND s.yyyymmdd >= DATEADD(WEEK, -12, DATEADD(dd, DATEDIFF(dd, 0, GETDATE()), 0))
        GROUP BY
            CASE
                WHEN s.yyyymmdd >= DATEADD(WEEK, -4, DATEADD(dd, DATEDIFF(dd, 0, GETDATE()), 0)) THEN
                    4
                WHEN s.yyyymmdd >= DATEADD(WEEK, -12, DATEADD(dd, DATEDIFF(dd, 0, GETDATE()), 0)) THEN
                    12
                ELSE
                    99
            END,
            s.location,
            s.part_no
    ) usage
    WHERE
        usage.location IS NOT NULL
        AND usage.part_no IS NOT NULL
    GROUP BY
        usage.location, usage.part_no
)
;







GO
