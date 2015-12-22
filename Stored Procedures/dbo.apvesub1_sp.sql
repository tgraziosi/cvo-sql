SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[apvesub1_sp] @error_level smallint, @debug_level smallint = 0 AS 
DECLARE @credit_invoice_flag smallint IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + " " + "tmp\\apvesub1.sp" + ", line " + STR( 45, 5 ) + " -- ENTRY: " 
IF (SELECT err_type FROM apedterr WHERE err_code = 11080) <= @error_level BEGIN  IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + " " + "tmp\\apvesub1.sp" + ", line " + STR( 50, 5 ) + " -- MSG: " + "Check if any tax sequence_id is less than 1" 
     INSERT #ewerror  SELECT 4000,  11080,  "",  "",  sequence_id,  0.0,  2,  trx_ctrl_num, 
 sequence_id,  "",  0  FROM #apvovtax  WHERE sequence_id < 1 END IF (SELECT err_type FROM apedterr WHERE err_code = 11090) <= @error_level 
BEGIN  IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + " " + "tmp\\apvesub1.sp" + ", line " + STR( 73, 5 ) + " -- MSG: " + "Check if any tax_type_code is blank" 
     INSERT #ewerror  SELECT 4000,  11090,  tax_type_code,  "",  0,  0.0,  1,  trx_ctrl_num, 
 sequence_id,  "",  0  FROM #apvovtax  WHERE tax_type_code = "" END IF (SELECT err_type FROM apedterr WHERE err_code = 11100) <= @error_level 
BEGIN  IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + " " + "tmp\\apvesub1.sp" + ", line " + STR( 96, 5 ) + " -- MSG: " + "Check if any tax_type_code is valid" 
     INSERT #ewerror  SELECT 4000,  11100,  tax_type_code,  "",  0,  0.0,  1,  trx_ctrl_num, 
 sequence_id,  "",  0  FROM #apvovtax  WHERE tax_type_code NOT IN (SELECT tax_type_code FROM aptxtype) 
END SELECT @credit_invoice_flag = credit_invoice_flag FROM apco IF @credit_invoice_flag = 0 
BEGIN IF (SELECT err_type FROM apedterr WHERE err_code = 11110) <= @error_level BEGIN 
 IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + " " + "tmp\\apvesub1.sp" + ", line " + STR( 123, 5 ) + " -- MSG: " + "Check if amt_taxable is negative" 
     INSERT #ewerror  SELECT 4000,  11110,  "",  "",  0,  amt_extended,   4,  trx_ctrl_num, 
 sequence_id,  "",  0  FROM #apvovcdt b   WHERE ((amt_extended) < (0.0) - 0.0000001)  
END END IF @credit_invoice_flag = 0 BEGIN IF (SELECT err_type FROM apedterr WHERE err_code = 11120) <= @error_level 
BEGIN  IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + " " + "tmp\\apvesub1.sp" + ", line " + STR( 149, 5 ) + " -- MSG: " + "Check if amt_gross is negative" 
     INSERT #ewerror  SELECT 4000,  11120,  "",  "",  0,  amt_gross,  4,  trx_ctrl_num, 
 sequence_id,  "",  0  FROM #apvovtax b  WHERE ((amt_gross) < (0.0) - 0.0000001) 
END END IF @credit_invoice_flag = 0 BEGIN IF (SELECT err_type FROM apedterr WHERE err_code = 11130) <= @error_level 
BEGIN  IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + " " + "tmp\\apvesub1.sp" + ", line " + STR( 176, 5 ) + " -- MSG: " + "Check if amt_tax is negative" 
     INSERT #ewerror  SELECT 4000,  11130,  "",  "",  0,  amt_tax,  4,  trx_ctrl_num, 
 sequence_id,  "",  0  FROM #apvovtax  WHERE ((amt_tax) < (0.0) - 0.0000001) END 
END IF @credit_invoice_flag = 0 BEGIN IF (SELECT err_type FROM apedterr WHERE err_code = 11140) <= @error_level 
BEGIN  IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + " " + "tmp\\apvesub1.sp" + ", line " + STR( 203, 5 ) + " -- MSG: " + "Check if amt_final_tax is negative" 
     INSERT #ewerror  SELECT 4000,  11140,  "",  "",  0,  amt_final_tax,  4,  trx_ctrl_num, 
 sequence_id,  "",  0  FROM #apvovtax  WHERE ((amt_final_tax) < (0.0) - 0.0000001) 
