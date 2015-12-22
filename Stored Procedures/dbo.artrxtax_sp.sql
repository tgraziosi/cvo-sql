SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO









 



					 










































 





















































































































































































































































































CREATE PROCEDURE [dbo].[artrxtax_sp]	@batch_ctrl_num	varchar( 16 ),
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

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/artrxtax.sp" + ", line " + STR( 42, 5 ) + " -- ENTRY: "

IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, "tmp/artrxtax.sp", 44, "entry artrxtax_sp", @PERF_time_last OUTPUT



DELETE	artrxtax
FROM	#artrxtax_work a, artrxtax b
WHERE	a.tax_type_code = b.tax_type_code
AND	a.doc_ctrl_num = b.doc_ctrl_num
AND	a.trx_type = b.trx_type
AND	db_action > 0

SELECT	@status = @@error

IF ( @perf_level >= 2 ) EXEC perf_sp @batch_ctrl_num, "tmp/artrxtax.sp", 65, "delete artrxtax: delete action", @PERF_time_last OUTPUT

IF ( @status = 0 )
BEGIN
	INSERT	artrxtax 
	( 
		tax_type_code,
		doc_ctrl_num,
		trx_type,
		date_applied,
		date_doc,
		amt_gross,
		amt_taxable,
		amt_tax
	)
	SELECT		 
		tax_type_code,
		doc_ctrl_num,
		trx_type,
		date_applied,
		date_doc,
		amt_gross,
		amt_taxable,
		amt_tax
	FROM	#artrxtax_work
	WHERE	db_action > 0
	AND 	db_action < 4

	SELECT	@status = @@error

	IF ( @perf_level >= 2 ) EXEC perf_sp @batch_ctrl_num, "tmp/artrxtax.sp", 95, "insert artrxtax: insert action", @PERF_time_last OUTPUT

END


IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, "tmp/artrxtax.sp", 100, "exit artrxtax_sp", @PERF_time_last OUTPUT
RETURN @status

GO
GRANT EXECUTE ON  [dbo].[artrxtax_sp] TO [public]
GO
