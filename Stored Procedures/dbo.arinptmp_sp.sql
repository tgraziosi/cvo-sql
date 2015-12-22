SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO









 



					 










































 





















































































































































































































































































CREATE PROCEDURE [dbo].[arinptmp_sp]	@batch_ctrl_num	varchar( 16 ),
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

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arinptmp.sp" + ", line " + STR( 42, 5 ) + " -- ENTRY: "

IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, "tmp/arinptmp.sp", 44, "entry arinptmp_sp", @PERF_time_last OUTPUT



DELETE	arinptmp
FROM	#arinptmp_work a, arinptmp b
WHERE	a.customer_code = b.customer_code 
AND	a.trx_ctrl_num = b.trx_ctrl_num
AND	a.doc_ctrl_num = b.doc_ctrl_num
AND	db_action > 0

SELECT	@status = @@error

IF ( @perf_level >= 2 ) EXEC perf_sp @batch_ctrl_num, "tmp/arinptmp.sp", 65, "delete arinptmp: delete action", @PERF_time_last OUTPUT

IF ( @status = 0 )
BEGIN
	INSERT	arinptmp 
	( 
		trx_ctrl_num,
		doc_ctrl_num,
		trx_desc,
		date_doc,
 	customer_code,
		payment_code,
 	amt_payment,
		prompt1_inp,
		prompt2_inp,
		prompt3_inp,
		prompt4_inp,
		amt_disc_taken,
		cash_acct_code
	)
	SELECT		 
		trx_ctrl_num,
		doc_ctrl_num,
		trx_desc,
		date_doc,
 	customer_code,
		payment_code,
 	amt_payment,
		prompt1_inp,
		prompt2_inp,
		prompt3_inp,
		prompt4_inp,
		amt_disc_taken,
		cash_acct_code
	FROM	#arinptmp_work
	WHERE	db_action > 0
	AND 	db_action < 4

	SELECT	@status = @@error

	IF ( @perf_level >= 2 ) EXEC perf_sp @batch_ctrl_num, "tmp/arinptmp.sp", 105, "insert arinptmp: insert action", @PERF_time_last OUTPUT

END


IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, "tmp/arinptmp.sp", 110, "exit arinptmp_sp", @PERF_time_last OUTPUT
RETURN @status

GO
GRANT EXECUTE ON  [dbo].[arinptmp_sp] TO [public]
GO
