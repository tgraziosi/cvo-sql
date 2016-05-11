SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/* PVCS Revision or Version:Revision              
I:\vcs\AP\PROCS\apvapt.SPv - e7.2.2 : 1.3
              Confidential Information                  
   Limited Distribution of Authorized Persons Only      
   Created 1996 and Protected as Unpublished Work       
         Under the U.S. Copyright Act of 1976           
Copyright (c) 1996 Epicor Software Corporation, 1996  
                 All Rights Reserved                    
*/                                                










 



					 










































 

















































































































































































































































































































































































































































































































































































 


























































































































































































































































































































































































































 





























CREATE PROC [dbo].[APVAPostTemp_sp] 
								@batch_ctrl_num varchar(16),
								@process_group_num 	varchar(16),
								@user_id				int, 
								@cm_exist 				smallint,
			 					@period_end 			int,
								@debug_level 			smallint = 0,
								@perf_level				smallint = 0
AS



DECLARE	@date_applied int,
		@result int,
		@journal_ctrl_num varchar(16)


IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/apvapt.sp" + ", line " + STR( 61, 5 ) + " -- ENTRY: "

SELECT @date_applied = date_applied
FROM batchctl
WHERE batch_ctrl_num = @batch_ctrl_num


EXEC @result = APVAUpdateExtendedAmounts_sp @debug_level

IF (@result != 0)
	 RETURN @result



EXEC @result = APVAProcessGLEntries_sp @process_group_num,
										@date_applied,
										@batch_ctrl_num,
										@user_id,
										@journal_ctrl_num OUTPUT,
										@debug_level

IF (@result != 0)
	 RETURN @result



EXEC @result = APVAInsertPostedRecords_sp 	@journal_ctrl_num,
											@date_applied,
											@debug_level
IF (@result != 0)
	 RETURN @result


EXEC @result = APVAUpdatePostedRecords_sp 	@debug_level

IF (@result != 0)
	 RETURN @result

EXEC @result = APVAVendorActSum_sp	@debug_level

IF @result != 0
	 RETURN @result


EXEC @result = APVADeleteInputTables_sp	@debug_level

IF @result != 0
	 RETURN @result


IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/apvapt.sp" + ", line " + STR( 111, 5 ) + " -- EXIT: "

RETURN 0
GO
GRANT EXECUTE ON  [dbo].[APVAPostTemp_sp] TO [public]
GO