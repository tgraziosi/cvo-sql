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

































































  



					  

























































 

















































































































































































































































































































































































































































































































































































































































































































CREATE  PROCEDURE [dbo].[arnxtbat_sp]	@module					smallint,
								@source_batch			varchar(16),
								@batch_type				smallint,
								@user_id				smallint,
								@date_applied			int,
								@company_code			char(8),
								@next_batch				varchar(16) OUTPUT,
								@debug_level	smallint = 0,
				 				@org_id		varchar(30)   


AS DECLARE 
		@batch_description      varchar(30),
		@doc_name               char(30),
		@jul_date               int,
		@jul_time               int,          
		@mask                   varchar(16), 
		@next_number            int,
		@result                 smallint,
		@tran_started           tinyint,
		@user_name              varchar(30)


IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arnxtbat.cpp" + ", line " + STR( 69, 5 ) + " -- ENTRY: "




EXEC appdate_sp @jul_date output
EXEC apptime_sp @jul_time output 











SELECT @user_name=user_name
FROM ewusers_vw
WHERE user_id = @user_id




IF ( @@trancount = 0 )
BEGIN
	IF ( @debug_level > 2 ) SELECT CONVERT(char,getdate(),109) + "  " + "arnxtbat.cpp" + ", line " + STR( 96, 5 ) + " -- MSG: " + "Beginning Transaction"
	BEGIN TRAN
	SELECT  @tran_started = 1
END






WHILE 1=1
BEGIN
	



	EXEC @result = ARGetNextControl_SP	2100,
										@next_batch OUTPUT,
										@next_number OUTPUT

	IF ( @result != 0 )
	BEGIN
		IF ( @tran_started = 1 )
		BEGIN
			IF ( @debug_level > 2 ) SELECT CONVERT(char,getdate(),109) + "  " + "arnxtbat.cpp" + ", line " + STR( 120, 5 ) + " -- MSG: " + "Rolling Back transaction"
			ROLLBACK TRAN
		END
		SELECT  @next_batch = " "
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arnxtbat.cpp" + ", line " + STR( 124, 5 ) + " -- EXIT: "
		RETURN 32500
	END

	IF NOT EXISTS(  SELECT  1
			FROM    batchctl
			WHERE   batch_ctrl_num = @next_batch )
	BREAK

END







SELECT  @batch_description = batch_description
FROM    batchctl
WHERE   process_group_num = @source_batch

EXEC appgetstring_sp 'STR_STD_TRANS', @doc_name  OUT

SELECT  @batch_description = ISNULL(@batch_description, @doc_name)
















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
VALUES (	@next_batch, 
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
			@user_name, 
			" ", 
			" ", 
			@company_code,
			@org_id )  

	IF ( @@rowcount != 1 )
		goto rollback_trx



IF ( @tran_started = 1 )
BEGIN
	IF ( @debug_level > 2 ) SELECT CONVERT(char,getdate(),109) + "  " + "arnxtbat.cpp" + ", line " + STR( 222, 5 ) + " -- MSG: " + "Commiting Transaction"
	COMMIT TRAN
END

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arnxtbat.cpp" + ", line " + STR( 226, 5 ) + " -- EXIT: "	
RETURN 0

rollback_trx:
IF ( @tran_started = 1 )
BEGIN
	IF ( @debug_level > 2 ) SELECT CONVERT(char,getdate(),109) + "  " + "arnxtbat.cpp" + ", line " + STR( 232, 5 ) + " -- MSG: " + "Rolling Back transaction"
	ROLLBACK TRAN
END

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arnxtbat.cpp" + ", line " + STR( 236, 5 ) + " -- EXIT: "	
RETURN  32500




/**/                                              
GO
GRANT EXECUTE ON  [dbo].[arnxtbat_sp] TO [public]
GO
