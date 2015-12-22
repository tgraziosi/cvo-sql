SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROC [dbo].[ARCBUPDateCustActivity_SP] @customer_code varchar(8)
 
AS
BEGIN

 
 DECLARE @precision_home smallint,
 @precision_oper smallint

 SELECT @precision_home = curr_precision
 FROM glcurr_vw, glco
 WHERE glco.home_currency = glcurr_vw.currency_code

 SELECT @precision_oper = curr_precision
 FROM glcurr_vw, glco
 WHERE glco.oper_currency = glcurr_vw.currency_code

 
 CREATE TABLE #customer_bal
 ( customer_code varchar(8), 
 amt_balance_home float,
 amt_balance_oper float,
 amt_on_acct_home float,
 amt_on_acct_oper float,
 amt_inv_unp_home float,
 amt_inv_unp_oper float, 
 amt_on_order_home float,
 amt_on_order_oper float, 
 num_inv int,
 num_inv_paid int,
 num_overdue_pyt int,
 days_overdue int,
 days_pay int,
 avg_days_overdue int,
 avg_days_pay int,
 exists_flag int
 ) 
 
 
 INSERT #customer_bal
 SELECT customer_code, 
 ROUND(SUM(SIGN(SIGN(ref_id-1)+1)*ROUND(amount*( SIGN(1 + SIGN(rate_home))*(rate_home) + (SIGN(ABS(SIGN(ROUND(rate_home,6))))/(rate_home + SIGN(1 - ABS(SIGN(ROUND(rate_home,6)))))) * SIGN(SIGN(rate_home) - 1) ), @precision_home)), @precision_home),
 ROUND(SUM(SIGN(SIGN(ref_id-1)+1)*ROUND(amount*( SIGN(1 + SIGN(rate_oper))*(rate_oper) + (SIGN(ABS(SIGN(ROUND(rate_oper,6))))/(rate_oper + SIGN(1 - ABS(SIGN(ROUND(rate_oper,6)))))) * SIGN(SIGN(rate_oper) - 1) ), @precision_oper)), @precision_oper),
 ROUND(SUM(SIGN(SIGN(0.5-ref_id)+1)*ROUND(-amount*( SIGN(1 + SIGN(rate_home))*(rate_home) + (SIGN(ABS(SIGN(ROUND(rate_home,6))))/(rate_home + SIGN(1 - ABS(SIGN(ROUND(rate_home,6)))))) * SIGN(SIGN(rate_home) - 1) ), @precision_home)), @precision_home),
 ROUND(SUM(SIGN(SIGN(0.5-ref_id)+1)*ROUND(-amount*( SIGN(1 + SIGN(rate_oper))*(rate_oper) + (SIGN(ABS(SIGN(ROUND(rate_oper,6))))/(rate_oper + SIGN(1 - ABS(SIGN(ROUND(rate_oper,6)))))) * SIGN(SIGN(rate_oper) - 1) ), @precision_oper)), @precision_oper),
 0.0, 0.0, 
 0.0, 0.0, 
 SUM(SIGN(SIGN(2031.5 - trx_type)+1)*SIGN(SIGN(1.5-ref_id)+1)),
 SUM(SIGN(SIGN(2031.5 - trx_type)+1)*SIGN(paid_flag)*SIGN(SIGN(1.5-ref_id)+1)),
 SUM(SIGN(SIGN(2031.5 - trx_type)+1)*SIGN(paid_flag)*SIGN(SIGN(1.5-ref_id)+1)
 * SIGN(SIGN(date_paid - date_due+0.5)+1)),
 SUM(SIGN(SIGN(2031.5 - trx_type)+1)*(date_paid-date_due)*SIGN(paid_flag)
 * SIGN(SIGN(date_paid-date_due+0.5)+1)),
 SUM(SIGN(SIGN(2031.5 - trx_type)+1)*(date_paid-date_doc)*SIGN(paid_flag)
 * SIGN(SIGN(date_paid-date_doc+0.5)+1)), 
 0, 0, 0
 FROM artrxage
 WHERE customer_code = @customer_code
 GROUP BY customer_code 
 
 CREATE CLUSTERED INDEX #cust_bal_ind ON #customer_bal(customer_code)
 
 
 UPDATE #customer_bal
 SET avg_days_pay = ROUND(days_pay/num_inv_paid, 0),
 avg_days_overdue = ROUND(days_overdue/num_inv_paid, 0)
 WHERE num_inv_paid > 0
 
 IF EXISTS ( SELECT customer_code
 FROM arinpchg
 WHERE trx_type <= 2031
 AND hold_flag = 0 )
 BEGIN
 
 CREATE TABLE #unposted_trx
 (
 customer_code varchar(8),
 amt_inv_unp_home float,
 amt_inv_unp_oper float,
 exists_flag smallint
 )
 
 INSERT #unposted_trx
 SELECT customer_code, 
 SUM(SIGN(SIGN(2031.5-trx_type)+1)*SIGN(1-hold_flag)*
 ROUND(amt_net * ( SIGN(1 + SIGN(rate_home))*(rate_home) + (SIGN(ABS(SIGN(ROUND(rate_home,6))))/(rate_home + SIGN(1 - ABS(SIGN(ROUND(rate_home,6)))))) * SIGN(SIGN(rate_home) - 1) ), @precision_home)),
 SUM(SIGN(SIGN(2031.5-trx_type)+1)*SIGN(1-hold_flag)*
 ROUND(amt_net * ( SIGN(1 + SIGN(rate_oper))*(rate_oper) + (SIGN(ABS(SIGN(ROUND(rate_oper,6))))/(rate_oper + SIGN(1 - ABS(SIGN(ROUND(rate_oper,6)))))) * SIGN(SIGN(rate_oper) - 1) ), @precision_oper)),
 0
 FROM arinpchg
 WHERE customer_code = @customer_code
 GROUP BY customer_code
 
 
 UPDATE #unposted_trx
 SET exists_flag = 1
 FROM #customer_bal
 WHERE #customer_bal.customer_code = #unposted_trx.customer_code
 
 
 INSERT #customer_bal
 SELECT customer_code, 0.0, 0.0, 0.0, 0.0, 
 amt_inv_unp_home, amt_inv_unp_oper,0.0,0.0,
 0, 0, 0, 0, 0, 0, 0, 0
 FROM #unposted_trx
 WHERE #unposted_trx.exists_flag = 0
 
 
 UPDATE #customer_bal
 SET amt_inv_unp_home = #unposted_trx.amt_inv_unp_home,
 amt_inv_unp_oper = #unposted_trx.amt_inv_unp_oper
 FROM #unposted_trx
 WHERE #customer_bal.customer_code = #unposted_trx.customer_code
 AND #unposted_trx.exists_flag = 1
 
 DROP TABLE #unposted_trx
 
 END
 
  
 UPDATE #customer_bal
 SET exists_flag = 1
 FROM aractcus
 WHERE aractcus.customer_code = #customer_bal.customer_code
 
 
 UPDATE aractcus
 SET last_trx_time = 0

 
 UPDATE aractcus
 SET amt_balance = bal.amt_balance_home,
 amt_on_acct = bal.amt_on_acct_home,
 amt_inv_unposted = bal.amt_inv_unp_home,
 amt_balance_oper = bal.amt_balance_oper,
 amt_on_acct_oper = bal.amt_on_acct_oper,
 amt_inv_unp_oper = bal.amt_inv_unp_oper,
 num_inv = bal.num_inv,
 num_inv_paid = bal.num_inv_paid,
 num_overdue_pyt = bal.num_overdue_pyt,
 avg_days_overdue = bal.avg_days_overdue,
 avg_days_pay = bal.avg_days_pay,
 last_trx_time = 1
 FROM #customer_bal bal
 WHERE bal.customer_code = aractcus.customer_code
 AND exists_flag = 1

 
 INSERT aractcus ( 
 customer_code, date_last_inv, date_last_cm,
 date_last_adj, date_last_wr_off, date_last_pyt,
 date_last_nsf, date_last_fin_chg, date_last_late_chg,
 date_last_comm, amt_last_inv, amt_last_cm,
 amt_last_adj, amt_last_wr_off, amt_last_pyt,
 amt_last_nsf, amt_last_fin_chg, amt_last_late_chg,
 amt_last_comm, amt_age_bracket1, amt_age_bracket2,
 amt_age_bracket3, amt_age_bracket4, amt_age_bracket5,
 amt_age_bracket6, amt_on_order, amt_inv_unposted,
 last_inv_doc, last_cm_doc, last_adj_doc,
 last_wr_off_doc, last_pyt_doc, last_nsf_doc,
 last_fin_chg_doc, last_late_chg_doc, high_amt_ar,
 high_amt_inv, high_date_ar, high_date_inv,
 num_inv, num_inv_paid, num_overdue_pyt,
 avg_days_pay, avg_days_overdue, last_trx_time,
 amt_balance, amt_on_acct, amt_age_b1_oper, 
 amt_age_b2_oper, amt_age_b3_oper, amt_age_b4_oper, 
 amt_age_b5_oper, amt_age_b6_oper, amt_on_order_oper, 
 amt_inv_unp_oper, high_amt_ar_oper, high_amt_inv_oper, 
 amt_balance_oper, amt_on_acct_oper, last_inv_cur,
 last_cm_cur, last_adj_cur, last_wr_off_cur,
 last_pyt_cur, last_nsf_cur, last_fin_chg_cur,
 last_late_chg_cur, last_age_upd_date
 ) 
 SELECT customer_code, 0, 0,
 0, 0, 0,
 0, 0, 0,
 0, 0.0, 0.0,
 0.0, 0.0, 0.0,
 0.0, 0.0, 0.0,
 0.0, 0.0, 0.0,
 0.0, 0.0, 0.0,
 0.0, amt_on_order_home, amt_inv_unp_home,
 ' ', ' ', ' ', 
 ' ', ' ', ' ',
 ' ', ' ', 0.0,
 0.0, 0, 0,
 num_inv, num_inv_paid, num_overdue_pyt,
 avg_days_pay, avg_days_overdue, 1,
 amt_balance_home, amt_on_acct_home, 0.0,
 0.0, 0.0, 0.0,
 0.0, 0.0, amt_on_order_oper,
 amt_inv_unp_oper, 0.0, 0.0,
 amt_balance_oper, amt_on_acct_oper, ' ',
 ' ', ' ', ' ',
 ' ', ' ', ' ',
 ' ', 0 
 FROM #customer_bal
 WHERE exists_flag = 0

 
 DELETE aractcus
 WHERE last_trx_time = 0 
 AND customer_code = @customer_code
 AND customer_code NOT IN ( SELECT payer_cust_code FROM artrxage 
 WHERE payer_cust_code NOT IN (
 SELECT customer_code FROM #customer_bal )
 )

 DROP TABLE #customer_bal

END


/**/                                              
GO
GRANT EXECUTE ON  [dbo].[ARCBUPDateCustActivity_SP] TO [public]
GO
