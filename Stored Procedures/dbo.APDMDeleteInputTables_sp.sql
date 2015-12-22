SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO



CREATE PROC [dbo].[APDMDeleteInputTables_sp] @debug_level smallint = 0
AS


IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apdmdit.cpp" + ", line " + STR( 46, 5 ) + " -- ENTRY: "

	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apdmdit.cpp" + ", line " + STR( 48, 5 ) + " -- MSG: " + "Delete records in #apdmchg_work"
	UPDATE  #apdmchg_work
	SET     db_action = db_action | 4
	
	IF (@@error != 0)
		RETURN -1

	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apdmdit.cpp" + ", line " + STR( 55, 5 ) + " -- MSG: " + "Delete records in #apinpcdt_work"
	UPDATE  #apdmcdt_work
	SET		db_action = db_action | 4

	IF (@@error!=0)
	    RETURN -1

	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apdmdit.cpp" + ", line " + STR( 62, 5 ) + " -- MSG: " + "Delete records in #apinptaxdtl_work"
	UPDATE  #apdmtaxdtl_work
	SET		db_action = db_action | 4

	IF (@@error!=0)
	    RETURN -1


IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apdmdit.cpp" + ", line " + STR( 70, 5 ) + " -- EXIT: "
RETURN 0
GO
GRANT EXECUTE ON  [dbo].[APDMDeleteInputTables_sp] TO [public]
GO
