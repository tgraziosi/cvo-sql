SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[apchkrpr_sp]  @to_white_paper smallint,  @void_chks smallint,  @void_from_check int, 
 @void_thru_check int,  @start_check int,  @user_id smallint,  @cash_acct_code varchar(32), 
 @process_group_num varchar(16),  @lines_per_check smallint,  @debug_level smallint = 0 
AS  DECLARE  @print_batch_num int,  @result int,  @check_num_mask varchar(16),  @check_start_col smallint, 
 @check_length smallint,  @trx_ctrl_num varchar(16),  @sys_date int,  @company_code varchar(8), 
 @check_numint int,  @voids_exist smallint,  @last_check int,  @start_check_masked varchar(16), 
 @last_check_masked varchar(16) IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + ' ' + 'tmp\\apchkrpr.sp' + ', line ' + STR( 61, 5 ) + ' -- ENTRY: ' 
SELECT @voids_exist = 0 IF NOT EXISTS (SELECT * FROM #check_header)  BEGIN  DROP TABLE #check_header 
 RETURN -4  END CREATE TABLE #apchkstb 
(
 vendor_code varchar(12),  check_num varchar(16),  cash_acct_code varchar(32),  print_batch_num int, 
 payment_num varchar(16),  payment_type smallint,  print_acct_num smallint,  payment_memo smallint, 
 voucher_classification smallint,  voucher_comment smallint,  voucher_memo smallint, 
 voucher_num varchar(16),  amt_paid float,  amt_disc_taken float,  amt_net float, 
 invoice_num varchar(16),  invoice_date int,  voucher_date_due int,  description varchar(60), 
 voucher_classify varchar(8) ,  voucher_internal_memo varchar(40),  comment_line varchar(40), 
 posted_flag smallint,  printed_flag smallint,  overflow_flag smallint,  nat_cur_code varchar(8), 
 lines smallint,  history_flag smallint 
)
IF (@@error != 0)  RETURN -1 CREATE TABLE #apexpdst 
(
 vendor_code varchar(12),  check_num varchar(16),  cash_acct_code varchar(32),  print_batch_num int, 
 payment_num varchar(16),  payment_type smallint,  voucher_num varchar(16),  sequence_id int, 
 amt_dist float,  gl_exp_acct varchar(32),  posted_flag smallint,  printed_flag smallint, 
 overflow_flag smallint) IF (@@error != 0)  RETURN -1    CREATE TABLE #apvohist 
(
 trx_ctrl_num varchar(16),  invoice_num varchar(16),  invoice_date datetime NULL, 
 voucher_num varchar(16),  voucher_date_due datetime NULL,  amt_paid float,  amt_disc_taken float, 
 amt_net float,  doc_ctrl_num varchar(16),  description varchar(60),  payment_type smallint, 
 symbol varchar(8),  curr_precision smallint,  voucher_internal_memo varchar(40), 
 comment_line varchar(40),  voucher_classify varchar(8),  trx_link varchar(16) 
)
IF (@@error != 0)  RETURN -1 CREATE TABLE #aptrx_work  (  trx_ctrl_num varchar(16), 
 doc_ctrl_num varchar(16),  batch_code varchar(16),  date_applied int,  date_doc int, 
 vendor_code varchar(12),  pay_to_code varchar(8),  cash_acct_code varchar(32),  payment_code varchar(8), 
 void_flag smallint,  user_id smallint,  doc_desc varchar(40),  company_code varchar(8), 
 nat_cur_code varchar(8)  ) IF (@@error != 0)  RETURN -1    BEGIN TRAN PRINTBATCHNUM 
 UPDATE apnumber  SET next_print_batch_num = next_print_batch_num + 1  IF (@@error != 0) 
 BEGIN  ROLLBACK TRAN PRINTBATCHNUM  RETURN -1  END  SELECT @print_batch_num = (next_print_batch_num - 1) 
 FROM apnumber  IF (@@error != 0)  BEGIN  ROLLBACK TRAN PRINTBATCHNUM  RETURN -1 
 END COMMIT TRAN PRINTBATCHNUM UPDATE #check_header SET print_batch_num = @print_batch_num 
IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + ' ' + 'tmp\\apchkrpr.sp' + ', line ' + STR( 126, 5 ) + ' -- MSG: ' + 'Print batch num is ' + str(@print_batch_num) 
   SELECT @check_num_mask = check_num_mask,  @check_start_col = check_start_col, 
 @check_length = check_length FROM apcash WHERE cash_acct_code = @cash_acct_code 
   EXEC @result = appdate_sp @sys_date OUTPUT    SELECT @company_code = company_code FROM glco 
CREATE TABLE #apvoidchecks (check_num varchar(16)) SELECT @check_numint = @void_from_check 
WHILE (@check_numint <= @void_thru_check) BEGIN  INSERT #apvoidchecks  VALUES ( SUBSTRING(@check_num_mask, 1, 
 @check_start_col -1) + RIGHT('0000000000000000' +  RTRIM(LTRIM(STR(@check_numint, 16, 0))), 
 @check_length))  SELECT @check_numint = @check_numint + 1 END DELETE #apvoidchecks 
FROM #apvoidchecks, appyhdr WHERE #apvoidchecks.check_num = appyhdr.doc_ctrl_num 
AND appyhdr.cash_acct_code = @cash_acct_code     INSERT #aptrx_work (  trx_ctrl_num, 
 doc_ctrl_num,  batch_code,  date_applied,  date_doc,  vendor_code,  pay_to_code, 
 cash_acct_code,  payment_code,  void_flag,  user_id,  doc_desc,  company_code,  nat_cur_code) 
 SELECT  check_num,  check_num,  ' ',  @sys_date,  0,  ' ',  ' ',  @cash_acct_code, 
 'VDSPCHK',  4,  @user_id,  'Spoiled Check',  @company_code,  ''  FROM #apvoidchecks 
 IF @@rowcount > 0  SELECT @voids_exist = 1 DROP TABLE #apvoidchecks      UPDATE #aptrx_work 
 SET trx_ctrl_num = #check_header.trx_ctrl_num,  batch_code = #check_header.batch_code, 
 date_applied = #check_header.date_applied,  date_doc = #check_header.date_doc, 
 vendor_code = #check_header.vendor_code,  pay_to_code = #check_header.pay_to_code, 
 void_flag = 2,  doc_desc = #check_header.trx_desc,  payment_code = #check_header.payment_code 
 FROM #aptrx_work, #check_header  WHERE #aptrx_work.doc_ctrl_num = #check_header.doc_ctrl_num 
   INSERT #apchkstb  (  vendor_code,  check_num,  cash_acct_code,  print_batch_num, 
 payment_num,  payment_type,  print_acct_num,  payment_memo,  voucher_classification, 
 voucher_comment,  voucher_memo,  voucher_num,  amt_paid,  amt_disc_taken,  amt_net, 
 invoice_num,  invoice_date,  voucher_date_due,  description,  voucher_classify, 
 voucher_internal_memo,  comment_line,  posted_flag,  printed_flag,  overflow_flag, 
 nat_cur_code,  lines,  history_flag  ) SELECT a.vendor_code,  a.check_num,  a.cash_acct_code, 
 b.print_batch_num,  a.payment_num,  a.payment_type,  a.print_acct_num,  a.payment_memo, 
 a.voucher_classification,  a.voucher_comment,  a.voucher_memo,  a.voucher_num,  a.amt_paid, 
 a.amt_disc_taken,  a.amt_net,  a.invoice_num,  a.invoice_date,  a.voucher_date_due, 
 a.description,  a.voucher_classify,  a.voucher_internal_memo,  a.comment_line,  a.posted_flag, 
 a.printed_flag,  a.overflow_flag,  a.nat_cur_code,  1,  history_flag FROM apchkstb a,#check_header b 
