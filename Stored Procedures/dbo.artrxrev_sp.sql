SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


























  



					  

























































 




















































































































































































































































































































CREATE PROCEDURE [dbo].[artrxrev_sp]	@batch_ctrl_num	varchar( 16 ),
					@debug_level		smallint = 0,
					@perf_level			smallint = 0
WITH RECOMPILE
AS








DECLARE
        @PERF_time_last     datetime

SELECT  @PERF_time_last = GETDATE()

















									







DECLARE
	@status 	int

SELECT 	@status = 0

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'artrxrev.cpp' + ', line ' + STR( 42, 5 ) + ' -- ENTRY: '

IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, 'artrxrev.cpp', 44, 'entry artrxrev_sp', @PERF_time_last OUTPUT











DELETE	artrxrev
FROM	#artrxrev_work a, artrxrev b
WHERE	a.trx_ctrl_num = b.trx_ctrl_num
AND	a.trx_type = b.trx_type
AND	a.sequence_id = b.sequence_id
AND	a.db_action > 0

SELECT	@status = @@error

IF ( @perf_level >= 2 ) EXEC perf_sp @batch_ctrl_num, 'artrxrev.cpp', 65, 'delete artrxrev: delete action', @PERF_time_last OUTPUT

IF ( @status = 0 )
BEGIN
	INSERT	artrxrev 
	( 
		trx_ctrl_num,
		sequence_id,
		rev_acct_code,
		apply_amt,
		trx_type,
		reference_code,
		org_id
	)
	SELECT		   
		trx_ctrl_num,
		sequence_id,
		rev_acct_code,
		apply_amt,
		trx_type,
		reference_code,
		org_id
	FROM	#artrxrev_work
	WHERE	db_action > 0
	AND	db_action < 4 

	SELECT	@status = @@error

	IF ( @perf_level >= 2 ) EXEC perf_sp @batch_ctrl_num, 'artrxrev.cpp', 93, 'insert artrxrev: insert action', @PERF_time_last OUTPUT

END


IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, 'artrxrev.cpp', 98, 'exit artrxrev_sp', @PERF_time_last OUTPUT
RETURN @status

GO
GRANT EXECUTE ON  [dbo].[artrxrev_sp] TO [public]
GO
