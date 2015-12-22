SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE [dbo].[apdesub1_sp] @error_level smallint, @debug_level smallint = 0
AS
IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/apdesub1.sp" + ", line " + STR( 35, 5 ) + " -- ENTRY: "


IF (SELECT err_type FROM apedterr WHERE err_code = 21080) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/apdesub1.sp" + ", line " + STR( 40, 5 ) + " -- MSG: " + "Check if any tax sequence_id is less than 1"
	
 INSERT #ewerror
	 SELECT 4000,
			 21080,
			 "",
			 "",
			 sequence_id,
			 0.0,
			 2,
			 trx_ctrl_num,
			 sequence_id,
			 "",
			 0
	 FROM #apdmvtax 
 	 WHERE sequence_id < 1
END


IF (SELECT err_type FROM apedterr WHERE err_code = 21090) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/apdesub1.sp" + ", line " + STR( 63, 5 ) + " -- MSG: " + "Check if any tax_type_code is blank"
	
 INSERT #ewerror
	 SELECT 4000,
			 21090,
			 tax_type_code,
			 "",
			 0,
			 0.0,
			 1,
			 trx_ctrl_num,
			 sequence_id,
			 "",
			 0
	 FROM #apdmvtax 
 	 WHERE tax_type_code = ""
END


IF (SELECT err_type FROM apedterr WHERE err_code = 21100) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/apdesub1.sp" + ", line " + STR( 86, 5 ) + " -- MSG: " + "Check if any tax_type_code is valid"
	
 INSERT #ewerror
	 SELECT 4000,
			 21100,
			 tax_type_code,
			 "",
			 0,
			 0.0,
			 1,
			 trx_ctrl_num,
			 sequence_id,
			 "",
			 0
	 FROM #apdmvtax 
 	 WHERE tax_type_code NOT IN (SELECT tax_type_code FROM aptxtype)
END



IF (SELECT err_type FROM apedterr WHERE err_code = 21110) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/apdesub1.sp" + ", line " + STR( 110, 5 ) + " -- MSG: " + "Check if amt_taxable is negative"
	
 INSERT #ewerror
	 SELECT 4000,
			 21110,
			 "",
			 "",
			 0,
			 amt_taxable,
			 4,
			 trx_ctrl_num,
			 sequence_id,
			 "",
			 0
	 FROM #apdmvtax b
 	 WHERE ((amt_taxable) < (0.0) - 0.0000001)
END

IF (SELECT err_type FROM apedterr WHERE err_code = 21120) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/apdesub1.sp" + ", line " + STR( 132, 5 ) + " -- MSG: " + "Check if amt_gross is negative"
	
 INSERT #ewerror
	 SELECT 4000,
			 21120,
			 "",
			 "",
			 0,
			 amt_gross,
			 4,
			 trx_ctrl_num,
			 sequence_id,
			 "",
			 0
	 FROM #apdmvtax b
 	 WHERE ((amt_gross) < (0.0) - 0.0000001)
END


IF (SELECT err_type FROM apedterr WHERE err_code = 21130) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/apdesub1.sp" + ", line " + STR( 155, 5 ) + " -- MSG: " + "Check if amt_tax is negative"
	
 INSERT #ewerror
	 SELECT 4000,
			 21130,
			 "",
			 "",
			 0,
			 amt_tax,
			 4,
			 trx_ctrl_num,
			 sequence_id,
			 "",
			 0
	 FROM #apdmvtax
 	 WHERE ((amt_tax) < (0.0) - 0.0000001)
END


IF (SELECT err_type FROM apedterr WHERE err_code = 21140) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/apdesub1.sp" + ", line " + STR( 178, 5 ) + " -- MSG: " + "Check if amt_final_tax is negative"
	
 INSERT #ewerror
	 SELECT 4000,
			 21140,
			 "",
			 "",
			 0,
			 amt_final_tax,
			 4,
			 trx_ctrl_num,
			 sequence_id,
			 "",
			 0
	 FROM #apdmvtax 
 	 WHERE ((amt_final_tax) < (0.0) - 0.0000001)
END





IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/apdesub1.sp" + ", line " + STR( 202, 5 ) + " -- EXIT: "
RETURN 0
GO
GRANT EXECUTE ON  [dbo].[apdesub1_sp] TO [public]
GO
