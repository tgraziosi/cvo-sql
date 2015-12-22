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
























































































CREATE	PROCEDURE [dbo].[glrea_sp] 	@posted_flag	int,
				@sys_date 	int,
				@from_date 	int,
				@thru_date 	int,
				@company_code 	varchar(8),
				@proc_key 	smallint, 	
				@user_id 	smallint,
				@orig_flag 	smallint,
				@debug 		smallint     = 0

AS 
DECLARE 
	@min_journal_ctrl_num varchar(16),							
	@client_id		varchar(20),
	@cur_date      		int, 		
	@description	 	varchar(40),
	@E_NO_VALID_REA_TRX	int,
	@E_INVALID_NATCODE	int,
	@E_INVALID_REA_DATES	int,
	@E_AUTO_GEN_OK		int,
	@E_AUTO_GEN_OK_ERR	int,
	@err_msg		varchar(80),
	@from_date_fmt		varchar(24),
	@jour_num 	 	varchar(16),	
	@nat_cur_code	 	varchar(8),
	@perc_done	 	float,	
	@result			int,
	@thru_date_fmt		varchar(24),
	@tot_count 	 	int,	       
	@tot_cr 	 	float, 		
	@tot_trx 	 	float,		
	@tot_trx_done 		float,	       
	@ret_tmp_error		smallint,
	@set_error		smallint,
        @user_name              varchar(30)  ,
        @oper_cur_code          varchar(8),
	@str_msg		varchar(255)

IF @debug >= 1
	SELECT "________________________ Entering GLREA.SP ________________________"	 " "


IF @debug >= 3
	SELECT 	@posted_flag		"--- Post flag",
		@sys_date		"Sys date",
		@from_date		"From date",
		@thru_date		"Thru date",
		@company_code		"Company"




SELECT	@E_INVALID_NATCODE = e_code
FROM	glerrdef
WHERE	e_sdesc = "E_INVALID_NATCODE"

SELECT	@E_INVALID_REA_DATES = e_code
FROM	glerrdef
WHERE	e_sdesc = "E_INVALID_REA_DATES"

SELECT	@E_NO_VALID_REA_TRX = e_code
FROM	glerrdef
WHERE	e_sdesc = "E_NO_VALID_REA_TRX"

SELECT	@E_AUTO_GEN_OK = e_code
FROM	glerrdef
WHERE	e_sdesc = "E_AUTO_GEN_OK"

SELECT	@E_AUTO_GEN_OK_ERR = e_code
FROM	glerrdef
WHERE	e_sdesc = "E_AUTO_GEN_OK_ERR"





SELECT	@nat_cur_code = NULL,
        @oper_cur_code = NULL,
	@client_id = "POSTTRX"

SELECT  @nat_cur_code = home_currency,
        @oper_cur_code = oper_currency
FROM	glco




IF ( @nat_cur_code IS NULL )
BEGIN
	EXEC	glgetmsg_sp	@E_INVALID_NATCODE,
				@err_msg	OUTPUT

	EXEC status_sp	"GLREA",
			@proc_key, 
			@user_id, 
			@err_msg, 
			0,	
			@orig_flag, 
			1	

	UPDATE	glreall			
	SET 	posted_flag = 0	
	WHERE	posted_flag = @posted_flag	

	EXEC @result =	glputerr_sp 	@client_id, 
					@user_id, 	
					@E_INVALID_NATCODE,
					"GLREA.SP",
					NULL,  		
					NULL,		
					NULL,		
					NULL,		
					NULL		

	IF @debug >= 3
		SELECT "--- " + @err_msg

	RETURN @E_INVALID_NATCODE
END
		



SELECT  @user_name = user_name 
FROM    CVO_Control..smusers 
WHERE   user_id = @user_id





SELECT  @cur_date = NULL

SELECT  @cur_date = period_end_date
FROM    glprd
WHERE   @from_date BETWEEN period_start_date AND period_end_date

IF ( @cur_date IS NULL )
BEGIN
	EXEC	glgetmsg_sp	@E_INVALID_REA_DATES,
				@err_msg OUTPUT

	EXEC	status_sp "GLREA", @proc_key, @user_id, 
			@err_msg, 0, @orig_flag, 1

	




	UPDATE	glreall
	SET 	posted_flag = 0
	WHERE	posted_flag = @posted_flag

	EXEC	glfmtdt_sp	@from_date,
				@from_date_fmt OUTPUT

	EXEC	glfmtdt_sp	@thru_date,
				@thru_date_fmt OUTPUT

	EXEC @result =	glputerr_sp 	@client_id, 
					@user_id, 	
					@E_INVALID_REA_DATES,
					"GLREA.SP",
					NULL,  		
					@from_date_fmt,	
					@thru_date_fmt,	
					NULL,		
					NULL		

	IF @debug >= 3
		SELECT "--- " + @err_msg

	RETURN @E_INVALID_REA_DATES
END




SELECT  @from_date = @cur_date 

SELECT	@cur_date = NULL

