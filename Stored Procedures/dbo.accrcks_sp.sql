SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[accrcks_sp] 	@customer varchar(8), 	
				@check varchar(16), 	 
				@check_date int, 	 
				@check_amount float, 		
				@date_applied int,	 
				@currency_code varchar(8),
				@batch_number varchar(20),			 
				@micr_number varchar(20), 
				@mc_flag smallint, 	 
				@def_curr_code varchar(8),	
				@oper_currency varchar(8),
				@cb_installed int,
				@ck_divide_flag_h smallint OUTPUT,
				@total_cbs float OUTPUT,
				@run_from_client int,
				@settlement_ctrl_num varchar(16),
/* Sage */
				@customer_name varchar(40)
/* Sage */

AS

DECLARE @next_tcn varchar(16), 	
	@num int, 	
	@today int,		
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
	@paid_flag int,		
	@first_tcn varchar(16), 
	@last_tcn varchar(16),	 
	@error_message varchar(120),	
	@deduction int,
	@hold_flag smallint,	
	@last_check varchar(16),	
	@last_check_amount float,
	@last_check_date int,	
	@last_customer varchar(8), 
	@amt_loaded float, 	 
	@payment_count int,		
	@rate_type_home	varchar(8),			 
	@rate_type_oper varchar(8),	
	@rate_home float,
	@rate_oper float,	
	@one_cur_cust smallint,
	@customer_currency varchar(8),	
	@divide_flag_h smallint,	
	@inv_date_applied varchar(8),	
	@inv_rate_type_home varchar(8), 
	@inv_rate_type_oper varchar(8),
	@inv_rate_home float, 	
	@inv_rate_oper float, 	
	@inv_currency varchar(8),	
	@inv_new_rate_home float, 	
	@inv_new_rate_oper float,	
	@home_amt_applied float,	
	@ck_divide_flag_o smallint,	
	@gain_loss_oper float, 	
	@gain_loss_home float, 
	@home_amt_disc_taken float,
	@inv_amt_disc_taken float,	
	@inv_amt_applied float,	
	@divide_flag_o smallint, 
	@payment_code varchar(8),
	@asset_acct_code varchar(32),	
	@bal_fwd_flag smallint,
	@return_code int,
	@payment_type int

	/* Get today's date */
	EXEC appdate_sp @today OUTPUT

	/* Initialize the check error flag */
	SELECT 	@check_error = 0, 
		@deduction=0, 
		@hold_flag=0

	/* Select currency information for the check's customer */
	SELECT 	@one_cur_cust = one_cur_cust, 
		@rate_type_home = rate_type_home,
		@rate_type_oper = rate_type_oper,
		@customer_currency = nat_cur_code, 
		@payment_code = payment_code,
		@bal_fwd_flag = bal_fwd_flag 
	FROM	armaster
	WHERE	customer_code = @customer 
	AND	address_type = 0

	/* Select the asset account code from the customer's payment code */
	SELECT	@asset_acct_code = asset_acct_code
	FROM 	arpymeth
	WHERE	payment_code = @payment_code

	/* Validate the check's currency information */
	EXEC acvalchk_sp 	@customer,
				@check,  
				@check_date, 
				@check_amount, 
				@date_applied,	
				@currency_code OUTPUT,
				@batch_number,
				@micr_number,
				@mc_flag,
				@def_curr_code,
				@oper_currency,
				@customer_currency,
				@one_cur_cust,
				@payment_code OUTPUT,
				@rate_type_home OUTPUT,			 
				@rate_type_oper OUTPUT,	
				@rate_home OUTPUT,
				@rate_oper OUTPUT,
				@ck_divide_flag_h OUTPUT,
				@ck_divide_flag_o OUTPUT,
				@asset_acct_code OUTPUT,
				@check_error OUTPUT,
/* Sage */
				@customer_name
/* Sage */

	/* If the currency validations failed then do not create the check */
	If @check_error = 1
		RETURN 1

	
	/* Look for duplicate check numbers already in the system */
	If EXISTS ( 	SELECT 	doc_ctrl_num 
			FROM 	artrx 
			WHERE 	doc_ctrl_num = @check 
			AND 	customer_code = @customer)
	   AND @run_from_client <> 3
	BEGIN
		SELECT @error_message = 'Warning! Duplicate check# has already been posted for the customer.'
		INSERT autocash_errors (batch_number, 
					micr_number, 
					customer_code, 
					check_number, 
					check_date, 
					check_amount,
					date_applied, 
					apply_to_num, 
					amt_applied, 
					amt_disc_taken,
					error_message, 
					currency_code,
/* Sage */				amt_on_acct,
					inv_amt_applied,
					customer_name)
