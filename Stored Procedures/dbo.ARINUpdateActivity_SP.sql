SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROC [dbo].[ARINUpdateActivity_SP]	@batch_ctrl_num	varchar( 16 ),
					@debug_level		smallint,
					@perf_level		smallint,
					@home_precision	smallint,
					@oper_precision	smallint
AS






DECLARE
 @PERF_time_last datetime

SELECT @PERF_time_last = GETDATE()















									







DECLARE
	@result 		int

IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, "tmp/arinua.sp", 59, "Entering ARINUpdateActivity_SP", @PERF_time_last OUTPUT

BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arinua.sp" + ", line " + STR( 62, 5 ) + " -- ENTRY: "

	
	IF 1 = (
			SELECT aractcus_flag
			FROM	arco
		)
	BEGIN
		EXEC @result = ARINUpdateCustomerActivity_SP	@batch_ctrl_num,
									@debug_level,
									@perf_level,
									@home_precision,
									@oper_precision
		IF( @result != 0 )
		BEGIN
			IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arinua.sp" + ", line " + STR( 79, 5 ) + " -- EXIT: "
			RETURN @result
		END
	END

	
	IF 1 = (	SELECT	aractslp_flag
			FROM	arco
		)
	BEGIN
		EXEC @result = ARINUpdateSalesActivity_SP	@batch_ctrl_num,
						 		@debug_level,
								@perf_level,
								@home_precision,
								@oper_precision
		IF( @result != 0 )
		BEGIN
			IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arinua.sp" + ", line " + STR( 98, 5 ) + " -- EXIT: "
			RETURN @result
		END
	END
	
	
	IF 1 = (	SELECT	aractprc_flag
			FROM	arco
		)
	BEGIN
		EXEC @result = ARINUpdatePriceCodeActivity_SP	@batch_ctrl_num,
									@debug_level,
									@perf_level,
									@home_precision,
									@oper_precision
		IF( @result != 0 )
		BEGIN
			IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arinua.sp" + ", line " + STR( 117, 5 ) + " -- EXIT: "
			RETURN @result
		END
	END

	
	IF 1 = (	SELECT	aractter_flag
			FROM	arco
		)
	BEGIN
		EXEC @result = ARINUpdateTerritoryActivity_SP	@batch_ctrl_num,
									@debug_level,
									@perf_level,
									@home_precision,
									@oper_precision
		IF( @result != 0 )
		BEGIN
			IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arinua.sp" + ", line " + STR( 136, 5 ) + " -- EXIT: "
			RETURN @result
		END
	END
	
	
	IF 1 = (	SELECT	aractshp_flag
			FROM	arco
		)
	BEGIN
		EXEC @result = ARINUpdateShipToActivity_SP	@batch_ctrl_num,
									@debug_level,
									@perf_level,
									@home_precision,
									@oper_precision
		IF( @result != 0 )
		BEGIN
			IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arinua.sp" + ", line " + STR( 155, 5 ) + " -- EXIT: "
			RETURN @result
		END
	END
	
	IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, "tmp/arinua.sp", 160, "Leaving ARINUpdateActivity_SP", @PERF_time_last OUTPUT
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arinua.sp" + ", line " + STR( 161, 5 ) + " -- EXIT: "
	RETURN 0 
END
GO
GRANT EXECUTE ON  [dbo].[ARINUpdateActivity_SP] TO [public]
GO
