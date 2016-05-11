SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/* PVCS Revision or Version:Revision              
I:\vcs\AP\PROCS\apvoup.SPv - e7.2.2 : 1.4.1.0
              Confidential Information                  
   Limited Distribution of Authorized Persons Only      
   Created 1996 and Protected as Unpublished Work       
         Under the U.S. Copyright Act of 1976           
Copyright (c) 1996 Epicor Software Corporation, 1996  
                 All Rights Reserved                    
*/                                                










 



					 










































 

















































































































































































































































































































































































































































































































































































 























































































CREATE PROC [dbo].[APVOUpdatePersistant_sp]
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

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/apvoup.sp" + ", line " + STR( 59, 5 ) + " -- ENTRY: "



	
	SELECT	@posted_user = user_name
	FROM	glusers_vw
	WHERE	@user_id = user_id


	

	EXEC @result = APVOPostStub_sp 	@batch_ctrl_num, @process_group_num, 
					@posted_user, @user_id, @debug_level

	IF (@result != 0)
		RETURN @result
	

	

	EXEC @result = APVOModifyPersistant_sp	@batch_ctrl_num,
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

	EXEC @result = appysav_sp @user_id

	IF( @result != 0 )
		RETURN @result

	EXEC @result = apvosav_sp @user_id, NULL, @debug_level, @batch_ctrl_num

	IF( @result != 0 )
		RETURN @result


	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/apvoup.sp" + ", line " + STR( 116, 5 ) + " -- EXIT: "
	RETURN 0
END
GO
GRANT EXECUTE ON  [dbo].[APVOUpdatePersistant_sp] TO [public]
GO