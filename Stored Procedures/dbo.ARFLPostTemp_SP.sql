SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/* PVCS Revision or Version:Revision              
I:\vcs\AR\PROCS\arflpt.SPv - e7.2.2 : 1.2
              Confidential Information                  
   Limited Distribution of Authorized Persons Only      
   Created 1996 and Protected as Unpublished Work       
         Under the U.S. Copyright Act of 1976           
Copyright (c) 1996 Epicor Software Corporation, 1996  
                 All Rights Reserved                    
*/                                                











 



					 










































 






















































































































































































































































































CREATE PROC [dbo].[ARFLPostTemp_SP]	@batch_ctrl_num	varchar( 16 ),
				@process_ctrl_num	varchar( 16 ),
				@process_user_id	smallint,
				@journal_type		varchar( 8 ),
				@company_code		varchar( 8 ),
				@home_currency	varchar( 8 ),
				@oper_currency	varchar( 8 ),
				@charge_option	smallint,
				@date_applied		int,
				@debug_level		smallint = 0,
				@perf_level		smallint = 0	
AS






DECLARE
 @PERF_time_last datetime

SELECT @PERF_time_last = GETDATE()















									







DECLARE
 	@result		int


BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arflpt.sp" + ", line " + STR( 60, 5 ) + " -- ENTRY: "
	IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, "tmp/arflpt.sp", 61, "Entering ARFLPostTemp_SP", @PERF_time_last OUTPUT
	
		
	EXEC @result = ARFLApplyCharges_SP 		@batch_ctrl_num,
								@charge_option,
								@date_applied,
								@home_currency,
								@oper_currency,
								@process_user_id,
								@debug_level,
								@perf_level

	IF( @result != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arflpt.sp" + ", line " + STR( 77, 5 ) + " -- EXIT: "
		RETURN @result
	END
	
		
	EXEC @result = ARFLAssignControlNum_SP 		@batch_ctrl_num,
								@debug_level,
								@perf_level

	IF( @result != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arflpt.sp" + ", line " + STR( 90, 5 ) + " -- EXIT: "
		RETURN @result
	END

	
	EXEC @result = ARFLCreateRelatedRecs_SP 	@batch_ctrl_num,
							@process_user_id,
							@charge_option,
						 	@debug_level,
							@perf_level

	IF( @result != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arflpt.sp" + ", line " + STR( 105, 5 ) + " -- EXIT: "
		RETURN @result
	END
		
		
	EXEC @result = ARFLCreateGLTrans_SP	@batch_ctrl_num,
						 	@debug_level,
						 	@perf_level
	IF( @result != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arflpt.sp" + ", line " + STR( 117, 5 ) + " -- EXIT: "
		RETURN @result
	END

	
	EXEC @result = ARFLUpdateDependTrans_SP 	@batch_ctrl_num,
							@process_ctrl_num,
							@debug_level,
							@perf_level
	IF( @result != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arflpt.sp" + ", line " + STR( 130, 5 ) + " -- EXIT: "
		RETURN @result
	END
	
	
	EXEC @result = ARFLUpdateActivitySummary_SP	@batch_ctrl_num,
								@debug_level,
								@perf_level
	IF( @result != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arflpt.sp" + ", line " + STR( 142, 5 ) + " -- EXIT: "
		RETURN @result
	END
	
	IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, "tmp/arflpt.sp", 146, "Leaving ARFLPostTemp_SP", @PERF_time_last OUTPUT
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arflpt.sp" + ", line " + STR( 147, 5 ) + " -- EXIT: "
	RETURN 0
END
GO
GRANT EXECUTE ON  [dbo].[ARFLPostTemp_SP] TO [public]
GO
