SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROC [dbo].[ARPYInsertTempTables_SP]	@process_ctrl_num	varchar( 16 ),
						@batch_ctrl_num	varchar( 16 ),
						@debug_level		smallint = 0,
                                		@perf_level		smallint = 0	
AS








DECLARE
        @PERF_time_last     datetime

SELECT  @PERF_time_last = GETDATE()

















									







DECLARE
	@result 	int

IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, 'arpyitt.cpp', 132, 'Entering ARPYInsertTempTables_SP', @PERF_time_last OUTPUT

BEGIN
	
	


	

	

	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'arpyitt.cpp' + ', line ' + STR( 143, 5 ) + ' -- ENTRY: '
	IF ( @perf_level >= 2 ) EXEC perf_sp @batch_ctrl_num, 'arpyitt.cpp', 144, 'Start inserting unposted payment headers into #arinppyt_work', @PERF_time_last OUTPUT

    	INSERT #arinppyt_work
    	(	
    		trx_ctrl_num,				doc_ctrl_num,
    		trx_desc,				batch_code,				trx_type,
    		non_ar_flag,				non_ar_doc_num,			gl_acct_code,
    		date_entered,				date_applied,				date_doc,
    		customer_code,			payment_code,				payment_type,
    		amt_payment,				amt_on_acct,				prompt1_inp,
    		prompt2_inp,				prompt3_inp,				prompt4_inp,
		deposit_num,				bal_fwd_flag,				printed_flag,
		posted_flag,				hold_flag,				wr_off_flag,
		on_acct_flag,				user_id,				max_wr_off,
		days_past_due,			void_type,				cash_acct_code,
		origin_module_flag,			db_action,				process_group_num,
		source_trx_ctrl_num,			source_trx_type,			nat_cur_code,
		rate_type_home,			rate_type_oper,			rate_home,
		rate_oper,				amt_discount,				reference_code,		settlement_ctrl_num,
		org_id
	)
	SELECT	trx_ctrl_num,				doc_ctrl_num,
		trx_desc,				batch_code,				trx_type,
		non_ar_flag,				non_ar_doc_num,			gl_acct_code,
		date_entered,				date_applied,				date_doc,
		customer_code,			payment_code,				payment_type,
		amt_payment,				amt_on_acct,				prompt1_inp,
		prompt2_inp,				prompt3_inp,				prompt4_inp,
		deposit_num,				bal_fwd_flag,				printed_flag,
		posted_flag,				hold_flag,				wr_off_flag,
		on_acct_flag,				user_id,				max_wr_off,
		days_past_due,			void_type,				cash_acct_code,
		origin_module_flag,			0,				process_group_num,
		source_trx_ctrl_num,			source_trx_type,			nat_cur_code,
		rate_type_home,			rate_type_oper,			rate_home,
		rate_oper,				amt_discount,				reference_code,		settlement_ctrl_num,
		org_id
	FROM	arinppyt
	WHERE	batch_code = @batch_ctrl_num

	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 2 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'arpyitt.cpp' + ', line ' + STR( 186, 5 ) + ' -- MSG: ' + 'Error inserting into #arinppyt_work'
		IF ( @debug_level > 2 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'arpyitt.cpp' + ', line ' + STR( 187, 5 ) + ' -- MSG: ' + '@@error = ' + STR( @@error, 7 )
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'arpyitt.cpp' + ', line ' + STR( 188, 5 ) + ' -- EXIT: '
        	RETURN 34563
	END
        
	UPDATE #arinppyt_work
	SET org_id = ISNULL((select organization_id from Organization where outline_num = '1'),'')	
	WHERE org_id IS NULL

	    IF( @@error != 0 )
        	RETURN -1
	



	IF ( @perf_level >= 2 ) EXEC perf_sp @batch_ctrl_num, 'arpyitt.cpp', 202, 'Done inserting unposted payment headers into #arinppyt_work', @PERF_time_last OUTPUT

	


	IF ( @perf_level >= 2 ) EXEC perf_sp @batch_ctrl_num, 'arpyitt.cpp', 207, 'Start inserting unposted payment details into #arinppdt_work', @PERF_time_last OUTPUT
	INSERT #arinppdt_work
	(	
		trx_ctrl_num,				doc_ctrl_num,
		sequence_id,				trx_type,					apply_to_num,
		apply_trx_type,			customer_code,				payer_cust_code,
		date_aging,				amt_applied,					amt_disc_taken,
		wr_off_flag,				amt_max_wr_off,				void_flag,
		line_desc,				sub_apply_num,				sub_apply_type,
		amt_tot_chg,				amt_paid_to_date,				terms_code,
		posting_code,				date_doc,					amt_inv,
		db_action,				gain_home,					gain_oper,
		inv_amt_applied,			inv_amt_disc_taken,				inv_amt_max_wr_off,
		inv_cur_code,				writeoff_code,			org_id
	)
	SELECT	d.trx_ctrl_num,			d.doc_ctrl_num,
		d.sequence_id,			d.trx_type,					d.apply_to_num,
		d.apply_trx_type,			d.customer_code,				h.customer_code,
		d.date_aging,				d.amt_applied,				d.amt_disc_taken,	
		d.wr_off_flag,			d.amt_max_wr_off,				d.void_flag,
		d.line_desc,				d.sub_apply_num,				d.sub_apply_type,
		d.amt_tot_chg,			d.amt_paid_to_date,				d.terms_code,
		d.posting_code,			d.date_doc,					d.amt_inv,
		0,				d.gain_home,					d.gain_oper,
		d.inv_amt_applied,			d.inv_amt_disc_taken,			d.inv_amt_max_wr_off,
		d.inv_cur_code,				d.writeoff_code,		d.org_id
	FROM	arinppdt d, #arinppyt_work h
	WHERE	d.trx_ctrl_num = h.trx_ctrl_num
	AND	d.trx_type = h.trx_type

	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 2 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'arpyitt.cpp' + ', line ' + STR( 239, 5 ) + ' -- MSG: ' + 'Error inserting into #arinppdt_work'
		IF ( @debug_level > 2 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'arpyitt.cpp' + ', line ' + STR( 240, 5 ) + ' -- MSG: ' + '@@error = ' + STR( @@error, 7 )
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'arpyitt.cpp' + ', line ' + STR( 241, 5 ) + ' -- EXIT: '
		RETURN 34563
	END

	 
	UPDATE #arinppdt_work
	SET org_id = ISNULL((select organization_id from Organization where outline_num = '1'),'')	
	WHERE org_id IS NULL

	    IF( @@error != 0 )
        	RETURN -1
		

	



	IF EXISTS(	SELECT trx_type
			FROM	#arinppyt_work
			WHERE	trx_type = 2151
		  )
	BEGIN
		UPDATE pbatch
		SET 	start_number = (SELECT COUNT(*) FROM #arinppdt_work),
			start_total = (SELECT ISNULL(SUM(inv_amt_applied),0.0) FROM #arinppdt_work), 
			flag = 1
		WHERE 	batch_ctrl_num = @batch_ctrl_num
		AND 	process_ctrl_num = @process_ctrl_num
	END
	ELSE
	BEGIN
		UPDATE pbatch
		SET 	start_number = (SELECT COUNT(*) FROM #arinppyt_work),
			start_total = (SELECT ISNULL(SUM(amt_payment),0.0) FROM #arinppyt_work),
			flag = 1
		WHERE 	batch_ctrl_num = @batch_ctrl_num
		AND 	process_ctrl_num = @process_ctrl_num
	END

	IF ( @perf_level >= 2 ) EXEC perf_sp @batch_ctrl_num, 'arpyitt.cpp', 280, 'Done inserting unposted payment details into #arinppdt_work', @PERF_time_last OUTPUT


	


	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'arpyitt.cpp' + ', line ' + STR( 286, 5 ) + ' -- ENTRY: '
	IF ( @perf_level >= 2 ) EXEC perf_sp @batch_ctrl_num, 'arpyitt.cpp', 287, 'Start inserting unposted payment details into #arnonardet_work', @PERF_time_last OUTPUT


    	INSERT #arnonardet_work
	(
		trx_ctrl_num,     	trx_type, 		sequence_id,		
		line_desc,		tax_code,		gl_acct_code,		
		unit_price,		extended_price,		reference_code,		
		amt_tax,		qty_shipped,		org_id,	db_action	
	)
	SELECT 	d.trx_ctrl_num,     	d.trx_type,		d.sequence_id,		
		d.line_desc,		d.tax_code,		d.gl_acct_code,		
		d.unit_price,		d.extended_price,	d.reference_code,	
		d.amt_tax,		d.qty_shipped,		d.org_id,	0
	FROM 	arnonardet d, #arinppyt_work h
	WHERE	d.trx_ctrl_num = h.trx_ctrl_num
	AND     h.non_ar_flag = 1

	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 2 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'arpyitt.cpp' + ', line ' + STR( 307, 5 ) + ' -- MSG: ' + 'Error inserting into #arnonardet_work'
		IF ( @debug_level > 2 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'arpyitt.cpp' + ', line ' + STR( 308, 5 ) + ' -- MSG: ' + '@@error = ' + STR( @@error, 7 )
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'arpyitt.cpp' + ', line ' + STR( 309, 5 ) + ' -- EXIT: '
        	RETURN 34563
	END
         
	UPDATE #arnonardet_work
	SET org_id = ISNULL((select organization_id from Organization where outline_num = '1'),'')	
	WHERE org_id IS NULL

	    IF( @@error != 0 )
        	RETURN -1
		
	IF ( @perf_level >= 2 ) EXEC perf_sp @batch_ctrl_num, 'arpyitt.cpp', 320, 'Done inserting unposted payment headers into #arnonardet_work', @PERF_time_last OUTPUT

	


	IF ( @perf_level >= 2 ) EXEC perf_sp @batch_ctrl_num, 'arpyitt.cpp', 325, 'Start inserting unposted payment tax details into #arinptax_work', @PERF_time_last OUTPUT
    	INSERT #arinptax_work
    	(	
		trx_ctrl_num,		trx_type,
		sequence_id,		tax_type_code,		amt_taxable,
		amt_gross,		amt_tax,		amt_final_tax,
		db_action
	)		
    	SELECT                 	
		d.trx_ctrl_num,		d.trx_type,
		d.sequence_id,		d.tax_type_code,	d.amt_taxable,
		d.amt_gross,		d.amt_tax,		d.amt_final_tax,
		0
    	FROM    arinptax d, #arinppyt_work h
    	WHERE   d.trx_ctrl_num = h.trx_ctrl_num
      	AND     d.trx_type     = h.trx_type
	AND     h.non_ar_flag  = 1

    	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'arpyitt.cpp' + ', line ' + STR( 345, 5 ) + ' -- EXIT: '
        	RETURN 34563
	END

	IF ( @perf_level >= 2 ) EXEC perf_sp @batch_ctrl_num, 'arpyitt.cpp', 349, 'Done inserting unposted invoice tax details into #arinptax_work', @PERF_time_last OUTPUT



	IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, 'arpyitt.cpp', 353, 'Leaving ARPYInsertTempTables_SP', @PERF_time_last OUTPUT
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'arpyitt.cpp' + ', line ' + STR( 354, 5 ) + ' -- EXIT: '
	RETURN 0
END
GO
GRANT EXECUTE ON  [dbo].[ARPYInsertTempTables_SP] TO [public]
GO
