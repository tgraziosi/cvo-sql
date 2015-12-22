SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO





CREATE PROC [dbo].[APPYDeleteInputTables_sp] @debug_level smallint = 0
AS


IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/appydit.sp" + ", line " + STR( 45, 5 ) + " -- ENTRY: "

	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/appydit.sp" + ", line " + STR( 47, 5 ) + " -- MSG: " + "Delete records in #appypyt_work"
	UPDATE #appypyt_work
	SET db_action = db_action | 4
	
	IF (@@error != 0)
		RETURN -1

	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/appydit.sp" + ", line " + STR( 54, 5 ) + " -- MSG: " + "Delete records in #appypdt_work"
	UPDATE #appypdt_work
	SET		db_action = db_action | 4

	IF (@@error!=0)
	 RETURN -1



IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/appydit.sp" + ", line " + STR( 63, 5 ) + " -- EXIT: "
RETURN 0
GO
GRANT EXECUTE ON  [dbo].[APPYDeleteInputTables_sp] TO [public]
GO
