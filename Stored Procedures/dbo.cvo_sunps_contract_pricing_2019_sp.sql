SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[cvo_sunps_contract_pricing_2019_sp]
AS
BEGIN

-- Jan 2018 - set up contract pricing for sunps 2019

-- EXEC cvo_sunps_contract_pricing_2019_sp
-- select * From c_quote where note like 'sunps 2019 contract pricing%'
  
    SET NOCOUNT ON;

    DECLARE @seasonstartdate DATETIME
    SET @seasonstartdate = '11/12/2018'


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
           t.note  note,
           GETDATE() date_entered,
           '12/31/2019' date_expires,
           0.00 sales_comm,
           NULL cust_part_no,
           'USD' curr_key,
           '1/1/2019' start_date,
           '' style,
           'SUN' res_type,
		   'Y' net_only
    FROM
    (
    SELECT DISTINCT
           cust_code,
           CASE WHEN co.promo_level = '1' THEN 44.99 WHEN co.promo_level in ('2','3') THEN 39.99 ELSE 9999.99 END CONTRACT_PRICE,
           'SUNPS 2019 Contract Pricing' + CASE WHEN co.promo_level = '3' THEN ' - Renewal' ELSE '' END Note
    FROM orders o (NOLOCK)
        JOIN CVO_orders_all co (NOLOCK)
            ON co.order_no = o.order_no
               AND co.ext = o.ext
    WHERE o.status <> 'V' -- switch to all orders per KB request 12/6/2018
          AND co.promo_id = 'sunps'
          AND o.date_entered >= @seasonstartdate
          AND RIGHT(o.user_category, 2) NOT IN ( 'rb', 'tb' )
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
                           AND c.ilevel = 1
                           AND 'SUN' = c.res_type
                           AND note like 'SUNPS 2019 Contract Pricing%'
                           AND date_expires = '12/31/2019'
                           AND c.style = ''
                     );

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
           t.note  note,
           GETDATE() date_entered,
           '12/31/2019' date_expires,
           0.00 sales_comm,
           NULL cust_part_no,
           'USD' curr_key,
           '1/1/2019' start_date,
           '' style,
           'SUN' res_type,
		   'Y' net_only
    FROM
    (
    SELECT distinct
           CDC.CUSTOMER_CODE cust_code,
           CASE WHEN cdc.code = 'SUN191' THEN 44.99 WHEN CDC.CODE = 'SUN192' THEN 39.99 ELSE 9999.99 END CONTRACT_PRICE,
           'SUNPS 2019 Contract Pricing - Renewal' Note
           FROM dbo.cvo_cust_designation_codes AS cdc WHERE CDC.CODE IN ('sun191','sun192')

    ) AS t
        CROSS JOIN
        (SELECT 'BCBG' brand UNION SELECT 'SM' UNION SELECT 'IZOD') AS b

    WHERE NOT EXISTS (
                     SELECT 1
                     FROM dbo.c_quote c
                     WHERE c.customer_key = t.cust_code
                           AND 'ALL' = c.ship_to_no
                           AND c.item = b.brand
                           AND c.ilevel = 1
                           AND 'SUN' = c.res_type
                           AND note like 'SUNPS 2019 Contract Pricing%'
                           AND date_expires = '12/31/2019'
                           AND c.style = ''
                     );

END;

GO
GRANT EXECUTE ON  [dbo].[cvo_sunps_contract_pricing_2019_sp] TO [public]
GO
