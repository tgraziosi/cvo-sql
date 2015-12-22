SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROC [dbo].[ARFLUpdateSummary_SP]	@batch_ctrl_num	varchar( 16 ),
					@debug_level		smallint,
					@perf_level		smallint,
					@home_precision	int,
					@oper_precision	int
AS






DECLARE
 @PERF_time_last datetime

SELECT @PERF_time_last = GETDATE()















									







DECLARE
	@result 		int

IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, "tmp/arflus.sp", 61, "Entering ARFLUpdateSummary_SP", @PERF_time_last OUTPUT

BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arflus.sp" + ", line " + STR( 64, 5 ) + " -- ENTRY: "

	
	IF 1 = (
			SELECT arsumcus_flag
			FROM	arco
		)
	BEGIN
		EXEC @result = ARFLUpdateCustomerSummary_SP	@batch_ctrl_num,
									@debug_level,
									@perf_level,
									@home_precision,
									@oper_precision
		IF( @result != 0 )
		BEGIN
			IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arflus.sp" + ", line " + STR( 81, 5 ) + " -- EXIT: "
			RETURN @result
		END
	END

	
	IF 1 = (	SELECT	arsumslp_flag
			FROM	arco
		)
	BEGIN
		EXEC @result = ARFLUpdateSalesSummary_SP	@batch_ctrl_num,
						 		@debug_level,
						 		@perf_level,
								@home_precision,
								@oper_precision
		IF( @result != 0 )
		BEGIN
			IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arflus.sp" + ", line " + STR( 100, 5 ) + " -- EXIT: "
			RETURN @result
		END
	END

	
	IF 1 = (	SELECT	arsumprc_flag
			FROM	arco
		)
	BEGIN
		EXEC @result = ARFLUpdatePriceSummary_SP	@batch_ctrl_num,
								@debug_level,
								@perf_level,
								@home_precision,
								@oper_precision
		IF( @result != 0 )
		BEGIN
			IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arflus.sp" + ", line " + STR( 119, 5 ) + " -- EXIT: "
			RETURN @result
		END
	END

	
	IF 1 = (	SELECT	arsumter_flag
			FROM	arco
		)
	BEGIN
		EXEC @result = ARFLUpdateTerritorySummary_SP	@batch_ctrl_num,
									@debug_level,
									@perf_level,
									@home_precision,
									@oper_precision
		IF( @result != 0 )
		BEGIN
			IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arflus.sp" + ", line " + STR( 138, 5 ) + " -- EXIT: "
			RETURN @result
		END
	END

	
	IF 1 = (	SELECT	arsumshp_flag
			FROM	arco
		)
	BEGIN
		EXEC @result = ARFLUpdateShipToSummary_SP	@batch_ctrl_num,
							 	@debug_level,
							 	@perf_level,
								@home_precision,
								@oper_precision
						
		IF( @result != 0 )
		BEGIN
			IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arflus.sp" + ", line " + STR( 158, 5 ) + " -- EXIT: "
			RETURN @result
		END
	END
	
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arflus.sp" + ", line " + STR( 163, 5 ) + " -- EXIT: "
	RETURN 0 
END
GO
GRANT EXECUTE ON  [dbo].[ARFLUpdateSummary_SP] TO [public]
GO
