SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO





CREATE PROC [dbo].[APVOInsertPostedRecords_sp]  @journal_ctrl_num  varchar(16),
										@date_applied int,
										@debug_level smallint = 0
AS
			 
	DECLARE	@current_date int,
			@next_num int,
			@mask varchar(16),
			@disb_num varchar(16),
			@flag smallint

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvoipr.cpp" + ", line " + STR( 60, 5 ) + " -- ENTRY: "
			 							 

	EXEC appdate_sp @current_date OUTPUT		

UPDATE 	#apvochg_work
SET 	apply_to_num = trx_ctrl_num
WHERE 	apply_to_num = ""


IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvoipr.cpp" + ", line " + STR( 70, 5 ) + " -- MSG: " + "Insert voucher header records"
INSERT  #apvox_work (
	trx_ctrl_num,           	trx_type,               	doc_ctrl_num,   
	apply_to_num,           	user_trx_type_code,		po_ctrl_num,
	vend_order_num,         	ticket_num, 			date_applied,
	date_aging,			date_due,			date_doc,
	date_entered,			date_received,			date_required,
	date_discount,			posting_code,			vendor_code,
	pay_to_code,			branch_code,			class_code,
	approval_code,			comment_code,			fob_code,
	terms_code,			tax_code,			recurring_code,
	payment_code,			add_cost_flag,			recurring_flag,			
	one_time_vend_flag,		one_check_flag, 		accrual_flag,
	times_accrued,			amt_gross,			amt_discount,
	amt_freight,			amt_tax,			amt_misc,				
	amt_net,			amt_tax_included,		frt_calc_tax,			
	doc_desc,			user_id,			gl_trx_id,				
	intercompany_flag,		company_code,			cms_flag,				
	nat_cur_code,			rate_type_home,	 		rate_type_oper,			
	rate_home,			rate_oper,		 	net_original_amt,
	org_id,				tax_freight_no_recoverable,	db_action)
SELECT
	trx_ctrl_num,           	trx_type,            		doc_ctrl_num,
	apply_to_num,           	user_trx_type_code,     	po_ctrl_num,
	vend_order_num,         	ticket_num, 			date_applied,
	date_aging,			date_due,			date_doc,
	date_entered,			date_received,			date_required,
	date_discount,			posting_code,			vendor_code,            
	pay_to_code,			branch_code,			class_code,             
	approval_code,			comment_code,			fob_code,               
	terms_code,			tax_code,			recurring_code,         
	payment_code,			add_cost_flag,			recurring_flag,
	one_time_vend_flag,		one_check_flag,			accrual_flag,
	times_accrued,			amt_gross,			amt_discount,			
	amt_freight,			amt_tax,			amt_misc,				
	amt_net,			amt_tax_included,		0.0,			
	doc_desc,			user_id,			@journal_ctrl_num,		
	intercompany_flag,		company_code,			cms_flag,				
	nat_cur_code,			rate_type_home,	 		rate_type_oper,			
	rate_home,			rate_oper,		   	net_original_amt,
	org_id,				tax_freight_no_recoverable,	2
FROM    #apvochg_work
  


IF (@@error != 0)
	RETURN -1

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvoipr.cpp" + ", line " + STR( 118, 5 ) + " -- MSG: " + "Insert voucher tax records"
INSERT  #apvoxtax_work(
	trx_ctrl_num,   trx_type,       tax_type_code,
	date_applied,   amt_gross,      amt_taxable,
	amt_tax,		db_action )
SELECT  a.trx_ctrl_num,   a.trx_type,       a.tax_type_code,
	b.date_applied, a.amt_gross,     a.amt_taxable,    
	a.amt_final_tax,	2
FROM    #apvotax_work a, #apvochg_work b
WHERE a.trx_ctrl_num = b.trx_ctrl_num
AND a.trx_type = b.trx_type


IF (@@error != 0)
	RETURN -1

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvoipr.cpp" + ", line " + STR( 134, 5 ) + " -- MSG: " + "Insert voucher tax details records"
INSERT 	#apvoxtaxdtl_work(
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
	2
FROM	#apvotaxdtl_work t, #apvochg_work h
WHERE	t.trx_ctrl_num = h.trx_ctrl_num AND
		t.trx_type = h.trx_type
 

IF (@@ERROR != 0)
	RETURN -1

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvoipr.cpp" + ", line " + STR( 170, 5 ) + " -- MSG: " + "Insert voucher detail records"
INSERT  #apvoxcdt_work(
	trx_ctrl_num,   	trx_type,       	sequence_id,
	location_code,  	item_code,      	bulk_flag,
	qty_ordered,    	qty_received,   	tax_code,  	    	
	code_1099,			unit_code,      	unit_price,     	
	amt_discount,		amt_freight,    	amt_tax,
	amt_misc,			date_entered,   	gl_exp_acct,
	rma_num,			line_desc,      	serial_id,
	company_id,			po_ctrl_num,    	approval_code,
	amt_extended,		calc_tax,			rec_company_code,	
	reference_code, 	po_orig_flag,			org_id,
	db_action,		amt_nonrecoverable_tax,		amt_tax_det )
SELECT
	trx_ctrl_num,   	trx_type,       	sequence_id,
	location_code,  	item_code,      	bulk_flag,
	qty_ordered,    	qty_received,		tax_code,
	code_1099,			unit_code,      	unit_price,
	amt_discount,		amt_freight,    	amt_tax,
	amt_misc,			date_entered,		gl_exp_acct,
	rma_num,			line_desc,      	serial_id,
	company_id,			po_ctrl_num,    	approval_code,
	amt_orig_extended,  calc_tax,			rec_company_code,	
	reference_code, 	po_orig_flag,		org_id,
	2,		amt_nonrecoverable_tax,		amt_tax_det
FROM    #apvocdt_work
  
IF (@@error != 0)
	RETURN -1

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvoipr.cpp" + ", line " + STR( 200, 5 ) + " -- MSG: " + "Insert voucher aging records"

INSERT	#apvoxage_work(
	trx_ctrl_num,		trx_type,		doc_ctrl_num,
	ref_id,			apply_to_num,		apply_trx_type,
	date_doc,		date_applied,		date_due,
	date_aging,		vendor_code,		pay_to_code,
	class_code,		branch_code,		amount,
	nat_cur_code,		rate_home,		rate_oper,
	journal_ctrl_num,	account_code,		org_id,
	db_action )
SELECT
	a.trx_ctrl_num,   	a.trx_type,		b.doc_ctrl_num,
	a.sequence_id,    	b.apply_to_num,		0,					
	b.date_doc,       	b.date_applied,		a.date_due,
	a.date_aging,     	b.vendor_code,		b.pay_to_code,
	b.class_code,     	b.branch_code,		a.amt_due,
	b.nat_cur_code,	  	b.rate_home,		b.rate_oper,
	@journal_ctrl_num,	dbo.IBAcctMask_fn(c.ap_acct_code, a.org_id),		a.org_id,
	2
FROM    #apvoage_work a, #apvochg_work b, apaccts c
WHERE a.trx_ctrl_num = b.trx_ctrl_num
AND b.posting_code = c.posting_code

  
IF(@@error != 0)
	RETURN -1



IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvoipr.cpp" + ", line " + STR( 230, 5 ) + " -- EXIT: "
RETURN 0
GO
GRANT EXECUTE ON  [dbo].[APVOInsertPostedRecords_sp] TO [public]
GO
