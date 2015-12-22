SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/*                                                      
               Confidential Information                  
    Limited Distribution of Authorized Persons Only       
    Created 2001 and Protected as Unpublished Work       
          Under the U.S. Copyright Act of 1976            
 Copyright (c) 2001 Epicor Software Corporation, 2001    
                  All Rights Reserved                    
*/                                                























































































  



					  

























































 

























































































































































































































































































CREATE PROC [dbo].[aptrxinp_sp]	
	@apply_to_num	varchar(16),
	@trx_ctrl_num	varchar(16),
	@trx_type		smallint,
	@date_entered	int,
	@date_applied	int,
	@user_id		smallint
AS
DECLARE @vendor_code	varchar(12),	@pay_to_code	varchar(8),
		@amt_due		float,			@amt_net		float,
		@amt_ptd		float,			@company_code 	varchar(8)


SELECT @company_code = company_code
FROM glco




BEGIN TRAN

IF 	@trx_type = 4021
BEGIN
	

 	
	DELETE	apinpadj_vw
	WHERE	trx_ctrl_num = @trx_ctrl_num
	AND	trx_type = @trx_type

	DELETE	apinpage
	WHERE	trx_ctrl_num = @trx_ctrl_num
	AND	trx_type = @trx_type

	


	SELECT 	@vendor_code 	= vendor_code,
		@amt_net	= amt_net,
		@amt_ptd	= amt_paid_to_date
	FROM	aptrxapl_vw
	WHERE	trx_ctrl_num 	= @apply_to_num
	
	


	SELECT	@amt_due = @amt_net - @amt_ptd

	


	INSERT	apinpchg (
	        timestamp,
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
	    amt_tax	,
	    amt_freight,
	    amt_misc,
	    amt_net	,
		amt_paid,
		amt_due	,
		amt_restock,
		amt_tax_included,
		frt_calc_tax,
		doc_desc,
		hold_desc,
		user_id	,
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
		nat_cur_code,
		rate_type_home,
		rate_type_oper,
		rate_home,
		rate_oper,
		net_original_amt,
		org_id,
		tax_freight_no_recoverable
 )

	SELECT	NULL,
		@trx_ctrl_num,
		@trx_type,
		doc_ctrl_num,
		@apply_to_num,
		user_trx_type_code,
		"",
		po_ctrl_num,		
		vend_order_num,
		ticket_num,		
		@date_applied,		
		date_aging,		
		date_due,		
		date_doc,		
		@date_entered,		
		date_received,		
		date_required,		
		0,
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
		"",		
		payment_code,		
		times_accrued,		
		accrual_flag,		
		0,
		-1,
		0,
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
		amt_paid_to_date,		
		@amt_due,			
		0,
		0,
		0,
		"",
		"",
		@user_id,			
		0,
		"",
		"",
		"",
		"",
		"",
		"",
		"",
		"",
		intercompany_flag,
		@company_code,
		0,
		"",
		currency_code,
		rate_type_home,
		rate_type_oper,
		rate_home,
		rate_oper,
		net_original_amt,
		org_id,
		tax_freight_no_recoverable
	FROM	aptrxapl_vw
	WHERE	trx_ctrl_num = @apply_to_num

	IF	@@rowcount = 0
	BEGIN
		ROLLBACK TRAN
		RETURN
	END		

	


	INSERT	apinpage
	SELECT  NULL,
	        @trx_ctrl_num,  @trx_type,  	ref_id,  	
		@date_applied,	date_due,	date_aging,	
		amount
	FROM	aptrxage
	WHERE	trx_ctrl_num = @apply_to_num
	AND	trx_type = 4091
	AND	paid_flag = 0
END




DELETE	apinpcdt
WHERE	trx_ctrl_num = @trx_ctrl_num
AND	trx_type = @trx_type




INSERT	apinpcdt (
	timestamp,
	trx_ctrl_num,
	trx_type,
	sequence_id,
	location_code,
	item_code,
	bulk_flag,
	qty_ordered,
	qty_received,
	qty_returned,
	qty_prev_returned,
	approval_code,
	tax_code,
	return_code,
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
	reference_code,
	new_rec_company_code,
	new_reference_code,
	org_id,
	amt_nonrecoverable_tax,
	amt_tax_det )
SELECT  NULL,
        @trx_ctrl_num,
	@trx_type,
	sequence_id,
	location_code,
	item_code,
	0,
	qty_ordered,
	qty_received,
	qty_returned,
	0,
	"",
	tax_code,
	"",
	code_1099,
	"",
	unit_code,
	unit_price,
	amt_discount,
	amt_freight,
	amt_tax,
	amt_misc,
	amt_extended,
	calc_tax,
	@date_entered,
	gl_exp_acct,
	gl_exp_acct,
	"",
	line_desc,
	serial_id,	
	0,
 	1,
	0,
	rec_company_code,
	reference_code,
	rec_company_code,
	reference_code,
	org_id,
	amt_nonrecoverable_tax,
	0
FROM	apvodet
WHERE	trx_ctrl_num = @apply_to_num

COMMIT TRAN
RETURN


GO
GRANT EXECUTE ON  [dbo].[aptrxinp_sp] TO [public]
GO
