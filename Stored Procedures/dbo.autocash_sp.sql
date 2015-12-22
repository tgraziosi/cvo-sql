SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


/*                                                      
               Confidential Information                  
    Limited Distribution of Authorized Persons Only       
    Created 2008 and Protected as Unpublished Work       
          Under the U.S. Copyright Act of 1976            
 Copyright (c) 2008 Epicor Software Corporation, 2008    
                  All Rights Reserved                    
*/

/* 
** Description		:  Create AR Batches for Autocash
*/

CREATE PROCEDURE [dbo].[autocash_sp] @checks_processed int OUTPUT, @total_value money OUTPUT, @on_account money OUTPUT,
			     @tot_payments money OUTPUT, @deductions money OUTPUT, @run_from_client int, @from_tcn varchar(16) OUTPUT, 
			     @to_tcn varchar(16) OUTPUT, @checks_in_error int OUTPUT, @def_curr_code varchar(8) OUTPUT, 
			     @date varchar(10) OUTPUT

AS

DECLARE @customer varchar(8), 	
	@check varchar(16), 	 
	@next_tcn varchar(16), 	
	@num int, 	
	@today int,		
	@check_date int, 	 
	@check_amount float, 		
	@apply_to_num varchar(16), 	
	@amt_applied float, 	
	@amt_disc_taken float, 	 
	@date_aging int, 		
	@amt_paid_to_date float,
	@terms_code varchar(8),	
	@posting_code varchar(8),
	@amt_tot_chg float, 		
	@amt_gross float, 	
	@payment_error int,	
	@check_error int,	 
	@total_payments float,		
	@seq_counter int,
	@test_cust varchar(16),	
	@error_flag int,	 
	@amt_on_acct float,		
	@batch_number varchar(20),			 
	@paid_flag int,		
	@first_tcn varchar(16), 
	@last_tcn varchar(16),	 
	@error_message varchar(120),	
	@hold_flag smallint,	
	@date_applied int,	 
	@last_check varchar(16),	
	@last_check_amount float,
	@last_check_date int,	
	@last_customer varchar(8), 
	@micr_number varchar(20), 
	@cb_installed int,
	@total_cbs float, 	
	@amt_loaded float, 	 
	@payment_count int,		
	@currency_code varchar(8),
	@mc_flag smallint, 	 
	@oper_currency varchar(8),
	@return_code int,
	@ck_divide_flag_h smallint,
	@description varchar(40),
	@result int,
	@settlement_ctrl_num varchar(16),
/* Sage */
	@customer_name varchar(40)
