SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO




CREATE PROC [dbo].[APVAValidate_sp]	 	@debug_level		smallint = 0

AS

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvav.cpp" + ", line " + STR( 45, 5 ) + " -- ENTRY: "


INSERT #apvavchg (
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
	payment_code, 
	posted_flag, 
	hold_flag, 
    recurring_flag, 
	one_time_vend_flag, 
	one_check_flag, 
    amt_gross, 
    amt_discount, 
    amt_tax, 
    amt_freight, 
    amt_misc, 
    amt_net,
    amt_tax_included,
    frt_calc_tax, 
	doc_desc, 
	hold_desc, 
	user_id, 
	next_serial_id, 
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
	org_id,
	interbranch_flag,
	temp_flag
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
	payment_code, 
	0, 
	0, 
    recurring_flag, 
	one_time_vend_flag, 
	one_check_flag, 
    amt_gross, 
    amt_discount, 
    amt_tax, 
    amt_freight, 
    amt_misc, 
    amt_net, 
	amt_tax_included,
	frt_calc_tax,
	doc_desc, 
	hold_desc, 
	user_id, 
	next_serial_id, 
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
	0 
	,org_id
	,0
	,0
FROM	#apvachg_work


INSERT #apvavcdt 
( 
	trx_ctrl_num, 
	trx_type, 
	sequence_id, 
	location_code, 
	item_code, 
	bulk_flag, 
	qty_ordered, 
	qty_received, 
	qty_prev_returned, 
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
	new_gl_exp_acct, 
	rma_num, 
	line_desc, 
	serial_id, 
	company_id, 
	iv_post_flag, 
	po_orig_flag, 
	rec_company_code, 
	new_rec_company_code, 
	reference_code, 
	new_reference_code, 
	flag 
	,org_id
	,temp_flag
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
	qty_prev_returned, 
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
	new_gl_exp_acct, 
	rma_num, 
	line_desc, 
	serial_id, 
	company_id, 
	iv_post_flag, 
	po_orig_flag, 
	rec_company_code, 
	new_rec_company_code, 
	reference_code, 
	new_reference_code, 
	0 
	,org_id
	,0
FROM #apvacdt_work


INSERT #apvavage  
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
FROM #apvaage_work


IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvav.cpp" + ", line " + STR( 276, 5 ) + " -- EXIT: "
RETURN 0
GO
GRANT EXECUTE ON  [dbo].[APVAValidate_sp] TO [public]
GO
