SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROC [dbo].[ARCMPostTemp_SP]	@batch_ctrl_num	varchar( 16 ),
					@debug_level		smallint,
					@perf_level		smallint
AS






DECLARE
 @PERF_time_last datetime

SELECT @PERF_time_last = GETDATE()















									







DECLARE	@result	int

IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, "tmp/arcmpt.sp", 96, "Entering ARCMPostTemp_SP", @PERF_time_last OUTPUT

BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcmpt.sp" + ", line " + STR( 99, 5 ) + " -- ENTRY: "

	
	
CREATE TABLE #arcmtemp
(
	trx_ctrl_num		varchar(16),
	trx_type		smallint,
	journal_ctrl_num	varchar(16),
)


	
	EXEC @result = ARCMCreateWorkTable_SP	@batch_ctrl_num,
							@debug_level,
							@perf_level
	IF( @result != 0 )
	BEGIN
		DROP TABLE #arcmtemp
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcmpt.sp" + ", line " + STR( 119, 5 ) + " -- EXIT: "
		RETURN @result
	END

	
	
	EXEC @result = ARCMCreateGLTransactions_SP	@batch_ctrl_num,
								@debug_level,
								@perf_level
	IF( @result != 0 )
	BEGIN
		DROP TABLE #arcmtemp
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcmpt.sp" + ", line " + STR( 140, 5 ) + " -- EXIT: "
		RETURN @result
	END

	
	IF ( @debug_level > 2 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcmpt.sp" + ", line " + STR( 148, 5 ) + " -- MSG: " + "Going to ARCMCreateOnAccountRecords_SP"
	EXEC @result = ARCMCreateOnAccountRecords_SP	@batch_ctrl_num,
								@debug_level,
								@perf_level
	IF( @result != 0 )
	BEGIN
		DROP TABLE #arcmtemp
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcmpt.sp" + ", line " + STR( 155, 5 ) + " -- EXIT: "
		RETURN @result
	END

	
	EXEC @result = ARCMMoveUnpostedRecords_SP	@batch_ctrl_num,
							@debug_level,
							@perf_level
	IF( @result != 0 )
	BEGIN
		DROP TABLE #arcmtemp
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcmpt.sp" + ", line " + STR( 169, 5 ) + " -- EXIT: "
		RETURN @result
	END
	
	
	EXEC @result = ARCMUpdateInvoiceQuantities_SP	@batch_ctrl_num,
								@debug_level,
								@perf_level
	IF( @result != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcmpt.sp" + ", line " + STR( 182, 5 ) + " -- EXIT: "
		RETURN @result
	END

	
	EXEC @result = ARCMUpdateActivitySummary_SP	@batch_ctrl_num,
								@debug_level,
								@perf_level
	IF( @result != 0 )
	BEGIN
		DROP TABLE #arcmtemp
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcmpt.sp" + ", line " + STR( 196, 5 ) + " -- EXIT: "
		RETURN @result
	END

	DROP TABLE #arcmtemp
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcmpt.sp" + ", line " + STR( 201, 5 ) + " -- EXIT: "
	RETURN 0 
END
GO
GRANT EXECUTE ON  [dbo].[ARCMPostTemp_SP] TO [public]
GO