/* Sage */

	/* Suppress the display of row counts affected by each statement */
	SET NOCOUNT ON

	/* Create temporary tables */                                               

	CREATE TABLE #arinppyt_work
	(
	trx_ctrl_num		varchar(16),
	doc_ctrl_num		varchar(16),
	trx_desc		varchar(40),
	batch_code		varchar(16),
	trx_type		smallint,
	non_ar_flag		smallint,
	non_ar_doc_num	varchar(16),
	gl_acct_code		varchar(32), 
	date_entered		int,
	date_applied		int,
	date_doc		int,
	customer_code		varchar(8),
	payment_code		varchar(8),
	payment_type		smallint,
	amt_payment		float,
	amt_on_acct		float,
	prompt1_inp		varchar(30),
	prompt2_inp		varchar(30),
	prompt3_inp		varchar(30),
	prompt4_inp		varchar(30),
	deposit_num		varchar(16),
	bal_fwd_flag		smallint, 
	printed_flag		smallint,
	posted_flag		smallint,
	hold_flag		smallint,
	wr_off_flag		smallint,
	on_acct_flag		smallint, 
	user_id		smallint, 
	max_wr_off		float,	 
	days_past_due		int,	 
	void_type		smallint, 
	cash_acct_code	varchar(32),
	origin_module_flag	smallint	NULL,
	db_action		smallint,
	process_group_num	varchar(16)	NULL,
	temp_flag		smallint	NULL,
	source_trx_ctrl_num	varchar(16)	NULL,
	source_trx_type	smallint	NULL,
	nat_cur_code		varchar(8), 
	rate_type_home	varchar(8),
	rate_type_oper	varchar(8),
	rate_home		float,
	rate_oper		float, 
	amt_discount		float NULL,
	reference_code varchar(8) NULL,
	settlement_ctrl_num varchar(16) NULL
	)

	CREATE INDEX arinppyt_work_ind_0
	ON #arinppyt_work( trx_ctrl_num, trx_type, customer_code )

	CREATE INDEX arinppyt_work_ind_1
	ON #arinppyt_work( batch_code, trx_ctrl_num )

	CREATE INDEX arinppyt_work_ind_2
	ON #arinppyt_work( cash_acct_code )

	CREATE INDEX arinppyt_work_ind_3
	ON #arinppyt_work( customer_code )

	CREATE INDEX arinppyt_work_ind_4
	ON #arinppyt_work( date_applied )

	CREATE INDEX arinppyt_work_ind_5
	ON #arinppyt_work( payment_type )

	CREATE INDEX arinppyt_work_ind_6
	ON #arinppyt_work( payment_code )
	
	CREATE INDEX #arinppyt_work_ind_7 
	ON #arinppyt_work (trx_ctrl_num ) 


	CREATE TABLE #arinppdt_work
	(
	trx_ctrl_num		varchar(16),
	doc_ctrl_num		varchar(16),
	sequence_id		int,
	trx_type		smallint,
	apply_to_num		varchar(16),
	apply_trx_type	smallint,
	customer_code		varchar(8),
	payer_cust_code	varchar(8)	NULL,
	date_aging		int,
	amt_applied		float,
	amt_disc_taken	float,
	wr_off_flag		smallint,
	amt_max_wr_off	float,
	void_flag		smallint,
	line_desc		varchar(40),
	sub_apply_num		varchar(16),
	sub_apply_type	smallint,
	amt_tot_chg		float,	
	amt_paid_to_date	float,	
	terms_code		varchar(8),	
	posting_code		varchar(8),	
	date_doc		int,	
	amt_inv		float,
	gain_home		float,		
	gain_oper		float,
	inv_amt_applied	float,
	inv_amt_disc_taken	float,
	inv_amt_max_wr_off	float,		
	inv_cur_code		varchar(8),	
	db_action		smallint,
	temp_flag		smallint	NULL
	)

	CREATE INDEX arinppdt_work_ind_0
	ON #arinppdt_work(apply_to_num, apply_trx_type, trx_ctrl_num, trx_type)

	CREATE INDEX arinppdt_work_ind_1
	ON #arinppdt_work(trx_ctrl_num, trx_type, sequence_id)

	CREATE INDEX arinppdt_work_ind_2
	ON #arinppdt_work(doc_ctrl_num, trx_type, sequence_id)

	CREATE INDEX #arinppdt_work_ind_3 
	ON #arinppdt_work (trx_ctrl_num) 
	
	CREATE TABLE #checks (batch_number varchar(20), micr_number varchar(20), customer_code varchar(8), check_number varchar(16), check_amount float,
 			      check_date int, date_applied int, currency_code varchar(8) )
	
	CREATE TABLE #payments (batch_number varchar(20), micr_number varchar(20), customer_code varchar(8), check_number varchar(16), apply_to_num varchar(16), 
			        amt_applied float, amt_disc_taken float, payment_count int)

	CREATE TABLE #archgbk 
	(
		trx_ctrl_num varchar(16) NOT NULL,
		chargeref varchar(16) NOT NULL, 
		chargeamt float NOT NULL,
		cb_reason_code varchar(8) NULL, 
		cb_responsibility_code varchar(8) NULL, 
		store_number varchar(16) NULL,
		apply_to_num varchar(16) NULL,
		nat_cur_code varchar(8) NULL,
		customer_code varchar(8) NULL  
		)
	CREATE INDEX #archgbk_ind_0 ON #archgbk(trx_ctrl_num)
	CREATE UNIQUE INDEX #archgbk_ind_1 ON #archgbk(trx_ctrl_num, chargeref)  

	CREATE TABLE #arcbtot
	(
		trx_ctrl_num varchar(16) NOT NULL,
		total_chargebacks float
	)
	CREATE INDEX arcbtot_ind_0 ON #arcbtot(trx_ctrl_num)


	/* Get today's date */
	EXEC appdate_sp @today OUTPUT

	/* Is the Chargeback module installed */
	SELECT @cb_installed = 0
	IF EXISTS (SELECT app_id FROM CVO_Control..sminst WHERE app_id=2001) 
		SELECT @cb_installed = 1

	/* Is the database multi-currency */
	SELECT 	@mc_flag=mc_flag, 
		@def_curr_code=def_curr_code 
	FROM arco

	/* Retrieve the operational currency code */
	SELECT @oper_currency=oper_currency 
	FROM glco
	
	/* Get the Settlement Control Number 
	EXEC @error_flag = ARGetNextControl_SP 	2015,  
						@settlement_ctrl_num OUTPUT,  
						@num OUTPUT*/

	/* Clear error table */
	DELETE autocash_errors

	/* Get the customer codes for each check */
