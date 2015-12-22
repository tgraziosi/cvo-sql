SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROC [dbo].[ARFLUpdateActivitySummary_SP]	@batch_ctrl_num	varchar( 16 ),
						@debug_level		smallint,
						@perf_level		smallint
AS






DECLARE
 @PERF_time_last datetime

SELECT @PERF_time_last = GETDATE()















									







DECLARE
	@home_precision	int,
	@oper_precision	int,
	@result 		int

IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, "tmp/arfluas.sp", 62, "Entering ARFLUpdateActivitySummary_SP", @PERF_time_last OUTPUT

BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arfluas.sp" + ", line " + STR( 65, 5 ) + " -- ENTRY: "
	
	SELECT	@home_precision = curr_precision
	FROM	glcurr_vw, glco
	WHERE	glco.home_currency = glcurr_vw.currency_code
	
	SELECT	@oper_precision = curr_precision
	FROM	glcurr_vw, glco
	WHERE	glco.oper_currency = glcurr_vw.currency_code

	
	EXEC @result = ARFLUpdateActivity_SP	@batch_ctrl_num,
							@debug_level,
							@perf_level,
							@home_precision,
							@oper_precision
	IF( @result != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arfluas.sp" + ", line " + STR( 85, 5 ) + " -- EXIT: "
		RETURN @result
	END

	
	EXEC @result = ARFLUpdateSummary_SP	@batch_ctrl_num,
							@debug_level,
							@perf_level,
							@home_precision,
							@oper_precision	
	IF( @result != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arfluas.sp" + ", line " + STR( 99, 5 ) + " -- EXIT: "
		RETURN @result
	END
	
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arfluas.sp" + ", line " + STR( 103, 5 ) + " -- EXIT: "
	RETURN 0 
END
GO
GRANT EXECUTE ON  [dbo].[ARFLUpdateActivitySummary_SP] TO [public]
GO
