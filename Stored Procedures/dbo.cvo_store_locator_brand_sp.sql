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
    FROM arterr t
        (NOLOCK)
    WHERE dbo.calculate_region_fn(t.territory_code) < '800'
    ) terr
        JOIN armaster cust
        (NOLOCK)
            ON cust.territory_code = terr.territory_code
               AND cust.status_type = 1
               AND cust.addr_sort1 IN ( 'Customer', 'Intl Retailer' )
        JOIN CVO_armaster_all car
        (NOLOCK)
            ON car.customer_code = cust.customer_code
               AND car.ship_to = cust.ship_to_code
               AND car.door = 1
        JOIN
        (
        SELECT DISTINCT sbm.customer,
               CASE WHEN car.door = 1 THEN sbm.ship_to ELSE '' END AS ship_to,
               CASE WHEN i.category = 'op' AND pa.part_no IS NOT NULL THEN pa.attribute ELSE i.category END collection
        FROM inv_master i
            (NOLOCK)
            JOIN cvo_sbm_details sbm
            (NOLOCK)
                ON sbm.part_no = i.part_no
			JOIN cvo_armaster_all car (nolock) ON car.customer_code = sbm.customer AND car.ship_to = sbm.ship_to
			JOIN armaster ar (nolock) ON ar.customer_code = sbm.customer AND ar.ship_to_code = sbm.ship_to
            LEFT JOIN dbo.cvo_part_attributes AS pa
                ON pa.part_no = i.part_no
                   AND pa.attribute = 'Pogocam'
        WHERE i.type_code IN ( 'frame', 'sun' )
              AND i.void = 'n'
              AND sbm.yyyymmdd > DATEADD(year, -1, GETDATE())
			  AND ar.status_type = 1 -- active
              AND ar.address_type <> 9
        GROUP BY sbm.customer,
                 CASE WHEN car.door = 1 THEN sbm.ship_to ELSE '' END,
                 CASE WHEN i.category = 'op' AND pa.part_no IS NOT NULL THEN pa.attribute ELSE i.category END
        HAVING SUM(qnet) > 4
        UNION ALL
        SELECT DISTINCT sd.customer,
               CASE WHEN car.door = 1 THEN car.ship_to ELSE '' END AS ship_to,
               'Kids Premier' category
        FROM dbo.cvo_sbm_details AS sd
            (NOLOCK)
            JOIN armaster ar
            (NOLOCK)
                ON ar.customer_code = sd.customer
                   AND ar.ship_to_code = sd.ship_to
            JOIN dbo.CVO_armaster_all AS car
            (NOLOCK)
                ON car.customer_code = ar.customer_code
                   AND car.ship_to = ar.ship_to_code
        WHERE sd.yyyymmdd
              BETWEEN @start AND @end
              AND ar.status_type = 1 -- active
              AND ar.address_type <> 9
        GROUP BY customer,
                 CASE WHEN car.door = 1 THEN car.ship_to ELSE '' END,
                 car.door,
                 sd.ship_to
        HAVING SUM(sd.anet) > 500
               AND EXISTS
                   (
                   SELECT 1
                   FROM cvo_sbm_details sbm (nolock)
                   WHERE sbm.customer = sd.customer
                         AND sbm.promo_id = 'bts'
                         AND sbm.year >= YEAR(DATEADD(DAY, -365 * 3, @end))
                   )
        ) sales
            ON sales.customer = cust.customer_code
               AND sales.ship_to = cust.ship_to_code
    WHERE 1 = 1;

END;




GO
GRANT EXECUTE ON  [dbo].[cvo_store_locator_brand_sp] TO [public]
GO
