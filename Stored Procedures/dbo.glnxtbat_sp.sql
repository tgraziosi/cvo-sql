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



















































































































  



					  

























































 











































































































































































































































































































                       


















































































































































































































































CREATE  PROCEDURE [dbo].[glnxtbat_sp]
		@module                 smallint,
		@source_batch           varchar(16),
		@batch_type             smallint,
		@user_name              varchar(30),
		@date_applied           int,
		@company_code           char(8),
		@next_batch             varchar(16) OUTPUT,
		@org_id			varchar(30)  


AS 
BEGIN
	DECLARE 

		@batch_on               smallint,    
		@batch_description      varchar(40),
		@doc_name               char(40),
		@jul_date               int,
		@jul_time               int,          
		@mask                   varchar(16), 
		@next_number            int,
		@result                 smallint,
		@tran_started           tinyint

	


	EXEC appdate_sp @jul_date output
	EXEC apptime_sp @jul_time output 

	


	SELECT  @batch_on = batch_proc_flag 
	FROM    glco

	
	IF ( @batch_on = 0 )
	BEGIN
		SELECT @next_batch = " "
		RETURN 0
	END

	


	IF ( @user_name IS NULL )
		RETURN  1046

	IF ( @@trancount = 0 )
	BEGIN
		BEGIN TRAN
		SELECT  @tran_started = 1
	END

	
	SELECT  @mask=batch_ctrl_num_mask, 
		@next_number=next_batch_ctrl_num
	FROM    glnumber WITH (HOLDLOCK)

	




	WHILE 1=1
	BEGIN
		


		UPDATE  glnumber 
		SET     next_batch_ctrl_num=@next_number+1

		
		EXEC    fmtctlnm_sp     @next_number, 
					@mask, 
					@next_batch     OUTPUT, 
					@result         OUTPUT

		IF ( @result != 0 )
		BEGIN
			IF ( @tran_started = 1 )
				ROLLBACK TRAN
			SELECT  @next_batch = " "
			return 1015
		END

		IF NOT EXISTS(  SELECT  1
				FROM    batchctl
				WHERE   batch_ctrl_num = @next_batch )
			BREAK

		SELECT  @next_number=next_batch_ctrl_num
		FROM    glnumber
	END
	





	SELECT  @batch_description = batch_description
	FROM    batchctl
	WHERE   batch_ctrl_num = @source_batch
	
	IF ( @batch_description IS NULL )
	BEGIN
		SELECT  @batch_description = "  "
	END


	IF ( @batch_type = 6010 ) 
	BEGIN
		


		IF ( @source_batch != "" )
		BEGIN
			SELECT  @doc_name = document_name
			FROM    batchctl
			WHERE   batch_ctrl_num = @source_batch

			IF ( @doc_name IS NULL )
			BEGIN
				EXEC    @result = glgetstr_sp   2,
								@doc_name OUTPUT
			END
		END
		
		ELSE    
		BEGIN
			EXEC    @result = glgetstr_sp   3,
							@doc_name OUTPUT
		END
	END

	ELSE IF ( @batch_type = 6020 ) 
	BEGIN
		EXEC    @result = glgetstr_sp   4,
						@doc_name OUTPUT
	END

	ELSE IF ( @batch_type = 6030 ) 
	BEGIN
		EXEC    @result = glgetstr_sp   5,
						@doc_name OUTPUT
	END
	






	

	INSERT batchctl (       batch_ctrl_num, 
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

	VALUES (                @next_batch, 
				@batch_description, 
				@jul_date, 
				@jul_time, 
				0, 
				0, 
				0, 
				0.0, 
				0, 
				0.0, 
				6010, 
				@doc_name,
				0, 
				0, 
				0, 
				0, 
				0, 
				@date_applied, 
				0, 
				0, 
				@user_name, 
				" ", 
				" ", 
				@company_code,
				@org_id ) 
	IF ( @@error != 0 )
		goto rollback_trx


	IF ( @tran_started = 1 )
		COMMIT TRAN

	RETURN 0

	rollback_trx:
	IF ( @tran_started = 1 )
		ROLLBACK TRAN

	RETURN  1015

	


END
/**/                                              
GO
GRANT EXECUTE ON  [dbo].[glnxtbat_sp] TO [public]
GO