/* Sage */
			VALUES		(@batch_number, 
					@micr_number, 
					@customer, 
					@check, 
					@check_date, 
					@check_amount,
					@date_applied,
					'', 
					0, 
					0,
					@error_message, 
					@currency_code,
/* Sage */				0,
					0,
					@customer_name)
/* Sage */
		RETURN 1

	END

	If EXISTS (	SELECT 	doc_ctrl_num 
			FROM 	arinppyt 
			WHERE 	doc_ctrl_num = @check 
			AND 	customer_code = @customer)
	   AND @run_from_client <> 3
		BEGIN
		SELECT @error_message = 'Warning! Duplicate check# exists in the unposted cash receipts table.'
		INSERT autocash_errors (batch_number, 
					micr_number, 
					customer_code, 
					check_number, 
					check_date, 
					check_amount,
					date_applied, 
					apply_to_num, 
					amt_applied, 
					amt_disc_taken,
					error_message, 
					currency_code,
/* Sage */				amt_on_acct,
					inv_amt_applied,
					customer_name)
/* Sage */
			VALUES		(@batch_number, 
					@micr_number, 
					@customer, 
					@check, 
					@check_date, 
					@check_amount,
					@date_applied,
					'', 
					0, 
					0,
					@error_message, 
					@currency_code,
/* Sage */				0,
					0,
					@customer_name)
/* Sage */
		RETURN 1

	END

	/* Get the next control number from the Autocash number range */
	IF @run_from_client = 3
		EXEC @error_flag = ARGetNextControl_SP 	3002,  
						@next_tcn OUTPUT,  
						@num OUTPUT
	ELSE
		EXEC @error_flag = ARGetNextControl_SP 	2995,  
						@next_tcn OUTPUT,  
						@num OUTPUT

	/* Keep track of the range of cash receipts control numbers used */
	If @first_tcn is null 
		SELECT @first_tcn=@next_tcn


	SELECT 	@last_tcn=@next_tcn,
		@payment_type = 1

	/* Check to see if the receipt is an on account credit memo */
	If EXISTS (	SELECT doc_ctrl_num 
			FROM artrx 
			WHERE doc_ctrl_num = @check
			AND trx_type = 2032
			AND customer_code = @customer )
		SELECT @payment_type = 4
			
	/* Create unposted check header in the temporary table */
	INSERT #arinppyt_work 	(trx_ctrl_num, 
				doc_ctrl_num, 
				trx_desc, 
				batch_code, 
				trx_type, 
				non_ar_flag,  
 				non_ar_doc_num, 
				gl_acct_code, 
				date_entered,  
				date_applied, 
				date_doc, 
				customer_code,  
	  			payment_code, 
				payment_type, 
				amt_payment,  
				amt_on_acct, 
				prompt1_inp, 
				prompt2_inp, 
	  			prompt3_inp, 
				prompt4_inp, 
				deposit_num,  
				bal_fwd_flag, 
				printed_flag, 
				posted_flag, 
	  			hold_flag, 
				wr_off_flag, 
				on_acct_flag,  
				user_id, 
				max_wr_off, 
				days_past_due,  
				void_type, 
	  			cash_acct_code, 
				origin_module_flag, 
				process_group_num, 
				source_trx_ctrl_num, 
				source_trx_type, 
				nat_cur_code, 
				rate_type_home, 
				rate_type_oper, 
				rate_home,
				rate_oper, 
				amt_discount, 
				db_action,
				settlement_ctrl_num ) 
		VALUES		(@next_tcn, 
				@check, 
				'AUTOCASH BATCH ' + @batch_number, 
				'', 
				2111, 
				0,
				'', 
				'', 
				@today, 
				@date_applied, 
				@check_date, 
				@customer, 
				@payment_code, 
				@payment_type, 
				@check_amount, 
				0, 
				'', 
				'',
				'', 
				'', 
				'', 
				@bal_fwd_flag, 
				0, 
				0, 
				0, 
				0, 
				0, 
				1, 
				0, 
				0, 
				0, 
				@asset_acct_code, 
				0, 
				'', 
				'', 
				0, 
				@currency_code, 
				@rate_type_home, 
				@rate_type_oper, 
				@rate_home,
				@rate_oper, 
				0, 
				1,
				@settlement_ctrl_num )

	/* Intialize the variables used to accumulate the total payments on the check and
	the payment sequence id */
	SELECT 	@total_payments=0, 
		@seq_counter=0, 
		@total_cbs=0
	
	/* Declare the cursor to read each payment from the #payments table */
	DECLARE payment_cur CURSOR FOR 
		SELECT 	apply_to_num, 
			amt_applied, 
			amt_disc_taken, 
			payment_count 
		FROM 	#payments
		WHERE 	check_number = @check 
		AND 	customer_code = @customer 

	/* Open the payment cursor */
	OPEN 	payment_cur

	/* Read the first entry from the #payments table */
	FETCH 	payment_cur 
	INTO 	@apply_to_num, 
		@amt_applied, 
		@amt_disc_taken, 
		@payment_count

	/* If the read of the #payments table was successful then enter the While loop */
	WHILE @@fetch_status = 0 
	BEGIN
		/* Create the check application */
		EXEC @return_code = accrpymt_sp @customer,
						@check,  
						@check_date, 
						@check_amount, 
						@date_applied,	
						@currency_code,
						@batch_number,
						@micr_number,
						@apply_to_num, 
						@amt_applied, 
						@amt_disc_taken, 
						@payment_count,
						@mc_flag,
						@def_curr_code,
						@oper_currency,
						@customer_currency,
						@one_cur_cust,
						@payment_code,
						@rate_type_home,			 
						@rate_type_oper,	
						@rate_home,
						@rate_oper,
						@ck_divide_flag_h,
						@ck_divide_flag_o,
						@cb_installed,
						@next_tcn,
						@total_payments OUTPUT,
						@total_cbs OUTPUT,
						@deduction OUTPUT,
						@seq_counter OUTPUT,
