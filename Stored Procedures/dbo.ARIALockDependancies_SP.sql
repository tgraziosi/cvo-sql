SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROC [dbo].[ARIALockDependancies_SP]	@batch_ctrl_num	varchar( 16 ),
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

IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, "tmp/ariald.sp", 52, "Entering ARIALockDependencies_SP", @PERF_time_last OUTPUT

BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/ariald.sp" + ", line " + STR( 55, 5 ) + " -- ENTRY: "

	
	IF ( @perf_level >= 2 ) EXEC perf_sp @batch_ctrl_num, "tmp/ariald.sp", 61, "Start inserting dependant transactions into #deplock", @PERF_time_last OUTPUT
	INSERT	#deplock
	(	
		customer_code,
		doc_ctrl_num, 
		trx_type, 
		lock_status,
		temp_flag 
	)
	SELECT		
		x.customer_code,
		x.apply_to_num,
		x.apply_trx_type,
		0,
		0
	FROM	#arinpchg_work chg, artrx x
	WHERE	chg.apply_to_num = x.doc_ctrl_num
	AND	chg.apply_trx_type = x.trx_type
	AND	chg.batch_code = @batch_ctrl_num
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/ariald.sp" + ", line " + STR( 82, 5 ) + " -- EXIT: "
		RETURN 34563
	END
	
	IF( @debug_level >= 4 )
	BEGIN
		SELECT	"Items in #deplock before locking"
		SELECT	doc_ctrl_num + " " + STR(trx_type, 6)
		FROM	#deplock
	END
	IF ( @perf_level >= 2 ) EXEC perf_sp @batch_ctrl_num, "tmp/ariald.sp", 92, "Done inserting dependant transactions into #deplock", @PERF_time_last OUTPUT

		
	IF EXISTS(	SELECT	'X'
			FROM	#deplock )
	BEGIN	
		EXEC @result = ARMarkDependancies_SP	@batch_ctrl_num,
								@process_ctrl_num,
								@all_trx_marked OUTPUT,
								@debug_level,
								@perf_level
		IF( @result != 0 )
		BEGIN
			IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/ariald.sp" + ", line " + STR( 107, 5 ) + " -- EXIT: "
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
	
	IF ( @all_trx_marked = 0 )
	BEGIN
		IF ( @debug_level > 2 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/ariald.sp" + ", line " + STR( 123, 5 ) + " -- MSG: " + "Some dependant transactions didn't get locked"
	
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
			IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/ariald.sp" + ", line " + STR( 141, 5 ) + " -- EXIT: "
		 	RETURN 34563
		END
	END
	
	IF( @debug_level >= 2 )
	BEGIN
		SELECT	"Dump of #ewerror..."
		SELECT	"trx_ctrl_num = " + trx_ctrl_num + 
			"info1 = " + info1 +
			"err_code = " + STR(err_code, 8)
		FROM	#ewerror
	END
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/ariald.sp" + ", line " + STR( 154, 5 ) + " -- EXIT: "
	IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, "tmp/ariald.sp", 155, "Leaving ARIALockDependancies_SP", @PERF_time_last OUTPUT
	RETURN 0
END
GO
GRANT EXECUTE ON  [dbo].[ARIALockDependancies_SP] TO [public]
GO
