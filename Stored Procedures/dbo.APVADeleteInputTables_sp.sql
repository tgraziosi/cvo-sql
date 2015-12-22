SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO



CREATE PROC [dbo].[APVADeleteInputTables_sp] @debug_level smallint = 0
AS


IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/apvadit.sp" + ", line " + STR( 46, 5 ) + " -- ENTRY: "

	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/apvadit.sp" + ", line " + STR( 48, 5 ) + " -- MSG: " + "Delete records in #apvachg_work"
	UPDATE #apvachg_work
	SET db_action = db_action | 4
	
	IF (@@error != 0)
		RETURN -1

	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/apvadit.sp" + ", line " + STR( 55, 5 ) + " -- MSG: " + "Delete records in #apvacdt_work"
	UPDATE #apvacdt_work
	SET		db_action = db_action | 4

	IF (@@error!=0)
	 RETURN -1

	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/apvadit.sp" + ", line " + STR( 62, 5 ) + " -- MSG: " + "Delete records in #apvaage_work"
	UPDATE #apvaage_work
	SET		db_action = db_action | 4

	IF (@@error!=0)
	 RETURN -1


IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/apvadit.sp" + ", line " + STR( 70, 5 ) + " -- EXIT: "
RETURN 0
GO
GRANT EXECUTE ON  [dbo].[APVADeleteInputTables_sp] TO [public]
GO
