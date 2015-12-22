SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO






CREATE PROC [dbo].[APDMModifyPersistant_sp]
											@batch_ctrl_num		varchar(16),
											@client_id 			varchar(20),
											@user_id			int,  
											@process_group_num  varchar(16),
											@debug_level		smallint = 0
AS

DECLARE
	@errbuf				varchar(100),
	@result				int,
	@current_date		int

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apdmmp.cpp" + ", line " + STR( 115, 5 ) + " -- ENTRY: "

EXEC appdate_sp	@current_date OUTPUT







EXEC @result = APDMUPActivity_sp  	@batch_ctrl_num, 
									@client_id,
									@user_id,
	                                @debug_level
IF(@result != 0 )
	RETURN @result





DELETE  apinpcdt
FROM	#apdmcdt_work t
	INNER JOIN apinpcdt a ON t.trx_ctrl_num = a.trx_ctrl_num AND t.trx_type = a.trx_type AND t.sequence_id = a.sequence_id
WHERE (t.db_action & 4) = 4

IF (@@error != 0)
	RETURN -1






DELETE  apinpchg_all
FROM	#apdmchg_work t
	INNER JOIN apinpchg_all a ON t.trx_ctrl_num = a.trx_ctrl_num AND t.trx_type = a.trx_type
WHERE (t.db_action & 4) = 4


DELETE apinptax
FROM	#apdmchg_work t
	INNER JOIN apinptax a ON t.trx_ctrl_num = a.trx_ctrl_num AND t.trx_type = a.trx_type
WHERE (t.db_action & 4) = 4

IF (@@error != 0)
	RETURN -1

DELETE apinptaxdtl
FROM	#apdmchg_work t
	INNER JOIN apinptaxdtl a ON t.trx_ctrl_num = a.trx_ctrl_num AND	t.trx_type = a.trx_type
WHERE (t.db_action & 4) = 4

IF (@@error != 0)
	RETURN -1






EXEC @result = APDMUPSummary_sp	@batch_ctrl_num, 
								@client_id,
								@user_id,
                                @debug_level
IF(@result != 0 )
		RETURN @result








UPDATE a
SET state_flag = 1,
	process_ctrl_num = ""
FROM apvohdr a
	INNER JOIN #apdmxv_work b ON a.trx_ctrl_num = b.trx_ctrl_num

IF (@@error != 0)
	RETURN -1


INSERT  apdmhdr(
	trx_ctrl_num,		doc_ctrl_num,		apply_to_num,
	user_trx_type_code,	batch_code,			po_ctrl_num,
	vend_order_num,		ticket_num,			date_posted,
	date_applied,		date_doc,			date_entered,
	posting_code,		vendor_code,		pay_to_code,
	branch_code,		class_code,			comment_code,
	fob_code,			tax_code,			state_flag,
	amt_gross,			amt_discount,		amt_freight,
	amt_tax,			amt_misc,			amt_net,
	amt_restock,		amt_tax_included,	frt_calc_tax,
	doc_desc,			user_id,			journal_ctrl_num,
	intercompany_flag,	process_ctrl_num,	currency_code,
	rate_type_home,		rate_type_oper,		rate_home,
	rate_oper, 		org_id,			tax_freight_no_recoverable
)
SELECT	trx_ctrl_num,       doc_ctrl_num,			apply_to_num,
        user_trx_type_code, batch_code,				po_ctrl_num,
        vend_order_num,     ticket_num,			    @current_date,
		date_applied,       date_doc,               date_entered,
		posting_code,		vendor_code,            pay_to_code,            
		branch_code,		class_code,             comment_code,
		fob_code,           tax_code,				1,
		amt_gross,          amt_discount,			amt_freight,
		amt_tax,            amt_misc,				amt_net,
		amt_restock,        amt_tax_included,		frt_calc_tax,
		doc_desc,           user_id,                gl_trx_id,
		intercompany_flag,  " ",					nat_cur_code,			
		rate_type_home,			rate_type_oper,			rate_home,				
		rate_oper, 		org_id,		tax_freight_no_recoverable
FROM    #apdmx_work
WHERE	(db_action & 2) = 2
AND trx_type = 4092

IF (@@error != 0)
	RETURN -1


