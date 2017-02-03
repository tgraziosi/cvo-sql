SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[cvo_sunps_2017_sp]
AS
    SET NOCOUNT ON;

    DECLARE @asofdate DATETIME;
    SELECT  @asofdate = '11/1/2016';

    SELECT  sunps.customer ,
            sunps.ship_to ,
            sunps.last_sunps_activity ,
            sunps.sunps_net_sales ,
            sunps.sunps_net_qty ,
            cust_info.address_name ,
            cust_info.contact_name ,
            cust_info.contact_email ,
            cust_info.territory_code
    FROM    ( -- customer who purchased sunps in previous years
              SELECT    customer ,
                        ship_to ,
                        MAX(yyyymmdd) last_sunps_activity ,
                        SUM(anet) sunps_net_sales ,
                        SUM(qnet) sunps_net_qty
              FROM      cvo_sbm_details sbm
                        JOIN inv_master i ON i.part_no = sbm.part_no
              WHERE     promo_id = 'sunps'
                        AND i.type_code IN ( 'frame', 'sun' )
                        AND c_year >= 2012
              GROUP BY  customer ,
                        ship_to
              HAVING    MAX(yyyymmdd) < @asofdate
                        AND SUM(qnet) > 0
            ) AS sunps
            INNER JOIN ( SELECT ar.customer_code ,
                                ar.ship_to_code ,
                                ar.address_name ,
                                ar.contact_name ,
                                ar.contact_email ,
                                ar.territory_code
                         FROM   armaster ar
                                JOIN dbo.CVO_armaster_all AS car ON car.customer_code = ar.customer_code
                                                              AND car.ship_to = ar.ship_to_code
                         WHERE  car.door = 1
                                AND ar.status_type = 1
                       ) cust_info ON cust_info.customer_code = sunps.customer
                                      AND cust_info.ship_to_code = sunps.ship_to
            LEFT OUTER JOIN -- orders already placed in this cycle
            ( SELECT DISTINCT
                        o.cust_code ,
                        o.ship_to ,
                        MAX(o.date_entered) latest_order
              FROM      orders o
                        JOIN CVO_orders_all co ON co.ext = o.ext
                                                  AND co.order_no = o.order_no
              WHERE     co.promo_id = 'sunps'
                        AND o.date_entered >= @asofdate
                        AND status <> 'V'
                        AND o.who_entered <> 'backordr'
              GROUP BY  o.cust_code ,
                        o.ship_to
            ) new_orders ON new_orders.cust_code = sunps.customer
                            AND new_orders.ship_to = sunps.ship_to
    WHERE   1 = 1
            AND new_orders.cust_code IS NULL;

GO
GRANT EXECUTE ON  [dbo].[cvo_sunps_2017_sp] TO [public]
GO
