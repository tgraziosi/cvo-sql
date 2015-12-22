SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO





CREATE PROC [dbo].[ARCMLockInsertDepend_SP]	@batch_ctrl_num	varchar( 16 ),
						@process_ctrl_num	varchar( 16 ),
						@batch_proc_flag	smallint,
						@debug_level		smallint = 0,
						@perf_level		smallint = 0 
AS






DECLARE
 @PERF_time_last datetime

SELECT @PERF_time_last = GETDATE()















									







DECLARE	@result		int,
		@trans_unlocked_flag	int

IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, "tmp/arcmlid.sp", 57, "Entering ARCMLockInsertDepend_SP", @PERF_time_last OUTPUT

BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcmlid.sp" + ", line " + STR( 60, 5 ) + " -- ENTRY: "

	
	EXEC @result = ARCMLockDependancies_SP	@batch_ctrl_num,
							@process_ctrl_num,
							@batch_proc_flag,
							@debug_level,
							@perf_level
	IF( @result != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcmlid.sp" + ", line " + STR( 72, 5 ) + " -- EXIT: "
		RETURN @result
	END

	
	EXEC @result = ARCMInsertDependancies_SP	@batch_ctrl_num,
							@process_ctrl_num,
							@debug_level,
							@perf_level
	IF( @result != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcmlid.sp" + ", line " + STR( 85, 5 ) + " -- EXIT: "
		RETURN @result
	END

	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcmlid.sp" + ", line " + STR( 89, 5 ) + " -- EXIT: "
	IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, "tmp/arcmlid.sp", 90, "Leaving ARCMLockInsertDepend_SP", @PERF_time_last OUTPUT
	RETURN 0
END
GO
GRANT EXECUTE ON  [dbo].[ARCMLockInsertDepend_SP] TO [public]
GO
