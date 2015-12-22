SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROC [dbo].[ARWOPostTemp_SP]	@batch_ctrl_num	varchar(16),
				@process_ctrl_num	varchar(16),
				@debug_level		smallint,
				@perf_level		smallint

AS






DECLARE
 @PERF_time_last datetime

SELECT @PERF_time_last = GETDATE()















									







DECLARE
	@result	int

IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, "tmp/arwopt.sp", 52, "Entering ARWOPostTemp_SP", @PERF_time_last OUTPUT

BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arwopt.sp" + ", line " + STR( 55, 5 ) + " -- ENTRY: "

	
CREATE TABLE #arwotemp
(
	trx_ctrl_num		varchar(16),
	trx_type			smallint,
	journal_ctrl_num	varchar(16)
)



	EXEC @result = ARWOCreateDependantTrans_SP 	@batch_ctrl_num,
								@debug_level,
								@perf_level


	IF( @result != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arwopt.sp" + ", line " + STR( 67, 5 ) + " -- EXIT: "
		RETURN @result
	END

	EXEC @result = ARWOMoveUnpostedRecords_SP	@batch_ctrl_num,
							@debug_level,
							@perf_level

	IF( @result != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arwopt.sp" + ", line " + STR( 77, 5 ) + " -- EXIT: "
		RETURN @result
	END

	EXEC @result = ARWOUpdateDependTrans_SP 	@batch_ctrl_num,
							@process_ctrl_num,
							@debug_level,
							@perf_level

	IF( @result != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arwopt.sp" + ", line " + STR( 88, 5 ) + " -- EXIT: "
		RETURN @result
	END


	EXEC @result = ARWOSumActInsTmp_SP		@batch_ctrl_num,
							@debug_level,
							@perf_level

	IF( @result != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arwopt.sp" + ", line " + STR( 99, 5 ) + " -- EXIT: "
		RETURN @result
	END

	IF ( @debug_level > 2 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arwopt.sp" + ", line " + STR( 103, 5 ) + " -- MSG: " + "After call to ARWOSumActInsTmp_SP"
	

	IF ( @debug_level > 2 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arwopt.sp" + ", line " + STR( 106, 5 ) + " -- MSG: " + "After call to ARWOMoveUnpostedRecords_SP"

	IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, "tmp/arwopt.sp", 108, "Exiting ARWOPostTemp_SP", @PERF_time_last OUTPUT
	RETURN 0

	DROP TABLE #arwotemp

END

GO
GRANT EXECUTE ON  [dbo].[ARWOPostTemp_SP] TO [public]
GO
