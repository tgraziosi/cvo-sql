SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW [dbo].[cvo_bts_customers_vw]
AS
SELECT DISTINCT
    o.cust_code, o.ship_to -- , co.promo_level
--, p.promo_id, p.promo_level, p.promo_start_date, o.date_entered, p.promo_end_date
FROM
    dbo.CVO_promotions p (NOLOCK)
    JOIN CVO_orders_all co (NOLOCK)
        ON p.promo_id = co.promo_id
           AND p.promo_level = co.promo_level
    JOIN orders o (NOLOCK)
        ON co.order_no = o.order_no
           AND co.ext = o.ext
    JOIN armaster ar (nolock) ON ar.customer_code = o.cust_code AND ar.ship_to_code = o.ship_to
WHERE
ar.status_type = 1
AND (p.promo_id+p.promo_level) IN 
(
'6+2dd',
'BTS1',
'BTS2',
'BTS2018',
'BTS2018WEB',
'BTS3',
'BTScs',
'BTSdd',
'BTSddweb',
'BTSKIDS1',
'BTSkids2',
'BTSOP',
'BTStween1',
'BTStween2',
'BTSweb',
'BTSweb18',
'DD1',
'DDIS',
'KIDS3',
'KIDS4'
)
--p.promo_id = 'bts'
--    AND p.promo_level IN ('dd','2018')
    AND o.status <> 'v'
    AND o.who_entered <> 'backordr'
    --AND p.promo_start_date <= o.date_entered
    --AND p.promo_end_date >= GETDATE()
    AND o.date_entered > DATEADD(YEAR,-5,GETDATE())
;


GO
GRANT REFERENCES ON  [dbo].[cvo_bts_customers_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[cvo_bts_customers_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[cvo_bts_customers_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[cvo_bts_customers_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[cvo_bts_customers_vw] TO [public]
GO