/* Sage */
						@customer_name
/* Sage */


		/* Read the next payment for the check */
		FETCH payment_cur INTO @apply_to_num, @amt_applied, @amt_disc_taken, @payment_count
	END

	/* Close the payment cursor */
	CLOSE payment_cur
	DEALLOCATE payment_cur

	/* If the total payments exceeds the amount of the check then write an error to the
	   autoash error table */
	IF @total_payments > @check_amount 
	BEGIN
		/* If chargebacks is not installed hold the check so the deduction
		   can be reconciled prior to posting */
		If @cb_installed = 0
			SELECT @hold_flag=1

		/* If the over-application was not caused by a chargeback, write out an error */
		IF @deduction = 0
		BEGIN
			SELECT @error_message='Warning! Check is over-applied. See control# ' + @next_tcn
			INSERT autocash_errors (batch_number, 
						micr_number, 
						customer_code, 
						check_number, 
						check_date, 
						check_amount,
						date_applied, 
						apply_to_num, 
						amt_applied, 
						amt_disc_taken,
						error_message, 
						currency_code,
/* Sage */					amt_on_acct,
						inv_amt_applied,
						customer_name)
/* Sage */
				VALUES		(@batch_number, 
						@micr_number, 
						@customer, 
						@check, 
						@check_date, 
						@check_amount,
						@date_applied, 
						'', 
						@total_payments,
						0,
						@error_message, 
						@currency_code,
/* Sage */					0,
						@total_payments,
						@customer_name)
/* Sage */
		END
	END

	/* If the check is not in error, update the amt_on_acct by deducting the payments from
	   the check amount */
	SELECT @amt_on_acct=round(@check_amount + isnull(@total_cbs,0) - @total_payments,2)
	IF @amt_on_acct > 0
		UPDATE 	#arinppyt_work 
		SET 	amt_on_acct=@amt_on_acct, 
			on_acct_flag = 1
		WHERE	customer_code=@customer 
		AND 	doc_ctrl_num=@check 

	/* If the check is over-applied, place it on hold */
	IF @hold_flag = 1
		UPDATE 	#arinppyt_work 
		SET 	hold_flag = 1
		WHERE	customer_code=@customer 
		AND 	doc_ctrl_num=@check 

	/* Insert the total chargebacks record for the check */
	If @cb_installed = 1
		INSERT 	#arcbtot (trx_ctrl_num, 
				total_chargebacks)
		VALUES 		(@next_tcn, 
				@total_cbs)


	/* Succesful completion */
	RETURN 0

GO
GRANT EXECUTE ON  [dbo].[accrcks_sp] TO [public]
GO
