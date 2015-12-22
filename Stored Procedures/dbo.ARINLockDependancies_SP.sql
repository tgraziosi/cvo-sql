SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROC [dbo].[ARINLockDependancies_SP]	@batch_ctrl_num	varchar( 16 ),
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

IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, "tmp/arinld.sp", 131, "Entering ARINLockDependencies_SP", @PERF_time_last OUTPUT

BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arinld.sp" + ", line " + STR( 134, 5 ) + " -- ENTRY: "

	
	IF ( @perf_level >= 2 ) EXEC perf_sp @batch_ctrl_num, "tmp/arinld.sp", 141, "Start inserting dependant transactions into #deplock", @PERF_time_last OUTPUT
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
		apply_to_num,
		apply_trx_type,
		0,
		0
	FROM	#arinpchg_work
	WHERE	batch_code = @batch_ctrl_num
	AND	apply_trx_type != 0
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arinld.sp" + ", line " + STR( 161, 5 ) + " -- EXIT: "
		RETURN 34563
	END
	IF( @debug_level >= 4 )
	BEGIN
		SELECT	"Items in #deplock before locking"
		SELECT	doc_ctrl_num + " " + STR(trx_type, 6)
		FROM	#deplock
	END
	IF ( @perf_level >= 2 ) EXEC perf_sp @batch_ctrl_num, "tmp/arinld.sp", 170, "Done inserting dependant transactions into #deplock", @PERF_time_last OUTPUT

		
	IF EXISTS(	SELECT	*
			FROM	#deplock )
	BEGIN	
		EXEC @result = ARMarkDependancies_SP	@batch_ctrl_num,
								@process_ctrl_num,
								@all_trx_marked OUTPUT,
								@debug_level,
								@perf_level
		IF( @result != 0 )
		BEGIN
			IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arinld.sp" + ", line " + STR( 185, 5 ) + " -- EXIT: "
			RETURN 34563
		END
	END
	ELSE
		SELECT	@all_trx_marked = 1
		
	IF( @debug_level >= 4 )
	BEGIN
		SELECT	"Items in #deplock after locking"
		SELECT	doc_ctrl_num + " " + STR(trx_type, 6) + " " + STR(lock_status, 6)
		FROM	#deplock
	END

	
	IF( @all_trx_marked = 0 )
	BEGIN
		IF ( @debug_level > 2 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arinld.sp" + ", line " + STR( 205, 5 ) + " -- MSG: " + "Some dependant transactions didn't get locked"

		
		INSERT	#ewerror
		(	module_id, 					err_code,		
			info1,			info2,			infoint,
		 	infofloat,		flag1,			trx_ctrl_num,
		 	sequence_id,		source_ctrl_num,	extra
		)
		SELECT 2000,			20900,
			a.doc_ctrl_num,	"",			0,
			0.0,			1,		b.trx_ctrl_num,
			0,			"",			0				
		FROM	#deplock a, #arinpchg_work b
		WHERE	a.lock_status != 1
		AND	b.apply_to_num = a.doc_ctrl_num

		IF( @@error != 0 )
		BEGIN
			IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arinld.sp" + ", line " + STR( 227, 5 ) + " -- EXIT: "
		 	RETURN 34563
		END
						
		IF( @batch_proc_flag = 1 )
		BEGIN	
			IF ( @debug_level > 2 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arinld.sp" + ", line " + STR( 233, 5 ) + " -- MSG: " + "accounting batch mode is on"
			IF ( @debug_level > 2 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arinld.sp" + ", line " + STR( 234, 5 ) + " -- MSG: " + "The batch has errors so kick out this batch"
			
		END
		ELSE	
		BEGIN		
			IF ( @debug_level > 2 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arinld.sp" + ", line " + STR( 245, 5 ) + " -- MSG: " + "Not in accounting batch mode"
			
			UPDATE	#arinpchg_work
			SET	batch_code = ' ',
				process_group_num = a.trx_ctrl_num,
				posted_flag = 0
			FROM	arinpchg a, #ewerror b
			WHERE	a.trx_ctrl_num = b.trx_ctrl_num
			AND	a.trx_type >= 2021
			AND	a.trx_type <= 2031
			
			IF( @@error != 0 )
			BEGIN
				IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arinld.sp" + ", line " + STR( 261, 5 ) + " -- EXIT: "
				RETURN 34563
			END
		END		
	END	

	IF( @debug_level >= 4 )
	BEGIN
		SELECT	"Dump of #arinpchg_work after locking"
		SELECT	batch_code + " " + trx_ctrl_num + " " + STR(posted_flag, 6)
		FROM	#arinpchg_work
		
		SELECT "Dumping #ewerror..."
		SELECT "trx_ctrl_num = " + trx_ctrl_num +
			"err_code = " + str(err_code, 8) +
			"info1 = " + info1
		FROM	#ewerror
	END
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arinld.sp" + ", line " + STR( 279, 5 ) + " -- EXIT: "
	IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, "tmp/arinld.sp", 280, "Leaving ARINLockDependancies_SP", @PERF_time_last OUTPUT
	RETURN 0
END
GO
GRANT EXECUTE ON  [dbo].[ARINLockDependancies_SP] TO [public]
GO
