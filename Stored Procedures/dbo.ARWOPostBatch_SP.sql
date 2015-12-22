SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROC [dbo].[ARWOPostBatch_SP]	@batch_ctrl_num varchar( 16 ),
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
	@journal_type		varchar(8),
	@company_code		varchar(8),
	@home_cur_code	varchar(8),
	@oper_cur_code	varchar(8),
	@validation_status	int,
	@last_trx_ctrl_num	varchar( 16 ),
	@trx_ctrl_num		varchar( 16 ),
	@doc_ctrl_num		varchar( 16 ),
	@number		int,
	@wr_count		int
	

IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, "tmp/arwopb.sp", 60, "Entering ARWOPostBatch_SP", @PERF_time_last OUTPUT

BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arwopb.sp" + ", line " + STR( 63, 5 ) + " -- ENTRY: "
	IF ( @debug_level > 2 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arwopb.sp" + ", line " + STR( 64, 5 ) + " -- MSG: " + "batch_ctrl_num: " + @batch_ctrl_num

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

	
	IF ( @debug_level > 2 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arwopb.sp" + ", line " + STR( 89, 5 ) + " -- MSG: " + "calling ARCRinit_SP"
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
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arwopb.sp" + ", line " + STR( 107, 5 ) + " -- EXIT: "
 	RETURN @result
	END
	
	
	IF ( @debug_level > 2 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arwopb.sp" + ", line " + STR( 118, 5 ) + " -- MSG: " + "calling ARPYInsertTempTables_SP"
 	EXEC @result = ARPYInsertTempTables_SP	@process_ctrl_num,
 							@batch_ctrl_num, 
 	 @debug_level,
 	@perf_level
 	IF( @result != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arwopb.sp" + ", line " + STR( 125, 5 ) + " -- EXIT: "
 	RETURN @result
	END

	
	
	SELECT @wr_count = COUNT(trx_ctrl_num)
	FROM	#arinppyt_work
	WHERE	batch_code = @batch_ctrl_num

	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arwopb.sp" + ", line " + STR( 146, 5 ) + " -- EXIT: "
		RETURN 34563
	END
	
	SELECT @last_trx_ctrl_num = ' '
	
	WHILE (@wr_count > 0)
	BEGIN
		SELECT @trx_ctrl_num = NULL,
			@wr_count = @wr_count - 1

		SELECT @trx_ctrl_num = MIN(trx_ctrl_num)
		FROM	#arinppyt_work
		WHERE	trx_ctrl_num > @last_trx_ctrl_num
		AND	batch_code = @batch_ctrl_num
		
		IF( @@error != 0 )
		BEGIN
			IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arwopb.sp" + ", line " + STR( 164, 5 ) + " -- EXIT: "
			RETURN 34563
		END
		
		SELECT @last_trx_ctrl_num = @trx_ctrl_num
		
		EXEC @result = ARGetNextControl_SP 	2031,
								@doc_ctrl_num OUTPUT,
								@number OUTPUT,
								@debug_level

		IF( @result != 0 )
			RETURN @result

		UPDATE #arinppyt_work
		SET	doc_ctrl_num = @doc_ctrl_num
		WHERE	trx_ctrl_num = @trx_ctrl_num
		AND	trx_type = 2151
		AND	batch_code = @batch_ctrl_num
		
		IF( @@error != 0 )
		BEGIN
			IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arwopb.sp" + ", line " + STR( 186, 5 ) + " -- EXIT: "
			RETURN 34563
		END
		
		IF (@debug_level > 3)
		BEGIN
			SELECT "@doc_ctrl_num = " + @doc_ctrl_num +
				"@trx_ctrl_num = " + @trx_ctrl_num
			
			SELECT "after update of doc_ctrl_num "
			SELECT "trx_ctrl_num = " + trx_ctrl_num +
				"trx_type = " + STR(trx_type,6) +
				"batch_code = " + batch_code +
				"doc_ctrl_num = " + doc_ctrl_num
			FROM	#arinppyt_work
			WHERE	batch_code = @batch_ctrl_num
		END

	END

	
	UPDATE #arinppdt_work
	SET	doc_ctrl_num = a.doc_ctrl_num
	FROM	#arinppyt_work a
	WHERE	#arinppdt_work.trx_ctrl_num = a.trx_ctrl_num
	AND	#arinppdt_work.trx_type = a.trx_type
	AND	a.batch_code = @batch_ctrl_num
	
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arwopb.sp" + ", line " + STR( 220, 5 ) + " -- EXIT: "
		RETURN 34563
	END
	
 	
 	EXEC @result = ARWOLockDependancies_SP 	@batch_ctrl_num,
							@process_ctrl_num,
 	@batch_proc_flag,
 	@debug_level,
 	@perf_level

 	IF( @result != 0 AND @result != 34562 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arwopb.sp" + ", line " + STR( 237, 5 ) + " -- EXIT: "
 	RETURN @result
	END

	IF ( @debug_level > 2 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arwopb.sp" + ", line " + STR( 241, 5 ) + " -- MSG: " + "After call to ARWOLockDependancies_SP"

	IF( @result = 0 )
	BEGIN
	 	EXEC @result = ARWOInsertDependancies_SP 	@batch_ctrl_num,
								@process_ctrl_num,
 	 	@batch_proc_flag,
 	 	@debug_level,
 	 	@perf_level
	 	IF( @result != 0 )
		BEGIN
			IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arwopb.sp" + ", line " + STR( 252, 5 ) + " -- EXIT: "
	 	RETURN @result
		END

	END

	
	EXEC @result = ARPYPostInsertValTables_SP

	IF( @result != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arwopb.sp" + ", line " + STR( 268, 5 ) + " -- EXIT: "
		RETURN @result
	END

	
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arwopb.sp" + ", line " + STR( 276, 5 ) + " -- EXIT: "
	IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, "tmp/arwopb.sp", 277, "Leaving ARWOPostBatch_SP", @PERF_time_last OUTPUT
 	RETURN 0 
END
GO
GRANT EXECUTE ON  [dbo].[ARWOPostBatch_SP] TO [public]
GO
