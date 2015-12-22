SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

/*                                                      
               Confidential Information                  
    Limited Distribution of Authorized Persons Only       
    Created 2008 and Protected as Unpublished Work       
          Under the U.S. Copyright Act of 1976            
 Copyright (c) 2008 Epicor Software Corporation, 2008    
                  All Rights Reserved                    
*/                                                




























































































CREATE PROC [dbo].[cmpost_sp](
			@x_posted_flag int,  
			@x_post_date int,
			@x_proc_key smallint, 
			@x_user_id smallint, 
			@x_orig_flag smallint)
AS      

DECLARE @next_jrnl_ctrl_code	int, 
	@jrnl_ctrl_code_mask	char(12),
	@total_trx		int, 
	@gl_exist		smallint,
	@jour_type		char(8),
	@cm_id 			int, 
	@next_gl_jcc		char(32),
	@trx_ctrl_num 		char(16),	
	@last_trx_ctrl_num 	char(16), 
	@trx_type 		smallint,
	@batch_code 		char(16), 
	@cash_acct_code 	char(32),
	@date_applied 		int, 
	@last_date_applied   	int, 
	@date_entered 		int, 
	@next_flag 		smallint,
	@float_holder 		float, 
	@int_holder 		int, 
	@jcc_len 		smallint,
	@char_holder 		char(80), 
	@seq_id 		smallint, 
	@last_sqid 		smallint, 
	@trx_type_cls 		char(8), 
	@line_desc 		char(40),
	@amt_extend 		float, 
	@account_code 		char(32), 
	@doc_ctrl_num 		char(16),
	@date_document  	int, 
	@auto_rec_flag 		smallint, 
	@debug_flag 		smallint,
	@company_code 		varchar(8), 
	@error_flag  		int, 	
	@ret_status 		int, 
	@company_id 		smallint, 
	@parent_company_id 	smallint,
	@source_batch_code 	varchar(16), 
	@rec_company_code 	varchar(8),
	@cmerror_msg 		varchar(100),
	@tran_start		smallint,
	@rate_type_home 	varchar(8),
	@rate_type_oper 	varchar(8),
	@str_msg 		varchar(255),
	@str_msg2		VARCHAR(255)

SELECT	@cm_id = 7000,
	@company_code = ' ', 
	@rec_company_code = ' ',
	@tran_start = 0 




SELECT	@company_id = company_id 
FROM	cmco

SELECT @rate_type_home = rate_type_home,
	   @rate_type_oper = rate_type_oper
FROM glco




SELECT	@total_trx = 0.0
SELECT	@total_trx = COUNT( trx_ctrl_num )
FROM	cmmanhdr      
WHERE	posted_flag = @x_posted_flag

IF (( @total_trx = NULL ) OR ( @total_trx !> 0.0 ))   
BEGIN

	EXEC appgetstring_sp "STR_CM_FAIL_POST_TRAN", @str_msg OUT

	EXEC 	status_sp	
			"CMPOST", 
			@x_proc_key, 
			@x_user_id, 
		  	@str_msg, 
			0, 
		  	@x_orig_flag, 
			1
	RETURN 
END 




SELECT	@gl_exist = NULL

SET ROWCOUNT 0

SELECT  @gl_exist = gl_flag
FROM    cmco

IF (( @@ROWCOUNT = 0 ) OR ( @gl_exist = NULL ))
BEGIN

	EXEC appgetstring_sp "STR_CM_FAIL_POST_CMCO", @str_msg OUT

	EXEC	status_sp	
			"CMPOST", 
			@x_proc_key, 
			@x_user_id, 
			@str_msg, 
			0, 
			@x_orig_flag, 
			1
	RETURN 
END

SELECT	@jour_type = NULL
SELECT	@jour_type = journal_type
FROM	glappid
WHERE	app_id = @cm_id

