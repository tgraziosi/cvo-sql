SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/* PVCS Revision or Version:Revision              
I:\vcs\AR\PROCS\arcrup.SPv - e7.2.2 : 1.8
              Confidential Information                  
   Limited Distribution of Authorized Persons Only      
   Created 1996 and Protected as Unpublished Work       
         Under the U.S. Copyright Act of 1976           
Copyright (c) 1996 Epicor Software Corporation, 1996  
                 All Rights Reserved                    
*/                                                









 



					 










































 








































































































































































































































































































































































































































































































CREATE PROC [dbo].[ARCRUpdatePersistant_SP]			@batch_ctrl_num		varchar( 16 ),
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
	@err_msg	varchar(100)

IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, "tmp/arcrup.sp", 87, "Entering ARCRUpdatePersistant_SP", @PERF_time_last OUTPUT

BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcrup.sp" + ", line " + STR( 90, 5 ) + " -- ENTRY: "
		
	
	EXEC @result = ARModifyPersistant_SP	@batch_ctrl_num,
											@debug_level,
											@perf_level
	IF( @result != 0 )
	BEGIN
		IF ( @debug_level > 2 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcrup.sp" + ", line " + STR( 101, 5 ) + " -- MSG: " + " A database error occured in ARModifyPersistant_SP"
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcrup.sp" + ", line " + STR( 102, 5 ) + " -- EXIT: "
		RETURN @result
	END

		IF EXISTS(SELECT 1 FROM perror (NOLOCK) WHERE batch_code = @batch_ctrl_num )
			EXEC @result = batupdst_sp	@batch_ctrl_num, 5
		ELSE	
			EXEC @result = batupdst_sp	@batch_ctrl_num, 1	

	IF( @result != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcrup.sp" + ", line " + STR( 113, 5 ) + " -- EXIT: "
		RETURN 34563
	END

	
	IF EXISTS (SELECT * FROM arco WHERE bb_flag = 1 )
	BEGIN
		EXEC @result = cminpsav_sp
		IF( @result != 0 )
		BEGIN
			IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcrup.sp" + ", line " + STR( 125, 5 ) + " -- EXIT: "
			RETURN 34563
		END
	END

	
	EXEC @result = gltrxsav_sp	@process_ctrl_num,
								@company_code,
								@debug_level
	IF( @result != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcrup.sp" + ", line " + STR( 138, 5 ) + " -- EXIT: "
		RETURN 34563
	END
	
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcrup.sp" + ", line " + STR( 142, 5 ) + " -- EXIT: "					
	IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, "tmp/arcrup.sp", 143, "Leaving ARCRUpdatePersistant_SP", @PERF_time_last OUTPUT
	RETURN 0
END
GO
GRANT EXECUTE ON  [dbo].[ARCRUpdatePersistant_SP] TO [public]
GO
