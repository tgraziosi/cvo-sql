SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO






CREATE PROCEDURE [dbo].[appesub1_sp] @error_level smallint, @called_from smallint = 0, @debug_level smallint = 0
WITH RECOMPILE
AS

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/appesub1.sp" + ", line " + STR( 37, 5 ) + " -- ENTRY: "

IF (SELECT err_type FROM apedterr WHERE err_code = 670) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/appesub1.sp" + ", line " + STR( 41, 5 ) + " -- MSG: " + "Check if approval amt <= 0.0"
	
 INSERT #ewerror
	 SELECT 4000,
			 670,
			 "",
			 "",
			 0,
			 b.amount,
			 4,
			 b.trx_ctrl_num,
			 0,
			 "",
			 0
	 FROM #appyvpyt a, apaprtrx b
	 WHERE a.trx_ctrl_num = b.trx_ctrl_num
	 AND b.trx_type = 4111
	 AND ((b.amount) <= (0.0) + 0.0000001)
END


IF (SELECT err_type FROM apedterr WHERE err_code = 680) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/appesub1.sp" + ", line " + STR( 66, 5 ) + " -- MSG: " + "Check if approved flag is valid"
	
 INSERT #ewerror
	 SELECT 4000,
			 680,
			 "",
			 "",
			 b.approved_flag,
			 0.0,
			 2,
			 b.trx_ctrl_num,
			 0,
			 "",
			 0
	 FROM #appyvpyt a, apaprtrx b
	 WHERE a.trx_ctrl_num = b.trx_ctrl_num
	 AND b.trx_type = 4111
	 AND b.approved_flag NOT IN (0,1)
END



IF (SELECT err_type FROM apedterr WHERE err_code = 690) <= @error_level
BEGIN
	
 INSERT #ewerror
	 SELECT 4000,
			 690,
			 "",
			 "",
			 b.approved_flag,
			 0.0,
			 2,
			 b.trx_ctrl_num,
			 0,
			 "",
			 0
	 FROM apaprtrx b, #appyvpyt c
	 WHERE b.trx_type = 4111
	 AND b.trx_ctrl_num = c.trx_ctrl_num
	 AND b.approved_flag = 0
	 AND c.approval_flag = 0
END


IF (SELECT err_type FROM apedterr WHERE err_code = 700) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/appesub1.sp" + ", line " + STR( 117, 5 ) + " -- MSG: " + "Check if disapproved flag is valid"
	
 INSERT #ewerror
	 SELECT 4000,
			 700,
			 "",
			 "",
			 b.disappr_flag,
			 0.0,
			 2,
			 b.trx_ctrl_num,
			 0,
			 "",
			 0
	 FROM #appyvpyt a, apaprtrx b
	 WHERE a.trx_ctrl_num = b.trx_ctrl_num
	 AND b.trx_type = 4111
	 AND b.disappr_flag NOT IN (0,1)
END


IF (SELECT err_type FROM apedterr WHERE err_code = 710) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/appesub1.sp" + ", line " + STR( 142, 5 ) + " -- MSG: " + "Check if disapproved flag is 1"
	
 INSERT #ewerror
	 SELECT 4000,
			 710,
			 "",
			 "",
			 b.disappr_flag,
			 0.0,
			 2,
			 b.trx_ctrl_num,
			 0,
			 "",
			 0
	 FROM #appyvpyt a, apaprtrx b
	 WHERE a.trx_ctrl_num = b.trx_ctrl_num
	 AND b.trx_type = 4111
	 AND b.disappr_flag = 1
END




IF (SELECT err_type FROM apedterr WHERE err_code = 730) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/appesub1.sp" + ", line " + STR( 169, 5 ) + " -- MSG: " + "Check if disable flag is valid"
	
 INSERT #ewerror
	 SELECT 4000,
			 730,
			 "",
			 "",
			 b.disable_flag,
			 0.0,
			 2,
			 b.trx_ctrl_num,
			 0,
			 "",
			 0
	 FROM #appyvpyt a, apaprtrx b
	 WHERE a.trx_ctrl_num = b.trx_ctrl_num
	 AND b.trx_type = 4111
	 AND b.disable_flag NOT IN (0,1)
END



IF (SELECT err_type FROM apedterr WHERE err_code = 740) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/appesub1.sp" + ", line " + STR( 195, 5 ) + " -- MSG: " + "Check if date approved is valid"
	
 INSERT #ewerror
	 SELECT 4000,
			 740,
			 "",
			 "",
			 b.date_approved,
			 0.0,
			 3,
			 b.trx_ctrl_num,
			 0,
			 "",
			 0
	 FROM #appyvpyt a, apaprtrx b
	 WHERE a.trx_ctrl_num = b.trx_ctrl_num
	 AND b.trx_type = 4111
	 AND b.approved_flag != 0
	 AND (b.date_approved <= 0) 
END



IF (SELECT err_type FROM apedterr WHERE err_code = 750) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/appesub1.sp" + ", line " + STR( 222, 5 ) + " -- MSG: " + "Check if date doc is valid"
	
 INSERT #ewerror
	 SELECT 4000,
			 750,
			 "",
			 "",
			 b.date_doc,
			 0.0,
			 3,
			 b.trx_ctrl_num,
			 0,
			 "",
			 0
	 FROM #appyvpyt a, apaprtrx b
	 WHERE a.trx_ctrl_num = b.trx_ctrl_num
	 AND b.trx_type = 4111
	 AND b.date_doc <= 0