/* Sage */
	SELECT @customer_name=' '
	EXEC acgetcst_sp @customer_name	
/* Sage */ 

	/* Load the processing tables from the autocash table */
	EXEC acldtbls_sp

	/* Read each record from the temporary processing table */
	DECLARE check_cur CURSOR FOR 
		SELECT 	batch_number, 
			micr_number, 
			customer_code, 
			check_number, 
			check_amount, 
			check_date, 
			date_applied, 
			currency_code 
		FROM 	#checks

	/* Open the check cursor */
	OPEN 	check_cur

	/* Read the first entry from the #checks table */
	FETCH 	check_cur 
	INTO 	@batch_number, 
		@micr_number, 
		@customer, 
		@check, 
		@check_amount, 
		@check_date, 
		@date_applied,
		@currency_code

	/* If the read of the #checks table was successful then enter the While loop */
	WHILE @@fetch_status = 0
   	BEGIN

/* Sage */
		SELECT @customer_name = address_name
		FROM armaster
		WHERE customer_code = @customer and address_type = 0
/* Sage */
/* Begin Fix: 012005 - Get the Settlement Control Number */
		EXEC @error_flag = ARGetNextControl_SP 	2015,  
						@settlement_ctrl_num OUTPUT,  
						@num OUTPUT
/* End Fix: 012005 */

		/* Create the check from the temporary processing tables */
		 EXEC @return_code = accrcks_sp @customer,
						@check,  
						@check_date, 
						@check_amount, 
						@date_applied,	
						@currency_code,
						@batch_number,
						@micr_number,
						@mc_flag,
						@def_curr_code,
						@oper_currency,
						@cb_installed,
						@ck_divide_flag_h OUTPUT,
						@total_cbs OUTPUT,
						@run_from_client,
						@settlement_ctrl_num, 
/* Sage */
						@customer_name
/* Sage */
/* Begin Fix: 012005 */
		IF @run_from_client = 3
			SELECT @description = 'Chargeback/Credit Memo Match' 
		ELSE
			SELECT @description = 'Autocash '
		EXEC @result = autostl_sp @description, @settlement_ctrl_num
		IF @result != 0
		BEGIN
			ROLLBACK TRANSACTION AUTOCASH_LOAD
			RETURN 1
		END
/* End Fix: 012005 */
							
		/* Read the next check */
		FETCH 	check_cur 
		INTO 	@batch_number, 
			@micr_number, 
			@customer, 
			@check, 
			@check_amount, 
			@check_date, 
			@date_applied,
			@currency_code

   	END


	/* Close and deallocate the check cursor, and deallocate the payment cursor */
	CLOSE check_cur
	DEALLOCATE check_cur
	
	BEGIN TRANSACTION AUTOCASH_LOAD
	
	/* Create batch records for batch mode */
	SELECT @description = 'Autocash '
	IF EXISTS (SELECT batch_proc_flag FROM arco WHERE batch_proc_flag = 1)
	BEGIN
		IF @run_from_client = 3
			SELECT @description = 'Chargeback/Credit Memo Match' 
		ELSE
			SELECT @description = 'Autocash '

		EXEC @result = autobtch_sp @description
		IF @result != 0
		BEGIN
			ROLLBACK TRANSACTION AUTOCASH_LOAD
			RETURN 1
		END
	END

