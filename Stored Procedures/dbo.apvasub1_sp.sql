SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE [dbo].[apvasub1_sp] @error_level smallint, @debug_level smallint = 0
AS
IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/apvasub1.sp" + ", line " + STR( 27, 5 ) + " -- ENTRY: "




IF (SELECT err_type FROM apedterr WHERE err_code = 31150) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/apvasub1.sp" + ", line " + STR( 34, 5 ) + " -- MSG: " + "Check if any aging sequence_id is less than 1"
	
 INSERT #ewerror
	 SELECT 4000,
			 31150,
			 "",
			 "",
			 sequence_id,
			 0.0,
			 2,
			 trx_ctrl_num,
			 sequence_id,
			 "",
			 0
	 FROM #apvavage 
 	 WHERE sequence_id < 1
END



IF (SELECT err_type FROM apedterr WHERE err_code = 31200) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/apvasub1.sp" + ", line " + STR( 58, 5 ) + " -- MSG: " + "Check if date due <= 0"
	
 INSERT #ewerror
	 SELECT 4000,
			 31200,
			 "",
			 "",
			 date_due,
			 0.0,
			 3,
			 trx_ctrl_num,
			 sequence_id,
			 "",
			 0
	 FROM #apvavage 
 	 WHERE date_due <= 0
END



IF (SELECT err_type FROM apedterr WHERE err_code = 31210) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/apvasub1.sp" + ", line " + STR( 82, 5 ) + " -- MSG: " + "Check if date aging <= 0"
	
 INSERT #ewerror
	 SELECT 4000,
			 31210,
			 "",
			 "",
			 date_aging,
			 0,
			 3,
			 trx_ctrl_num,
			 sequence_id,
			 "",
			 0
	 FROM #apvavage 
	 WHERE date_applied <= 0
END



IF (SELECT err_type FROM apedterr WHERE err_code = 31211) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/apvasub1.sp" + ", line " + STR( 106, 5 ) + " -- MSG: " + "Check if date aging matches header or header is 0"
	
 INSERT #ewerror
	 SELECT 4000,
			 31211,
			 "",
			 "",
			 b.date_aging,
			 0.0,
			 3,
			 b.trx_ctrl_num,
			 b.sequence_id,
			 "",
			 0
	 FROM #apvavage b, #apvavchg c
	 WHERE b.trx_ctrl_num = c.trx_ctrl_num
	 AND c.date_aging != 0
	 AND b.date_aging != c.date_aging
END







IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/apvasub1.sp" + ", line " + STR( 134, 5 ) + " -- EXIT: "
RETURN 0
GO
GRANT EXECUTE ON  [dbo].[apvasub1_sp] TO [public]
GO
