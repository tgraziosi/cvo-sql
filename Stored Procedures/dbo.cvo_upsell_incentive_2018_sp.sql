SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[cvo_upsell_incentive_2018_sp] (@sdate DATETIME, @edate datetime)

 AS 

 /*
EXEC dbo.cvo_upsell_incentive_2018_sp @sdate = '2018-04-01', -- datetime
                                      @edate = '2018-04-02' -- datetime
									  */

begin
DECLARE @ssdate DATETIME, @eedate DATETIME
SELECT @ssdate = @sdate, @eedate = DATEADD(ms,-3,DATEADD(DAY,1,@edate))

SELECT  
CASE WHEN c.user_login IS NOT NULL THEN c.fname + ' ' + c.lname ELSE  'Unknown - '+o.who_entered END AS who_entered,
SUM(ol.ordered) ordered, 

SUM(CASE WHEN DATEADD(DAY, DATEDIFF(DAY,0,ol.time_entered), 0) >=  @edate THEN ol.ordered ELSE 0 end) ordered_today,

SUM(
(CASE o.type WHEN 'I' THEN ROUND((ol.curr_price - ROUND(col.amt_disc,2)),2,1)  -- v10.7
   ELSE CASE ol.discount WHEN 0 THEN ol.curr_price  
   -- START v11.6
   ELSE CASE WHEN col.list_price = ol.curr_price THEN ROUND(col.list_price - (col.list_price * ol.discount/100),2)
      ELSE ROUND((ol.curr_price - ROUND(ol.curr_price * ol.discount/100,2 * ol.discount/100,2)),2,1) END

END END ) * CASE WHEN o.type = 'i' THEN ol.ordered ELSE ol.cr_ordered END
) AS ExtPrice,

SUM(CASE when DATEADD(DAY, DATEDIFF(DAY,0,ol.time_entered), 0) >= @edate
then
CASE o.type WHEN 'I' 
			THEN ROUND((ol.curr_price - ROUND(col.amt_disc,2)),2,1)  -- v10.7
   ELSE CASE ol.discount WHEN 0 THEN ol.curr_price  
   -- START v11.6
   ELSE CASE WHEN col.list_price = ol.curr_price THEN ROUND(col.list_price - (col.list_price * ol.discount/100),2)
      ELSE ROUND((ol.curr_price - ROUND(ol.curr_price * ol.discount/100,2 * ol.discount/100,2)),2,1) END

END END  * CASE WHEN o.type = 'i' THEN ol.ordered ELSE ol.cr_ordered END
ELSE 0 END
) AS ExtPrice_today


FROM cvo_ord_list col (nolock)
JOIN ord_list ol (nolock) ON ol.order_no = col.order_no AND ol.order_ext = col.order_ext AND ol.line_no = col.line_no
JOIN orders o (NOLOCK) ON o.order_no = col.order_no AND o.ext = col.order_ext
LEFT OUTER JOIN cvo_cmi_users c ON c.user_login = o.who_entered
WHERE col.upsell_flag = 1 
AND ol.time_entered BETWEEN @ssdate AND @eedate
AND o.who_entered NOT IN ('backordr','outofstock','gkubicki','cgiammanco','awatkins')
AND o.status <> 'V'
AND O.TYPE = 'I'
AND 'RB' <> RIGHT(O.user_CATEGORY,2)

GROUP BY CASE WHEN c.user_login IS NOT NULL THEN c.fname + ' ' + c.lname ELSE  'Unknown - '+o.who_entered END
ORDER BY ExtPrice DESC

end








GO
GRANT EXECUTE ON  [dbo].[cvo_upsell_incentive_2018_sp] TO [public]
GO
