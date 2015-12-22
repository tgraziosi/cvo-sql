SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO




CREATE PROC [dbo].[APVOInsertTempTable_sp]			@process_ctrl_num   varchar(16),
                                			@batch_ctrl_num		varchar(16),
											@debug_level		smallint = 0
   
AS

DECLARE
    @result int

DECLARE @organization_id VARCHAR(30)
SET @organization_id = ISNULL((select organization_id from Organization where outline_num = '1'),'')

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvoitt.cpp" + ", line " + STR( 74, 5 ) + " -- ENTRY: "

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvoitt.cpp" + ", line " + STR( 76, 5 ) + " -- MSG: " + "Load #apvochg_work"
INSERT	#apvochg_work 
	(
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
	add_cost_flag,		
	recurring_flag,
	one_time_vend_flag,	
	one_check_flag,		
	amt_gross,
    amt_discount,		
    amt_tax,		
    amt_freight,
    amt_misc,		
	glamt_tax,
	glamt_freight,
	glamt_misc,
	glamt_discount,
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
	process_group_num,
	iv_ctrl_num,
	nat_cur_code,	 
	rate_type_home,	 
	rate_type_oper,	 
	rate_home,		   
	rate_oper,		   
	net_original_amt,
	org_id,
	tax_freight_no_recoverable,
	db_action)

SELECT  trx_ctrl_num,		
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
		add_cost_flag,		
		recurring_flag,		
		one_time_vend_flag,	
		one_check_flag,		
		amt_gross,
		amt_discount,
        amt_tax,
        amt_freight,
        amt_misc,
		amt_tax,
		amt_freight,
		amt_misc,
		amt_discount,
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
        process_group_num,
		"",
		nat_cur_code,	 
		rate_type_home,	 
		rate_type_oper,	 
		rate_home,		   
		rate_oper,		   
		net_original_amt,
		ISNULL(org_id,@organization_id),
		tax_freight_no_recoverable,
		0 
FROM	apinpchg
WHERE	batch_code = @batch_ctrl_num 
AND 	posted_flag = -1

    IF( @@error != 0 )
        RETURN -1


	


IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvoitt.cpp" + ", line " + STR( 249, 5 ) + " -- MSG: " + "Load #apvocdt_work"
INSERT #apvocdt_work(
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
	amt_orig_extended,
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
	org_id,
	db_action,
	amt_nonrecoverable_tax,
	amt_tax_det)

SELECT	d.trx_ctrl_num,		
		d.trx_type,
		d.sequence_id,		
		d.location_code,	
		d.item_code,
		d.bulk_flag,		
		d.qty_ordered,
		d.qty_received,
		d.approval_code,
		d.tax_code,		
		d.code_1099,  
		d.po_ctrl_num,		
		d.unit_code,		
		d.unit_price,
		d.amt_discount, 
		d.amt_freight,
		d.amt_tax, 
		d.amt_misc, 
		d.amt_extended, 		
		d.amt_extended,
		d.calc_tax,		
		d.date_entered,
		d.gl_exp_acct,		
		d.rma_num,
		d.line_desc,  		
		d.serial_id,  		
		d.company_id,
		d.iv_post_flag, 	
		d.po_orig_flag, 	
		d.rec_company_code,
		d.reference_code,  	
		ISNULL(d.org_id,@organization_id),
		0,
		d.amt_nonrecoverable_tax,
		d.amt_tax_det

FROM	apinpcdt d
	INNER JOIN #apvochg_work h ON d.trx_ctrl_num = h.trx_ctrl_num AND d.trx_type = h.trx_type


    IF( @@error != 0 )
        RETURN -1



IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvoitt.cpp" + ", line " + STR( 332, 5 ) + " -- MSG: " + "Load #apvoage_work"
INSERT	#apvoage_work(
	trx_ctrl_num,	
	trx_type,
	sequence_id,	
	date_applied,	
	date_due,
	date_aging,	
	amt_due,	
	org_id,
	db_action)
