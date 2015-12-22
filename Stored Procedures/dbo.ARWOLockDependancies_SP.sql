SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROC [dbo].[ARWOLockDependancies_SP]		@batch_ctrl_num	varchar( 16 ),
							@process_ctrl_num	varchar( 16 ),
							@batch_proc_flag	smallint,
							@debug_level		smallint = 0,
							@perf_level		smallint = 0 
AS






DECLARE
 @PERF_time_last datetime

SELECT @PERF_time_last = GETDATE()















									







DECLARE
	@result		int,
	@all_trx_marked	int

IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, "tmp/arwold.sp", 52, "Entering ARWOLockDependancies_SP", @PERF_time_last OUTPUT

BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arwold.sp" + ", line " + STR( 55, 5 ) + " -- ENTRY: "
	
	IF ( @perf_level >= 2 ) EXEC perf_sp @batch_ctrl_num, "tmp/arwold.sp", 61, "Start inserting dependant transactions into #deplock", @PERF_time_last OUTPUT

	INSERT	#deplock
	(	
		customer_code,
		doc_ctrl_num, 
		trx_type, 
		lock_status,
		temp_flag 
	)
	SELECT		
		trx.customer_code,
		pdt.apply_to_num,
		pdt.apply_trx_type,
		0,
		0
	FROM	#arinppdt_work pdt, artrx trx
	WHERE	pdt.apply_to_num = trx.doc_ctrl_num
	AND	pdt.apply_trx_type = trx.trx_type

	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 2 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arwold.sp" + ", line " + STR( 83, 5 ) + " -- MSG: " + "Error inserting into #deplock"
		IF ( @debug_level > 2 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arwold.sp" + ", line " + STR( 84, 5 ) + " -- MSG: " + "@@error = " + STR(@@error, 7)
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arwold.sp" + ", line " + STR( 85, 5 ) + " -- EXIT: "
		RETURN 34563
	END
	

	IF ( @perf_level >= 2 ) EXEC perf_sp @batch_ctrl_num, "tmp/arwold.sp", 90, "Done inserting dependant transactions into #deplock", @PERF_time_last OUTPUT

	IF( @debug_level >= 2 )
	BEGIN
		SELECT	"Transaction we are going to lock:"
		SELECT	"customer_code, doc_ctrl_num, trx_type, lock_status, temp_flag"
		SELECT	customer_code + " " +
			doc_ctrl_num + " " + 
			STR(trx_type, 6) + " " + 
			STR(lock_status, 6) + " " + 
			STR(temp_flag, 6)
		FROM	#deplock
	END

		
	EXEC @result = ARMarkDependancies_SP	@batch_ctrl_num,
							@process_ctrl_num,
							@all_trx_marked OUTPUT,
							@debug_level,
							@perf_level
	IF( @result != 0 )
	BEGIN
		IF ( @debug_level > 2 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arwold.sp" + ", line " + STR( 114, 5 ) + " -- MSG: " + "ARMarkDependancies_SP has failed"
		IF ( @debug_level > 2 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arwold.sp" + ", line " + STR( 115, 5 ) + " -- MSG: " + "@result = " + STR( @result, 6 )
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arwold.sp" + ", line " + STR( 116, 5 ) + " -- EXIT: "
		RETURN 34563
	END
			
	SELECT "all_trx_marked = " + STR(@all_trx_marked,2,0)
	IF( @all_trx_marked = 0 )
	BEGIN
		SELECT "ready to place transactions on hold"
		
		
		IF ( @perf_level >= 3 ) EXEC perf_sp @batch_ctrl_num, "tmp/arwold.sp", 129, "Start inserting errors into #ar_hold", @PERF_time_last OUTPUT
		INSERT	#ewerror
		(	module_id, 					err_code,		
			info1,			info2,			infoint,
			infofloat,		flag1,			trx_ctrl_num,
			sequence_id,		source_ctrl_num,	extra
		)
		SELECT 2000,			34554,
			c.apply_to_num,	"",			0,
			0.0,			1,		b.trx_ctrl_num,
			0,			"",			0				
		FROM	#deplock a, #arinppyt_work b, #arinppdt_work c
		WHERE	a.lock_status != 1
		 AND	a.doc_ctrl_num = c.apply_to_num
		 AND	a.trx_type = c.apply_trx_type
		 AND	b.trx_ctrl_num = c.trx_ctrl_num
		 AND	b.trx_type = c.trx_type

		IF ( @perf_level >= 3 ) EXEC perf_sp @batch_ctrl_num, "tmp/arwold.sp", 147, "Done inserting errors into #ar_hold", @PERF_time_last OUTPUT

		IF( @batch_proc_flag = 1 )
		BEGIN	
			IF ( @debug_level > 2 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arwold.sp" + ", line " + STR( 151, 5 ) + " -- MSG: " + "accounting batch mode is on"

			
			IF ( @perf_level >= 2 ) EXEC perf_sp @batch_ctrl_num, "tmp/arwold.sp", 156, "Start updating #arinppyt_work to make transaction available again", @PERF_time_last OUTPUT

			UPDATE	#arinppyt_work
			SET	process_group_num = trx_ctrl_num,
				posted_flag = 0,
				db_action = db_action | 1

			IF( @@error != 0 )
			BEGIN
				IF ( @debug_level > 2 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arwold.sp" + ", line " + STR( 165, 5 ) + " -- MSG: " + "Update to #arinppyt_work failed"
				IF ( @debug_level > 2 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arwold.sp" + ", line " + STR( 166, 5 ) + " -- MSG: " + "@@error = " + STR( @@error, 6 )
				IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arwold.sp" + ", line " + STR( 167, 5 ) + " -- EXIT: "
				RETURN 34563
			END
			IF ( @perf_level >= 2 ) EXEC perf_sp @batch_ctrl_num, "tmp/arwold.sp", 170, "Done updating #arinppyt_work to make transaction available again", @PERF_time_last OUTPUT
		
			IF ( @debug_level > 2 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arwold.sp" + ", line " + STR( 172, 5 ) + " -- MSG: " + "The batch has errors so kick out this batch"
			IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arwold.sp" + ", line " + STR( 173, 5 ) + " -- EXIT: "
			RETURN 34562
		END
		ELSE	
		BEGIN		
			IF ( @debug_level > 2 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arwold.sp" + ", line " + STR( 178, 5 ) + " -- MSG: " + "Not in accounting batch mode"

			
			IF ( @perf_level >= 2 ) EXEC perf_sp @batch_ctrl_num, "tmp/arwold.sp", 184, "Start updating #arinppyt_work to make transaction available again", @PERF_time_last OUTPUT

			UPDATE	#arinppyt_work
			SET	process_group_num = b.trx_ctrl_num,
				batch_code = ' ',
				posted_flag = 0,
				db_action = db_action | 1
			FROM	#arinppyt_work a, #ewerror b
			WHERE	a.trx_ctrl_num = b.trx_ctrl_num
			 AND	a.trx_type = 2151

			IF( @@error != 0 )
			BEGIN
				IF ( @debug_level > 2 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arwold.sp" + ", line " + STR( 197, 5 ) + " -- MSG: " + "Update to #arinppyt_work failed"
				IF ( @debug_level > 2 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arwold.sp" + ", line " + STR( 198, 5 ) + " -- MSG: " + "@@error = " + STR( @@error, 6 )
				IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arwold.sp" + ", line " + STR( 199, 5 ) + " -- EXIT: "
				RETURN 34563
				RETURN -1
			END

			IF ( @perf_level >= 2 ) EXEC perf_sp @batch_ctrl_num, "tmp/arwold.sp", 204, "Done updating #arinppyt_work to make transaction available again", @PERF_time_last OUTPUT
		END		
	END	
	IF ( @debug_level > 2 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arwold.sp" + ", line " + STR( 207, 5 ) + " -- MSG: " + "Correct end of ARWOLockDependancies_SP"
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arwold.sp" + ", line " + STR( 208, 5 ) + " -- EXIT: "
	IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, "tmp/arwold.sp", 209, "Leaving ARWOLockDependancies_SP", @PERF_time_last OUTPUT
	RETURN 0
END
GO
GRANT EXECUTE ON  [dbo].[ARWOLockDependancies_SP] TO [public]
GO
