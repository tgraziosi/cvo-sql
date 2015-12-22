SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROC [dbo].[ARINInsertTempTables_SP]	@process_ctrl_num	varchar( 16 ),
						@batch_ctrl_num	varchar( 16 ),
						@debug_level		smallint = 0,
                                		@perf_level		smallint = 0	
AS








DECLARE
        @PERF_time_last     datetime

SELECT  @PERF_time_last = GETDATE()

















									







DECLARE
    @result 	int

IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, "arinitt.cpp", 139, "Entering ARINInsertTempTables_SP", @PERF_time_last OUTPUT

BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arinitt.cpp" + ", line " + STR( 142, 5 ) + " -- ENTRY: "

		
	


	IF ( @perf_level >= 2 ) EXEC perf_sp @batch_ctrl_num, "arinitt.cpp", 148, "Start inserting unposted invoice headers into #arinpchg_work", @PERF_time_last OUTPUT
	INSERT #arinpchg_work
	(
		trx_ctrl_num,		doc_ctrl_num,
		doc_desc,		apply_to_num,		apply_trx_type,
		order_ctrl_num,	batch_code,    	trx_type,
		date_entered,		date_applied,		date_doc,
		date_shipped,		date_required,	date_due,
		date_aging,	    	customer_code,   	ship_to_code,
	    	salesperson_code,	territory_code,	comment_code,
		fob_code,		freight_code,		terms_code,
		fin_chg_code,		price_code,		dest_zone_code,
		posting_code,	    	recurring_flag,	recurring_code,
		tax_code,	    	cust_po_num,		total_weight,
	    	amt_gross,	    	amt_freight,	   
	    	amt_tax,	    	amt_discount,		amt_net,		
	    	amt_paid,		amt_due,		amt_cost,		
	    	amt_profit,		next_serial_id,	printed_flag,		
	    	posted_flag,		hold_flag,		hold_desc,		
	    	user_id,		customer_addr1,	customer_addr2,	
	    	customer_addr3,	customer_addr4,	customer_addr5,	
	    	customer_addr6,	ship_to_addr1,	ship_to_addr2,	
	    	ship_to_addr3,	ship_to_addr4,	ship_to_addr5,	
	    	ship_to_addr6,	attention_name,	attention_phone,	
	    	amt_rem_rev,		amt_rem_tax,		date_recurring,	
	    	location_code,	db_action,		source_trx_ctrl_num,	
	    	source_trx_type,	amt_discount_taken,	amt_write_off_given,
		nat_cur_code,		rate_type_home,	rate_type_oper,   
		rate_home,		rate_oper,		edit_list_flag,
		amt_tax_included,       org_id,
		customer_city , customer_state , customer_postal_code, 	customer_country_code,
		ship_to_city, 	ship_to_state, 	ship_to_postal_code, ship_to_country_code 
	)
	SELECT
		trx_ctrl_num,		doc_ctrl_num,
		doc_desc,		apply_to_num,		apply_trx_type,
		order_ctrl_num,	batch_code,    	trx_type,
		date_entered,		date_applied,		date_doc,
		date_shipped,		date_required,	date_due,
		date_aging,	    	customer_code,    	ship_to_code,
	    	salesperson_code,	territory_code,	comment_code,
		fob_code,		freight_code,		terms_code,
		fin_chg_code,		price_code,		dest_zone_code,
		posting_code,	    	recurring_flag,	recurring_code,
		tax_code,	    	cust_po_num,		total_weight,
	    	amt_gross,	      	amt_freight,	
	    	amt_tax,	    	amt_discount,		amt_net,		
	    	amt_paid,		amt_due,		amt_cost,		
	    	amt_profit,		next_serial_id,	printed_flag,		
	    	posted_flag,		hold_flag,		hold_desc,		
	    	user_id,		customer_addr1,	customer_addr2,	
	    	customer_addr3,	customer_addr4,	customer_addr5,	
	    	customer_addr6,	ship_to_addr1,	ship_to_addr2,	
	    	ship_to_addr3,	ship_to_addr4,	ship_to_addr5,	
	    	ship_to_addr6,	attention_name,	attention_phone,	
	    	amt_rem_rev,		amt_rem_tax,		date_recurring,	
	    	location_code,	0,		source_trx_ctrl_num,	
	    	source_trx_type,	amt_discount_taken,	amt_write_off_given,
		nat_cur_code,		rate_type_home,	rate_type_oper,   
		rate_home,		rate_oper,		edit_list_flag,
		amt_tax_included,       org_id,
		customer_city , customer_state , customer_postal_code, 	customer_country_code,
		ship_to_city, 	ship_to_state, 	ship_to_postal_code, ship_to_country_code 
	FROM	arinpchg
	WHERE	batch_code = @batch_ctrl_num
    	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arinitt.cpp" + ", line " + STR( 211, 5 ) + " -- EXIT: "
        	RETURN 34563
	END
	IF ( @perf_level >= 2 ) EXEC perf_sp @batch_ctrl_num, "arinitt.cpp", 214, "Done inserting unposted invoice headers into #arinpchg_work", @PERF_time_last OUTPUT

	IF ( @perf_level >= 2 ) EXEC perf_sp @batch_ctrl_num, "arinitt.cpp", 216, "Start inserting unposted invoice detail into #arinpcdt_work", @PERF_time_last OUTPUT
	INSERT #arinpcdt_work
	(
		trx_ctrl_num,		doc_ctrl_num,
		sequence_id,		trx_type,		location_code,
		item_code,		bulk_flag,		date_entered,
		line_desc,		qty_ordered,		qty_shipped,							
		unit_code,		unit_price,		unit_cost,
		weight,		serial_id,		tax_code,			
		gl_rev_acct,		disc_prc_flag,	discount_amt,		
		discount_prc,		commission_flag,	rma_num,		
		return_code,		qty_returned,		qty_prev_returned,	
		new_gl_rev_acct,	iv_post_flag,		oe_orig_flag,		
		db_action,		extended_price,	calc_tax,
		reference_code,		cust_po,		org_id
	)
	SELECT
		d.trx_ctrl_num,	d.doc_ctrl_num,
		d.sequence_id,	d.trx_type,		d.location_code,
		d.item_code,		d.bulk_flag,		d.date_entered,
		d.line_desc,		d.qty_ordered,	d.qty_shipped,			
		d.unit_code,		d.unit_price,		d.unit_cost,
		d.weight,		d.serial_id,		d.tax_code,		
		d.gl_rev_acct,	d.disc_prc_flag,	d.discount_amt,	
		d.discount_prc,	d.commission_flag,	d.rma_num,		
		d.return_code,	d.qty_returned, 	d.qty_prev_returned,	
		d.new_gl_rev_acct,	d.iv_post_flag,	d.oe_orig_flag,	
		0,		d.extended_price,	d.calc_tax,
		d.reference_code,	d.cust_po,		d.org_id
	FROM	arinpcdt d, #arinpchg_work h
    	WHERE  d.trx_ctrl_num = h.trx_ctrl_num 
      	AND   	d.trx_type = h.trx_type
    	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arinitt.cpp" + ", line " + STR( 250, 5 ) + " -- EXIT: "
        	RETURN 34563
	END
	IF ( @perf_level >= 2 ) EXEC perf_sp @batch_ctrl_num, "arinitt.cpp", 253, "Done inserting unposted invoice headers into #arinpcdt_work", @PERF_time_last OUTPUT

	


	IF ( @perf_level >= 2 ) EXEC perf_sp @batch_ctrl_num, "arinitt.cpp", 258, "Start inserting unposted invoice aging details into #arinpage_work", @PERF_time_last OUTPUT
	INSERT #arinpage_work
    	(	
		trx_ctrl_num,		sequence_id,
		doc_ctrl_num,		apply_to_num,		apply_trx_type,
		trx_type,		date_applied,		date_due,
		date_aging,		customer_code,	salesperson_code,
		territory_code,	price_code,		amt_due,
		db_action
	)
    	SELECT                 	
		d.trx_ctrl_num,	d.sequence_id,
		d.doc_ctrl_num,	d.apply_to_num,	d.apply_trx_type,
		d.trx_type,		d.date_applied,	d.date_due,
		d.date_aging,		d.customer_code,	d.salesperson_code,
		d.territory_code,	d.price_code,		d.amt_due,
		0
    	FROM   arinpage d, #arinpchg_work h
    	WHERE  d.trx_ctrl_num = h.trx_ctrl_num
    	AND   	d.trx_type = h.trx_type
    	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arinitt.cpp" + ", line " + STR( 280, 5 ) + " -- EXIT: "
        	RETURN 34563
	END
	IF ( @perf_level >= 2 ) EXEC perf_sp @batch_ctrl_num, "arinitt.cpp", 283, "Done inserting unposted invoice aging details into #arinpage_work", @PERF_time_last OUTPUT

	


	IF ( @perf_level >= 2 ) EXEC perf_sp @batch_ctrl_num, "arinitt.cpp", 288, "Start inserting unposted invoice revenue details into #arinprev_work", @PERF_time_last OUTPUT
	INSERT #arinprev_work
    	(	
		trx_ctrl_num,		sequence_id,
		rev_acct_code,	apply_amt,			
		trx_type,		reference_code, 
		db_action,      org_id
	)		
    	SELECT                 	
		d.trx_ctrl_num,	d.sequence_id,
		d.rev_acct_code,	d.apply_amt,		
		d.trx_type,		reference_code,
		0,   d.org_id
    	FROM	arinprev d, #arinpchg_work h
    	WHERE	d.trx_ctrl_num = h.trx_ctrl_num
      	AND	d.trx_type = h.trx_type
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arinitt.cpp" + ", line " + STR( 306, 5 ) + " -- EXIT: "
        	RETURN 34563
	END
	IF ( @perf_level >= 2 ) EXEC perf_sp @batch_ctrl_num, "arinitt.cpp", 309, "Done inserting unposted invoice revenue details into #arinprev_work", @PERF_time_last OUTPUT

	


	IF ( @perf_level >= 2 ) EXEC perf_sp @batch_ctrl_num, "arinitt.cpp", 314, "Start inserting unposted invoice tax details into #arinptax_work", @PERF_time_last OUTPUT
    	INSERT #arinptax_work
    	(	
		trx_ctrl_num,		trx_type,
		sequence_id,		tax_type_code,	amt_taxable,
		amt_gross,		amt_tax,		amt_final_tax,
		db_action
	)		
    	SELECT                 	
		d.trx_ctrl_num,	d.trx_type,
		d.sequence_id,	d.tax_type_code,	d.amt_taxable,
		d.amt_gross,		
		d.amt_tax,		
		d.amt_final_tax,
		0
    	FROM   arinptax d, #arinpchg_work h
    	WHERE  d.trx_ctrl_num = h.trx_ctrl_num
      	AND   	d.trx_type = h.trx_type
    	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arinitt.cpp" + ", line " + STR( 334, 5 ) + " -- EXIT: "
        	RETURN 34563
	END
	IF ( @perf_level >= 2 ) EXEC perf_sp @batch_ctrl_num, "arinitt.cpp", 337, "Done inserting unposted invoice tax details into #arinptax_work", @PERF_time_last OUTPUT

	



	EXEC @result = ARINInsertDetailTables_SP	@batch_ctrl_num,
							@debug_level,
							@perf_level
	IF( @result != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arinitt.cpp" + ", line " + STR( 348, 5 ) + " -- EXIT: "
		RETURN 34563
	END

	UPDATE pbatch
	SET 	start_number = (SELECT COUNT(*) FROM #arinpchg_work),
		start_total = (SELECT ISNULL(SUM(amt_net),0.0) FROM #arinpchg_work),
		flag = 1
	WHERE 	batch_ctrl_num = @batch_ctrl_num
	AND 	process_ctrl_num = @process_ctrl_num
	
	IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, "arinitt.cpp", 359, "Leaving ARINInsertTempTables_SP", @PERF_time_last OUTPUT
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arinitt.cpp" + ", line " + STR( 360, 5 ) + " -- EXIT: "
    	RETURN 0
END
GO
GRANT EXECUTE ON  [dbo].[ARINInsertTempTables_SP] TO [public]
GO
