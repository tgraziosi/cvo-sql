SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO









 



					 










































 





















































































































































































































































































CREATE PROCEDURE [dbo].[artrxcom_sp]	@batch_ctrl_num	varchar( 16 ),
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

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/artrxcom.sp" + ", line " + STR( 42, 5 ) + " -- ENTRY: "

IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, "tmp/artrxcom.sp", 44, "entry artrxcom_sp", @PERF_time_last OUTPUT



DELETE	artrxcom
FROM	#artrxcom_work a, artrxcom b
WHERE	a.trx_ctrl_num = b.trx_ctrl_num
AND	a.sequence_id = b.sequence_id
AND	a.db_action > 0

SELECT	@status = @@error

IF ( @perf_level >= 2 ) EXEC perf_sp @batch_ctrl_num, "tmp/artrxcom.sp", 64, "delete artrxcom: delete action", @PERF_time_last OUTPUT

IF ( @status = 0 )
BEGIN
	INSERT	artrxcom 
	( 
		trx_ctrl_num,
		trx_type,
		doc_ctrl_num,
		sequence_id,
		salesperson_code,
		amt_commission,
		percent_flag,
		exclusive_flag,
		split_flag,
		commission_flag
	)
	SELECT		 
		trx_ctrl_num,
		trx_type,
		doc_ctrl_num,
		sequence_id,
		salesperson_code,
		amt_commission,
		percent_flag,
		exclusive_flag,
		split_flag,
		commission_flag
	FROM	#artrxcom_work
	WHERE	db_action > 0
	AND	db_action < 4

	SELECT	@status = @@error

	IF ( @perf_level >= 2 ) EXEC perf_sp @batch_ctrl_num, "tmp/artrxcom.sp", 98, "insert artrxcom: insert action", @PERF_time_last OUTPUT

END


IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, "tmp/artrxcom.sp", 103, "exit artrxcom_sp", @PERF_time_last OUTPUT
RETURN @status

GO
GRANT EXECUTE ON  [dbo].[artrxcom_sp] TO [public]
GO
