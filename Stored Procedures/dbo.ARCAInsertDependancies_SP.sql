SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROC [dbo].[ARCAInsertDependancies_SP]	@batch_ctrl_num	varchar( 16 ),
						@process_ctrl_num	varchar( 16 ),
						@batch_proc_flag	smallint,
						@debug_level		smallint = 0,
						@perf_level		smallint = 0 
AS








DECLARE
        @PERF_time_last     datetime

SELECT  @PERF_time_last = GETDATE()

















									







DECLARE
	@result	int


IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, 'arcaid.cpp', 52, 'Entering ARCAInsertDependancies_SP', @PERF_time_last OUTPUT

BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'arcaid.cpp' + ', line ' + STR( 55, 5 ) + ' -- ENTRY: '
	








	IF ( @perf_level >= 2 ) EXEC perf_sp @batch_ctrl_num, 'arcaid.cpp', 65, 'Start inserting records into #artrx_work', @PERF_time_last OUTPUT
	INSERT	#artrx_work
	(	
		doc_ctrl_num,		trx_ctrl_num,
		apply_to_num,		apply_trx_type,	order_ctrl_num,
		doc_desc,		batch_code,		trx_type,
		date_entered,		date_posted,		date_applied,
		date_doc,		date_shipped,		date_required,
		date_due,		date_aging,		customer_code,
		ship_to_code,		salesperson_code,	territory_code,
		comment_code,		fob_code,		freight_code,
		terms_code,		fin_chg_code,		price_code,
		dest_zone_code,	posting_code,		recurring_flag,
		recurring_code,	tax_code,		payment_code,
		payment_type,		cust_po_num,		non_ar_flag,
		gl_acct_code,		gl_trx_id,		prompt1_inp,
		prompt2_inp,		prompt3_inp,		prompt4_inp,
		deposit_num,		amt_gross,		amt_freight,
		amt_tax,		amt_discount,		amt_paid_to_date,
		amt_net,		amt_on_acct,		amt_cost,
		amt_tot_chg,		user_id,		void_flag,
		paid_flag,		date_paid,		posted_flag,
		commission_flag,	cash_acct_code,	non_ar_doc_num,
		purge_flag,		db_action,		source_trx_ctrl_num,
		source_trx_type,	nat_cur_code,		rate_type_home,
		rate_type_oper,	rate_home,		rate_oper,
		amt_discount_taken,	amt_tax_included,	reference_code,	org_id  
	)
	SELECT
		doc_ctrl_num,		trx_ctrl_num,
		apply_to_num,		apply_trx_type,	order_ctrl_num,
		doc_desc,		batch_code,		trx_type,
		date_entered,		date_posted,		date_applied,
		date_doc,		date_shipped,		date_required,
		date_due,		date_aging,		customer_code,
		ship_to_code,		salesperson_code,	territory_code,
		comment_code,		fob_code,		freight_code,
		terms_code,		fin_chg_code,		price_code,
		dest_zone_code,	posting_code,		recurring_flag,
		recurring_code,	tax_code,		payment_code,
		payment_type,		cust_po_num,		non_ar_flag,
		gl_acct_code,		gl_trx_id,		prompt1_inp,
		prompt2_inp,		prompt3_inp,		prompt4_inp,
		deposit_num,		amt_gross,		amt_freight,
		amt_tax,		amt_discount,		amt_paid_to_date,
		amt_net,		amt_on_acct,		amt_cost,
		amt_tot_chg,		user_id,		void_flag,
		paid_flag,		date_paid,		posted_flag,
		commission_flag,	cash_acct_code,	non_ar_doc_num,
		purge_flag,		0,		source_trx_ctrl_num,
		source_trx_type,	nat_cur_code,		rate_type_home,
		rate_type_oper,	rate_home,		rate_oper,
		amt_discount_taken,	amt_tax_included,	reference_code,	org_id
	FROM	artrx
	WHERE	process_group_num = @process_ctrl_num
	AND	payment_type IN (0,1,3)


	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 2 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'arcaid.cpp' + ', line ' + STR( 124, 5 ) + ' -- MSG: ' + 'Error inserting in #artrx_work: @@error = ' + STR( @@error, 7)
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'arcaid.cpp' + ', line ' + STR( 125, 5 ) + ' -- EXIT: '
		RETURN 34563
	END
	IF ( @perf_level >= 2 ) EXEC perf_sp @batch_ctrl_num, 'arcaid.cpp', 128, 'Done inserting into #artrx_work', @PERF_time_last OUTPUT

	





	IF ( @perf_level >= 2 ) EXEC perf_sp @batch_ctrl_num, 'arcaid.cpp', 136, 'Start inserting dependent posted payment detail records', @PERF_time_last OUTPUT
	INSERT	#artrxpdt_work
	(
		doc_ctrl_num,		trx_ctrl_num,
		sequence_id,		gl_trx_id,		customer_code,
		trx_type,		apply_to_num,		apply_trx_type,
		date_aging,		date_applied,		amt_applied,
		amt_disc_taken,	amt_wr_off,		void_flag,
		line_desc,		posted_flag,		sub_apply_num,
		sub_apply_type,	amt_tot_chg,		amt_paid_to_date,
		terms_code,		posting_code,		db_action,
		gain_home,		gain_oper,		inv_amt_applied,
		inv_amt_disc_taken,	inv_amt_wr_off,	inv_cur_code,
		payer_cust_code,	writeoff_code,org_id
	)
	SELECT	DISTINCT 
		a.doc_ctrl_num,		a.trx_ctrl_num,
		a.sequence_id,		a.gl_trx_id,		a.customer_code,
		a.trx_type,			a.apply_to_num,	a.apply_trx_type,
		a.date_aging,			a.date_applied,	a.amt_applied,
		a.amt_disc_taken,		a.amt_wr_off,		a.void_flag,
		a.line_desc,			a.posted_flag,	a.sub_apply_num,
		a.sub_apply_type,		a.amt_tot_chg,	a.amt_paid_to_date,
		a.terms_code,			a.posting_code,	0,
		a.gain_home,			a.gain_oper,		a.inv_amt_applied,
		a.inv_amt_disc_taken,	a.inv_amt_wr_off,	a.inv_cur_code,
		a.payer_cust_code,		b.writeoff_code,	a.org_id	
	FROM	artrxpdt a, #arinppdt_work b, #arinppyt_work c
	WHERE	a.doc_ctrl_num = b.doc_ctrl_num
	AND	a.payer_cust_code = b.payer_cust_code
	AND	a.trx_type = 2111
	AND	a.void_flag = 0
	AND	a.sequence_id = b.sequence_id
	AND	b.trx_ctrl_num = c.trx_ctrl_num
	AND	b.trx_type = c.trx_type
	AND	c.batch_code = @batch_ctrl_num

	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 2 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'arcaid.cpp' + ', line ' + STR( 175, 5 ) + ' -- MSG: ' + 'Error inserting in #artrxpdt_work: @@error = ' + STR( @@error, 7)
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'arcaid.cpp' + ', line ' + STR( 176, 5 ) + ' -- EXIT: '
		RETURN 34563
	END

	







		
	IF ( @perf_level >= 2 ) EXEC perf_sp @batch_ctrl_num, 'arcaid.cpp', 189, 'Start inserting dependent transactions into #artrx_work', @PERF_time_last OUTPUT
	





	INSERT	#artrxage_work
	(	
		trx_ctrl_num,		trx_type,
		ref_id,		doc_ctrl_num,		order_ctrl_num,
		cust_po_num,		apply_to_num,		apply_trx_type,
		sub_apply_num,	sub_apply_type,	date_doc,
		date_due,		date_applied,		date_aging,
		customer_code,	payer_cust_code,	salesperson_code,
		territory_code,	price_code,		amount,
		paid_flag,		group_id,		amt_fin_chg,
		amt_late_chg,		amt_paid,		db_action,
		rate_home,		rate_oper,		nat_cur_code,
		true_amount,		date_paid,		journal_ctrl_num,
		account_code,		org_id
	)
	SELECT
		age.trx_ctrl_num,	age.trx_type,
		age.ref_id,		age.doc_ctrl_num,	age.order_ctrl_num,
		age.cust_po_num,	age.apply_to_num,	age.apply_trx_type,
		age.sub_apply_num,	age.sub_apply_type,	age.date_doc,
		age.date_due,		age.date_applied,	age.date_aging,
		age.customer_code,	trx.customer_code,	age.salesperson_code,
		age.territory_code,	age.price_code,	age.amount,
		age.paid_flag,	age.group_id,		age.amt_fin_chg,
		age.amt_late_chg,	age.amt_paid,		0,
		age.rate_home,	age.rate_oper,	age.nat_cur_code,
		age.true_amount,	age.date_paid,	age.journal_ctrl_num,
		age.account_code,	age.org_id
	FROM	artrxage age, #artrx_work trx, artrxmap map
	WHERE	age.doc_ctrl_num = trx.doc_ctrl_num
	AND	age.payer_cust_code = trx.customer_code
	AND	age.trx_type = map.age_type 
	AND	map.artrx_type = trx.trx_type
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 2 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'arcaid.cpp' + ', line ' + STR( 231, 5 ) + ' -- MSG: ' + 'Error inserting in #artrxage_work: @@error = ' + STR( @@error, 7)
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'arcaid.cpp' + ', line ' + STR( 232, 5 ) + ' -- EXIT: '
		RETURN 34563
	END
	

	IF ( @perf_level >= 2 ) EXEC perf_sp @batch_ctrl_num, 'arcaid.cpp', 237, 'Done inserting dependent posted payment detail records', @PERF_time_last OUTPUT

	IF (@debug_level > 0)
	BEGIN
		SELECT 	'artrx_work'
		SELECT 	' trx_ctrl_num = ' + trx_ctrl_num +
				' doc_ctrl_num = ' + doc_ctrl_num +
				' trx_type = ' + STR(trx_type,6) +
				' customer_code = ' + customer_code	+
				' amt_net = ' + STR(amt_net,10,2) +
				' amt_paid_to_date = ' + STR(amt_paid_to_date,10,2) +
				' reference_code = ' + reference_code
		FROM #artrx_work

		SELECT 	'artrxage_work'
		SELECT 	' trx_ctrl_num = ' + trx_ctrl_num +
				' doc_ctrl_num = ' + doc_ctrl_num +
				' apply_to_num = ' + apply_to_num +
				' trx_type = ' + STR(trx_type,6) +
				' customer_code = ' + customer_code	+
				' amount = ' + STR(amount,10,2)
		FROM #artrxage_work

		SELECT 	'artrxpdt_work'
		SELECT 	' trx_ctrl_num = ' + trx_ctrl_num +
				' doc_ctrl_num = ' + doc_ctrl_num +
				' trx_type = ' + STR(trx_type,6) +
				' customer_code = ' + customer_code	+
				' amt_applied = ' + STR(amt_applied,10,2)
		FROM #artrxpdt_work
	END

	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'arcaid.cpp' + ', line ' + STR( 269, 5 ) + ' -- EXIT: '
	IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, 'arcaid.cpp', 270, 'Leaving ARCAInsertDependancies_SP', @PERF_time_last OUTPUT
	RETURN 0
END
GO
GRANT EXECUTE ON  [dbo].[ARCAInsertDependancies_SP] TO [public]
GO
