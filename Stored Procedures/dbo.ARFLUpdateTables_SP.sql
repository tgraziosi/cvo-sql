SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROC [dbo].[ARFLUpdateTables_SP]	@batch_ctrl_num	varchar( 16 ),
					@process_user_id	smallint,
					@debug_level		smallint = 0
AS






DECLARE
 @PERF_time_last datetime

SELECT @PERF_time_last = GETDATE()















									







DECLARE
	@result		int,
	@company_code		varchar( 8 ),
	@process_date		int,
	@period_end		int,
	@batch_type		smallint,
	@tran_started		smallint,
	@perf_level		smallint,
	@process_ctrl_num	varchar( 16)


IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, "tmp/arflut.sp", 44, "Entering ARFLUpdateTables_SP", @PERF_time_last OUTPUT

BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arflut.sp" + ", line " + STR( 47, 5 ) + " -- ENTRY: "
	
	SELECT	@perf_level = 0
	
	EXEC @result = batinfo_sp	@batch_ctrl_num,
					@process_ctrl_num OUTPUT,
					@process_user_id OUTPUT,
					@process_date OUTPUT,
					@period_end OUTPUT,
					@batch_type OUTPUT
	IF( @result != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arflut.sp" + ", line " + STR( 61, 5 ) + " -- EXIT: "
		RETURN 35011
	END
	
	
	SELECT	@company_code = company_code
	FROM	glco

	
	IF( @@trancount = 0 )
	BEGIN
		IF ( @debug_level > 2 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arflut.sp" + ", line " + STR( 76, 5 ) + " -- MSG: " + "Beginning Transaction"
		BEGIN TRAN 
		SELECT	@tran_started = 1
	END

	
	EXEC @result = ARFLUpdatePersistant_SP	@batch_ctrl_num,
							@process_ctrl_num,
							@company_code,
							@process_user_id,
							@debug_level,
							@perf_level
	IF(@result != 0 )
	BEGIN
		IF( @tran_started = 1 )
		BEGIN
			IF ( @debug_level > 2 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arflut.sp" + ", line " + STR( 96, 5 ) + " -- MSG: " + "Rolling Back transaction"
			ROLLBACK TRAN
			SELECT	@tran_started = 0
		END
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arflut.sp" + ", line " + STR( 100, 5 ) + " -- EXIT: "
		RETURN @result
	END

	UPDATE pbatch
	SET 	start_number = (	SELECT COUNT(*) 
					FROM 	#artrx_work
					WHERE	trx_type >= 2061
					AND	trx_type <= 2071
				 ),
		start_total = (	SELECT ISNULL(SUM(amt_net),0.0) 
					FROM 	#artrx_work
					WHERE	trx_type >= 2061
					AND	trx_type >= 2071
				),
		flag = 1
	WHERE 	batch_ctrl_num = @batch_ctrl_num
	AND 	process_ctrl_num = @process_ctrl_num
 	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arflut.sp" + ", line " + STR( 120, 5 ) + " -- EXIT: "
		RETURN 34563
	END
	
	IF( @tran_started = 1 )
	BEGIN
		IF ( @debug_level > 2 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arflut.sp" + ", line " + STR( 126, 5 ) + " -- MSG: " + "Commiting Transaction"
		COMMIT TRAN
		SELECT	@tran_started = 0
	END

	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arflut.sp" + ", line " + STR( 131, 5 ) + " -- EXIT: "
	IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, "tmp/arflut.sp", 132, "Entering ARFLUpdateTables_SP", @PERF_time_last OUTPUT
	RETURN 0
END
GO
GRANT EXECUTE ON  [dbo].[ARFLUpdateTables_SP] TO [public]
GO
