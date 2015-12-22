SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[apvehdr5_sp] @error_level smallint, @debug_level smallint = 0
AS

DECLARE @credit_invoice_flag smallint
IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvehdr5.cpp" + ", line " + STR( 48, 5 ) + " -- ENTRY: "




IF (SELECT err_type FROM apedterr WHERE err_code = 10140) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvehdr5.cpp" + ", line " + STR( 55, 5 ) + " -- MSG: " + "Check if date doc is valid"
	


      INSERT #ewerror
	  SELECT 4000,
			 10140,
			 "",
			 "",
			 date_doc,
			 0.0,
			 3,
			 trx_ctrl_num,
			 0,
			 "",
			 0
	  FROM #apvovchg 
  	  WHERE date_doc <= 0
END


IF (SELECT err_type FROM apedterr WHERE err_code = 10150) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvehdr5.cpp" + ", line " + STR( 78, 5 ) + " -- MSG: " + "Check if date entered is valid"
	


      INSERT #ewerror
	  SELECT 4000,
			 10150,
			 "",
			 "",
			 date_entered,
			 0.0,
			 3,
			 trx_ctrl_num,
			 0,
			 "",
			 0
	  FROM #apvovchg 
  	  WHERE date_entered <= 0
END


IF (SELECT err_type FROM apedterr WHERE err_code = 10160) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvehdr5.cpp" + ", line " + STR( 101, 5 ) + " -- MSG: " + "Check if date required is valid"
	


      INSERT #ewerror
	  SELECT 4000,
			 10160,
			 "",
			 "",
			 date_required,
			 0.0,
			 3,
			 trx_ctrl_num,
			 0,
			 "",
			 0
	  FROM #apvovchg 
  	  WHERE date_required < 0
END


IF (SELECT err_type FROM apedterr WHERE err_code = 10170) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvehdr5.cpp" + ", line " + STR( 124, 5 ) + " -- MSG: " + "Check if date recurring is valid"
	


      INSERT #ewerror
	  SELECT 4000,
			 10170,
			 "",
			 "",
			 date_recurring,
			 0.0,
			 3,
			 trx_ctrl_num,
			 0,
			 "",
			 0
	  FROM #apvovchg 
  	  WHERE date_recurring < 0
END


IF (SELECT err_type FROM apedterr WHERE err_code = 10200) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvehdr5.cpp" + ", line " + STR( 147, 5 ) + " -- MSG: " + "Check if date discount is valid"
	


      INSERT #ewerror
	  SELECT 4000,
			 10200,
			 "",
			 "",
			 date_discount,
			 0.0,
			 3,
			 trx_ctrl_num,
			 0,
			 "",
			 0
	  FROM #apvovchg 
  	  WHERE date_discount < 0
END


IF (SELECT err_type FROM apedterr WHERE err_code = 10180) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvehdr5.cpp" + ", line " + STR( 170, 5 ) + " -- MSG: " + "Check if date discount is greater than due_date"
	


      INSERT #ewerror
	  SELECT 4000,
			 10180,
			 "",
			 "",
			 date_discount,
			 0.0,
			 3,
			 trx_ctrl_num,
			 0,
			 "",
			 0
	  FROM #apvovchg
  	  WHERE date_discount > date_due
END


