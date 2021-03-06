SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROC [dbo].[ARFLUpdateActivity_SP]	@batch_ctrl_num	varchar( 16 ),
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

IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, "tmp/arflua.sp", 59, "Entering ARFLUpdateActivity_SP", @PERF_time_last OUTPUT

BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arflua.sp" + ", line " + STR( 62, 5 ) + " -- ENTRY: "

	
	IF 1 = (
			SELECT aractcus_flag
			FROM	arco
		)
	BEGIN
		EXEC @result = ARFLUpdateCustomerActivity_SP	@batch_ctrl_num,
									@debug_level,
									@perf_level,
									@home_precision,
									@oper_precision

		IF( @result != 0 )
		BEGIN
			IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arflua.sp" + ", line " + STR( 80, 5 ) + " -- EXIT: "
			RETURN @result
		END
	END

	
	IF 1 = (	SELECT	aractslp_flag
			FROM	arco
		)
	BEGIN
		EXEC @result = ARFLUpdateSalesActivity_SP	@batch_ctrl_num,
						 		@debug_level,
						 		@perf_level,
								@home_precision,
								@oper_precision
		IF( @result != 0 )
		BEGIN
			IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arflua.sp" + ", line " + STR( 99, 5 ) + " -- EXIT: "
			RETURN @result
		END
	END
	
	
	IF 1 = (	SELECT	aractprc_flag
			FROM	arco
		)
	BEGIN
		EXEC @result = ARFLUpdatePriceActivity_SP	@batch_ctrl_num,
								@debug_level,
								@perf_level,
								@home_precision,
								@oper_precision
		IF( @result != 0 )
		BEGIN
			IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arflua.sp" + ", line " + STR( 118, 5 ) + " -- EXIT: "
			RETURN @result
		END
	END
	
	
	IF 1 = (	SELECT	aractter_flag
			FROM	arco
		)
	BEGIN
		EXEC @result = ARFLUpdateTerritoryActivity_SP	@batch_ctrl_num,
									@debug_level,
									@perf_level,
									@home_precision,
									@oper_precision
		IF( @result != 0 )
		BEGIN
			IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arflua.sp" + ", line " + STR( 137, 5 ) + " -- EXIT: "
			RETURN @result
		END
	END
	
	
	IF 1 = (	SELECT	aractshp_flag
			FROM	arco
		)
	BEGIN
		EXEC @result = ARFLUpdateShipToActivity_SP	@batch_ctrl_num,
									@debug_level,
									@perf_level,
									@home_precision,
									@oper_precision
		IF( @result != 0 )
		BEGIN
			IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arflua.sp" + ", line " + STR( 156, 5 ) + " -- EXIT: "
			RETURN @result
		END
	END
	
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arflua.sp" + ", line " + STR( 161, 5 ) + " -- EXIT: "
	RETURN 0 
END
GO
GRANT EXECUTE ON  [dbo].[ARFLUpdateActivity_SP] TO [public]
GO
