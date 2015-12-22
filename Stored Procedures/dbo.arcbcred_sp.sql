SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO



CREATE PROC [dbo].[arcbcred_sp]  	@trx_ctrl_num varchar(16),	@chargeamt float, 		
				@chargeref varchar(16),		@customer varchar(8),
				@debug_level smallint

	AS

	DECLARE 	@doc_ctrl_num varchar(16),
/* Begin Fix Call 573EG */
			@date_applied int
/* End Fix Call 573EG */

Begin /**/

 IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'tmp/arcbcred.sp' + ', line ' + STR( 1, 5 ) + ' -- ENTRY: '

/* Get the check number */
 SELECT  @doc_ctrl_num=doc_ctrl_num,
/* Begin Fix Call 573EG */
	@date_applied = date_applied
/* End Fix Call 573EG */
 FROM	#arinppyt_work
 WHERE 	trx_ctrl_num = @trx_ctrl_num 

/* Offset the credit memo's on account amount by the amount used on the check */

 INSERT #artrxage_work	(trx_ctrl_num, 
			doc_ctrl_num, 
			apply_to_num, 
			trx_type, 
			date_doc, 
			date_due,  
			date_aging, 
			customer_code, 
			salesperson_code,  
			territory_code, 
			price_code, 
			amount, 
			paid_flag, 
			apply_trx_type, 
			ref_id,  
			group_id, 
			sub_apply_num, 
			sub_apply_type,  
			amt_fin_chg, 
			amt_late_chg, 
			amt_paid, 
			date_applied, 
			cust_po_num, 
			order_ctrl_num,
			rate_home, 
			rate_oper, 
			nat_cur_code, 
			true_amount, 
			date_paid,
			journal_ctrl_num, 
			account_code, 
			payer_cust_code,
			org_id,
			db_action) 
	SELECT		@trx_ctrl_num, 
			@doc_ctrl_num, 
			apply_to_num, 
			2111, 
			date_doc, 
			0,  
/* Begin Fix Call 573EG */
			@date_applied, 
/* End Fix Call 573EG */
			customer_code, 
			salesperson_code,  
			territory_code, 
			price_code, 
			@chargeamt, 
			paid_flag, 
			apply_trx_type, 
			-1,  
			group_id, 
			sub_apply_num, 
			sub_apply_type,  
			amt_fin_chg, 
			amt_late_chg, 
			0, 
/* Begin Fix Call 573EG */
			@date_applied, 
/* End Fix Call 573EG */
			cust_po_num, 
			'',
			rate_home, 
			rate_oper, 
			nat_cur_code, 
			@chargeamt, 
			0,
			'', 
			account_code, 
			@customer,
			org_id,
			1
	FROM artrxage 
	WHERE doc_ctrl_num = @chargeref 
	AND ref_id = 0 
	AND trx_type = 2161

/* Update the credit memo header with the proper amount on account */
	/* Create the Debit Transaction Header for the Chargeback */
  IF NOT EXISTS (SELECT * FROM #artrx_work WHERE doc_ctrl_num = @chargeref AND trx_type=2111 AND payment_type = 3)
	INSERT #artrx_work	(doc_ctrl_num,  trx_ctrl_num,  apply_to_num,  apply_trx_type,
				order_ctrl_num,  doc_desc,  batch_code,  trx_type,  
				date_entered, date_posted, date_applied,  date_doc,
				date_shipped,  date_required,  date_due,  date_aging, 
				customer_code,  ship_to_code,  posting_code,  salesperson_code,
				territory_code,  comment_code,  fob_code,  freight_code, 
				terms_code,  fin_chg_code,  price_code,  recurring_flag,
				recurring_code,  tax_code,  payment_code,  payment_type, 
				cust_po_num,  non_ar_flag,  gl_acct_code,  gl_trx_id,
				prompt1_inp,  prompt2_inp,  prompt3_inp,  prompt4_inp,
				deposit_num,  amt_gross,  amt_freight,  amt_tax,  amt_tax_included,
				amt_discount,  amt_paid_to_date,  amt_net,  amt_on_acct,  
				amt_cost,  amt_tot_chg,  user_id,  void_flag,
				paid_flag,  date_paid,  posted_flag,  commission_flag,
				cash_acct_code,  non_ar_doc_num,  purge_flag, dest_zone_code,
				nat_cur_code, rate_type_home, rate_type_oper, rate_home,
				rate_oper, amt_discount_taken, amt_write_off_given, org_id, db_action)  
	SELECT			doc_ctrl_num,  trx_ctrl_num,  apply_to_num,  apply_trx_type,
				order_ctrl_num,  doc_desc,  batch_code,  trx_type,  
				date_entered, date_posted, date_applied,  date_doc,
				date_shipped,  date_required,  date_due,  date_aging, 
				customer_code,  ship_to_code,  posting_code,  salesperson_code,
				territory_code,  comment_code,  fob_code,  freight_code, 
				terms_code,  fin_chg_code,  price_code,  recurring_flag,
				recurring_code,  tax_code,  payment_code,  payment_type, 
				cust_po_num,  non_ar_flag,  gl_acct_code,  gl_trx_id,
				prompt1_inp,  prompt2_inp,  prompt3_inp,  prompt4_inp,
				deposit_num,  amt_gross,  amt_freight,  amt_tax,  amt_tax_included,
				amt_discount,  amt_paid_to_date,  amt_net,  isnull(round((amt_on_acct - @chargeamt),2),0),  
				amt_cost,  amt_tot_chg,  user_id,  void_flag,
				paid_flag,  date_paid,  posted_flag,  commission_flag,
				cash_acct_code,  non_ar_doc_num,  purge_flag, dest_zone_code,
				nat_cur_code, rate_type_home, rate_type_oper, rate_home,
				rate_oper, amt_discount_taken, amt_write_off_given, org_id, 1
	FROM	artrx
	WHERE 	doc_ctrl_num = @chargeref 
	AND 	trx_type=2111 
	AND 	payment_type = 3

	
 /* Call 1427 ***
 UPDATE #artrx_work
 SET	amt_on_acct = isnull(round((amt_on_acct - @chargeamt),2),0)
 WHERE 	doc_ctrl_num = @chargeref 
 AND 	trx_type=2111 
 AND 	payment_type = 3  
***/