INSERT  appyhdr(
	trx_ctrl_num,		doc_ctrl_num,		batch_code,
	date_posted,		date_applied,		date_doc,
	date_entered,		vendor_code,		pay_to_code,
	approval_code,		cash_acct_code,		payment_code,
	state_flag,			void_flag,			amt_net,
	amt_discount,		amt_on_acct,		payment_type,
	doc_desc,			user_id,			journal_ctrl_num,
	print_batch_num,	process_ctrl_num,	currency_code,
	rate_type_home,		rate_type_oper,		rate_home,
	rate_oper,		payee_name, org_id
)
SELECT	trx_ctrl_num,       doc_ctrl_num,			batch_code,
	  	@current_date,		date_applied,           date_doc,               
	  	date_entered,       vendor_code,            pay_to_code,            
	  	approval_code,      "",						"DBMEMO",
   		1,			0,						amt_net,
   		amt_discount,		amt_on_acct,			payment_type,
		doc_desc,           user_id,                gl_trx_id,
		0,					"",						nat_cur_code,			
		rate_type_home,		rate_type_oper,			rate_home,				
		rate_oper, "", org_id
FROM    #apdmx_work
WHERE	(db_action & 2) = 2
AND trx_type = 4111







INSERT  aptrxage (
	trx_ctrl_num,   trx_type,       	doc_ctrl_num,
	ref_id,         apply_to_num,   	apply_trx_type,
	date_doc,       date_applied,   	date_due,
	date_aging,     vendor_code,    	pay_to_code,
	class_code,     branch_code,    	amount,
	paid_flag,      cash_acct_code, 	amt_paid_to_date,
	date_paid,		nat_cur_code,		rate_home,
	rate_oper,		journal_ctrl_num,	account_code, 
	org_id)

SELECT	
	trx_ctrl_num,   trx_type,       	doc_ctrl_num,
	ref_id,         apply_to_num,   	apply_trx_type,
	date_doc,       date_applied,   	date_due,
	date_aging,     vendor_code,    	pay_to_code,
	class_code,     branch_code,    	amount,
	paid_flag,      cash_acct_code, 	amt_paid_to_date,
	0,				nat_cur_code,		rate_home,
	rate_oper,		journal_ctrl_num,	account_code, 
	org_id
FROM    #apdmxage_work
WHERE	(db_action & 2) = 2

IF (@@error != 0)
	RETURN -1




INSERT  apdmdet (
	trx_ctrl_num,	sequence_id,	location_code,
	item_code,		qty_received,	qty_returned,
	tax_code,		return_code,	unit_code,
	unit_price,		amt_discount,	amt_freight,
	amt_tax,		amt_misc,		amt_extended,
	calc_tax,		gl_exp_acct,	rma_num,
	line_desc,		serial_id,		rec_company_code,
	reference_code,	qty_prev_returned, org_id,
	amt_nonrecoverable_tax,	amt_tax_det
)
SELECT	trx_ctrl_num,   	sequence_id,		location_code,
 		item_code,      	qty_ordered,    	qty_returned,
		tax_code,       	return_code,    	unit_code,      	
		unit_price,     	amt_discount,		amt_freight,
		amt_tax,        	amt_misc,			amt_extended,
		calc_tax,			gl_exp_acct,    	rma_num, 
		line_desc,      	serial_id,			rec_company_code, 	
		reference_code, 	qty_prev_returned , org_id,
		amt_nonrecoverable_tax,	amt_tax_det
FROM    #apdmxcdt_work
WHERE	(db_action & 2) = 2

IF (@@error != 0)
	RETURN -1




UPDATE det
SET qty_returned = b.qty_returned
FROM apvodet det
	 INNER JOIN #apdmxcdv_work b ON det.trx_ctrl_num = b.trx_ctrl_num


IF (@@error != 0)
	RETURN -1






INSERT aptrxtax (
	   trx_ctrl_num	 ,	
	   trx_type		 ,	
	   tax_type_code ,		
	   date_applied	 ,	
	   amt_gross	 ,		
	   amt_taxable	 ,		
	   amt_tax	     )		
SELECT 
	   trx_ctrl_num	 ,
	   trx_type		 ,
	   tax_type_code ,
	   date_applied	 ,
	   amt_gross	 ,
	   amt_taxable	 ,
	   amt_tax	     
FROM   #apdmxtax_work
WHERE  (db_action & 2) = 2





INSERT 	aptrxtaxdtl(
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
	account_code)
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
	t.account_code
FROM	#apdmxtaxdtl_work t
WHERE  (t.db_action & 2) = 2
 
IF (@@ERROR != 0)
	RETURN -1

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apdmmp.cpp" + ", line " + STR( 397, 5 ) + " -- EXIT: "

RETURN 0
GO
GRANT EXECUTE ON  [dbo].[APDMModifyPersistant_sp] TO [public]
GO
