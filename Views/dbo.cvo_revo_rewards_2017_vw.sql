SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW [dbo].[cvo_revo_rewards_2017_vw] AS 
SELECT ship_to_region territory, o.salesperson, o.date_entered, o.order_no, o.ext, o.status, LEFT(o.user_category,2) order_type, SUM(ordered) revo_ordered,
o.cust_code, o.ship_to, o.ship_to_name , oa.promo_id, oa.promo_level
FROM inv_master i 
JOIN ord_list ol ON ol.part_no = i.part_no
JOIN orders o ON o.order_no = ol.order_no AND o.ext = ol.order_ext
JOIN dbo.CVO_orders_all AS oa ON  oa.order_no = o.order_no AND  oa.ext = o.ext 
WHERE i.category = 'revo' AND i.type_code IN ('frame','sun')
-- AND 'st' = LEFT(o.user_category,2)
AND 'rb' <> RIGHT(o.user_category,2)
AND o.type = 'i'
AND o.status <> 'v'
AND o.who_entered <> 'backordr'
AND ISNULL(oa.promo_id,'') NOT IN ('revo') AND ISNULL(oa.promo_level,'') NOT IN ('1','2','3','try')
AND 2017 = DATEPART(YEAR,o.date_entered)
GROUP BY o.ship_to_region ,
         o.salesperson ,
		 o.date_entered,
         o.order_no ,
         o.ext ,
         o.cust_code ,
         o.ship_to ,
         o.ship_to_name,
		 o.status,
		 LEFT(o.user_category,2),
		 oa.promo_id,
		 oa.promo_level

		 ;


GO
GRANT SELECT ON  [dbo].[cvo_revo_rewards_2017_vw] TO [public]
GO
