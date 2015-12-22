SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

/* PVCS Revision or Version:Revision              
I:\vcs\CM\PROCS\cmmtpb2.SPv - e7.2.2 : 1.0
              Confidential Information                  
   Limited Distribution of Authorized Persons Only      
   Created 1996 and Protected as Unpublished Work       
         Under the U.S. Copyright Act of 1976           
Copyright (c) 1996 Epicor Software Corporation, 1996  
                 All Rights Reserved                    
*/                                                













 



					 










































 




























































































































































































































































 










































































































































































































































































































































































































CREATE PROCEDURE [dbo].[CMMTPostBatch2_sp] 

	@batch_ctrl_num	varchar(16),	
	@debug_level	smallint = 0
AS

DECLARE
 @result int,
 @rf_result int,
 @batch_proc_flag smallint,
	@process_group_num 	varchar(16),
	@period_end int,
	@gl_exist			smallint,
	@errbuf varchar(100),
	@client_id 			varchar(20),
	@user_id			int,
	@batch_type			smallint,
	@date_applied		int


BEGIN


IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/cmmtpb2.sp" + ", line " + STR( 40, 5 ) + " -- ENTRY: "

	SELECT @client_id = "CMPOSTING"




	SELECT	@process_group_num = p.process_ctrl_num,
			@user_id = p.process_user_id,
			@date_applied = b.date_applied,
			@batch_type = b.batch_type
	FROM	batchctl b, pcontrol_vw p
	WHERE	b.process_group_num = p.process_ctrl_num
	AND	b.batch_ctrl_num = @batch_ctrl_num
	


	SELECT	@batch_proc_flag = batch_proc_flag,
			@gl_exist = gl_flag
	FROM	cmco


	


 EXEC @rf_result = CMMTResetFlag_sp 
 								@batch_ctrl_num,
									@client_id,
									@user_id,
									@process_group_num,
									@batch_proc_flag,	
 @debug_level
 IF(( @rf_result != 0 ) AND (@rf_result != -2))
			RETURN @rf_result
 

	SELECT	@period_end = period_end_date
	FROM	glprd
	WHERE	@date_applied BETWEEN period_start_date AND period_end_date


 
 EXEC @result = CMMTPostTemp_sp @batch_ctrl_num, 
									@process_group_num,
								 @user_id,
									@period_end,
 @debug_level

 IF( @result != 0 )
			RETURN @result
 

 	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/cmmtpb2.sp" + ", line " + STR( 103, 5 ) + " -- EXIT: "
 RETURN @rf_result 
END
GO
GRANT EXECUTE ON  [dbo].[CMMTPostBatch2_sp] TO [public]
GO
