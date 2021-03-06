SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO









 



					 










































 








































































































































































































































































































































































































































































































CREATE PROC [dbo].[ARCAPostBatch2_SP]	@batch_ctrl_num varchar( 16 ),
 	@debug_level smallint = 0,
 	@perf_level smallint = 0 
AS






DECLARE
 @PERF_time_last datetime

SELECT @PERF_time_last = GETDATE()















									







DECLARE
	@result		int,
	@batch_proc_flag	smallint,
	@cm_flag		smallint,
	@process_ctrl_num	varchar( 16 ),
	@process_user_id	smallint,
	@process_date		int,
	@period_end		int,
	@batch_type		smallint,
	@journal_type		varchar( 8 ),
	@company_code		varchar( 8 ),
	@home_cur_code	varchar( 8 ),
	@oper_cur_code	varchar( 8 ),
	@validation_status	int

IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, "tmp/arcapb2.sp", 51, "Entering ARCAPostBatch2_SP", @PERF_time_last OUTPUT

BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcapb2.sp" + ", line " + STR( 54, 5 ) + " -- ENTRY: "
	
	
	EXEC @result = ARCRInit_SP	@batch_ctrl_num, 
 	@batch_proc_flag OUTPUT,
					@cm_flag OUTPUT,
					@process_ctrl_num OUTPUT,
					@process_user_id OUTPUT,
					@process_date OUTPUT,
					@period_end OUTPUT,
					@batch_type OUTPUT,
					@journal_type OUTPUT,
					@company_code OUTPUT,
					@home_cur_code OUTPUT,
					@oper_cur_code OUTPUT,
					@debug_level,
					@perf_level
	IF( @result != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcapb2.sp" + ", line " + STR( 75, 5 ) + " -- EXIT: "
 	RETURN @result
	END

	
	SELECT	@process_ctrl_num	= p.process_ctrl_num,
		@process_user_id 	= p.process_user_id
	FROM	batchctl b, pcontrol_vw p
	WHERE	b.process_group_num = p.process_ctrl_num
	AND	b.batch_ctrl_num = @batch_ctrl_num

	
	EXEC @validation_status = ARCAResetFlags_SP	@batch_ctrl_num,
								@process_ctrl_num,
								@batch_proc_flag,
								@process_user_id,
		 		@debug_level,
								@perf_level	

	IF ( @validation_status != 0 AND @validation_status != 34570 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcapb2.sp" + ", line " + STR( 106, 5 ) + " -- EXIT: "
		RETURN @validation_status
	END
	
	
	UPDATE	#arinppdt_work
	SET	temp_flag = 0
	
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcapb2.sp" + ", line " + STR( 132, 5 ) + " -- EXIT: "
		RETURN 34563
	END

	UPDATE	#arinppdt_work
	SET	temp_flag = 1
	FROM	#arinppyt_work pyt, #arinppdt_work pdt
	WHERE	pyt.trx_ctrl_num = pdt.trx_ctrl_num
	AND	pyt.batch_code = @batch_ctrl_num
	
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcapb2.sp" + ", line " + STR( 144, 5 ) + " -- EXIT: "
		RETURN 34563
	END

	EXEC @result = ARCAPostTemp_SP	@batch_ctrl_num,
						@process_ctrl_num,
						@debug_level,
						@perf_level	


	IF ( @result != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcapb2.sp" + ", line " + STR( 156, 5 ) + " -- EXIT: "
		RETURN @result
	END 
	
	
	UPDATE	#artrx_work
	SET	posted_flag = 1,
		process_group_num = trx_ctrl_num,
		db_action = db_action | 1 
	WHERE	posted_flag != 1

	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcapb2.sp" + ", line " + STR( 171, 5 ) + " -- EXIT: "
		RETURN 34563
	END
	
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcapb2.sp" + ", line " + STR( 175, 5 ) + " -- EXIT: "
	IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, "tmp/arcapb2.sp", 176, "Leaving ARCAPostBatch_SP2", @PERF_time_last OUTPUT
 	RETURN @validation_status 
END
GO
GRANT EXECUTE ON  [dbo].[ARCAPostBatch2_SP] TO [public]
GO
