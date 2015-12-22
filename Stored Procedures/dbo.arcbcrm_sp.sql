SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROC [dbo].[arcbcrm_sp]  	@trx_type smallint,		@trx_ctrl_num varchar(16),
				@chargeamt float, 		@chargeref varchar(16),
				@customer varchar(8),	
				@cb_reason_code varchar(8),	@cb_responsibility_code varchar(8),
				@store varchar(16),		@debug_level smallint = 0,
/* Begin mod: CB0002 - Add reason description */
				@cb_reason_desc varchar(40)
/* End mod: CB0002 */
	AS

	DECLARE @num int,  
		@next_tcn char(32), 
		@next_pay_tcn char(32),
		@next_doc char(32),
 		@err_rtn int,  
		@error_flag int,  
		@posting_code varchar(8),
		@result int,
		@salesperson varchar(8),
		@terms varchar(8), 
		@territory varchar(8),
		@today int,
		@batch_code varchar(16),
		@date_entered int,
		@date_applied int,
		@date_doc int,
		@customer_code varchar(8),
		@non_ar_flag smallint,
		@prompt1_inp varchar(30),
		@prompt2_inp varchar(30),
		@prompt3_inp varchar(30),
		@prompt4_inp varchar(30),
		@tax_code varchar(8),
		@rev_acct_code varchar(32),
		@ar_acct_code varchar(32),
		@price_code varchar(8),
		@ord_ctrl_num varchar(16),
		@nat_cur_code varchar(8), 
		@rate_type_home varchar(8), 
		@rate_type_oper varchar(8),	
		@rate_home float,
 		@rate_oper float,
		@check_num varchar(16),
/* Begin mod: CB0004 - Add working variable for customer code */
		@cb_customer varchar(8),
/* End mod: CB0004 */
/* Begin PAT102901 */
		@p_apply_num varchar(16),
		@inv_date_due int,
		@inv_date_aging int,
		@apply_trx_type int,
		@next_ref int,
		@inv_customer varchar(8),
/* End PAT102901 */
		@org_id varchar(30)

Begin /**/

/* Set the amount to be positive */
SELECT @chargeamt = (@chargeamt * -1)

/* Get the current date */
	EXEC appdate_sp @today OUTPUT

/* Get fields from the customer */	
	SELECT 	@terms=terms_code, 
		@salesperson=salesperson_code, 
		@territory=territory_code,
		@posting_code=posting_code, 
		@tax_code=tax_code
	FROM	armaster
	WHERE 	customer_code = @customer
	SELECT 'tmp/archgbk.sp' + ', line ' + STR( 1, 5 ) + 'CUSTOMER ' + @customer 

/* Select currency information from check header */
	SELECT  @nat_cur_code=nat_cur_code, 
		@rate_type_home=rate_type_home, 
		@rate_type_oper=rate_type_oper,	
		@rate_home=rate_home, 
		@rate_oper=rate_oper,
		@check_num = doc_ctrl_num,
		@org_id = org_id
	FROM	#arinppyt_work
	WHERE 	trx_ctrl_num = @trx_ctrl_num AND
		trx_type = @trx_type  

/* Set nulls to spaces */
	IF @salesperson IS NULL SELECT @salesperson=' '
	IF @territory IS NULL SELECT @territory=' '
	IF @posting_code IS NULL SELECT @posting_code=' '
	IF @terms IS NULL SELECT @terms=' '
	IF @price_code is NULL SELECT @price_code=' '
	IF @ord_ctrl_num is NULL SELECT @ord_ctrl_num=' '


/* Get defaults from the check header */
	SELECT  @customer_code=''
	SELECT  @batch_code=batch_code,  
		@date_entered=date_entered,  
		@date_applied=date_applied,  
		@date_doc=date_doc,
		@customer_code=customer_code, 
		@non_ar_flag=non_ar_flag
	FROM 	#arinppyt_work  
	WHERE 	trx_ctrl_num = @trx_ctrl_num AND
 		trx_type = @trx_type  
	IF ( @@error != 0 ) 
		BEGIN  
			IF ( @debug_level > 1 ) SELECT 'tmp/archgbk.sp' + ', line ' + STR( 2, 5 ) + ' -- EXIT: ' 
 			RETURN 2 
		END
