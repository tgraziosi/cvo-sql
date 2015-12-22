SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO





























  



					  

























































 














































































































































































































































































































































































































































































































































































































































































































CREATE PROC [dbo].[ARCAMoveUnpostedRecords_SP]	@batch_ctrl_num	varchar(16),
						@debug_level		smallint,
						@perf_level		smallint

AS








DECLARE
        @PERF_time_last     datetime

SELECT  @PERF_time_last = GETDATE()

















									







DECLARE
	@result		int,
	@sys_date		int,
	@deposit_num		varchar( 16 ),
	@posted_flag		smallint

	
SELECT	@deposit_num = SPACE( 16 ),
	@posted_flag = 1


IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, 'arcamur.cpp', 87, 'Entering ARCAMoveUnpostedRecords_SP', @PERF_time_last OUTPUT

BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'arcamur.cpp' + ', line ' + STR( 90, 5 ) + ' -- ENTRY: '

	



	EXEC appdate_sp @sys_date OUTPUT

	


	INSERT	#artrxpdt_work 
	(
   		doc_ctrl_num,		trx_ctrl_num,		sequence_id,	
   		gl_trx_id,  		customer_code,	trx_type,	
   		apply_trx_type,	apply_to_num,		date_aging,	
   		date_applied,		amt_applied,		amt_disc_taken,	
   		amt_wr_off,		void_flag,		line_desc,	
   		posted_flag,		sub_apply_type,	sub_apply_num,	
   		amt_tot_chg,		amt_paid_to_date,	terms_code,	
   		posting_code,		db_action,		gain_home,	
		gain_oper,		inv_amt_applied,	inv_amt_disc_taken,
		inv_amt_wr_off,	inv_cur_code,		payer_cust_code,
		writeoff_code,		org_id
   	)
   	SELECT	
   		pyt.doc_ctrl_num,		pyt.trx_ctrl_num,	pdt.sequence_id,	
   		tmp.journal_ctrl_num,	pdt.customer_code,	pyt.trx_type,	
		pdt.apply_trx_type,		pdt.apply_to_num,	pdt.date_aging,	
		pyt.date_applied,		pdt.amt_applied,  	pdt.amt_disc_taken,	
		pdt.amt_max_wr_off,		0,			pdt.line_desc,	
		@posted_flag,			pdt.sub_apply_type,	pdt.sub_apply_num,	
		pdt.amt_tot_chg,		0.0,			pdt.terms_code,	
		pdt.posting_code,		2,	pdt.gain_home,
		pdt.gain_oper,		pdt.inv_amt_applied,	pdt.inv_amt_disc_taken,
		pdt.inv_amt_max_wr_off,	pdt.inv_cur_code,	pyt.customer_code,
		pdt.writeoff_code,		pdt.org_id	
	FROM	#arinppdt_work pdt, #arcatemp tmp, #arinppyt_work pyt
	WHERE	pdt.trx_ctrl_num = tmp.trx_ctrl_num
	AND	pdt.trx_ctrl_num = pyt.trx_ctrl_num
	AND	pyt.batch_code = @batch_ctrl_num 	
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'arcamur.cpp' + ', line ' + STR( 133, 5 ) + ' -- EXIT: '
		RETURN 34563
	END	

	SELECT 'Dumping artrxpdt_work records after moving unposted records'
	SELECT ' doc_ctrl_num = ' + doc_ctrl_num +
		' trx_type = ' + STR(trx_type,6) +
		' customer_code = ' + customer_code +
		' void_flag = ' + STR(void_flag,2) +
		' amt_applied = ' + STR(amt_applied, 10,2) +
		' db_action = ' + STR(db_action,2)
	FROM #artrxpdt_work


	


 
	INSERT	#artrx_work 
	(
		trx_ctrl_num, 	   	doc_ctrl_num, 		doc_desc, 
		batch_code, 	 		trx_type,			non_ar_flag, 
		apply_to_num, 	   	apply_trx_type, 		gl_acct_code, 
		date_posted, 			date_applied, 		date_doc, 
		gl_trx_id, 			customer_code, 		payment_code, 
		amt_net, 			payment_type, 		prompt1_inp, 
		prompt2_inp, 			prompt3_inp, 			prompt4_inp, 
		deposit_num, 			void_flag, 			amt_on_acct, 
		paid_flag, 			user_id, 			posted_flag, 
		date_entered,			date_paid, 			cash_acct_code, 
		non_ar_doc_num, 		order_ctrl_num, 		date_shipped, 
		date_required, 		date_due, 			date_aging,
		ship_to_code, 		salesperson_code, 		territory_code, 
		comment_code, 		fob_code, 			freight_code, 
		terms_code, 			price_code, 			dest_zone_code, 
		posting_code, 		recurring_flag, 		recurring_code, 
		cust_po_num, 			amt_gross, 			amt_freight, 
		amt_tax, 			amt_discount, 		amt_paid_to_date, 
		amt_cost, 			amt_tot_chg, 			fin_chg_code, 
		tax_code, 			commission_flag, 		purge_flag, 
		db_action,			source_trx_ctrl_num,		source_trx_type,
		amt_discount_taken,		amt_write_off_given,		nat_cur_code, 
		rate_type_home,		rate_type_oper,		rate_home,
		rate_oper,			amt_tax_included,		reference_code,
		org_id
	)
	SELECT	
		pyt.trx_ctrl_num, 		doc_ctrl_num, 		trx_desc, 
		batch_code, 			pyt.trx_type, 		non_ar_flag, 
		' ', 				0, 				gl_acct_code, 
		@sys_date, 			date_applied, 		date_doc, 
		tmp.journal_ctrl_num, 	customer_code, 		payment_code, 
		amt_payment,			payment_type, 		prompt1_inp, 
		prompt2_inp, 			prompt3_inp, 			prompt4_inp, 
		@deposit_num, 		0, 				amt_on_acct, 
		0, 				user_id, 			@posted_flag, 
 		date_entered, 		0, 				cash_acct_code, 
		non_ar_doc_num, 		' ', 				0, 
		0, 				0, 				0, 
		' ', 				' ', 				' ', 
		' ', 				' ', 				' ', 
		' ',				' ',				' ', 
		' ', 				0, 				' ', 
		' ', 				0, 				0, 
		0, 				0, 				0, 
		0, 				0.0, 				' ', 
		' ', 				0, 				0, 
		2,		pyt.source_trx_ctrl_num,	pyt.source_trx_type,
		0.0,				0.0,				pyt.nat_cur_code,
		pyt.rate_type_home,		pyt.rate_type_oper,		pyt.rate_home,
		pyt.rate_oper,		0.0,				pyt.reference_code,
		pyt.org_id
	FROM	#arinppyt_work pyt, #arcatemp tmp
	WHERE	pyt.trx_ctrl_num = tmp.trx_ctrl_num
	AND	pyt.batch_code = @batch_ctrl_num
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'arcamur.cpp' + ', line ' + STR( 210, 5 ) + ' -- EXIT: '
		RETURN 34563
	END
	SELECT 'Dumping artrx_work records after moving unposted records'
	SELECT	'doc_ctrl_num = ' + doc_ctrl_num +
		' org_id = ' + org_id +
		' trx_type = ' + STR(trx_type,6) +
		' customer_code = ' + customer_code +
		' amt_net = ' + STR(amt_net,10,2) +
		' void_flag = ' + STR(void_flag,2) +
		' amt_on_acct = ' + STR(amt_on_acct, 10,2) +
		' paid_flag = ' + STR(paid_flag, 2) +
		' db_action = ' + STR(db_action,2)
	FROM #artrx_work




	INSERT #artrxndet_work (trx_ctrl_num,		trx_type,		sequence_id,		line_desc,		
				tax_code,		gl_acct_code,		unit_price,		extended_price,		
				reference_code,		amt_tax,		qty_shipped,		org_id, 	db_action
					)
	SELECT 			det.trx_ctrl_num, 	det.trx_type,		det.sequence_id,	det.line_desc,		
				det.tax_code,		det.gl_acct_code,	det.unit_price,		det.extended_price,	
				det.reference_code,	det.amt_tax,		det.qty_shipped,	det.org_id,	2
	FROM	#arinppyt_work pyt, 	#arnonardet_work det
	WHERE	pyt.trx_ctrl_num	= det.trx_ctrl_num
	AND	pyt.trx_type		= det.trx_type
	AND	pyt.batch_code 		= @batch_ctrl_num

	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'arcamur.cpp' + ', line ' + STR( 242, 5 ) + ' -- EXIT: '
		RETURN 34563
	END
	

	



	


	INSERT	#artrxtax_work
	(
		trx_type,		doc_ctrl_num,	
		tax_type_code,		date_applied,		amt_gross,	
		amt_taxable,		amt_tax,		date_doc,
		db_action
	)
	SELECT	pyt.trx_type,		pyt.trx_ctrl_num,	
		arinptax.tax_type_code,	pyt.date_applied, 	arinptax.amt_gross,	
		arinptax.amt_taxable,	arinptax.amt_final_tax,	pyt.date_doc,
		2
	FROM	#arinppyt_work pyt, #arinptax_work arinptax
	WHERE	pyt.batch_code 		= @batch_ctrl_num
	AND	pyt.trx_ctrl_num 	= arinptax.trx_ctrl_num
	AND	pyt.trx_type 		= arinptax.trx_type	

	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'arcamur.cpp' + ', line ' + STR( 272, 5 ) + ' -- EXIT: '
		RETURN 34563
	END



	







	UPDATE #arinppdt_work
	SET	db_action = pdt.db_action | 4,
		trx_type = 2121
	FROM 	#arinppyt_work pyt, #arinppdt_work pdt
	WHERE	pyt.trx_ctrl_num = pdt.trx_ctrl_num
	AND	pyt.trx_type = pdt.trx_type
	AND	pyt.batch_code = @batch_ctrl_num



	UPDATE 	#arinptax_work
	SET	#arinptax_work.db_action = 4, 
		#arinptax_work.trx_type = 2121
	FROM	#arinppyt_work pyt
	WHERE	#arinptax_work.trx_ctrl_num = pyt.trx_ctrl_num
	AND	pyt.batch_code = @batch_ctrl_num


	UPDATE 	#arnonardet_work
	SET	#arnonardet_work.db_action = 4, 
		#arnonardet_work.trx_type = 2121	
	FROM	#arinppyt_work pyt
	WHERE	#arnonardet_work.trx_ctrl_num = pyt.trx_ctrl_num
	AND	pyt.batch_code = @batch_ctrl_num




	UPDATE #arinppyt_work
	SET	db_action = db_action | 4,
		trx_type = 2121
	FROM 	#arinppyt_work 
	WHERE	batch_code = @batch_ctrl_num

	SELECT ' dumping arinppyt_work after setting dbaction to delete'
	SELECT 'doc_ctrl_num = ' + doc_ctrl_num +
		'trx_type = ' + STR(trx_type,6) +
		'batch_code = ' + batch_code +
		'posted_flag = ' + STR(posted_flag,2)
	FROM	#arinppyt_work


	IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, 'arcamur.cpp', 330, 'Leaving ARCAMoveUnpostedRecords_SP', @PERF_time_last OUTPUT

    RETURN 0 

END

GO
GRANT EXECUTE ON  [dbo].[ARCAMoveUnpostedRecords_SP] TO [public]
GO