IF (SELECT err_type FROM apedterr WHERE err_code = 10190) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvehdr5.cpp" + ", line " + STR( 193, 5 ) + " -- MSG: " + "Check if date discount compared to terms definition"
	


      INSERT #ewerror
	  SELECT 4000,
			 10190,
			 '',
			 '',
			 b.date_discount,
			 0.0,
			 3,
			 b.trx_ctrl_num,
			 0,
			 '',
			 0
	  FROM #apvovchg b, apterms c, aptermsd d
  	  WHERE b.terms_code = c.terms_code
	  AND c.terms_code = d.terms_code
	  AND d.sequence_id = (SELECT MIN(sequence_id) FROM aptermsd)
	  AND c.terms_type in (1,4)
	  AND b.date_discount != b.date_doc + d.discount_days
	  AND d.discount_prc != 0


	  SELECT 	 b.trx_ctrl_num,
			 b.date_discount,
			 d.discount_days,
			 c.min_days_due,
			 dtdate_doc = dateadd(dd,b.date_doc,'1/1/1800'),
			 dtdate_discount = dateadd(dd,b.date_discount,'1/1/1800'),
			 dtdate_calc = dateadd(dd,b.date_doc,'1/1/1800'),
			 d.discount_prc
	  INTO #date_calc2
	  FROM #apvovchg b, apterms c, aptermsd d
  	  WHERE b.terms_code = c.terms_code
	  AND c.terms_code = d.terms_code
	  AND d.sequence_id = (SELECT MIN(sequence_id) FROM aptermsd)
	  AND c.terms_type = 2


	  DELETE #date_calc2
	  WHERE dtdate_doc < '1/3/3552'
	  OR dtdate_discount < '1/3/3552'

	  DELETE #date_calc2
	  WHERE discount_days = 0
	  OR discount_prc = 0
	  

	  UPDATE #date_calc2
	  SET dtdate_doc = dateadd(dd,-657072,dtdate_doc),
	      dtdate_discount = dateadd(dd,-657072,dtdate_discount),
		  dtdate_calc = dateadd(dd,-657072,dtdate_calc)      

	  UPDATE #date_calc2
	  SET dtdate_calc = dateadd(mm,1,dtdate_calc)
	  FROM #date_calc2
	  WHERE (discount_days - datepart(dd,dtdate_doc)) < min_days_due

	  UPDATE #date_calc2
	  SET dtdate_calc = dateadd(dd,discount_days,     dateadd(dd,-datepart(dd,dtdate_doc),dtdate_calc)  )
	  FROM #date_calc2


	  UPDATE #date_calc2
	  SET dtdate_calc = dateadd(dd,   -datepart(dd,dtdate_calc),  dtdate_calc)
	  FROM #date_calc2
	  WHERE datepart(dd,dtdate_calc) < discount_days
      


      INSERT #ewerror
	  SELECT 4000,
			 10190,
			 '',
			 '',
			 date_discount,
			 0.0,
			 3,
			 trx_ctrl_num,
			 0,
			 '',
			 0
	  FROM #date_calc2
	  WHERE dtdate_discount != dtdate_calc

	  DROP TABLE #date_calc2

      INSERT #ewerror
	  SELECT 4000,
			 10190,
			 '',
			 '',
			 b.date_discount,
			 0.0,
			 3,
			 b.trx_ctrl_num,
			 0,
			 '',
			 0
	  FROM #apvovchg b, apterms c, aptermsd d
  	  WHERE b.terms_code = c.terms_code
	  AND c.terms_code = d.terms_code
	  AND d.sequence_id = (SELECT MIN(sequence_id) FROM aptermsd)
	  AND c.terms_type = 2
	  AND d.discount_days = 0
	  AND b.date_discount != b.date_doc + d.discount_days
	  AND d.discount_prc != 0



      INSERT #ewerror
	  SELECT 4000,
			 10190,
			 '',
			 '',
			 b.date_discount,
			 0.0,
			 3,
			 b.trx_ctrl_num,
			 0,
			 '',
			 0
	  FROM #apvovchg b, apterms c, aptermsd d
  	  WHERE b.terms_code = c.terms_code
	  AND c.terms_code = d.terms_code
	  AND d.sequence_id = (SELECT MIN(sequence_id) FROM aptermsd)
	  AND c.terms_type = 3
	  AND b.date_discount != d.date_discount
	  AND d.discount_prc != 0 

	INSERT #ewerror
	  SELECT 4000,
			 10190,
			 '',
			 '',
			 b.date_discount,
			 0.0,
			 3,
			 b.trx_ctrl_num,
			 0,
			 '',
			 0
	  FROM #apvovchg b, apterms c, aptermsd d
  	  WHERE b.terms_code = c.terms_code
	  AND c.terms_code = d.terms_code
	  AND d.sequence_id = (SELECT MIN(sequence_id) FROM aptermsd)
	  AND c.terms_type in (1,2,3,4)
	  AND b.date_discount != b.date_due
	  AND d.discount_prc = 0 

      
END


SELECT @credit_invoice_flag = credit_invoice_flag FROM apco

IF @credit_invoice_flag = 0
BEGIN
IF (SELECT err_type FROM apedterr WHERE err_code = 10670) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvehdr5.cpp" + ", line " + STR( 355, 5 ) + " -- MSG: " + "Check if amt_gross is negative"

      INSERT #ewerror
	  SELECT 4000,
			 10670,
			 "",
			 "",
			 0,
			 amt_gross,
			 4,
			 trx_ctrl_num,
			 0,
			 "",
			 0
	  FROM #apvovchg 
  	  WHERE ((amt_gross) < (0.0) - 0.0000001)
END

END

