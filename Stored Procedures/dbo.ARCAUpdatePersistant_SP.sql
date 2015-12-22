SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO









 



					 










































 






















































































































































































































































































































































































































































































































 
















































































CREATE PROC [dbo].[ARCAUpdatePersistant_SP]			@batch_ctrl_num		varchar( 16 ),
											@process_ctrl_num	varchar( 16 ),
											@company_code		varchar( 8 ),
											@process_user_id	smallint,
											@debug_level		smallint = 0,
											@perf_level			smallint = 0	
AS






DECLARE
 @PERF_time_last datetime

SELECT @PERF_time_last = GETDATE()















									







DECLARE
	@result		int,
	@err_msg	varchar(100)

IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, "tmp/arcaup.sp", 38, "Entering ARCAUpdatePersistant_SP", @PERF_time_last OUTPUT

BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcaup.sp" + ", line " + STR( 41, 5 ) + " -- ENTRY: "
		
	
	UPDATE #arinppyt_work
	SET	trx_type = 2121
	WHERE	trx_type IN (2113, 2112)
	
	UPDATE #arinppdt_work
	SET	trx_type = 2121
	WHERE	trx_type IN (2113, 2112)
	
	
	
	EXEC @result = ARModifyPersistant_SP	@batch_ctrl_num,
							@debug_level,
							@perf_level
	IF( @result != 0 )
	BEGIN
		IF ( @debug_level > 2 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcaup.sp" + ", line " + STR( 70, 5 ) + " -- MSG: " + " A database error occured in ARModifyPersistant_SP"
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcaup.sp" + ", line " + STR( 71, 5 ) + " -- EXIT: "
		RETURN @result
	END

	
	EXEC @result = arpysav_sp	@company_code,
								@process_user_id
	IF( @result != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcaup.sp" + ", line " + STR( 83, 5 ) + " -- EXIT: "
		RETURN 34563
	END
	
	
	IF EXISTS (SELECT * FROM batchctl where batch_ctrl_num = @batch_ctrl_num and
			hold_flag = 0)
	BEGIN
	
		EXEC @result = batupdst_sp	@batch_ctrl_num,
									1
		IF( @result != 0 )
		BEGIN
			IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcaup.sp" + ", line " + STR( 98, 5 ) + " -- EXIT: "
			RETURN 34563
		END
	
	END

	
	IF EXISTS (SELECT * FROM arco WHERE bb_flag = 1 )
	BEGIN
		EXEC @result = cminpsav_sp
		IF( @result != 0 )
		BEGIN
			IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcaup.sp" + ", line " + STR( 112, 5 ) + " -- EXIT: "
			RETURN 34563
		END
	END

	
	EXEC @result = gltrxsav_sp	@process_ctrl_num,
					@company_code,
					@debug_level
	IF( @result != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcaup.sp" + ", line " + STR( 125, 5 ) + " -- EXIT: "
		RETURN 34563
	END

	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcaup.sp" + ", line " + STR( 129, 5 ) + " -- EXIT: "					
	IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, "tmp/arcaup.sp", 130, "Leaving ARCAUpdatePersistant_SP", @PERF_time_last OUTPUT
	RETURN 0
END
GO
GRANT EXECUTE ON  [dbo].[ARCAUpdatePersistant_SP] TO [public]
GO
