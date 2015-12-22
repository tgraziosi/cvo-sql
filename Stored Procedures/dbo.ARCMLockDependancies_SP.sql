SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROC [dbo].[ARCMLockDependancies_SP]	@batch_ctrl_num	varchar( 16 ),
						@process_ctrl_num	varchar( 16 ),
						@batch_proc_flag	smallint,
						@debug_level		smallint = 0,
						@perf_level		smallint = 0 
AS






DECLARE
 @PERF_time_last datetime

SELECT @PERF_time_last = GETDATE()















									







DECLARE	@result			int,
		@all_trx_marked		int

IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, "tmp/arcmld.sp", 116, "Entering ARCMLockDependencies_SP", @PERF_time_last OUTPUT

BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcmld.sp" + ", line " + STR( 119, 5 ) + " -- ENTRY: "

	
	IF ( @perf_level >= 2 ) EXEC perf_sp @batch_ctrl_num, "tmp/arcmld.sp", 127, "Start inserting dependant transactions into #deplock", @PERF_time_last OUTPUT

	INSERT	#deplock
	(
		customer_code,		doc_ctrl_num,		trx_type,
		lock_status,			temp_flag
	)
	SELECT	master.customer_code,	master.apply_to_num,	master.apply_trx_type,
		0,			0
	FROM	artrx master, #arinpchg_work arinpchg
	WHERE	arinpchg.apply_to_num = master.doc_ctrl_num
	AND	arinpchg.apply_trx_type = master.trx_type
	AND	master.trx_type < 2051
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcmld.sp" + ", line " + STR( 142, 5 ) + " -- EXIT: "
		RETURN 34563
	END

	IF ( @perf_level >= 2 ) EXEC perf_sp @batch_ctrl_num, "tmp/arcmld.sp", 146, "Done inserting dependant transactions into #deplock", @PERF_time_last OUTPUT

		
	EXEC @result = ARMarkDependancies_SP	@batch_ctrl_num,
							@process_ctrl_num,
							@all_trx_marked OUTPUT,
							@debug_level,
							@perf_level
	IF( @result != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcmld.sp" + ", line " + STR( 158, 5 ) + " -- EXIT: "
		RETURN 34563
	END

	IF( @debug_level >= 4 )
	BEGIN
		SELECT	"Items in #deplock after locking"
		SELECT	doc_ctrl_num + " " + 
		STR(trx_type, 6) + " " + 
		STR(lock_status, 6)
		FROM	#deplock
	END

	
	IF( @all_trx_marked = 0 )
	BEGIN
		IF ( @debug_level > 2 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcmld.sp" + ", line " + STR( 177, 5 ) + " -- MSG: " + "Some dependant transactions didn't get locked"

		
		INSERT	#ewerror
		(	module_id, 					err_code,		
			info1,			info2,			infoint,
			infofloat,		flag1,			trx_ctrl_num,
			sequence_id,		source_ctrl_num,	extra
		)
		SELECT 2000,			20900,
			master.apply_to_num,	"",			0,
			0.0,			1,		b.trx_ctrl_num,
			0,			"",			0				
		FROM	artrx master, #deplock a, #arinpchg_work b
		WHERE	a.lock_status != 1
		AND	b.apply_to_num = master.doc_ctrl_num
		AND	b.apply_trx_type = master.trx_type
		AND	a.doc_ctrl_num = master.apply_to_num

		IF( @@error != 0 )
		BEGIN
			IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcmld.sp" + ", line " + STR( 201, 5 ) + " -- EXIT: "
			RETURN 34563
		END
		
		IF ( @debug_level > 2 )
		BEGIN
			SELECT "dumping #ewerror..."
			SELECT	"trx_ctrl_num = " + trx_ctrl_num +
				"apply_to_num = " + info1
			FROM	#ewerror
		END

		IF( @batch_proc_flag = 1 )
		BEGIN	
			IF ( @debug_level > 2 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcmld.sp" + ", line " + STR( 215, 5 ) + " -- MSG: " + "accounting batch mode is on"
			
			
			
		END
		ELSE	
		BEGIN		
			IF ( @debug_level > 2 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcmld.sp" + ", line " + STR( 228, 5 ) + " -- MSG: " + "Not in accounting batch mode"
			
			UPDATE	#arinpchg_work
			SET	batch_code = ' ',
				process_group_num = a.trx_ctrl_num,
				posted_flag = 0,
				db_action = db_action | 1
			FROM	#arinpchg_work a, #ewerror b
			WHERE	a.trx_ctrl_num = b.trx_ctrl_num
			
			IF( @@error != 0 )
			BEGIN
				IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcmld.sp" + ", line " + STR( 243, 5 ) + " -- EXIT: "
				RETURN 34563
			END
		END		
	END	

	IF( @debug_level >= 4 )
	BEGIN
		SELECT	"Dumping of #arinpchg_work..."
		SELECT	batch_code + " " + 
			trx_ctrl_num + " " + 
			STR(posted_flag, 6)
		FROM	#arinpchg_work
	END
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcmld.sp" + ", line " + STR( 257, 5 ) + " -- EXIT: "
	IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, "tmp/arcmld.sp", 258, "Leaving ARCMLockDependancies_SP", @PERF_time_last OUTPUT
	RETURN 0
END
GO
GRANT EXECUTE ON  [dbo].[ARCMLockDependancies_SP] TO [public]
GO
