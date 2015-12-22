SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/* PVCS Revision or Version:Revision              
I:\vcs\AR\PROCS\arcri.SPv - e7.2.2 : 1.5.1.0
              Confidential Information                  
   Limited Distribution of Authorized Persons Only      
   Created 1996 and Protected as Unpublished Work       
         Under the U.S. Copyright Act of 1976           
Copyright (c) 1996 Epicor Software Corporation, 1996  
                 All Rights Reserved                    
*/                                                









 



					 










































 








































































































































































































































































































































































































































































































CREATE PROC [dbo].[ARCRInit_SP]	@batch_ctrl_num	varchar( 16 ),
				@batch_proc_flag	smallint OUTPUT,
				@cm_flag		smallint OUTPUT,
				@process_ctrl_num	varchar( 16 ) OUTPUT,
				@process_user_id	smallint OUTPUT,
				@process_date		int OUTPUT,
				@period_end		int OUTPUT,
				@batch_type		smallint OUTPUT,
				@journal_type		varchar(8) OUTPUT,
				@company_code		varchar(8) OUTPUT,
				@home_currency	varchar(8) OUTPUT,
				@oper_currency	varchar(8) OUTPUT,
				@debug_level		smallint = 0,
				@perf_level 	smallint = 0 
AS






DECLARE
 @PERF_time_last datetime

SELECT @PERF_time_last = GETDATE()















									







DECLARE
 @result 			int

IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, "tmp/arcri.sp", 100, "Entering ARCRInit_SP", @PERF_time_last OUTPUT

BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcri.sp" + ", line " + STR( 103, 5 ) + " -- ENTRY: "
	
	SELECT	@batch_proc_flag = batch_proc_flag,
		@cm_flag = bb_flag
	FROM	arco
	IF( @@error != 0 OR @@rowcount = 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcri.sp" + ", line " + STR( 112, 5 ) + " -- EXIT: "
		IF ( @debug_level > 2 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcri.sp" + ", line " + STR( 113, 5 ) + " -- MSG: " + "database error or not row in arco"
		RETURN 34563
	END

	
	EXEC @result = batinfo_sp	@batch_ctrl_num,
					@process_ctrl_num OUTPUT,
					@process_user_id OUTPUT,
					@process_date OUTPUT,
					@period_end OUTPUT,
					@batch_type OUTPUT
	IF( @result != 0 )
	BEGIN
		IF ( @debug_level > 2 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcri.sp" + ", line " + STR( 130, 5 ) + " -- MSG: " + "batinfo_sp return error: @result = " + STR(@result, 3)
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcri.sp" + ", line " + STR( 131, 5 ) + " -- EXIT: "
		RETURN 35011
	END

	
	SELECT	@journal_type = journal_type
	FROM	glappid
	WHERE	app_id = 2000
	IF( @@error != 0 OR @journal_type IS NULL )
	BEGIN
		IF ( @debug_level > 2 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcri.sp" + ", line " + STR( 143, 5 ) + " -- MSG: " + "journal_type not found in glappid"
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcri.sp" + ", line " + STR( 144, 5 ) + " -- EXIT: "
		RETURN 34563
	END

	
	SELECT	@company_code = company_code
	FROM	glco
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 2 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcri.sp" + ", line " + STR( 155, 5 ) + " -- MSG: " + "Company code not found in glco"
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcri.sp" + ", line " + STR( 156, 5 ) + " -- EXIT: "
		RETURN 34563
	END

	
	SELECT	@home_currency = home_currency,
		@oper_currency = oper_currency
	FROM	glco

	IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, "tmp/arcri.sp", 167, "Leaving ARCRInit_SP", @PERF_time_last OUTPUT
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcri.sp" + ", line " + STR( 168, 5 ) + " -- EXIT: "
	RETURN 0
END





/**/                                              
GO
GRANT EXECUTE ON  [dbo].[ARCRInit_SP] TO [public]
GO
