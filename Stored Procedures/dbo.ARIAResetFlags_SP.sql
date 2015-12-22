SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROC [dbo].[ARIAResetFlags_SP] 	@batch_ctrl_num	varchar(16),
					@process_ctrl_num 	varchar(16),
					@batch_proc_flag 	smallint,
					@process_user_id	smallint,
 	@debug_level 	smallint = 0,
					@perf_level		smallint = 0 
 					 

AS

DECLARE
 	@result 	int

BEGIN

	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/ariarf.sp" + ", line " + STR( 52, 5 ) + " -- ENTRY: "

	
	IF (( SELECT COUNT(*) FROM #ewerror ) = 0)
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/ariarf.sp" + ", line " + STR( 59, 5 ) + " -- EXIT: "
	 	RETURN 0
	END

	
	INSERT perror
	(	process_ctrl_num,	batch_code,	module_id,
		err_code,		info1,		info2,
		infoint, 		infofloat, 	flag1,
		trx_ctrl_num,	 	sequence_id,	source_ctrl_num,
		extra
	)
	SELECT	@process_ctrl_num,	@batch_ctrl_num,	module_id,
		err_code,		info1,	 		info2,
		infoint, 		infofloat, 		flag1,
		trx_ctrl_num,		sequence_id,		source_ctrl_num,
		extra 
	FROM 	#ewerror
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/ariarf.sp" + ", line " + STR( 81, 5 ) + " -- EXIT: "
		RETURN @result
	END

	IF( @debug_level >= 2 )
	BEGIN
		SELECT	"Dumping #ewerror..."
		SELECT	"trx_ctrl_num = " + trx_ctrl_num 
		FROM	#ewerror
	END

	
	UPDATE	#arinpchg_work 
	SET	batch_code = ' ',
		posted_flag = 0,
		process_group_num = a.trx_ctrl_num,
		hold_flag = 1,
		db_action = db_action | 1
	FROM	#arinpchg_work a, #ewerror b
	WHERE	a.trx_ctrl_num = b.trx_ctrl_num
	AND	a.trx_type = 2051
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/ariarf.sp" + ", line " + STR( 106, 5 ) + " -- EXIT: "
		RETURN @result
	END
	
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/ariarf.sp" + ", line " + STR( 110, 5 ) + " -- EXIT: "
	
	
	RETURN 34570
END
GO
GRANT EXECUTE ON  [dbo].[ARIAResetFlags_SP] TO [public]
GO
