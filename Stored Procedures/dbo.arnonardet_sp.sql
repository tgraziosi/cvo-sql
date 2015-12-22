SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


























  



					  

























































 




















































































































































































































































































































CREATE PROCEDURE [dbo].[arnonardet_sp]		@batch_ctrl_num	varchar( 16 ),
					@debug_level		smallint = 0,
					@perf_level		smallint = 0
WITH RECOMPILE
AS








DECLARE
        @PERF_time_last     datetime

SELECT  @PERF_time_last = GETDATE()

















									







DECLARE
	@status 	int

SELECT 	@status = 0

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'arnoardt.cpp' + ', line ' + STR( 49, 5 ) + ' -- ENTRY: '

IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, 'arnoardt.cpp', 51, 'entry arnonardet_sp', @PERF_time_last OUTPUT












IF ( @perf_level >= 2 ) EXEC perf_sp @batch_ctrl_num, 'arnoardt.cpp', 64, 'delete arnonardet: delete action', @PERF_time_last OUTPUT




DELETE	arnonardet
FROM	#arnonardet_work a, arnonardet b
WHERE	a.trx_ctrl_num 	= b.trx_ctrl_num
AND	a.trx_type 	= b.trx_type
AND	a.db_action 	> 0


SELECT	@status = @@error

IF ( @status = 0 )
BEGIN
	INSERT	arnonardet 
	( 
		timestamp,
		trx_ctrl_num,  
		trx_type,   
		sequence_id,	
		line_desc,
		tax_code,
		gl_acct_code,
		unit_price,
		extended_price,
		reference_code,
		amt_tax,
		qty_shipped,
		org_id
	)
	SELECT		   
		NULL,
		det.trx_ctrl_num,     
		det.trx_type,
		det.sequence_id,	
		det.line_desc,
		det.tax_code,
		det.gl_acct_code,
		det.unit_price,
		det.extended_price,
		det.reference_code,
		det.amt_tax,
		det.qty_shipped,
		det.org_id
	FROM	#arnonardet_work det, #arinppyt_work pyt
	WHERE	pyt.trx_ctrl_num 	= det.trx_ctrl_num
	AND	pyt.trx_type 		= det.trx_type
	AND	det.db_action 		> 0
	AND 	det.db_action 		< 4

	SELECT	@status = @@error

	IF ( @perf_level >= 2 ) EXEC perf_sp @batch_ctrl_num, 'arnoardt.cpp', 118, 'insert arnonardet: insert action', @PERF_time_last OUTPUT

END


IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, 'arnoardt.cpp', 123, 'exit arnonardet_sp', @PERF_time_last OUTPUT
RETURN @status

GO
GRANT EXECUTE ON  [dbo].[arnonardet_sp] TO [public]
GO
