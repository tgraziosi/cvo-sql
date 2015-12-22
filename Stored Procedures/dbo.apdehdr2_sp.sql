SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE [dbo].[apdehdr2_sp] @error_level smallint, @debug_level smallint = 0
AS

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apdehdr2.cpp" + ", line " + STR( 27, 5 ) + " -- ENTRY: "





IF (SELECT err_type FROM apedterr WHERE err_code = 20410) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apdehdr2.cpp" + ", line " + STR( 35, 5 ) + " -- MSG: " + "Check if fob code is valid"
	



















      INSERT #ewerror
	  SELECT 4000,
			 20410,
			 a.fob_code,
			 "",
			 0,
			 0.0,
			 1,
			 a.trx_ctrl_num,
			 0,
			 "",
			 0
	  FROM #apdmvchg a
		LEFT JOIN apfob b ON a.fob_code = b.fob_code 
  	  WHERE a.fob_code != ""
		AND b.fob_code  IS NULL


END


IF (SELECT err_type FROM apedterr WHERE err_code = 20400) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apdehdr2.cpp" + ", line " + STR( 79, 5 ) + " -- MSG: " + "Check if fob code is not the default"
	




















      INSERT #ewerror
	 SELECT 4000,
			 20400,
			 b.fob_code,
			 "",
			 0,
			 0.0,
			 1,
			 b.trx_ctrl_num,
			 0,
			 "",
			 0
	 FROM #apdmvchg b, apfob c (nolock), apmaster_all d (nolock)
 	 WHERE b.fob_code = c.fob_code
	 AND b.vendor_code = d.vendor_code
	 AND b.fob_code != d.fob_code
	 AND b.pay_to_code = ""
	 AND d.address_type  = 0


	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apdehdr2.cpp" + ", line " + STR( 121, 5 ) + " -- MSG: " + "Check if fob code is not the default"
	





















	 INSERT #ewerror
		 SELECT 4000,
				 20400,
				 b.fob_code,
				 "",
				 0,
				 0.0,
				 1,
				 b.trx_ctrl_num,
				 0,
				 "",
				 0
		 FROM #apdmvchg b, apfob c (nolock), apmaster_all d (nolock)
	 	 WHERE b.fob_code = c.fob_code
		 AND b.vendor_code = d.vendor_code
		 AND b.pay_to_code = d.pay_to_code
		 AND b.fob_code != d.fob_code
		 AND d.address_type  = 1


END

IF (SELECT err_type FROM apedterr WHERE err_code = 20450) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apdehdr2.cpp" + ", line " + STR( 168, 5 ) + " -- MSG: " + "Check if tax code is valid"
	


      INSERT #ewerror
	  SELECT 4000,
			 20450,
			 tax_code,
			 "",
			 0,
			 0.0,
			 1,
			 trx_ctrl_num,
			 0,
			 "",
			 0
	  FROM #apdmvchg b
  	  WHERE tax_code NOT IN (SELECT tax_code FROM aptax)
	  AND tax_code != ""
END


IF (SELECT err_type FROM apedterr WHERE err_code = 20440) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apdehdr2.cpp" + ", line " + STR( 192, 5 ) + " -- MSG: " + "Check if tax code is not the default"
	


      INSERT #ewerror
	  SELECT 4000,
			 20440,
			 b.tax_code,
			 "",
			 0,
			 0.0,
			 1,
			 b.trx_ctrl_num,
			 0,
			 "",
			 0
	  FROM #apdmvchg b, aptax c, apvend d
  	  WHERE b.tax_code = c.tax_code
	  AND b.vendor_code = d.vendor_code
	  AND b.tax_code != d.tax_code
	  AND b.pay_to_code = ""

	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apdehdr2.cpp" + ", line " + STR( 214, 5 ) + " -- MSG: " + "Check if tax code is not the default"
	


      INSERT #ewerror
	  SELECT 4000,
			 20440,
			 b.tax_code,
			 "",
			 0,
			 0.0,
			 1,
			 b.trx_ctrl_num,
			 0,
			 "",
			 0
	  FROM #apdmvchg b, aptax c, appayto d
  	  WHERE b.tax_code = c.tax_code
	  AND b.vendor_code = d.vendor_code
	  AND b.pay_to_code = d.pay_to_code
	  AND b.tax_code != d.tax_code
END



