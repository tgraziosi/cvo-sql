SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/* PVCS Revision or Version:Revision              
I:\vcs\AP\PROCS\apvaup.SPv - e7.2.2 : 1.2
              Confidential Information                  
   Limited Distribution of Authorized Persons Only      
   Created 1996 and Protected as Unpublished Work       
         Under the U.S. Copyright Act of 1976           
Copyright (c) 1996 Epicor Software Corporation, 1996  
                 All Rights Reserved                    
*/                                                










 



					 










































 

















































































































































































































































































































































































































































































































































































 























































































CREATE PROC [dbo].[APVAUpdatePersistant_sp]
											@batch_ctrl_num		varchar(16),
											@process_group_num 	varchar(16),
											@client_id 			varchar(20),
											@user_id			int, 
											@debug_level		smallint = 0
AS

DECLARE
	@errbuf				varchar(100),
	@company_code 			varchar(8),
	@he_result			int,
	@result				int,
	@posted_user			varchar(30)



BEGIN

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/apvaup.sp" + ", line " + STR( 58, 5 ) + " -- ENTRY: "


	
	SELECT	@posted_user = user_name
	FROM	glusers_vw
	WHERE	@user_id = user_id


	

	EXEC @result = APVAPostStub_sp 	@batch_ctrl_num, @process_group_num, 
					@posted_user, @user_id, @debug_level

	IF (@result != 0)
		RETURN @result
	

	

	EXEC @result = APVAModifyPersistant_sp	@batch_ctrl_num,
											@client_id,
											@user_id,
											@debug_level
	IF( @result != 0 )
			RETURN @result
	

	SELECT @company_code = company_code from glco 

	EXEC @result = gltrxsav_sp @process_group_num,
								@company_code
	IF( @result != 0 )
		RETURN -1

	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/apvaup.sp" + ", line " + STR( 102, 5 ) + " -- EXIT: "
	RETURN 0
END
GO
GRANT EXECUTE ON  [dbo].[APVAUpdatePersistant_sp] TO [public]
GO