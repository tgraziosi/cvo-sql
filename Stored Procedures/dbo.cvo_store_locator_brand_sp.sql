SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[cvo_store_locator_brand_sp]
AS
BEGIN


    DECLARE @start DATETIME,
            @end DATETIME;
    SELECT @start = BeginDate,
           @end = EndDate
    FROM dbo.cvo_date_range_vw AS drv
    WHERE Period = 'rolling 12 ty';

    CREATE TABLE #cust
    (
        collection VARCHAR(12),
        customer_code VARCHAR(8),
        ship_to_code VARCHAR(8),
        address_name VARCHAR(40),
        addr2 VARCHAR(40),
        addr3 VARCHAR(40),
        addr4 VARCHAR(40),
        addr5 VARCHAR(40),
        city VARCHAR(40),
        state VARCHAR(40),
        postal_code VARCHAR(15),
        country_code VARCHAR(3),
        contact_phone VARCHAR(30)
    );

    INSERT INTO #cust
    (
        collection,
        customer_code,
        ship_to_code,
        address_name,
        addr2,
        addr3,
        addr4,
        addr5,
        city,
        state,
        postal_code,
        country_code,
        contact_phone
    )
    SELECT sales.collection,
           cust.customer_code,
           cust.ship_to_code,
           cust.address_name,
           cust.addr2,
           cust.addr3,
           cust.addr4,
           cust.addr5,
           cust.city,
           cust.state,
           cust.postal_code,
           cust.country_code,
           cust.contact_phone
    FROM
    (
        SELECT t.territory_code
        FROM arterr t (NOLOCK)
        WHERE dbo.calculate_region_fn(t.territory_code) < '800'
    ) terr
        JOIN armaster cust (NOLOCK)
            ON cust.territory_code = terr.territory_code
               AND cust.status_type = 1
               AND cust.addr_sort1 IN ( 'Customer', 'Intl Retailer' )
        JOIN CVO_armaster_all car (NOLOCK)
            ON car.customer_code = cust.customer_code
               AND car.ship_to = cust.ship_to_code
               AND car.door = 1
        JOIN
        (
            SELECT DISTINCT
                   sbm.customer,
                   CASE
                       WHEN car.door = 1 THEN
                           sbm.ship_to
                       ELSE
                           ''
                   END AS ship_to,
                   CASE
                       WHEN i.category = 'op'
                            AND pa.part_no IS NOT NULL THEN
                           pa.attribute
                       ELSE
                           i.category
                   END collection
            FROM inv_master i (NOLOCK)
                JOIN cvo_sbm_details sbm (NOLOCK)
                    ON sbm.part_no = i.part_no
                JOIN CVO_armaster_all car (NOLOCK)
                    ON car.customer_code = sbm.customer
                       AND car.ship_to = sbm.ship_to
                JOIN armaster ar (NOLOCK)
                    ON ar.customer_code = sbm.customer
                       AND ar.ship_to_code = sbm.ship_to
                LEFT JOIN dbo.cvo_part_attributes AS pa
                    ON pa.part_no = i.part_no
                       AND pa.attribute = 'Pogocam'
            WHERE i.type_code IN ( 'frame', 'sun' )
                  AND i.void = 'n'
                  AND sbm.yyyymmdd > DATEADD(YEAR, -1, GETDATE())
                  AND ar.status_type = 1 -- active
                  AND ar.address_type <> 9
            GROUP BY sbm.customer,
                     CASE
                         WHEN car.door = 1 THEN
                             sbm.ship_to
                         ELSE
                             ''
                     END,
                     CASE
                         WHEN i.category = 'op'
                              AND pa.part_no IS NOT NULL THEN
                             pa.attribute
                         ELSE
                             i.category
                     END
            HAVING SUM(qnet) > 4
            UNION ALL
            SELECT DISTINCT
                   sd.customer,
                   CASE
                       WHEN car.door = 1 THEN
                           car.ship_to
                       ELSE
                           ''
                   END AS ship_to,
                   'Kids Premier' category
            FROM dbo.cvo_sbm_details AS sd (NOLOCK)
                JOIN armaster ar (NOLOCK)
                    ON ar.customer_code = sd.customer
                       AND ar.ship_to_code = sd.ship_to
                JOIN dbo.CVO_armaster_all AS car (NOLOCK)
                    ON car.customer_code = ar.customer_code
                       AND car.ship_to = ar.ship_to_code
            WHERE sd.yyyymmdd
                  BETWEEN @start AND @end
                  AND ar.status_type = 1 -- active
                  AND ar.address_type <> 9
            GROUP BY customer,
                     CASE
                         WHEN car.door = 1 THEN
                             car.ship_to
                         ELSE
                             ''
                     END,
                     car.door,
                     sd.ship_to
            HAVING SUM(sd.anet) > 500
                   AND EXISTS
                       (
                           SELECT 1
                           FROM cvo_sbm_details sbm (NOLOCK)
                           WHERE sbm.customer = sd.customer
                                 AND sbm.promo_id = 'bts'
                                 AND sbm.year >= YEAR(DATEADD(DAY, -365 * 3, @end))
                       )
        ) sales
            ON sales.customer = cust.customer_code
               AND sales.ship_to = cust.ship_to_code
    WHERE 1 = 1;


    SELECT c.collection,
           c.customer_code,
           c.ship_to_code,
           c.address_name,
           c.addr2,
           c.addr3,
           c.addr4,
           c.addr5,
           c.city,
           c.state,
           c.postal_code,
           c.country_code,
           c.contact_phone
    FROM #cust c
    UNION ALL
    SELECT brands.collection,
           ar.customer_code,
           ar.ship_to_code,
           ar.address_name,
           ar.addr2,
           ar.addr3,
           ar.addr4,
           ar.addr5,
           ar.city,
           ar.state,
           ar.postal_code,
           ar.country_code,
           ar.contact_phone
    FROM
    (SELECT DISTINCT collection, customer_code FROM #cust c) brands
        JOIN armaster ar
            ON ar.customer_code = brands.customer_code
        JOIN CVO_armaster_all car
            ON car.customer_code = ar.customer_code
               AND car.ship_to = ar.ship_to_code
    WHERE car.door = 1
          AND ar.status_type = 1
          AND ar.address_type = 1 -- ship-to's only
          AND NOT EXISTS
    (
        SELECT 1
        FROM #cust c
        WHERE c.customer_code = ar.customer_code
              AND c.ship_to_code = ar.ship_to_code
    );

END;





GO
GRANT EXECUTE ON  [dbo].[cvo_store_locator_brand_sp] TO [public]
GO