WHERE a.payment_num = b.trx_ctrl_num INSERT #apexpdst (  vendor_code,  check_num, 
 cash_acct_code,  print_batch_num,  payment_num,  payment_type,  voucher_num,  sequence_id, 
 amt_dist,  gl_exp_acct,  posted_flag,  printed_flag,  overflow_flag) SELECT  a.vendor_code, 
 a.check_num,  a.cash_acct_code,  a.print_batch_num,  a.payment_num,  a.payment_type, 
 a.voucher_num,  a.sequence_id,  a.amt_dist,  a.gl_exp_acct,  a.posted_flag,  a.printed_flag, 
 a.overflow_flag FROM apexpdst a,#check_header WHERE a.payment_num = #check_header.trx_ctrl_num 
   BEGIN  EXEC @result = apvohist_sp @debug_level  IF (@result != 0)  RETURN @result 
END EXEC @result = apchklns_sp 1,  1,  1,  1,  1,  @debug_level IF (@result != 0) 
 return @result EXEC @result = apchknmb_sp 1,  @cash_acct_code,  @to_white_paper, 
 @start_check,  @last_check OUTPUT,  @check_num_mask,  @check_start_col,  @check_length, 
 @voids_exist OUTPUT,  @lines_per_check,  @debug_level IF @result != 0  RETURN @result 
   UPDATE #check_header SET #check_header.pay_to_name = apvnd_vw.pay_to_name,  #check_header.addr1 = apvnd_vw.addr1, 
 #check_header.addr2 = apvnd_vw.addr2,  #check_header.addr3 = apvnd_vw.addr3,  #check_header.addr4 = apvnd_vw.addr4, 
 #check_header.addr5 = apvnd_vw.addr5,  #check_header.addr6 = apvnd_vw.addr6 FROM #check_header, apvnd_vw 
