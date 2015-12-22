SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROC [dbo].[ARPYPostInsertValTables_SP]	
AS

DECLARE
	@result 	int

BEGIN
	
	


	

	




	


	INSERT	#arvalpyt
	(	trx_ctrl_num,		doc_ctrl_num,		trx_desc,
		batch_code,		trx_type,   		non_ar_flag,
		non_ar_doc_num,		gl_acct_code, 		date_entered,
		date_applied,		date_doc,		customer_code,
		payment_code,	      	payment_type,		amt_payment,
		amt_on_acct,		prompt1_inp,		prompt2_inp,
		prompt3_inp, 		prompt4_inp,		deposit_num,
		bal_fwd_flag,    	printed_flag,	      	posted_flag,
		hold_flag,		wr_off_flag,		on_acct_flag, 
		user_id, 		max_wr_off,		days_past_due,	 
		void_type,  		cash_acct_code, 	origin_module_flag,
		process_group_num,	temp_flag,		source_trx_ctrl_num,
		source_trx_type,    	nat_cur_code,		rate_type_home,
		rate_type_oper,   	rate_home, 		rate_oper, 
		amt_discount,		reference_code,		org_id
	)
	SELECT	trx_ctrl_num,		doc_ctrl_num,	   	trx_desc,
		batch_code,	    	trx_type,	 	non_ar_flag,
		non_ar_doc_num,  	CASE WHEN non_ar_flag = 1 AND trx_type = 2121 THEN	cash_acct_code 
					ELSE gl_acct_code
					END , 			date_entered,
		date_applied,		date_doc,		customer_code,
		payment_code,		payment_type,		amt_payment,
		amt_on_acct, 		prompt1_inp,	     	prompt2_inp,
		prompt3_inp,		prompt4_inp,		deposit_num,
		bal_fwd_flag, 		printed_flag,	 	posted_flag,
		hold_flag,		wr_off_flag,	   	on_acct_flag, 
		user_id, 	  	max_wr_off,  		days_past_due,	 
		void_type,   		cash_acct_code, 	origin_module_flag,
		process_group_num, 	0,	     		source_trx_ctrl_num,
		source_trx_type,	nat_cur_code, 	rate_type_home,
		rate_type_oper, 	rate_home, 		rate_oper, 
		amt_discount,		reference_code, 	org_id		
	FROM	#arinppyt_work

	



	INSERT	#arvalpdt
	(	trx_ctrl_num,	    	doc_ctrl_num,	   	sequence_id,
		trx_type,	    	apply_to_num,	     	apply_trx_type,
		customer_code, 	payer_cust_code, 	date_aging,
		amt_applied,		amt_disc_taken,	wr_off_flag,
		amt_max_wr_off,    	void_flag, 		line_desc,
		sub_apply_num,     	sub_apply_type, 	amt_tot_chg,	
		amt_paid_to_date,	terms_code,		posting_code,	
		date_doc,		amt_inv,  		gain_home,		
		gain_oper,		inv_amt_applied,    	inv_amt_disc_taken,
		inv_amt_max_wr_off,	inv_cur_code,		writeoff_code,
		temp_flag,		org_id
	)
	SELECT	hdr.trx_ctrl_num,   	hdr.doc_ctrl_num, 	det.sequence_id,
		hdr.trx_type,		det.apply_to_num,   	det.apply_trx_type,
		det.customer_code, 	hdr.customer_code,	det.date_aging,
		det.amt_applied,	det.amt_disc_taken,	det.wr_off_flag,
		det.amt_max_wr_off, 	det.void_flag,		det.line_desc,
		det.sub_apply_num,	det.sub_apply_type,	det.amt_tot_chg,	
		det.amt_paid_to_date,det.terms_code, 		det.posting_code,	
		det.date_doc,	   	det.amt_inv,		det.gain_home,		
		det.gain_oper,    	det.inv_amt_applied,	det.inv_amt_disc_taken,
		det.inv_amt_max_wr_off,det.inv_cur_code,	det.writeoff_code,
		0,			det.org_id
	FROM	#arinppdt_work det, #arvalpyt hdr
	WHERE	hdr.trx_ctrl_num = det.trx_ctrl_num
	AND	hdr.trx_type = det.trx_type

	
	


	INSERT #arvalnonardet
	(
		trx_ctrl_num   ,	sequence_id     ,	line_desc      ,	tax_code   ,
		gl_acct_code    ,	extended_price  ,	reference_code ,	temp_flag,
		org_id
	)
	SELECT
		trx_ctrl_num   ,	sequence_id     ,	line_desc      ,	tax_code   ,
		gl_acct_code    ,	extended_price  ,	reference_code ,	0,
		org_id
	FROM    #arnonardet_work

	


	INSERT #arvaltax
	(	trx_ctrl_num,		trx_type,		sequence_id,
		tax_type_code,		amt_taxable,		amt_gross,
		amt_tax,		amt_final_tax
	)
	SELECT	trx_ctrl_num,   	trx_type,		sequence_id,
		tax_type_code,		amt_taxable,		amt_gross,
		amt_tax,		amt_final_tax
	FROM	#arinptax_work
	
     	RETURN 0
END
GO
GRANT EXECUTE ON  [dbo].[ARPYPostInsertValTables_SP] TO [public]
GO