END


			
IF (SELECT err_type FROM apedterr WHERE err_code = 760) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/appesub1.sp" + ", line " + STR( 248, 5 ) + " -- MSG: " + "Check if date assigned is valid"
	
 INSERT #ewerror
	 SELECT 4000,
			 760,
			 "",
			 "",
			 b.date_assigned,
			 0.0,
			 3,
			 b.trx_ctrl_num,
			 0,
			 "",
			 0
	 FROM #appyvpyt a, apaprtrx b
	 WHERE a.trx_ctrl_num = b.trx_ctrl_num
	 AND b.trx_type = 4111
	 AND b.date_assigned <= 0
END

IF (SELECT err_type FROM apedterr WHERE err_code = 770) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/appesub1.sp" + ", line " + STR( 272, 5 ) + " -- MSG: " + "Check if approval code is valid"
	
 INSERT #ewerror
	 SELECT 4000,
			 770,
			 b.approval_code,
			 "",
			 0,
			 0.0,
			 1,
			 b.trx_ctrl_num,
			 0,
			 "",
			 0
	 FROM #appyvpyt a, apaprtrx b
	 WHERE a.trx_ctrl_num = b.trx_ctrl_num
	 AND b.trx_type = 4111
	 AND b.approval_code NOT IN (SELECT approval_code FROM apapr)
END


IF (SELECT err_type FROM apedterr WHERE err_code = 780) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/appesub1.sp" + ", line " + STR( 297, 5 ) + " -- MSG: " + "Check if sequence_flag is valid"
	
 INSERT #ewerror
	 SELECT 4000,
			 780,
			 "",
			 "",
			 b.sequence_flag,
			 0.0,
			 2,
			 b.trx_ctrl_num,
			 0,
			 "",
			 0
	 FROM #appyvpyt a, apaprtrx b
	 WHERE a.trx_ctrl_num = b.trx_ctrl_num
	 AND b.trx_type = 4111
	 AND b.sequence_flag NOT IN (0,1)
END



IF (SELECT err_type FROM apedterr WHERE err_code = 790) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/appesub1.sp" + ", line " + STR( 323, 5 ) + " -- MSG: " + "Check if appr_seq_id is valid"
	
 INSERT #ewerror
	 SELECT 4000,
			 790,
			 "",
			 "",
			 b.appr_seq_id,
			 0.0,
			 2,
			 b.trx_ctrl_num,
			 0,
			 "",
			 0
	 FROM #appyvpyt a, apaprtrx b
	 WHERE a.trx_ctrl_num = b.trx_ctrl_num
	 AND b.trx_type = 4111
	 AND b.appr_seq_id <= 0
END


IF (SELECT err_type FROM apedterr WHERE err_code = 800) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/appesub1.sp" + ", line " + STR( 348, 5 ) + " -- MSG: " + "Check if appr_complete is valid"
	
 INSERT #ewerror
	 SELECT 4000,
			 800,
			 "",
			 "",
			 b.appr_complete,
			 0.0,
			 2,
			 b.trx_ctrl_num,
			 0,
			 "",
			 0
	 FROM #appyvpyt a, apaprtrx b
	 WHERE a.trx_ctrl_num = b.trx_ctrl_num
	 AND b.trx_type = 4111
	 AND b.appr_complete NOT IN (0,1)
END


IF (SELECT err_type FROM apedterr WHERE err_code = 810) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/appesub1.sp" + ", line " + STR( 373, 5 ) + " -- MSG: " + "Check if vendor_code matches header vendor_code"
	
 INSERT #ewerror
	 SELECT 4000,
			 810,
			 b.vendor_code,
			 "",
			 0,
			 0.0,
			 1,
			 b.trx_ctrl_num,
			 0,
			 "",
			 0
	 FROM apaprtrx b, #appyvpyt c
	 WHERE b.trx_type = 4111
	 AND b.trx_ctrl_num = c.trx_ctrl_num
	 AND b.vendor_code != c.vendor_code
END


IF (SELECT err_type FROM apedterr WHERE err_code = 820) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/appesub1.sp" + ", line " + STR( 398, 5 ) + " -- MSG: " + "Check if origin_flag is valid"
	
 INSERT #ewerror
	 SELECT 4000,
			 820,
			 "",
			 "",
			 b.origin_flag,
			 0.0,
			 2,
			 b.trx_ctrl_num,
			 0,
			 "",
			 0
	 FROM #appyvpyt a, apaprtrx b
	 WHERE a.trx_ctrl_num = b.trx_ctrl_num
	 AND b.trx_type = 4111
	 AND b.origin_flag NOT IN (1,2,3)
END


IF (SELECT err_type FROM apedterr WHERE err_code = 650) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/appesub1.sp" + ", line " + STR( 423, 5 ) + " -- MSG: " + "Check if approval records are missing"
	
 INSERT #ewerror
	 SELECT 4000,
			 650,
			 "",
			 "",
			 0,
			 0.0,
			 0,
			 b.trx_ctrl_num,
			 0,
			 "",
			 0
	 FROM #appyvpyt b, apco c
	 WHERE c.aprv_check_flag = 1
	 AND b.trx_ctrl_num NOT IN (SELECT trx_ctrl_num FROM apaprtrx)
	 AND b.approval_flag != 0
END


						


IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/appesub1.sp" + ", line " + STR( 449, 5 ) + " -- EXIT: "
RETURN 0
GO
GRANT EXECUTE ON  [dbo].[appesub1_sp] TO [public]
GO
