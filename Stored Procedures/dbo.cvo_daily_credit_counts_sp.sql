SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[cvo_daily_credit_counts_sp] 
	@sdate DATETIME, @edate datetime
AS 

SET NOCOUNT ON
SET ANSI_WARNINGS OFF

SELECT credits.who_processed, CASE WHEN credits.who_entered <> who_processed THEN 'RMA' ELSE 'Manual' end as Credit_type, COUNT(order_no) num_credits, SUM(num_skus) total_skus, AVG(num_skus) avg_skus
from
(SELECT o.who_entered, REVERSE(SUBSTRING(REVERSE(o.user_def_fld3), 1, 
               CHARINDEX(' ', REVERSE(o.user_def_fld3)) - 1)) who_processed, 
o.order_no, o.ext, cOUNT(part_no) num_skus
FROM orders o
JOIN 
ord_list (NOLOCK) ol ON ol.order_no = o.order_no AND ol.order_ext = o.ext
WHERE o.type = 'c' AND o.status IN ('r','s','t')
AND o.date_shipped BETWEEN @sdate AND @edate 

GROUP BY o.who_entered, REVERSE(SUBSTRING(REVERSE(o.user_def_fld3), 1, 
               CHARINDEX(' ', REVERSE(o.user_def_fld3)) - 1)), o.order_no, o.ext
) credits
GROUP BY CASE
         WHEN credits.who_entered <> who_processed THEN
         'RMA'
         ELSE
         'Manual'
         END,
         credits.who_processed 

GO
GRANT EXECUTE ON  [dbo].[cvo_daily_credit_counts_sp] TO [public]
GO
