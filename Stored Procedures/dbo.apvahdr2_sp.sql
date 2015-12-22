SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO




CREATE PROCEDURE [dbo].[apvahdr2_sp] @error_level smallint, @debug_level smallint = 0
AS

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/apvahdr2.sp" + ", line " + STR( 26, 5 ) + " -- ENTRY: "



IF (SELECT err_type FROM apedterr WHERE err_code = 30110) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/apvahdr2.sp" + ", line " + STR( 32, 5 ) + " -- MSG: " + "Check if date aging is not date_due or date_doc"
	
 INSERT #ewerror
	 SELECT 4000,
			 30110,
			 "",
			 "",
			 date_aging,
			 0.0,
			 3,
			 trx_ctrl_num,
			 0,
			 "",
			 0
	 FROM #apvavchg 
 	 WHERE date_aging != date_due
	 AND date_aging != date_doc
END


IF (SELECT err_type FROM apedterr WHERE err_code = 30120) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/apvahdr2.sp" + ", line " + STR( 56, 5 ) + " -- MSG: " + "Check if date due is valid"
	
 INSERT #ewerror
	 SELECT 4000,
			 30120,
			 "",
			 "",
			 date_due,
			 0.0,
			 3,
			 trx_ctrl_num,
			 0,
			 "",
			 0
	 FROM #apvavchg 
 	 WHERE date_due <= 0
END


IF (SELECT err_type FROM apedterr WHERE err_code = 30130) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/apvahdr2.sp" + ", line " + STR( 79, 5 ) + " -- MSG: " + "Check if date due compared to terms definition"
	
 INSERT #ewerror
	 SELECT 4000,
			 30130,
			 "",
			 "",
			 b.date_due,
			 0.0,
			 3,
			 b.trx_ctrl_num,
			 0,
			 "",
			 0
	 FROM #apvavchg b, apterms c
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
	 FROM #apvavchg b, apterms c
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
	 SET dtdate_calc = dateadd(dd,days_due, dateadd(dd,-datepart(dd,dtdate_doc),dtdate_calc) )
	 FROM #date_calc


	 UPDATE #date_calc
	 SET dtdate_calc = dateadd(dd, -datepart(dd,dtdate_calc), dtdate_calc)
	 FROM #date_calc
	 WHERE datepart(dd,dtdate_calc) < days_due
 


 INSERT #ewerror
	 SELECT 4000,
			 30130,
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
			 30130,
			 "",
			 "",
			 b.date_due,
			 0.0,
			 3,
			 b.trx_ctrl_num,
			 0,
			 "",
			 0
	 FROM #apvavchg b, apterms c
 	 WHERE b.terms_code = c.terms_code
	 AND c.terms_type = 3
	 AND b.date_due != c.date_due 

END


IF (SELECT err_type FROM apedterr WHERE err_code = 30140) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/apvahdr2.sp" + ", line " + STR( 185, 5 ) + " -- MSG: " + "Check if date doc is valid"
	
 INSERT #ewerror
	 SELECT 4000,
			 30140,
			 "",
			 "",
			 date_doc,
			 0.0,
			 3,
			 trx_ctrl_num,
			 0,
			 "",
			 0
	 FROM #apvavchg 
 	 WHERE date_doc <= 0
END


IF (SELECT err_type FROM apedterr WHERE err_code = 30150) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/apvahdr2.sp" + ", line " + STR( 208, 5 ) + " -- MSG: " + "Check if date entered is valid"
	
 INSERT #ewerror
	 SELECT 4000,
			 30150,
			 "",
			 "",
			 date_entered,
			 0.0,
			 3,
			 trx_ctrl_num,
			 0,
			 "",
			 0
	 FROM #apvavchg 
 	 WHERE date_entered <= 0
END


IF (SELECT err_type FROM apedterr WHERE err_code = 30160) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/apvahdr2.sp" + ", line " + STR( 231, 5 ) + " -- MSG: " + "Check if date required is valid"
	
 INSERT #ewerror
	 SELECT 4000,
			 30160,
			 "",
			 "",
			 date_required,
			 0.0,
			 3,
			 trx_ctrl_num,
			 0,
			 "",
			 0
	 FROM #apvavchg 
 	 WHERE date_required < 0
END


