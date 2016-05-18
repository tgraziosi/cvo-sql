SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW [dbo].[cvo_cart_order_select_vw] AS 

SELECT o.order_no, o.ext, o.status, o.sch_ship_date, 
	ISNULL(MIN(CASE when i.type_code NOT IN ('case') THEN i.part_no ELSE NULL end),'Other') min_part_no,
	SUM(CASE WHEN i.type_code IN ('frame','sun') THEN ordered-shipped ELSE 0 END) AS Num_Frames,
	SUM(CASE WHEN i.type_code IN ('case') THEN ordered-shipped ELSE 0 END) AS Num_cases,
	SUM(ordered-shipped) num_items
FROM ord_list ol
JOIN orders o ON o.order_no = ol.order_no AND o.ext = ol.order_ext
JOIN inv_master i ON i.part_no = ol.part_no
WHERE o.user_category LIKE 'rx%'
AND EXISTS (SELECT 1 FROM dbo.tdc_pick_queue AS tpq 
	WHERE tpq.part_no = ol.part_no AND tpq.trans_type_no = ol.order_no AND tpq.trans_type_ext = ol.order_ext 
	AND tx_lock = 'R' AND trans = 'stdpick' AND tpq.priority <> 3)
AND o.location = '001'
AND o.status IN ('n','q') -- new or open/print
AND o.so_priority_code <> 3 -- no custom orders please
GROUP BY o.order_no ,
         o.ext,
		 o.status,
		 o.sch_ship_date
-- ORDER BY MIN(CASE when i.type_code NOT IN ('case') THEN i.part_no ELSE NULL end)

GO
GRANT REFERENCES ON  [dbo].[cvo_cart_order_select_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[cvo_cart_order_select_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[cvo_cart_order_select_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[cvo_cart_order_select_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[cvo_cart_order_select_vw] TO [public]
GO
