SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[apvesub2_sp] @error_level smallint, @debug_level smallint = 0 AS 
DECLARE @credit_invoice_flag smallint IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + " " + "tmp\\apvesub2.sp" + ", line " + STR( 41, 5 ) + " -- ENTRY: " 
IF (SELECT err_type FROM apedterr WHERE err_code = 11210) <= @error_level BEGIN  IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + " " + "tmp\\apvesub2.sp" + ", line " + STR( 45, 5 ) + " -- MSG: " + "Check if date aging <= 0" 
     INSERT #ewerror  SELECT 4000,  11210,  "",  "",  date_aging,  0,  3,  trx_ctrl_num, 
 sequence_id,  "",  0  FROM #apvovage  WHERE date_aging <= 0 END IF (SELECT err_type FROM apedterr WHERE err_code = 11211) <= @error_level 
BEGIN  IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + " " + "tmp\\apvesub2.sp" + ", line " + STR( 69, 5 ) + " -- MSG: " + "Check if date aging matches header or header is 0" 
     INSERT #ewerror  SELECT 4000,  11211,  "",  "",  b.date_aging,  0.0,  3,  b.trx_ctrl_num, 
 b.sequence_id,  "",  0  FROM #apvovage b, #apvovchg c  WHERE b.trx_ctrl_num = c.trx_ctrl_num 
 AND c.date_aging != 0  AND b.date_aging != c.date_aging END SELECT @credit_invoice_flag = credit_invoice_flag FROM apco 
IF @credit_invoice_flag = 0 BEGIN IF (SELECT err_type FROM apedterr WHERE err_code = 11220) <= @error_level 
BEGIN  IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + " " + "tmp\\apvesub2.sp" + ", line " + STR( 98, 5 ) + " -- MSG: " + "Check if amt_due < 0" 
     INSERT #ewerror  SELECT 4000,  11220,  "",  "",  0,  amt_due,  4,  trx_ctrl_num, 
 sequence_id,  "",  0  FROM #apvovage  WHERE ((amt_due) < (0.0) - 0.0000001) END 
END IF (SELECT err_type FROM apedterr WHERE err_code = 11230) <= @error_level BEGIN 
 IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + " " + "tmp\\apvesub2.sp" + ", line " + STR( 122, 5 ) + " -- MSG: " + "Check if sum of aging = voucher amt_net" 
     INSERT #ewerror  SELECT 4000,  11230,  "",  "",  0,  sum(b.amt_due),  4,  b.trx_ctrl_num, 
 0,  "",  0  FROM #apvovage b, #apvovchg c  WHERE b.trx_ctrl_num = c.trx_ctrl_num 
 GROUP BY b.trx_ctrl_num  HAVING (ABS((max(c.amt_net))-(sum(b.amt_due))) > 0.0000001) 
END IF (SELECT err_type FROM apedterr WHERE err_code = 11320) <= @error_level BEGIN 
 IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + " " + "tmp\\apvesub2.sp" + ", line " + STR( 148, 5 ) + " -- MSG: " + "validate cash accounts exist in glchart" 
 INSERT #ewerror  SELECT 4000,  11320,  cash_acct_code,  "",  0,  0.0,  1,  trx_ctrl_num, 
 0,  "",  0  FROM #apvovtmp  WHERE cash_acct_code NOT IN (SELECT account_code FROM glchart) 
 AND cash_acct_code != "" END IF (SELECT err_type FROM apedterr WHERE err_code = 11321) <= @error_level 
BEGIN  IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + " " + "tmp\\apvesub2.sp" + ", line " + STR( 169, 5 ) + " -- MSG: " + "check if cash account is inactive" 
 INSERT #ewerror  SELECT 4000,  11321,  b.cash_acct_code,  "",  0,  0.0,  1,  b.trx_ctrl_num, 
 0,  "",  0  FROM #apvovtmp b, glchart c  WHERE b.cash_acct_code = c.account_code 
 AND c.inactive_flag = 1 END IF (SELECT err_type FROM apedterr WHERE err_code = 11322) <= @error_level 
BEGIN  IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + " " + "tmp\\apvesub2.sp" + ", line " + STR( 190, 5 ) + " -- MSG: " + "check if account is invalid for the apply date" 
 INSERT #ewerror  SELECT 4000,  11322,  b.cash_acct_code,  "",  0,  0.0,  1,  b.trx_ctrl_num, 
 0,  "",  0  FROM #apvovtmp b, glchart c  WHERE b.cash_acct_code = c.account_code 
 AND ((b.date_applied < c.active_date  AND c.active_date != 0)  OR (b.date_applied > c.inactive_date 
 AND c.inactive_date != 0)) END IF (SELECT err_type FROM apedterr WHERE err_code = 11324) <= @error_level 
BEGIN  IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + " " + "tmp\\apvesub2.sp" + ", line " + STR( 216, 5 ) + " -- MSG: " + "check if on-account account is inactive" 
 INSERT #ewerror  SELECT 4000,  11324,  c.on_acct_code,  "",  0,  0.0,  1,  b.trx_ctrl_num, 
 0,  "",  0  FROM #apvovtmp b, appymeth c, glchart d  WHERE b.payment_code = c.payment_code 
 AND c.on_acct_code = d.account_code  AND d.inactive_flag = 1 END IF (SELECT err_type FROM apedterr WHERE err_code = 11325) <= @error_level 
