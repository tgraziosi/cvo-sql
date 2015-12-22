SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO





CREATE PROC [dbo].[APDMResetFlag_sp]	@batch_ctrl_num 	varchar(16),
								@client_id 			varchar(20),
								@user_id			smallint,  
								@process_ctrl_num 	varchar(16),
								@batch_proc_flag    smallint,
                                @debug_level        smallint = 0
    
AS

DECLARE
	@errbuf				varchar(100),
    @he_result          int,
    @result             int

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apdmrf.cpp" + ", line " + STR( 77, 5 ) + " -- ENTRY: "

	



	IF (( SELECT COUNT(1) FROM #ewerror ) = 0)
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
	SELECT 		    @process_ctrl_num,
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
	   FROM apinpchg, #apdmchg_work b
	   WHERE apinpchg.trx_ctrl_num = b.trx_ctrl_num
	   AND apinpchg.trx_type = b.trx_type


	   IF( @@error != 0)
	   BEGIN
	    ROLLBACK TRAN reset
	   	RETURN -1
	   END
	   
	   
	   


	   UPDATE	apvohdr
	   SET		state_flag = 1,
		   		process_ctrl_num = ''
	   FROM     apvohdr, #apdmchg_work b
	   WHERE    apvohdr.trx_ctrl_num = b.apply_to_num

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

	   



	   IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apdmrf.cpp" + ", line " + STR( 177, 5 ) + " -- EXIT: "
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
		  AND	apinpchg.trx_type = 4092

		IF( @@error != 0)
		   BEGIN
			ROLLBACK TRAN reset
			RETURN -1
		   END


		DELETE #apdmcdt_work
		FROM #apdmcdt_work a, #ewerror b
		WHERE  a.trx_ctrl_num = b.trx_ctrl_num
		
		IF( @@error != 0)
		   BEGIN
		    ROLLBACK TRAN reset
	   		RETURN -1
		   END



	   


	   UPDATE	apvohdr
	   SET		state_flag = 1,
		   		process_ctrl_num = ''
	   FROM     apvohdr, #apdmchg_work b, #ewerror c
	   WHERE    apvohdr.trx_ctrl_num = b.apply_to_num
	   AND      b.trx_ctrl_num = c.trx_ctrl_num

	   IF( @@error != 0)
	   BEGIN
	    ROLLBACK TRAN reset
	   	RETURN -1
	   END



	   DELETE   #apdmxv_work
	   FROM     #apdmxv_work a, #apdmchg_work b, #ewerror c
	   WHERE    a.trx_ctrl_num = b.apply_to_num
	   AND      b.trx_ctrl_num = c.trx_ctrl_num

	   IF( @@error != 0)
		   BEGIN
		    ROLLBACK TRAN reset
	   		RETURN -1
		   END

	   DELETE   #apdmxcdv_work
	   FROM     #apdmxv_work a, #apdmchg_work b, #ewerror c
	   WHERE    a.trx_ctrl_num = b.apply_to_num
	   AND      b.trx_ctrl_num = c.trx_ctrl_num

	   IF( @@error != 0)
		   BEGIN
		    ROLLBACK TRAN reset
	   		RETURN -1
		   END


		DELETE #apdmchg_work
		FROM #apdmchg_work a, #ewerror b
		WHERE  a.trx_ctrl_num = b.trx_ctrl_num


		IF( @@error != 0)
		   BEGIN
		    ROLLBACK TRAN reset
	   		RETURN -1
		   END

	   COMMIT TRAN reset
	   IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apdmrf.cpp" + ", line " + STR( 271, 5 ) + " -- EXIT: "
	   IF EXISTS(SELECT 1 FROM #apdmchg_work)
	      RETURN -2
	   ELSE
	      RETURN -3
	END

GO
GRANT EXECUTE ON  [dbo].[APDMResetFlag_sp] TO [public]
GO
