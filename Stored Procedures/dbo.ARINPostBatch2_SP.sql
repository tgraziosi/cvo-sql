SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROC [dbo].[ARINPostBatch2_SP]	@batch_ctrl_num varchar( 16 ),
					@debug_level smallint = 0,
					@perf_level smallint = 0 
AS






DECLARE
 @PERF_time_last datetime

SELECT @PERF_time_last = GETDATE()















									







DECLARE
	@result 	int,
 	@batch_proc_flag 	smallint,
	@process_ctrl_num 	varchar( 16 ),
	@process_user_id smallint,
	@validation_status	int

IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, "tmp/arinpb2.sp", 53, "Entering ARINPostBatch_SP", @PERF_time_last OUTPUT

BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arinpb2.sp" + ", line " + STR( 56, 5 ) + " -- ENTRY: "

	
	SELECT	@process_ctrl_num	= p.process_ctrl_num,
		@process_user_id 	= p.process_user_id
	FROM	batchctl b, pcontrol_vw p
	WHERE	b.process_group_num = p.process_ctrl_num
	AND	b.batch_ctrl_num = @batch_ctrl_num
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arinpb2.sp" + ", line " + STR( 68, 5 ) + " -- EXIT: "
		RETURN 34563
	END
	
	SELECT	@batch_proc_flag = batch_proc_flag
	FROM	arco
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arinpb2.sp" + ", line " + STR( 76, 5 ) + " -- EXIT: "
		RETURN 34563
	END
	
	
	EXEC @validation_status = ARINResetFlags_SP	@batch_ctrl_num,
								@process_ctrl_num,
								@batch_proc_flag,
								@process_user_id,
		 		@debug_level,
								@perf_level	

	
	IF ( @validation_status != 0 AND @validation_status != 34570 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arinpb2.sp" + ", line " + STR( 100, 5 ) + " -- EXIT: "
		RETURN @validation_status
	END
	
	
	EXEC @result = ARINPostTemp_SP	@batch_ctrl_num,
						@process_ctrl_num,
						@process_user_id,
						@debug_level,
						@perf_level

	IF ( @result != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arinpb2.sp" + ", line " + STR( 115, 5 ) + " -- EXIT: "
		RETURN @result
	END 
	
	
	UPDATE	#artrx_work
	SET	posted_flag = 1,
		process_group_num = trx_ctrl_num,
		db_action = db_action | 1
	WHERE	posted_flag != 1
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arinpb2.sp" + ", line " + STR( 129, 5 ) + " -- EXIT: "
		RETURN 34563
	END

	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arinpb2.sp" + ", line " + STR( 133, 5 ) + " -- EXIT: "
	IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, "tmp/arinpb2.sp", 134, "Leaving ARINPostBatch_SP", @PERF_time_last OUTPUT
	RETURN @validation_status 
END
GO
GRANT EXECUTE ON  [dbo].[ARINPostBatch2_SP] TO [public]
GO
