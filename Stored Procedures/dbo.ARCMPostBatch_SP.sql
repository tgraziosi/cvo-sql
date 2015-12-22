SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROC [dbo].[ARCMPostBatch_SP]	@batch_ctrl_num varchar( 16 ),
 	@debug_level smallint = 0,
 	@perf_level smallint = 0 
AS






DECLARE
 @PERF_time_last datetime

SELECT @PERF_time_last = GETDATE()















									







DECLARE
	@result 	int,
	@batch_proc_flag 	smallint,
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

IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, "tmp/arcmpb.sp", 126, "Entering ARCMPostBatch_SP", @PERF_time_last OUTPUT

BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcmpb.sp" + ", line " + STR( 129, 5 ) + " -- ENTRY: "

	SELECT	@process_ctrl_num = p.process_ctrl_num
	FROM	batchctl b, pcontrol_vw p
	WHERE	b.process_group_num = p.process_ctrl_num
	AND	b.batch_ctrl_num = @batch_ctrl_num

	INSERT pbatch (	process_ctrl_num,	batch_ctrl_num,
				start_number,		start_total,
				end_number,		end_total,
				start_time,		end_time,
				flag 
			)
	VALUES (
				@process_ctrl_num, 	@batch_ctrl_num,
				0,		 0,
				0,		 	0,
				getdate(),	 	NULL,
				0
			)

	
	EXEC @result = ARCHGInit_SP	@batch_ctrl_num, 
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
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcmpb.sp" + ", line " + STR( 170, 5 ) + " -- EXIT: "
 	RETURN @result
	END

	
	EXEC @result = ARCMInsertTempTables_SP	@process_ctrl_num,
							@batch_ctrl_num,
							@debug_level,
							@perf_level
 	IF( @result != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcmpb.sp" + ", line " + STR( 183, 5 ) + " -- EXIT: "
		RETURN @result
	END

	
 	EXEC @result = ARCMLockInsertDepend_SP	@batch_ctrl_num,
							@process_ctrl_num,
							@batch_proc_flag,
							@debug_level,
							@perf_level
							
 	IF( @result != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcmpb.sp" + ", line " + STR( 200, 5 ) + " -- EXIT: "
		RETURN @result
	END
	
	
	EXEC @result = ARCMPostInsertValTables_SP

	IF( @result != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcmpb.sp" + ", line " + STR( 214, 5 ) + " -- EXIT: "
		RETURN @result
	END 
	
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcmpb.sp" + ", line " + STR( 218, 5 ) + " -- EXIT: "
	IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, "tmp/arcmpb.sp", 219, "Leaving ARCMPostBatch_SP", @PERF_time_last OUTPUT
 	RETURN 0
END
GO
GRANT EXECUTE ON  [dbo].[ARCMPostBatch_SP] TO [public]
GO