/* Begin: PAT102901 - Decrement the paid amount of the invoice by the amount of the chargeback */
/*read data from the new temp table #archgbk_arinppdt*/
	IF EXISTS(SELECT * FROM #archgbk_arinppdt WHERE trx_ctrl_num = @trx_ctrl_num and chargeref = @chargeref and apply_to_num <> '')
		BEGIN
			SELECT 	@p_apply_num = apply_to_num
			FROM 	#archgbk_arinppdt
			WHERE 	trx_ctrl_num = @trx_ctrl_num 
			AND	chargeref = @chargeref 

			SELECT 	@terms=terms_code, 
				@salesperson=salesperson_code, 
				@territory=territory_code,
				@posting_code=posting_code, 
				@tax_code=tax_code, 
				@price_code=price_code,
				@ord_ctrl_num=order_ctrl_num, 
				@nat_cur_code=nat_cur_code, 
				@rate_type_home=rate_type_home, 
				@rate_type_oper=rate_type_oper,	
				@rate_home=rate_home, 
				@rate_oper=rate_oper,
				@inv_date_due=date_due,
				@inv_date_aging=date_aging,
				@apply_trx_type = trx_type,
				@inv_customer = customer_code,
				@org_id = org_id
			FROM	#artrx_work
			WHERE 	doc_ctrl_num = @p_apply_num AND
				trx_type in (2021, 2031)
			
			UPDATE 	#artrx_work  
			SET 	amt_paid_to_date= amt_paid_to_date - @chargeamt,
				db_action= db_action | 1 
			WHERE 	doc_ctrl_num = @p_apply_num AND
				trx_type = @apply_trx_type
			IF ( @@error != 0 ) 
				BEGIN  
					IF ( @debug_level > 1 ) SELECT 'tmp/archgbk.sp' + ', line ' + STR( 1, 5 ) + ' -- EXIT: ' 
 					RETURN 1 
				END

			UPDATE 	#artrxage_work  
			SET 	amt_paid= amt_paid - @chargeamt,
				db_action= db_action | 1 
			WHERE 	doc_ctrl_num = @p_apply_num AND
				trx_type = @apply_trx_type
			IF ( @@error != 0 ) 
				BEGIN  
					IF ( @debug_level > 1 ) SELECT 'tmp/archgbk.sp' + ', line ' + STR( 2, 5 ) + ' -- EXIT: ' 
 					RETURN 1 
				END
		END

/* End: PAT102901 */
/* Begin mod: CB0004 - 	If a customer code was specified on the chargeback then use it.  
			This is for check related chargebacks only */
/*read data from the new temp table #archgbk_arinppdt*/
	SELECT 	@cb_customer = customer_code
	FROM	#archgbk_arinppdt
	WHERE 	trx_ctrl_num = @trx_ctrl_num AND
		chargeref = @chargeref

	IF @cb_customer IS NOT NULL
		SELECT	@customer_code = @cb_customer
/* End mod: CB0004 */

/* Create table entries for the Credit Chargeback */

	/* Get the next control number from the Chargeback document number range */
	EXEC @error_flag = ARGetNextControl_SP 3000,  @next_tcn OUTPUT,  @num OUTPUT

	/* Get the next document number from the Chargeback document number range */
	EXEC @error_flag = ARGetNextControl_SP 3001,  @next_doc OUTPUT,  @num OUTPUT

	/* Get the next control number from the payment number range */
	EXEC @error_flag = ARGetNextControl_SP 2010,  @next_pay_tcn OUTPUT,  @num OUTPUT

	/* Create the Transaction Header for the Credit Chargeback */
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
				deposit_num,  amt_gross,  amt_freight,  amt_tax, amt_tax_included,
				amt_discount,  amt_paid_to_date,  amt_net,  amt_on_acct,  
				amt_cost,  amt_tot_chg,  user_id,  void_flag,
				paid_flag,  date_paid,  posted_flag,  commission_flag,
				cash_acct_code,  non_ar_doc_num,  purge_flag, dest_zone_code,
				nat_cur_code, rate_type_home, rate_type_oper, rate_home,
				rate_oper, amt_discount_taken, amt_write_off_given, org_id, db_action)  

		VALUES  	(@next_doc,  @next_tcn,  @next_doc,  0, 
				@check_num,  @chargeref,  @batch_code,  2032,  
				@date_entered,  @today,  @date_applied,  @date_doc,
  				0,  0,  0,  0,
				@customer_code,  ' ',  @posting_code,  @salesperson,
				@territory,  ' ',  ' ',  ' ',
				@terms,  ' ',  @price_code,  1,
				' ',  @tax_code,  ' ',  0,
				@chargeref,  @non_ar_flag,  ' ',  ' ',
				@trx_ctrl_num,  @check_num,  ' ',  ' ', 
				' ',  @chargeamt,  0,  0, 0,
				0, 0,  @chargeamt,  0, 
				0,  0,  1, 0,
				0,  0,  1,  0, 
				' ',  ' ',  0,' ',
				@nat_cur_code, @rate_type_home, @rate_type_oper, @rate_home,
				@rate_oper, 0, 0, @org_id, 1)
	IF ( @@error != 0 ) 
		BEGIN  
			IF ( @debug_level > 1 ) SELECT 'tmp/archgbk.sp' + ', line ' + STR( 3, 5 ) + ' -- EXIT: ' 
 			RETURN 3 
		END
 
	/* Insert the chargeback detail fields for the new chargeback
	Add Insert of chargeref */
	INSERT arcbinv 		(trx_ctrl_num,
				cb_reason_code, 
 				cb_status_code, 
 				cb_responsibility_code, 
				store_number,
/* Begin mod: CB0002 - Add reason description */
				cb_reason_desc,
				chargeref)
