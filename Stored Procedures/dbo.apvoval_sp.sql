SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO




CREATE PROCEDURE        [dbo].[apvoval_sp] @debug_level smallint = 0
			
AS

DECLARE @result int                

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvoval.cpp" + ", line " + STR( 45, 5 ) + " -- ENTRY: "

IF (SELECT COUNT(1) FROM #apinpchg) = 0
   RETURN -2


INSERT #apvovchg (
	trx_ctrl_num,
    trx_type,
	doc_ctrl_num, 
    apply_to_num, 
    user_trx_type_code,	 
	batch_code, 
	po_ctrl_num,	 
	vend_order_num, 
	ticket_num,	 
	date_applied, 
	date_aging, 
	date_due,
	date_doc, 
	date_entered, 
	date_received, 
	date_required, 
	date_recurring, 
	date_discount,	 
	posting_code,	 
    vendor_code,	 
    pay_to_code,	 
	branch_code,	 
	class_code,	 
	approval_code, 
	comment_code, 
	fob_code, 
	terms_code, 
	tax_code, 
	recurring_code, 
	location_code, 
	payment_code, 
	times_accrued, 
	accrual_flag, 
	drop_ship_flag, 
	posted_flag, 
	hold_flag, 
	add_cost_flag, 
	approval_flag, 
    recurring_flag, 
	one_time_vend_flag, 
	one_check_flag, 
    amt_gross, 
    amt_discount, 
    amt_tax, 
    amt_freight, 
    amt_misc, 
    amt_net, 
	amt_paid, 
	amt_due, 
	amt_tax_included,
	frt_calc_tax,
	doc_desc, 
	hold_desc, 
	user_id, 
	next_serial_id, 
	pay_to_addr1, 
	pay_to_addr2, 
	pay_to_addr3, 
	pay_to_addr4, 
	pay_to_addr5, 
	pay_to_addr6, 
	attention_name, 
	attention_phone, 
	intercompany_flag, 
	company_code, 
	cms_flag, 
	nat_cur_code, 
	rate_type_home, 
	rate_type_oper, 
	rate_home, 
	rate_oper, 
	flag,
	net_original_amt,
	org_id,
	interbranch_flag,
	temp_flag,
	tax_freight_no_recoverable
) 
SELECT  
	trx_ctrl_num,
    trx_type,	 
	doc_ctrl_num, 
    apply_to_num, 
    user_trx_type_code,	 
	batch_code, 
	po_ctrl_num,	 
	vend_order_num, 
	ticket_num,	 
	date_applied, 
	date_aging, 
	date_due,
	date_doc, 
	date_entered, 
	date_received, 
	date_required, 
	date_recurring, 
	date_discount,	 
	posting_code,	 
    vendor_code,	 
    pay_to_code,	 
	branch_code,	 
	class_code,	 
	approval_code, 
	comment_code, 
	fob_code, 
	terms_code, 
	tax_code, 
	recurring_code, 
	location_code, 
	payment_code, 
	times_accrued, 
	accrual_flag, 
	drop_ship_flag, 
	posted_flag, 
	hold_flag, 
	add_cost_flag, 
	approval_flag, 
    recurring_flag, 
	one_time_vend_flag, 
	one_check_flag, 
    amt_gross, 
    amt_discount, 
    amt_tax, 
    amt_freight, 
    amt_misc, 
    amt_net, 
	amt_paid, 
	amt_due, 
	amt_tax_included,
	frt_calc_tax,
	doc_desc, 
	hold_desc, 
	user_id, 
	next_serial_id, 
	pay_to_addr1, 
	pay_to_addr2, 
	pay_to_addr3, 
	pay_to_addr4, 
	pay_to_addr5, 
	pay_to_addr6, 
	attention_name, 
	attention_phone, 
	intercompany_flag, 
	company_code, 
	cms_flag, 
	nat_cur_code, 
	rate_type_home, 
	rate_type_oper, 
	rate_home, 
	rate_oper, 
	0,
	net_original_amt,
	org_id,
	0,
	0,
	tax_freight_no_recoverable
FROM	#apinpchg

INSERT #apvovcdt 
( 
	trx_ctrl_num, 
	trx_type, 
	sequence_id, 
	location_code, 
	item_code, 
	bulk_flag, 
	qty_ordered, 
	qty_received, 
	approval_code, 
	tax_code, 
	code_1099, 
	po_ctrl_num, 
	unit_code, 
	unit_price, 
	amt_discount, 
	amt_freight, 
	amt_tax, 
	amt_misc, 
	amt_extended,
	calc_tax, 
	date_entered, 
	gl_exp_acct, 
	rma_num, 
	line_desc, 
	serial_id, 
	company_id, 
	iv_post_flag, 
	po_orig_flag, 
	rec_company_code, 
	reference_code, 
	flag,
	org_id,
	temp_flag,
	amt_nonrecoverable_tax
) 	
SELECT 
	trx_ctrl_num, 
	trx_type, 
	sequence_id, 
	location_code, 
	item_code, 
	bulk_flag, 
	qty_ordered, 
	qty_received, 
	approval_code, 
	tax_code, 
	code_1099, 
	po_ctrl_num, 
	unit_code, 
	unit_price, 
	amt_discount, 
	amt_freight, 
	amt_tax, 
	amt_misc, 
	amt_extended, 
	calc_tax,
	date_entered, 
	gl_exp_acct, 
	rma_num, 
	line_desc, 
	serial_id, 
	company_id, 
	iv_post_flag, 
	po_orig_flag, 
	rec_company_code, 
	reference_code, 
	0,
	org_id,
	0,
	amt_nonrecoverable_tax
FROM #apinpcdt


INSERT #apvovage
( 
	trx_ctrl_num, 
	trx_type, 
	sequence_id, 
	date_applied, 
	date_due, 
	date_aging, 
	amt_due 
) 
SELECT 
	trx_ctrl_num, 
	trx_type, 
	sequence_id, 
	date_applied, 
	date_due, 
	date_aging, 
	amt_due 
FROM #apinpage

INSERT #apvovtax 
( 
	trx_ctrl_num, 
	trx_type, 
	sequence_id, 
	tax_type_code, 
	amt_taxable, 
	amt_gross, 
	amt_tax, 
	amt_final_tax 
) 
SELECT 
	trx_ctrl_num, 
	trx_type, 
	sequence_id, 
	tax_type_code, 
	amt_taxable, 
	amt_gross, 
	amt_tax, 
	amt_final_tax 
FROM #apinptax

INSERT 	#apvovtaxdtl
(
	trx_ctrl_num,
	sequence_id,
	trx_type,
	tax_sequence_id,
	detail_sequence_id,
	tax_type_code,
	amt_taxable,
	amt_gross,
	amt_tax,
	amt_final_tax,
	recoverable_flag,
	account_code
)
SELECT
	trx_ctrl_num,
	sequence_id,
	trx_type,
	tax_sequence_id,
	detail_sequence_id,
	tax_type_code,
	amt_taxable,
	amt_gross,
	amt_tax,
	amt_final_tax,
	recoverable_flag,
	account_code
FROM 	#apinptaxdtl



IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvoval.cpp" + ", line " + STR( 359, 5 ) + " -- EXIT: "
			




RETURN 0

GO
GRANT EXECUTE ON  [dbo].[apvoval_sp] TO [public]
GO