IF (SELECT err_type FROM apedterr WHERE err_code = 10679) <= @error_level
BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvehdr5.cpp" + ", line " + STR( 377, 5 ) + " -- MSG: " + "Check if amt_gross is the sum = line item distribution - tax_included"


	  SELECT a.trx_ctrl_num,
			 amt_gross = a.amt_gross + a.amt_tax_included,
			 amt_extended = SUM(b.amt_extended + isnull(b.amt_nonrecoverable_tax,0))	 
	  INTO 	 #amtgross_calc
	  FROM #apvovchg a, #apvovcdt b
	  WHERE a.trx_ctrl_num = b.trx_ctrl_num
	  GROUP BY a.trx_ctrl_num, a.amt_gross, a.amt_tax_included


      INSERT #ewerror
	  SELECT 4000,
			 10679,
			 "",
			 "",
			 0,
			 amt_gross,
			 4,
			 trx_ctrl_num,
			 0,
			 "",
			 0
	  FROM #amtgross_calc 
  	  WHERE (ABS((amt_gross)-(amt_extended)) > 0.0000001)


	DROP TABLE #amtgross_calc
END	 


IF @credit_invoice_flag = 0
BEGIN
IF (SELECT err_type FROM apedterr WHERE err_code = 10700) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvehdr5.cpp" + ", line " + STR( 413, 5 ) + " -- MSG: " + "Check if amt_discount is negative"

      INSERT #ewerror
	  SELECT 4000,
			 10700,
			 "",
			 "",
			 0,
			 amt_discount,
			 4,
			 trx_ctrl_num,
			 0,
			 "",
			 0
	  FROM #apvovchg 
  	  WHERE ((amt_discount) < (0.0) - 0.0000001)
END
END


IF (SELECT err_type FROM apedterr WHERE err_code = 10690) <= @error_level
BEGIN
   IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvehdr5.cpp" + ", line " + STR( 435, 5 ) + " -- MSG: " + "Check if amt_discount = line item distribution"

      INSERT #ewerror
	  SELECT 4000,
			 10690,
			 "",
			 "",
			 0,
			 b.amt_discount,
			 4,
			 b.trx_ctrl_num,
			 0,
			 "",
			 0
	  FROM #apvovchg b, #apvovcdt c
  	  WHERE b.trx_ctrl_num = c.trx_ctrl_num
	  GROUP BY b.trx_ctrl_num, b.amt_discount
	  HAVING (ABS((b.amt_discount)-(SUM(c.amt_discount))) > 0.0000001)
END


IF @credit_invoice_flag = 0
BEGIN
IF (SELECT err_type FROM apedterr WHERE err_code = 10720) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvehdr5.cpp" + ", line " + STR( 460, 5 ) + " -- MSG: " + "Check if amt_tax is negative"

      INSERT #ewerror
	  SELECT 4000,
			 10720,
			 "",
			 "",
			 0,
			 amt_tax,
			 5,
			 trx_ctrl_num,
			 0,
			 "",
			 0
	  FROM #apvovchg 
  	  WHERE ((amt_tax) < (0.0) - 0.0000001)
END

END

IF (SELECT err_type FROM apedterr WHERE err_code = 10715) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvehdr5.cpp" + ", line " + STR( 482, 5 ) + " -- MSG: " + "Check if amt_tax is 0"

      INSERT #ewerror
	  SELECT 4000,
			 10715,
			 "",
			 "",
			 0,
			 amt_tax,
			 4,
			 trx_ctrl_num,
			 0,
			 "",
			 0
	  FROM #apvovchg 
  	  WHERE (ABS((amt_tax)-(0.0)) < 0.0000001)
END


IF (SELECT err_type FROM apedterr WHERE err_code = 10716) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvehdr5.cpp" + ", line " + STR( 503, 5 ) + " -- MSG: " + "Check if amt_tax = line item distribution"
      INSERT #ewerror
	  SELECT 4000,
			 10716,
			 "",
			 "",
			 0,
			 b.amt_tax,
			 4,
			 b.trx_ctrl_num,
			 0,
			 "",
			 0
	  FROM #apvovchg b, #apvovcdt c
  	  WHERE b.trx_ctrl_num = c.trx_ctrl_num
	  GROUP BY b.trx_ctrl_num, b.amt_tax
	  HAVING (ABS((b.amt_tax)-(SUM(c.amt_tax))) > 0.0000001)
	  AND (ABS((SUM(c.amt_tax))-(0.0)) > 0.0000001)
END



IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvehdr5.cpp" + ", line " + STR( 525, 5 ) + " -- EXIT: "
RETURN 0
GO
GRANT EXECUTE ON  [dbo].[apvehdr5_sp] TO [public]
GO
