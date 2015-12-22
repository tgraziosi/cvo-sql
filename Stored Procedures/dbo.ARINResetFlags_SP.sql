SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROC [dbo].[ARINResetFlags_SP] 	@batch_ctrl_num	varchar(16),
					@process_ctrl_num 	varchar(16),
					@batch_proc_flag 	smallint,
					@process_user_id	smallint,
 	@debug_level 	smallint = 0,
					@perf_level		smallint = 0 
 					 

AS

DECLARE
 	@result 	int,
	@tran_started		smallint

BEGIN

	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arinrf.sp" + ", line " + STR( 54, 5 ) + " -- ENTRY: "

	
	IF (( SELECT COUNT(*) FROM #ewerror ) = 0)
	 RETURN 0

	
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


	IF( @batch_proc_flag = 1 )
	BEGIN
		
		
		UPDATE	#arinpchg_work 
		SET	hold_flag = 1,
			db_action = db_action | 1
		FROM	#arinpchg_work a, #ewerror b
		WHERE	a.trx_ctrl_num = b.trx_ctrl_num
		AND	a.trx_type >= 2021
		AND	a.trx_type <= 2031
		IF( @@error != 0 )
		BEGIN
			IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arinrf.sp" + ", line " + STR( 100, 5 ) + " -- EXIT: "
			RETURN 34563
		END

		
		UPDATE	#arinpchg_work 
		SET	posted_flag = 0,
			process_group_num = trx_ctrl_num,
			db_action = db_action | 1
		IF( @@error != 0 )
		BEGIN
			IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arinrf.sp" + ", line " + STR( 113, 5 ) + " -- EXIT: "
			RETURN 34563
		END
		
		
		UPDATE	#artrx_work
		SET	posted_flag = 1,
			process_group_num = trx_ctrl_num,
			db_action = db_action | 1
		IF( @@error != 0 )
		BEGIN
			IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arinrf.sp" + ", line " + STR( 126, 5 ) + " -- EXIT: "
			RETURN 34563
		END
		
		
		IF( @@trancount = 0 )
		BEGIN
			BEGIN TRAN
			SELECT	@tran_started = 1
		END

							
		IF EXISTS(SELECT 1 FROM #ewerror WHERE err_code != 20900 )
			EXEC @result = batupdst_sp	@batch_ctrl_num,
							5
		ELSE
			EXEC @result = batupdst_sp	@batch_ctrl_num,
							0
		IF( @result != 0 )
		BEGIN
			IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arinrf.sp" + ", line " + STR( 153, 5 ) + " -- EXIT: "
			RETURN 34563
		END

		EXEC @result = ARINModifyPersistant_SP	@batch_ctrl_num,
								@debug_level,
								@perf_level
		
		IF( @result != 0 )
		BEGIN
			IF( @tran_started = 1 )
			BEGIN
				ROLLBACK TRAN
				SELECT	@tran_started = 0
			END
			IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arinrf.sp" + ", line " + STR( 168, 5 ) + " -- EXIT: "
			RETURN @result
		END
		
		IF( @tran_started = 1 )
		BEGIN
			COMMIT TRAN
			IF( @@error != 0 )
			BEGIN
				IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arinrf.sp" + ", line " + STR( 177, 5 ) + " -- EXIT: "
				RETURN 34563
			END
		END

		
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arinrf.sp" + ", line " + STR( 187, 5 ) + " -- EXIT: "
		RETURN 34562
	END
	ELSE 
	BEGIN
		IF( @debug_level >= 2 )
		BEGIN
			SELECT	"Transaction to be put on hold"
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
		
 AND a.trx_type in ( 2021, 2031 )
		AND	err_code != 34554
		IF( @@error != 0 )
		BEGIN
			IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arinrf.sp" + ", line " + STR( 218, 5 ) + " -- EXIT: "
			RETURN @result
		END
	END
	
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arinrf.sp" + ", line " + STR( 223, 5 ) + " -- EXIT: "
	
	
	RETURN 34570
END
GO
GRANT EXECUTE ON  [dbo].[ARINResetFlags_SP] TO [public]
GO
