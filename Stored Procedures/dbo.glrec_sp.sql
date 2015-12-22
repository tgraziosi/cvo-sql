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


































































CREATE  PROCEDURE [dbo].[glrec_sp] 
	@posted_flag 		int,       
	@sys_date 		int,          
	@period_end_date 	int,
	@company_code		varchar(8),
	@proc_key 		smallint,     
	@user_id 		smallint,      
	@orig_flag 		smallint
AS
DECLARE                  
	@E_CANT_GEN_TRX_NUM	int,
	@E_CANT_INSERT_GLTRX	int,
	@E_INVALID_COMPID	int,
	@E_NO_VALID_REC_TRX	int,
	@E_AUTO_GEN_OK		int,
	@E_AUTO_GEN_OK_ERR	int,
	@E_GEN_RECUR_ERR	int,
	@E_NO_MATCHING_PRD	int,
	@E_INVALID_ACCTCODE	int,
	@base_amt 		float,        
        @batch_on       	smallint,      
	@client_id		varchar(20),
	@company_id		smallint,	
	@continue_flag 		smallint,         
	@cur_date 		int,
	@err_msg 		varchar(80),   
	@found_errors		smallint,
	@gl_module 		int,         
        @gltrx_posted_flg	smallint,    
	@home_cur_code		varchar(8),
	@int_buff 		int, 
	@jour_desc 		varchar(40),
	@jour_num 		varchar(32), 
	@last_applied 		int,         
	@length 		smallint,   	
	@nat_cur_code 		varchar(8), 	
	@new_jour_num 		varchar(32), 
	@next_batch_code	varchar(16),	
	@next_code 		varchar(32),	
	@num_prd 		smallint,	
	@perc_done 		float,	    	
	@perc_flag 		smallint,   
	@period 		smallint,    
	@period1 		int,           
	@period2 		int, 	      
	@period3 		int,           
	@period4 		int,         
	@period5 		int, 
	@period6 		int,      	
	@period7 		int,           
	@period8 		int,		
	@period9 		int,         
	@period10 		int,    	
	@period11 		int,
	@period12 		int,    	
	@period13 		int,        
	@rate			float,
	@rec_type 		smallint,     
	@recur_if_zero 		smallint,    
	@result			int,
	@save_date 		int,        	
	@start_col 		smallint,    
	@to_amount		float,		
	@tot_trx 		float,         
	@tot_trx_done 		float,	      
	@track_bal_amt 		float,	      
	@track_bal_flag 	smallint, 
	@tran_started		tinyint,
	@user_name		varchar(30),
	@year_end_type 		smallint
        ,
        @oper_cur_code          varchar(8),
        @rate_type_home         varchar(8),
        @rate_type_oper         varchar(8),
        @rate_oper              float,
	@interbranch_flag 	int,
	@org_id			varchar(30), 
	@str_msg		varchar(255)


			



SELECT  @gl_module = 6000, 
	@rec_type = 2,
	@client_id = "POSTTRX"




SELECT	@tran_started = 0

SELECT	@E_INVALID_ACCTCODE = e_code
FROM	glerrdef
WHERE	e_sdesc = "E_INVALID_ACCTCODE"

SELECT	@E_CANT_GEN_TRX_NUM = e_code
FROM	glerrdef
WHERE	e_sdesc = "E_CANT_GEN_TRX_NUM"

SELECT	@E_CANT_INSERT_GLTRX = e_code
FROM	glerrdef
WHERE	e_sdesc = "E_CANT_INSERT_GLTRX"

SELECT	@E_INVALID_COMPID = e_code
FROM	glerrdef
WHERE	e_sdesc = "E_INVALID_COMPID"

SELECT	@E_AUTO_GEN_OK = e_code
FROM	glerrdef
WHERE	e_sdesc = "E_AUTO_GEN_OK"

SELECT	@E_AUTO_GEN_OK_ERR = e_code
FROM	glerrdef
WHERE	e_sdesc = "E_AUTO_GEN_OK_ERR"

SELECT	@E_GEN_RECUR_ERR = e_code
FROM	glerrdef
WHERE	e_sdesc = "E_GEN_RECUR_ERR"

