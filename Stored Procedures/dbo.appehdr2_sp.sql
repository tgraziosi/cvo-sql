SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO






CREATE PROCEDURE [dbo].[appehdr2_sp] @error_level smallint, @called_from smallint, @debug_level smallint = 0
WITH RECOMPILE
AS

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/appehdr2.sp" + ", line " + STR( 35, 5 ) + " -- ENTRY: "



IF (SELECT err_type FROM apedterr WHERE err_code = 180) <= @error_level
BEGIN
 IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/appehdr2.sp" + ", line " + STR( 41, 5 ) + " -- MSG: " + "Check if date doc <= 0"
	
 INSERT #ewerror
	 SELECT 4000,
			 180,
			 "",
			 "",
			 date_doc,
			 0.0,
			 3,
			 trx_ctrl_num,
			 0,
			 "",
			 0
	 FROM #appyvpyt 
 	 WHERE date_doc <= 0
END


IF (SELECT err_type FROM apedterr WHERE err_code = 190) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/appehdr2.sp" + ", line " + STR( 64, 5 ) + " -- MSG: " + "Check if date applied and date_doc in same period"
	
 INSERT #ewerror
	 SELECT 4000,
			 190,
			 "",
			 "",
			 b.date_doc,
			 0.0,
			 3,
			 b.trx_ctrl_num,
			 0,
			 "",
			 0
	 FROM #appyvpyt b, glprd c, glprd d
	 WHERE b.date_applied <= c.period_end_date 
	 AND b.date_applied >= c.period_start_date
	 AND b.date_doc <= d.period_end_date 
	 AND b.date_doc >= d.period_start_date
	 AND c.period_end_date != d.period_end_date
END


IF (@called_from != 1)
BEGIN
IF (SELECT err_type FROM apedterr WHERE err_code = 200) <= @error_level
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/appehdr2.sp" + ", line " + STR( 93, 5 ) + " -- MSG: " + "Check if one time vendor address exists"
		
 INSERT #ewerror
	 SELECT 4000,
			 200,
			 b.pay_to_code,
			 "",
			 0,
			 0.0,
			 1,
			 b.trx_ctrl_num,
			 0,
			 "",
			 0
	 FROM #appyvpyt b, apco c
	 WHERE b.vendor_code = c.one_time_vend_code
	 AND NOT EXISTS (SELECT * FROM apvnd_vw d 
		 				WHERE d.vendor_code = b.vendor_code
		 				AND d.pay_to_code = b.pay_to_code)
	END
END


IF (SELECT err_type FROM apedterr WHERE err_code = 210) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/appehdr2.sp" + ", line " + STR( 120, 5 ) + " -- MSG: " + "Check if vendor code exists"
	
 INSERT #ewerror
	 SELECT 4000,
			 210,
			 vendor_code,
			 "",
			 0,
			 0.0,
			 1,
			 trx_ctrl_num,
			 0,
			 "",
			 0
	 FROM #appyvpyt 
	 WHERE vendor_code NOT IN (SELECT vendor_code FROM apvend)
END


IF (SELECT err_type FROM apedterr WHERE err_code = 220) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/appehdr2.sp" + ", line " + STR( 143, 5 ) + " -- MSG: " + "Check if vendor code is active"
	
 INSERT #ewerror
	 SELECT 4000,
	 		 220,
			 b.vendor_code,
			 "",
			 0,
			 0.0,
			 1,
			 b.trx_ctrl_num,
			 0,
			 "",
			 0
	 FROM #appyvpyt b, apvend c
	 WHERE b.vendor_code = c.vendor_code
	 AND c.status_type != 5
END



IF (SELECT err_type FROM apedterr WHERE err_code = 230) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/appehdr2.sp" + ", line " + STR( 168, 5 ) + " -- MSG: " + "Check if vendor code is on payment_hold"
	
 INSERT #ewerror
	 SELECT 4000,
			 230,
			 b.vendor_code,
			 "",
			 0,
			 0.0,
			 1,
			 b.trx_ctrl_num,
			 0,
			 "",
			 0
	 FROM #appyvpyt b, apvend c
	 WHERE b.vendor_code = c.vendor_code
	 AND c.status_type = 1
END
	 
IF (@called_from != 1)
BEGIN

	IF (SELECT err_type FROM apedterr WHERE err_code = 240) <= @error_level
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/appehdr2.sp" + ", line " + STR( 194, 5 ) + " -- MSG: " + "Check if pay_to_code exists"
		
	 INSERT #ewerror
		 SELECT 4000,
				 240,
				 b.pay_to_code,
				 "",
				 0,
				 0.0,
				 1,
				 b.trx_ctrl_num,
				 0,
				 "",
				 0
		 FROM #appyvpyt b, apco d
		 WHERE NOT EXISTS (SELECT * FROM apvnd_vw c 
			 				 WHERE c.vendor_code = b.vendor_code 
			 				 AND c.pay_to_code = b.pay_to_code)
		 AND b.pay_to_code != ""
	END
END

IF (SELECT err_type FROM apedterr WHERE err_code = 250) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/appehdr2.sp" + ", line " + STR( 220, 5 ) + " -- MSG: " + "Check if pay_to_code is active"
	
 INSERT #ewerror
	 SELECT 4000,
			 250,
			 b.pay_to_code,
			 "",
			 0,
			 0.0,
			 1,
			 b.trx_ctrl_num,
			 0,
			 "",
			 0
	 FROM #appyvpyt b, apvnd_vw c
	 WHERE b.vendor_code = c.vendor_code
	 AND b.pay_to_code = c.pay_to_code
	 AND c.status_type != 5
