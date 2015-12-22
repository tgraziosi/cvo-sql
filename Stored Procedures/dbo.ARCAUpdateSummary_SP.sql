SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO



CREATE PROC [dbo].[ARCAUpdateSummary_SP]	@batch_ctrl_num	varchar( 16 ),
					@debug_level		smallint,
					@perf_level		smallint,
					@home_precision	float,
					@oper_precision	float	
AS






DECLARE
 @PERF_time_last datetime

SELECT @PERF_time_last = GETDATE()















									







DECLARE
	@result 		int

IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, "tmp/arcaus.sp", 31, "Entering ARCAUpdateSummary_SP", @PERF_time_last OUTPUT

BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcaus.sp" + ", line " + STR( 34, 5 ) + " -- ENTRY: "

	
	IF 1 = (
			SELECT arsumcus_flag
			FROM	arco
		)
	BEGIN
		EXEC @result = ARCAUpdateCustomerSummary_SP	@batch_ctrl_num,
									@debug_level,
									@perf_level,
									@home_precision,
									@oper_precision
		IF( @result != 0 )
		BEGIN
			IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcaus.sp" + ", line " + STR( 51, 5 ) + " -- EXIT: "
			RETURN @result
		END
	END
	

	
	IF 1 = (	SELECT	arsumslp_flag
			FROM	arco
		)
	BEGIN
		EXEC @result = ARCAUpdateSalesSummary_SP	@batch_ctrl_num,
						 		@debug_level,
						 		@perf_level,
								@home_precision,
								@oper_precision
		IF( @result != 0 )
		BEGIN
			IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcaus.sp" + ", line " + STR( 71, 5 ) + " -- EXIT: "
			RETURN @result
		END
	END
	
	
	
	IF 1 = (	SELECT	arsumprc_flag
			FROM	arco
		)
	BEGIN
		EXEC @result = ARCAUpdatePriceSummary_SP	@batch_ctrl_num,
								@debug_level,
								@perf_level,
								@home_precision,
								@oper_precision
		IF( @result != 0 )
		BEGIN
			IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcaus.sp" + ", line " + STR( 91, 5 ) + " -- EXIT: "
			RETURN @result
		END
	END


	
	IF 1 = (	SELECT	arsumter_flag
			FROM	arco
		)
	BEGIN
		EXEC @result = ARCAUpdateTErritorySummary_SP	@batch_ctrl_num,
									@debug_level,
									@perf_level,
									@home_precision,
									@oper_precision
		IF( @result != 0 )
		BEGIN
			IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcaus.sp" + ", line " + STR( 111, 5 ) + " -- EXIT: "
			RETURN @result
		END
	END
	

	
	IF 1 = (	SELECT	arsumshp_flag
			FROM	arco
		)
	BEGIN
		EXEC @result = ARCAUpdateShipToSummary_SP	@batch_ctrl_num,
							 	@debug_level,
							 	@perf_level,
								@home_precision,
								@oper_precision
		IF( @result != 0 )
		BEGIN
			IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcaus.sp" + ", line " + STR( 131, 5 ) + " -- EXIT: "
			RETURN @result
		END
	END
	

	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcaus.sp" + ", line " + STR( 137, 5 ) + " -- EXIT: "
	RETURN 0 
END
GO
GRANT EXECUTE ON  [dbo].[ARCAUpdateSummary_SP] TO [public]
GO
