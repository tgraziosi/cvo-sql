SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[arinptax_sp]	@batch_ctrl_num	varchar( 16 ),
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

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arinptax.sp" + ", line " + STR( 42, 5 ) + " -- ENTRY: "

IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, "tmp/arinptax.sp", 44, "entry arinptax_sp", @PERF_time_last OUTPUT



DELETE	arinptax
FROM	#arinptax_work a, arinptax b
WHERE	a.trx_ctrl_num = b.trx_ctrl_num 
AND	a.trx_type = b.trx_type 
AND	a.sequence_id = b.sequence_id
AND	db_action > 0

SELECT	@status = @@error

IF ( @perf_level >= 2 ) EXEC perf_sp @batch_ctrl_num, "tmp/arinptax.sp", 65, "delete arinptax: delete action", @PERF_time_last OUTPUT

IF ( @status = 0 )
BEGIN
	INSERT	arinptax 
	( 
		trx_ctrl_num,
		trx_type,
		sequence_id,
		tax_type_code,
		amt_taxable,
		amt_gross,
		amt_tax,
		amt_final_tax
	)
	SELECT		 
		trx_ctrl_num,
		trx_type,
		sequence_id,
		tax_type_code,
		amt_taxable,
		amt_gross,
		amt_tax,
		amt_final_tax	
	FROM	#arinptax_work
	WHERE	db_action > 0
	AND 	db_action < 4

	SELECT	@status = @@error

	IF ( @perf_level >= 2 ) EXEC perf_sp @batch_ctrl_num, "tmp/arinptax.sp", 95, "insert arinptax: insert action", @PERF_time_last OUTPUT

END


IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, "tmp/arinptax.sp", 100, "exit arinptax_sp", @PERF_time_last OUTPUT
RETURN @status

GO
GRANT EXECUTE ON  [dbo].[arinptax_sp] TO [public]
GO
