SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO









 



					 










































 








































































































































































































































































































































































































































































































CREATE PROC [dbo].[ARIAPostBatch_SP]	@batch_ctrl_num	varchar( 16 ),
					@debug_level		smallint = 0,
					@perf_level		smallint = 0 
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
	@company_code		varchar( 8 ),
	@journal_type		varchar( 8 ),
	@home_cur_code	varchar( 8 ), 
	@oper_cur_code	varchar( 8 ), 
	@validation_status	int

IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, "tmp/ariapb.sp", 50, "Entering ARIAPostBatch_SP", @PERF_time_last OUTPUT

BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/ariapb.sp" + ", line " + STR( 53, 5 ) + " -- ENTRY: "

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
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/ariapb.sp" + ", line " + STR( 93, 5 ) + " -- EXIT: "
		RETURN @result
	END

	
	EXEC @result = ARIAInsertTempTables_SP	@process_ctrl_num,
							@batch_ctrl_num,
							@debug_level,
							@perf_level
	IF( @result != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/ariapb.sp" + ", line " + STR( 106, 5 ) + " -- EXIT: "
		RETURN @result
	END

	
	EXEC @result = ARIALockDependancies_SP	@batch_ctrl_num,
							@process_ctrl_num,
							@batch_proc_flag,
							@debug_level,
							@perf_level
	IF( @result != 0 )
	BEGIN
		IF ( @debug_level > 2 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/ariapb.sp" + ", line " + STR( 120, 5 ) + " -- MSG: " + "ARIALockDependancies_SP has failed"
		IF ( @debug_level > 2 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/ariapb.sp" + ", line " + STR( 121, 5 ) + " -- MSG: " + "@result = " + STR( @result, 7 )
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/ariapb.sp" + ", line " + STR( 122, 5 ) + " -- EXIT: "
		RETURN @result
	END

	
	EXEC @result = ARIAInsertDependancies_SP	@batch_ctrl_num,
							@process_ctrl_num,
							@debug_level,
							@perf_level
	IF( @result != 0 )
	BEGIN
		IF ( @debug_level > 2 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/ariapb.sp" + ", line " + STR( 135, 5 ) + " -- MSG: " + "ARIAInsertDependancies_SP has failed"
		IF ( @debug_level > 2 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/ariapb.sp" + ", line " + STR( 136, 5 ) + " -- MSG: " + "@result = " + STR( @result, 7 )
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/ariapb.sp" + ", line " + STR( 137, 5 ) + " -- EXIT: "
		RETURN @result
	END

	EXEC @result = ARIAPostInsertValTables_SP
	
	IF( @result != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/ariapb.sp" + ", line " + STR( 145, 5 ) + " -- EXIT: "
		RETURN @result
	END 
	
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/ariapb.sp" + ", line " + STR( 149, 5 ) + " -- EXIT: "
	IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, "tmp/ariapb.sp", 150, "Leaving ARIAPostBatch_SP", @PERF_time_last OUTPUT
	RETURN 0 
END
GO
GRANT EXECUTE ON  [dbo].[ARIAPostBatch_SP] TO [public]
GO
