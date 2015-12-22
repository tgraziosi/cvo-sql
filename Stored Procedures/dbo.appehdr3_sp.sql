SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO





CREATE PROCEDURE [dbo].[appehdr3_sp] @error_level smallint, @called_from smallint = 0, @debug_level smallint = 0
WITH RECOMPILE
AS

DECLARE @precision int

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "appehdr3.cpp" + ", line " + STR( 46, 5 ) + " -- ENTRY: "


	SELECT @precision = curr_precision
	FROM glcurr_vw a, glco b
	WHERE a.currency_code = b.home_currency




IF (SELECT err_type FROM apedterr WHERE err_code = 350) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "appehdr3.cpp" + ", line " + STR( 58, 5 ) + " -- MSG: " + "Check if amt_payment < 0"
	


      INSERT #ewerror
	  SELECT 4000,
		 	 350,
			 "",
			 "",
			 0,
			 amt_payment,
			 4,
			 trx_ctrl_num,
			 0,
			 "",
			 0
	  FROM #appyvpyt
	  WHERE ((amt_payment) < (0.0) - 0.0000001)
END



IF (SELECT err_type FROM apedterr WHERE err_code = 360) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "appehdr3.cpp" + ", line " + STR( 82, 5 ) + " -- MSG: " + "Check if amt_payment = sum of details + amt_on_acct"
	


      INSERT #ewerror
	  SELECT 4000,
			 360,
			 "",
			 "",
			 0,
			 b.amt_payment,
			 4,
			 b.trx_ctrl_num,
			 0,
			 "",
			 0
	  FROM #appyvpyt b, #appyvpdt c
	  WHERE b.trx_ctrl_num = c.trx_ctrl_num
	  GROUP BY b.trx_ctrl_num, b.amt_payment,b.amt_on_acct									
	  HAVING 
(ABS(((SIGN(b.amt_payment) * ROUND(ABS(b.amt_payment) + 0.0000001, @precision)))-((SIGN(SUM(c.amt_applied) + b.amt_on_acct) * ROUND(ABS(SUM(c.amt_applied) + b.amt_on_acct) + 0.0000001, @precision)))) > 0.0000001)
END




IF (SELECT err_type FROM apedterr WHERE err_code = 370) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "appehdr3.cpp" + ", line " + STR( 110, 5 ) + " -- MSG: " + "Check if amt_payment > amt max check for vendor"
	


      INSERT #ewerror
	  SELECT 4000,
			 370,
			 "",
			 "",
			 0,
			 b.amt_payment,
			 4,
			 b.trx_ctrl_num,
			 0,
			 "",
			 0
	  FROM #appyvpyt b, apvend c
	  WHERE b.vendor_code = c.vendor_code
	  AND ((b.amt_payment) > (c.amt_max_check) + 0.0000001)
	  AND ((c.amt_max_check) > (0.0) + 0.0000001)
END



IF (SELECT err_type FROM apedterr WHERE err_code = 380) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "appehdr3.cpp" + ", line " + STR( 136, 5 ) + " -- MSG: " + "Check if amt_on_acct < 0"
	


      INSERT #ewerror
	  SELECT 4000,
			 380,
			 "",
			 "",
			 0,
			 amt_on_acct,
			 4,
			 trx_ctrl_num,
			 0,
			 "",
			 0
	  FROM #appyvpyt 
	  WHERE ((amt_on_acct) < (0.0) - 0.0000001)
END



IF (SELECT err_type FROM apedterr WHERE err_code = 390) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "appehdr3.cpp" + ", line " + STR( 160, 5 ) + " -- MSG: " + "Check if amt_on_acct > 0"
	


      INSERT #ewerror
	  SELECT 4000,
			 390,
			 "",
			 "",
			 0,
			 amt_on_acct,
			 4,
			 trx_ctrl_num,
			 0,
			 "",
			 0
	  FROM #appyvpyt 
	  WHERE ((amt_on_acct) > (0.0) + 0.0000001)
END



IF (SELECT err_type FROM apedterr WHERE err_code = 410) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "appehdr3.cpp" + ", line " + STR( 184, 5 ) + " -- MSG: " + "Check if posted flag is valid"
	


      INSERT #ewerror
	  SELECT 4000,
			 410,
			 "",
			 "",
			 posted_flag,
			 0.0,
			 2,
			 trx_ctrl_num,
			 0,
			 "",
			 0
	  FROM #appyvpyt 
	  WHERE posted_flag NOT IN (0,-1)
END




IF (SELECT err_type FROM apedterr WHERE err_code = 400) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "appehdr3.cpp" + ", line " + STR( 209, 5 ) + " -- MSG: " + "Check if posted flag != 0"
	


      INSERT #ewerror
	  SELECT 4000,
			 400,
			 "",
			 "",
			 posted_flag,
			 0.0,
			 2,
			 trx_ctrl_num,
			 0,
			 "",
			 0
	  FROM #appyvpyt 
	  WHERE posted_flag != 0