/* End mod: CB0002 */

		VALUES		(@next_tcn,
				@cb_reason_code, 
 				'DE', 
 				@cb_responsibility_code, 
				@store,
/* Begin mod: CB0002 - Add reason description */
				@cb_reason_desc,
				@chargeref)
/* End mod: CB0002 */
 	IF ( @@error != 0 ) 
		BEGIN  
			IF ( @debug_level > 1 ) SELECT 'tmp/archgbk.sp' + ', line ' + STR( 3, 5 ) + ' -- EXIT: ' 
 			RETURN 6 
		END

	/* Create the detail information for the Credit Chargeback */
	/*Add mask account*/
	SELECT @rev_acct_code= dbo.IBAcctMask_fn(rev_acct_code,@org_id), 
		@ar_acct_code=dbo.IBAcctMask_fn(ar_acct_code,@org_id)
	from araccts where posting_code=@posting_code


	INSERT 	artrxcdt  	(doc_ctrl_num, trx_ctrl_num, sequence_id, 
			   	trx_type, location_code,  item_code, bulk_flag, 
				date_entered,  date_posted, date_applied, line_desc, 
 				qty_ordered, qty_shipped, unit_code,  unit_price, 
				weight, amt_cost,  serial_id, tax_code, 
				gl_rev_acct, discount_prc, discount_amt, rma_num,  
				return_code, qty_returned, new_gl_rev_acct, disc_prc_flag, 
				extended_price, calc_tax, org_id )

		VALUES		(@next_doc, @next_tcn, 1,
				2032, ' ', ' ', 0, @today, @today, @date_applied, ' ',
				0, 0, ' ', @chargeamt, 0, 0, 1, @tax_code,
				@rev_acct_code, 0, 0, ' ', ' ', 1, ' ', 0,
				@chargeamt, 0, @org_id)
				

	/* Create the payment Transaction Header for the Cedit Chargeback */
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

		VALUES  	(@next_doc,  @next_pay_tcn,  @next_doc,  0, 
				@ord_ctrl_num,  @chargeref,  @batch_code,  2111,  
				@date_entered,  @today,  @date_applied,  @date_doc,
  				0,  0,  @today,  @today,
				@customer_code,  ' ',  @posting_code,  @salesperson,
				@territory,  ' ',  ' ',  ' ',
				@terms,  ' ',  @price_code,  0,
				' ',  @tax_code,  ' ',  3,
				@chargeref,  @non_ar_flag,  ' ',  ' ',
/* Begin mod: PAT102901				@trx_ctrl_num,  @check_num,  ' ',  ' ', */
				CASE
				  WHEN @p_apply_num = '' OR @p_apply_num IS NULL THEN @trx_ctrl_num
				  ELSE ' '
				END,  
				@check_num,  ' ',  ' ',
/* End mod: PAT102901 */
				' ',  0,  0,  0, 0,
				0, 0,  @chargeamt,  @chargeamt,
				0,  0,  1, 0,
				0,  0,  1,  0, 
				' ',  ' ',  0,' ',
				@nat_cur_code, @rate_type_home, @rate_type_oper, @rate_home,
				@rate_oper, 0, 0, @org_id, 1)
	IF ( @@error != 0 ) 
		BEGIN  
			IF ( @debug_level > 1 ) SELECT 'tmp/archgbk.sp' + ', line ' + STR( 3, 5 ) + ' -- EXIT: ' 
 			RETURN 3 
		END
 

	/* Create the payment aging information for the Credit Chargeback */
	INSERT 	#artrxage_work	(trx_ctrl_num, doc_ctrl_num, apply_to_num, trx_type, 
				date_doc, date_due,  date_aging, customer_code, 
				salesperson_code,  territory_code, price_code, amount, 
 				paid_flag, apply_trx_type, ref_id,  group_id, 
				sub_apply_num, sub_apply_type,  amt_fin_chg, amt_late_chg, 
				amt_paid, date_applied, cust_po_num, order_ctrl_num,
				rate_home, rate_oper, nat_cur_code, true_amount, date_paid,
 				journal_ctrl_num, account_code, payer_cust_code, org_id,
				db_action) 

		VALUES		(@next_pay_tcn,  @next_doc,  @next_doc,  2161,
				@date_doc, @today,  @today, @customer_code,
				@salesperson, @territory,  @price_code, (@chargeamt * -1),
				0, 2161, 0,  0,
				@next_doc,  2161,  0,  0,
				0,   @date_applied,  @chargeref,  @ord_ctrl_num,
				@rate_home, @rate_oper, @nat_cur_code, (@chargeamt * -1), @date_applied,
				' ', @ar_acct_code, @customer_code, @org_id,
				1)
	IF ( @@error != 0 ) 
		BEGIN  
			IF ( @debug_level > 1 ) SELECT 'tmp/archgbk.sp' + ', line ' + STR( 4, 5 ) + ' -- EXIT: ' 
 			RETURN 4 
		END

