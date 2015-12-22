SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROC [dbo].[arcycle_sp]	@batch_ctrl_num	varchar( 16 ),
				@debug_level		smallint = 0,
				@perf_level		smallint = 0
WITH RECOMPILE
AS






DECLARE
 @PERF_time_last datetime

SELECT @PERF_time_last = GETDATE()















									







DECLARE
	@status 	int

BEGIN
	SELECT 	@status = 0

	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcycle.sp" + ", line " + STR( 43, 5 ) + " -- ENTRY: "

	IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, "tmp/arcycle.sp", 45, "entry arcycle_sp", @PERF_time_last OUTPUT

	
	UPDATE	arcycle
	SET	date_last_used = b.date_last_used,
		amt_tracked_balance = b.amt_tracked_balance
	FROM	arcycle a, #arcycle_work b
	WHERE	a.cycle_code = b.cycle_code			
	
	IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, "tmp/arcycle.sp", 56, "exit arcycle_sp", @PERF_time_last OUTPUT
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcycle.sp" + ", line " + STR( 57, 5 ) + " -- EXIT: "
	RETURN @status
END
GO
GRANT EXECUTE ON  [dbo].[arcycle_sp] TO [public]
GO