END



IF (SELECT err_type FROM apedterr WHERE err_code = 420) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "appehdr3.cpp" + ", line " + STR( 233, 5 ) + " -- MSG: " + "Check if printed flag is valid"
	


      INSERT #ewerror
	  SELECT 4000,
			 420,
			 "",
			 "",
			 printed_flag,
			 0.0,
			 2,
			 trx_ctrl_num,
			 0,
			 "",
			 0
	  FROM #appyvpyt 
	  WHERE printed_flag NOT IN (-1,0,1,2,4)	
END


IF (SELECT err_type FROM apedterr WHERE err_code = 440) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "appehdr3.cpp" + ", line " + STR( 256, 5 ) + " -- MSG: " + "Check if hold flag is valid"
	


      INSERT #ewerror
	  SELECT 4000,
			 440,
			 "",
			 "",
			 hold_flag,
			 0.0,
			 2,
			 trx_ctrl_num,
			 0,
			 "",
			 0
	  FROM #appyvpyt 
	  WHERE hold_flag NOT IN (0,1)
END


IF (SELECT err_type FROM apedterr WHERE err_code = 430) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "appehdr3.cpp" + ", line " + STR( 279, 5 ) + " -- MSG: " + "Check if hold flag is 1"
	


      INSERT #ewerror
	  SELECT 4000,
			 430,
			 "",
			 "",
			 hold_flag,
			 0.0,
			 2,
			 trx_ctrl_num,
			 0,
			 "",
			 0
	  FROM #appyvpyt 
	  WHERE hold_flag = 1
END



IF (SELECT err_type FROM apedterr WHERE err_code = 460) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "appehdr3.cpp" + ", line " + STR( 303, 5 ) + " -- MSG: " + "Check if approval flag is valid"
	


      INSERT #ewerror
	  SELECT 4000,
			 460,
			 "",
			 "",
			 approval_flag,
			 0.0,
			 2,
			 trx_ctrl_num,
			 0,
			 "",
			 0
	  FROM #appyvpyt 
	  WHERE approval_flag NOT IN (0,1)
END



IF (SELECT err_type FROM apedterr WHERE err_code = 450) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "appehdr3.cpp" + ", line " + STR( 327, 5 ) + " -- MSG: " + "Check if approval flag is 1"
	


      INSERT #ewerror
	  SELECT 4000,
			 450,
			 "",
			 "",
			 approval_flag,
			 0.0,
			 2,
			 trx_ctrl_num,
			 0,
			 "",
			 0
	  FROM #appyvpyt 
	  WHERE approval_flag = 1
END



IF (SELECT err_type FROM apedterr WHERE err_code = 470) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "appehdr3.cpp" + ", line " + STR( 351, 5 ) + " -- MSG: " + "Check if amount exceeds max user amount"
	


      INSERT #ewerror
	  SELECT 4000,
			 470,
			 "",
			 "",
			 0,
			 b.amt_payment,
			 4,
			 b.trx_ctrl_num,
			 0,
			 "",
			 0
	  FROM #appyvpyt b, apusers c
	  WHERE b.user_id = c.user_id
	  AND b.approval_flag = 1
	  AND ((b.amt_payment) > (c.amt_max) + 0.0000001)
END



IF (SELECT err_type FROM apedterr WHERE err_code = 510) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "appehdr3.cpp" + ", line " + STR( 377, 5 ) + " -- MSG: " + "Check if discount taken < 0.0"
	


      INSERT #ewerror
	  SELECT 4000,
			 510,
			 "",
			 "",
			 0,
			 amt_disc_taken,
			 4,
			 trx_ctrl_num,
			 0,
			 "",
			 0
	  FROM #appyvpyt 
	  WHERE ((amt_disc_taken) < (0.0) - 0.0000001)
END


IF (SELECT err_type FROM apedterr WHERE err_code = 10823) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "appehdr3.cpp" + ", line " + STR( 400, 5 ) + " -- MSG: " + "Check if discount taken > amt_payment"
	


      INSERT #ewerror
	  SELECT 4000,
			 480,
			 "",
			 "",
			 0,
			 amt_disc_taken,
			 4,
			 trx_ctrl_num,
			 0,
			 "",
			 0
	  FROM #appyvpyt 
	  WHERE ((amt_disc_taken) > (amt_payment) + 0.0000001)
END




IF (SELECT err_type FROM apedterr WHERE err_code = 500) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "appehdr3.cpp" + ", line " + STR( 425, 5 ) + " -- MSG: " + "Check if amt_disc_taken = sum of details disc"
	


      INSERT #ewerror
	  SELECT 4000,
			 500,
			 "",
			 "",
			 0,
			 b.amt_disc_taken,
			 4,
			 b.trx_ctrl_num,
			 0,
			 "",
			 0
	  FROM #appyvpyt b, #appyvpdt c
	  WHERE b.trx_ctrl_num = c.trx_ctrl_num
	  GROUP BY b.trx_ctrl_num, b.amt_disc_taken
	  HAVING 