WHERE #check_header.vendor_code = apvnd_vw.vendor_code AND #check_header.pay_to_code = apvnd_vw.pay_to_code 
IF (@@error != 0)  RETURN -1     SELECT @start_check_masked = SUBSTRING(@check_num_mask, 1, 
 @check_start_col -1) + RIGHT('0000000000000000' +  RTRIM(LTRIM(STR(@start_check, 16, 0))), 
 @check_length)  SELECT @last_check_masked = SUBSTRING(@check_num_mask, 1,  @check_start_col -1) + RIGHT('0000000000000000' + 
 RTRIM(LTRIM(STR(@last_check, 16, 0))),  @check_length) BEGIN TRAN UPDPERM    IF EXISTS(SELECT * FROM apchecks_vw 
 WHERE cash_acct_code = @cash_acct_code  AND doc_ctrl_num BETWEEN @start_check_masked AND @last_check_masked) 
 BEGIN  ROLLBACK TRAN UPDPERM  DROP TABLE #apchkstb  DROP TABLE #apexpdst  RETURN -5 
 END IF EXISTS(SELECT * FROM apinppyt  WHERE trx_type = 4111  AND cash_acct_code = @cash_acct_code 
 AND doc_ctrl_num BETWEEN @start_check_masked AND @last_check_masked)  BEGIN  SELECT @result = -6 
 END  UPDATE apcash  SET next_check_num = @last_check + 1  WHERE cash_acct_code = @cash_acct_code 
 AND next_check_num BETWEEN @start_check AND @last_check  IF (@@error != 0)  BEGIN 
 ROLLBACK TRAN UPDPERM  RETURN -1  END  UPDATE apinppyt  SET printed_flag = 1,  apinppyt.doc_ctrl_num = #check_header.doc_ctrl_num, 
 apinppyt.date_doc = #check_header.date_doc,  apinppyt.print_batch_num = @print_batch_num, 
 apinppyt.payee_name = #check_header.addr1  FROM apinppyt, #check_header  WHERE apinppyt.trx_ctrl_num = #check_header.trx_ctrl_num 
 AND apinppyt.posted_flag = -1  AND apinppyt.process_group_num = @process_group_num 
 IF (@@error != 0)  BEGIN  ROLLBACK TRAN UPDPERM  RETURN -1  END  DELETE apchkstb 
 FROM apchkstb,#apchkstb  WHERE apchkstb.payment_num = #apchkstb.payment_num  INSERT apchkstb ( 
 vendor_code,  check_num,  cash_acct_code,  print_batch_num,  payment_num,  payment_type, 
 print_acct_num,  payment_memo,  voucher_classification,  voucher_comment,  voucher_memo, 
 voucher_num,  amt_paid,  amt_disc_taken,  amt_net,  invoice_num,  invoice_date, 
 voucher_date_due,  description,  voucher_classify,  voucher_internal_memo,  comment_line, 
 posted_flag,  printed_flag,  overflow_flag,  nat_cur_code,  history_flag)  SELECT 
 vendor_code,  check_num,  cash_acct_code,  print_batch_num,  payment_num,  payment_type, 
 print_acct_num,  payment_memo,  voucher_classification,  voucher_comment,  voucher_memo, 
 voucher_num,  amt_paid,  amt_disc_taken,  amt_net,  invoice_num,  invoice_date, 
 voucher_date_due,  description,  voucher_classify,  voucher_internal_memo,  comment_line, 
 posted_flag,  printed_flag,  overflow_flag,  nat_cur_code,  history_flag  FROM #apchkstb 
 IF (@@error != 0)  BEGIN  ROLLBACK TRAN UPDPERM  RETURN -1  END  DELETE apexpdst 
 FROM apexpdst,#apexpdst  WHERE apexpdst.payment_num = #apexpdst.payment_num  INSERT apexpdst ( 
 vendor_code,  check_num,  cash_acct_code,  print_batch_num,  payment_num,  payment_type, 
 voucher_num,  sequence_id,  amt_dist,  gl_exp_acct,  posted_flag,  printed_flag, 
 overflow_flag)  SELECT  vendor_code,  check_num,  cash_acct_code,  print_batch_num, 
 payment_num,  payment_type,  voucher_num,  sequence_id,  amt_dist,  gl_exp_acct, 
 posted_flag,  printed_flag,  overflow_flag  FROM #apexpdst  IF (@@error != 0)  BEGIN 
 ROLLBACK TRAN UPDPERM  RETURN -1  END  IF (@voids_exist = 1)  BEGIN  DELETE #aptrx_work 
 FROM apvchdr,#aptrx_work  WHERE apvchdr.doc_ctrl_num = #aptrx_work.doc_ctrl_num 
 AND apvchdr.cash_acct_code = #aptrx_work.cash_acct_code  INSERT apvchdr (  trx_ctrl_num, 
 doc_ctrl_num,  batch_code,  date_applied,  date_doc,  date_entered,  vendor_code, 
 pay_to_code,  cash_acct_code,  payment_code,  state_flag,  void_flag,  amt_net, 
 amt_discount,  user_id,  print_batch_num,  process_ctrl_num,  currency_code  )  SELECT 
 trx_ctrl_num,  doc_ctrl_num,  batch_code,  date_applied,  date_doc,  @sys_date, 
 vendor_code,  pay_to_code,  cash_acct_code,  payment_code,  -1,  void_flag,  0.0, 
 0.0,  user_id,  @print_batch_num,  @process_group_num,  nat_cur_code  FROM #aptrx_work 
 IF (@@error != 0)  BEGIN  ROLLBACK TRAN UPDPERM  RETURN -1  END  END     UPDATE apchkdsb 
 SET apchkdsb.check_num = #check_header.doc_ctrl_num,  apchkdsb.cash_acct_code = @cash_acct_code 
 FROM apchkdsb,#check_header  WHERE apchkdsb.check_ctrl_num = #check_header.trx_ctrl_num 
COMMIT TRAN UPDPERM DROP TABLE #apchkstb DROP TABLE #apexpdst DROP TABLE #aptrx_work 
IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + ' ' + 'tmp\\apchkrpr.sp' + ', line ' + STR( 648, 5 ) + ' -- EXIT: ' 
RETURN @result 
GO
GRANT EXECUTE ON  [dbo].[apchkrpr_sp] TO [public]
GO