IF (( @@ROWCOUNT = 0 ) OR ( @jour_type = NULL ) OR (@jour_type = " " ))
BEGIN

	EXEC appgetstring_sp "STR_CM_FAIL_POST_GLAPPID", @str_msg OUT

	EXEC	status_sp	
			"CMPOST", 
			@x_proc_key, 	
			@x_user_id, 
		 	@str_msg, 
			0, 
			@x_orig_flag, 
			1
	RETURN
END
	 




SELECT	@total_trx = 0.0,
	@date_applied = 0
WHILE ( 1 = 1 )
BEGIN	

	


	SELECT	@last_date_applied = @date_applied
	SELECT	@date_applied = NULL
		
	SELECT	@date_applied = min(date_applied)
	FROM	cmmanhdr
	WHERE	posted_flag = @x_posted_flag
		
	SELECT	@last_date_applied = @date_applied,
		@batch_code = NULL

	


	IF ( @date_applied = NULL )
	BEGIN

		EXEC appgetstring_sp "STR_POSTED", @str_msg OUT
		EXEC appgetstring_sp "STR_TRANS_SUCCESS", @str_msg2 OUT

		SELECT 	@cmerror_msg = @str_msg + convert(varchar(5), @total_trx) + @str_msg2
		EXEC	status_sp	"CMPOST", 
					@x_proc_key, 
					@x_user_id, 
		   			@cmerror_msg, 
					100, 
					@x_orig_flag, 
					0
	
		RETURN
	END

	


  	SELECT @trx_ctrl_num = " "
	WHILE ( 1 = 1 )
	BEGIN	
		



		SELECT	@last_trx_ctrl_num = @trx_ctrl_num
		SELECT	@trx_ctrl_num = NULL
		
		SELECT	@trx_ctrl_num = min(trx_ctrl_num)
		FROM	cmmanhdr
		WHERE	posted_flag = @x_posted_flag
		  AND	trx_ctrl_num > @last_trx_ctrl_num
		  AND	date_applied = @date_applied
			
		SELECT	@trx_ctrl_num = trx_ctrl_num,
			@trx_type = trx_type,
			@cash_acct_code = cash_acct_code,
			@date_entered = date_entered,
			@source_batch_code = batch_code
		FROM	cmmanhdr
		WHERE	trx_ctrl_num = @trx_ctrl_num
			
		SELECT	@last_trx_ctrl_num = @trx_ctrl_num
	
		



		IF (@trx_ctrl_num = NULL)
			break

		IF ( @@trancount = 0 )
		BEGIN
			BEGIN TRANSACTION
			SELECT @tran_start = 1
		END

		



	        UPDATE  cmmanhdr
	        SET     posted_flag = 1
		WHERE   trx_type = @trx_type
		  AND	trx_ctrl_num = @trx_ctrl_num
		  AND	posted_flag = @x_posted_flag
	
		


		SELECT	@next_gl_jcc = NULL

		EXEC appgetstring_sp "STR_CM_POST", @str_msg OUT

		EXEC 	@ret_status = gltrxhdr_sp 
					@cm_id, 
					@jour_type, 
					@next_gl_jcc OUTPUT, 
					@str_msg, 
					@date_entered, 
					@date_applied,
					0, 
					0,	
					0,	
					@source_batch_code,
					@batch_code OUTPUT, 
					0, 		
					0, 
					@company_code, 
					' ', 		
					@trx_ctrl_num,	
					@trx_type, 
					@x_user_id,
					0, 		
					@error_flag OUTPUT

		IF ( @ret_status != 0 ) OR (@next_gl_jcc = NULL) 
		BEGIN
			ROLLBACK TRANSACTION
			EXEC glgetmsg_sp @ret_status, @cmerror_msg OUTPUT

			EXEC appgetstring_sp "STR_CM_FAIL_POST", @str_msg OUT

			SELECT @cmerror_msg = @str_msg + @cmerror_msg
			EXEC	status_sp	
					"CMPOST", 
					@x_proc_key, 
					@x_user_id, 
					@cmerror_msg, 
					0, 
					@x_orig_flag, 
					1
			RETURN
		END 
	
		


		SELECT  @seq_id = -1
		WHILE ( 1 = 1 )
		BEGIN	
			SELECT  @last_sqid = @seq_id
	
			SELECT  @seq_id = NULL
	
			SELECT  @seq_id = MIN(sequence_id)                          
			FROM    cmmandtl
			WHERE   trx_ctrl_num = @trx_ctrl_num
			  AND   trx_type = @trx_type
		       	  AND   sequence_id > @last_sqid
																
	
		       	SELECT	@seq_id = sequence_id,
				@account_code = account_code,
				@doc_ctrl_num = doc_ctrl_num,
				@date_document = date_document,
				@trx_type_cls = trx_type_cls,
				@amt_extend = amount_natural,
				@auto_rec_flag  = auto_rec_flag               
			FROM    cmmandtl
			WHERE   trx_ctrl_num = @trx_ctrl_num
			  AND   trx_type = @trx_type
			  AND   sequence_id = @seq_id
																
	
			SELECT	@line_desc = trx_type_cls_desc
			FROM	cmtrxcls
			WHERE	trx_type_cls = @trx_type_cls

			IF ( @seq_id = NULL )
				BREAK
	
			


			IF ( @amt_extend = 0.0 )
			BEGIN
			      	CONTINUE
			END 


			


			SELECT	@amt_extend = - @amt_extend
			EXEC	@ret_status = glacsum_sp
						@cm_id, 
						@next_gl_jcc, 
						@rec_company_code, 
						@company_id,
						@cash_acct_code, 
						@line_desc,
						@doc_ctrl_num, 
						@trx_ctrl_num,
						' ', 		
						@amt_extend, 	 
						@amt_extend, 	
						' ', 		
						1, 		
						@trx_type, 
						1, 		
						@amt_extend,
						1,
						@rate_type_home,
						@rate_type_oper,
						' ',		
						' ',		
						' ',		 
						' ',		
						@seq_id, 
						@error_flag OUTPUT
		
      			IF ( @ret_status != 0 )
			BEGIN
				ROLLBACK TRANSACTION
				EXEC glgetmsg_sp @ret_status, @cmerror_msg OUTPUT
				SELECT @cmerror_msg = @str_msg + @cmerror_msg
				EXEC	status_sp	
						"CMPOST", 
						@x_proc_key, 
						@x_user_id, 
						@cmerror_msg, 
						0, 
						@x_orig_flag, 
						1
				RETURN
			END 

			


			SELECT	@amt_extend = - @amt_extend
			EXEC	@ret_status = glacsum_sp 
						@cm_id, 
						@next_gl_jcc, 
						@rec_company_code, 	
						@company_id,
						@account_code, 
						@line_desc,
						@doc_ctrl_num, 
						@trx_ctrl_num,
						' ' ,	
						@amt_extend , 
						@amt_extend , 
						' ' , 
						1 , 
						@trx_type, 
						1 , 	
						@amt_extend,
						1,
						@rate_type_home,
						@rate_type_oper,
						' ' ,
						' ' , 	
						' ' , 
						' ' , 
						@seq_id, 
						@error_flag OUTPUT
			IF ( @ret_status != 0 )
			BEGIN
				ROLLBACK TRANSACTION
				EXEC glgetmsg_sp @ret_status, @cmerror_msg OUTPUT
				SELECT @cmerror_msg = @str_msg +
					@cmerror_msg
				EXEC	status_sp	"CMPOST", 
							@x_proc_key, 
							@x_user_id, 
							@cmerror_msg, 
							0, 
							@x_orig_flag, 
							1
				RETURN
			END 	
			
			IF EXISTS ( 
				SELECT	doc_ctrl_num	
				FROM	cminpdtl
			 	WHERE	trx_ctrl_num = @trx_ctrl_num
			 	  AND	trx_type = @trx_type
			 	  AND	doc_ctrl_num = @doc_ctrl_num 
				  )
			BEGIN
				ROLLBACK TRANSACTION

				EXEC appgetstring_sp "STR_CM_FAIL_POST_CMINPNEW", @str_msg OUT

				EXEC	status_sp	"CMPOST", 
							@x_proc_key, 
				   			@x_user_id, 
							@str_msg, 
				   			0, 
							@x_orig_flag, 
							1
				RETURN 
			END 
	
			EXEC	cminpnew_sp	@trx_ctrl_num, 
						@trx_type, 
						@auto_rec_flag, 
						@line_desc, 
						@doc_ctrl_num, 
						@cash_acct_code,
						@date_applied
		END	
	
		


		IF EXISTS ( 
			SELECT	trx_ctrl_num 
			FROM	cmtrx
			WHERE   trx_ctrl_num = @trx_ctrl_num
			  AND	trx_type = @trx_type 
			  )
		BEGIN
			ROLLBACK TRANSACTION		

			EXEC appgetstring_sp "STR_CM_FAIL_POST_CMTRX", @str_msg OUT
			EXEC	status_sp	"CMPOST", 
						@x_proc_key, 
						@x_user_id, 
						@str_msg, 
						0, 
						@x_orig_flag, 
						1
			RETURN
		END
	
		INSERT  cmtrx ( 
			trx_ctrl_num, 
			trx_type, 
			batch_code, 
			cash_acct_code,
			date_applied,
			date_entered,
			gl_trx_id,
			user_id,
			date_posted)
		SELECT	trx_ctrl_num, 
			trx_type, 
			batch_code, 
			cash_acct_code,
			date_applied, 
			date_entered, 
			@next_gl_jcc, 
			user_id, 
			@x_post_date
		FROM	cmmanhdr
		WHERE	trx_ctrl_num = @trx_ctrl_num
		  AND	trx_type = @trx_type

		


		IF EXISTS ( 
			SELECT	trx_ctrl_num 
			FROM	cmtrxdtl
			WHERE   trx_ctrl_num = @trx_ctrl_num
			  AND	trx_type = @trx_type 
			  )
		BEGIN
			ROLLBACK TRANSACTION

			EXEC appgetstring_sp "STR_CM_FAIL_POST_CMTRXDTL", @str_msg OUT
			EXEC	status_sp	
					"CMPOST", 
					@x_proc_key, 
					@x_user_id, 
					@str_msg, 
					0, 
					@x_orig_flag, 
					1
			RETURN 
		END
	
		INSERT cmtrxdtl (	trx_ctrl_num, 
					trx_type, 
					sequence_id,
					doc_ctrl_num, 
					date_document,
					trx_type_cls,
					account_code,
					amount_natural,
					auto_rec_flag	)
		SELECT  		trx_ctrl_num, 
					trx_type, 
					sequence_id,
					doc_ctrl_num, 
					date_document,
					trx_type_cls,
					account_code,
					amount_natural,
					auto_rec_flag   
		FROM    		cmmandtl
		WHERE   		trx_ctrl_num = @trx_ctrl_num
		  AND   		trx_type = @trx_type
			
		


		DELETE  cmmanhdr
		WHERE   trx_ctrl_num = @trx_ctrl_num
		  AND   trx_type = @trx_type

		DELETE  cmmandtl
		WHERE   trx_ctrl_num = @trx_ctrl_num
		  AND   trx_type = @trx_type

		SELECT	@total_trx = @total_trx + 1

		IF ( @tran_start = 1 )
		BEGIN
			COMMIT TRANSACTION
			SELECT @tran_start = 0
		END		

	END	
END 	
GO
GRANT EXECUTE ON  [dbo].[cmpost_sp] TO [public]
GO
