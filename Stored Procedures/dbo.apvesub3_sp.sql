SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[apvesub3_sp] @error_level smallint, @debug_level smallint = 0
AS

DECLARE @precision int

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/apvesub3.sp" + ", line " + STR( 38, 5 ) + " -- ENTRY: "


	SELECT @precision = curr_precision
	FROM glcurr_vw a, glco b
	WHERE a.currency_code = b.home_currency


IF (SELECT err_type FROM apedterr WHERE err_code = 11330) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/apvesub3.sp" + ", line " + STR( 48, 5 ) + " -- MSG: " + "Check if amt_payment <= 0.0"
	
 INSERT #ewerror
	 SELECT 4000,
			 11330,
			 "",
			 "",
			 0,
			 amt_payment,
			 4,
			 trx_ctrl_num,
			 0,
			 "",
			 0
	 FROM #apvovtmp 
 	 WHERE ((amt_payment) <= (0.0) + 0.0000001)
END





IF (SELECT err_type FROM apedterr WHERE err_code = 11360) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/apvesub3.sp" + ", line " + STR( 74, 5 ) + " -- MSG: " + "Check if amt_disc_taken < 0.0"
	
 INSERT #ewerror
	 SELECT 4000,
			 11360,
			 "",
			 "",
			 0,
			 amt_disc_taken,
			 4,
			 trx_ctrl_num,
			 0,
			 "",
			 0
	 FROM #apvovtmp 
 	 WHERE ((amt_disc_taken) < (0.0) - 0.0000001)
END



IF (SELECT err_type FROM apedterr WHERE err_code = 11350) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/apvesub3.sp" + ", line " + STR( 98, 5 ) + " -- MSG: " + "Check if amt_disc_taken > amt_payment"
	
 INSERT #ewerror
	 SELECT 4000,
			 11350,
			 "",
			 "",
			 0,
			 amt_disc_taken,
			 4,
			 trx_ctrl_num,
			 0,
			 "",
			 0
	 FROM #apvovtmp 
 	 WHERE ((amt_disc_taken) > (amt_payment) + 0.0000001)
END



IF (SELECT err_type FROM apedterr WHERE err_code = 11370) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/apvesub3.sp" + ", line " + STR( 122, 5 ) + " -- MSG: " + "Check if payment_code is valid"
	
 INSERT #ewerror
	 SELECT 4000,
			 11370,
			 payment_code,
			 "",
			 0,
			 0.0,
			 1,
			 trx_ctrl_num,
			 0,
			 "",
			 0
	 FROM #apvovtmp 
 	 WHERE payment_code NOT IN (SELECT payment_code FROM appymeth)
	 AND payment_code != ""
END




IF (SELECT err_type FROM apedterr WHERE err_code = 11380) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/apvesub3.sp" + ", line " + STR( 148, 5 ) + " -- MSG: " + "Check if system generated check"
	
 INSERT #ewerror
	 SELECT 4000,
			 11380,
			 b.payment_code,
			 "",
			 0,
			 0.0,
			 1,
			 b.trx_ctrl_num,
			 0,
			 "",
			 0
	 FROM #apvovtmp b, appymeth c
 	 WHERE b.payment_code = c.payment_code
	 AND c.payment_type = 2
	 AND b.payment_type = 1
END



IF (SELECT err_type FROM apedterr WHERE err_code = 11385) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/apvesub3.sp" + ", line " + STR( 174, 5 ) + " -- MSG: " + "Check if bank generated check"
	
 INSERT #ewerror
	 SELECT 4000,
			 11385,
			 b.payment_code,
			 "",
			 0,
			 0.0,
			 1,
			 b.trx_ctrl_num,
			 0,
			 "",
			 0
	 FROM #apvovtmp b, appymeth c
 	 WHERE b.payment_code = c.payment_code
	 AND c.payment_type = 3
	 AND b.payment_type = 1
END


IF (SELECT err_type FROM apedterr WHERE err_code = 11380) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/apvesub3.sp" + ", line " + STR( 199, 5 ) + " -- MSG: " + "Check if payment_type is valid"
	
 INSERT #ewerror
	 SELECT 4000,
			 11380,
			 "",
			 "",
			 payment_type,
			 0.0,
			 2,
			 trx_ctrl_num,
			 0,
			 "",
			 0
	 FROM #apvovtmp 
 	 WHERE payment_type NOT IN (1,2,3)
END


IF (SELECT err_type FROM apedterr WHERE err_code = 11390) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/apvesub3.sp" + ", line " + STR( 222, 5 ) + " -- MSG: " + "Check if approval_flag is valid"
	
 INSERT #ewerror
	 SELECT 4000,
			 11390,
			 "",
			 "",
			 approval_flag,
			 0.0,
			 2,
			 trx_ctrl_num,
			 0,
			 "",
			 0
	 FROM #apvovtmp 
 	 WHERE approval_flag NOT IN (0,1)
END



IF (SELECT err_type FROM apedterr WHERE err_code = 11240) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/apvesub3.sp" + ", line " + STR( 246, 5 ) + " -- MSG: " + "Check if payment record is missing"
	
 INSERT #ewerror
	 SELECT 4000,
			 11240,
			 "",
			 "",
			 0,
			 amt_paid,
			 4,
			 trx_ctrl_num,
			 0,
			 "",
			 0
	 FROM #apvovchg 
 	 WHERE ((amt_paid) > (0.0) + 0.0000001)
	 AND trx_ctrl_num NOT IN (SELECT trx_ctrl_num FROM apinptmp)
