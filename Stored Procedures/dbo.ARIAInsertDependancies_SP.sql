SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROC [dbo].[ARIAInsertDependancies_SP]	@batch_ctrl_num	varchar( 16 ),
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


IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, 'ariaid.cpp', 54, 'Entering ARIAInsertDependancies_SP', @PERF_time_last OUTPUT

BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'ariaid.cpp' + ', line ' + STR( 57, 5 ) + ' -- ENTRY: '

	








	IF ( @perf_level >= 2 ) EXEC perf_sp @batch_ctrl_num, 'ariaid.cpp', 68, 'Start inserting records into #artrx_work', @PERF_time_last OUTPUT
	INSERT	#artrx_work
	(	
		trx_ctrl_num,		doc_ctrl_num,
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
		amt_tot_chg,		amt_discount_taken,	amt_write_off_given,
		user_id,		void_flag,		paid_flag,		
		date_paid,		posted_flag,		commission_flag,	
		cash_acct_code,	non_ar_doc_num,	purge_flag,		
		db_action,		source_trx_ctrl_num,	source_trx_type,
		nat_cur_code,		rate_type_home,	rate_type_oper,
		rate_home,		rate_oper,		amt_tax_included,
		org_id
	)
	SELECT
		trx_ctrl_num,		doc_ctrl_num,
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
		amt_tot_chg,		amt_discount_taken,	amt_write_off_given,
		user_id,		void_flag,		paid_flag,		
		date_paid,		posted_flag,		commission_flag,	
		cash_acct_code,	non_ar_doc_num,	purge_flag,		
		0,		source_trx_ctrl_num,	source_trx_type,
		nat_cur_code,		rate_type_home,	rate_type_oper,
		rate_home,		rate_oper,		amt_tax_included,
		org_id
	FROM	artrx
	WHERE	process_group_num = @process_ctrl_num
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 2 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'ariaid.cpp' + ', line ' + STR( 127, 5 ) + ' -- MSG: ' + 'Error inserting in #artrx_work: @@error = ' + STR( @@error, 7)
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'ariaid.cpp' + ', line ' + STR( 128, 5 ) + ' -- EXIT: '
		RETURN 34563
	END
	IF( @debug_level >= 4 )
	BEGIN
		SELECT	'Dependancies inserted into #artrx_work'
		SELECT	trx_ctrl_num + ' ' + doc_ctrl_num
		FROM	#artrx_work
	END
	IF ( @perf_level >= 2 ) EXEC perf_sp @batch_ctrl_num, 'ariaid.cpp', 137, 'Done inserting into #artrx_work', @PERF_time_last OUTPUT

	



	IF ( @perf_level >= 2 ) EXEC perf_sp @batch_ctrl_num, 'ariaid.cpp', 143, 'Start inserting records into #artrxcdt_work', @PERF_time_last OUTPUT
	INSERT	#artrxcdt_work
	(	
		doc_ctrl_num, 	trx_ctrl_num, 	sequence_id,
		trx_type, 		location_code, 	item_code,
		bulk_flag, 		date_entered, 	date_posted,
		date_applied, 	line_desc,	 	qty_ordered,
		qty_shipped, 		unit_code, 		unit_price,
		weight, 		amt_cost, 		serial_id,
		tax_code, 		gl_rev_acct, 		discount_prc,
		discount_amt, 	rma_num, 		return_code,
		qty_returned, 	new_gl_rev_acct, 	disc_prc_flag,
		extended_price, 	db_action,		calc_tax,
		reference_code,		cust_po,	org_id		
	)
	SELECT
		a.doc_ctrl_num, 	a.trx_ctrl_num, 	a.sequence_id,
		a.trx_type, 		a.location_code, 	a.item_code,
		a.bulk_flag, 		a.date_entered, 	a.date_posted,
		a.date_applied, 	a.line_desc,	 	a.qty_ordered,
		a.qty_shipped, 	a.unit_code, 		a.unit_price,
		a.weight, 		a.amt_cost, 		a.serial_id,
		a.tax_code, 		a.gl_rev_acct, 	a.discount_prc,
		a.discount_amt, 	a.rma_num, 		a.return_code,
		a.qty_returned, 	a.new_gl_rev_acct, 	a.disc_prc_flag,
		a.extended_price, 	0,		a.calc_tax,
		a.reference_code,	a.cust_po,		a.org_id
	FROM	artrxcdt a, #arinpchg_work b
	WHERE	a.doc_ctrl_num = b.apply_to_num
	AND	a.trx_type = b.apply_trx_type
	AND	b.trx_type = 2051
	AND	b.batch_code = @batch_ctrl_num
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 2 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'ariaid.cpp' + ', line ' + STR( 177, 5 ) + ' -- MSG: ' + 'Error inserting in #artrxcdt_work: @@error = ' + STR( @@error, 7)
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'ariaid.cpp' + ', line ' + STR( 178, 5 ) + ' -- EXIT: '
		RETURN 34563
	END
	IF ( @perf_level >= 2 ) EXEC perf_sp @batch_ctrl_num, 'ariaid.cpp', 181, 'Done inserting into #artrxcdt_work', @PERF_time_last OUTPUT


	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'ariaid.cpp' + ', line ' + STR( 184, 5 ) + ' -- EXIT: '
	IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, 'ariaid.cpp', 185, 'Leaving ARIAInsertDependancies_SP', @PERF_time_last OUTPUT
	RETURN 0
END
GO
GRANT EXECUTE ON  [dbo].[ARIAInsertDependancies_SP] TO [public]
GO