SELECT  @cur_date = period_end_date
FROM    glprd
WHERE   @thru_date BETWEEN period_start_date AND period_end_date

IF ( @cur_date IS NULL )
BEGIN
	EXEC	glgetmsg_sp	@E_INVALID_REA_DATES,
				@err_msg OUTPUT

	EXEC 	status_sp "GLREA", @proc_key, @user_id, 
			@err_msg, 0, @orig_flag, 1

	




	UPDATE	glreall
	SET 	posted_flag = 0
	WHERE	posted_flag = @posted_flag

	EXEC	glfmtdt_sp	@from_date,
				@from_date_fmt OUTPUT

	EXEC	glfmtdt_sp	@thru_date,
				@thru_date_fmt OUTPUT

	EXEC @result =	glputerr_sp 	@client_id, 
					@user_id, 	
					@E_INVALID_REA_DATES,
					"GLREA.SP",
					NULL,  		
					@from_date_fmt,	
					@thru_date_fmt,	
					NULL,		
					NULL		

	IF @debug >= 3
		SELECT "--- " + @err_msg

	RETURN @E_INVALID_REA_DATES
END

SELECT	@thru_date = @cur_date




SELECT	@tot_count = NULL

SELECT	@tot_count = COUNT( date_last_applied )
FROM	glreall
WHERE	posted_flag = @posted_flag
AND	date_last_applied < @thru_date

IF (( @tot_count IS NULL ) OR ( @tot_count = 0 ))
BEGIN
	UPDATE	glreall			
	SET 	posted_flag = 0	
	WHERE	posted_flag = @posted_flag	

	EXEC	glgetmsg_sp	@E_NO_VALID_REA_TRX,
				@err_msg OUTPUT

	EXEC status_sp	"GLREA", @proc_key, @user_id, 
			@err_msg, 100, @orig_flag, 0
	IF @debug >= 1
		SELECT "- ", @err_msg
	RETURN 0
END

SELECT	@tot_trx = @tot_count





EXEC appgetstring_sp "STR_PROCESSING", @str_msg OUT

EXEC status_sp "GLREA", @proc_key, @user_id, @str_msg, 
			0, @orig_flag, 0
IF @debug >= 1
	SELECT "- Processing" 

SELECT	@tot_trx_done = 0.0, @jour_num = ''

SELECT  @ret_tmp_error = 0, @set_error = 0

WHILE ( 1 = 1 )
BEGIN
	


	SELECT	@jour_num = NULL

	SELECT	@min_journal_ctrl_num = MIN(journal_ctrl_num)		
	FROM	glreall												
	WHERE	posted_flag = @posted_flag							

	SELECT	@jour_num = journal_ctrl_num,
		@description = journal_description
	FROM	glreall
	WHERE	posted_flag = @posted_flag
	  AND	journal_ctrl_num = @min_journal_ctrl_num			
	
	


	IF ( @jour_num IS NULL )
	BEGIN

		IF (@set_error = 1)
			EXEC	glgetmsg_sp	@E_AUTO_GEN_OK_ERR,
						@err_msg OUTPUT
		ELSE
			EXEC	glgetmsg_sp	@E_AUTO_GEN_OK,
						@err_msg OUTPUT

		EXEC status_sp "GLREA", @proc_key, @user_id, 
				@err_msg, 100, @orig_flag, 0
		IF @debug >= 1
			SELECT "- ", @err_msg
		RETURN 0 
	END

	IF @debug >= 2
		SELECT "-- Next journal: " + @jour_num
	







	EXEC	@result = glreatrx_sp	@posted_flag,
					@jour_num,
					@description,
					@sys_date,
					@cur_date,
					@company_code,
					@nat_cur_code,
                                        @oper_cur_code,
					@proc_key, 	
					@user_id,
					@user_name,
			  		@orig_flag,
					@ret_tmp_error OUTPUT,
					@debug

	IF ( @result != 0 )
	BEGIN

		EXEC @result =	glputerr_sp 	@client_id, 
						@user_id, 	
						@result,
						"glrea.sp",
						NULL,  		
						@jour_num, 	
						NULL,		
						NULL,		
						NULL		

		IF @debug >= 3
			SELECT "--- Error calling GLREATRX"

		SELECT	@set_error = 1
		



		UPDATE	glreall
		SET	posted_flag = 0
		WHERE	journal_ctrl_num = @jour_num

	END

	


	IF (@ret_tmp_error = 1)
 	    SELECT @set_error = 1

	


	SELECT	@tot_trx_done = @tot_trx_done + 1
	SELECT	@perc_done = @tot_trx_done / @tot_trx * 100

	EXEC status_sp "GLREA", @proc_key, @user_id, @str_msg,
			@perc_done, @orig_flag, 0

	IF @debug >= 3
		SELECT "--- " + RTRIM(CONVERT(varchar(3), ROUND(@perc_done,0))) + "% complete"
END
RETURN 0

/**/                                              
GO
GRANT EXECUTE ON  [dbo].[glrea_sp] TO [public]
GO