/* Update the paid flag on the credit memo if fully disbursed */
 UPDATE #artrx_work
 SET	paid_flag = 1
 WHERE 	doc_ctrl_num = @chargeref 
 AND 	trx_type=2111 
 AND 	payment_type = 3  
 AND	amt_on_acct = 0

/*** Call 1609 - Update the paid flag on the credit memo aging if fully disbursed ***/

  IF NOT EXISTS (SELECT * FROM #artrxage_work WHERE doc_ctrl_num = @chargeref AND ref_id = 0 AND trx_type = 2161)
 	INSERT #artrxage_work	(trx_ctrl_num, 
			doc_ctrl_num, 
			apply_to_num, 
			trx_type, 
			date_doc, 
			date_due,  
			date_aging, 
			customer_code, 
			salesperson_code,  
			territory_code, 
			price_code, 
			amount, 
			paid_flag, 
			apply_trx_type, 
			ref_id,  
			group_id, 
			sub_apply_num, 
			sub_apply_type,  
			amt_fin_chg, 
			amt_late_chg, 
			amt_paid, 
			date_applied, 
			cust_po_num, 
			order_ctrl_num,
			rate_home, 
			rate_oper, 
			nat_cur_code, 
			true_amount, 
			date_paid,
			journal_ctrl_num, 
			account_code, 
			payer_cust_code,
			org_id,
			db_action) 
	SELECT		trx_ctrl_num, 
			doc_ctrl_num, 
			apply_to_num, 
			trx_type, 
			date_doc, 
			date_due,  
			date_aging, 
			customer_code, 
			salesperson_code,  
			territory_code, 
			price_code, 
			amount, 
			paid_flag, 
			apply_trx_type, 
			ref_id,  
			group_id, 
			sub_apply_num, 
			sub_apply_type,  
			amt_fin_chg, 
			amt_late_chg, 
			amt_paid, 
			date_applied, 
			cust_po_num, 
			order_ctrl_num,
			rate_home, 
			rate_oper, 
			nat_cur_code, 
			true_amount, 
			date_paid,
			journal_ctrl_num, 
			account_code, 
			payer_cust_code,
			org_id,
			1
	FROM artrxage 
	WHERE doc_ctrl_num = @chargeref 
	AND ref_id = 0 
	AND trx_type = 2161

 UPDATE #artrxage_work
 SET	paid_flag = 1
 FROM 	#artrx_work a, #artrxage_work b
 WHERE 	a.doc_ctrl_num = @chargeref 
 AND 	a.trx_type=2111 
 AND 	a.payment_type = 3  
 AND	a.amt_on_acct = 0
 AND 	a.doc_ctrl_num = b.doc_ctrl_num
 AND	b.ref_id = 0 

/*** End Call 1609 ***/   

END /**/                                              
GO
GRANT EXECUTE ON  [dbo].[arcbcred_sp] TO [public]
GO
