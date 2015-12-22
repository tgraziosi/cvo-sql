SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[apvehdr4_sp] @error_level smallint, @debug_level smallint = 0
AS

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvehdr4.cpp" + ", line " + STR( 40, 5 ) + " -- ENTRY: "


IF (SELECT err_type FROM apedterr WHERE err_code = 10610) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvehdr4.cpp" + ", line " + STR( 45, 5 ) + " -- MSG: " + "Check if one_time_vend_flag is valid"
	


      INSERT #ewerror
	  SELECT 4000,
			 10610,
			 "",
			 "",
			 one_time_vend_flag,
			 0.0,
			 2,
			 trx_ctrl_num,
			 0,
			 "",
			 0
	  FROM #apvovchg 
  	  WHERE one_time_vend_flag NOT IN (0,1)
END




IF (SELECT err_type FROM apedterr WHERE err_code = 10620) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvehdr4.cpp" + ", line " + STR( 70, 5 ) + " -- MSG: " + "Check if one_time_vend address is entered"
	


      INSERT #ewerror
	  SELECT 4000,
			 10620,
			 "",
			 "",
			 one_time_vend_flag,
			 0.0,
			 2,
			 trx_ctrl_num,
			 0,
			 "",
			 0
	  FROM #apvovchg b
  	  WHERE one_time_vend_flag = 1
	  AND pay_to_addr1 = ""
END



IF (SELECT err_type FROM apedterr WHERE err_code = 10630) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvehdr4.cpp" + ", line " + STR( 95, 5 ) + " -- MSG: " + "Check if one_time_vend name is entered"
	


      INSERT #ewerror
	  SELECT 4000,
			 10630,
			 b.pay_to_addr1,
			 "",
			 0,
			 0.0,
			 1,
			 b.trx_ctrl_num,
			 0,
			 "",
			 0
	  FROM #apvovchg b, apvend c
  	  WHERE b.one_time_vend_flag = 1
	  AND b.vendor_code = c.vendor_code
	  AND b.pay_to_addr1 = c.vendor_name
END


IF (SELECT err_type FROM apedterr WHERE err_code = 10640) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvehdr4.cpp" + ", line " + STR( 120, 5 ) + " -- MSG: " + "Check if one_time_vend_flag is 1 but code is not one_time_vend"
	


      INSERT #ewerror
	  SELECT 4000,
			 10640,
			 vendor_code,
			 "",
			 0,
			 0.0,
			 1,
			 trx_ctrl_num,
			 0,
			 "",
			 0
	  FROM #apvovchg 
  	  WHERE one_time_vend_flag = 1
	  AND vendor_code NOT IN (SELECT one_time_vend_code FROM apco)
END


IF (SELECT err_type FROM apedterr WHERE err_code = 10660) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvehdr4.cpp" + ", line " + STR( 144, 5 ) + " -- MSG: " + "Check if one_check_flag is valid"
	


      INSERT #ewerror
	  SELECT 4000,
			 10660,
			 "",
			 "",
			 one_check_flag,
			 0.0,
			 2,
			 trx_ctrl_num,
			 0,
			 "",
			 0
	  FROM #apvovchg 
  	  WHERE one_check_flag NOT IN (0,1)
END



IF (SELECT err_type FROM apedterr WHERE err_code = 10650) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvehdr4.cpp" + ", line " + STR( 168, 5 ) + " -- MSG: " + "Check if one_check_flag is not the default"
	


      INSERT #ewerror
	  SELECT 4000,
			 10650,
			 "",
			 "",
			 b.one_check_flag,
			 0.0,
			 2,
			 b.trx_ctrl_num,
			 0,
			 "",
			 0
	  FROM #apvovchg b,  apvend c
  	  WHERE b.vendor_code = c.vendor_code
	  AND b.one_check_flag != c.one_check_flag
END





IF (SELECT err_type FROM apedterr WHERE err_code = 10050) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvehdr4.cpp" + ", line " + STR( 195, 5 ) + " -- MSG: " + "Check if date applied <= 0"
	


      INSERT #ewerror
	  SELECT 4000,
			 10050,
			 "",
			 "",
			 date_applied,
			 0.0,
			 3,
			 trx_ctrl_num,
			 0,
			 "",
			 0
	  FROM #apvovchg 
  	  WHERE date_applied <= 0
END