IF (SELECT err_type FROM apedterr WHERE err_code = 30200) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/apvahdr2.sp" + ", line " + STR( 254, 5 ) + " -- MSG: " + "Check if date discount is valid"
	
 INSERT #ewerror
	 SELECT 4000,
			 30200,
			 "",
			 "",
			 date_discount,
			 0.0,
			 3,
			 trx_ctrl_num,
			 0,
			 "",
			 0
	 FROM #apvavchg 
 	 WHERE date_discount < 0
END


IF (SELECT err_type FROM apedterr WHERE err_code = 30180) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/apvahdr2.sp" + ", line " + STR( 277, 5 ) + " -- MSG: " + "Check if date discount is greater than due_date"
	
 INSERT #ewerror
	 SELECT 4000,
			 30180,
			 "",
			 "",
			 date_discount,
			 0.0,
			 3,
			 trx_ctrl_num,
			 0,
			 "",
			 0
	 FROM #apvavchg
 	 WHERE date_discount > date_due
END


IF (SELECT err_type FROM apedterr WHERE err_code = 30190) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/apvahdr2.sp" + ", line " + STR( 300, 5 ) + " -- MSG: " + "Check if date discount compared to terms definition"
	
 INSERT #ewerror
	 SELECT 4000,
			 30190,
			 "",
			 "",
			 b.date_discount,
			 0.0,
			 3,
			 b.trx_ctrl_num,
			 0,
			 "",
			 0
	 FROM #apvavchg b, apterms c
 	 WHERE b.terms_code = c.terms_code
	 AND c.terms_type = 1
	 AND b.date_discount != b.date_doc + c.discount_days


	 SELECT b.trx_ctrl_num,
			 b.date_discount,
			 c.discount_days,
			 c.min_days_due,
			 dtdate_doc = dateadd(dd,b.date_doc,"1/1/1800"),
			 dtdate_discount = dateadd(dd,b.date_discount,"1/1/1800"),
			 dtdate_calc = dateadd(dd,b.date_doc,"1/1/1800")
	 INTO #date_calc2
	 FROM #apvavchg b, apterms c
 	 WHERE b.terms_code = c.terms_code
	 AND c.terms_type = 2


	 DELETE #date_calc2
	 WHERE dtdate_doc < "1/3/3552"
	 OR dtdate_discount < "1/3/3552"


	 UPDATE #date_calc2
	 SET dtdate_doc = dateadd(dd,-657072,dtdate_doc),
	 dtdate_discount = dateadd(dd,-657072,dtdate_discount),
		 dtdate_calc = dateadd(dd,-657072,dtdate_calc) 


 UPDATE #date_calc2
	 SET dtdate_calc = dateadd(mm,1,dtdate_calc)
	 FROM #date_calc2
	 WHERE datepart(dd,dtdate_doc) > discount_days - min_days_due



	 UPDATE #date_calc2
	 SET dtdate_calc = dateadd(dd,discount_days, dateadd(dd,-datepart(dd,dtdate_doc),dtdate_calc) )
	 FROM #date_calc2


	 UPDATE #date_calc2
	 SET dtdate_calc = dateadd(dd, -datepart(dd,dtdate_calc), dtdate_calc)
	 FROM #date_calc2
	 WHERE datepart(dd,dtdate_calc) < discount_days
 


 INSERT #ewerror
	 SELECT 4000,
			 30190,
			 "",
			 "",
			 date_discount,
			 0.0,
			 3,
			 trx_ctrl_num,
			 0,
			 "",
			 0
	 FROM #date_calc2
	 WHERE dtdate_discount != dtdate_calc

	 DROP TABLE #date_calc2


 INSERT #ewerror
	 SELECT 4000,
			 30190,
			 "",
			 "",
			 b.date_discount,
			 0.0,
			 3,
			 b.trx_ctrl_num,
			 0,
			 "",
			 0
	 FROM #apvavchg b, apterms c
 	 WHERE b.terms_code = c.terms_code
	 AND c.terms_type = 3
	 AND b.date_discount != c.date_discount 

END





IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/apvahdr2.sp" + ", line " + STR( 406, 5 ) + " -- EXIT: "
RETURN 0
GO
GRANT EXECUTE ON  [dbo].[apvahdr2_sp] TO [public]
GO