(ABS(((SIGN(b.amt_disc_taken) * ROUND(ABS(b.amt_disc_taken) + 0.0000001, @precision)))-((SIGN(SUM(c.amt_disc_taken)) * ROUND(ABS(SUM(c.amt_disc_taken)) + 0.0000001, @precision)))) > 0.0000001)
END


IF (SELECT err_type FROM apedterr WHERE err_code = 520) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "appehdr3.cpp" + ", line " + STR( 451, 5 ) + " -- MSG: " + "Check if print batch num <= 0"
	


      INSERT #ewerror
	  SELECT 4000,
			 520,
			 "",
			 "",
			 b.print_batch_num,
			 0.0,
			 2,
			 b.trx_ctrl_num,
			 0,
			 "",
			 0
	  FROM #appyvpyt b, appymeth c
	  WHERE b.payment_code = c.payment_code
	  AND c.payment_type = 2
	  AND b.printed_flag = 1
	  AND b.print_batch_num <= 0
END




IF (SELECT err_type FROM apedterr WHERE err_code = 525) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "appehdr3.cpp" + ", line " + STR( 479, 5 ) + " -- MSG: " + "Validate nat_cur_code exists"
	


      INSERT #ewerror
	  SELECT 4000,
			 525,
			 nat_cur_code,
			 "",
			 0,
			 0.0,
			 1,
			 trx_ctrl_num,
			 0,
			 "",
			 0
	  FROM #appyvpyt 
  	  WHERE nat_cur_code NOT IN (SELECT currency_code FROM glcurr_vw)
END



IF (SELECT err_type FROM apedterr WHERE err_code = 526) <= @error_level
BEGIN
	


	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "appehdr3.cpp" + ", line " + STR( 506, 5 ) + " -- MSG: " + "Validate rate_type_home exists"
      INSERT #ewerror
	  SELECT 4000,
			 526,
			 rate_type_home,
			 "",
			 0,
			 0.0,
			 1,
			 trx_ctrl_num,
			 0,
			 "",
			 0
	  FROM #appyvpyt 
  	  WHERE rate_type_home NOT IN (SELECT rate_type FROM glrtype_vw)
END


IF (SELECT err_type FROM apedterr WHERE err_code = 527) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "appehdr3.cpp" + ", line " + STR( 526, 5 ) + " -- MSG: " + "Validate rate_type_oper exists"
	


      INSERT #ewerror
	  SELECT 4000,
			 527,
			 rate_type_oper,
			 "",
			 0,
			 0.0,
			 1,
			 trx_ctrl_num,
			 0,
			 "",
			 0
	  FROM #appyvpyt 
  	  WHERE rate_type_oper NOT IN (SELECT rate_type FROM glrtype_vw)
END

IF ((SELECT mc_flag FROM apco) = 1)
BEGIN
	IF (SELECT err_type FROM apedterr WHERE err_code = 850) <= @error_level
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "appehdr3.cpp" + ", line " + STR( 550, 5 ) + " -- MSG: " + "Validate gain/loss accounts exist"


			CREATE TABLE #g_l_accts
			(
			 trx_ctrl_num varchar(16),
			 nat_cur_code varchar(8),
			 ap_acct_code varchar(32),
			 flag smallint
			)

			INSERT #g_l_accts (trx_ctrl_num, nat_cur_code, ap_acct_code, flag)
			SELECT DISTINCT c.trx_ctrl_num, b.nat_cur_code, dbo.IBAcctMask_fn ( d.ap_acct_code , a.org_id) , 0
			FROM apvohdr a, #appyvpdt b, #appyvpyt c, apaccts d
			WHERE a.trx_ctrl_num = b.apply_to_num
			AND b.trx_ctrl_num = c.trx_ctrl_num
			AND a.posting_code = d.posting_code
			AND (b.nat_cur_code != c.nat_cur_code
			     OR b.gain_home != 0.0
				 OR b.gain_oper != 0.0)

			UPDATE #g_l_accts
			SET flag = 1
			FROM CVO_Control..mccocdt a, #g_l_accts b, glco c
			WHERE a.company_code = c.company_code
			AND b.ap_acct_code like a.acct_mask
			AND a.currency_code = b.nat_cur_code


			INSERT	#ewerror
			SELECT 4000,
				850,
				nat_cur_code + "--" + ap_acct_code,
				"",
				0,
				0.0,
				1,
				trx_ctrl_num,
				0,
				"",
				0
			FROM	#g_l_accts
			WHERE	flag = 0

			DROP TABLE #g_l_accts
	 END

END




IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "appehdr3.cpp" + ", line " + STR( 602, 5 ) + " -- EXIT: "
RETURN 0
GO
GRANT EXECUTE ON  [dbo].[appehdr3_sp] TO [public]
GO
