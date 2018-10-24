SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[cvo_upsell_orders_sp] (@s DATETIME, @e datetime) AS 

-- exec cvo_upsell_orders_sp '9/1/2018','9/30/2018'

BEGIN
SET NOCOUNT ON

DECLARE @sd DATETIME, @ed DATETIME
SELECT @sd = @s, @ed = DATEADD(d,1,@e)

SELECT  o.who_entered ,
        o.status ,
        o.date_entered ,
		o.cust_code,
		o.ship_to,
		o.ship_to_name,
        o.order_no ,
        o.ext ,
		o.user_category,
        ol.line_no ,
        ol.part_no ,
        i.type_code ,
        col.list_price ,
        CASE o.type
          WHEN 'I'
          THEN CASE ( ISNULL(col.is_amt_disc, 'n') )
                 WHEN 'Y'
                 THEN ROUND(( ol.shipped * ol.curr_price ) - ( ol.shipped
                                                              * ROUND(ISNULL(col.amt_disc,
                                                              0), 2) ), 2)
                 ELSE ROUND(( ol.shipped * ol.curr_price ) - ( ( ol.shipped
                                                              * ol.curr_price )
                                                              * ( ol.discount
                                                              / 100.00 ) ), 2)
               END       			  -- v10.7
          ELSE CASE ol.discount
                 WHEN 0 THEN ol.curr_price * -ol.cr_shipped
                 ELSE CASE WHEN col.orig_list_price = ol.curr_price
                           THEN -ol.cr_shipped * ROUND(col.orig_list_price
                                                       - ROUND(( col.orig_list_price
                                                              * ol.discount
                                                              / 100 ), 2), 2)
                           ELSE -ol.cr_shipped * ROUND(( ol.curr_price
                                                         - ROUND(ol.curr_price
                                                              * ol.discount
                                                              / 100, 2) ), 2,
                                                       1)
                      END
               END
        END AS net_amt ,
        ol.ordered ,
        ol.shipped ,
        co.promo_id ,
        co.promo_level ,
        CASE WHEN o.note > '' THEN 'Order: ' + o.note 
			 ELSE '' END order_note,
        CASE WHEN ol.note > '' then
			 CASE WHEN o.note = '' THEN 'Line: '+ ol.note
				  WHEN o.note <> '' THEN '; Line: '+ ol.note
				  ELSE ol.note
				  end
			ELSE ol.note
			end line_note,
		ISNULL(tx.Salesperson_code,'Unknown') dept
FROM    CVO_ord_list col
        JOIN ord_list ol ON ol.line_no = col.line_no
                            AND ol.order_ext = col.order_ext
                            AND ol.order_no = col.order_no
        JOIN inv_master i ON i.part_no = ol.part_no
        JOIN orders o ON o.order_no = col.order_no
                         AND o.ext = col.order_ext
        JOIN dbo.CVO_orders_all AS co ON co.order_no = o.order_no
                                         AND co.ext = o.ext
		LEFT OUTER JOIN dbo.CVO_TerritoryXref AS tx ON REPLACE(tx.User_name,'cvoptical\','') = o.who_entered
WHERE   col.upsell_flag = 1
        AND o.status <> 'v'
        AND o.who_entered <> 'backordr'
        AND o.type = 'i'
		AND o.date_entered BETWEEN @sd AND @ed

END

GRANT ALL ON dbo.cvo_upsell_orders_sp TO PUBLIC



GO
GRANT EXECUTE ON  [dbo].[cvo_upsell_orders_sp] TO [public]
GO
