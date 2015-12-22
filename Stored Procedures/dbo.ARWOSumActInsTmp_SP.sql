SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROC [dbo].[ARWOSumActInsTmp_SP] 	@batch_ctrl_num 	varchar(16),
					@debug_level		smallint = 0,
					@perf_level		smallint = 0
AS
DECLARE	@result	int

BEGIN 
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arwosait.sp" + ", line " + STR( 36, 5 ) + " -- ENTRY: "

	IF ( @debug_level > 2 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arwosait.sp" + ", line " + STR( 38, 5 ) + " -- MSG: " + "batch_ctrl_num = " + @batch_ctrl_num

	EXEC @result = ARWOUpdateSummary_SP 	@batch_ctrl_num,
							@debug_level,
							@perf_level

	IF (@result != 0)
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arwosait.sp" + ", line " + STR( 46, 5 ) + " -- EXIT: "
		RETURN @result
	END

	EXEC @result = ARWOUpdateActivity_SP 	@batch_ctrl_num,
							@debug_level,
							@perf_level

	IF (@result != 0)
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arwosait.sp" + ", line " + STR( 56, 5 ) + " -- EXIT: "
		RETURN @result
	END

	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arwosait.sp" + ", line " + STR( 60, 5 ) + " -- EXIT: "
	RETURN 0

END


/**/                                              
GO
GRANT EXECUTE ON  [dbo].[ARWOSumActInsTmp_SP] TO [public]
GO
