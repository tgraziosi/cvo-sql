SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO





























  



					  

























































 












































































































































































































































































































































































































































































































































































































































































































CREATE PROC [dbo].[ARIAMoveUnpostedRecords_SP]	@batch_ctrl_num	varchar(16),
						@journal_ctrl_num	varchar(16),
						@debug_level		smallint,
						@perf_level		smallint

AS








DECLARE
        @PERF_time_last     datetime

SELECT  @PERF_time_last = GETDATE()

















									







DECLARE
	@result	int,
	@sys_date	int
	
IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, 'ariamur.cpp', 57, 'Entering ARIAMoveUnpostedRecords_SP', @PERF_time_last OUTPUT

BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'ariamur.cpp' + ', line ' + STR( 60, 5 ) + ' -- ENTRY: '

	



	EXEC appdate_sp @sys_date OUTPUT

	




	INSERT	#artrxcdt_work 
	(
		doc_ctrl_num,		trx_ctrl_num,		sequence_id,
		trx_type,		location_code,	item_code,
		bulk_flag,		date_entered,		date_posted,
		date_applied,		line_desc,		qty_ordered,	
		qty_shipped,		unit_code,		unit_price,
		weight,		amt_cost,		serial_id,
		tax_code,		gl_rev_acct,		discount_prc,	
		discount_amt,		rma_num,		return_code,
		qty_returned,		new_gl_rev_acct,	disc_prc_flag,
		extended_price,	db_action,		calc_tax,
		reference_code,		new_reference_code,	cust_po, org_id
   	)
   	SELECT
		cdt.doc_ctrl_num,	cdt.trx_ctrl_num,	cdt.sequence_id,
		cdt.trx_type,		cdt.location_code,	cdt.item_code,
		cdt.bulk_flag,	cdt.date_entered,	@sys_date,
		chg.date_applied,	cdt.line_desc,	cdt.qty_ordered,	
		cdt.qty_shipped,	cdt.unit_code,	cdt.unit_price,
		cdt.weight,		0.0,			cdt.serial_id,
		cdt.tax_code,		cdt.gl_rev_acct,	cdt.discount_prc,	
		cdt.discount_amt,	cdt.rma_num,		cdt.return_code,
		cdt.qty_returned,	cdt.new_gl_rev_acct,	cdt.disc_prc_flag,
		cdt.extended_price,	2,	cdt.calc_tax,
		cdt.reference_code, 	cdt.new_reference_code,	cdt.cust_po, cdt.org_id
	FROM	#arinpcdt_work cdt, #arinpchg_work chg
	WHERE	cdt.trx_ctrl_num = chg.trx_ctrl_num
	AND	cdt.trx_type = chg.trx_type
	AND	(cdt.gl_rev_acct != cdt.new_gl_rev_acct
	OR	 cdt.reference_code != cdt.new_reference_code )
	AND	chg.batch_code = @batch_ctrl_num 	
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'ariamur.cpp' + ', line ' + STR( 107, 5 ) + ' -- EXIT: '
		RETURN 34563
	END	

	SELECT 'Dumping artrxcdt_work records after moving unposted records'
	SELECT ' doc_ctrl_num = ' + doc_ctrl_num +
		' sequence_id = ' + STR(sequence_id, 2) +
		' trx_type = ' + STR(trx_type,6) +
		' gl_rev_acct = ' + gl_rev_acct +
		' new_gl_rev_acct = ' + new_gl_rev_acct +
		' extended_price = ' + STR(extended_price, 10,2) +
		' db_action = ' + STR(db_action,2)
	FROM #artrxcdt_work

	

 
	INSERT	#artrx_work 
	(
		trx_ctrl_num,		doc_ctrl_num,		apply_to_num,
		apply_trx_type,	order_ctrl_num,	doc_desc,
		batch_code, 		trx_type, 		date_entered,
		date_posted, 		date_applied, 	date_doc,
		date_shipped, 	date_required, 	date_due,
		date_aging, 		customer_code, 	ship_to_code,
		salesperson_code, 	territory_code, 	comment_code,
		fob_code, 		freight_code, 	terms_code,
		fin_chg_code, 	price_code, 		dest_zone_code,
		posting_code, 	recurring_flag, 	recurring_code,
		tax_code, 		payment_code, 	payment_type,
		cust_po_num, 		non_ar_flag, 		gl_acct_code,
		gl_trx_id, 		prompt1_inp, 		prompt2_inp,
		prompt3_inp, 		prompt4_inp, 		deposit_num,
		amt_gross, 		amt_freight, 		amt_tax,
		amt_discount, 	amt_paid_to_date, 	amt_net,
		amt_on_acct, 		amt_cost, 		amt_tot_chg,
		amt_discount_taken, 	amt_write_off_given, user_id,
		void_flag, 		paid_flag, 		date_paid,
		posted_flag, 		commission_flag, 	cash_acct_code,
		non_ar_doc_num, 	purge_flag, 		process_group_num,
		source_trx_ctrl_num, source_trx_type, 	nat_cur_code,
		rate_type_home, 	rate_type_oper, 	rate_home,
		rate_oper, 		db_action,		amt_tax_included,	 org_id
	)
	SELECT	
		trx_ctrl_num,		doc_ctrl_num,		apply_to_num,
		apply_trx_type,	order_ctrl_num,	doc_desc,
		batch_code, 		trx_type, 		date_entered,
		@sys_date, 		date_applied, 	date_doc,
		date_shipped, 	date_required, 	date_due,
		date_aging, 		customer_code, 	ship_to_code,
		salesperson_code, 	territory_code, 	comment_code,
		fob_code, 		freight_code, 	terms_code,
		fin_chg_code, 	price_code, 		dest_zone_code,
		posting_code, 	recurring_flag, 	recurring_code,
		tax_code, 		' ', 			0,
		cust_po_num, 		0, 			' ',
		@journal_ctrl_num,	' ', 			' ',
		' ', 			' ', 			' ',
		amt_gross, 		amt_freight, 		amt_tax,
		amt_discount, 	0.0, 			amt_net,
		0.0, 			amt_cost, 		0.0,
		amt_discount_taken, 	amt_write_off_given, user_id,
		0, 			0, 			0,
		1, 		0, 			' ',
		' ', 			0, 			process_group_num,
		source_trx_ctrl_num, source_trx_type, 	nat_cur_code,
		rate_type_home, 	rate_type_oper, 	rate_home,
		rate_oper, 		2,	amt_tax_included, 	org_id
	FROM	#arinpchg_work 
	WHERE	batch_code = @batch_ctrl_num
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'ariamur.cpp' + ', line ' + STR( 180, 5 ) + ' -- EXIT: '
		RETURN 34563
	END
	SELECT 'Dumping artrx_work records after moving unposted records'
	SELECT	'doc_ctrl_num = ' + doc_ctrl_num +
		' trx_type = ' + STR(trx_type,6) +
		' customer_code = ' + customer_code +
		' amt_net = ' + STR(amt_net,10,2) +
		' ship_to_code = ' + ship_to_code +
		' db_action = ' + STR(db_action,2)
	FROM #artrx_work

	


	UPDATE	#arinpchg_work
	SET	db_action = 4
	WHERE	batch_code = @batch_ctrl_num
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'ariamur.cpp' + ', line ' + STR( 200, 5 ) + ' -- EXIT: '
		RETURN 34563
	END

	UPDATE	#arinpcdt_work
	SET	db_action = 4
	FROM	#arinpchg_work arinpchg, #arinpcdt_work arinpcdt
	WHERE	arinpchg.batch_code = @batch_ctrl_num
	AND	arinpchg.trx_ctrl_num = arinpcdt.trx_ctrl_num
	AND	arinpchg.trx_type = arinpcdt.trx_type
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'ariamur.cpp' + ', line ' + STR( 212, 5 ) + ' -- EXIT: '
		RETURN 34563
	END

	IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, 'ariamur.cpp', 216, 'Leaving ARIAMoveUnpostedRecords_SP', @PERF_time_last OUTPUT

    RETURN 0 

END

GO
GRANT EXECUTE ON  [dbo].[ARIAMoveUnpostedRecords_SP] TO [public]
GO
