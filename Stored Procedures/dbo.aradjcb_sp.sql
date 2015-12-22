SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROC [dbo].[aradjcb_sp]  	@trx_type smallint,		@trx_ctrl_num varchar(16),
				@apply_trx_type smallint,  	@p_apply_num varchar(16),
				@chargeamt float, 		@chargeref varchar(16),
				@customer varchar(8),		@cb_reason_code varchar(8),	
				@cb_responsibility_code varchar(8), @store varchar(16),
				@debug_level smallint = 0
	AS

	DECLARE @num int,  
		@next_tcn char(32), 
		@next_doc char(32),  
		@error_flag int,  
		@posting_code varchar(8),
		@rec_date_doc int,
		@rec_date_due int,
		@result int,
		@salesperson varchar(8),
		@terms varchar(8), 
		@territory varchar(8),
		@today int,
		@batch_code varchar(16),
		@date_applied int,
		@date_doc int,	
		@date_aging int,
		@customer_code varchar(8),
		@non_ar_flag smallint,
		@tax_code varchar(8),
		@rev_acct_code varchar(32),
		@price_code varchar(8),
		@ord_ctrl_num varchar(16),
		@nat_cur_code varchar(8), 
		@rate_type_home varchar(8), 
		@rate_type_oper varchar(8),	
		@rate_home float,
 		@rate_oper float,
		@ship_to_code varchar(8),
		@next_ref integer,
		@prompt2_inp varchar(16),
		@org_id varchar(30)


Begin /**/

 IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/aradjcb.sp" + ", line " + STR( 1, 5 ) + " -- ENTRY: "

/* Get the current date */
	EXEC appdate_sp @today OUTPUT

/* Get fields from the invoice document */
	SELECT 	@terms=terms_code, 
		@salesperson=salesperson_code, 
		@territory=territory_code,
		@posting_code=posting_code, 
		@tax_code=tax_code, 
		@batch_code=batch_code,
		@non_ar_flag=non_ar_flag, 
		@customer_code=customer_code, 
		@date_applied=date_applied,  
		@date_doc=date_doc, 
		@rec_date_due=date_due, 
		@date_aging=date_aging, 
		@price_code=price_code,
		@ord_ctrl_num=order_ctrl_num, 
		@nat_cur_code=nat_cur_code, 
		@rate_type_home=rate_type_home, 
		@rate_type_oper=rate_type_oper,	
		@rate_home=rate_home, 
		@rate_oper=rate_oper,
		@ship_to_code=ship_to_code,
		@prompt2_inp = prompt2_inp,
		@org_id = org_id
	FROM	artrx
	WHERE 	doc_ctrl_num = @p_apply_num AND
		trx_type = @apply_trx_type 

/* Set nulls to spaces */
	IF @salesperson IS NULL SELECT @salesperson=" "
	IF @territory IS NULL SELECT @territory=" "
	IF @posting_code IS NULL SELECT @posting_code=" "
	IF @terms IS NULL SELECT @terms=" "
	IF @price_code IS NULL SELECT @price_code=" "
	IF @ord_ctrl_num IS NULL SELECT @ord_ctrl_num=" "

/* Decrement the paid amount of the invoice by the amount of the chargeback */
	UPDATE 	#artrx_work  
	SET 	amt_paid_to_date = amt_paid_to_date + @chargeamt
	WHERE 	doc_ctrl_num = @p_apply_num AND
		trx_type = @apply_trx_type 
	IF ( @@error != 0 ) 
		BEGIN  
			IF ( @debug_level > 1 ) SELECT "tmp/aradjcb.sp" + ", line " + STR( 1, 5 ) + " -- EXIT: " 
 				RETURN 1 
		END

 	UPDATE 	artrxage  
	SET 	amt_paid = amt_paid + @chargeamt
	WHERE 	doc_ctrl_num = @p_apply_num AND
		trx_type = @apply_trx_type 
	IF ( @@error != 0 ) 
		BEGIN  
			IF ( @debug_level > 1 ) SELECT "tmp/aradjcb.sp" + ", line " + STR( 2, 5 ) + " -- EXIT: " 
 				RETURN 1 
		END

