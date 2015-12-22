SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE [dbo].[apdehdr3_sp] @error_level smallint, @debug_level smallint = 0
AS

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apdehdr3.cpp" + ", line " + STR( 36, 5 ) + " -- ENTRY: "


IF (SELECT err_type FROM apedterr WHERE err_code = 20140) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apdehdr3.cpp" + ", line " + STR( 41, 5 ) + " -- MSG: " + "Check if date doc is valid"
	


      INSERT #ewerror
	  SELECT 4000,
			 20140,
			 "",
			 "",
			 date_doc,
			 0.0,
			 3,
			 trx_ctrl_num,
			 0,
			 "",
			 0
	  FROM #apdmvchg 
  	  WHERE date_doc <= 0
END


IF (SELECT err_type FROM apedterr WHERE err_code = 20150) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apdehdr3.cpp" + ", line " + STR( 64, 5 ) + " -- MSG: " + "Check if date entered is valid"
	


      INSERT #ewerror
	  SELECT 4000,
			 20150,
			 "",
			 "",
			 date_entered,
			 0.0,
			 3,
			 trx_ctrl_num,
			 0,
			 "",
			 0
	  FROM #apdmvchg 
  	  WHERE date_entered <= 0
END




IF (SELECT err_type FROM apedterr WHERE err_code = 20670) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apdehdr3.cpp" + ", line " + STR( 89, 5 ) + " -- MSG: " + "Check if amt_gross is negative"

      INSERT #ewerror
	  SELECT 4000,
			 20670,
			 "",
			 "",
			 0,
			 amt_gross,
			 4,
			 trx_ctrl_num,
			 0,
			 "",
			 0
	  FROM #apdmvchg 
  	  WHERE ((amt_gross) < (0.0) - 0.0000001)
END



IF (SELECT err_type FROM apedterr WHERE err_code = 20679) <= @error_level
BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apdehdr3.cpp" + ", line " + STR( 111, 5 ) + " -- MSG: " + "Check if amt_gross is the sum = line item distribution"


	  SELECT a.trx_ctrl_num,
			 amt_gross = a.amt_gross + a.amt_tax_included,
			 amt_extended = SUM(b.amt_extended + b.amt_nonrecoverable_tax) 
	  INTO 	 #amtgross_calc
	  FROM #apdmvchg a, #apdmvcdt b
	  WHERE a.trx_ctrl_num = b.trx_ctrl_num
	  GROUP BY a.trx_ctrl_num, a.amt_gross, a.amt_tax_included


      INSERT #ewerror
	  SELECT 4000,
			 20679,
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



IF (SELECT err_type FROM apedterr WHERE err_code = 20700) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apdehdr3.cpp" + ", line " + STR( 146, 5 ) + " -- MSG: " + "Check if amt_discount is negative"

      INSERT #ewerror
	  SELECT 4000,
			 20700,
			 "",
			 "",
			 0,
			 amt_discount,
			 4,
			 trx_ctrl_num,
			 0,
			 "",
			 0
	  FROM #apdmvchg 
  	  WHERE ((amt_discount) < (0.0) - 0.0000001)
END



IF (SELECT err_type FROM apedterr WHERE err_code = 20690) <= @error_level
BEGIN
   IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apdehdr3.cpp" + ", line " + STR( 168, 5 ) + " -- MSG: " + "Check if amt_discount = line item distribution"

      INSERT #ewerror
	  SELECT 4000,
			 20690,
			 "",
			 "",
			 0,
			 b.amt_discount,
			 4,
			 b.trx_ctrl_num,
			 0,
			 "",
			 0
	  FROM #apdmvchg b, #apdmvcdt c
  	  WHERE b.trx_ctrl_num = c.trx_ctrl_num
	  GROUP BY b.trx_ctrl_num, b.amt_discount
	  HAVING (ABS((b.amt_discount)-(SUM(c.amt_discount))) > 0.0000001)
END



IF (SELECT err_type FROM apedterr WHERE err_code = 20720) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apdehdr3.cpp" + ", line " + STR( 192, 5 ) + " -- MSG: " + "Check if amt_tax is negative"

      INSERT #ewerror
	  SELECT 4000,
			 20720,
			 "",
			 "",
			 0,
			 amt_tax,
			 5,
			 trx_ctrl_num,
			 0,
			 "",
			 0
	  FROM #apdmvchg 
  	  WHERE ((amt_tax) < (0.0) - 0.0000001)
END

IF (SELECT err_type FROM apedterr WHERE err_code = 20715) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apdehdr3.cpp" + ", line " + STR( 212, 5 ) + " -- MSG: " + "Check if amt_tax is 0"

      INSERT #ewerror
	  SELECT 4000,
			 20715,
			 "",
			 "",
			 0,
			 amt_tax,
			 4,
			 trx_ctrl_num,
			 0,
			 "",
			 0
	  FROM #apdmvchg 
  	  WHERE (ABS((amt_tax)-(0.0)) < 0.0000001)
END


IF (SELECT err_type FROM apedterr WHERE err_code = 20716) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apdehdr3.cpp" + ", line " + STR( 233, 5 ) + " -- MSG: " + "Check if amt_tax = line item distribution"
      INSERT #ewerror
	  SELECT 4000,
			 20716,
			 "",
			 "",
			 0,
			 b.amt_tax,
			 4,
			 b.trx_ctrl_num,
			 0,
			 "",
			 0
	  FROM #apdmvchg b, #apdmvcdt c
  	  WHERE b.trx_ctrl_num = c.trx_ctrl_num
	  GROUP BY b.trx_ctrl_num, b.amt_tax
	  HAVING (ABS((b.amt_tax)-(SUM(c.amt_tax))) > 0.0000001)
	  AND (ABS((SUM(c.amt_tax))-(0.0)) > 0.0000001)
