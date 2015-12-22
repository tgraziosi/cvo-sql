SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROC [dbo].[ARWOResetFlags_SP] 	@batch_ctrl_num	varchar(16),
					@process_ctrl_num 	varchar(16),
					@batch_proc_flag 	smallint,
					@process_user_id	smallint,
 	@debug_level 	smallint = 0,
					@perf_level		smallint = 0 
 					 

AS

DECLARE
	@company_code		varchar(8),
 	@result 	int,
	@tran_started		smallint

BEGIN

	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arworf.sp" + ", line " + STR( 54, 5 ) + " -- ENTRY: "

	
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
		
		
		UPDATE	#arinppyt_work 
		SET	hold_flag = 1,
			db_action = db_action | 1
		FROM	#arinppyt_work a, #ewerror b
		WHERE	a.trx_ctrl_num = b.trx_ctrl_num
		AND	a.trx_type = 2151
		IF( @@error != 0 )
		BEGIN
			IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arworf.sp" + ", line " + STR( 99, 5 ) + " -- EXIT: "
			RETURN 34563
		END

		
		UPDATE	#arinppyt_work 
		SET	posted_flag = 0,
			process_group_num = trx_ctrl_num,
			db_action = db_action | 1
		IF( @@error != 0 )
		BEGIN
			IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arworf.sp" + ", line " + STR( 112, 5 ) + " -- EXIT: "
			RETURN 34563
		END
		
		
		UPDATE	#artrx_work
		SET	posted_flag = 1,
			process_group_num = trx_ctrl_num,
			db_action = db_action | 1
		IF( @@error != 0 )
		BEGIN
			IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arworf.sp" + ", line " + STR( 125, 5 ) + " -- EXIT: "
			RETURN 34563
		END
		
		
		SELECT	@company_code = company_code
		FROM	glco

		
		IF( @@trancount = 0 )
		BEGIN
			BEGIN TRAN
			SELECT	@tran_started = 1
		END

							
		IF EXISTS(SELECT 1 FROM #ewerror WHERE err_code != 34554 )
			EXEC @result = batupdst_sp	@batch_ctrl_num,
							5
		ELSE
			EXEC @result = batupdst_sp	@batch_ctrl_num,
							0
		IF( @result != 0 )
		BEGIN
			IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arworf.sp" + ", line " + STR( 158, 5 ) + " -- EXIT: "
			RETURN 34563
		END

		EXEC @result = ARModifyPersistant_SP	@batch_ctrl_num,
								@debug_level,
 								@perf_level
			
		IF( @result != 0 )
		BEGIN
			IF( @tran_started = 1 )
			BEGIN
				ROLLBACK TRAN
				SELECT	@tran_started = 0
			END
			IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arworf.sp" + ", line " + STR( 173, 5 ) + " -- EXIT: "
			RETURN @result
		END
		
		IF( @tran_started = 1 )
		BEGIN
			COMMIT TRAN
			IF( @@error != 0 )
			BEGIN
				IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arworf.sp" + ", line " + STR( 182, 5 ) + " -- EXIT: "
				RETURN 34563
			END
		END

		
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arworf.sp" + ", line " + STR( 192, 5 ) + " -- EXIT: "
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

		
		UPDATE	#arinppyt_work 
		SET	batch_code = ' ',
			posted_flag = 0,
			process_group_num = a.trx_ctrl_num,
			hold_flag = 1,
			db_action = db_action | 1
		FROM	#arinppyt_work a, #ewerror b
		WHERE	a.trx_ctrl_num = b.trx_ctrl_num
		AND	a.trx_type = 2151
		AND	err_code != 34554
		IF( @@error != 0 )
		BEGIN
			IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arworf.sp" + ", line " + STR( 219, 5 ) + " -- EXIT: "
			RETURN 34563
		END
	END
	
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arworf.sp" + ", line " + STR( 224, 5 ) + " -- EXIT: "
	
	
	RETURN 34570
END
GO
GRANT EXECUTE ON  [dbo].[ARWOResetFlags_SP] TO [public]
GO
