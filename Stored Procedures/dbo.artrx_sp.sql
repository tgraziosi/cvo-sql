SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


























  



					  

























































 




















































































































































































































































































































CREATE PROC [dbo].[artrx_sp]	@batch_ctrl_num	varchar( 16 ),
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
	SELECT	@status = 0

	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'artrx.cpp' + ', line ' + STR( 43, 5 ) + ' -- ENTRY: '

	IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, 'artrx.cpp', 45, 'entry artrx_sp', @PERF_time_last OUTPUT

	








	IF ( @debug_level > 2 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'artrx.cpp' + ', line ' + STR( 56, 5 ) + ' -- MSG: ' + 'Deleting Actions'
	DELETE	artrx
	FROM	#artrx_work a, artrx b
	WHERE	a.customer_code = b.customer_code
	AND	a.trx_ctrl_num = b.trx_ctrl_num 
	AND	a.trx_type = b.trx_type 
	AND	a.db_action > 0

	SELECT @status = @@error
	
	IF ( @perf_level >= 2 ) EXEC perf_sp @batch_ctrl_num, 'artrx.cpp', 66, 'delete artrx: delete action', @PERF_time_last OUTPUT
	
	IF ( @status = 0 )
	BEGIN
	
		IF ( @debug_level > 2 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'artrx.cpp' + ', line ' + STR( 71, 5 ) + ' -- MSG: ' + 'Inserting into table artrx'
		INSERT	artrx 
		( 
			doc_ctrl_num,		trx_ctrl_num,		apply_to_num,
			apply_trx_type,	order_ctrl_num,	doc_desc,
			batch_code,		trx_type,		date_entered,
			date_posted,		date_applied,		date_doc,
			date_shipped,		date_required,	date_due,
			date_aging,		customer_code,	ship_to_code,
			salesperson_code,	territory_code,	comment_code,
			fob_code,		freight_code,		terms_code,
			fin_chg_code,		price_code,		dest_zone_code,
			posting_code,		recurring_flag,	recurring_code,
			tax_code,		payment_code,		payment_type,
			cust_po_num,		non_ar_flag,		gl_acct_code,
			gl_trx_id,		prompt1_inp,		prompt2_inp,
			prompt3_inp,		prompt4_inp,		deposit_num,
			amt_gross,		amt_freight,		amt_tax,
			amt_discount,		amt_paid_to_date,	amt_net,
			amt_on_acct,		amt_cost,		amt_tot_chg,
			user_id,		void_flag,		paid_flag,
			date_paid,		posted_flag,		commission_flag,
			cash_acct_code,	non_ar_doc_num,	purge_flag,
			process_group_num,	amt_discount_taken,	amt_write_off_given,
			source_trx_ctrl_num,	source_trx_type,	nat_cur_code, 
			rate_type_home,	rate_type_oper,	rate_home,
			rate_oper,		amt_tax_included,	reference_code,
			org_id
		)
		SELECT	doc_ctrl_num,		trx_ctrl_num,		apply_to_num,
			apply_trx_type,	order_ctrl_num,	doc_desc,
			batch_code,		trx_type,		date_entered,
			date_posted,		date_applied,		date_doc,
			date_shipped,		date_required,	date_due,
			date_aging,		customer_code,	ship_to_code,
			salesperson_code,	territory_code,	comment_code,
			fob_code,		freight_code,		terms_code,
			fin_chg_code,		price_code,		dest_zone_code,
			posting_code,		recurring_flag,	recurring_code,
			tax_code,		payment_code,		payment_type,
			cust_po_num,		non_ar_flag,		gl_acct_code,
			gl_trx_id,		prompt1_inp,		prompt2_inp,
			prompt3_inp,		prompt4_inp,		deposit_num,
			amt_gross,		amt_freight,		amt_tax,
			amt_discount,		amt_paid_to_date,	amt_net,
			amt_on_acct,		amt_cost,		amt_tot_chg,
			user_id,		void_flag,		paid_flag,
			date_paid,		posted_flag,		commission_flag,
			cash_acct_code,	non_ar_doc_num,	purge_flag,
			process_group_num,	amt_discount_taken,	amt_write_off_given,
			source_trx_ctrl_num,	source_trx_type,	nat_cur_code,
			rate_type_home,	rate_type_oper,	rate_home,
			rate_oper,		amt_tax_included,	reference_code,
			org_id
		FROM	#artrx_work
		WHERE	db_action > 0
		AND 	db_action < 4
	
		SELECT @status = @@error
	
		IF ( @perf_level >= 2 ) EXEC perf_sp @batch_ctrl_num, 'artrx.cpp', 131, 'insert artrx: update and insert action', @PERF_time_last OUTPUT
	END
	
	IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, 'artrx.cpp', 134, 'exit artrx_sp', @PERF_time_last OUTPUT

	RETURN @status
END
GO
GRANT EXECUTE ON  [dbo].[artrx_sp] TO [public]
GO
