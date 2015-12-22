SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/* PVCS Revision or Version:Revision              
I:\vcs\AR\PROCS\ariamp.SPv - e7.2.2 : 1.1
              Confidential Information                  
   Limited Distribution of Authorized Persons Only      
   Created 1996 and Protected as Unpublished Work       
         Under the U.S. Copyright Act of 1976           
Copyright (c) 1996 Epicor Software Corporation, 1996  
                 All Rights Reserved                    
*/                                                









 



					 










































 








































































































































































































































































































































































































































































































CREATE PROC [dbo].[ARIAModifyPersistant_SP]	@batch_ctrl_num	varchar( 16 ),
						@debug_level		smallint = 0,
						@perf_level		smallint = 0	
AS






DECLARE
 @PERF_time_last datetime

SELECT @PERF_time_last = GETDATE()















									







DECLARE
	@result	int

IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, "tmp/ariamp.sp", 35, "ARIAModifyPersistant_SP", @PERF_time_last OUTPUT

BEGIN
	
	EXEC @result = aractcus_sp	@batch_ctrl_num,
								@debug_level,
								@perf_level
	IF( @result != 0 OR @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/ariamp.sp" + ", line " + STR( 46, 5 ) + " -- EXIT: "
		RETURN @result
	END

	
	EXEC @result = aractprc_sp	@batch_ctrl_num,
								@debug_level,
								@perf_level
	IF( @result != 0 OR @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/ariamp.sp" + ", line " + STR( 58, 5 ) + " -- EXIT: "
		RETURN @result
	END

	
	EXEC @result = aractshp_sp	@batch_ctrl_num,
								@debug_level,
								@perf_level
	IF( @result != 0 OR @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/ariamp.sp" + ", line " + STR( 70, 5 ) + " -- EXIT: "
		RETURN @result
	END
	
	EXEC @result = aractslp_sp	@batch_ctrl_num,
								@debug_level,
								@perf_level
	IF( @result != 0 OR @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/ariamp.sp" + ", line " + STR( 81, 5 ) + " -- EXIT: "
		RETURN @result
	END

	
	EXEC @result = aractter_sp	@batch_ctrl_num,
								@debug_level,
								@perf_level
	IF( @result != 0 OR @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/ariamp.sp" + ", line " + STR( 93, 5 ) + " -- EXIT: "
		RETURN @result
	END

	
	EXEC @result = arinpcdt_sp	@batch_ctrl_num,
					@debug_level,
					@perf_level
	IF( @result != 0 OR @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/ariamp.sp" + ", line " + STR( 105, 5 ) + " -- EXIT: "
		RETURN @result
	END

	
	EXEC @result = arinpchg_sp	@batch_ctrl_num,
					@debug_level,
					@perf_level
	IF( @result != 0 OR @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/ariamp.sp" + ", line " + STR( 117, 5 ) + " -- EXIT: "
		RETURN @result
	END

	
	EXEC @result = artrx_sp	@batch_ctrl_num,
					@debug_level,
					@perf_level
	IF( @result != 0 OR @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/ariamp.sp" + ", line " + STR( 129, 5 ) + " -- EXIT: "
		RETURN @result
	END
	
	
	EXEC @result = artrxcdt_sp	@batch_ctrl_num,
					@debug_level,
					@perf_level
	IF( @result != 0 OR @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/ariamp.sp" + ", line " + STR( 141, 5 ) + " -- EXIT: "
		RETURN @result
	END

	
	EXEC @result = arsumcus_sp	@batch_ctrl_num,
								@debug_level,
								@perf_level
	IF( @result != 0 OR @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/ariamp.sp" + ", line " + STR( 153, 5 ) + " -- EXIT: "
		RETURN @result
	END
 
	
	EXEC @result = arsumprc_sp	@batch_ctrl_num,
								@debug_level,
								@perf_level
	IF( @result != 0 OR @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/ariamp.sp" + ", line " + STR( 165, 5 ) + " -- EXIT: "
		RETURN @result
	END
 
	
	EXEC @result = arsumshp_sp	@batch_ctrl_num,
								@debug_level,
								@perf_level
	IF( @result != 0 OR @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/ariamp.sp" + ", line " + STR( 177, 5 ) + " -- EXIT: "
		RETURN @result
	END

	
	EXEC @result = arsumslp_sp	@batch_ctrl_num,
								@debug_level,
								@perf_level
	IF( @result != 0 OR @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/ariamp.sp" + ", line " + STR( 189, 5 ) + " -- EXIT: "
		RETURN @result
	END

	
	EXEC @result = arsumter_sp	@batch_ctrl_num,
								@debug_level,
								@perf_level
	IF( @result != 0 OR @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/ariamp.sp" + ", line " + STR( 201, 5 ) + " -- EXIT: "
		RETURN @result
	END

	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/ariamp.sp" + ", line " + STR( 205, 5 ) + " -- EXIT: "
	RETURN 0
END
GO
GRANT EXECUTE ON  [dbo].[ARIAModifyPersistant_SP] TO [public]
GO