SELECT	a.trx_ctrl_num,	
		a.trx_type,
		a.sequence_id,	
		a.date_applied,	
		a.date_due,
		a.date_aging,	
		a.amt_due,
		ISNULL(h.org_id,@organization_id),
		0
FROM	apinpage a
	INNER JOIN #apvochg_work h ON a.trx_ctrl_num = h.trx_ctrl_num AND a.trx_type = h.trx_type


IF (@@ERROR != 0)
	RETURN -1


IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvoitt.cpp" + ", line " + STR( 360, 5 ) + " -- MSG: " + "Load #apvotax_work"
INSERT 	#apvotax_work(
	trx_ctrl_num, 		
	trx_type,
	sequence_id,	
	tax_type_code,		
	amt_taxable,
	amt_gross,	
	amt_tax,		
	amt_final_tax,
	db_action)		
SELECT	t.trx_ctrl_num,		
		t.trx_type,
		t.sequence_id,  
		t.tax_type_code,	
		t.amt_taxable,
		t.amt_gross,
		t.amt_tax,
		t.amt_final_tax,
		0
FROM	apinptax t
	INNER JOIN #apvochg_work h ON t.trx_ctrl_num = h.trx_ctrl_num AND t.trx_type = h.trx_type

 
IF (@@ERROR != 0)
	RETURN -1

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvoitt.cpp" + ", line " + STR( 387, 5 ) + " -- MSG: " + "Load #apvotaxdtl_work"
INSERT 	#apvotaxdtl_work(
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
	account_code,
	db_action)
SELECT	t.trx_ctrl_num,
	t.sequence_id,
	t.trx_type,
	t.tax_sequence_id,
	t.detail_sequence_id,
	t.tax_type_code,
	t.amt_taxable,
	t.amt_gross,
	t.amt_tax,
	t.amt_final_tax,
	t.recoverable_flag,
	t.account_code,
	0
FROM	apinptaxdtl t
	INNER JOIN #apvochg_work h ON t.trx_ctrl_num = h.trx_ctrl_num AND t.trx_type = h.trx_type

 
IF (@@ERROR != 0)
	RETURN -1

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvoitt.cpp" + ", line " + STR( 422, 5 ) + " -- MSG: " + "Load #apvotmp_work"
INSERT	#apvotmp_work(
    trx_ctrl_num,			
    trx_type,
	doc_ctrl_num,		
	trx_desc,			
	date_applied,
	date_doc,		
	vendor_code,			
	payment_code,
	code_1099,		
	cash_acct_code,			
	amt_payment,
	amt_disc_taken,		
	payment_type,			
	approval_flag,
	user_id,		
	org_id,
	db_action)
SELECT  p.trx_ctrl_num,		
		p.trx_type,
		p.doc_ctrl_num,		
		p.trx_desc,		
		p.date_applied,
		p.date_doc,		
		p.vendor_code,		
		p.payment_code,
		p.code_1099,		
		p.cash_acct_code,	
		p.amt_payment,
		p.amt_disc_taken,
		p.payment_type,		
		p.approval_flag,	
		p.user_id,
		ISNULL(h.org_id,@organization_id),
		0
FROM	apinptmp p
	INNER JOIN #apvochg_work h ON p.trx_ctrl_num = h.trx_ctrl_num AND p.trx_type = h.trx_type


IF (@@ERROR != 0)
	RETURN -1

DECLARE @amt_net FLOAT
DECLARE @count INTEGER

SET @amt_net = (SELECT ISNULL(SUM(amt_net),0.0) FROM #apvochg_work)
SET @count = (SELECT COUNT(1) FROM #apvochg_work)


UPDATE pbatch
SET start_number = @count,
	start_total = @amt_net,
	flag = 1
WHERE batch_ctrl_num = @batch_ctrl_num
AND process_ctrl_num = @process_ctrl_num


	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvoitt.cpp" + ", line " + STR( 480, 5 ) + " -- EXIT: "
    RETURN 0
GO
GRANT EXECUTE ON  [dbo].[APVOInsertTempTable_sp] TO [public]
GO
