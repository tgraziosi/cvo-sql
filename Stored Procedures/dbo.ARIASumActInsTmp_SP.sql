SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROC [dbo].[ARIASumActInsTmp_SP]	@batch_ctrl_num	varchar( 16 ),
					@perf_level		smallint,
					@debug_level		int = 0
AS

DECLARE	@result int

BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/ariasait.sp" + ", line " + STR( 35, 5 ) + " -- ENTRY: "
	
	
	EXEC @result = ARIAUpdateActivity_SP	@batch_ctrl_num,
							@perf_level,
							@debug_level

	IF ( @result != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/ariasait.sp" + ", line " + STR( 46, 5 ) + " -- EXIT: "
		RETURN @result
	END

	
	EXEC @result = ARIAUpdateSummary_SP	@batch_ctrl_num,
							@perf_level,
							@debug_level

	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/ariasait.sp" + ", line " + STR( 57, 5 ) + " -- EXIT: "
	RETURN @result

END


/**/                                              
GO
GRANT EXECUTE ON  [dbo].[ARIASumActInsTmp_SP] TO [public]
GO
