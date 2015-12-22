SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


























  



					  

























































 




















































































































































































































































































































CREATE PROC [dbo].[artrxpdt_sp]	@batch_ctrl_num	varchar( 16 ),
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
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'artrxpdt.cpp' + ', line ' + STR( 43, 5 ) + ' -- ENTRY: '


	IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, 'artrxpdt.cpp', 46, 'entry artrxpdt_sp', @PERF_time_last OUTPUT

	








	IF ( @debug_level > 2 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'artrxpdt.cpp' + ', line ' + STR( 57, 5 ) + ' -- MSG: ' + 'Deleting Actions'
	DELETE	artrxpdt
	FROM	#artrxpdt_work a, artrxpdt b
	WHERE 	a.trx_ctrl_num = b.trx_ctrl_num 
	AND	a.trx_type = b.trx_type 
	AND	a.sequence_id = b.sequence_id 
	AND	a.db_action > 0

	SELECT	@status = @@error

	IF ( @status = 0 )
	BEGIN
		IF ( @debug_level > 2 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'artrxpdt.cpp' + ', line ' + STR( 69, 5 ) + ' -- MSG: ' + 'Inserting into table artrxpdt'
		INSERT	artrxpdt
		( 
			doc_ctrl_num,		trx_ctrl_num,		sequence_id,
			gl_trx_id,	 	customer_code,	trx_type,
			apply_to_num,		apply_trx_type,	date_aging,
			date_applied,		amt_applied,		amt_disc_taken,
			amt_wr_off,		void_flag,		line_desc,
			posted_flag,		sub_apply_num,	sub_apply_type,
			amt_tot_chg,		amt_paid_to_date,	terms_code,
			posting_code,		payer_cust_code,	gain_home,
			gain_oper,		inv_amt_applied,	inv_amt_disc_taken,
			inv_amt_wr_off,	inv_cur_code, writeoff_code, 	org_id
		)
		SELECT	doc_ctrl_num,		trx_ctrl_num,		sequence_id,
			gl_trx_id,		customer_code,	trx_type,
			apply_to_num,		apply_trx_type,	date_aging,
			date_applied,		amt_applied,		amt_disc_taken,
			amt_wr_off,		void_flag,		line_desc,
			posted_flag,		sub_apply_num,	sub_apply_type,
			amt_tot_chg,		amt_paid_to_date,	terms_code,
			posting_code,		payer_cust_code,	gain_home,
			gain_oper,		inv_amt_applied,	inv_amt_disc_taken,
			inv_amt_wr_off,	inv_cur_code,		writeoff_code,	org_id
		FROM	#artrxpdt_work
		WHERE	db_action > 0
		AND	db_action < 4 

		SELECT	@status = @@error

		IF ( @perf_level >= 2 ) EXEC perf_sp @batch_ctrl_num, 'artrxpdt.cpp', 99, 'insert artrxpdt: insert action', @PERF_time_last OUTPUT
	END
	
	IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, 'artrxpdt.cpp', 102, 'exit artrxpdt_sp', @PERF_time_last OUTPUT

	RETURN @status 
END
GO
GRANT EXECUTE ON  [dbo].[artrxpdt_sp] TO [public]
GO
