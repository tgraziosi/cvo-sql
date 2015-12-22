SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROC [dbo].[ARIAInsertTempTables_SP]	@process_ctrl_num	varchar( 16 ),
						@batch_ctrl_num	varchar( 16 ),
						@debug_level		smallint = 0,
                                		@perf_level		smallint = 0	
AS








DECLARE
        @PERF_time_last     datetime

SELECT  @PERF_time_last = GETDATE()

















									







DECLARE
    @result 	int

IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, 'ariaitt.cpp', 55, 'Entering ARIAInsertTempTables_SP', @PERF_time_last OUTPUT

BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'ariaitt.cpp' + ', line ' + STR( 58, 5 ) + ' -- ENTRY: '

	


	IF ( @perf_level >= 2 ) EXEC perf_sp @batch_ctrl_num, 'ariaitt.cpp', 63, 'Start inserting unposted invoice headers into #arinpchg_work', @PERF_time_last OUTPUT
	INSERT #arinpchg_work
	(
		trx_ctrl_num,		doc_ctrl_num,		doc_desc,
		apply_to_num,		apply_trx_type,	order_ctrl_num,
		batch_code,    	trx_type,		date_entered,
		date_applied,		date_doc,		date_shipped,
		date_required,	date_due,		date_aging,
		customer_code,   	ship_to_code,		salesperson_code,
		territory_code,	comment_code,		fob_code,
		freight_code,		terms_code,		fin_chg_code,
		price_code,		dest_zone_code,	posting_code,
		recurring_flag,	recurring_code,	tax_code,
		cust_po_num,		total_weight,		amt_gross,
	    	amt_freight,		amt_tax,		amt_discount,
		amt_net,		amt_paid,		amt_due,
		amt_cost,		amt_profit,		next_serial_id,
		printed_flag,		posted_flag,		hold_flag,
		hold_desc,		user_id,		customer_addr1,
		customer_addr2,	customer_addr3,	customer_addr4,
		customer_addr5,	customer_addr6,	ship_to_addr1,
		ship_to_addr2,	ship_to_addr3,	ship_to_addr4,
		ship_to_addr5,	ship_to_addr6,	attention_name,
		attention_phone,	amt_rem_rev,		amt_rem_tax,
		date_recurring,	location_code,	db_action,
		source_trx_ctrl_num,	source_trx_type,	amt_discount_taken,
		amt_write_off_given,	nat_cur_code,		rate_type_home,
		rate_type_oper,	rate_home,		rate_oper,
		edit_list_flag,	amt_tax_included,	org_id	
	)
	SELECT
		trx_ctrl_num,		doc_ctrl_num,		doc_desc,
		apply_to_num,		apply_trx_type,	order_ctrl_num,
		batch_code,    	trx_type,		date_entered,
		date_applied,		date_doc,		date_shipped,
		date_required,	date_due,		date_aging,
		customer_code,   	ship_to_code,		salesperson_code,
		territory_code,	comment_code,		fob_code,
		freight_code,		terms_code,		fin_chg_code,
		price_code,		dest_zone_code,	posting_code,
		recurring_flag,	recurring_code,	tax_code,
		cust_po_num,		total_weight,		amt_gross,
	    	amt_freight,		amt_tax,		amt_discount,
		amt_net,		amt_paid,		amt_due,
		amt_cost,		amt_profit,		next_serial_id,
		printed_flag,		posted_flag,		hold_flag,
		hold_desc,		user_id,		customer_addr1,
		customer_addr2,	customer_addr3,	customer_addr4,
		customer_addr5,	customer_addr6,	ship_to_addr1,
		ship_to_addr2,	ship_to_addr3,	ship_to_addr4,
		ship_to_addr5,	ship_to_addr6,	attention_name,
		attention_phone,	amt_rem_rev,		amt_rem_tax,
		date_recurring,	location_code,	0,
		source_trx_ctrl_num,	source_trx_type,	amt_discount_taken,
		amt_write_off_given,	nat_cur_code,		rate_type_home,
		rate_type_oper,	rate_home,		rate_oper,
		edit_list_flag,	amt_tax_included,	org_id
	FROM	arinpchg
	WHERE	batch_code = @batch_ctrl_num
    	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'ariaitt.cpp' + ', line ' + STR( 124, 5 ) + ' -- EXIT: '
        	RETURN 34563
	END

	
	UPDATE #arinpchg_work
	SET org_id = ISNULL((select organization_id from Organization where outline_num = '1'),'')	
	WHERE org_id IS NULL

	    IF( @@error != 0 )
        	RETURN -1
	

	IF ( @perf_level >= 2 ) EXEC perf_sp @batch_ctrl_num, 'ariaitt.cpp', 137, 'Done inserting unposted invoice headers into #arinpchg_work', @PERF_time_last OUTPUT

	IF ( @perf_level >= 2 ) EXEC perf_sp @batch_ctrl_num, 'ariaitt.cpp', 139, 'Start inserting unposted invoice detail into #arinpcdt_work', @PERF_time_last OUTPUT
	INSERT #arinpcdt_work
	(
		trx_ctrl_num,		doc_ctrl_num,		sequence_id,
		trx_type,		location_code,	item_code,
		bulk_flag,		date_entered,		line_desc,
		qty_ordered,		qty_shipped,		unit_code,
		unit_price,		unit_cost, 		extended_price,
		weight,		serial_id,		tax_code,			
		gl_rev_acct,		disc_prc_flag,	discount_amt,		
		discount_prc,		commission_flag,	rma_num,		
		return_code,		qty_returned,		qty_prev_returned,	
		new_gl_rev_acct,	iv_post_flag,		oe_orig_flag,		
		db_action,		calc_tax,		reference_code,
		new_reference_code,	cust_po,	org_id
	)
	SELECT
		d.trx_ctrl_num,	d.doc_ctrl_num,	d.sequence_id,
		d.trx_type,		d.location_code,	d.item_code,
		d.bulk_flag,		d.date_entered,	d.line_desc,
		d.qty_ordered,	d.qty_shipped,	d.unit_code,
		d.unit_price,		d.unit_cost, 		d.extended_price,
		d.weight,		d.serial_id,		d.tax_code,			
		d.gl_rev_acct,	d.disc_prc_flag,	d.discount_amt,		
		d.discount_prc,	d.commission_flag,	d.rma_num,		
		d.return_code,	d.qty_returned,	d.qty_prev_returned,	
		d.new_gl_rev_acct,	d.iv_post_flag,	d.oe_orig_flag,
		0,		d.calc_tax,		d.reference_code,
		d.new_reference_code,	d.cust_po,	d.org_id
	FROM	arinpcdt d, #arinpchg_work h
    	WHERE  d.trx_ctrl_num = h.trx_ctrl_num 
      	AND   	d.trx_type = h.trx_type
    	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'ariaitt.cpp' + ', line ' + STR( 173, 5 ) + ' -- EXIT: '
        	RETURN 34563
	END
       
	UPDATE #arinpcdt_work
	SET org_id = ISNULL((select organization_id from Organization where outline_num = '1'),'')	
	WHERE org_id IS NULL

	    IF( @@error != 0 )
        	RETURN -1
	
	IF (@debug_level > 2)
	BEGIN
		SELECT '#######################################'
		SELECT 	' trx_ctrl_num = ' + trx_ctrl_num +
				' doc_ctrl_num = ' + doc_ctrl_num +
				' sequence_id = ' + STR(sequence_id,2) +
				' trx_type = ' + STR(trx_type,6) +
				' gl_rev_acct = ' + gl_rev_acct	+
				' new_gl_rev_acct = ' + new_gl_rev_acct
		FROM #arinpcdt_work

	END
	
	IF ( @perf_level >= 2 ) EXEC perf_sp @batch_ctrl_num, 'ariaitt.cpp', 197, 'Done inserting unposted invoice headers into #arinpcdt_work', @PERF_time_last OUTPUT

	UPDATE pbatch
	SET 	start_number = (SELECT COUNT(*) FROM #arinpchg_work),
		start_total = (SELECT ISNULL(SUM(amt_net),0.0) FROM #arinpchg_work),
		flag = 1
	WHERE 	batch_ctrl_num = @batch_ctrl_num
	AND 	process_ctrl_num = @process_ctrl_num
	
	IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, 'ariaitt.cpp', 206, 'Leaving ARIAInsertTempTables_SP', @PERF_time_last OUTPUT
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'ariaitt.cpp' + ', line ' + STR( 207, 5 ) + ' -- EXIT: '
    	RETURN 0
END
GO
GRANT EXECUTE ON  [dbo].[ARIAInsertTempTables_SP] TO [public]
GO
