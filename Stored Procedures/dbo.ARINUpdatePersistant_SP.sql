SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/* PVCS Revision or Version:Revision              
I:\vcs\AR\PROCS\arinup.SPv - e7.2.2 : 1.7.1.0
              Confidential Information                  
   Limited Distribution of Authorized Persons Only      
   Created 1996 and Protected as Unpublished Work       
         Under the U.S. Copyright Act of 1976           
Copyright (c) 1996 Epicor Software Corporation, 1996  
                 All Rights Reserved                    
*/                                                









 



					 










































 








































































































































































































































































































































































































































































































CREATE PROC [dbo].[ARINUpdatePersistant_SP]			@batch_ctrl_num		varchar( 16 ),
											@process_ctrl_num	varchar( 16 ),
											@company_code		varchar( 8 ),
											@process_user_id	smallint,
											@debug_level		smallint = 0,
											@perf_level			smallint = 0	
AS






DECLARE
 @PERF_time_last datetime

SELECT @PERF_time_last = GETDATE()















									







DECLARE
	@result		int,
	@err_msg		varchar(100),
	@new_batch_code	varchar( 16 )

IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, "tmp/arinup.sp", 102, "Entering ARINUpdatePersistant_SP", @PERF_time_last OUTPUT

BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arinup.sp" + ", line " + STR( 105, 5 ) + " -- ENTRY: "
		
	
	EXEC @result = ARINModifyPersistant_SP	@batch_ctrl_num,
											@debug_level,
											@perf_level
	IF( @result != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arinup.sp" + ", line " + STR( 116, 5 ) + " -- EXIT: "
		RETURN 34563
	END

	
	EXEC @result = arpysav_sp	@company_code,
								@process_user_id
	IF( @result != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arinup.sp" + ", line " + STR( 127, 5 ) + " -- EXIT: "
		RETURN 34563
	END

	
	EXEC @result = arinsav_sp	@process_user_id, @new_batch_code OUTPUT
	IF( @result != 0 )
 	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arinup.sp" + ", line " + STR( 137, 5 ) + " -- EXIT: "
		RETURN 34563
	END

	
	IF EXISTS (SELECT * FROM batchctl where batch_ctrl_num = @batch_ctrl_num and
			hold_flag = 0)
	BEGIN
		
		EXEC @result = batupdst_sp	@batch_ctrl_num,
									1
		IF( @result != 0 )
		BEGIN
			IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arinup.sp" + ", line " + STR( 152, 5 ) + " -- EXIT: "
			RETURN 34563
		END
	END

	
	IF EXISTS( SELECT * FROM arco WHERE iv_flag = 0 )
	BEGIN
		
		EXEC @result = gltrxsav_sp	@process_ctrl_num,
									@company_code
		IF( @result != 0 )
		BEGIN
			IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arinup.sp" + ", line " + STR( 173, 5 ) + " -- EXIT: "
			RETURN 34563
		END
	END

	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arinup.sp" + ", line " + STR( 178, 5 ) + " -- EXIT: "					
	IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, "tmp/arinup.sp", 179, "Leaving ARINUpdatePersistant_SP", @PERF_time_last OUTPUT
	RETURN 0
END
GO
GRANT EXECUTE ON  [dbo].[ARINUpdatePersistant_SP] TO [public]
GO
