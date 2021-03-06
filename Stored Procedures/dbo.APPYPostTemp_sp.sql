SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/*                                                      
               Confidential Information                  
    Limited Distribution of Authorized Persons Only       
    Created 2001 and Protected as Unpublished Work       
          Under the U.S. Copyright Act of 1976            
 Copyright (c) 2001 Epicor Software Corporation, 2001    
                  All Rights Reserved                    
*/                                                



































































  



					  

























































 














































































































































































































































































































































































































































































































































































































































































































                       




































































































































































































































































































































































































































































































































                       




























































































































































































































































































































































































































































                       











































CREATE PROC [dbo].[APPYPostTemp_sp]
								@batch_ctrl_num varchar(16),
								@process_group_num 	varchar(16),
								@user_id				int,  
								@cm_exist 				smallint,
								@period_end 			int,
								@debug_level 			smallint = 0
AS





DECLARE	

	    @date_applied int,
		@result  int,
		@journal_ctrl_num varchar(16)



IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "appypt.cpp" + ", line " + STR( 71, 5 ) + " -- ENTRY: "




SELECT @date_applied = date_applied
FROM batchctl
WHERE batch_ctrl_num = @batch_ctrl_num



EXEC @result = APPYNumberBankGenerated_sp  @debug_level
IF (@result != 0)
	        RETURN @result






EXEC @result = APPYProcessGLEntries_sp  @process_group_num,
										@date_applied,
										@batch_ctrl_num,
										@user_id,
										@journal_ctrl_num OUTPUT,
										@debug_level

IF (@result != 0)
	        RETURN @result


IF (@cm_exist = 1)
   BEGIN
	EXEC @result = APPYProcessCMEntries_sp @date_applied, @debug_level
	IF (@result != 0)
	        RETURN @result


   END

EXEC @result = APPYCalculatePaymentDist_sp 	@debug_level
IF (@result != 0)
	        RETURN @result



EXEC @result = APPYUpdatePostedRecords_sp	@date_applied,
											@debug_level
IF (@result != 0)
	        RETURN @result


EXEC @result = APPYInsertPostedRecords_sp 	@journal_ctrl_num,
											@date_applied,
											@debug_level
IF (@result != 0)
	        RETURN @result



EXEC @result = APPYVendorActSum_sp	@debug_level

IF @result != 0
	    RETURN @result


EXEC @result = APPYDeleteInputTables_sp	@debug_level

IF @result != 0
	    RETURN @result





IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "appypt.cpp" + ", line " + STR( 146, 5 ) + " -- EXIT: "

RETURN 0
GO
GRANT EXECUTE ON  [dbo].[APPYPostTemp_sp] TO [public]
GO
