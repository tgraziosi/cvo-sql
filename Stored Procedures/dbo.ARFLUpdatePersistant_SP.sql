SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROC [dbo].[ARFLUpdatePersistant_SP] 	@batch_ctrl_num 	varchar( 16 ),
						@process_ctrl_num	varchar( 16 ),
						@company_code		varchar( 8 ),
						@process_user_id	smallint,
						@debug_level		smallint,
						@perf_level		smallint	
AS






DECLARE
 @PERF_time_last datetime

SELECT @PERF_time_last = GETDATE()















									







DECLARE
	@result 	int,
	@err_msg	varchar(100)

IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, "tmp/arflup.sp", 51, "Entering ARFLUpdatePersistant_SP", @PERF_time_last OUTPUT

BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arflup.sp" + ", line " + STR( 54, 5 ) + " -- ENTRY: "
	
	
	INSERT perror
	(	process_ctrl_num,	batch_code,	module_id,
		err_code,		info1,		info2,
		infoint, 		infofloat, 	flag1,
		trx_ctrl_num,	 	sequence_id,	source_ctrl_num,
		extra
	)
	SELECT	@process_ctrl_num,	@batch_ctrl_num,	module_id,
		err_code,		info1,	 		info2,
		infoint, 		infofloat, 		flag1,
		trx_ctrl_num,		sequence_id,		source_ctrl_num,
		extra 
	FROM 	#ewerror

	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arflup.sp" + ", line " + STR( 75, 5 ) + " -- EXIT: "
		RETURN 34563
	END
		
	
	EXEC @result = ARFLModifyPersistant_SP	@batch_ctrl_num,
							@debug_level,
							@perf_level
	IF( @result != 0 )
	BEGIN
		IF ( @debug_level > 2 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arflup.sp" + ", line " + STR( 88, 5 ) + " -- MSG: " + " A database error occured in ARModifyPersistant_SP"
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arflup.sp" + ", line " + STR( 89, 5 ) + " -- EXIT: "
		RETURN @result
	END

	
	EXEC @result = batupdst_sp	@batch_ctrl_num,
								1
	IF( @result != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arflup.sp" + ", line " + STR( 100, 5 ) + " -- EXIT: "
		RETURN 34563
	END

	
	EXEC @result = gltrxsav_sp	@process_ctrl_num,
								@company_code,
								@debug_level
	IF( @result != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arflup.sp" + ", line " + STR( 112, 5 ) + " -- EXIT: "
		RETURN 34563
	END

	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arflup.sp" + ", line " + STR( 116, 5 ) + " -- EXIT: "					
	IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, "tmp/arflup.sp", 117, "Leaving ARFLUpdatePersistant_SP", @PERF_time_last OUTPUT
	RETURN 0
END
GO
GRANT EXECUTE ON  [dbo].[ARFLUpdatePersistant_SP] TO [public]
GO
