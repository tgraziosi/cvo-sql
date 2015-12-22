SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROC [dbo].[ARINUpdateActivitySummary_SP]	@batch_ctrl_num	varchar( 16 ),
						@debug_level		smallint,
						@perf_level		smallint
AS






DECLARE
 @PERF_time_last datetime

SELECT @PERF_time_last = GETDATE()















									







DECLARE
	@result 		int,
	@home_precision	smallint,
	@oper_precision	smallint


IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, "tmp/arinuas.sp", 63, "Entering ARINUpdateActivitySummary_SP", @PERF_time_last OUTPUT

BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arinuas.sp" + ", line " + STR( 66, 5 ) + " -- ENTRY: "

	
	SELECT	@home_precision = curr_precision
	FROM	glco, glcurr_vw
	WHERE	glco.home_currency = glcurr_vw.currency_code

	SELECT	@oper_precision = curr_precision
	FROM	glco, glcurr_vw
	WHERE	glco.oper_currency = glcurr_vw.currency_code
	
	
	EXEC @result = ARINUpdateActivity_SP	@batch_ctrl_num,
							@debug_level,
							@perf_level,
							@home_precision,
							@oper_precision
	IF( @result != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arinuas.sp" + ", line " + STR( 90, 5 ) + " -- EXIT: "
		RETURN @result
	END

	
	EXEC @result = ARINUpdateSummary_SP	@batch_ctrl_num,
							@debug_level,
							@perf_level,
							@home_precision,
							@oper_precision
	IF( @result != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arinuas.sp" + ", line " + STR( 104, 5 ) + " -- EXIT: "
		RETURN @result
	END
	
	IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, "tmp/arinuas.sp", 108, "Leaving ARINUpdateActivitySummary_SP", @PERF_time_last OUTPUT
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arinuas.sp" + ", line " + STR( 109, 5 ) + " -- EXIT: "
	RETURN 0 
END
GO
GRANT EXECUTE ON  [dbo].[ARINUpdateActivitySummary_SP] TO [public]
GO
