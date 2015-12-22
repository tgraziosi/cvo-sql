SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROC [dbo].[ARCALockDependancies_SP]	@batch_ctrl_num	varchar( 16 ),
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

IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, "tmp/arcald.sp", 52, "Entering ARCALockDependancies_SP", @PERF_time_last OUTPUT

BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcald.sp" + ", line " + STR( 55, 5 ) + " -- ENTRY: "
	
	IF ( @perf_level >= 2 ) EXEC perf_sp @batch_ctrl_num, "tmp/arcald.sp", 65, "Start inserting dependant transactions into #deplock", @PERF_time_last OUTPUT
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
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 2 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcald.sp" + ", line " + STR( 85, 5 ) + " -- MSG: " + "Error inserting into #deplock"
		IF ( @debug_level > 2 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcald.sp" + ", line " + STR( 86, 5 ) + " -- MSG: " + "@@error = " + STR(@@error, 7)
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcald.sp" + ", line " + STR( 87, 5 ) + " -- EXIT: "
		RETURN 34563
	END

	
	INSERT #deplock
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
		2111,
		0,
		0
	FROM	#arinppyt_work

	IF ( @perf_level >= 2 ) EXEC perf_sp @batch_ctrl_num, "tmp/arcald.sp", 111, "Done inserting dependant transactions into #deplock", @PERF_time_last OUTPUT

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
		IF ( @debug_level > 2 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcald.sp" + ", line " + STR( 135, 5 ) + " -- MSG: " + "ARMarkDependancies_SP has failed"
		IF ( @debug_level > 2 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcald.sp" + ", line " + STR( 136, 5 ) + " -- MSG: " + "@result = " + STR( @result, 6 )
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcald.sp" + ", line " + STR( 137, 5 ) + " -- EXIT: "
		RETURN 34563
	END
			
	
	IF( @all_trx_marked = 0 )
	BEGIN
		
		IF ( @perf_level >= 3 ) EXEC perf_sp @batch_ctrl_num, "tmp/arcald.sp", 151, "Start inserting errors into #ewerror", @PERF_time_last OUTPUT
		
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

		IF( @debug_level >= 2 )
		BEGIN

			SELECT "before inserting into #ewerror deplock contains"
			SELECT	customer_code + " " +
				doc_ctrl_num + " " + 
				STR(trx_type, 6) + " " + 
				STR(lock_status, 6) + " " + 
				STR(temp_flag, 6)
			FROM	#deplock
			
			SELECT	"before inserting into #ewerror arinppyt_work contains"
			SELECT	customer_code + " " +
				doc_ctrl_num + " " + 
				STR(trx_type, 6) 
			FROM	#arinppyt_work

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
		AND	a.customer_code = b.customer_code
		AND	a.doc_ctrl_num = b.doc_ctrl_num
		AND	b.trx_type between 2112 and 2121

		IF( @@error != 0 )
		BEGIN
			IF ( @debug_level > 2 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcald.sp" + ", line " + STR( 211, 5 ) + " -- MSG: " + "Insert into #ewerror failed"
			IF ( @debug_level > 2 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcald.sp" + ", line " + STR( 212, 5 ) + " -- MSG: " + "@@error = " + STR( @@error, 6 )
			IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcald.sp" + ", line " + STR( 213, 5 ) + " -- EXIT: "
			RETURN 34563
		END
		IF ( @perf_level >= 3 ) EXEC perf_sp @batch_ctrl_num, "tmp/arcald.sp", 216, "Done inserting errors into #ewerror", @PERF_time_last OUTPUT

		IF( @debug_level >= 2 )
		BEGIN
			SELECT "arhold has been loaded with the following"
			SELECT "trx_ctrl_num = " + trx_ctrl_num 
			FROM #ewerror
		END
	
		IF( @batch_proc_flag = 1 )
		BEGIN	
			IF ( @debug_level > 2 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcald.sp" + ", line " + STR( 227, 5 ) + " -- MSG: " + "accounting batch mode is on"
		END
		ELSE	
		BEGIN		
			IF ( @debug_level > 2 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcald.sp" + ", line " + STR( 231, 5 ) + " -- MSG: " + "Not in accounting batch mode"
			
			IF ( @perf_level >= 2 ) EXEC perf_sp @batch_ctrl_num, "tmp/arcald.sp", 236, "Start updating #arinppyt_work to make transaction available again", @PERF_time_last OUTPUT
			UPDATE	#arinppyt_work
			SET	process_group_num = a.trx_ctrl_num,
				batch_code = ' ',
				posted_flag = 0,
				db_action = db_action | 1
			FROM	#arinppyt_work a, #ewerror b
			WHERE	a.trx_ctrl_num = b.trx_ctrl_num
			IF( @@error != 0 )
			BEGIN
				IF ( @debug_level > 2 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcald.sp" + ", line " + STR( 246, 5 ) + " -- MSG: " + "Update to #arinppyt_work failed"
				IF ( @debug_level > 2 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcald.sp" + ", line " + STR( 247, 5 ) + " -- MSG: " + "@@error = " + STR( @@error, 6 )
				IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcald.sp" + ", line " + STR( 248, 5 ) + " -- EXIT: "
				RETURN 34563
				RETURN -1
			END
			IF ( @perf_level >= 2 ) EXEC perf_sp @batch_ctrl_num, "tmp/arcald.sp", 252, "Done updating #arinppyt_work to make transaction available again", @PERF_time_last OUTPUT
		END		
	END	
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcald.sp" + ", line " + STR( 255, 5 ) + " -- EXIT: "
	IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, "tmp/arcald.sp", 256, "Leaving ARCALockDependancies_SP", @PERF_time_last OUTPUT
	RETURN 0
END
GO
GRANT EXECUTE ON  [dbo].[ARCALockDependancies_SP] TO [public]
GO