/* Begin: PAT102901 - Add aging record to offset credit memo on invoice */
/*read data from the new temp table*/
	IF EXISTS(SELECT * FROM #archgbk_arinppdt WHERE trx_ctrl_num = @trx_ctrl_num and chargeref = @chargeref and apply_to_num <> '')
		BEGIN
			SELECT @next_ref = ISNULL(MAX(ref_id) + 1,1)
			FROM artrxage 
			WHERE apply_to_num = @p_apply_num 
			AND apply_trx_type = @apply_trx_type
			AND trx_type = 2111

			INSERT 	#artrxage_work	(trx_ctrl_num, doc_ctrl_num, apply_to_num, trx_type, 
						date_doc, date_due,  date_aging, customer_code, 
						salesperson_code,  territory_code, price_code, amount, 
 						paid_flag, apply_trx_type, ref_id,  group_id, 
						sub_apply_num, sub_apply_type,  amt_fin_chg, amt_late_chg, 
						amt_paid, date_applied, cust_po_num, order_ctrl_num,
						rate_home, rate_oper, nat_cur_code, true_amount, date_paid,
 						journal_ctrl_num, account_code, payer_cust_code, org_id,
						db_action) 

				VALUES		(@next_tcn,  @next_doc,  @p_apply_num,  2111,
						@date_doc, @inv_date_due,  @inv_date_aging, @inv_customer,
						@salesperson, @territory,  @price_code, @chargeamt,
						0, @apply_trx_type, @next_ref,  0,
						@p_apply_num,  @apply_trx_type,  0,  0,
						0,   @date_applied,  @chargeref, @ord_ctrl_num,
						@rate_home, @rate_oper, @nat_cur_code, @chargeamt, @date_applied,
						' ', ' ', @inv_customer, @org_id,
						1)
			IF ( @@error != 0 ) 
				BEGIN  
					IF ( @debug_level > 1 ) SELECT 'tmp/archgbk.sp' + ', line ' + STR( 5, 5 ) + ' -- EXIT: ' 
 					RETURN 5 
				END
		END
  
  
END /**/                                              
GO
GRANT EXECUTE ON  [dbo].[arcbcrm_sp] TO [public]
GO