SELECT	@E_NO_VALID_REC_TRX = e_code
FROM	glerrdef
WHERE	e_sdesc = "E_NO_VALID_REC_TRX"

SELECT	@E_NO_MATCHING_PRD = e_code
FROM	glerrdef
WHERE	e_sdesc = "E_NO_MATCHING_PRD"

SELECT @found_errors = 0




SELECT  @user_name = user_name 
FROM    CVO_Control..smusers 
WHERE   user_id=@user_id




SELECT  @tot_trx = NULL

SELECT  @tot_trx = count(journal_ctrl_num)
FROM    glrecur
WHERE   posted_flag = @posted_flag
AND	date_last_applied < @period_end_date

IF (( @tot_trx IS NULL ) OR ( @tot_trx = 0.0 ))
BEGIN
	EXEC	glgetmsg_sp	@E_NO_VALID_REC_TRX,
				@err_msg OUTPUT

	EXEC status_sp	"GLREC",
			@proc_key, 
			@user_id, 
			@err_msg, 
			100, 
			@orig_flag, 
			0

        UPDATE glrecur 
	SET    posted_flag = 0
	WHERE  posted_flag = @posted_flag

        RETURN 0
END





EXEC appgetstring_sp "STR_PROCESSING", @str_msg OUT

EXEC status_sp "GLREC", @proc_key, @user_id, @str_msg, 
			0, @orig_flag, 0



		

SELECT 	@company_id = company_id,
        @home_cur_code = home_currency,
        @oper_cur_code = oper_currency,
        @rate_type_home = rate_type_home,
        @rate_type_oper = rate_type_oper
FROM	glco
		


		
IF ( @@ROWCOUNT != 1 )		
BEGIN		
	EXEC	glgetmsg_sp	@E_INVALID_COMPID,
				@err_msg	OUTPUT

	EXEC 	status_sp "GLREC",@proc_key, 			
			@user_id, @err_msg,0,			
			@orig_flag, 1			
		
	UPDATE	glrecur			
	SET 	posted_flag = 0			
	WHERE	posted_flag = @posted_flag			
		
	EXEC	glputerr_sp	@client_id, 
				@user_id, 
				@E_INVALID_COMPID, 
				NULL, 
				NULL, 
				NULL, 
				NULL, 
				NULL, 
				NULL

	return @E_INVALID_COMPID

END		

SELECT  @tot_trx_done = 0.0

