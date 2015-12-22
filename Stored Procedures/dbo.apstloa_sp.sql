SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[apstloa_sp]  @vendor_code varchar(12),  @pay_to_code varchar(8),  @user_id smallint, 
 @company_code varchar(8),  @date_applied int,  @settlement_ctrl_num varchar(16), 
 @approval_code varchar(8),  @batch_code varchar(16) AS DECLARE  @current_date int, 
 @trx_ctrl_num varchar(16) EXEC appdate_sp @current_date OUTPUT CREATE TABLE #onacct (trx_ctrl_num varchar(16), 
 doc_ctrl_num varchar(16),  date_doc int,  date_applied int,  payment_code varchar(8), 
 cash_acct_code varchar(32),  amt_on_acct float,  nat_cur_code varchar(8),  rate_home float, 
 rate_oper float,  rate_type_home varchar(8),  rate_type_oper varchar(8))    EXEC apldoa_sp @vendor_code, "", 0 
   DELETE #onacct FROM #onacct a, apinppyt p WHERE p.trx_type = 4111 AND p.payment_type in ( 2, 3 ) 
AND a.doc_ctrl_num = p.doc_ctrl_num AND a.cash_acct_code = p.cash_acct_code    DELETE #onacct 
FROM #onacct a, #apinppyt3450 c WHERE a.doc_ctrl_num = c.doc_ctrl_num AND a.cash_acct_code = c.cash_acct_code 
INSERT #apinppyt3450 (  timestamp,  trx_ctrl_num,  trx_type,  doc_ctrl_num,  trx_desc, 
 batch_code,  cash_acct_code,  date_entered,  date_applied,  date_doc,  vendor_code, 
 pay_to_code,  approval_code,  payment_code,  payment_type,  amt_payment,  amt_on_acct, 
 posted_flag,  printed_flag,  hold_flag,  approval_flag,  gen_id,  user_id,  void_type, 
 amt_disc_taken,  print_batch_num,  company_code,  process_group_num,  nat_cur_code, 
 rate_type_home,  rate_type_oper,  rate_home,  rate_oper,  payee_name,  settlement_ctrl_num ) 
SELECT  NULL ,  "" ,  4111 ,  #onacct.doc_ctrl_num,  "" ,  @batch_code,  #onacct.cash_acct_code, 
 @current_date ,  @date_applied ,  #onacct.date_doc,  @vendor_code,  @pay_to_code, 
 @approval_code,  #onacct.payment_code,  0,  0,   0,   0 ,  2 ,  0 ,  0 ,  0 ,  @user_id, 
 0 ,  0.0 ,  0 ,  @company_code,  NULL ,  #onacct.nat_cur_code,  #onacct.rate_type_home, 
 #onacct.rate_type_oper,  #onacct.rate_home,  #onacct.rate_oper,  NULL ,  @settlement_ctrl_num 
FROM  #onacct ORDER BY cash_acct_code    UPDATE #apinppyt3450 SET payment_type = case appyhdr.payment_type 
 WHEN 1 THEN 2  WHEN 3 THEN 3  END,  amt_payment= appyhdr.amt_on_acct,  amt_on_acct= appyhdr.amt_on_acct 
FROM #apinppyt3450 #apinppyt3450, appyhdr appyhdr WHERE #apinppyt3450.doc_ctrl_num = appyhdr.doc_ctrl_num 
AND #apinppyt3450.cash_acct_code = appyhdr.cash_acct_code    WHILE (1=1) BEGIN  SET ROWCOUNT 0 
 EXEC apnewnum_sp 4111, "", @trx_ctrl_num OUTPUT  SET ROWCOUNT 1  UPDATE #apinppyt3450 
 SET trx_ctrl_num = @trx_ctrl_num  WHERE trx_ctrl_num = ""  IF (@@rowcount = 0)  BREAK 
END SET ROWCOUNT 0    UPDATE #avail_onacct SET in_use=1 FROM #avail_onacct a, #apinppyt3450 b 
WHERE a.doc_ctrl_num=b.doc_ctrl_num AND a.cash_acct_code=b.cash_acct_code DROP TABLE #onacct 
GO
GRANT EXECUTE ON  [dbo].[apstloa_sp] TO [public]
GO
