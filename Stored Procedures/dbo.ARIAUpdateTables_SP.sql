SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROC [dbo].[ARIAUpdateTables_SP]	@batch_ctrl_num	varchar( 16 ),
					@debug_level		smallint = 0,
					@perf_level		smallint = 0	
AS






DECLARE
 @PERF_time_last datetime

SELECT @PERF_time_last = GETDATE()















									







DECLARE
	@result		int,
	@process_ctrl_num	varchar(16),
	@process_user_id	smallint,
	@company_code		varchar(8),
	@process_date		int,
	@period_end		int,
	@batch_type		smallint,
	@tran_started		smallint


IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, "tmp/ariaut.sp", 46, "Entering ARIAUpdateTables_SP", @PERF_time_last OUTPUT

BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/ariaut.sp" + ", line " + STR( 49, 5 ) + " -- ENTRY: "
		
	
	EXEC @result = ARIAModifyPersistant_SP	@batch_ctrl_num,
							@debug_level,
							@perf_level
	IF( @result != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/ariaut.sp" + ", line " + STR( 60, 5 ) + " -- EXIT: "
		RETURN 34563
	END

	
	EXEC @result = batinfo_sp	@batch_ctrl_num,
					@process_ctrl_num OUTPUT,
					@process_user_id OUTPUT,
					@process_date OUTPUT,
					@period_end OUTPUT,
					@batch_type OUTPUT

	IF( @result != 0 )
	BEGIN
		IF ( @debug_level > 2 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/ariaut.sp" + ", line " + STR( 76, 5 ) + " -- MSG: " + "batinfo error: @result = " + STR(@result, 7)
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/ariaut.sp" + ", line " + STR( 77, 5 ) + " -- EXIT: "
		RETURN 35011
	END

	
	EXEC @result = batupdst_sp	@batch_ctrl_num,
					1
	IF( @result != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/ariaut.sp" + ", line " + STR( 88, 5 ) + " -- EXIT: "
		RETURN 34563
	END
	
	
	SELECT	@company_code = company_code
	FROM	glco

	
	EXEC @result = gltrxsav_sp	@process_ctrl_num,
					@company_code
	IF( @result != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/ariaut.sp" + ", line " + STR( 105, 5 ) + " -- EXIT: "
		RETURN 34563
	END

	UPDATE pbatch
	SET 	end_number = (SELECT COUNT(*) 
				FROM 	#artrx_work
				WHERE	trx_type = 2051
			 ),
		end_total = (	SELECT ISNULL(SUM(amt_net),0.0) 
				FROM 	#artrx_work
				WHERE	trx_type = 2051
			 ),
		end_time = getdate(),
		flag = 2
	WHERE 	batch_ctrl_num = @batch_ctrl_num
	AND 	process_ctrl_num = @process_ctrl_num
							
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/ariaut.sp" + ", line " + STR( 123, 5 ) + " -- EXIT: "
	IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, "tmp/ariaut.sp", 124, "Entering ARIAUpdateTables_SP", @PERF_time_last OUTPUT
	RETURN 0
END
GO
GRANT EXECUTE ON  [dbo].[ARIAUpdateTables_SP] TO [public]
GO
