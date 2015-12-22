SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO





CREATE PROCEDURE        [dbo].[apdmval_sp] @debug_level smallint = 0
			
AS

DECLARE @result int                

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apdmval.cpp" + ", line " + STR( 34, 5 ) + " -- ENTRY: "

IF (SELECT COUNT(1) FROM #apinpchg) = 0
   RETURN -2


INSERT #apdmvchg (
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
	date_doc,
	date_entered,
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
	location_code,
	posted_flag,
	hold_flag,
    amt_gross,
    amt_discount,
    amt_tax,
    amt_freight,
    amt_misc,
    amt_net,
	amt_restock,
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
	net_original_amt,
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
	date_doc,
	date_entered,
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
	location_code,
	0,
	hold_flag,
    amt_gross,
    amt_discount,
    amt_tax,
    amt_freight,
    amt_misc,
    amt_net,
	amt_restock,
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
	0,
	net_original_amt,
	org_id,
	0,
	0
FROM	#apinpchg


INSERT #apdmvcdt
(
	trx_ctrl_num,
	trx_type,
	sequence_id,
	location_code, 
	item_code,
	bulk_flag,
	qty_ordered,
	qty_returned,
	qty_prev_returned,
	approval_code,
	tax_code,
	return_code,
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
	temp_flag
) 
SELECT 
	trx_ctrl_num, 
	trx_type,
	sequence_id,
	location_code,
	item_code,
	bulk_flag,
	qty_ordered,
	qty_returned,
	qty_prev_returned,
	approval_code,
	tax_code,
	return_code,
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
	0
FROM #apinpcdt


INSERT #apdmvtax
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


IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apdmval.cpp" + ", line " + STR( 248, 5 ) + " -- EXIT: "
			




RETURN 0

GO
GRANT EXECUTE ON  [dbo].[apdmval_sp] TO [public]
GO
