SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/* PVCS Revision or Version:Revision              
I:\vcs\AR\PROCS\ariapt.SPv - e7.2.2 : 1.1
              Confidential Information                  
   Limited Distribution of Authorized Persons Only      
   Created 1996 and Protected as Unpublished Work       
         Under the U.S. Copyright Act of 1976           
Copyright (c) 1996 Epicor Software Corporation, 1996  
                 All Rights Reserved                    
*/                                                











 



					 










































 










































































































































































































































































 































































































































































































































































































































































































































































































































































































































































 




























CREATE PROC [dbo].[ARIAPostTemp_SP]	@batch_ctrl_num	varchar( 16 ),
					@process_ctrl_num	varchar( 16 ),
					@user_id 		smallint, 
					@debug_level		smallint,
					@perf_level		smallint
AS






DECLARE
 @PERF_time_last datetime

SELECT @PERF_time_last = GETDATE()















									







DECLARE
	@trx_num		varchar( 16 ), 
	@trx_type 		smallint, 
	@journal_ctrl_num 	varchar( 16 ),
	@cust_code 		varchar( 8 ),
	@amt_paid 		float,	
	@last_trx_ctrl 	varchar( 16 ), 
	@result 		int, 
	@min_trx_ctrl_num	varchar( 16)

IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, "tmp/ariapt.sp", 57, "Entering ARIAPostTemp_SP", @PERF_time_last OUTPUT

BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/ariapt.sp" + ", line " + STR( 60, 5 ) + " -- ENTRY: "

	
	EXEC @result = ARIACreateGLTrans_SP	@batch_ctrl_num,
							@journal_ctrl_num OUTPUT,
							@debug_level,
							@perf_level
	IF( @result != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/ariapt.sp" + ", line " + STR( 71, 5 ) + " -- EXIT: "
		RETURN 34563
	END

	
	EXEC @result = ARIAUpdateDependTrans_SP	@batch_ctrl_num,
							@debug_level,
							@perf_level
	IF( @result != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/ariapt.sp" + ", line " + STR( 83, 5 ) + " -- EXIT: "
		RETURN 34563
	END

	

	IF ( @debug_level > 3 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/ariapt.sp" + ", line " + STR( 91, 5 ) + " -- MSG: " + "Before Update activity and summary."
	EXEC @result = ARIASumActInsTmp_SP	@batch_ctrl_num,
						@perf_level,
						@debug_level
	IF( @result != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/ariapt.sp" + ", line " + STR( 97, 5 ) + " -- EXIT: "
		RETURN @result
	END
	IF ( @debug_level > 3 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/ariapt.sp" + ", line " + STR( 100, 5 ) + " -- MSG: " + "After Update activity and summary."
	
	
	EXEC @result = ARIAMoveUnpostedRecords_SP	@batch_ctrl_num,
							@journal_ctrl_num,
					 		@debug_level,
					 		@perf_level
	IF( @result != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/ariapt.sp" + ", line " + STR( 111, 5 ) + " -- EXIT: "
		RETURN @result
	END
	
	
	IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, "tmp/ariapt.sp", 116, "Leaving ARIAPostTemp_SP", @PERF_time_last OUTPUT
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/ariapt.sp" + ", line " + STR( 117, 5 ) + " -- EXIT: "
	RETURN 0 
END

GO
GRANT EXECUTE ON  [dbo].[ARIAPostTemp_SP] TO [public]
GO