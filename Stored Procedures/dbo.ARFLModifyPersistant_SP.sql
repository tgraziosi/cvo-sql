SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/* PVCS Revision or Version:Revision              
I:\vcs\AR\PROCS\arflmp.SPv - e7.2.2 : 1.1
              Confidential Information                  
   Limited Distribution of Authorized Persons Only      
   Created 1996 and Protected as Unpublished Work       
         Under the U.S. Copyright Act of 1976           
Copyright (c) 1996 Epicor Software Corporation, 1996  
                 All Rights Reserved                    
*/                                                









 



					 










































 








































































































































































































































































































































































































































































































CREATE PROC [dbo].[ARFLModifyPersistant_SP]			@batch_ctrl_num		varchar( 16 ),
											@debug_level		smallint = 0,
											@perf_level			smallint = 0	
AS






DECLARE
 @PERF_time_last datetime

SELECT @PERF_time_last = GETDATE()















									







DECLARE
	@result		int

IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, "tmp/arflmp.sp", 45, "ARFLModifyPersistant_SP", @PERF_time_last OUTPUT

BEGIN
	
	EXEC @result = aractcus_sp	@batch_ctrl_num,
					@debug_level,
					@perf_level
	IF( @result != 0 OR @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arflmp.sp" + ", line " + STR( 56, 5 ) + " -- EXIT: "
		RETURN @result
	END

	
	EXEC @result = aractprc_sp	@batch_ctrl_num,
								@debug_level,
								@perf_level
	IF( @result != 0 OR @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arflmp.sp" + ", line " + STR( 68, 5 ) + " -- EXIT: "
		RETURN @result
	END

	
	EXEC @result = aractshp_sp	@batch_ctrl_num,
								@debug_level,
								@perf_level
	IF( @result != 0 OR @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arflmp.sp" + ", line " + STR( 80, 5 ) + " -- EXIT: "
		RETURN @result
	END
	
	EXEC @result = aractslp_sp	@batch_ctrl_num,
								@debug_level,
								@perf_level
	IF( @result != 0 OR @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arflmp.sp" + ", line " + STR( 91, 5 ) + " -- EXIT: "
		RETURN @result
	END

	
	EXEC @result = aractter_sp	@batch_ctrl_num,
								@debug_level,
								@perf_level
	IF( @result != 0 OR @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arflmp.sp" + ", line " + STR( 103, 5 ) + " -- EXIT: "
		RETURN @result
	END

	
	EXEC @result = arsumcus_sp	@batch_ctrl_num,
								@debug_level,
								@perf_level
	IF( @result != 0 OR @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arflmp.sp" + ", line " + STR( 115, 5 ) + " -- EXIT: "
		RETURN @result
	END
 
	
	EXEC @result = arsumprc_sp	@batch_ctrl_num,
								@debug_level,
								@perf_level
	IF( @result != 0 OR @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arflmp.sp" + ", line " + STR( 127, 5 ) + " -- EXIT: "
		RETURN @result
	END
 
	
	EXEC @result = arsumshp_sp	@batch_ctrl_num,
								@debug_level,
								@perf_level
	IF( @result != 0 OR @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arflmp.sp" + ", line " + STR( 139, 5 ) + " -- EXIT: "
		RETURN @result
	END

	
	EXEC @result = arsumslp_sp	@batch_ctrl_num,
								@debug_level,
								@perf_level
	IF( @result != 0 OR @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arflmp.sp" + ", line " + STR( 151, 5 ) + " -- EXIT: "
		RETURN @result
	END

	
	EXEC @result = arsumter_sp	@batch_ctrl_num,
								@debug_level,
								@perf_level
	IF( @result != 0 OR @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arflmp.sp" + ", line " + STR( 163, 5 ) + " -- EXIT: "
		RETURN @result
	END

	
	EXEC @result = artrx_sp	@batch_ctrl_num,
							@debug_level,
							@perf_level
	IF( @result != 0 OR @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arflmp.sp" + ", line " + STR( 175, 5 ) + " -- EXIT: "
		RETURN @result
	END

	
	EXEC @result = artrxage_sp	@batch_ctrl_num,
								@debug_level,
								@perf_level
	IF( @result != 0 OR @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arflmp.sp" + ", line " + STR( 187, 5 ) + " -- EXIT: "
		RETURN @result
	END
	
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arflmp.sp" + ", line " + STR( 191, 5 ) + " -- EXIT: "
	RETURN 0
END
GO
GRANT EXECUTE ON  [dbo].[ARFLModifyPersistant_SP] TO [public]
GO