END

IF (SELECT err_type FROM apedterr WHERE err_code = 20710) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apdehdr3.cpp" + ", line " + STR( 255, 5 ) + " -- MSG: " + "Check if amt_tax exceeds tax detail distribution"

      INSERT #ewerror
	  SELECT 4000,
			 20710,
			 "",
			 "",
			 0,
			 b.amt_tax,
			 4,
			 b.trx_ctrl_num,
			 0,
			 "",
			 0
	  FROM #apdmvchg b, #apdmvtax c
  	  WHERE b.trx_ctrl_num = c.trx_ctrl_num
	  GROUP BY b.trx_ctrl_num, b.amt_tax
	  HAVING 
((ABS(b.amt_tax)) > (SUM(ABS(c.amt_final_tax))) + 0.0000001) 
END





IF (SELECT err_type FROM apedterr WHERE err_code = 20740) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apdehdr3.cpp" + ", line " + STR( 282, 5 ) + " -- MSG: " + "Check if amt_freight is negative"

      INSERT #ewerror
	  SELECT 4000,
			 20740,
			 "",
			 "",
			 0,
			 amt_freight,
			 4,
			 trx_ctrl_num,
			 0,
			 "",
			 0
	  FROM #apdmvchg 
  	  WHERE ((amt_freight) < (0.0) - 0.0000001)
END


IF (SELECT err_type FROM apedterr WHERE err_code = 20730) <= @error_level
BEGIN
  	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apdehdr3.cpp" + ", line " + STR( 303, 5 ) + " -- MSG: " + "Check if amt_freight = line item distribution"

      INSERT #ewerror
	  SELECT 4000,
			 20730,
			 "",
			 "",
			 0,
			 b.amt_freight,
			 4,
			 b.trx_ctrl_num,
			 0,
			 "",
			 0
	  FROM #apdmvchg b, #apdmvcdt c
  	  WHERE b.trx_ctrl_num = c.trx_ctrl_num
	  GROUP BY b.trx_ctrl_num, b.amt_freight
	  HAVING 
(ABS((b.amt_freight)-(SUM(c.amt_freight))) > 0.0000001)
END


IF (SELECT err_type FROM apedterr WHERE err_code = 20760) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apdehdr3.cpp" + ", line " + STR( 327, 5 ) + " -- MSG: " + "Check if amt_misc is negative"

      INSERT #ewerror
	  SELECT 4000,
			 20760,
			 "",
			 "",
			 0,
			 amt_misc,
			 4,
			 trx_ctrl_num,
			 0,
			 "",
			 0
	  FROM #apdmvchg
  	  WHERE ((amt_misc) < (0.0) - 0.0000001)
END


IF (SELECT err_type FROM apedterr WHERE err_code = 20750) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apdehdr3.cpp" + ", line " + STR( 348, 5 ) + " -- MSG: " + "Check if amt_misc = line item distribution"

      INSERT #ewerror
	  SELECT 4000,
			 20750,
			 "",
			 "",
			 0,
			 b.amt_misc,
			 4,
			 b.trx_ctrl_num,
			 0,
			 "",
			 0
	  FROM #apdmvchg b, #apdmvcdt c
  	  WHERE b.trx_ctrl_num = c.trx_ctrl_num
	  GROUP BY b.trx_ctrl_num, b.amt_misc
	  HAVING 
(ABS((b.amt_misc)-(SUM(c.amt_misc))) > 0.0000001) 
END


IF (SELECT err_type FROM apedterr WHERE err_code = 20820) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apdehdr3.cpp" + ", line " + STR( 372, 5 ) + " -- MSG: " + "Check if amt_net is negative"
      INSERT #ewerror
	  SELECT 4000,
			 20820,
			 "",
			 "",
			 0,
			 amt_net,
			 4,
			 trx_ctrl_num,
			 0,
			 "",
			 0
	  FROM #apdmvchg 
  	  WHERE ((amt_net) < (0.0) - 0.0000001)
END



IF (SELECT err_type FROM apedterr WHERE err_code = 20800) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apdehdr3.cpp" + ", line " + STR( 393, 5 ) + " -- MSG: " + "Check if amt_net = gross + tax + freight + freight tax non recoverable + misc - disc"
      INSERT #ewerror
	  SELECT 4000,
			 20800,
			 "",
			 "",
			 0,
			 amt_net,
			 4,
			 trx_ctrl_num,
			 0,
			 "",
			 0
	  FROM #apdmvchg 
  	  WHERE 
(ABS((amt_net)-(amt_gross + amt_tax + amt_freight + tax_freight_no_recoverable + amt_misc - amt_discount)) > 0.0000001)
END


IF (SELECT err_type FROM apedterr WHERE err_code = 20810) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apdehdr3.cpp" + ", line " + STR( 414, 5 ) + " -- MSG: " + "Check if debit memo of same amount and vendor already exists"
      INSERT #ewerror
	  SELECT 4000,
			 20810,
			 "",
			 "",
			 0,
			 b.amt_net,
			 4,
			 b.trx_ctrl_num,
			 0,
			 "",
			 0
	  FROM #apdmvchg b
  	  WHERE EXISTS (SELECT * FROM apinpchg c
                      WHERE c.vendor_code = b.vendor_code
		      AND c.amt_net = b.amt_net  


		      AND c.trx_ctrl_num != b.trx_ctrl_num
		      AND c.trx_type = 4092)
END	



IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apdehdr3.cpp" + ", line " + STR( 439, 5 ) + " -- EXIT: "
RETURN 0
GO
GRANT EXECUTE ON  [dbo].[apdehdr3_sp] TO [public]
GO
