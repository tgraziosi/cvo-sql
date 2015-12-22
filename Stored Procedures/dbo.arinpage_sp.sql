SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO









 



					 










































 





















































































































































































































































































CREATE PROCEDURE [dbo].[arinpage_sp]	@batch_ctrl_num	varchar( 16 ),
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

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arinpage.sp" + ", line " + STR( 42, 5 ) + " -- ENTRY: "


IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, "tmp/arinpage.sp", 45, "entry arinpage_sp", @PERF_time_last OUTPUT



DELETE	arinpage
FROM	#arinpage_work a, arinpage b
WHERE	a.trx_ctrl_num = b.trx_ctrl_num 
AND	a.trx_type = b.trx_type 
AND	a.date_aging = b.date_aging
AND	db_action > 0 

SELECT	@status = @@error

IF ( @perf_level >= 2 ) EXEC perf_sp @batch_ctrl_num, "tmp/arinpage.sp", 66, "delete arinpage: delete action", @PERF_time_last OUTPUT

IF ( @status = 0 )
BEGIN
	INSERT	arinpage 
	( 
		trx_ctrl_num,
		sequence_id,
		doc_ctrl_num,
		apply_to_num,
		apply_trx_type,
		trx_type,
		date_applied,
		date_due,
		date_aging,
		customer_code,
		salesperson_code,
		territory_code,
		price_code,
		amt_due
	)
	SELECT		 
		trx_ctrl_num,
		sequence_id,
		doc_ctrl_num,
		apply_to_num,
		apply_trx_type,
		trx_type,
		date_applied,
		date_due,
		date_aging,
		customer_code,
		salesperson_code,
		territory_code,
		price_code,
		amt_due
	FROM	#arinpage_work
	WHERE	db_action > 0
	AND 	db_action < 4

	SELECT	@status = @@error

	IF ( @perf_level >= 2 ) EXEC perf_sp @batch_ctrl_num, "tmp/arinpage.sp", 108, "insert arinpage: insert action", @PERF_time_last OUTPUT

END


IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, "tmp/arinpage.sp", 113, "exit arinpage_sp", @PERF_time_last OUTPUT
RETURN @status

GO
GRANT EXECUTE ON  [dbo].[arinpage_sp] TO [public]
GO
