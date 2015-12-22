SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[arinprev_sp]	@batch_ctrl_num	varchar( 16 ),
					@debug_level		smallint = 0,
					@perf_level		smallint = 0
WITH RECOMPILE
AS






DECLARE
 @PERF_time_last datetime

SELECT @PERF_time_last = GETDATE()















									







DECLARE
	@status 	int

SELECT 	@status = 0

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arinprev.sp" + ", line " + STR( 42, 5 ) + " -- ENTRY: "

IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, "tmp/arinprev.sp", 44, "entry arinprev_sp", @PERF_time_last OUTPUT



DELETE	arinprev
FROM	#arinprev_work a, arinprev b
WHERE	a.trx_ctrl_num = b.trx_ctrl_num 
AND	a.trx_type = b.trx_type 
AND	a.sequence_id = b.sequence_id
AND	db_action > 0

SELECT	@status = @@error

IF ( @perf_level >= 2 ) EXEC perf_sp @batch_ctrl_num, "tmp/arinprev.sp", 65, "delete arinprev: delete action", @PERF_time_last OUTPUT

IF ( @status = 0 )
BEGIN
	INSERT	arinprev 
	( 
		trx_ctrl_num,
		sequence_id,
		rev_acct_code,
		apply_amt,
		trx_type,
		reference_code
	)
	SELECT		 
		trx_ctrl_num,
		sequence_id,
		rev_acct_code,
		apply_amt,
		trx_type,
		reference_code
	FROM	#arinprev_work
	WHERE	db_action > 0
	AND 	db_action < 4

	SELECT	@status = @@error

	IF ( @perf_level >= 2 ) EXEC perf_sp @batch_ctrl_num, "tmp/arinprev.sp", 91, "insert arinprev: insert action", @PERF_time_last OUTPUT

END


IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, "tmp/arinprev.sp", 96, "exit arinprev_sp", @PERF_time_last OUTPUT
RETURN @status

GO
GRANT EXECUTE ON  [dbo].[arinprev_sp] TO [public]
GO
