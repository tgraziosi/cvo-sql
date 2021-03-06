SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO










 



					 










































 








































































































































































































































































































































































































































































































CREATE PROC [dbo].[ARCRCreateDependantTrans_SP]	@batch_ctrl_num	varchar( 16 ),
						@debug_level		smallint,
						@perf_level		smallint
AS






DECLARE
 @PERF_time_last datetime

SELECT @PERF_time_last = GETDATE()















									







DECLARE
	@result 			int,
	@cm_if				int

IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, "tmp/arcrcdt.sp", 62, "Entering ARCRCreateDependantTrans_SP", @PERF_time_last OUTPUT

BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcrcdt.sp" + ", line " + STR( 65, 5 ) + " -- ENTRY: "

	
	EXEC @result = ARCRCreateGLTrans_SP	@batch_ctrl_num,
						 	@debug_level,
						 	@perf_level
	IF( @result != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcrcdt.sp" + ", line " + STR( 75, 5 ) + " -- EXIT: "
		RETURN @result
	END
	
	
	
	SELECT	@cm_if = bb_flag
	FROM	arco

	IF (@cm_if = 1 AND EXISTS (	SELECT payment_type
					FROM	#arinppyt_work
					WHERE	batch_code = @batch_ctrl_num
					AND	payment_type = 1	) )
	BEGIN

		EXEC @result = ARCRCreateCMtrans_SP	@batch_ctrl_num,
								@debug_level,
								@perf_level

		IF(@result != 0)
		BEGIN
			IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcrcdt.sp" + ", line " + STR( 101, 5 ) + " -- EXIT: "
			RETURN @result
		END
	END

	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcrcdt.sp" + ", line " + STR( 106, 5 ) + " -- EXIT: "
	RETURN 0 
END
GO
GRANT EXECUTE ON  [dbo].[ARCRCreateDependantTrans_SP] TO [public]
GO