/* Create table entries for the Chargeback */

	/* Get the next control number from the Chargeback document number range */
	EXEC @error_flag = ARGetNextControl_SP 3003,  @next_tcn OUTPUT,  @num OUTPUT

	/* Get the next document number from the Chargeback document number range */
	EXEC @error_flag = ARGetNextControl_SP 3004,  @next_doc OUTPUT,  @num OUTPUT

	/* Create the Debit Transaction Header for the Chargeback */
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

		VALUES  	(@next_doc,  @next_tcn,  @next_doc,  2031, 
				@ord_ctrl_num,  @chargeref,  @batch_code,  2031,  
				@today,  @today,  @date_applied,  @date_doc,
  				0,  0,  @rec_date_due,  @date_aging,
				@customer,  @ship_to_code,  @posting_code,  @salesperson,
				@territory,  " ",  " ",  " ",
				@terms,  " ",  @price_code,  0,
				" ",  @tax_code,  " ",  0,
				@chargeref,  @non_ar_flag,  " ",  " ",
				@trx_ctrl_num,  @prompt2_inp,  " ",  " ",
				" ",  @chargeamt,  0,  0, 0,
				0, 0,  @chargeamt,  0, 
				0,  @chargeamt,  1, 0,
				0,  0,  1,  0, 
				" ",  " ",  0," ",
				@nat_cur_code, @rate_type_home, @rate_type_oper, @rate_home,
				@rate_oper, 0, 0, @org_id, 1)
	IF ( @@error != 0 ) 
		BEGIN  
			IF ( @debug_level > 1 ) SELECT "tmp/aradjcb.sp" + ", line " + STR( 3, 5 ) + " -- EXIT: " 
 			RETURN 3 
		END
 
	/* Insert the invoice information record for the chargeback */
	INSERT	artrxxtr 
	( 
	 	rec_set,
	 	amt_due,
	 	amt_paid,
	 	trx_type,
	 	trx_ctrl_num,
	 	addr1,
	 	addr2,
	 	addr3,
	 	addr4,
	 	addr5,
	 	addr6,
	 	ship_addr1,
	 	ship_addr2,
	 	ship_addr3,
	 	ship_addr4,
	 	ship_addr5,
	 	ship_addr6,
	 	attention_name,
	 	attention_phone
	)
	SELECT		 
	 	1,
	 	@chargeamt,
	 	0,
	 	2031,
	 	@next_tcn,
	 	addr1,
	 	addr2,
	 	addr3,
	 	addr4,
	 	addr5,
	 	addr6,
	 	addr1,
	 	addr2,
	 	addr3,
	 	addr4,
	 	addr5,
	 	addr6,
	 	attention_name,
	 	attention_phone
	FROM	armaster 
	WHERE	customer_code=@customer 
	AND	address_type=0

	/* If a shipto code has been specified, retrieve the shipto address */
	IF @ship_to_code is not null
		UPDATE 	artrxxtr	
		SET	ship_addr1 = a.addr1,
			ship_addr2 = a.addr2,
			ship_addr3 = a.addr3,
			ship_addr4 = a.addr4,
			ship_addr5 = a.addr5,
			ship_addr6 = a.addr6,
			attention_name = a.attention_name,
			attention_phone = a.attention_phone
		FROM	artrxxtr, armaster a
		WHERE	trx_ctrl_num=@next_tcn
		AND	a.customer_code=@customer
		AND	a.ship_to_code=@ship_to_code
		AND	a.address_type=1

	/* Insert the chargeback detail fields for the new chargeback */
	/*insert chargeref field no arcninv*/
	INSERT arcbinv 	(trx_ctrl_num,
				cb_reason_code, 
 				cb_status_code, 
 				cb_responsibility_code, 
				store_number,
				chargeref)

		VALUES		(@next_tcn,
				@cb_reason_code, 
 				"DE", 
 				@cb_responsibility_code, 
				@store,
				@chargeref)
 	IF ( @@error != 0 ) 
		BEGIN  
			IF ( @debug_level > 1 ) SELECT "tmp/archgbk.sp" + ", line " + STR( 3, 5 ) + " -- EXIT: " 
 			RETURN 6 
		END

	/* Create the Debit aging detail information for the Chargeback */
	SELECT @rev_acct_code= dbo.IBAcctMask_fn(rev_acct_code,@org_id) from araccts where posting_code=@posting_code

	INSERT 	artrxcdt  	(doc_ctrl_num, trx_ctrl_num, sequence_id, 
			   	trx_type, location_code,  item_code, bulk_flag, 
				date_entered,  date_posted, date_applied, line_desc, 
 				qty_ordered, qty_shipped, unit_code,  unit_price, 
				weight, amt_cost,  serial_id, tax_code, 
				gl_rev_acct, discount_prc, discount_amt, rma_num,  
				return_code, qty_returned, new_gl_rev_acct, disc_prc_flag,
				extended_price, calc_tax, org_id )

		VALUES		(@next_doc, @next_tcn, 1,
				2031, " ", " ", 0, @today, @today, @date_applied, " ",
				1, 1, " ", @chargeamt, 0, 0, 1, @tax_code,
				@rev_acct_code, 0, 0, " ", " ", 0, " ", 0,
				@chargeamt, 0, @org_id)


	/* Create the Debit aging information for the Chargeback */
	INSERT 	artrxage	(trx_ctrl_num, doc_ctrl_num, apply_to_num, trx_type, 
				date_doc, date_due,  date_aging, customer_code, 
				salesperson_code,  territory_code, price_code, amount, 
 				paid_flag, apply_trx_type, ref_id,  group_id, 
				sub_apply_num, sub_apply_type,  amt_fin_chg, amt_late_chg, 
				amt_paid, date_applied, cust_po_num, order_ctrl_num,
				rate_home, rate_oper, nat_cur_code, true_amount, date_paid,
 				journal_ctrl_num, account_code, payer_cust_code, org_id) 

		VALUES		(@next_tcn,  @next_doc,  @next_doc,  2031,
				@date_doc, @rec_date_due,  @date_aging, @customer,
				@salesperson, @territory,  @price_code, @chargeamt,
				0, 2031, 1,  0,
				@next_doc,  2031,  0,  0,
				0,   @date_applied,  @chargeref,  @ord_ctrl_num,
				@rate_home, @rate_oper, @nat_cur_code, @chargeamt, @date_applied,
				" ", " ", @customer, @org_id)
	IF ( @@error != 0 ) 
		BEGIN  
			IF ( @debug_level > 1 ) SELECT "tmp/aradjcb.sp" + ", line " + STR( 4, 5 ) + " -- EXIT: " 
 			RETURN 4 
		END
  

	/* Create the Credit aging information for the Chargeback */
		SELECT @next_ref = ISNULL(MAX(ref_id) + 1,1)
		FROM artrxage 
		WHERE apply_to_num = @p_apply_num 
		AND apply_trx_type = 2031
		AND trx_type = 2111

		INSERT 	artrxage	(trx_ctrl_num, doc_ctrl_num, apply_to_num, trx_type, 
					date_doc, date_due,  date_aging, customer_code, 
					salesperson_code,  territory_code, price_code, amount, 
 					paid_flag, apply_trx_type, ref_id,  group_id, 
					sub_apply_num, sub_apply_type,  amt_fin_chg, amt_late_chg, 
					amt_paid, date_applied, cust_po_num, order_ctrl_num,
					rate_home, rate_oper, nat_cur_code, true_amount, date_paid,
 					journal_ctrl_num, account_code, payer_cust_code, org_id) 

			VALUES		(@next_tcn,  @next_doc,  @p_apply_num,  2111,
					@date_doc, @rec_date_due,  @date_aging, @customer_code,
					@salesperson, @territory,  @price_code, (@chargeamt * -1),
					0, 2031, @next_ref,  0,
					@p_apply_num,  2031,  0,  0,
					0,   @date_applied,  @chargeref,  @ord_ctrl_num,
					@rate_home, @rate_oper, @nat_cur_code, (@chargeamt * -1), @date_applied,
					" ", " ", @customer_code, @org_id)
		IF ( @@error != 0 ) 
			BEGIN  
				IF ( @debug_level > 1 ) SELECT "tmp/aradjcb.sp" + ", line " + STR( 5, 5 ) + " -- EXIT: " 
 				RETURN 5 
			END
  
  
END /**/                                              
GO
GRANT EXECUTE ON  [dbo].[aradjcb_sp] TO [public]
GO
