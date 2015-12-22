SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROC [dbo].[ARWOInsertDependancies_SP]	@batch_ctrl_num	varchar( 16 ),
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


IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, "arwoid.cpp", 54, "Entering ARWOInsertDependancies_SP", @PERF_time_last OUTPUT

BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arwoid.cpp" + ", line " + STR( 57, 5 ) + " -- ENTRY: "
	








	IF ( @perf_level >= 2 ) EXEC perf_sp @batch_ctrl_num, "arwoid.cpp", 67, "Start inserting records into #artrx_work", @PERF_time_last OUTPUT

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
		amt_tax_included,	org_id
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
		amt_tax_included,	org_id
	FROM	artrx
	WHERE	process_group_num = @process_ctrl_num

	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 2 ) SELECT CONVERT(char,getdate(),109) + "  " + "arwoid.cpp" + ", line " + STR( 126, 5 ) + " -- MSG: " + "Error inserting in #artrx_work: @@error = " + STR( @@error, 7)
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arwoid.cpp" + ", line " + STR( 127, 5 ) + " -- EXIT: "
		RETURN 34563
	END
	IF ( @perf_level >= 2 ) EXEC perf_sp @batch_ctrl_num, "arwoid.cpp", 130, "Done inserting into #artrx_work", @PERF_time_last OUTPUT

	IF ( @perf_level >= 2 ) EXEC perf_sp @batch_ctrl_num, "arwoid.cpp", 132, "Start inserting dependent transactions into #artrxage_work", @PERF_time_last OUTPUT
	


	SELECT a0.doc_ctrl_num, a0.trx_type, MAX(a0.date_aging) date_aging_max
	INTO #artrxage_max_age
	FROM artrxage a0, #artrx_work a1
	WHERE	a0.doc_ctrl_num = a1.doc_ctrl_num
	AND	a0.trx_type = a1.trx_type
	GROUP BY a0.doc_ctrl_num, a0.trx_type 



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
		a0.trx_ctrl_num,	a0.trx_type,
		a0.ref_id,		a0.doc_ctrl_num,	a0.order_ctrl_num,
		a0.cust_po_num,	a0.apply_to_num,	a0.apply_trx_type,
		a0.sub_apply_num,	a0.sub_apply_type,	a0.date_doc,
		a0.date_due,		a0.date_applied,	a0.date_aging,
		a0.customer_code,	a1.customer_code,	a0.salesperson_code,
		a0.territory_code,	a0.price_code,		a2.inv_amt_applied,
		a0.paid_flag,		a0.group_id,		a0.amt_fin_chg,
		a0.amt_late_chg,	a0.amt_paid,		0,
		a0.rate_home,		a0.rate_oper,		a0.nat_cur_code,
		a0.amount,		a0.date_paid,		a0.journal_ctrl_num,
		a0.account_code,	a0.org_id
	FROM	artrxage a0, #artrx_work a1, #arinppdt_work a2, #artrxage_max_age a3
	WHERE	a0.doc_ctrl_num = a1.doc_ctrl_num
	AND	a0.trx_type = a1.trx_type
	AND	a0.doc_ctrl_num = a3.doc_ctrl_num
	AND	a0.trx_type = a3.trx_type
	AND	a0.doc_ctrl_num = a2.apply_to_num
	AND 	a0.date_aging = a3.date_aging_max

	DROP TABLE #artrxage_max_age

	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 2 ) SELECT CONVERT(char,getdate(),109) + "  " + "arwoid.cpp" + ", line " + STR( 185, 5 ) + " -- MSG: " + "Error inserting in #artrxage_work: @@error = " + STR( @@error, 7)
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arwoid.cpp" + ", line " + STR( 186, 5 ) + " -- EXIT: "
		RETURN 34563
	END

	IF ( @perf_level >= 2 ) EXEC perf_sp @batch_ctrl_num, "arwoid.cpp", 190, "Done inserting dependent transactions into #artrxage_work", @PERF_time_last OUTPUT

	IF (@debug_level > 2)
	BEGIN
		SELECT "#######################################"
		SELECT 	"artrx_work"
		SELECT 	" trx_ctrl_num = " + trx_ctrl_num +
				" doc_ctrl_num = " + doc_ctrl_num +
				" trx_type = " + STR(trx_type,6) +
				" customer_code = " + customer_code	+
				" amt_net = " + STR(amt_net,10,2) +
				" amt_paid_to_date = " + STR(amt_paid_to_date,10,2)
		FROM #artrx_work

		SELECT 	"artrxage_work"
		SELECT 	" trx_ctrl_num = " + trx_ctrl_num +
				" doc_ctrl_num = " + doc_ctrl_num +
				" apply_to_num = " + apply_to_num +
				" trx_type = " + STR(trx_type,6) +
				" customer_code = " + customer_code	+
				" amount = " + STR(amount,10,2)
		FROM #artrxage_work
		SELECT "#######################################"

	END

	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arwoid.cpp" + ", line " + STR( 216, 5 ) + " -- EXIT: "
	IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, "arwoid.cpp", 217, "Leaving ARCAInsertDependancies_SP", @PERF_time_last OUTPUT
	RETURN 0
END
GO
GRANT EXECUTE ON  [dbo].[ARWOInsertDependancies_SP] TO [public]
GO
