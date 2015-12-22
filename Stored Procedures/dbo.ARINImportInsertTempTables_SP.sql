SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROC [dbo].[ARINImportInsertTempTables_SP]	@process_ctrl_num	varchar(16),
						@batch_ctrl_num	varchar(16),
						@user_id		smallint,
						@debug_level		smallint = 0
AS
DECLARE
 	@result 	int,
	@date_entered	int

BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/ariniitt.sp" + ", line " + STR( 58, 5 ) + " -- ENTRY: "
	
	SELECT	@date_entered = datediff(dd,"1/1/80",getdate())+722815
	
	
	INSERT INTO #arinpchg
	(
		link,
		trx_ctrl_num,			doc_ctrl_num,			doc_desc,
		apply_to_num,			apply_trx_type,		
		order_ctrl_num,
		batch_code,			trx_type,			date_entered,
		date_applied,			date_doc,			
		date_shipped,			date_required,		
		date_due,			date_aging,
		customer_code,		ship_to_code,			salesperson_code,
		territory_code,		comment_code,			fob_code,
		freight_code,			terms_code,			fin_chg_code,
		price_code,			dest_zone_code,		posting_code,
		recurring_flag,		recurring_code,		tax_code,
		cust_po_num,			total_weight,			amt_gross,
		amt_freight,			amt_tax,			amt_tax_included,
		amt_discount,			amt_net,			amt_paid,
		amt_due,			amt_cost,			amt_profit,
		next_serial_id,		printed_flag,			posted_flag,
		hold_flag,			hold_desc,			user_id,
		customer_addr1,		customer_addr2,		customer_addr3,
		customer_addr4,		customer_addr5,		customer_addr6,
		ship_to_addr1,		ship_to_addr2,		ship_to_addr3,
		ship_to_addr4,		ship_to_addr5,		ship_to_addr6,
		attention_name,		attention_phone,		amt_rem_rev,
		amt_rem_tax,			date_recurring,		location_code,
		process_group_num,		trx_state,			mark_flag,
		amt_discount_taken,		amt_write_off_given,		source_trx_ctrl_num,
		source_trx_type,		nat_cur_code,			rate_type_home,
		rate_type_oper,		rate_home,			rate_oper,
		edit_list_flag
	)
	SELECT
		link,			
		trx_ctrl_num, 		doc_ctrl_num, 		doc_desc,		
		apply_to_num,			apply_trx_type,		
		order_ctrl_num,
		batch_ctrl_num,		trx_type,			@date_entered,
		date_applied,			date_doc,			
		date_shipped,			date_required,		
		date_due,			date_aging,
		customer_code,		ship_to_code,			salesperson_code,
		territory_code,		comment_code,			fob_code,
		freight_code,			terms_code,			fin_chg_code,
		price_code,			dest_zone_code,		posting_code,
		0,				recurring_code,		tax_code,
		cust_po_num,			0.0,				0.0,			
	 	amt_freight,			0.0,				0.0,
		0.0,				0.0,				0.0,
		0.0,				0.0,				0.0,
		0,				printed_flag,			0,	
	 	hold_flag,			hold_desc,			@user_id,	
	 	customer_addr1,		customer_addr2,		customer_addr3,	
	 	customer_addr4,		customer_addr5,		customer_addr6,	
	 	ship_to_addr1,		ship_to_addr2,		ship_to_addr3,	
	 	ship_to_addr4,		ship_to_addr5,	 ship_to_addr6,	
	 	attention_name,		attention_phone,		0.0,
		0.0,				0,				location_code,	
		process_ctrl_num,		0,				0,
		0.0,				0.0,				source_trx_ctrl_num,	
	 	source_trx_type,		nat_cur_code,			rate_type_home,	
	 	rate_type_oper, 		rate_home,			rate_oper,	
		0
	FROM	arinthdr
	WHERE	batch_ctrl_num = @batch_ctrl_num
 	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/ariniitt.sp" + ", line " + STR( 133, 5 ) + " -- EXIT: "
 	RETURN 34563
	END
	
	INSERT #arinpcdt
	(
		link,
		trx_ctrl_num,		doc_ctrl_num,			sequence_id,
		trx_type,		location_code,		item_code,
		bulk_flag,		date_entered,			line_desc,
		qty_ordered,		qty_shipped,			unit_code,
		unit_price,		unit_cost,			weight,
		serial_id,		tax_code,			gl_rev_acct,
		disc_prc_flag,	discount_amt,			commission_flag,
		rma_num,		return_code,			qty_returned,
		qty_prev_returned,	new_gl_rev_acct,		iv_post_flag,
		oe_orig_flag,		discount_prc,			
		extended_price,
		calc_tax,		trx_state,			mark_flag
	)
	SELECT
		d.link,	
		h.trx_ctrl_num,	h.doc_ctrl_num,		d.sequence_id,	
		h.trx_type,		d.location_code,		d.item_code,	
		0,			@date_entered,		d.line_desc,		
		d.qty_ordered,	d.qty_shipped,		d.unit_code,		
		d.unit_price,		d.unit_cost,			d.weight,		
		d.serial_id,		d.tax_code,			d.gl_rev_acct,	
		d.disc_prc_flag,	(1-d.disc_prc_flag)*d.discount, 0,
		'',			'',				0,
		0,			'',				d.iv_post_flag,	
		d.oe_orig_flag,	(d.disc_prc_flag)*d.discount, 
		0.0,
		0.0,			0,				0	
	FROM	arintdet d, #arinpchg h
	WHERE	d.link = h.link
 	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/ariniitt.sp" + ", line " + STR( 171, 5 ) + " -- EXIT: "
 	RETURN 34563
	END
	
	IF ( @debug_level > 0 )
	BEGIN
		SELECT "link = " + link +
			"customer_code = " + customer_code
		FROM	#arinpchg
		
		SELECT "link = " + link
		FROM	#arinpcdt
	END

	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/ariniitt.sp" + ", line " + STR( 185, 5 ) + " -- EXIT: "
 	RETURN 0
END
GO
GRANT EXECUTE ON  [dbo].[ARINImportInsertTempTables_SP] TO [public]
GO