BEGIN  IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + " " + "tmp\\apvesub2.sp" + ", line " + STR( 239, 5 ) + " -- MSG: " + "check if on-account account is invalid for the apply date" 
 INSERT #ewerror  SELECT 4000,  11325,  c.on_acct_code,  "",  0,  0.0,  1,  b.trx_ctrl_num, 
 0,  "",  0  FROM #apvovtmp b, appymeth c, glchart d  WHERE b.payment_code = c.payment_code 
 AND c.on_acct_code = d.account_code  AND ((b.date_applied < d.active_date  AND d.active_date != 0) 
 OR (b.date_applied > d.inactive_date  AND d.inactive_date != 0)) END IF (SELECT err_type FROM apedterr WHERE err_code = 11250) <= @error_level 
BEGIN  IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + " " + "tmp\\apvesub2.sp" + ", line " + STR( 267, 5 ) + " -- MSG: " + "Check if date applied <= 0" 
     INSERT #ewerror  SELECT 4000,  11250,  "",  "",  date_applied,  0.0,  3,  trx_ctrl_num, 
 0,  "",  0  FROM #apvovtmp  WHERE date_applied <= 0 END IF (SELECT err_type FROM apedterr WHERE err_code = 11260) <= @error_level 
BEGIN  IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + " " + "tmp\\apvesub2.sp" + ", line " + STR( 290, 5 ) + " -- MSG: " + "Check if applied to future period" 
     INSERT #ewerror  SELECT 4000,  11260,  "",  "",  b.date_applied,  0.0,  3, 
 b.trx_ctrl_num,  0,  "",  0  FROM #apvovtmp b, apco c  WHERE b.date_applied > c.period_end_date 
END IF (SELECT err_type FROM apedterr WHERE err_code = 11270) <= @error_level BEGIN 
 IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + " " + "tmp\\apvesub2.sp" + ", line " + STR( 313, 5 ) + " -- MSG: " + "Check if applied to prior period" 
     INSERT #ewerror  SELECT 4000,  11270,  "",  "",  b.date_applied,  0.0,  3, 
 b.trx_ctrl_num,  0,  "",  0  FROM #apvovtmp b, glprd c, apco d  WHERE b.date_applied < c.period_start_date 
 AND c.period_end_date = d.period_end_date END IF (SELECT err_type FROM apedterr WHERE err_code = 11284) <= @error_level 
BEGIN  IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + " " + "tmp\\apvesub2.sp" + ", line " + STR( 337, 5 ) + " -- MSG: " + "Check if applied period exists" 
     SELECT trx_ctrl_num, sequence_id = 0, date_applied, flag = 0  INTO #check_applied 
 FROM #apvovtmp  UPDATE #check_applied  SET flag = 1  FROM #check_applied a, glprd b 
 WHERE a.date_applied BETWEEN b.period_start_date AND b.period_end_date  INSERT #ewerror 
 SELECT 4000,  11284,  "",  "",  date_applied,  0.0,  3,  trx_ctrl_num,  sequence_id, 
 "",  0  FROM #check_applied  WHERE flag = 0  DROP TABLE #check_applied END IF (SELECT err_type FROM apedterr WHERE err_code = 11280) <= @error_level 
BEGIN  IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + " " + "tmp\\apvesub2.sp" + ", line " + STR( 374, 5 ) + " -- MSG: " + "Check if date applied in valid apco range" 
     INSERT #ewerror  SELECT 4000,  11280,  "",  "",  b.date_applied,  0.0,  3, 
 b.trx_ctrl_num,  0,  "",  0  FROM #apvovtmp b, #apvovchg c, apco d  WHERE b.trx_ctrl_num = c.trx_ctrl_num 
 AND abs(b.date_applied - c.date_entered) > d.date_range_verify END IF (SELECT err_type FROM apedterr WHERE err_code = 11290) <= @error_level 
BEGIN  IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + " " + "tmp\\apvesub2.sp" + ", line " + STR( 399, 5 ) + " -- MSG: " + "Check if date doc <= 0" 
     INSERT #ewerror  SELECT 4000,  11290,  "",  "",  date_doc,  0.0,  3,  trx_ctrl_num, 
 0,  "",  0  FROM #apvovtmp  WHERE date_doc <= 0 END IF (SELECT err_type FROM apedterr WHERE err_code = 11300) <= @error_level 
BEGIN  IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + " " + "tmp\\apvesub2.sp" + ", line " + STR( 423, 5 ) + " -- MSG: " + "Check if vendor code is different from header" 
     INSERT #ewerror  SELECT 4000,  11300,  b.vendor_code,  "",  0,  0.0,  1,  b.trx_ctrl_num, 
 0,  "",  0  FROM #apvovtmp b, #apvovchg c  WHERE b.trx_ctrl_num = c.trx_ctrl_num 
 AND b.vendor_code != c.vendor_code END IF (SELECT err_type FROM apedterr WHERE err_code = 11310) <= @error_level 
BEGIN  IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + " " + "tmp\\apvesub2.sp" + ", line " + STR( 448, 5 ) + " -- MSG: " + "Check if code_1099 is valid" 
     INSERT #ewerror  SELECT 4000,  11310,  code_1099,  "",  0,  0.0,  1,  trx_ctrl_num, 
 0,  "",  0  FROM #apvovtmp  WHERE code_1099 NOT IN (SELECT code_1099 FROM appyt) 
 AND code_1099 != "" END IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + " " + "tmp\\apvesub2.sp" + ", line " + STR( 472, 5 ) + " -- EXIT: " 
RETURN 0 
GO
GRANT EXECUTE ON  [dbo].[apvesub2_sp] TO [public]
GO