END END IF (SELECT err_type FROM apedterr WHERE err_code = 11150) <= @error_level 
BEGIN  IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + " " + "tmp\\apvesub1.sp" + ", line " + STR( 227, 5 ) + " -- MSG: " + "Check if any aging sequence_id is less than 1" 
     INSERT #ewerror  SELECT 4000,  11150,  "",  "",  sequence_id,  0.0,  2,  trx_ctrl_num, 
 sequence_id,  "",  0  FROM #apvovage  WHERE sequence_id < 1 END IF (SELECT err_type FROM apedterr WHERE err_code = 11160) <= @error_level 
BEGIN  IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + " " + "tmp\\apvesub1.sp" + ", line " + STR( 250, 5 ) + " -- MSG: " + "Check if date applied <= 0" 
     INSERT #ewerror  SELECT 4000,  11160,  "",  "",  date_applied,  0.0,  3,  trx_ctrl_num, 
 sequence_id,  "",  0  FROM #apvovage  WHERE date_applied <= 0 END IF (SELECT err_type FROM apedterr WHERE err_code = 11180) <= @error_level 
BEGIN  IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + " " + "tmp\\apvesub1.sp" + ", line " + STR( 273, 5 ) + " -- MSG: " + "Check if applied to future period" 
     INSERT #ewerror  SELECT 4000,  11180,  "",  "",  b.date_applied,  0.0,  3, 
 b.trx_ctrl_num,  b.sequence_id,  "",  0  FROM #apvovage b, apco c  WHERE b.date_applied > c.period_end_date 
END IF (SELECT err_type FROM apedterr WHERE err_code = 11170) <= @error_level BEGIN 
 IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + " " + "tmp\\apvesub1.sp" + ", line " + STR( 296, 5 ) + " -- MSG: " + "Check if applied to prior period" 
     INSERT #ewerror  SELECT 4000,  11170,  "",  "",  b.date_applied,  0.0,  3, 
 b.trx_ctrl_num,  b.sequence_id,  "",  0  FROM #apvovage b, glprd c, apco d  WHERE b.date_applied < c.period_start_date 
 AND c.period_end_date = d.period_end_date END IF (SELECT err_type FROM apedterr WHERE err_code = 11194) <= @error_level 
BEGIN  IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + " " + "tmp\\apvesub1.sp" + ", line " + STR( 319, 5 ) + " -- MSG: " + "Check if applied period exists" 
     SELECT trx_ctrl_num, sequence_id, date_applied, flag = 0  INTO #check_applied 
 FROM #apvovage  UPDATE #check_applied  SET flag = 1  FROM #check_applied a, glprd b 
 WHERE a.date_applied BETWEEN b.period_start_date AND b.period_end_date  INSERT #ewerror 
 SELECT 4000,  11194,  "",  "",  date_applied,  0.0,  3,  trx_ctrl_num,  sequence_id, 
 "",  0  FROM #check_applied  WHERE flag = 0  DROP TABLE #check_applied END IF (SELECT err_type FROM apedterr WHERE err_code = 11190) <= @error_level 
BEGIN  IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + " " + "tmp\\apvesub1.sp" + ", line " + STR( 356, 5 ) + " -- MSG: " + "Check if date applied in valid apco range" 
     INSERT #ewerror  SELECT 4000,  11190,  "",  "",  b.date_applied,  0.0,  3, 
 b.trx_ctrl_num,  b.sequence_id,  "",  0  FROM #apvovage b, apco c, #apvovchg d 
 WHERE b.trx_ctrl_num = d.trx_ctrl_num  AND abs(b.date_applied - d.date_entered) > c.date_range_verify 
END IF (SELECT err_type FROM apedterr WHERE err_code = 11200) <= @error_level BEGIN 
 IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + " " + "tmp\\apvesub1.sp" + ", line " + STR( 380, 5 ) + " -- MSG: " + "Check if date due <= 0" 
     INSERT #ewerror  SELECT 4000,  11200,  "",  "",  date_due,  0.0,  3,  trx_ctrl_num, 
 sequence_id,  "",  0  FROM #apvovage  WHERE date_due <= 0 END IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + " " + "tmp\\apvesub1.sp" + ", line " + STR( 407, 5 ) + " -- EXIT: " 
RETURN 0 
GO
GRANT EXECUTE ON  [dbo].[apvesub1_sp] TO [public]
GO
