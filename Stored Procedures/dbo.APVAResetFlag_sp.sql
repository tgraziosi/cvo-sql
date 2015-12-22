SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO





CREATE PROC [dbo].[APVAResetFlag_sp]	@batch_ctrl_num 	varchar(16),
								@client_id 			varchar(20),
								@user_id			smallint, 
								@process_ctrl_num 	varchar(16),
								@batch_proc_flag smallint,
 @debug_level smallint = 0
AS

DECLARE
	@errbuf				varchar(100),
 @he_result int,
 @result int

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/apvarf.sp" + ", line " + STR( 60, 5 ) + " -- ENTRY: "

	
	IF (( SELECT COUNT(*) FROM #ewerror ) = 0)
	 RETURN 0

	

	INSERT perror(
				 process_ctrl_num,
					batch_code,
				 module_id,
					err_code,
					info1,
					info2,
					infoint,
					infofloat,
					flag1,
					trx_ctrl_num,
					sequence_id,
					source_ctrl_num,
					extra
				 )
	SELECT 		 @process_ctrl_num,
					@batch_ctrl_num,
					module_id,
					err_code,
					info1,
					info2,
					infoint,
					infofloat,
					flag1,
					trx_ctrl_num,
					sequence_id,
					source_ctrl_num,
					extra 
	FROM #ewerror


	
	IF( @batch_proc_flag = 1 ) 
	BEGIN

		BEGIN TRAN reset
	 
	 UPDATE	apinpchg
	 SET		posted_flag = 0,
		 		process_group_num = ' '
	 FROM apinpchg, #apvachg_work b
	 WHERE apinpchg.trx_ctrl_num = b.trx_ctrl_num
	 AND apinpchg.trx_type = 4021


	 IF( @@error != 0)
	 BEGIN
	 ROLLBACK TRAN reset
	 	RETURN -1
	 END
	 
	 
	 
	 UPDATE	apvohdr
	 SET		state_flag = 0,
		 		process_ctrl_num = ''
	 FROM apvohdr, #apvachg_work b
	 WHERE apvohdr.trx_ctrl_num = b.apply_to_num

	 IF( @@error != 0)
	 BEGIN
	 ROLLBACK TRAN reset
	 	RETURN -1
	 END


		EXEC	@result = batupdst_sp	@batch_ctrl_num, 0
		IF(@result != 0)
			BEGIN
				ROLLBACK TRAN reset
				RETURN -1
			END

	 COMMIT TRAN reset

	 
	 IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/apvarf.sp" + ", line " + STR( 159, 5 ) + " -- EXIT: "
	 RETURN -3
	END
	ELSE
	BEGIN

		BEGIN TRAN reset
		
		UPDATE	apinpchg
		SET		batch_code = ' ',
				process_group_num = ' ',
				posted_flag = 0,
				hold_flag = 1
		FROM	apinpchg, #ewerror b
		WHERE	apinpchg.trx_ctrl_num = b.trx_ctrl_num
		 AND	apinpchg.trx_type = 4021

		IF( @@error != 0)
		 BEGIN
			ROLLBACK TRAN reset
			RETURN -1
		 END


	 
	 UPDATE	apvohdr
	 SET		state_flag = 0,
		 		process_ctrl_num = ''
	 FROM apvohdr, #apvachg_work b, #ewerror c
	 WHERE apvohdr.trx_ctrl_num = b.apply_to_num
	 AND b.trx_ctrl_num = c.trx_ctrl_num

	 IF( @@error != 0)
	 BEGIN
	 ROLLBACK TRAN reset
	 	RETURN -1
	 END



	 DELETE #apvaxage_work
	 FROM #apvaxage_work a, #apvachg_work b, #ewerror c
	 WHERE a.trx_ctrl_num = b.apply_to_num
	 AND a.trx_type = 4091
	 AND b.trx_ctrl_num = c.trx_ctrl_num

	 IF( @@error != 0)
		 BEGIN
		 ROLLBACK TRAN reset
	 		RETURN -1
		 END

	 DELETE #apvaxcdv_work
	 FROM #apvaxcdv_work a, #apvachg_work b, #ewerror c
	 WHERE a.trx_ctrl_num = b.apply_to_num
	 AND b.trx_ctrl_num = c.trx_ctrl_num

	 IF( @@error != 0)
		 BEGIN
		 ROLLBACK TRAN reset
	 		RETURN -1
		 END

	 DELETE #apvaxv_work
	 FROM #apvaxv_work a, #apvachg_work b, #ewerror c
	 WHERE a.trx_ctrl_num = b.apply_to_num
	 AND b.trx_ctrl_num = c.trx_ctrl_num

	 IF( @@error != 0)
		 BEGIN
		 ROLLBACK TRAN reset
	 		RETURN -1
		 END

		DELETE #apvacdt_work
		FROM #apvacdt_work a, #ewerror b
		WHERE a.trx_ctrl_num = b.trx_ctrl_num
		
		IF( @@error != 0)
		 BEGIN
		 ROLLBACK TRAN reset
	 		RETURN -1
		 END

		DELETE #apvaage_work
		FROM #apvaage_work a, #ewerror b
		WHERE a.trx_ctrl_num = b.trx_ctrl_num
		
		IF( @@error != 0)
		 BEGIN
		 ROLLBACK TRAN reset
	 		RETURN -1
		 END


		DELETE #apvachg_work
		FROM #apvachg_work a, #ewerror b
		WHERE a.trx_ctrl_num = b.trx_ctrl_num


		IF( @@error != 0)
		 BEGIN
		 ROLLBACK TRAN reset
	 		RETURN -1
		 END



	 COMMIT TRAN reset
	 IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/apvarf.sp" + ", line " + STR( 275, 5 ) + " -- EXIT: "
	 IF EXISTS(SELECT * FROM #apvachg_work)
	 RETURN -2
	 ELSE
	 RETURN -3
	END

GO
GRANT EXECUTE ON  [dbo].[APVAResetFlag_sp] TO [public]
GO