IF (SELECT err_type FROM apedterr WHERE err_code = 10060) <= @error_level
BEGIN
   	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvehdr4.cpp" + ", line " + STR( 217, 5 ) + " -- MSG: " + "Check if applied to future period"
	


	IF OBJECT_ID('tempdb..#apvochg_work ') IS NOT NULL BEGIN
		INSERT #ewerror
			  SELECT 4000,
					 10060,
					 "",
					 "",
					 b.date_applied,
					 0.0,
					 3,
					 b.trx_ctrl_num,
					 0,
					 "",
					 0
			  FROM #apvovchg b, apco c
			  WHERE b.date_applied > c.period_end_date
			  AND ((b.recurring_flag != 1)  
			  OR   (b.recurring_flag = 1 AND EXISTS(SELECT 1 FROM #apvochg_work WHERE #apvochg_work.trx_ctrl_num = b.trx_ctrl_num)))
	END
	ELSE BEGIN
	INSERT #ewerror
			  SELECT 4000,
					 10060,
					 "",
					 "",
					 b.date_applied,
					 0.0,
					 3,
					 b.trx_ctrl_num,
					 0,
					 "",
					 0
			  FROM #apvovchg b, apco c
			  WHERE b.date_applied > c.period_end_date
	END 
      
END


IF (SELECT err_type FROM apedterr WHERE err_code = 10070) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvehdr4.cpp" + ", line " + STR( 261, 5 ) + " -- MSG: " + "Check if applied to prior period"
	


	IF OBJECT_ID('tempdb..#apvochg_work ') IS NOT NULL BEGIN
		  INSERT #ewerror
		  SELECT 4000,
				 10070,
				 "",
				 "",
				 b.date_applied,
				 0.0,
				 3,
				 b.trx_ctrl_num,
				 0,
				 "",
				 0
		  FROM #apvovchg b, glprd c, apco d
		  WHERE b.date_applied < c.period_start_date
		  AND c.period_end_date = d.period_end_date
		  AND ((b.recurring_flag != 1)  
		  OR   (b.recurring_flag = 1 AND EXISTS(SELECT 1 FROM #apvochg_work WHERE #apvochg_work.trx_ctrl_num = b.trx_ctrl_num)))
	END
	ELSE BEGIN
		INSERT #ewerror
		  SELECT 4000,
				 10070,
				 "",
				 "",
				 b.date_applied,
				 0.0,
				 3,
				 b.trx_ctrl_num,
				 0,
				 "",
				 0
		  FROM #apvovchg b, glprd c, apco d
		  WHERE b.date_applied < c.period_start_date
		  AND c.period_end_date = d.period_end_date
	END
	     
END


IF (SELECT err_type FROM apedterr WHERE err_code = 10090) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvehdr4.cpp" + ", line " + STR( 307, 5 ) + " -- MSG: " + "Check if applied period exists"
	


      UPDATE #apvovchg
      SET flag = 1
	  FROM #apvovchg, glprd c
  	  WHERE #apvovchg.date_applied BETWEEN c.period_start_date AND c.period_end_date


      INSERT #ewerror
	  SELECT 4000,
			 10090,
			 "",
			 "",
			 date_applied,
			 0.0,
			 3,
			 trx_ctrl_num,
			 0,
			 "",
			 0
	  FROM #apvovchg 
  	  WHERE flag = 0


     UPDATE #apvovchg
     SET flag = 0
END



IF (SELECT err_type FROM apedterr WHERE err_code = 10080) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvehdr4.cpp" + ", line " + STR( 341, 5 ) + " -- MSG: " + "Check if date applid in valid apco range"
	


      INSERT #ewerror
	  SELECT 4000,
			 10080,
			 "",
			 "",
			 b.date_applied,
			 0.0,
			 3,
			 b.trx_ctrl_num,
			 0,
			 "",
			 0
	  FROM #apvovchg b, apco c
  	  WHERE abs(b.date_applied - b.date_entered) > c.date_range_verify
END


IF (SELECT err_type FROM apedterr WHERE err_code = 10100) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvehdr4.cpp" + ", line " + STR( 364, 5 ) + " -- MSG: " + "Check if date aging is valid"
	


      INSERT #ewerror
	  SELECT 4000,
			 10100,
			 "",
			 "",
			 date_aging,
			 0.0,
			 3,
			 trx_ctrl_num,
			 0,
			 "",
			 0
	  FROM #apvovchg b
  	  WHERE date_aging < 0
END

IF (SELECT err_type FROM apedterr WHERE err_code = 10110) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvehdr4.cpp" + ", line " + STR( 386, 5 ) + " -- MSG: " + "Check if date aging is not date_due or date_doc"
	


      INSERT #ewerror
	  SELECT 4000,
			 10110,
			 "",
			 "",
			 date_aging,
			 0.0,
			 3,
			 trx_ctrl_num,
			 0,
			 "",
			 0
	  FROM #apvovchg 
  	  WHERE date_aging != date_due
	  AND date_aging != date_doc
END


IF (SELECT err_type FROM apedterr WHERE err_code = 10120) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvehdr4.cpp" + ", line " + STR( 410, 5 ) + " -- MSG: " + "Check if date due is valid"
	


      INSERT #ewerror
	  SELECT 4000,
			 10120,
			 "",
			 "",
			 date_due,
			 0.0,
			 3,
			 trx_ctrl_num,
			 0,
			 "",
			 0
	  FROM #apvovchg 
  	  WHERE date_due <= 0
END


IF (SELECT err_type FROM apedterr WHERE err_code = 10130) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvehdr4.cpp" + ", line " + STR( 433, 5 ) + " -- MSG: " + "Check if date due compared to terms definition"
	


      INSERT #ewerror
	  SELECT 4000,
			 10130,
			 "",
			 "",
			 b.date_due,
			 0.0,
			 3,
			 b.trx_ctrl_num,
			 0,
			 "",
			 0
	  FROM #apvovchg b, apterms c
  	  WHERE b.terms_code = c.terms_code
	  AND c.terms_type = 1
	  AND b.date_due != b.date_doc + c.days_due

	  SELECT b.trx_ctrl_num,
			 b.date_due,
			 c.days_due,
			 c.min_days_due,
			 dtdate_doc = dateadd(dd,b.date_doc,"1/1/1800"),
			 dtdate_due = dateadd(dd,b.date_due,"1/1/1800"),
			 dtdate_calc = dateadd(dd,b.date_doc,"1/1/1800")
	  INTO #date_calc
	  FROM #apvovchg b, apterms c
  	  WHERE b.terms_code = c.terms_code
	  AND c.terms_type = 2


	  DELETE #date_calc
	  WHERE dtdate_doc < "1/3/3552"
	  OR dtdate_due < "1/3/3552"


	  UPDATE #date_calc
	  SET dtdate_doc = dateadd(dd,-657072,dtdate_doc),
	      dtdate_due = dateadd(dd,-657072,dtdate_due),
		  dtdate_calc = dateadd(dd,-657072,dtdate_calc)      




      UPDATE #date_calc
	  SET dtdate_calc = dateadd(mm,1,dtdate_calc)
	  FROM #date_calc
	  WHERE datepart(dd,dtdate_doc) > days_due - min_days_due



	  UPDATE #date_calc
	  SET dtdate_calc = dateadd(dd,days_due,     dateadd(dd,-datepart(dd,dtdate_doc),dtdate_calc)  )
	  FROM #date_calc


	  UPDATE #date_calc
	  SET dtdate_calc = dateadd(dd,   -datepart(dd,dtdate_calc),  dtdate_calc)
	  FROM #date_calc
	  WHERE datepart(dd,dtdate_calc) < days_due
      


      INSERT #ewerror
	  SELECT 4000,
			 10130,
			 "",
			 "",
			 date_due,
			 0.0,
			 3,
			 trx_ctrl_num,
			 0,
			 "",
			 0
	  FROM #date_calc
	  WHERE dtdate_due != dtdate_calc

	  DROP TABLE #date_calc


      INSERT #ewerror
	  SELECT 4000,
			 10130,
			 "",
			 "",
			 b.date_due,
			 0.0,
			 3,
			 b.trx_ctrl_num,
			 0,
			 "",
			 0
	  FROM #apvovchg b, apterms c
  	  WHERE b.terms_code = c.terms_code
	  AND c.terms_type = 3
	  AND b.date_due != c.date_due 

END






IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvehdr4.cpp" + ", line " + STR( 541, 5 ) + " -- EXIT: "
RETURN 0
GO
GRANT EXECUTE ON  [dbo].[apvehdr4_sp] TO [public]
GO
