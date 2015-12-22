SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO



CREATE PROC [dbo].[APPYUpdatePostedRecords_sp]  @date_applied int,
										@debug_level smallint = 0
AS


							 
IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "appyupr.cpp" + ", line " + STR( 51, 5 ) + " -- ENTRY: "


IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "appyupr.cpp" + ", line " + STR( 54, 5 ) + " -- MSG: " + "Update on-acct amounts in #appytrxp_work"
UPDATE #appytrxp_work
SET amt_on_acct = amt_on_acct - ISNULL((SELECT SUM(amt_payment - amt_on_acct)
									   FROM #appypyt_work
									   WHERE payment_type IN (2,3)
									   AND #appypyt_work.doc_ctrl_num = #appytrxp_work.doc_ctrl_num
									   AND #appypyt_work.cash_acct_code = #appytrxp_work.cash_acct_code),0.0),
    db_action = 1
FROM #appytrxp_work



IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "appyupr.cpp" + ", line " + STR( 66, 5 ) + " -- MSG: " + "Update date_paid in #appyageo_work"
UPDATE #appyageo_work
SET date_paid = @date_applied,
    db_action = 1
FROM #appyageo_work, #appytrxp_work b
WHERE #appyageo_work.doc_ctrl_num = b.doc_ctrl_num
AND #appyageo_work.cash_acct_code = b.cash_acct_code
AND @date_applied > #appyageo_work.date_paid


IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "appyupr.cpp" + ", line " + STR( 76, 5 ) + " -- MSG: " + "Update on-acct amounts in #appyageo_work"
UPDATE #appyageo_work
SET paid_flag = 1,
    db_action = 1
FROM #appyageo_work, #appytrxp_work b
WHERE #appyageo_work.doc_ctrl_num = b.doc_ctrl_num
AND #appyageo_work.cash_acct_code = b.cash_acct_code
AND ((b.amt_on_acct) <= (0.0) + 0.0000001) 



IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "appyupr.cpp" + ", line " + STR( 87, 5 ) + " -- MSG: " + "Update amt_paid_to_date in #appytrxv_work"
UPDATE #appytrxv_work
SET amt_paid_to_date = amt_paid_to_date + (SELECT ISNULL(SUM(b.vo_amt_applied + b.vo_amt_disc_taken),0.0)
											   FROM #paydist b
											   WHERE #appytrxv_work.trx_ctrl_num = b.apply_to_num),
    db_action = 1
FROM #appytrxv_work 


IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "appyupr.cpp" + ", line " + STR( 96, 5 ) + " -- MSG: " + "Update date_paid in #appyagev_work"
UPDATE #appyagev_work
SET date_paid = @date_applied,
    db_action = 1
FROM #appyagev_work, #appytrxv_work b
WHERE #appyagev_work.trx_ctrl_num = b.trx_ctrl_num
AND  @date_applied > #appyagev_work.date_paid

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "appyupr.cpp" + ", line " + STR( 104, 5 ) + " -- MSG: " + "Update paid_flag in #appyagev_work"
UPDATE #appyagev_work
SET paid_flag = 1,
    db_action = 1
FROM #appyagev_work, #appytrxv_work b
WHERE #appyagev_work.trx_ctrl_num = b.trx_ctrl_num
AND ((b.amt_net) <= (b.amt_paid_to_date) + 0.0000001)


IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "appyupr.cpp" + ", line " + STR( 113, 5 ) + " -- MSG: " + "Update paid_flag in #appytrxv_work"
UPDATE #appytrxv_work
SET paid_flag = 1,
    db_action = 1
WHERE (ABS((amt_net)-(amt_paid_to_date)) < 0.0000001)

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "appyupr.cpp" + ", line " + STR( 119, 5 ) + " -- MSG: " + "Update date_paid in #appytrxv_work"
UPDATE #appytrxv_work
SET date_paid = ISNULL((SELECT MAX(a.date_doc)
                 FROM #paydist a
				 WHERE a.apply_to_num = #appytrxv_work.trx_ctrl_num),#appytrxv_work.date_paid),
    db_action = 1
FROM #appytrxv_work 
WHERE ((amt_net) <= (amt_paid_to_date) + 0.0000001)


IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "appyupr.cpp" + ", line " + STR( 129, 5 ) + " -- EXIT: "
RETURN 0
GO
GRANT EXECUTE ON  [dbo].[APPYUpdatePostedRecords_sp] TO [public]
GO
