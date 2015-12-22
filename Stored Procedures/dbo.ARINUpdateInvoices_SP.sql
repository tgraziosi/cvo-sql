SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO





























  



					  

























































 













































































































































































































































































































































































































































































































































































































































































































CREATE PROC  [dbo].[ARINUpdateInvoices_SP]	@batch_ctrl_num	varchar( 16 ),
					@journal_ctrl_num	varchar( 16 ),
					@debug_level		smallint,
					@perf_level		smallint
AS








DECLARE
        @PERF_time_last     datetime

SELECT  @PERF_time_last = GETDATE()

















									






IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, "arinui.cpp", 33, "Entering ARINUpdateInvoices_SP", @PERF_time_last OUTPUT

DECLARE
	@result	int,
	@system_date	int
	
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arinui.cpp" + ", line " + STR( 40, 5 ) + " -- ENTRY: "

	EXEC appdate_sp @system_date OUTPUT
	
	INSERT	#artrx_work
	(
		trx_ctrl_num,		doc_ctrl_num,		doc_desc,	
		batch_code,		trx_type,		non_ar_flag, 
		apply_to_num,		apply_trx_type,	gl_acct_code,	
		date_posted,		date_applied,		date_doc,	
		gl_trx_id,		customer_code,	payment_code,	
		amt_net,		payment_type,		prompt1_inp,	
		prompt2_inp,		prompt3_inp,		prompt4_inp,	
		deposit_num,		void_flag,		amt_on_acct,
		paid_flag,		user_id,		posted_flag,
		date_entered,		date_paid,		order_ctrl_num,	
		date_shipped,		date_required,	date_due,	
		date_aging,		ship_to_code,		salesperson_code, 
		territory_code,	comment_code,		fob_code,	
		freight_code,		terms_code,		price_code,	
		dest_zone_code,	posting_code,		recurring_flag,	
		recurring_code,	cust_po_num,		amt_gross,	
		amt_freight,		amt_tax,		amt_discount,	
		amt_paid_to_date, 	amt_cost,		amt_tot_chg,	
		fin_chg_code,		tax_code,		commission_flag, 
		cash_acct_code,	non_ar_doc_num,	db_action,
		nat_cur_code,		rate_type_home,	rate_type_oper,
		rate_home,		rate_oper,		amt_discount_taken,
		amt_write_off_given,	source_trx_ctrl_num,	source_trx_type,
		amt_tax_included,	purge_flag,             org_id
	)
	SELECT	trx_ctrl_num,		doc_ctrl_num,		doc_desc,
		batch_code,		trx_type,		0,
		apply_to_num,		apply_trx_type,	" ",
		@system_date,		date_applied,		date_doc,	
		@journal_ctrl_num,	customer_code,	" ",
		amt_net,		0,			" ",
		" ",			" ",			" ",
		" ",			0,			0,
		1 - SIGN(ABS(amt_net)), user_id,		1,
		date_entered,		
					date_applied,			
								order_ctrl_num,	
		date_shipped,		date_required,	date_due,	
		date_aging,		ship_to_code,		salesperson_code, 
		territory_code,	comment_code,		fob_code,	
		freight_code,		terms_code,		price_code,		
		dest_zone_code,	posting_code,		recurring_flag,	
		recurring_code,	cust_po_num,		amt_gross,	
		amt_freight,		amt_tax,		amt_discount,	
		0,			amt_cost,		amt_net,	
		fin_chg_code,		tax_code,		0,		
		" ",			" ",			2,
		nat_cur_code,		rate_type_home,	rate_type_oper,
		rate_home,		rate_oper,		amt_discount_taken,
		amt_write_off_given,	source_trx_ctrl_num,	source_trx_type,
		amt_tax_included,	0,                      org_id
	FROM	#arinpchg_work
	WHERE	batch_code = @batch_ctrl_num
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arinui.cpp" + ", line " + STR( 101, 5 ) + " -- EXIT: "
		RETURN 34563
	END

	


	UPDATE	#arinpchg_work
	SET	db_action = 4
	WHERE	batch_code = @batch_ctrl_num
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arinui.cpp" + ", line " + STR( 113, 5 ) + " -- EXIT: "
		RETURN 34563
	END
	
	



	INSERT	#artrxxtr_work
	(
		rec_set,		amt_due,		amt_paid,
		trx_type,		trx_ctrl_num,		addr1,
		addr2,			addr3,			addr4,
		addr5,			addr6,			ship_addr1,
		ship_addr2,		ship_addr3,		ship_addr4,
		ship_addr5,		ship_addr6,		attention_name,
		attention_phone,customer_country_code,	
		customer_city,	customer_state,	customer_postal_code,
		ship_to_country_code,	ship_to_city,	ship_to_state,
		ship_to_postal_code,	db_action
	)
	SELECT	1,			a.amt_due,		a.amt_paid,
		a.trx_type,		a.trx_ctrl_num,		a.customer_addr1,
		a.customer_addr2,	a.customer_addr3,	a.customer_addr4,
		a.customer_addr5,	a.customer_addr6,	a.ship_to_addr1,
		a.ship_to_addr2,	a.ship_to_addr3,	a.ship_to_addr4,
		a.ship_to_addr5,	a.ship_to_addr6,	a.attention_name,
		a.attention_phone,	b.customer_country_code,	
		b.customer_city,	b.customer_state,	b.customer_postal_code,
		b.ship_to_country_code,	b.ship_to_city,	b.	ship_to_state,
		b.ship_to_postal_code,	2
	FROM	#arinpchg_work a, arinpchg b
	WHERE	a.trx_ctrl_num = b.trx_ctrl_num
		ANd a.trx_type = b.trx_type 
		AND a.batch_code = @batch_ctrl_num

	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arinui.cpp" + ", line " + STR( 142, 5 ) + " -- EXIT: "
		RETURN 34563
	END		
	
	


	INSERT	#artrxtax_work
	(
		trx_type,		doc_ctrl_num,	
		tax_type_code,	date_applied,			amt_gross,	
		amt_taxable,		amt_tax,			date_doc,
		db_action
	)
	SELECT	arinpchg.trx_type,		arinpchg.doc_ctrl_num,
		arinptax.tax_type_code,	arinpchg.date_applied, 	arinptax.amt_gross,	
		arinptax.amt_taxable,	arinptax.amt_final_tax,	arinpchg.date_doc,
		2
	FROM	#arinpchg_work arinpchg, #arinptax_work arinptax
	WHERE	arinpchg.batch_code = @batch_ctrl_num
	AND	arinpchg.trx_ctrl_num = arinptax.trx_ctrl_num
	AND	arinpchg.trx_type = arinptax.trx_type
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arinui.cpp" + ", line " + STR( 166, 5 ) + " -- EXIT: "
		RETURN 34563
	END

	


	UPDATE	#arinptax_work
	SET	db_action = 4
	FROM	#arinpchg_work arinpchg
	WHERE	arinpchg.trx_ctrl_num = #arinptax_work.trx_ctrl_num
	AND	arinpchg.trx_type = #arinptax_work.trx_type
	AND	arinpchg.batch_code = @batch_ctrl_num
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arinui.cpp" + ", line " + STR( 181, 5 ) + " -- EXIT: "
		RETURN 34563
	END
	
	


	INSERT	#artrxcom_work
	(
		trx_ctrl_num,		trx_type,			doc_ctrl_num,	
		sequence_id,		salesperson_code, 		amt_commission, 
		percent_flag,		exclusive_flag,		split_flag,	
		commission_flag,	db_action
	)
	SELECT	arinpchg.trx_ctrl_num,	arinpchg.trx_type,		arinpchg.doc_ctrl_num,
		arinpcom.sequence_id,	arinpcom.salesperson_code, 	arinpcom.amt_commission, 
		arinpcom.percent_flag,	arinpcom.exclusive_flag,	arinpcom.split_flag,	
		0,				2
	FROM	#arinpchg_work arinpchg, #arinpcom_work arinpcom
	WHERE	batch_code = @batch_ctrl_num
	AND	arinpchg.trx_ctrl_num = arinpcom.trx_ctrl_num
	AND	arinpchg.trx_type = arinpcom.trx_type
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arinui.cpp" + ", line " + STR( 205, 5 ) + " -- EXIT: "
		RETURN 34563
	END

	


	UPDATE	#arinpcom_work
	SET	db_action = 4
	FROM	#arinpchg_work arinpchg
	WHERE	arinpchg.trx_ctrl_num = #arinpcom_work.trx_ctrl_num
	AND	arinpchg.trx_type = #arinpcom_work.trx_type
	AND	arinpchg.batch_code = @batch_ctrl_num
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arinui.cpp" + ", line " + STR( 220, 5 ) + " -- EXIT: "
		RETURN 34563
	END
	
	


	INSERT	#artrxage_work
	(
		trx_ctrl_num,			trx_type,			ref_id,  	
		doc_ctrl_num,			apply_to_num,			apply_trx_type,	
		sub_apply_num,		sub_apply_type,		date_doc,	
		date_due,			date_aging,			customer_code,	
		salesperson_code,		territory_code,		price_code,	
		amount,			paid_flag,			group_id,	
		amt_fin_chg,			amt_late_chg,			amt_paid,	
		order_ctrl_num,		cust_po_num,			date_applied,
		db_action,			payer_cust_code,		rate_home,
		rate_oper,			nat_cur_code,			true_amount,
		date_paid,			journal_ctrl_num,		account_code,
		org_id
	)
	SELECT	arinpchg.trx_ctrl_num,	arinpchg.trx_type,		arinpage.sequence_id,    		
		arinpchg.doc_ctrl_num,	arinpage.apply_to_num,	arinpage.apply_trx_type,	
		arinpage.doc_ctrl_num,	arinpage.trx_type,		arinpchg.date_doc,	
		arinpage.date_due,		arinpage.date_aging,		arinpage.customer_code,
		arinpage.salesperson_code,	arinpage.territory_code,	arinpage.price_code,	
		arinpage.amt_due,		1 - SIGN(ABS(arinpage.amt_due)),	0,
		0.0,				0.0,				0.0,		
		arinpchg.order_ctrl_num,	arinpchg.cust_po_num,	arinpchg.date_applied,
		2,		arinpage.customer_code,	arinpchg.rate_home,
		arinpchg.rate_oper,		arinpchg.nat_cur_code,	arinpage.amt_due,
		arinpchg.date_applied,	@journal_ctrl_num,		dbo.IBAcctMask_fn(acct.ar_acct_code,arinpchg.org_id),
        arinpchg.org_id
	FROM	#arinpchg_work arinpchg, #arinpage_work arinpage, araccts acct
	WHERE	arinpchg.batch_code = @batch_ctrl_num
	AND	arinpchg.trx_ctrl_num = arinpage.trx_ctrl_num
	AND	arinpchg.trx_type = arinpage.trx_type
	AND	arinpchg.posting_code = acct.posting_code	
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arinui.cpp" + ", line " + STR( 261, 5 ) + " -- EXIT: "
		RETURN 34563
	END

	
	CREATE TABLE	#master_invoices
	(	
		doc_ctrl_num	varchar( 16 ),
		trx_type	smallint,
		paid_flag	smallint,
		date_paid	int
	)	

	INSERT	#master_invoices
	SELECT	doc_ctrl_num,
		trx_type,
		paid_flag,
		date_paid
	FROM	#artrx_work
	WHERE	apply_to_num = doc_ctrl_num
	AND	apply_trx_type = trx_type
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arinui.cpp" + ", line " + STR( 284, 5 ) + " -- EXIT: "
		RETURN 34563
	END
	
	UPDATE	#artrx_work
	SET	paid_flag = #master_invoices.paid_flag,
		date_paid = #master_invoices.date_paid
	FROM	#master_invoices
	WHERE	#artrx_work.apply_to_num = #master_invoices.doc_ctrl_num
	AND	#artrx_work.apply_trx_type = #master_invoices.trx_type
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arinui.cpp" + ", line " + STR( 296, 5 ) + " -- EXIT: "
		RETURN 34563
	END
	
	DROP TABLE #master_invoices
		
	UPDATE	#artrxage_work
	SET	paid_flag = #artrx_work.paid_flag,
		date_paid = #artrx_work.date_paid
	FROM	#artrx_work
	WHERE	#artrx_work.doc_ctrl_num = #artrxage_work.apply_to_num
	AND	#artrx_work.trx_type = #artrxage_work.apply_trx_type
	AND	#artrx_work.doc_ctrl_num = #artrx_work.apply_to_num
	AND	#artrx_work.trx_type = #artrx_work.apply_trx_type
	AND	#artrxage_work.trx_type <= 2031
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arinui.cpp" + ", line " + STR( 313, 5 ) + " -- EXIT: "
		RETURN 34563
	END
	
	


	UPDATE	#arinpage_work
	SET	db_action = 4
	FROM	#arinpchg_work arinpchg
	WHERE	arinpchg.trx_ctrl_num = #arinpage_work.trx_ctrl_num
	AND	arinpchg.trx_type = #arinpage_work.trx_type
	AND	arinpchg.batch_code = @batch_ctrl_num
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arinui.cpp" + ", line " + STR( 328, 5 ) + " -- EXIT: "
		RETURN 34563
	END
	
	INSERT #artrxrev_work
	(
		trx_ctrl_num,			sequence_id,			rev_acct_code, 
		apply_amt, 			trx_type,			reference_code,
		db_action,			org_id
	)
	SELECT	arinpchg.trx_ctrl_num,	arinprev.sequence_id,	arinprev.rev_acct_code,	
		arinprev.apply_amt,		arinpchg.trx_type,		reference_code,
		2,       arinprev.org_id
	FROM	#arinpchg_work arinpchg, #arinprev_work arinprev
	WHERE	arinpchg.batch_code = @batch_ctrl_num
	AND	arinpchg.trx_ctrl_num = arinprev.trx_ctrl_num
	AND	arinpchg.trx_type = arinprev.trx_type
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arinui.cpp" + ", line " + STR( 347, 5 ) + " -- EXIT: "
		RETURN 34563
	END
	


	UPDATE	#arinprev_work
	SET	db_action = 4
	FROM	#arinpchg_work arinpchg
	WHERE	arinpchg.trx_ctrl_num = #arinprev_work.trx_ctrl_num
	AND	arinpchg.trx_type = #arinprev_work.trx_type
	AND	arinpchg.batch_code = @batch_ctrl_num
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arinui.cpp" + ", line " + STR( 361, 5 ) + " -- EXIT: "
		RETURN 34563
	END
	
	

	
	INSERT	#artrxcdt_work
	(
		doc_ctrl_num,			trx_ctrl_num, 		sequence_id,	
		trx_type,			location_code,		item_code, 
		bulk_flag, 			date_entered,			date_posted, 
		date_applied,			line_desc, 			qty_ordered,
		qty_shipped, 			unit_code,			unit_price,	
		weight,			amt_cost, 			serial_id,	
		tax_code, 			gl_rev_acct,			discount_prc,	
		discount_amt,			rma_num,			return_code,
		qty_returned,			new_gl_rev_acct, 		disc_prc_flag,		
		extended_price,		db_action,			calc_tax,
		reference_code,			cust_po,		org_id
	)
	SELECT	arinpchg.doc_ctrl_num,	arinpchg.trx_ctrl_num,	arinpcdt.sequence_id,	
		arinpchg.trx_type,		arinpcdt.location_code,	arinpcdt.item_code,	
		arinpcdt.bulk_flag,		arinpcdt.date_entered,	@system_date,	
		arinpchg.date_applied,	arinpcdt.line_desc,		arinpcdt.qty_ordered,
		arinpcdt.qty_shipped,	arinpcdt.unit_code,		arinpcdt.unit_price,	
		arinpcdt.weight,		arinpcdt.unit_cost*arinpcdt.qty_shipped,				arinpcdt.serial_id,	
		arinpcdt.tax_code,		arinpcdt.gl_rev_acct,	arinpcdt.discount_prc,
		arinpcdt.discount_amt,	arinpcdt.rma_num,		arinpcdt.return_code,
		0.0, 				arinpcdt.new_gl_rev_acct,	arinpcdt.disc_prc_flag,	
		arinpcdt.extended_price,	2,		arinpcdt.calc_tax,
		arinpcdt.reference_code,	arinpcdt.cust_po,   arinpcdt.org_id
	FROM	#arinpchg_work arinpchg, #arinpcdt_work arinpcdt
	WHERE	arinpchg.batch_code = @batch_ctrl_num
	AND	arinpchg.trx_ctrl_num = arinpcdt.trx_ctrl_num
	AND	arinpchg.trx_type = arinpcdt.trx_type
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arinui.cpp" + ", line " + STR( 399, 5 ) + " -- EXIT: "
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
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arinui.cpp" + ", line " + STR( 414, 5 ) + " -- EXIT: "
		RETURN 34563
	END
	
	IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, "arinui.cpp", 418, "Leaving ARINUpdateInvoices_SP", @PERF_time_last OUTPUT
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arinui.cpp" + ", line " + STR( 419, 5 ) + " -- EXIT: "
	RETURN 0
END
GO
GRANT EXECUTE ON  [dbo].[ARINUpdateInvoices_SP] TO [public]
GO