END


IF ((SELECT aprv_check_flag FROM apco) = 1)
 BEGIN

 IF (SELECT err_type FROM apedterr WHERE err_code = 260) <= @error_level
 BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/appehdr2.sp" + ", line " + STR( 248, 5 ) + " -- MSG: " + "Check if approval_code exists"
		
	 INSERT #ewerror
		 SELECT 4000,
				 260,
				 approval_code,
				 "",
				 0,
				 0.0,
				 1,
				 trx_ctrl_num,
				 0,
				 "",
				 0
		 FROM #appyvpyt 
		 WHERE approval_code NOT IN (SELECT approval_code FROM apapr)
		 AND approval_code != ""
	 END


 IF (SELECT err_type FROM apedterr WHERE err_code = 270) <= @error_level
 BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/appehdr2.sp" + ", line " + STR( 272, 5 ) + " -- MSG: " + "Check if approval_code is blank"
		
	 INSERT #ewerror
		 SELECT DISTINCT 4000,
				 270,
				 a.approval_code,
				 "",
				 0,
				 0.0,
				 1,
				 a.trx_ctrl_num,
				 0,
				 "",
				 0
		 FROM #appyvpyt a, apaprtrx b
		 WHERE a.trx_ctrl_num = b.trx_ctrl_num
		 AND b.trx_type = 4111
		 AND a.approval_code = ""
	 END

 END
ELSE
 BEGIN

	IF (SELECT err_type FROM apedterr WHERE err_code = 290) <= @error_level
	 BEGIN
			IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/appehdr2.sp" + ", line " + STR( 300, 5 ) + " -- MSG: " + "Check if approval_code exists"
			
	 	 INSERT #ewerror
		 	 SELECT 4000,
					 290,
					 approval_code,
					 "",
					 0,
					 0.0,
					 1,
					 trx_ctrl_num,
					 0,
					 "",
					 0
			 FROM #appyvpyt 
			 WHERE approval_code NOT IN (SELECT approval_code FROM apapr)
			 AND approval_code != ""
	 END

 END


IF (SELECT err_type FROM apedterr WHERE err_code = 300) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/appehdr2.sp" + ", line " + STR( 326, 5 ) + " -- MSG: " + "Check if approval_code is the default in apco"
	
 INSERT #ewerror
	 SELECT 4000,
			 300,
			 b.approval_code,
			 "",
			 0,
			 0.0,
			 1,
			 b.trx_ctrl_num,
			 0,
			 "",
			 0
	 FROM #appyvpyt b, apco c
	 WHERE b.approval_code != c.default_aprv_code
	 AND b.approval_code != ""
	 AND c.aprv_check_flag = 1
	 AND c.default_aprv_flag = 1
	 AND c.aprv_opr_flag = 1
END


IF (SELECT err_type FROM apedterr WHERE err_code = 310) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/appehdr2.sp" + ", line " + STR( 353, 5 ) + " -- MSG: " + "Check if approval_code is the default in apco"
	
 INSERT #ewerror
	 SELECT 4000,
			 310,
			 b.approval_code,
			 "",
			 0,
			 0.0,
			 1,
			 b.trx_ctrl_num,
			 0,
			 "",
			 0
	 FROM #appyvpyt b, apco c
	 WHERE b.approval_code != c.default_aprv_code
	 AND b.approval_code != ""
	 AND c.aprv_check_flag = 1
	 AND c.default_aprv_flag = 1
	 AND c.aprv_opr_flag = 0
END


IF (SELECT err_type FROM apedterr WHERE err_code = 320) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/appehdr2.sp" + ", line " + STR( 380, 5 ) + " -- MSG: " + "Check if payment_code is blank"
	
 INSERT #ewerror
	 SELECT 4000,
			 320,
			 payment_code,
			 "",
			 0,
			 0.0,
			 1,
			 trx_ctrl_num,
			 0,
			 "",
			 0
	 FROM #appyvpyt 
	 WHERE payment_code = ""
	 AND payment_type != 3
END


IF (SELECT err_type FROM apedterr WHERE err_code = 330) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/appehdr2.sp" + ", line " + STR( 404, 5 ) + " -- MSG: " + "Check if payment_code exists in appymeth"
	
 INSERT #ewerror
	 SELECT 4000,
			 330,
			 payment_code,
			 "",
			 0,
			 0.0,
			 1,
			 trx_ctrl_num,
			 0,
			 "",
			 0
	 FROM #appyvpyt 
	 WHERE payment_code NOT IN (SELECT payment_code FROM appymeth)
	 AND payment_code != ""
END


IF (SELECT err_type FROM apedterr WHERE err_code = 345) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/appehdr2.sp" + ", line " + STR( 428, 5 ) + " -- MSG: " + "Check if payment_type is valid"
	
 INSERT #ewerror
	 SELECT 4000,
			 345,
			 "",
			 "",
			 payment_type,
			 0.0,
			 2,
			 trx_ctrl_num,
			 0,
			 "",
			 0
	 FROM #appyvpyt 
	 WHERE payment_type NOT IN (1,2,3)
END









IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/appehdr2.sp" + ", line " + STR( 456, 5 ) + " -- EXIT: "
RETURN 0
GO
GRANT EXECUTE ON  [dbo].[appehdr2_sp] TO [public]
GO
