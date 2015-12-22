SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROC [dbo].[ARCRLockDependancies_SP] 	@batch_ctrl_num 	varchar( 16 ),
						@process_ctrl_num	varchar( 16 ),
					 	@batch_proc_flag	smallint,
					 	@debug_level		smallint = 0,
					 	@perf_level	 	smallint = 0 
AS






DECLARE
 @PERF_time_last datetime

SELECT @PERF_time_last = GETDATE()















									







DECLARE
	@result				int,
	@all_trx_marked		int

IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, "tmp/arcrld.sp", 82, "Entering ARCRLockDependencies_SP", @PERF_time_last OUTPUT

BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcrld.sp" + ", line " + STR( 85, 5 ) + " -- ENTRY: "
	

	IF ( @perf_level >= 2 ) EXEC perf_sp @batch_ctrl_num, "tmp/arcrld.sp", 95, "Start inserting dependant transactions into #deplock", @PERF_time_last OUTPUT
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
		pyt.apply_to_num,
		pyt.apply_trx_type,
		0,
		0
	FROM	#arinppdt_work pyt, artrx trx
	WHERE	pyt.apply_to_num = trx.doc_ctrl_num
	AND	pyt.apply_trx_type = trx.trx_type
	AND	trx.trx_type in (2021, 2031, 2071)
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 2 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcrld.sp" + ", line " + STR( 116, 5 ) + " -- MSG: " + "Error inserting into #deplock"
		IF ( @debug_level > 2 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcrld.sp" + ", line " + STR( 117, 5 ) + " -- MSG: " + "@@error = " + STR(@@error, 7)
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcrld.sp" + ", line " + STR( 118, 5 ) + " -- EXIT: "
		RETURN 34563
	END
		
	
	INSERT	#deplock
	(
		customer_code,
		doc_ctrl_num,
		trx_type,
		lock_status,
		temp_flag
	)
	SELECT
		customer_code,
		doc_ctrl_num,
		trx_type,
		0,
		0	
	FROM	#arinppyt_work
	WHERE	payment_type IN (2, 3, 4) 
	

	
	INSERT	#deplock
	(
		customer_code,
		doc_ctrl_num,
		trx_type,
		lock_status,
		temp_flag
	)
	SELECT
		a.customer_code,
		a.doc_ctrl_num,
		a.trx_type,
		0,
		0
	FROM	artrx a, #arinppdt_work b
	WHERE	a.paid_flag = 0
	 AND	a.customer_code = b.customer_code
	 AND	a.trx_type IN (2021, 2031, 2071) 
	 AND	b.apply_to_num = 'BAL-FORWARD'
			
	IF ( @perf_level >= 2 ) EXEC perf_sp @batch_ctrl_num, "tmp/arcrld.sp", 173, "Done inserting dependant transactions into #deplock", @PERF_time_last OUTPUT

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
		IF ( @debug_level > 2 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcrld.sp" + ", line " + STR( 198, 5 ) + " -- MSG: " + "ARMarkDependancies_SP has failed"
		IF ( @debug_level > 2 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcrld.sp" + ", line " + STR( 199, 5 ) + " -- MSG: " + "@result = " + STR( @result, 6 )
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcrld.sp" + ", line " + STR( 200, 5 ) + " -- EXIT: "
		RETURN 34563
	END
			
	
	IF( @all_trx_marked = 0 )
	BEGIN
		
		IF ( @perf_level >= 3 ) EXEC perf_sp @batch_ctrl_num, "tmp/arcrld.sp", 214, "Start inserting errors into #ewerror", @PERF_time_last OUTPUT
		INSERT	#ewerror
		(	module_id, 					err_code,		
			info1,			info2,			infoint,
			infofloat,		flag1,			trx_ctrl_num,
			sequence_id,		source_ctrl_num,	extra
		)
		SELECT 2000,			20900,
			c.apply_to_num,	"",			0,
			0.0,			1,		b.trx_ctrl_num,
			0,			"",			0				
		FROM	#deplock a, #arinppyt_work b, #arinppdt_work c
		WHERE	a.lock_status != 1
		 AND	a.doc_ctrl_num = c.apply_to_num
		 AND	a.trx_type = c.apply_trx_type
		 AND	b.trx_ctrl_num = c.trx_ctrl_num
		 AND	b.trx_type = c.trx_type
		 AND	a.temp_flag = 0
		IF( @@error != 0 )
		BEGIN
			IF ( @debug_level > 2 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcrld.sp" + ", line " + STR( 234, 5 ) + " -- MSG: " + "Insert into #ewerror failed"
			IF ( @debug_level > 2 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcrld.sp" + ", line " + STR( 235, 5 ) + " -- MSG: " + "@@error = " + STR( @@error, 6 )
			IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcrld.sp" + ", line " + STR( 236, 5 ) + " -- EXIT: "
			RETURN 34563
		END
		 
		INSERT	#ewerror
		(	module_id, 					err_code,		
			info1,			info2,			infoint,
			infofloat,		flag1,			trx_ctrl_num,
			sequence_id,		source_ctrl_num,	extra
		)
		SELECT 2000,			20900,
			b.doc_ctrl_num,	"",			0,
			0.0,			1,		b.trx_ctrl_num,
			0,			"",			0				
		FROM	#deplock a, #arinppyt_work b
		WHERE	a.lock_status != 1
		 AND	a.doc_ctrl_num = b.doc_ctrl_num
		 AND	a.trx_type = b.trx_type
		 AND	a.customer_code = b.customer_code
		 AND	a.temp_flag = 1

		IF( @@error != 0 )
		BEGIN
			IF ( @debug_level > 2 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcrld.sp" + ", line " + STR( 259, 5 ) + " -- MSG: " + "Insert into #ewerror failed"
			IF ( @debug_level > 2 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcrld.sp" + ", line " + STR( 260, 5 ) + " -- MSG: " + "@@error = " + STR( @@error, 6 )
			IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcrld.sp" + ", line " + STR( 261, 5 ) + " -- EXIT: "
			RETURN 34563
		END
		
		IF ( @debug_level > 2 )
		BEGIN
			SELECT "dumping #ewerror..."
			SELECT "trx_ctrl_num = " + trx_ctrl_num +
				"doc_ctrl_num = " + info1
			FROM	#ewerror
		END

		IF( @batch_proc_flag = 1 )
		BEGIN	
			IF ( @debug_level > 2 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcrld.sp" + ", line " + STR( 275, 5 ) + " -- MSG: " + "accounting batch mode is on"
		END
		ELSE	
		BEGIN		
			IF ( @debug_level > 2 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcrld.sp" + ", line " + STR( 279, 5 ) + " -- MSG: " + "Not in accounting batch mode"
			
			IF ( @perf_level >= 2 ) EXEC perf_sp @batch_ctrl_num, "tmp/arcrld.sp", 284, "Start updating #arinppyt_work to make transaction available again", @PERF_time_last OUTPUT
			UPDATE	#arinppyt_work
			SET	batch_code = '',
				process_group_num = a.trx_ctrl_num,
				posted_flag = 0,
				db_action = db_action | 1
			FROM	#arinppyt_work a, #ewerror b
			WHERE	a.trx_ctrl_num = b.trx_ctrl_num
			 AND	a.trx_type = 2111
			IF( @@error != 0 )
			BEGIN
				IF ( @debug_level > 2 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcrld.sp" + ", line " + STR( 295, 5 ) + " -- MSG: " + "Update to #arinppyt_work failed"
				IF ( @debug_level > 2 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcrld.sp" + ", line " + STR( 296, 5 ) + " -- MSG: " + "@@error = " + STR( @@error, 6 )
				IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcrld.sp" + ", line " + STR( 297, 5 ) + " -- EXIT: "
				RETURN 34563
				RETURN -1
			END
			IF ( @perf_level >= 2 ) EXEC perf_sp @batch_ctrl_num, "tmp/arcrld.sp", 301, "Done updating #arinppyt_work to make transaction available again", @PERF_time_last OUTPUT
		END		
	END	
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcrld.sp" + ", line " + STR( 304, 5 ) + " -- EXIT: "
	IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, "tmp/arcrld.sp", 305, "Leaving ARCRLockDependencies_SP", @PERF_time_last OUTPUT
	RETURN 0
END
GO
GRANT EXECUTE ON  [dbo].[ARCRLockDependancies_SP] TO [public]
GO
