SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROC [dbo].[ARCAUpdateTables_SP]		@batch_ctrl_num		varchar( 16 ),
									@debug_level		smallint = 0,
									@perf_level			smallint = 0	
AS






DECLARE
 @PERF_time_last datetime

SELECT @PERF_time_last = GETDATE()















									







DECLARE
	@result				int,
	@process_ctrl_num	varchar(16),
	@process_user_id	smallint,
	@company_code		varchar(8),
	@process_date		int,
	@period_end			int,
	@batch_type			smallint,
	@tran_started		smallint


IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, "tmp/arcaut.sp", 36, "Entering ARCAUpdateTables_SP", @PERF_time_last OUTPUT

BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcaut.sp" + ", line " + STR( 39, 5 ) + " -- ENTRY: "
	
	EXEC @result = batinfo_sp	@batch_ctrl_num,
								@process_ctrl_num OUTPUT,
								@process_user_id OUTPUT,
								@process_date OUTPUT,
								@period_end OUTPUT,
								@batch_type OUTPUT

	IF( @result != 0 )
	BEGIN
		IF ( @debug_level > 2 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcaut.sp" + ", line " + STR( 52, 5 ) + " -- MSG: " + "batinfo error: @result = " + STR(@result, 7)
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcaut.sp" + ", line " + STR( 53, 5 ) + " -- EXIT: "
		RETURN 35011
	END

	
	SELECT	@company_code = company_code
	FROM	glco

	
	EXEC @result = ARCAUpdateTempStatistics_SP	@batch_ctrl_num,
								@debug_level,
								@perf_level
	IF( @result != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcaut.sp" + ", line " + STR( 72, 5 ) + " -- EXIT: "
		RETURN @result
	END
									
	
	IF( @@trancount = 0 )
	BEGIN
		IF ( @debug_level > 2 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcaut.sp" + ", line " + STR( 81, 5 ) + " -- MSG: " + "Beginning Transaction"
		BEGIN TRAN 
		SELECT	@tran_started = 1
	END

	
	EXEC @result = ARCAUpdatePersistant_SP	@batch_ctrl_num,
							@process_ctrl_num,
							@company_code,
							@process_user_id,
							@debug_level,
							@perf_level
	IF(@result != 0 )
	BEGIN
		IF( @tran_started = 1 )
		BEGIN
			IF ( @debug_level > 2 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcaut.sp" + ", line " + STR( 101, 5 ) + " -- MSG: " + "Rolling Back transaction"
			ROLLBACK TRAN
			SELECT	@tran_started = 0
		END
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcaut.sp" + ", line " + STR( 105, 5 ) + " -- EXIT: "
		RETURN @result
	END

	UPDATE pbatch
	SET 	end_number = (SELECT COUNT(*) 
				FROM 	#artrx_work
				WHERE	trx_type >= 2112
				AND	trx_type <= 2121
				),
		end_total = (	SELECT ISNULL(SUM(amt_net),0.0) 
				FROM 	#artrx_work
				WHERE	trx_type >= 2112
				AND	trx_type <= 2121
				),
		end_time = getdate(),
		flag = 2
	WHERE 	batch_ctrl_num = @batch_ctrl_num
	AND 	process_ctrl_num = @process_ctrl_num
	
	IF( @tran_started = 1 )
	BEGIN
		IF ( @debug_level > 2 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcaut.sp" + ", line " + STR( 127, 5 ) + " -- MSG: " + "Commiting Transaction"
		COMMIT TRAN
		SELECT	@tran_started = 0
	END

	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcaut.sp" + ", line " + STR( 132, 5 ) + " -- EXIT: "
	IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, "tmp/arcaut.sp", 133, "Exiting ARCAUpdateTables_SP", @PERF_time_last OUTPUT
	RETURN 0
END
GO
GRANT EXECUTE ON  [dbo].[ARCAUpdateTables_SP] TO [public]
GO
