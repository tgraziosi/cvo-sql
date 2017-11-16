SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[cvo_ST_Activity_Tracker_sp]
(
    @sdate DATETIME = NULL,
    @edate DATETIME = NULL
)
AS

SET NOCOUNT ON;

SET ANSI_WARNINGS OFF;

BEGIN

    DECLARE @sdately DATETIME,
            @edately DATETIME;

    IF @sdate IS NULL
       OR @edate IS NULL
        SELECT @sdate = '11/1/2017',
               @edate = '2/1/2018';

    SELECT @sdately = DATEADD(YEAR, -1, @sdate),
           @edately = DATEADD(YEAR, -1, @edate);

    SELECT t.region,
           t.territory_code,
           arm.customer_code,
           arm.ship_to_code,
           arm.address_name,
           arm.city,
           arm.state,
           arm.postal_code,
           arm.contact_name,
           arm.contact_email,
           summary.YYear,
           summary.NetSales,
           summary.Num_ST_Orders
    FROM armaster arm (NOLOCK)
        JOIN
        (
            SELECT a.territory_code,
                   dbo.calculate_region_fn(a.territory_code) region
            FROM dbo.arterr AS a (NOLOCK)
        ) t
            ON t.territory_code = arm.territory_code
        LEFT OUTER JOIN
        (
            SELECT ar.customer_code,
                   CASE
                       WHEN car.door = 1 THEN
                           ar.ship_to_code
                       ELSE
                           ''
                   END ship_to_code,
                   facts.YYear,
                   SUM(ISNULL(facts.NetSales, 0)) NetSales,
                   SUM(ISNULL(facts.num_st_orders, 0)) Num_ST_Orders
            FROM armaster ar (NOLOCK)
                JOIN CVO_armaster_all car (NOLOCK)
                    ON car.customer_code = ar.customer_code
                       AND car.ship_to = ar.ship_to_code
                LEFT OUTER JOIN
                (
                    SELECT ar.customer_code,
                           ar.ship_to_code,
                           ar.YYear,
                           s.NetSales,
                           o.num_st_orders
                    FROM
                    (
                        SELECT ar.customer_code,
                               ar.ship_to_code,
                               yy.YYear
                        FROM armaster ar (NOLOCK)
                            CROSS JOIN
                            (SELECT 'TY' YYear UNION SELECT 'LY') yy
                    ) ar
                        LEFT OUTER JOIN
                        (
                            -- Net Sales
                            SELECT sd.customer,
                                   sd.ship_to,
                                   CASE
                                       WHEN yyyymmdd
                                            BETWEEN @sdate AND @edate THEN
                                           'TY'
                                       ELSE
                                           'LY'
                                   END yyear,
                                   SUM(ISNULL(anet, 0)) NetSales
                            FROM inv_master i (NOLOCK)
                                JOIN dbo.cvo_sbm_details AS sd (NOLOCK)
                                    ON sd.part_no = i.part_no
                            WHERE (
                                      yyyymmdd
                                  BETWEEN @sdate AND @edate
                                      OR yyyymmdd
                                  BETWEEN @sdately AND @edately
                                  )
                                  AND i.type_code IN ( 'frame', 'sun', 'parts' )
                            GROUP BY CASE
                                         WHEN yyyymmdd
                                              BETWEEN @sdate AND @edate THEN
                                             'TY'
                                         ELSE
                                             'LY'
                                     END,
                                     sd.customer,
                                     sd.ship_to
                        ) s
                            ON s.customer = ar.customer_code
                               AND s.ship_to = ar.ship_to_code
                               AND s.yyear = ar.YYear

                        -- st order counts
                        LEFT OUTER JOIN
                        (
                            SELECT o.cust_code,
                                   o.ship_to,
                                   CASE
                                       WHEN o.date_entered
                                            BETWEEN @sdate AND @edate THEN
                                           'TY'
                                       ELSE
                                           'LY'
                                   END YYear,
                                   COUNT(DISTINCT o.order_no) num_st_orders
                            FROM orders o (NOLOCK)
                                JOIN
                                (
                                    SELECT order_no,
                                           order_ext,
                                           SUM(ordered) ordered
                                    FROM ord_list ol (NOLOCK)
                                        JOIN inv_master i (NOLOCK)
                                            ON i.part_no = ol.part_no
                                    WHERE i.type_code IN ( 'frame', 'sun' )
                                    GROUP BY ol.order_no,
                                             ol.order_ext
                                ) ol
                                    ON ol.order_no = o.order_no
                                       AND ol.order_ext = o.ext
                            WHERE 'st' = LEFT(o.user_category, 2)
                                  AND 'rb' <> RIGHT(o.user_category, 2)
                                  AND o.status = 't'
                                  AND o.type = 'i'
                                  AND o.who_entered <> 'backordr'
                                  AND ol.ordered >= 5
                                  AND
                                  (
                                      o.date_entered
                                  BETWEEN @sdate AND @edate
                                      OR o.date_entered
                                  BETWEEN @sdately AND @edately
                                  )
                            GROUP BY o.cust_code,
                                     o.ship_to,
                                     CASE
                                         WHEN o.date_entered
                                              BETWEEN @sdate AND @edate THEN
                                             'TY'
                                         ELSE
                                             'LY'
                                     END
                        ) o
                            ON o.cust_code = ar.customer_code
                               AND o.ship_to = ar.ship_to_code
                               AND o.YYear = ar.YYear
                ) facts
                    ON facts.customer_code = ar.customer_code
                       AND facts.ship_to_code = ar.ship_to_code
            GROUP BY ar.customer_code,
                     CASE
                         WHEN car.door = 1 THEN
                             ar.ship_to_code
                         ELSE
                             ''
                     END,
                     facts.YYear
        ) summary
            ON summary.customer_code = arm.customer_code
               AND summary.ship_to_code = arm.ship_to_code
    WHERE arm.status_type = 1 -- currently active customers only
    ;

END;

GRANT EXECUTE ON dbo.cvo_ST_Activity_Tracker_sp TO PUBLIC;
GO
GRANT EXECUTE ON  [dbo].[cvo_ST_Activity_Tracker_sp] TO [public]
GO