/* Begin Fix: 012005 
	EXEC @result = autostl_sp @description, @settlement_ctrl_num
	IF @result != 0
	BEGIN
		ROLLBACK TRANSACTION AUTOCASH_LOAD
		RETURN 1
	END
   End Fix: 012005 */
	
	/* Fix for service pack 5a */
	UPDATE #arinppyt_work SET trx_ctrl_num = RTRIM(trx_ctrl_num)
	UPDATE #arinppdt_work SET trx_ctrl_num = RTRIM(trx_ctrl_num)
	/* End fix */

		INSERT	arinppyt 
		( 
			trx_ctrl_num,		doc_ctrl_num,		trx_desc,
		 	batch_code,		trx_type,		non_ar_flag,
			non_ar_doc_num,	gl_acct_code,		date_entered,
		 	date_applied,		date_doc,		customer_code,
		 	payment_code,		payment_type,		amt_payment,
			amt_on_acct,		prompt1_inp,		prompt2_inp,
			prompt3_inp,		prompt4_inp,		deposit_num,
			bal_fwd_flag,		printed_flag,		posted_flag,
			hold_flag,		wr_off_flag,		on_acct_flag,
		 	user_id,		max_wr_off,		days_past_due,
			void_type,		cash_acct_code,	origin_module_flag,
		 	process_group_num,	source_trx_ctrl_num,	source_trx_type,
			nat_cur_code,		rate_type_home,	rate_home,
			rate_type_oper,	rate_oper,		amt_discount,
			reference_code,	settlement_ctrl_num
			
		)
		SELECT	trx_ctrl_num,		doc_ctrl_num,		trx_desc,
		 	batch_code,		trx_type,		non_ar_flag,
		 	non_ar_doc_num,	gl_acct_code,		date_entered,
			date_applied,		date_doc,		customer_code,
			payment_code,		payment_type,		amt_payment,
		 	amt_on_acct,		prompt1_inp,		prompt2_inp,
		 	prompt3_inp,		prompt4_inp,		deposit_num,
			bal_fwd_flag,		printed_flag,		posted_flag,
		 	hold_flag,		wr_off_flag,		on_acct_flag,
		 	user_id,		max_wr_off,		days_past_due,
	 	 	void_type,		cash_acct_code,	origin_module_flag,
		 	process_group_num,	source_trx_ctrl_num,	source_trx_type,
			nat_cur_code,		rate_type_home,	rate_home,
			rate_type_oper,	rate_oper,		amt_discount,
			reference_code,	settlement_ctrl_num
		FROM	#arinppyt_work
		WHERE	db_action > 0
		AND 	db_action < 4
	
	IF @@error != 0
	BEGIN
		ROLLBACK TRANSACTION AUTOCASH_LOAD
		RETURN 1
	END

	EXEC @result = arinppdt_sp " ", 0, 0
	IF @result != 0
	BEGIN
		ROLLBACK TRANSACTION AUTOCASH_LOAD
		RETURN 1
	END

	/* Insert the total chargebacks for the check */
	IF @cb_installed = 1
	BEGIN
		INSERT archgbk (trx_ctrl_num,
				chargeref, 
				chargeamt,
 				cb_reason_code, 
				cb_responsibility_code, 
				store_number,
				apply_to_num,
				nat_cur_code,
				customer_code )
		SELECT		RTRIM(trx_ctrl_num),
				chargeref, 
				chargeamt,
 				cb_reason_code, 
				cb_responsibility_code, 
				store_number,
				apply_to_num,
				nat_cur_code,
				customer_code
		FROM		#archgbk 
		IF @@error != 0
		BEGIN
			ROLLBACK TRANSACTION AUTOCASH_LOAD
			RETURN 1
		END

		INSERT 	arcbtot (trx_ctrl_num, 
				total_chargebacks)
		SELECT		RTRIM(trx_ctrl_num),
				total_chargebacks
		FROM		#arcbtot
		IF @@error != 0
		BEGIN
			ROLLBACK TRANSACTION AUTOCASH_LOAD
			RETURN 1
		END
	END
	
	COMMIT TRANSACTION AUTOCASH_LOAD	


	/* Set return values */
	SELECT @checks_processed=count(doc_ctrl_num) FROM #arinppyt_work
	SELECT @from_tcn=isnull(min(trx_ctrl_num), 'none') FROM #arinppyt_work 
	SELECT @to_tcn=isnull(max(trx_ctrl_num), 'none') FROM #arinppyt_work
	SELECT @date=convert(varchar(12), dateadd(dd, (datediff(dd,'1/1/1753',convert(varchar(12),date_applied,102)) + 639906 ) - 639906, '1/1/1753'),101)
		FROM autocash GROUP BY date_applied

	/* Calculate totals in home currency */
	If @ck_divide_flag_h = 0
	BEGIN
		SELECT 	@on_account=isnull(convert(money,sum(amt_on_acct * abs(rate_home))),0) 
		FROM 	#arinppyt_work

		SELECT 	@tot_payments=isnull(convert(money,sum(a.amt_applied * abs(b.rate_home))),0) 
		FROM 	#arinppdt_work a, #arinppyt_work b
		WHERE	a.trx_ctrl_num = b.trx_ctrl_num

		SELECT 	@deductions=isnull(convert(money,sum(a.amt_applied * abs(b.rate_home))),0)
 		FROM 	autocash a, #arinppyt_work b 
		WHERE 	b.customer_code = a.customer_code  
		AND	b.doc_ctrl_num = a.check_number 
		AND 	a.amt_applied < 0
	END
	ELSE
	BEGIN
		SELECT 	@on_account=isnull(convert(money,sum(amt_on_acct / abs(rate_home))),0) 
		FROM 	#arinppyt_work

		SELECT 	@tot_payments=isnull(convert(money,sum(amt_applied / abs(b.rate_home))),0) 
		FROM 	#arinppdt_work a, #arinppyt_work b
		WHERE	a.trx_ctrl_num = b.trx_ctrl_num

		SELECT 	@deductions=isnull(convert(money,sum(a.amt_applied / abs(b.rate_home))),0) 
		FROM 	autocash a, #arinppyt_work b 
		WHERE 	b.customer_code = a.customer_code 
		AND 	b.doc_ctrl_num = a.check_number 
		AND 	a.amt_applied < 0
	END

	/* Delete the checks that were sucessfully loaded from the autocash table for error total */
	DELETE autocash FROM autocash a, #arinppyt_work b 
	WHERE b.customer_code = a.customer_code and b.doc_ctrl_num = a.check_number 

	SELECT @checks_in_error=isnull(count(distinct check_number+customer_code),0) FROM autocash 
	SELECT @total_value=round((@tot_payments + @on_account + @deductions),2)


	/* If not run from the Autocash client, display results	*/
	IF @run_from_client = 0
	BEGIN
		/* Display count of checks processed */
		SELECT 'Cash Receipts Control Numbers: ', @from_tcn, ' thru ', @to_tcn
		SELECT ' '
		SELECT @checks_processed, ' checks successfully processed ','Total check amount:      ',@total_value	 
	
		
		SELECT 'Successfully loaded:'
		SELECT  @date, ' Payments: ',@tot_payments, ' On account: ', @on_account, 'Deductions: ', @deductions 
		SELECT ' '
		SELECT 'Total Applied: ' , @total_value
		
		/* Total of errors */
		SELECT ' '
		SELECT 'In Error:'
		SELECT ' '
		SELECT @checks_in_error, ' checks with errors in AUTOCASH BATCH '
		SELECT ' '

	END

	/* Drop the temporary tables */
	DROP TABLE #arinppyt_work
	DROP TABLE #arinppdt_work
	DROP TABLE #checks
 	DROP TABLE #payments
	DROP TABLE #arcbtot
	DROP TABLE #archgbk
	
	/* Re-activate the display of row counts affected by each statement */
	SET NOCOUNT OFF

GO
GRANT EXECUTE ON  [dbo].[autocash_sp] TO [public]
GO
