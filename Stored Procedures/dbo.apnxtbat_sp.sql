SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/*                                                      
               Confidential Information                  
    Limited Distribution of Authorized Persons Only       
    Created 2008 and Protected as Unpublished Work       
          Under the U.S. Copyright Act of 1976            
 Copyright (c) 2008 Epicor Software Corporation, 2008    
                  All Rights Reserved                    
*/                                                



































































  



					  

























































 














































































































































































































































































































































































































































































































































































































































































































                       









































































CREATE  PROCEDURE [dbo].[apnxtbat_sp]
	        @module 		smallint,
		@source_batch	varchar(16),
	        @batch_type		smallint,
		@user_id        smallint,
        	@date_applied	int,
		@company_code	char(8),
	        @next_batch		varchar(16) OUTPUT,
		@batch_description varchar(30) = NULL,
		@org_id		   varchar(30) = NULL  


AS DECLARE 

		@doc_name		char(30),
		@jul_date		int,
        @jul_time		int,	      
        @mask			varchar(16), 
		@next_number	int,
		@result			smallint,
		@tran_started	tinyint,
		@completed_user_name		varchar(30),
		@start_user_name		varchar(30),
		@str_msg			varchar(255)




EXEC appdate_sp @jul_date output
EXEC apptime_sp @jul_time output 











SELECT @start_user_name=user_name
FROM ewusers_vw
WHERE user_id = @user_id

SELECT @completed_user_name = completed_user
FROM	batchctl
WHERE	batch_ctrl_num = @source_batch


IF @org_id is null AND (@batch_type = 4065 OR @batch_type = 4010)
BEGIN
	IF OBJECT_ID('tempdb..#apinpchg') IS NOT NULL 
		SELECT @org_id = org_id from #apinpchg where batch_code = @source_batch	
END

IF @next_batch IS NULL
    BEGIN
		
		SELECT	@mask=batch_ctrl_num_mask
		FROM	apnumber

		IF ( @@trancount = 0 )
			BEGIN
				BEGIN TRAN
				SELECT	@tran_started = 1
			END

		




		WHILE 1=1
			BEGIN
			


			UPDATE	apnumber 
			SET	next_batch_ctrl_num=next_batch_ctrl_num+1

			
			SELECT	@next_number=next_batch_ctrl_num-1
			FROM	apnumber
	
			
			EXEC	fmtctlnm_sp	@next_number, 
						@mask, 
						@next_batch	OUTPUT, 
						@result		OUTPUT

			IF ( @result != 0 )
			BEGIN
				IF ( @tran_started = 1 )
					ROLLBACK TRAN
				SELECT	@next_batch = " "
				return -1
			END

			IF NOT EXISTS(	SELECT	1
				     	FROM 	batchctl
				     	WHERE	batch_ctrl_num = @next_batch )
			BREAK

			SELECT	@next_number=next_batch_ctrl_num
			FROM	apnumber
		END

	END

ELSE

    IF EXISTS ( SELECT 1 
	            FROM batchctl
				WHERE batch_ctrl_num = @next_batch)

		  RETURN 0















EXEC appgetstring_sp "STR_STD_TRANS", @str_msg OUT

SELECT	@batch_description = ISNULL(@batch_description, @str_msg)


	


		SELECT	@doc_name = @str_msg

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

	VALUES ( 	@next_batch, 
				@batch_description, 
				@jul_date, 
				@jul_time, 
				0, 
				0, 
				0, 
				0.0, 
				0, 
				0.0, 
				@batch_type, 
				@doc_name,
		        0, 
				0, 
				0, 
				0, 
				0, 
				@date_applied, 
				0, 
				0, 
				ISNULL(@start_user_name,''), 
				ISNULL(@completed_user_name,''), 
				" ", 
				@company_code,
				@org_id ) 
	IF ( @@rowcount != 1 )
		goto rollback_trx



IF ( @tran_started = 1 )
	COMMIT TRAN

RETURN 0

rollback_trx:
IF ( @tran_started = 1 )
	ROLLBACK TRAN

RETURN	-1




/**/                                              
GO
GRANT EXECUTE ON  [dbo].[apnxtbat_sp] TO [public]
GO