WHILE ( 1 = 1 )
BEGIN
	


	SELECT  @jour_num = NULL

	




	SELECT  @jour_num = MIN(journal_ctrl_num)
	FROM    glrecur
	WHERE   posted_flag = @posted_flag

	


	IF  ( @jour_num IS NULL )
	BEGIN
		IF ( @found_errors = 1 )
			EXEC	glgetmsg_sp	@E_AUTO_GEN_OK_ERR,
 						@err_msg OUTPUT
		ELSE
			EXEC	glgetmsg_sp	@E_AUTO_GEN_OK,
						@err_msg OUTPUT

		EXEC status_sp	"GLREC", 
				@proc_key, 
				@user_id, 
				@err_msg, 
				100, 
				@orig_flag, 
				0

		IF ( @tran_started = 1 )
		BEGIN
			COMMIT TRAN
			SELECT @tran_started = 0
		END

		RETURN 0
	END

	SET     ROWCOUNT  0

	SELECT  @track_bal_flag = tracked_balance_flag,
		@perc_flag      = percentage_flag,
		@continue_flag  = continuous_flag,
		@recur_if_zero  = recur_if_zero_flag,
		@year_end_type  = year_end_type,
		@track_bal_amt  = tracked_balance_amount,
		@base_amt       = base_amount,
		@jour_desc      = recur_description,
		@last_applied   = date_last_applied,
		@period1        = date_end_period_1,
		@period2  = date_end_period_2,
		@period3  = date_end_period_3,
		@period4  = date_end_period_4,
		@period5  = date_end_period_5,
		@period6  = date_end_period_6,
		@period7  = date_end_period_7,
		@period8  = date_end_period_8,
		@period9  = date_end_period_9,
		@period10 = date_end_period_10,
		@period11 = date_end_period_11,
		@period12 = date_end_period_12,
		@period13 = date_end_period_13,
		@num_prd = number_of_periods,
                @nat_cur_code = nat_cur_code,
                @rate_type_home = rate_type_home,
                @rate_type_oper = rate_type_oper,
		@interbranch_flag = interbranch_flag,
		@org_id	= org_id	
	FROM    glrecur
	WHERE   journal_ctrl_num = @jour_num

	







	IF (@period_end_date <= @last_applied OR @num_prd = 0)
	BEGIN
		UPDATE 	glrecur 
		SET 	posted_flag = 0
		WHERE 	journal_ctrl_num = @jour_num


		CONTINUE
	END

	IF (     @track_bal_flag = 1 
	     AND @track_bal_amt <= 0.0 
	     AND @recur_if_zero  = 0
	   )
	BEGIN
        	UPDATE glrecur 
		SET    posted_flag = 0
		WHERE  journal_ctrl_num = @jour_num

		EXEC @result =	glputerr_sp	
			@client_id, 
			@user_id, 
			@E_GEN_RECUR_ERR, 
			NULL, 
			NULL, 
			@jour_num, 
			NULL, 
			NULL, 
			NULL

		SELECT @found_errors = 1

		CONTINUE

	END

	



	IF ( @continue_flag = 1 )
	BEGIN
		IF ( @period_end_date >= @period1 )
			SELECT  @period = 1
		ELSE
		BEGIN
			




			EXEC	glputerr_sp	@client_id, 
						@user_id, 
						@E_NO_MATCHING_PRD, 
						NULL, 
						NULL, 
						@jour_num, 
						NULL, 
						@period_end_date, 
						NULL

			UPDATE	glrecur 
			SET 	posted_flag = 0
			WHERE 	journal_ctrl_num = @jour_num

			SELECT	@found_errors = 1

			CONTINUE
		END
	END
	ELSE
	BEGIN
		IF ( @period_end_date = @period1 )
			SELECT  @period = 1
		ELSE IF ( @period_end_date = @period2 )
			SELECT  @period = 2
		ELSE IF ( @period_end_date = @period3 )
			SELECT  @period = 3
		ELSE IF ( @period_end_date = @period4 )
			SELECT  @period = 4
		ELSE IF ( @period_end_date = @period5 )
			SELECT  @period = 5
		ELSE IF ( @period_end_date = @period6 )
			SELECT  @period = 6
		ELSE IF ( @period_end_date = @period7 )
			SELECT  @period = 7
		ELSE IF ( @period_end_date = @period8 )
			SELECT  @period = 8
		ELSE IF ( @period_end_date = @period9 )
			SELECT  @period = 9
		ELSE IF ( @period_end_date = @period10 )
			SELECT  @period = 10
		ELSE IF ( @period_end_date = @period11 )
			SELECT  @period = 11
		ELSE IF ( @period_end_date = @period12 )
			SELECT  @period = 12
		ELSE IF ( @period_end_date = @period13 )
			SELECT  @period = 13
		ELSE
		BEGIN
			




			EXEC	glputerr_sp	@client_id, 
						@user_id, 
						@E_NO_MATCHING_PRD, 
						NULL, 
						NULL, 
						@jour_num, 
						NULL, 
						@period_end_date, 
						NULL

			UPDATE	glrecur 
			SET 	posted_flag = 0
			WHERE 	journal_ctrl_num = @jour_num

			SELECT	@found_errors = 1

			CONTINUE
		END
	END

	




	IF ( @@trancount = 0 )
	BEGIN
		BEGIN TRAN
		SELECT	@tran_started = 1
	END

	


	EXEC	@result = glnxttrx_sp	@next_code	OUTPUT

	IF ( @result != 0 )
	BEGIN
		IF ( @tran_started = 1 )
		BEGIN
			ROLLBACK TRAN
			SELECT	@tran_started = 0
		END

		EXEC	glputerr_sp	@client_id, 
					@user_id, 
					@result,
					"glrec.sp", 
					NULL, 
					@jour_num, 
					NULL, 
					NULL, 
					NULL

		SELECT	@found_errors = 1

		



		UPDATE	glrecur
		SET	posted_flag = 0
		WHERE	journal_ctrl_num = @jour_num

		CONTINUE	
	END
	
        


        EXEC @result = glnxtbat_sp	@gl_module, 
					" ", 
					6030, 
                         		@user_name, 
					@period_end_date, 
					@company_code,
                         		@next_batch_code OUTPUT,
					@org_id 	
	IF ( @result != 0 )
	BEGIN
		IF ( @tran_started = 1 )
		BEGIN
			ROLLBACK TRAN
			SELECT	@tran_started = 0
		END

		EXEC	glputerr_sp	@client_id, 
					@user_id, 
					@result, 
					"glrec.sp", 
					NULL, 
					@jour_num, 
					NULL, 
					NULL, 
					NULL

		SELECT	@found_errors = 1

		



		UPDATE	glrecur
		SET	posted_flag = 0
		WHERE	journal_ctrl_num = @jour_num

		CONTINUE	
	END

        




	EXEC appgetstring_sp "STR_RECURRING_TRANS", @str_msg OUT

	INSERT  gltrx
		(journal_type,          journal_ctrl_num,
		journal_description,    date_entered,
		date_applied,           recurring_flag,
		repeating_flag,         reversing_flag,
		hold_flag,              posted_flag,            
		date_posted,            source_batch_code,
		batch_code,             type_flag,
		intercompany_flag,	company_code,
		app_id,			home_cur_code,
		document_1,		trx_type,	  	
		user_id,		source_company_code,
                process_group_num,      oper_cur_code,
		org_id,			interbranch_flag )
	SELECT  journal_type,           @next_code,
		@str_msg + @jour_num,  @sys_date,
		@period_end_date,       0,
		0,                      0,
		0,                      0,
		0,                      " ",
		@next_batch_code,       @rec_type ,
		intercompany_flag,	@company_code,
		@gl_module,	  	@home_cur_code,
		journal_ctrl_num,	111, 			
		@user_id, 		" ",
                " ",                    @oper_cur_code,
		org_id,			interbranch_flag
	FROM    glrecur
	WHERE   journal_ctrl_num = @jour_num

	IF ( @@rowcount != 1 )
	BEGIN
		IF ( @tran_started = 1 )
		BEGIN
			ROLLBACK TRAN
			SELECT	@tran_started = 0
		END


		EXEC @result =	glputerr_sp 	@client_id, 
						@user_id, 	
						@E_CANT_INSERT_GLTRX,
						"glrec.SP",
						NULL,  		
						@jour_num, 	
						NULL,		
						NULL,		
						NULL		
		SELECT	@found_errors = 1

		



		UPDATE	glrecur
		SET	posted_flag = 0
		WHERE	journal_ctrl_num = @jour_num

		CONTINUE	
	END
	


        EXEC @result = CVO_Control..mccurate_sp 
		@period_end_date,	
		@nat_cur_code,		
		@home_cur_code,		
                @rate_type_home,        
		@rate OUTPUT,		
		0			

	IF ( @result != 0 )
	BEGIN
		IF ( @tran_started = 1 )
		BEGIN
			ROLLBACK TRAN
			SELECT @tran_started = 0
		END

		EXEC appgetstring_sp "STR_CANT_HOME_CURRENCY", @str_msg OUT

		SELECT	@err_msg = @str_msg
		EXEC status_sp	"GLREC",
			@proc_key, 
			@user_id, 
			@err_msg, 
			100, 
			@orig_flag, 
			0	
		RETURN @result
	END
        


        EXEC @result = CVO_Control..mccurate_sp 
		@period_end_date,	
		@nat_cur_code,		
                @oper_cur_code,         
                @rate_type_oper,        
                @rate_oper OUTPUT,      
		0			

	IF ( @result != 0 )
	BEGIN
		IF ( @tran_started = 1 )
		BEGIN
			ROLLBACK TRAN
			SELECT @tran_started = 0
		END

		EXEC appgetstring_sp "STR_CANT_OPER_CURRENCY", @str_msg OUT

		SELECT	@err_msg = @str_msg
		EXEC status_sp	"GLREC",
			@proc_key, 
			@user_id, 
			@err_msg, 
			100, 
			@orig_flag, 
			0	
		RETURN @result
        END

	EXEC @result = glrecdet_sp	@jour_num, 
					@period_end_date, 
					@period, 
					@track_bal_flag, 
					@perc_flag, 
					@recur_if_zero, 	
					@track_bal_amt, 
					@base_amt, 
					@next_code, 
					@company_id,		
					@jour_desc, 
					@nat_cur_code, 
					@rate, 
                                        @rate_oper,
                                        @rate_type_home,
                                        @rate_type_oper,
					@proc_key, 		
					@user_id, 
					@orig_flag

	



	IF ( @result != 0 )
	BEGIN
		IF ( @tran_started = 1 )
		BEGIN
			ROLLBACK TRAN
			SELECT @tran_started = 0
		END

		EXEC @result =	glputerr_sp 	@client_id, 
						@user_id, 	
						@E_INVALID_ACCTCODE,
						"glrec.SP",
						NULL, 		
						@jour_num, 	
						NULL,		
						NULL,		
						NULL		

		SELECT	@found_errors = 1

		



		UPDATE	glrecur
		SET	posted_flag = 0
		WHERE	journal_ctrl_num = @jour_num

		CONTINUE	
	END
	
	IF (@interbranch_flag=1)
		INSERT ibifc (	id,		date_entered,		date_applied,	controlling_org_id,	detail_org_id,
				amount,		currency_code,		tax_code,	state_flag,		trx_type,		
				link1,		link2,			username)
		SELECT		newid(), 	dateadd(day, @sys_date  - 693596, '01/01/1900'),		dateadd(day,@period_end_date-693596, '01/01/1900'), 	
											'',			'',
				0,		@home_cur_code,		'',		0,			111 , 			
				@next_code, '' ,	SYSTEM_USER

	

        




        UPDATE batchctl 
        SET    actual_number =
                     (SELECT count(batch_code)
                      FROM   gltrx
                      WHERE  batch_code = @next_batch_code), 
               actual_total = 0.0 
        WHERE  batch_ctrl_num = @next_batch_code
	
	UPDATE  glrecur
	SET     date_last_applied = @period_end_date,
		posted_flag = 0
	WHERE   journal_ctrl_num = @jour_num

	UPDATE  glrecdet
	SET     posted_flag = 0,
		date_applied = @period_end_date
	WHERE   journal_ctrl_num = @jour_num

	


	EXEC glicacct_sp	@next_code,
				@company_code, 
				0

	



	IF @period = @num_prd
	BEGIN
		EXEC @result = glrecend_sp	@jour_num, 
						@sys_date, 
						@period_end_date, 
						@year_end_type, 
						@proc_key, 
						@user_id, 
						@orig_flag, 
						@new_jour_num = @jour_num OUTPUT
		
		IF ( @result != 0 )
		BEGIN
			IF ( @tran_started = 1 )
			BEGIN
				ROLLBACK TRAN
				SELECT @tran_started = 0
			END

			SELECT	@found_errors = 1

			



			UPDATE	glrecur
			SET	posted_flag = 0
			WHERE	journal_ctrl_num = @jour_num

			CONTINUE	
		END

	END

	




	IF ( @tran_started = 1 )
	BEGIN
		COMMIT TRAN
		SELECT	@tran_started = 0
	END

	


	SELECT  @tot_trx_done = @tot_trx_done + 1
	SELECT  @perc_done = @tot_trx_done / @tot_trx * 100

	EXEC appgetstring_sp "STR_PROCESSING", @str_msg OUT
	
	EXEC status_sp "GLREC", @proc_key, @user_id, @str_msg, 
			@perc_done, @orig_flag, 0
END

IF ( @tran_started = 1 )
BEGIN
	COMMIT TRAN
	SELECT	@tran_started = 0
END

RETURN 0






/**/                                              
GO
GRANT EXECUTE ON  [dbo].[glrec_sp] TO [public]
GO
