SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[cvo_hello_backorders_sp] @customer VARCHAR(10) = NULL, @ship_to VARCHAR(10) = NULL

AS 

-- exec cvo_hello_backorders_sp '039226'

BEGIN

SET NOCOUNT ON 
SET ANSI_WARNINGS OFF

SELECT ol.part_no, i.description, ol.ordered, iav.NextPODueDate, o.order_no,o.ext, o.date_entered, o.user_def_fld4 hs_order_no
 FROM orders o 
JOIN ord_list ol (NOLOCK) ON ol.order_no = o.order_no AND ol.order_ext = o.ext
JOIN inv_master i (NOLOCK) ON i.part_no = ol.part_no
JOIN dbo.cvo_item_avail_vw AS iav (NOLOCK) ON iav.location = ol.location AND iav.part_no = ol.part_no
WHERE o.who_entered = 'backordr'
AND o.status < 'p'
AND i.type_code in ('frame','sun')
AND o.cust_code = ISNULL(@customer,'') AND o.ship_to = ISNULL(@ship_to,'')

END

GRANT EXECUTE ON dbo.cvo_hello_backorders_sp TO PUBLIC

GO
GRANT EXECUTE ON  [dbo].[cvo_hello_backorders_sp] TO [public]
GO
