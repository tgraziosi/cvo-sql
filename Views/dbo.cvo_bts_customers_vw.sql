SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW [dbo].[cvo_bts_customers_vw]
AS
SELECT DISTINCT
    cust_code, o.ship_to, co.promo_level
--, p.promo_id, p.promo_level, p.promo_start_date, o.date_entered, p.promo_end_date
FROM
    dbo.CVO_promotions p (NOLOCK)
    JOIN CVO_orders_all co (NOLOCK)
        ON p.promo_id = co.promo_id
           AND p.promo_level = co.promo_level
    JOIN orders o (NOLOCK)
        ON co.order_no = o.order_no
           AND co.ext = o.ext
WHERE
    p.promo_id = 'bts'
    AND p.promo_level IN ('dd','2018')
    AND o.status <> 'v'
    AND o.who_entered <> 'backordr'
    AND p.promo_start_date <= o.date_entered
    AND p.promo_end_date >= GETDATE()
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
