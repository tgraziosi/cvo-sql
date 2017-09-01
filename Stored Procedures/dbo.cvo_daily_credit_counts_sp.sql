SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[cvo_daily_credit_counts_sp] 
	@sdate DATETIME, @edate datetime
AS 

-- EXEC cvo_daily_credit_counts_sp '08/15/2017', '08/16/2017'

SET NOCOUNT ON
SET ANSI_WARNINGS OFF

SELECT credits.who_processed, CASE WHEN credits.who_entered <> who_processed THEN 'RMA Credit' ELSE 'Manual Credit' end as Credit_type, COUNT(order_no) num_credits, SUM(num_skus) total_skus, AVG(num_skus) avg_skus
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
         'RMA Credit'
         ELSE
         'Manual Credit'
         END,
         credits.who_processed 

UNION ALL

SELECT REPLACE(wms.UserID,'cvoptical\','') who_processed,
		trans,
		count (wms.tran_no) num_activity,
		COUNT(DISTINCT wms.part_no) total_skus,
		0 AS avg_skus
		 FROM TDC_LOG wms (NOLOCK)
		 WHERE wms.tran_date BETWEEN @sdate AND @edate
		 AND trans IN ('qcrelease','poptwy')
		 GROUP BY REPLACE(wms.UserID, 'cvoptical\', ''), wms.trans



GO
GRANT EXECUTE ON  [dbo].[cvo_daily_credit_counts_sp] TO [public]
GO
