SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROC [dbo].[ARWOCreateDependantTrans_SP]	@batch_ctrl_num	varchar(16),
						@debug_level		smallint,
						@perf_level		smallint

AS






DECLARE
 @PERF_time_last datetime

SELECT @PERF_time_last = GETDATE()















									






											 
DECLARE
	@result	int

IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, "tmp/arwocdt.sp", 38, "Entering ARWOCreateDependantTrans_SP", @PERF_time_last OUTPUT

BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arwocdt.sp" + ", line " + STR( 41, 5 ) + " -- ENTRY: "

	

	EXEC @result = ARWOCreateGLTrans_SP	@batch_ctrl_num,
							@debug_level,
							@perf_level

	IF(@result != 0)
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arwocdt.sp" + ", line " + STR( 53, 5 ) + " -- EXIT: "
		RETURN @result
	END

	
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arwocdt.sp" + ", line " + STR( 58, 5 ) + " -- EXIT: "
	IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, "tmp/arwocdt.sp", 59, "Leaving ARWOPostTemp_SP", @PERF_time_last OUTPUT
 RETURN 0 

END
GO
GRANT EXECUTE ON  [dbo].[ARWOCreateDependantTrans_SP] TO [public]
GO
