SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

/*                                                      
               Confidential Information                  
    Limited Distribution of Authorized Persons Only       
    Created 2001 and Protected as Unpublished Work       
          Under the U.S. Copyright Act of 1976            
 Copyright (c) 2001 Epicor Software Corporation, 2001    
                  All Rights Reserved                    
*/                                                




















































































































  



					  

























































 











































































































































































































































































































                       


































































































































































































































































































































































































































































































































































































































CREATE  PROCEDURE	[dbo].[gltrxbat_sp]
			@batch_code    	varchar(16) OUTPUT,
			@batch_source  	varchar(16),
			@batch_type    	smallint,
			@batch_user_id 	smallint,
			@batch_date    	int,
			@home_company  	varchar(8),
			@org_id		varchar(30) = NULL 
AS

BEGIN
	
	DECLARE 
		@batch_description	varchar(40),
		@doc_name		char(40),
		@jul_date		int,
        	@jul_time		int,	      
        	@mask			varchar(16), 
		@next_number		int,
		@result			smallint,
		@tran_started		tinyint,
		@user_name		varchar(30)

	


	EXEC appdate_sp @jul_date output
	EXEC apptime_sp @jul_time output 

	


	SELECT	@user_name = user_name
	FROM	glusers_vw
	WHERE	user_id = @batch_user_id

	IF ( @user_name IS NULL )
		RETURN	1028
	


	IF NOT EXISTS(	SELECT	*
			FROM	glprd
			WHERE	@batch_date 
			BETWEEN period_start_date 
			AND period_end_date )
		RETURN	1023
	


	IF ( @batch_type NOT IN (	6010,
			 		6020,
			 		6030 ) )
		RETURN 1064
	


	IF NOT EXISTS(	SELECT	*
			FROM	glcomp_vw
			WHERE	company_code = @home_company )
		RETURN	1005

	IF ( @@trancount = 0 )
	BEGIN
		BEGIN TRAN
		SELECT	@tran_started = 1
	END

	
	SELECT	@mask=batch_ctrl_num_mask, 
		@next_number=next_batch_ctrl_num
	FROM	glnumber WITH(HOLDLOCK)

	




	WHILE 1=1
	BEGIN
		


		UPDATE	glnumber 
		SET	next_batch_ctrl_num=@next_number+1

		
		EXEC	fmtctlnm_sp	@next_number, 
					@mask, 
					@batch_code	OUTPUT, 
					@result		OUTPUT

		IF ( @result != 0 )
		BEGIN
			IF ( @tran_started = 1 )
				ROLLBACK TRAN
			SELECT	@batch_code = " "
			RETURN	1015
		END

		IF NOT EXISTS(	SELECT	1
			     	FROM 	batchctl
			     	WHERE	batch_ctrl_num = @batch_code )
			BREAK

		SELECT	@next_number=next_batch_ctrl_num
		FROM	glnumber
	END
	





	SELECT	@batch_description = batch_description
	FROM	batchctl
	WHERE	batch_ctrl_num = @batch_source
	
	IF ( @batch_description IS NULL )
	BEGIN
		SELECT	@batch_description = "  "
	END


	IF ( @batch_type = 6010 ) 
	BEGIN
		


		IF ( @batch_source != "" )
		BEGIN
			SELECT	@doc_name = document_name
			FROM	batchctl
		        WHERE   batch_ctrl_num = @batch_source

			IF ( @doc_name IS NULL )
			BEGIN
				EXEC	@result = glgetstr_sp	2,
								@doc_name OUTPUT
			END
		END
		
		ELSE	
		BEGIN
			EXEC	@result = glgetstr_sp	3,
							@doc_name OUTPUT
		END
	END

	ELSE IF ( @batch_type = 6020 ) 
	BEGIN
		EXEC	@result = glgetstr_sp	4,
						@doc_name OUTPUT
	END

	ELSE IF ( @batch_type = 6030 ) 
	BEGIN
		EXEC	@result = glgetstr_sp	5,
						@doc_name OUTPUT
	END
	
	IF ( @result != 0 )
		GOTO rollback_trx

	INSERT batchctl (	batch_ctrl_num, 
				batch_description,
				start_date,
				start_time,
				completed_date,
				completed_time,
				control_number,
				control_total,
				actual_number,
				actual_total,
				batch_type,
				document_name,
				hold_flag,
				posted_flag,
				void_flag,
				selected_flag,
				number_held,
				date_applied,
				date_posted,
				time_posted,
				start_user,
				completed_user,
				posted_user,
				company_code,
				org_id ) 

	VALUES ( 		@batch_code, 
				@batch_description, 
				@jul_date, 
				@jul_time, 
				@jul_date, 
				@jul_time, 
				0, 
				0.0, 
				0, 
				0.0, 
				@batch_type, 
				@doc_name,
		                0, 
				-1, 
				0, 
				0, 
				0, 
				@batch_date, 
				0, 
				0, 
				@user_name, 
				@user_name, 
				" ", 
				@home_company,
				@org_id ) 
	IF ( @@error != 0 )
	BEGIN
		SELECT	@result = 1039
		goto rollback_trx
	END


	IF ( @tran_started = 1 )
		COMMIT TRAN

	RETURN 0

	rollback_trx:
	IF ( @tran_started = 1 )
		ROLLBACK TRAN

	RETURN	@result

	


END

/**/                                              
GO
GRANT EXECUTE ON  [dbo].[gltrxbat_sp] TO [public]
GO
