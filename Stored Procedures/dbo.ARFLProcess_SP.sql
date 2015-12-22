SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO










 



					 










































 








































































































































































































































































































































































































































































































CREATE PROC [dbo].[ARFLProcess_SP]	@batch_ctrl_num	varchar( 16 ),
				@process_ctrl_num	varchar( 16 ),
				@process_user_id	smallint,
				@journal_type		varchar( 8 ),
				@company_code		varchar( 8 ),
				@home_cur_code	varchar( 8 ),
				@oper_cur_code	varchar( 8 ),
				@charge_option	smallint,
				@date_applied		int,
				@debug_level		smallint = 0,
				@perf_level		smallint = 0	
AS






DECLARE
 @PERF_time_last datetime

SELECT @PERF_time_last = GETDATE()















									







DECLARE
	@result		int,
	@user_id		int,
	@tran_started		smallint

IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, "tmp/arflp.sp", 66, "Entering ARFLProcess_SP", @PERF_time_last OUTPUT

BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arflp.sp" + ", line " + STR( 69, 5 ) + " -- ENTRY: "

	
	EXEC @result = ARFLValidate_SP	@batch_ctrl_num,
						@debug_level,
						@perf_level
	IF( @result != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arflp.sp" + ", line " + STR( 79, 5 ) + " -- EXIT: "
		RETURN @result
	END

	IF EXISTS( SELECT * FROM #ewerror )
	BEGIN
		
		
		UPDATE	#artrx_work
		SET	posted_flag = 1,
			process_group_num = trx_ctrl_num,
			db_action = db_action | 1
		IF( @@error != 0 )
		BEGIN
			IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arflp.sp" + ", line " + STR( 99, 5 ) + " -- EXIT: "
			RETURN 34563
		END

		
		IF( @@trancount = 0 )
		BEGIN
			SELECT	@tran_started = 1
			BEGIN TRAN
		END
		
							
		IF EXISTS(SELECT 1 FROM #ewerror WHERE err_code != 34554 )
			EXEC @result = batupdst_sp	@batch_ctrl_num,
							5
		ELSE
			EXEC @result = batupdst_sp	@batch_ctrl_num,
								0
		IF( @result != 0 )
		BEGIN
			IF( @tran_started = 1 )
				ROLLBACK TRAN
			IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arflp.sp" + ", line " + STR( 126, 5 ) + " -- EXIT: "
			RETURN 34563
		END
		
		
		INSERT perror
		(	process_ctrl_num,	batch_code,		module_id,
			err_code,		info1,			info2,
			infoint, 		infofloat, 		flag1,
			trx_ctrl_num,	 	sequence_id,		source_ctrl_num,
			extra
		)
		SELECT	@process_ctrl_num,	@batch_ctrl_num,	module_id,
			err_code,		info1,	 		info2,
			infoint, 		infofloat, 		flag1,
			trx_ctrl_num,		sequence_id,		source_ctrl_num,
			extra 
		FROM 	#ewerror
		
		IF( @result != 0 )
		BEGIN
			IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arflp.sp" + ", line " + STR( 149, 5 ) + " -- EXIT: "
			RETURN 34563
		END
			
		
		EXEC @result = ARFLModifyPersistant_SP	@batch_ctrl_num,
								@debug_level,
 								@perf_level
		IF( @result != 0 )
		BEGIN
			IF( @tran_started = 1 )
				ROLLBACK TRAN
			IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arflp.sp" + ", line " + STR( 166, 5 ) + " -- EXIT: "
			RETURN @result
		END

		
		IF( @tran_started = 1 )
			COMMIT TRAN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arflp.sp" + ", line " + STR( 177, 5 ) + " -- EXIT: "
		RETURN 34562
	END
	
	
	EXEC @result = ARFLPostTemp_SP	@batch_ctrl_num,
						@process_ctrl_num,
						@process_user_id,
						@journal_type,
						@company_code,
						@home_cur_code,
						@oper_cur_code,
						@charge_option,
						@date_applied,
						@debug_level,
						@perf_level
	IF( @result != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arflp.sp" + ", line " + STR( 198, 5 ) + " -- EXIT: "
		RETURN @result
	END

	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arflp.sp" + ", line " + STR( 202, 5 ) + " -- EXIT: "
	IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, "tmp/arflp.sp", 203, "Leaving ARFLProcess_SP", @PERF_time_last OUTPUT
	RETURN 0
END
GO
GRANT EXECUTE ON  [dbo].[ARFLProcess_SP] TO [public]
GO
