SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROC [dbo].[ARCMCreateTempIndexes_SP]		@batch_ctrl_num		varchar( 16 ),
											@debug_level		smallint = 0,
 			@perf_level			smallint = 0	
AS






DECLARE
 @PERF_time_last datetime

SELECT @PERF_time_last = GETDATE()















									







DECLARE
 @result 	int

IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, "tmp/arcmcti.sp", 62, "Entering ARCMCreateTempIndexes_SP", @PERF_time_last OUTPUT

BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcmcti.sp" + ", line " + STR( 65, 5 ) + " -- ENTRY: "

	IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, "tmp/arcmcti.sp", 67, "Leaving ARCMCreateTempIndexes_SP", @PERF_time_last OUTPUT
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcmcti.sp" + ", line " + STR( 68, 5 ) + " -- EXIT: "
 RETURN 0
END
GO
GRANT EXECUTE ON  [dbo].[ARCMCreateTempIndexes_SP] TO [public]
GO
