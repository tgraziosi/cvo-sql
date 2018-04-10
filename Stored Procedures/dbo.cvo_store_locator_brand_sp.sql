SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[cvo_store_locator_brand_sp]
AS
BEGIN

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
FROM arterr t (nolock)
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
    SELECT sbm.customer,
           sbm.ship_to,
           i.category collection
    FROM inv_master i (NOLOCK)
        JOIN cvo_sbm_details sbm (NOLOCK)
            ON sbm.part_no = i.part_no
    WHERE i.type_code IN ( 'frame', 'sun' )
		  AND i.void = 'n'
          AND sbm.yyyymmdd > DATEADD(YEAR, -1, GETDATE())
    GROUP BY sbm.customer,
             sbm.ship_to,
             i.category
    HAVING SUM(qnet) > 4
    ) sales
        ON sales.customer = cust.customer_code
           AND sales.ship_to = cust.ship_to_code
WHERE 1 = 1
;

END


GO
GRANT EXECUTE ON  [dbo].[cvo_store_locator_brand_sp] TO [public]
GO
