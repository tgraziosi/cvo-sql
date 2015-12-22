SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO





CREATE PROC [dbo].[APPAResetFlag_sp]
								@batch_ctrl_num 	varchar(16),
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


BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/apparf.sp" + ", line " + STR( 64, 5 ) + " -- ENTRY: "

	
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
	 
	 UPDATE	apinppyt
	 SET		posted_flag = 0,
		 		process_group_num = ' '
	 FROM apinppyt, #appapyt_work b
	 WHERE apinppyt.trx_ctrl_num = b.trx_ctrl_num
	 AND apinppyt.trx_type = b.trx_type 

	 IF( @@error != 0)
	 BEGIN
	 ROLLBACK TRAN reset
	 	RETURN -1
	 END


	 
	 UPDATE	appyhdr
	 SET		state_flag = 0,
		 		process_ctrl_num = ''
	 FROM appyhdr, #appatrxp_work b
	 WHERE appyhdr.trx_ctrl_num = b.trx_ctrl_num

	 IF( @@error != 0)
	 BEGIN
	 ROLLBACK TRAN reset
	 	RETURN -1
	 END



	 
	 UPDATE	apvohdr
	 SET		state_flag = 0,
		 		process_ctrl_num = ''
	 FROM apvohdr, #appatrxv_work b
	 WHERE apvohdr.trx_ctrl_num = b.trx_ctrl_num

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
	 
	 



	 RETURN -3
	END
	ELSE
	BEGIN
		
	 BEGIN TRAN RESET_NONBATCH
		UPDATE	apinppyt
		SET		batch_code = ' ',
				process_group_num = ' ',
				posted_flag = 0,
				hold_flag = 1
		FROM	apinppyt, #ewerror b
		WHERE	apinppyt.trx_ctrl_num = b.trx_ctrl_num
		 AND	apinppyt.trx_type IN (4112,4113,4114,4115,4121)


		IF( @@error != 0)
		 BEGIN
		 ROLLBACK TRAN reset
	 		RETURN -1
		 END


	 
	 UPDATE	apvohdr
	 SET		state_flag = 1,
		 		process_ctrl_num = ''
	 FROM apvohdr, #appapdt_work b, #ewerror c
	 WHERE apvohdr.trx_ctrl_num = b.apply_to_num
	 AND b.trx_ctrl_num = c.trx_ctrl_num

	 IF( @@error != 0)
	 BEGIN
	 ROLLBACK TRAN reset
	 	RETURN -1
	 END



	 DELETE #appatrxv_work
	 FROM #appatrxv_work a, #appapdt_work b, #ewerror c
	 WHERE a.trx_ctrl_num = b.apply_to_num
	 AND b.trx_ctrl_num = c.trx_ctrl_num

	 IF( @@error != 0)
		 BEGIN
		 ROLLBACK TRAN reset
	 		RETURN -1
		 END


	 UPDATE	appyhdr
	 SET		state_flag = 1,
		 		process_ctrl_num = ''
	 FROM appyhdr, #appapyt_work b, #ewerror c
	 WHERE appyhdr.doc_ctrl_num = b.doc_ctrl_num
	 AND appyhdr.cash_acct_code = b.cash_acct_code
	 AND b.trx_ctrl_num = c.trx_ctrl_num

	 IF( @@error != 0)
		 BEGIN
		 ROLLBACK TRAN reset
	 		RETURN -1
		 END

	 DELETE #appatrxp_work
	 FROM #appatrxp_work a, #appapyt_work b, #ewerror c
	 WHERE a.doc_ctrl_num = b.doc_ctrl_num
	 AND a.cash_acct_code = b.cash_acct_code
	 AND b.trx_ctrl_num = c.trx_ctrl_num

	 IF( @@error != 0)
		 BEGIN
		 ROLLBACK TRAN reset
	 		RETURN -1
		 END



		DELETE #appapdt_work
		FROM #appapdt_work a, #ewerror b
		WHERE a.trx_ctrl_num = b.trx_ctrl_num


		IF( @@error != 0)
		 BEGIN
		 ROLLBACK TRAN reset
	 		RETURN -1
		 END


		DELETE #appapyt_work
		FROM #appapyt_work a, #ewerror b
		WHERE a.trx_ctrl_num = b.trx_ctrl_num


		IF( @@error != 0)
		 BEGIN
		 ROLLBACK TRAN reset
	 		RETURN -1
		 END


		COMMIT TRAN RESET_NONBATCH

		IF (SELECT COUNT(*) FROM #appapyt_work) = 0
		 RETURN -3
	END

	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/apparf.sp" + ", line " + STR( 302, 5 ) + " -- EXIT: "
	RETURN 0
END
GO
GRANT EXECUTE ON  [dbo].[APPAResetFlag_sp] TO [public]
GO
