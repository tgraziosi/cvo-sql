SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO



CREATE PROC [dbo].[ARCAUpdateActivity_SP]	@batch_ctrl_num	varchar( 16 ),
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

IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, "tmp/arcaua.sp", 42, "Entering ARCAUpdateActivity_SP", @PERF_time_last OUTPUT

BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcaua.sp" + ", line " + STR( 45, 5 ) + " -- ENTRY: "

	
	IF 1 = (
			SELECT aractcus_flag
			FROM	arco
		)
	BEGIN
		EXEC @result = ARCAUpdateCustomerActivity_SP	@batch_ctrl_num,
									@debug_level,
									@perf_level,
									@home_precision,
									@oper_precision	
		IF( @result != 0 )
		BEGIN
			IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcaua.sp" + ", line " + STR( 62, 5 ) + " -- EXIT: "
			RETURN @result
		END
	END

	
	IF 1 = (	SELECT	aractslp_flag
			FROM	arco
		)
	BEGIN
		EXEC @result = ARCAUpdateSalesActivity_SP	@batch_ctrl_num,
						 		@debug_level,
								@perf_level,
								@home_precision,
								@oper_precision	
		IF( @result != 0 )
		BEGIN
			IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcaua.sp" + ", line " + STR( 81, 5 ) + " -- EXIT: "
			RETURN @result
		END
	END
	
	
	IF 1 = (	SELECT	aractprc_flag
			FROM	arco
		)
	BEGIN
		EXEC @result = ARCAUpdatePriceActivity_SP	@batch_ctrl_num,
								@debug_level,
								@perf_level,
								@home_precision,
								@oper_precision	
		IF( @result != 0 )
		BEGIN
			IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcaua.sp" + ", line " + STR( 100, 5 ) + " -- EXIT: "
			RETURN @result
		END
	END

	
	IF 1 = (	SELECT	aractter_flag
			FROM	arco
		)
	BEGIN
		EXEC @result = ARCAUpdateTerritoryActivity_SP	@batch_ctrl_num,
									@debug_level,
									@perf_level,
									@home_precision,
									@oper_precision	
		IF( @result != 0 )
		BEGIN
			IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcaua.sp" + ", line " + STR( 119, 5 ) + " -- EXIT: "
			RETURN @result
		END
	END
	
	
	IF 1 = (	SELECT	aractter_flag
			FROM	arco
		)
	BEGIN
		EXEC @result = ARCAUpdateShipToActivity_SP	@batch_ctrl_num,
									@debug_level,
									@perf_level,
									@home_precision,
									@oper_precision	
		IF( @result != 0 )
		BEGIN
			IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcaua.sp" + ", line " + STR( 138, 5 ) + " -- EXIT: "
			RETURN @result
		END
	END
	
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcaua.sp" + ", line " + STR( 143, 5 ) + " -- EXIT: "
	RETURN 0 
END
GO
GRANT EXECUTE ON  [dbo].[ARCAUpdateActivity_SP] TO [public]
GO
