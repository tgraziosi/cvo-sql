SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[cvo_sunps_contract_pricing_2018_sp]
AS
BEGIN

-- Jan 2018 - set up contract pricing for sunps 2018  

-- EXEC cvo_sunps_contract_pricing_2018_sp
-- select * From c_quote where note = 'sunps 2018 contract pricing'
  
    SET NOCOUNT ON;

    INSERT INTO c_quote
    (
        customer_key,
        ship_to_no,
        ilevel,
        item,
        min_qty,
        type,
        rate,
        note,
        date_entered,
        date_expires,
        sales_comm,
        cust_part_no,
        curr_key,
        start_date,
        style,
        res_type,
		net_only
    )
    SELECT DISTINCT
           t.cust_code,
           'ALL' ship_to_no,
           '1' ilevel,
           b.brand item,
           1.0 min_qty,
           'P' type,
           t.CONTRACT_PRICE rate,
           'SUNPS 2018 Contract Pricing' note,
           GETDATE() date_entered,
           '12/31/2018' date_expires,
           0.00 sales_comm,
           NULL cust_part_no,
           'USD' curr_key,
           '1/1/2018' start_date,
           '' style,
           'SUN' res_type,
		   'Y' net_only
    FROM
    (
    SELECT DISTINCT
           cust_code,
           CASE WHEN co.promo_level = '1' THEN 44.99 WHEN co.promo_level = '2' THEN 39.99 ELSE 9999.99 END CONTRACT_PRICE
    FROM orders o (NOLOCK)
        JOIN CVO_orders_all co (NOLOCK)
            ON co.order_no = o.order_no
               AND co.ext = o.ext
    WHERE o.status = 't'
          AND co.promo_id = 'sunps'
          AND o.date_entered >= '11/1/2017'
          AND RIGHT(o.user_category, 2)NOT IN ( 'rb', 'tb' )
          AND o.type = 'i'
          AND o.who_entered <> 'backordr'
    ) AS t
        CROSS JOIN
        (SELECT 'BCBG' brand UNION SELECT 'SM' UNION SELECT 'IZOD') AS b

    WHERE NOT EXISTS (
                     SELECT 1
                     FROM dbo.c_quote c
                     WHERE c.customer_key = t.cust_code
                           AND 'ALL' = c.ship_to_no
                           AND c.item = b.brand
                           AND 'SUN' = c.res_type
                           AND note = 'SUNPS 2018 Contract Pricing'
                     );

END;

GRANT ALL ON dbo.cvo_sunps_contract_pricing_2018_sp TO PUBLIC



GO
GRANT EXECUTE ON  [dbo].[cvo_sunps_contract_pricing_2018_sp] TO [public]
GO
