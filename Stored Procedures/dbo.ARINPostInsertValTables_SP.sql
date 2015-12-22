SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROC [dbo].[ARINPostInsertValTables_SP]	
AS

DECLARE
	@result 	int


BEGIN

	


	INSERT #arvalchg
	(	trx_ctrl_num,		doc_ctrl_num,		doc_desc,
		apply_to_num,		apply_trx_type,	order_ctrl_num,	
		batch_code,		trx_type,		date_entered,		
		date_applied,		date_doc,		date_shipped,		
		date_required,	date_due,		date_aging,		
		customer_code,	ship_to_code,		salesperson_code,	
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
		attention_phone, 	amt_rem_rev,		amt_rem_tax,		
		date_recurring,	location_code,	process_group_num,	
		source_trx_ctrl_num,	source_trx_type,	amt_discount_taken,	
		amt_write_off_given,	nat_cur_code,		rate_type_home,	
		rate_type_oper,	rate_home,		rate_oper,
		amt_tax_included, org_id,
		customer_city , customer_state , customer_postal_code, 	customer_country_code,
		ship_to_city, 	ship_to_state, 	ship_to_postal_code, ship_to_country_code 
	) 
    	SELECT	trx_ctrl_num,   	doc_ctrl_num,		doc_desc,
		apply_to_num,		apply_trx_type,	order_ctrl_num,	
		batch_code,		trx_type,		date_entered,		
		date_applied,		date_doc,		date_shipped,		
		date_required,	date_due,		date_aging,		
		customer_code,	ship_to_code,		salesperson_code,	
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
		attention_phone, 	amt_rem_rev,		amt_rem_tax,		
		date_recurring,	location_code,	process_group_num,	
		source_trx_ctrl_num,	source_trx_type,	amt_discount_taken,	
		amt_write_off_given,	nat_cur_code,		rate_type_home,	
		rate_type_oper,	rate_home,		rate_oper,
		amt_tax_included, org_id,
		customer_city , customer_state , customer_postal_code, 	customer_country_code,
		ship_to_city, 	ship_to_state, 	ship_to_postal_code, ship_to_country_code 
		
	FROM	#arinpchg_work 
			
 	

		
	INSERT #arvalcdt
	(	trx_ctrl_num,		doc_ctrl_num,		sequence_id,
		trx_type,		location_code,	item_code,
		bulk_flag,		date_entered,		line_desc,
		qty_ordered,		qty_shipped,		unit_code,
		unit_price,		unit_cost,		extended_price,
		weight,		serial_id,		tax_code,
		gl_rev_acct,		disc_prc_flag,	discount_amt,
		discount_prc,		commission_flag,	rma_num,
		return_code,		qty_returned,		qty_prev_returned,
		new_gl_rev_acct,	iv_post_flag,		oe_orig_flag,
		calc_tax,		reference_code, org_id
	  )
	SELECT	trx_ctrl_num,		doc_ctrl_num,		sequence_id,
		trx_type,		location_code,	item_code,
		bulk_flag,		date_entered,		line_desc,
		qty_ordered,		qty_shipped,		unit_code,
		unit_price,		unit_cost,		extended_price,
		weight,		serial_id,		tax_code,
		gl_rev_acct,		disc_prc_flag,	discount_amt,
		discount_prc,		commission_flag,	rma_num,
		return_code,		qty_returned,		qty_prev_returned,
		new_gl_rev_acct,	iv_post_flag,		oe_orig_flag,
		calc_tax,		reference_code, org_id
	FROM	#arinpcdt_work 
	
	


	INSERT #arvalage
	(	trx_ctrl_num,		sequence_id,	  	doc_ctrl_num,	
		apply_to_num,		apply_trx_type,	trx_type,
		date_applied,		date_due,		date_aging,
		customer_code,	salesperson_code,	territory_code,
		price_code,		amt_due
	)
	SELECT trx_ctrl_num,		sequence_id,	  	doc_ctrl_num,	
		apply_to_num,		apply_trx_type,	trx_type,
		date_applied,		date_due,		date_aging,
		customer_code,	salesperson_code,	territory_code,
		price_code,		amt_due
	FROM	#arinpage_work
	
	


	INSERT #arvaltax
	(	trx_ctrl_num,		trx_type,		sequence_id,
		tax_type_code,	amt_taxable,		amt_gross,
		amt_tax,		amt_final_tax
	)
	SELECT	trx_ctrl_num,   	trx_type,		sequence_id,
		tax_type_code,	amt_taxable,		amt_gross,
		amt_tax,		amt_final_tax
	FROM	#arinptax_work
		
     	


	INSERT #arvaltmp
	(	trx_ctrl_num,		doc_ctrl_num,		date_doc,
		customer_code,	payment_code,		amt_payment,
		amt_disc_taken,	cash_acct_code
	)
	SELECT trx_ctrl_num,		doc_ctrl_num,		date_doc,
		customer_code,	payment_code,		amt_payment,
		amt_disc_taken,	cash_acct_code
	FROM	#arinptmp_work
     	
     	


	INSERT	#arvalrev
	(	trx_ctrl_num,		sequence_id,		rev_acct_code,
		apply_amt,		trx_type,		reference_code,
		temp_flag, 		org_id, 		interbranch_flag 
	)
	SELECT	trx_ctrl_num,		sequence_id,		rev_acct_code,
		apply_amt,		trx_type,		reference_code,
		0,			org_id, 		0
	FROM	#arinprev_work

	RETURN 0
END
GO
GRANT EXECUTE ON  [dbo].[ARINPostInsertValTables_SP] TO [public]
GO