IF (SELECT err_type FROM apedterr WHERE err_code = 20540) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apdehdr2.cpp" + ", line " + STR( 241, 5 ) + " -- MSG: " + "Check if posted flag is valid"
	


      INSERT #ewerror
	  SELECT 4000,
			 20540,
			 "",
			 "",
			 posted_flag,
			 0.0,
			 2,
			 trx_ctrl_num,
			 0,
			 "",
			 0
	  FROM #apdmvchg b
  	  WHERE posted_flag != 0
END


IF (SELECT err_type FROM apedterr WHERE err_code = 20560) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apdehdr2.cpp" + ", line " + STR( 264, 5 ) + " -- MSG: " + "Check if hold flag is valid"
	


      INSERT #ewerror
	  SELECT 4000,
	  		 20560,
			 "",
			 "",
			 hold_flag,
			 0.0,
			 2,
			 trx_ctrl_num,
			 0,
			 "",
			 0
	  FROM #apdmvchg 
  	  WHERE hold_flag NOT IN (0,1)
END


IF (SELECT err_type FROM apedterr WHERE err_code = 20550) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apdehdr2.cpp" + ", line " + STR( 287, 5 ) + " -- MSG: " + "Check if debit memo is on hold"
	


      INSERT #ewerror
	  SELECT 4000,
			 20550,
			 "",
			 "",
			 hold_flag,
			 0.0,
			 2,	
			 trx_ctrl_num,
			 0,
			 "",
			 0
	  FROM #apdmvchg 
  	  WHERE hold_flag = 1
END

IF (SELECT err_type FROM apedterr WHERE err_code = 20050) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apdehdr2.cpp" + ", line " + STR( 309, 5 ) + " -- MSG: " + "Check if date applied <= 0"
	


      INSERT #ewerror
	  SELECT 4000,
			 20050,
			 "",
			 "",
			 date_applied,
			 0.0,
			 3,
			 trx_ctrl_num,
			 0,
			 "",
			 0
	  FROM #apdmvchg 
  	  WHERE date_applied <= 0
END


IF (SELECT err_type FROM apedterr WHERE err_code = 20060) <= @error_level
BEGIN
   	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apdehdr2.cpp" + ", line " + STR( 332, 5 ) + " -- MSG: " + "Check if applied to future period"
	


      INSERT #ewerror
	  SELECT 4000,
			 20060,
			 "",
			 "",
			 b.date_applied,
			 0.0,
			 3,
			 b.trx_ctrl_num,
			 0,
			 "",
			 0
	  FROM #apdmvchg b, apco c
  	  WHERE b.date_applied > c.period_end_date
END


IF (SELECT err_type FROM apedterr WHERE err_code = 20070) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apdehdr2.cpp" + ", line " + STR( 355, 5 ) + " -- MSG: " + "Check if applied to prior period"
	


      INSERT #ewerror
	  SELECT 4000,
			 20070,
			 "",
			 "",
			 b.date_applied,
			 0.0,
			 3,
			 b.trx_ctrl_num,
			 0,
			 "",
			 0
	  FROM #apdmvchg b, glprd c, apco d
  	  WHERE b.date_applied < c.period_start_date
	  AND c.period_end_date = d.period_end_date
END


IF (SELECT err_type FROM apedterr WHERE err_code = 20090) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apdehdr2.cpp" + ", line " + STR( 379, 5 ) + " -- MSG: " + "Check if applied period exists"
	


      UPDATE #apdmvchg
      SET flag = 1
	  FROM #apdmvchg, glprd c
  	  WHERE #apdmvchg.date_applied BETWEEN c.period_start_date AND c.period_end_date


      INSERT #ewerror
	  SELECT 4000,
			 20090,
			 "",
			 "",
			 date_applied,
			 0.0,
			 3,
			 trx_ctrl_num,
			 0,
			 "",
			 0
	  FROM #apdmvchg 
  	  WHERE flag = 0


     UPDATE #apdmvchg
     SET flag = 0
END



IF (SELECT err_type FROM apedterr WHERE err_code = 20080) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apdehdr2.cpp" + ", line " + STR( 413, 5 ) + " -- MSG: " + "Check if date applid in valid apco range"
	


      INSERT #ewerror
	  SELECT 4000,
			 20080,
			 "",
			 "",
			 b.date_applied,
			 0.0,
			 3,
			 b.trx_ctrl_num,
			 0,
			 "",
			 0
	  FROM #apdmvchg b, apco c
  	  WHERE abs(b.date_applied - b.date_entered) > c.date_range_verify
END


IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apdehdr2.cpp" + ", line " + STR( 434, 5 ) + " -- EXIT: "
RETURN 0
GO
GRANT EXECUTE ON  [dbo].[apdehdr2_sp] TO [public]
GO
