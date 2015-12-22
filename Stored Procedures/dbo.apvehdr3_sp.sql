SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[apvehdr3_sp] @error_level smallint, @debug_level smallint = 0
AS

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvehdr3.cpp" + ", line " + STR( 35, 5 ) + " -- ENTRY: "


IF (SELECT err_type FROM apedterr WHERE err_code = 10450) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvehdr3.cpp" + ", line " + STR( 40, 5 ) + " -- MSG: " + "Check if tax code is valid"
	


      INSERT #ewerror
	  SELECT 4000,
			 10450,
			 b.tax_code,
			 "",
			 0,
			 0.0,
			 1,
			 b.trx_ctrl_num,
			 0,
			 "",
			 0
	  FROM #apvovchg b
		LEFT JOIN aptax a ON b.tax_code = a.tax_code 
  	  WHERE b.tax_code != ""
		AND a.tax_code IS NULL
END


IF (SELECT err_type FROM apedterr WHERE err_code = 10440) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvehdr3.cpp" + ", line " + STR( 65, 5 ) + " -- MSG: " + "Check if tax code is not the default"
	


	


















      INSERT #ewerror
	  SELECT 4000,
			 10440,
			 b.tax_code,
			 "",
			 0,
			 0.0,
			 1,
			 b.trx_ctrl_num,
			 0,
			 "",
			 0
         FROM #apvovchg b, artax c (nolock), apmaster_all d (nolock)
 	 WHERE b.tax_code = c.tax_code
	 AND b.vendor_code = d.vendor_code
	 AND b.tax_code != d.tax_code
	 AND b.pay_to_code = ""
	 AND d.address_type = 0


	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvehdr3.cpp" + ", line " + STR( 108, 5 ) + " -- MSG: " + "Check if tax code is not the default"
	


	


















      INSERT #ewerror
	  SELECT 4000,
			 10440,
			 b.tax_code,
			 "",
			 0,
			 0.0,
			 1,
			 b.trx_ctrl_num,
			 0,
			 "",
			 0
	 FROM #apvovchg b, artax c (nolock), apmaster_all d (nolock)
 	 WHERE b.tax_code = c.tax_code
	 AND b.vendor_code = d.vendor_code
	 AND b.pay_to_code = d.pay_to_code
	 AND b.tax_code != d.tax_code
	 AND d.address_type = 1

END




IF (SELECT err_type FROM apedterr WHERE err_code = 10460) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvehdr3.cpp" + ", line " + STR( 157, 5 ) + " -- MSG: " + "Check if recurring code is valid"
	


      INSERT #ewerror
	  SELECT 4000,
			 10460,
			 b.recurring_code,
			 "",
			 0,
			 0.0,
			 1,
			 b.trx_ctrl_num,
			 0,
			 "",
			 0
	  FROM #apvovchg b
		LEFT JOIN apcycle a ON b.recurring_code = a.cycle_code 
  	  WHERE b.recurring_code != ""
		AND a.cycle_code IS NULL
END


IF (SELECT err_type FROM apedterr WHERE err_code = 10480) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvehdr3.cpp" + ", line " + STR( 182, 5 ) + " -- MSG: " + "Check if recurring code is valid and flag is set"
	


      INSERT #ewerror
	  SELECT 4000,
			 10480,
			 "",
			 "",
			 b.recurring_flag,
			 0.0,
			 2,
			 b.trx_ctrl_num,
			 0,
			 "",
			 0
	  FROM #apvovchg b
		LEFT JOIN apcycle c ON b.recurring_code = c.cycle_code 
  	  WHERE b.recurring_code != ""
	  AND b.recurring_flag = 1
	  AND c.cycle_code IS NULL
END

IF (SELECT err_type FROM apedterr WHERE err_code = 10470) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvehdr3.cpp" + ", line " + STR( 207, 5 ) + " -- MSG: " + "Check if recurring code is valid and flag is not set"
	


      INSERT #ewerror
	  SELECT 4000,	
			 10470,
			 "",
			 "",
			 b.recurring_flag,
			 0.0,
			 2,
	  		 b.trx_ctrl_num,
			 0,
			 "",
			 0
	  FROM #apvovchg b, apcycle c
  	  WHERE b.recurring_code = c.cycle_code
	  AND b.recurring_flag != 1
