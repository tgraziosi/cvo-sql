SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO



CREATE PROC [dbo].[APVODeleteInputTables_sp] @debug_level smallint = 0
AS


IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvodit.cpp" + ", line " + STR( 49, 5 ) + " -- ENTRY: "

	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvodit.cpp" + ", line " + STR( 51, 5 ) + " -- MSG: " + "Delete records in #apvochg_work"
	UPDATE  #apvochg_work
	SET     db_action = db_action | 4
	
	IF (@@error != 0)
		RETURN -1

	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvodit.cpp" + ", line " + STR( 58, 5 ) + " -- MSG: " + "Delete records in #apvocdt_work"
	UPDATE  #apvocdt_work
	SET		db_action = db_action | 4

	IF (@@error!=0)
	    RETURN -1

	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvodit.cpp" + ", line " + STR( 65, 5 ) + " -- MSG: " + "Delete records in #apvotax_work"
	UPDATE  #apvotax_work
	SET		db_action = db_action | 4

	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvodit.cpp" + ", line " + STR( 69, 5 ) + " -- MSG: " + "Delete records in #apvotaxdtl_work"
	UPDATE  #apvotaxdtl_work
	SET		db_action = db_action | 4

	IF (@@error!=0)
	    RETURN -1

	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvodit.cpp" + ", line " + STR( 76, 5 ) + " -- MSG: " + "Delete records in #apvoage_work"
	UPDATE  #apvoage_work
	SET		db_action = db_action | 4

	IF (@@error!=0)
	    RETURN -1

	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvodit.cpp" + ", line " + STR( 83, 5 ) + " -- MSG: " + "Delete records in #apvotmp_work"
	UPDATE  #apvotmp_work
	SET		db_action = db_action | 4

	IF (@@error!=0)
	    RETURN -1


IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvodit.cpp" + ", line " + STR( 91, 5 ) + " -- EXIT: "
RETURN 0
GO
GRANT EXECUTE ON  [dbo].[APVODeleteInputTables_sp] TO [public]
GO
