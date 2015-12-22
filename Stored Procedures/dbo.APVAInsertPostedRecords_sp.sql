SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO




CREATE PROC [dbo].[APVAInsertPostedRecords_sp]  @journal_ctrl_num  varchar(16),
										@date_applied int,
										@debug_level smallint = 0
AS
			 
	DECLARE	@current_date int

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'apvaipr.cpp' + ', line ' + STR( 52, 5 ) + ' -- ENTRY: '
			 							 

	EXEC appdate_sp @current_date OUTPUT		



INSERT	#apvahisx_work(
		trx_ctrl_num,	po_ctrl_num,	vend_order_num,
		ticket_num,	date_received,	date_applied,
		date_aging,	date_doc,	date_required,
		date_discount,	class_code,	fob_code,
		terms_code,	db_action )
SELECT	trx_ctrl_num,	po_ctrl_num,	vend_order_num,
		ticket_num,	date_received,	date_applied,
		date_aging,	date_doc,	date_required,
		date_discount,	class_code,	fob_code,
		terms_code,	2
FROM	#apvax_work
WHERE trx_type = 4091


INSERT	#apvahisa_work
		(trx_ctrl_num, 	date_aging,	db_action )
SELECT	trx_ctrl_num, 	date_aging,	2
FROM	#apvaxage_work
WHERE trx_type = 4091



INSERT	#apvax_work (
	trx_ctrl_num,		trx_type,			doc_ctrl_num,	
	apply_to_num,		user_trx_type_code,	batch_code,
	po_ctrl_num,		vend_order_num,		date_applied,
	date_aging,			date_due,			date_doc,
	date_entered,		date_received,		date_required,
	posting_code,		vendor_code,		pay_to_code,
	branch_code,		class_code,			approval_code,
	comment_code,		fob_code,			terms_code,
	tax_code,			recurring_code,		recurring_flag,
	one_time_vend_flag,	amt_gross,			amt_discount,
	amt_freight,		amt_tax,			amt_misc,
	amt_net,			amt_tax_included,	frt_calc_tax,			
	doc_desc,			user_id,			gl_trx_id,			
	date_discount, 	   	ticket_num, 		one_check_flag,		
	payment_code,		intercompany_flag, 	company_code,       
	cms_flag,			nat_cur_code,	 	rate_type_home,		
	rate_type_oper,		rate_home,		   	rate_oper,			
	org_id,			db_action)
SELECT
	trx_ctrl_num,       trx_type,           doc_ctrl_num,
	apply_to_num,       user_trx_type_code,	batch_code,
	po_ctrl_num,        vend_order_num,     date_applied,
	date_aging,         date_due,			date_doc,
	date_entered,       date_received,		date_required,
	posting_code,		vendor_code,        pay_to_code,
	branch_code,		class_code,         approval_code,
	comment_code,		fob_code,           terms_code,
	tax_code,			recurring_code,		recurring_flag,
	one_time_vend_flag, amt_gross,          amt_discount,
	amt_freight,        amt_tax,            amt_misc,
	amt_net,            0.0,				0.0,			
	doc_desc,           user_id,			@journal_ctrl_num,	
	date_discount,      ticket_num,			one_check_flag,    	
	payment_code,      	intercompany_flag,	company_code,       
	cms_flag,			nat_cur_code,	 	rate_type_home,		
	rate_type_oper,		rate_home,		   	rate_oper,			
	org_id,			2
FROM 	#apvachg_work
  
IF (@@ERROR != 0)
	RETURN -1





INSERT	#apvaxcdt_work (
	trx_ctrl_num,			trx_type,			sequence_id,
	location_code,			item_code,			bulk_flag,
	qty_ordered,			qty_received,		tax_code,
	code_1099,				unit_code,			unit_price,
	amt_discount,			amt_freight,		amt_tax,
	amt_misc,				date_entered,		gl_exp_acct,
	new_gl_exp_acct,		rma_num,			line_desc,
	serial_id,				company_id,			po_ctrl_num,
	approval_code,			amt_extended,  	 	calc_tax,		
	rec_company_code, 		reference_code, 	po_orig_flag, 		
	new_rec_company_code,	new_reference_code, qty_prev_returned, 	
	org_id,			db_action)

SELECT
	trx_ctrl_num,			trx_type,			sequence_id,
	location_code,			item_code,			bulk_flag,
	qty_ordered,			qty_received,		tax_code,
	code_1099,				unit_code,			unit_price,			
	amt_discount,			amt_freight,		amt_tax,
	amt_misc,				date_entered,		gl_exp_acct,
	new_gl_exp_acct,		rma_num,			line_desc,
	serial_id,				company_id,			po_ctrl_num,
	approval_code,			amt_extended,		calc_tax,		
	rec_company_code, 		reference_code, 	po_orig_flag,   	
	new_rec_company_code,	new_reference_code, qty_prev_returned, 	
	org_id,			2
FROM	#apvacdt_work


IF (@@ERROR != 0)
	RETURN -1




IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'apvaipr.cpp' + ', line ' + STR( 165, 5 ) + ' -- EXIT: '
RETURN 0
GO
GRANT EXECUTE ON  [dbo].[APVAInsertPostedRecords_sp] TO [public]
GO