END


IF (SELECT err_type FROM apedterr WHERE err_code = 10510) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvehdr3.cpp" + ", line " + STR( 231, 5 ) + " -- MSG: " + "Check if payment code is valid"
	


      INSERT #ewerror
	  SELECT 4000,
			 10510,
			 a.payment_code,
			 "",
			 0,
			 0.0,
			 1,
			 a.trx_ctrl_num,
			 0,
			 "",
			 0
	  FROM #apvovchg a
		LEFT JOIN appymeth b ON a.payment_code = b.payment_code 
  	  WHERE a.payment_code != ""
		AND b.payment_code  IS NULL
END
 
IF (SELECT err_type FROM apedterr WHERE err_code = 10520) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvehdr3.cpp" + ", line " + STR( 255, 5 ) + " -- MSG: " + "Check if times accrued is valid"
	


      INSERT #ewerror
	  SELECT 4000,
			 10520,
			 "",
			 "",
			 times_accrued,
			 0.0,
			 2,
			 trx_ctrl_num,
			 0,
			 "",
			 0
	  FROM #apvovchg
  	  WHERE times_accrued < 0
END


IF (SELECT err_type FROM apedterr WHERE err_code = 10530) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvehdr3.cpp" + ", line " + STR( 278, 5 ) + " -- MSG: " + "Check if accrual flag is valid"
	


      INSERT #ewerror
	  SELECT 4000,
		     10530,
			 "",
			 "",
			 accrual_flag,
			 0.0,
			 2,
			 trx_ctrl_num,
			 0,
			 "",
			 0
	  FROM #apvovchg 
  	  WHERE accrual_flag NOT IN (0,1)
END


IF (SELECT err_type FROM apedterr WHERE err_code = 10540) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvehdr3.cpp" + ", line " + STR( 301, 5 ) + " -- MSG: " + "Check if posted flag is valid"
	


      INSERT #ewerror
	  SELECT 4000,
			 10540,
			 "",
			 "",
			 posted_flag,
			 0.0,
			 2,
			 trx_ctrl_num,
			 0,
			 "",
			 0
	  FROM #apvovchg b
  	  WHERE posted_flag != 0
END


IF (SELECT err_type FROM apedterr WHERE err_code = 10560) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvehdr3.cpp" + ", line " + STR( 324, 5 ) + " -- MSG: " + "Check if hold flag is valid"
	


      INSERT #ewerror
	  SELECT 4000,
	  		 10560,
			 "",
			 "",
			 hold_flag,
			 0.0,
			 2,
			 trx_ctrl_num,
			 0,
			 "",
			 0
	  FROM #apvovchg 
  	  WHERE hold_flag NOT IN (0,1)
END


IF (SELECT err_type FROM apedterr WHERE err_code = 10550) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvehdr3.cpp" + ", line " + STR( 347, 5 ) + " -- MSG: " + "Check if voucher is on hold"
	


      INSERT #ewerror
	  SELECT 4000,
			 10550,
			 "",
			 "",
			 hold_flag,
			 0.0,
			 2,	
			 trx_ctrl_num,
			 0,
			 "",
			 0
	  FROM #apvovchg 
  	  WHERE hold_flag = 1
	  AND  recurring_flag = 0
END


IF (SELECT err_type FROM apedterr WHERE err_code = 10570) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvehdr3.cpp" + ", line " + STR( 371, 5 ) + " -- MSG: " + "Check if add_cost_flag != 0"
	


      INSERT #ewerror
	  SELECT 4000,
			 10570,
			 "",
			 "",
			 add_cost_flag,
			 0.0,
			 2,
			 trx_ctrl_num,
			 0,
			 "",
			 0
	  FROM #apvovchg 
  	  WHERE add_cost_flag != 0
END







IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvehdr3.cpp" + ", line " + STR( 397, 5 ) + " -- EXIT: "
RETURN 0
GO
GRANT EXECUTE ON  [dbo].[apvehdr3_sp] TO [public]
GO
