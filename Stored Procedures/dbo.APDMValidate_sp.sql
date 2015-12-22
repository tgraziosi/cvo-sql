SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO




CREATE PROC [dbo].[APDMValidate_sp]	 	@debug_level		smallint = 0

AS

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apdmV.cpp" + ", line " + STR( 63, 5 ) + " -- ENTRY: "


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
	flag
	,org_id
	,interbranch_flag
	,temp_flag
	,tax_freight_no_recoverable
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
	0,
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
	0
	,org_id
	,0
	,0
	,tax_freight_no_recoverable
FROM	#apdmchg_work


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
	flag 
	,org_id
	,temp_flag,
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
	0
	,org_id
	,0,
	amt_nonrecoverable_tax
FROM #apdmcdt_work


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
	a.trx_ctrl_num,
	a.trx_type,
	a.sequence_id,
	a.tax_type_code,
	a.amt_taxable,
	a.amt_gross,
	a.amt_tax,
	a.amt_final_tax 
FROM apinptax a, #apdmchg_work b
WHERE a.trx_ctrl_num = b.trx_ctrl_num
AND a.trx_type = 4092

INSERT #apdmvtaxdtl
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
FROM #apdmtaxdtl_work

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apdmV.cpp" + ", line " + STR( 307, 5 ) + " -- EXIT: "
RETURN 0
GO
GRANT EXECUTE ON  [dbo].[APDMValidate_sp] TO [public]
GO
