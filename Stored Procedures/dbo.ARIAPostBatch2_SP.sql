SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROC [dbo].[ARIAPostBatch2_SP]	@batch_ctrl_num	varchar( 16 ),
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

IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, "tmp/ariapb2.sp", 47, "Entering ARIAPostBatch_SP", @PERF_time_last OUTPUT

BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/ariapb2.sp" + ", line " + STR( 50, 5 ) + " -- ENTRY: "

	SELECT	@process_ctrl_num = p.process_ctrl_num
	FROM	batchctl b, pcontrol_vw p
	WHERE	b.process_group_num = p.process_ctrl_num
	AND	b.batch_ctrl_num = @batch_ctrl_num

	
	EXEC @validation_status = ARIAResetFlags_SP	@batch_ctrl_num,
								@process_ctrl_num,
								@batch_proc_flag,
								@process_user_id,
		 		@debug_level,
								@perf_level	
	
	IF ( @validation_status != 0 AND @validation_status != 34570 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/ariapb2.sp" + ", line " + STR( 73, 5 ) + " -- EXIT: "
		RETURN @validation_status
	END
	

	
	EXEC @result = ARIAPostTemp_SP	@batch_ctrl_num,
						@process_ctrl_num,
						@process_user_id,
						@debug_level,
						@perf_level
	IF( @result != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/ariapb2.sp" + ", line " + STR( 88, 5 ) + " -- EXIT: "
		RETURN @result
	END 
	


	IF ( EXISTS(SELECT 1 from arco with (nolock) where chargeback_flag = 1 ))
	BEGIN
			/* Begin mod: CB0001 - Create chargebacks entered for the invoice adjustment */
		EXEC arcbadj_sp @batch_ctrl_num
			/* End mod: CB0001 */
	END

	UPDATE	#artrx_work
	SET	posted_flag = 1,
		process_group_num = trx_ctrl_num,
		db_action = db_action | 1
	WHERE	posted_flag != 1
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/ariapb2.sp" + ", line " + STR( 102, 5 ) + " -- EXIT: "
		RETURN 34563
	END

	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/ariapb2.sp" + ", line " + STR( 106, 5 ) + " -- EXIT: "
	IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, "tmp/ariapb2.sp", 107, "Leaving ARIAPostBatch_SP", @PERF_time_last OUTPUT
	RETURN @validation_status 
END
GO
GRANT EXECUTE ON  [dbo].[ARIAPostBatch2_SP] TO [public]
GO