END



IF (SELECT err_type FROM apedterr WHERE err_code = 11340) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/apvesub3.sp" + ", line " + STR( 271, 5 ) + " -- MSG: " + "Check if sum of payments = voucher amt_paid"
	
 INSERT #ewerror
	 SELECT 4000,
			 11340,
			 "",
			 "",
			 0,
			 sum(b.amt_payment),
			 4,
			 b.trx_ctrl_num,
			 0,
			 "",
			 0
	 FROM #apvovtmp b, #apvovchg c
 	 WHERE b.trx_ctrl_num = c.trx_ctrl_num
	 GROUP BY b.trx_ctrl_num, c.amt_paid																
	 HAVING 
(((SIGN(c.amt_paid) * ROUND(ABS(c.amt_paid) + 0.0000001, @precision))) > ((SIGN(sum(b.amt_payment + b.amt_disc_taken)) * ROUND(ABS(sum(b.amt_payment + b.amt_disc_taken)) + 0.0000001, @precision))) + 0.0000001)							
END



IF (SELECT err_type FROM apedterr WHERE err_code = 11410) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/apvesub3.sp" + ", line " + STR( 298, 5 ) + " -- MSG: " + "Check if amount <= 0.0"
	
 INSERT #ewerror
	 SELECT 4000,
			 11410,
			 "",
			 "",
			 0,
			 b.amount,
			 4,
			 b.trx_ctrl_num,
			 0,
			 "",
			 0
	 FROM #apvovchg a, apaprtrx b
 	 WHERE a.trx_ctrl_num = b.trx_ctrl_num
	 AND b.trx_type = 4091
	 AND ((b.amount) <= (0.0) + 0.0000001)
END




IF (SELECT err_type FROM apedterr WHERE err_code = 11440) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/apvesub3.sp" + ", line " + STR( 325, 5 ) + " -- MSG: " + "Check if date approved is valid"
	
 INSERT #ewerror
	 SELECT 4000,
			 11440,
			 "",
			 "",
			 b.date_approved,
			 0.0,
			 3,
			 b.trx_ctrl_num,
			 0,
			 "",
			 0
	 FROM #apvovchg a, apaprtrx b
 	 WHERE a.trx_ctrl_num = b.trx_ctrl_num
	 AND b.trx_type = 4091
	 AND b.date_approved <= 0
	 AND b.approved_flag = 1
END



IF (SELECT err_type FROM apedterr WHERE err_code = 11450) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/apvesub3.sp" + ", line " + STR( 352, 5 ) + " -- MSG: " + "Check if date doc is valid"
	
 INSERT #ewerror
	 SELECT 4000,
			 11450,
			 "",
			 "",
			 b.date_doc,
			 0.0,
			 3,
			 b.trx_ctrl_num,
			 0,
			 "",
			 0
	 FROM #apvovchg a, apaprtrx b
 	 WHERE a.trx_ctrl_num = b.trx_ctrl_num
	 AND b.trx_type = 4091
	 AND b.date_doc <= 0
END



IF (SELECT err_type FROM apedterr WHERE err_code = 11460) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/apvesub3.sp" + ", line " + STR( 378, 5 ) + " -- MSG: " + "Check if date assigned is valid"
	
 INSERT #ewerror
	 SELECT 4000,
			 11460,
			 "",
			 "",
			 b.date_assigned,
			 0.0,
			 3,
			 b.trx_ctrl_num,
			 0,
			 "",
			 0
	 FROM #apvovchg a, apaprtrx b
 	 WHERE a.trx_ctrl_num = b.trx_ctrl_num
	 AND b.trx_type = 4091
	 AND b.date_assigned <= 0
END



IF (SELECT err_type FROM apedterr WHERE err_code = 11470) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/apvesub3.sp" + ", line " + STR( 404, 5 ) + " -- MSG: " + "Check if vendor code is different from header"
	
 INSERT #ewerror
	 SELECT 4000,
			 11470,
			 b.vendor_code,
			 "",
			 0,
			 0.0,
			 1,
			 b.trx_ctrl_num,
			 0,
			 "",
			 0
	 FROM apaprtrx b, #apvovchg c
 	 WHERE b.trx_ctrl_num = c.trx_ctrl_num
	 AND b.trx_type = 4091
	 AND b.vendor_code != c.vendor_code
END



IF (SELECT err_type FROM apedterr WHERE err_code = 11400) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/apvesub3.sp" + ", line " + STR( 430, 5 ) + " -- MSG: " + "Check if approval records are missing"
	
 INSERT #ewerror
	 SELECT 4000,
			 11400,
			 "",
			 "",
			 0,
			 0.0,
			 0,
			 trx_ctrl_num,
			 0,
			 "",
			 0
	 FROM #apvovchg 
 	 WHERE approval_flag = 1
	 AND trx_ctrl_num NOT IN (SELECT trx_ctrl_num FROM apaprtrx)
END





IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/apvesub3.sp" + ", line " + STR( 455, 5 ) + " -- EXIT: "
RETURN 0
GO
GRANT EXECUTE ON  [dbo].[apvesub3_sp] TO [public]
GO
