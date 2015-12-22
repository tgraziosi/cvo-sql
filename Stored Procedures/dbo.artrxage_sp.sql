SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


























  



					  

























































 




















































































































































































































































































































CREATE PROC [dbo].[artrxage_sp] 	@batch_ctrl_num	varchar( 16 ),
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
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'artrxage.cpp' + ', line ' + STR( 40, 5 ) + ' -- ENTRY: '

	IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, 'artrxage.cpp', 42, 'entry artrxage_sp', @PERF_time_last OUTPUT

	








	IF ( @debug_level > 2 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'artrxage.cpp' + ', line ' + STR( 53, 5 ) + ' -- MSG: ' + 'Deleteing Actions'

	DELETE	artrxage
	FROM	#artrxage_work a,artrxage b
	WHERE	a.customer_code = b.customer_code
	AND	a.doc_ctrl_num = b.doc_ctrl_num
	AND	a.trx_type = b.trx_type 
	AND	a.trx_ctrl_num = b.trx_ctrl_num 
	AND	a.ref_id = b.ref_id
	AND	a.date_aging = b.date_aging 
	AND	a.sub_apply_num = b.sub_apply_num
	AND	a.db_action > 0

	SELECT	@status = @@error

	IF ( @perf_level >= 2 ) EXEC perf_sp @batch_ctrl_num, 'artrxage.cpp', 68, 'delete artrxage: delete action', @PERF_time_last OUTPUT

	IF ( @status = 0 )
	BEGIN

		IF ( @debug_level > 2 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'artrxage.cpp' + ', line ' + STR( 73, 5 ) + ' -- MSG: ' + 'Inserting into table artrxage'

		INSERT	artrxage 
		( 
			trx_ctrl_num,		trx_type,		ref_id,
	   		doc_ctrl_num,		order_ctrl_num,	cust_po_num,
			apply_to_num,		apply_trx_type,	sub_apply_num,
			sub_apply_type,	date_doc,		date_due,
			date_applied,		date_aging,		customer_code,
			salesperson_code,	territory_code,	price_code,
			amount,		paid_flag,		group_id,
		   	amt_fin_chg,		amt_late_chg,		amt_paid,
		   	payer_cust_code,	rate_oper,		rate_home,
			nat_cur_code,		true_amount,		date_paid,
			journal_ctrl_num,	account_code,		org_id
		)
		SELECT	trx_ctrl_num,		trx_type,		ref_id,
		   	doc_ctrl_num,		order_ctrl_num,	cust_po_num,
		   	apply_to_num,		apply_trx_type,	sub_apply_num,
		   	sub_apply_type,	date_doc,		date_due,
			date_applied,		date_aging,		customer_code,
		   	salesperson_code,	territory_code,	price_code,
		   	amount,		paid_flag,		group_id,
		   	amt_fin_chg,		amt_late_chg,		amt_paid,
		   	payer_cust_code,	rate_oper,		rate_home,
			nat_cur_code,		true_amount,		date_paid,
			journal_ctrl_num,	account_code,		org_id
		FROM	#artrxage_work
		WHERE	db_action > 0
	  	AND 	db_action < 4

		SELECT	@status = @@error

		IF ( @perf_level >= 2 ) EXEC perf_sp @batch_ctrl_num, 'artrxage.cpp', 106, 'insert artrxage: insert action', @PERF_time_last OUTPUT

	END

	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'artrxage.cpp' + ', line ' + STR( 110, 5 ) + ' -- EXIT: '	

	IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, 'artrxage.cpp', 112, 'exit artrxage_sp', @PERF_time_last OUTPUT

	RETURN @status
END
GO
GRANT EXECUTE ON  [dbo].[artrxage_sp] TO [public]
GO
