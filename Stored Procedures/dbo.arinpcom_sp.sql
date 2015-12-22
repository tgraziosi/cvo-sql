SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[arinpcom_sp]	@batch_ctrl_num	varchar( 16 ),
					@debug_level		smallint = 0,
					@perf_level		smallint = 0
AS






DECLARE
 @PERF_time_last datetime

SELECT @PERF_time_last = GETDATE()















									







DECLARE
	@status 	int

SELECT 	@status = 0

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arinpcom.sp" + ", line " + STR( 41, 5 ) + " -- ENTRY: "

IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, "tmp/arinpcom.sp", 43, "entry arinpcom_sp", @PERF_time_last OUTPUT



DELETE	arinpcom
FROM	#arinpcom_work a, arinpcom b
WHERE	a.trx_ctrl_num = b.trx_ctrl_num 
AND	a.trx_type = b.trx_type 
AND	a.sequence_id = b.sequence_id
AND	db_action > 0

SELECT	@status = @@error

IF ( @perf_level >= 2 ) EXEC perf_sp @batch_ctrl_num, "tmp/arinpcom.sp", 64, "delete arinpcom: delete action", @PERF_time_last OUTPUT

IF ( @status = 0 )
BEGIN
	INSERT	arinpcom 
	( 
		trx_ctrl_num,
		trx_type,
		sequence_id,
		salesperson_code,
		amt_commission,
		percent_flag,
		exclusive_flag,
		split_flag
	)
	SELECT		 
		trx_ctrl_num,
		trx_type,
		sequence_id,
		salesperson_code,
		amt_commission,
		percent_flag,
		exclusive_flag,
		split_flag
	FROM	#arinpcom_work
	WHERE	db_action > 0
	AND 	db_action < 4

	SELECT	@status = @@error

	IF ( @perf_level >= 2 ) EXEC perf_sp @batch_ctrl_num, "tmp/arinpcom.sp", 94, "insert arinpcom: insert action", @PERF_time_last OUTPUT

END


IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, "tmp/arinpcom.sp", 99, "exit arinpcom_sp", @PERF_time_last OUTPUT
RETURN @status

GO
GRANT EXECUTE ON  [dbo].[arinpcom_sp] TO [public]
GO
