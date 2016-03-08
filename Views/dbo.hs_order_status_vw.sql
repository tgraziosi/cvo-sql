
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO







-- select * From hs_order_status_vw where order_no = 1885329 where status <> 't'

CREATE VIEW [dbo].[hs_order_status_vw] AS 

-- Author:  Tine G. - 06/19/2013
-- purpose:  provide Handshake order status for HS Sync
-- usage:  select hs_order_no, hs_status from hs_order_status_vw where hs_order_no like '%'
-- 12/4/2013 - add promo/level info
-- 10/28/2015 - add source to differentiate Magento orders from Handshake orders
-- 2/26/2016  - include credits too

SELECT
o.user_def_fld4 HS_order_no, 
o.order_no, 
CASE WHEN o.status BETWEEN 'A' AND 'Q' THEN 'Processing'
	 WHEN o.status BETWEEN 'R' AND 'T' THEN 'Complete'
	 ELSE 'Unknown'
END AS HS_status,
o.status,
o.date_entered,
o.user_def_fld3 AS date_modified,
ISNULL(co.promo_id,'') promo_id,
ISNULL(co.promo_level,'') promo_level,
-- 10/28/2015 - add support for Magento orders
ISNULL(c.carrier_code,ISNULL(o.routing,'')) AS carrier,
ISNULL(c.cs_tracking_no,'') AS tracking
-- , CAST(ISNULL(o.USER_def_fld4,'0') AS INT) hs_order_no_int
, source = CASE WHEN LEFT(o.user_def_fld4,1) = 'M' THEN 'M' ELSE 'H' END
FROM orders o (NOLOCK)
INNER JOIN cvo_orders_all co (NOLOCK) ON o.order_no = co.order_no AND o.ext = co.ext
LEFT OUTER JOIN tdc_carton_tx c ON o.order_no = c.order_no AND o.ext = c.order_ext

WHERE user_def_fld4 <> ''
AND date_entered > '01/01/2013'
AND who_entered NOT IN ('backordr')
AND o.status <> 'V' -- AND o.type = 'I'
AND ISNULL(c.void,0) = 0













GO

GRANT REFERENCES ON  [dbo].[hs_order_status_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[hs_order_status_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[hs_order_status_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[hs_order_status_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[hs_order_status_vw] TO [public]
GO
