SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


























  



					  

























































 




















































































































































































































































































































CREATE PROCEDURE [dbo].[artrxcdt_sp]	@batch_ctrl_num	varchar( 16 ),
					@debug_level		smallint = 0,
					@perf_level		smallint = 0
WITH RECOMPILE
AS








DECLARE
        @PERF_time_last     datetime

SELECT  @PERF_time_last = GETDATE()

















									







DECLARE
	@status 	int
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'artrxcdt.cpp' + ', line ' + STR( 40, 5 ) + ' -- ENTRY: '

	IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, 'artrxcdt.cpp', 42, 'entry artrxcdt_sp', @PERF_time_last OUTPUT

	








	DELETE	artrxcdt
	FROM	#artrxcdt_work a, artrxcdt b
	WHERE	a.trx_ctrl_num = b.trx_ctrl_num
	AND	a.trx_type = b.trx_type
	AND	a.sequence_id = b.sequence_id
	AND	a.db_action > 0

	SELECT	@status = @@error

	IF ( @perf_level >= 2 ) EXEC perf_sp @batch_ctrl_num, 'artrxcdt.cpp', 62, 'delete artrxcdt: delete action', @PERF_time_last OUTPUT

	IF ( @status = 0 )
	BEGIN
		INSERT	artrxcdt 
		( 
			doc_ctrl_num,		trx_ctrl_num,
			sequence_id,		trx_type,		location_code,
			item_code,		bulk_flag,		date_entered,
			date_posted,		date_applied,		line_desc,
			qty_ordered,		qty_shipped,		unit_code,
			unit_price,		weight,		amt_cost,
			serial_id,		tax_code,		gl_rev_acct,
			discount_prc,		discount_amt,		rma_num,
			return_code,		qty_returned,		new_gl_rev_acct,
			disc_prc_flag,	extended_price,	calc_tax,
			reference_code,		new_reference_code,	cust_po,
			org_id
		)
		SELECT		   
			doc_ctrl_num,		trx_ctrl_num,
			sequence_id,		trx_type,		location_code,
			item_code,		bulk_flag,		date_entered,
			date_posted,		date_applied,		line_desc,
			qty_ordered,		qty_shipped,		unit_code,
			unit_price,		weight,		amt_cost,
			serial_id,		tax_code,		gl_rev_acct,
			discount_prc,		discount_amt,		rma_num,
			return_code,		qty_returned,		new_gl_rev_acct,
			disc_prc_flag,	extended_price,	calc_tax,
			reference_code,		new_reference_code,	ISNULL(cust_po, ''),
			org_id
		FROM	#artrxcdt_work
		WHERE	db_action > 0
		AND	db_action < 4

		SELECT	@status = @@error

		IF ( @perf_level >= 2 ) EXEC perf_sp @batch_ctrl_num, 'artrxcdt.cpp', 100, 'insert artrxcdt: insert action', @PERF_time_last OUTPUT
	END

IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, 'artrxcdt.cpp', 103, 'exit artrxcdt_sp', @PERF_time_last OUTPUT
RETURN @status
END
GO
GRANT EXECUTE ON  [dbo].[artrxcdt_sp] TO [public]
GO
