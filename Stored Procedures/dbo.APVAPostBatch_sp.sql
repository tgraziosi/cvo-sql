SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/* PVCS Revision or Version:Revision              
I:\vcs\AP\PROCS\apvapb.SPv - e7.2.2 : 1.5
              Confidential Information                  
   Limited Distribution of Authorized Persons Only      
   Created 1996 and Protected as Unpublished Work       
         Under the U.S. Copyright Act of 1976           
Copyright (c) 1996 Epicor Software Corporation, 1996  
                 All Rights Reserved                    
*/                                                










 



					 










































 

















































































































































































































































































































































































































































































































































































 























































































CREATE PROC [dbo].[APVAPostBatch_sp]
								@batch_ctrl_num varchar(16),
 @debug_level smallint = 0
AS

DECLARE @result int,
		@process_ctrl_num varchar(16)


BEGIN


IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/apvapb.sp" + ", line " + STR( 61, 5 ) + " -- ENTRY: "

	SELECT	@process_ctrl_num = p.process_ctrl_num
	FROM	batchctl b, pcontrol_vw p
	WHERE	b.process_group_num = p.process_ctrl_num
	AND	b.batch_ctrl_num = @batch_ctrl_num

	INSERT pbatch (	process_ctrl_num,
					batch_ctrl_num,
					start_number,
					start_total,
					end_number,
					end_total,
					start_time,
					end_time,
					flag
				 )
	VALUES (
				 @process_ctrl_num,
				 @batch_ctrl_num,
				 0,
				 0,
				 0,
				 0,
				 getdate(),
				 NULL,
				 0)

 
 EXEC @result = APVAInsertTempTable_sp @process_ctrl_num,
 										@batch_ctrl_num, 
 @debug_level

 IF( @result != 0 )
			RETURN @result

 
 EXEC @result = APVALockInsertDepend_sp @process_ctrl_num,
 @debug_level
 IF( @result != 0 )
			RETURN @result
	

 EXEC @result = APVAValidate_sp @debug_level
 IF( @result != 0 )
			RETURN @result

 	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/apvapb.sp" + ", line " + STR( 118, 5 ) + " -- EXIT: "
 RETURN 0 
END
GO
GRANT EXECUTE ON  [dbo].[APVAPostBatch_sp] TO [public]
GO
