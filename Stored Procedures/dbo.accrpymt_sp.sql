SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[accrpymt_sp] 	@customer varchar(8),
				@check varchar(16),  
				@check_date int, 
				@check_amount float, 
				@date_applied int,	
				@currency_code varchar(8),
				@batch_number varchar(20),
				@micr_number varchar(20),
				@apply_to_num varchar(16), 	
				@amt_applied float, 	
				@amt_disc_taken float, 	 
				@payment_count int,		
				@mc_flag smallint,
				@def_curr_code varchar(8),
				@oper_currency varchar(8),
				@customer_currency varchar(8),
				@one_cur_cust smallint,
				@payment_code varchar(8),
				@rate_type_home	varchar(8),			 
				@rate_type_oper varchar(8),	
				@rate_home float,
				@rate_oper float,
				@ck_divide_flag_h smallint,
				@ck_divide_flag_o smallint,
				@cb_installed int,
				@next_tcn varchar(16),
				@total_payments float OUTPUT,
				@total_cbs float OUTPUT,
				@deduction float OUTPUT,
				@seq_counter int OUTPUT,
/* Sage */
				@customer_name varchar(40)
/* Sage */


AS

DECLARE @num int, 	
	@today int,		
	@date_aging int, 		
	@amt_paid_to_date float,
	@terms_code varchar(8),	
	@posting_code varchar(8),
	@amt_tot_chg float, 		
	@amt_gross float, 	
	@check_error int,	 
	@test_cust varchar(16),	
	@error_flag int,	 
	@amt_on_acct float,		
	@paid_flag int,		
	@first_tcn varchar(16), 
	@last_tcn varchar(16),	 
	@error_message varchar(120),	
	@hold_flag smallint,	
	@last_check varchar(16),	
	@last_check_amount float,
	@last_check_date int,	
	@last_customer varchar(8), 
	@amt_loaded float, 	 
	@inv_date_applied varchar(8),	
	@inv_rate_type_home varchar(8), 
	@inv_rate_type_oper varchar(8),
	@inv_rate_home float, 	
	@inv_rate_oper float, 	
	@inv_currency varchar(8),	
	@inv_new_rate_home float, 	
	@inv_new_rate_oper float,	
	@home_amt_applied float,	
	@gain_loss_oper float, 	
	@gain_loss_home float, 
	@home_amt_disc_taken float,
	@inv_amt_disc_taken float,	
	@inv_amt_applied float,	
	@divide_flag_o smallint, 
	@asset_acct_code varchar(32),	
	@bal_fwd_flag smallint,
	@return_code int,
	@divide_flag_h smallint,
	@inv_new_home float,
	@inv_new_oper float,
	@inv_orig_home float,
	@inv_orig_oper float,
	@unposted_payments float,
/* Sage */
	@inv_cust varchar(8)
/* Sage */

	/* Initialize local variables */
	SELECT 	@date_aging=0, 
		@amt_paid_to_date=0, 
		@amt_tot_chg=0, 
		@amt_gross=0

	/* If deduction (chargeback) do not load application line.  If CB installed add chargeback */
	IF @amt_applied < 0
	BEGIN
		SELECT 	@deduction=1
		SELECT 	@error_message='Unauthorized deducton.  See control# ' + @next_tcn
		INSERT 	autocash_errors (batch_number, 
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
					@apply_to_num, 
					@amt_applied, 
					@amt_disc_taken,
					@error_message, 
					@currency_code,
/* Sage */				0,
					0,
					@customer_name)
/* Sage */

		IF @cb_installed = 1
		BEGIN
			/* Check for duplicate chargeback number */
			If EXISTS (SELECT chargeref 
				   FROM	  #archgbk
				   WHERE  chargeref = @apply_to_num 
				   AND	  trx_ctrl_num = @next_tcn)
			BEGIN
				SELECT 	@error_message='Duplicate chargeback reference number.  See control# ' + @next_tcn
				INSERT 	autocash_errors (batch_number, 
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
/* Sage */						amt_on_acct,
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
							@apply_to_num, 
							@amt_applied, 
							@amt_disc_taken,
							@error_message, 
							@currency_code,
/* Sage */						0,
							0,
							@customer_name)
/* Sage */
			END
			ELSE
			BEGIN
				INSERT 	#archgbk (trx_ctrl_num,
						  chargeref, 
	   					  chargeamt,
						  cb_reason_code, 
						  cb_responsibility_code, 
 						  store_number,
	 					  apply_to_num,
				 		  nat_cur_code,
						  customer_code)
					VALUES 	(@next_tcn, 
						@apply_to_num, 
						(@amt_applied * -1),
						'',
						'',
						'',
						'',
						@currency_code,
						@customer)
					
				SELECT 	@total_cbs = @total_cbs + (@amt_applied * -1)
			END
		END
		
		/* Exit the procedure */
		RETURN 1
	END

	/* Validate the apply to invoice and retrieve data from it */
	IF NOT EXISTS ( SELECT 	doc_ctrl_num
			FROM	artrx
			WHERE	doc_ctrl_num = @apply_to_num )
	BEGIN
		SELECT @error_message='Invoice does not exist. Amount placed on account. See control# ' + @next_tcn
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
					@apply_to_num, 
					@amt_applied, 
					@amt_disc_taken,
					@error_message, 
					@currency_code,
/* Sage */				@amt_applied,
					0,
					@customer_name)
/* Sage */

		/* Exit the procedure */
		RETURN 1
	END
	ELSE
		SELECT 	@date_aging = date_aging, 
			@amt_paid_to_date = amt_paid_to_date, 
			@amt_tot_chg = amt_tot_chg, 
			@amt_gross = amt_gross, 
			@paid_flag = paid_flag,
			@inv_rate_type_home = rate_type_home, 
			@inv_rate_type_oper = rate_type_oper,
			@inv_rate_home = rate_home, 
			@inv_rate_oper = rate_oper, 
			@inv_currency = nat_cur_code
		FROM	artrx
		WHERE	doc_ctrl_num = @apply_to_num 
/* Sage */
	/* Validate the apply to invoice and retrieve data from it */
	IF NOT EXISTS ( SELECT 	doc_ctrl_num
			FROM	artrx
			WHERE	doc_ctrl_num = @apply_to_num 
			AND	customer_code = @customer)
	BEGIN
		SELECT @inv_cust = customer_code
		FROM	artrx
		WHERE	doc_ctrl_num = @apply_to_num 

		SELECT @error_message='Bill-to does not match - ' + @inv_cust + '.  See control# ' + @next_tcn
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
					@apply_to_num, 
					@amt_applied, 
					@amt_disc_taken,
					@error_message, 
					@currency_code,
/* Sage */				0,
					0,
					@customer_name)
	END
/* Sage */

	/* If duplicate invoice or the invoice is already paid, place on account */
	If @payment_count > 1 OR
	   @paid_flag = 1 	   
	BEGIN
		If @payment_count > 1
			SELECT 	@error_message='Duplicate invoice payment. Amount placed on account. See control# ' + @next_tcn
		ELSE
			SELECT @error_message='Apply to invoice already paid. Amount placed on account. See control# ' + @next_tcn
				
		INSERT autocash_errors (batch_number, 
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
					@customer, 
					@check, 
					@check_date, 
					@check_amount,
					@date_applied, 
					@apply_to_num, 
					@amt_applied, 
					@amt_disc_taken,
					@error_message, 
					@currency_code,
/* Sage */				@amt_applied,
					0,
					@customer_name)
/* Sage */

		/* Exit the procedure */
		RETURN 1
	END
			
	/* Convert amt_applied to home currency if the invoice currency is different
	   than the check's */
	If @currency_code <> @inv_currency
	BEGIN
		If @ck_divide_flag_h = 0
			SELECT @home_amt_applied = round((@amt_applied * abs(@rate_home)),2)
		ELSE
			SELECT @home_amt_applied = round((@amt_applied / abs(@rate_home)),2)

		/* Convert amt_disc_taken to home currency */
		If @ck_divide_flag_h = 0
			SELECT @home_amt_disc_taken = round((@amt_disc_taken * abs(@rate_home)),2)
		ELSE
			SELECT @home_amt_disc_taken = round((@amt_disc_taken / abs(@rate_home)),2)	
	END

	/* Get exchange rate to home currency for invoice as of the check's date_applied */
	EXEC CVO_Control..mccurate_sp
		@date_applied,
		@inv_currency,	
		@def_curr_code,		
		@inv_rate_type_home,	
		@inv_new_rate_home OUTPUT,
		0,
		@divide_flag_h	OUTPUT

	/* If no exchange rate to home currency from invoice currency then error */
	If @inv_new_rate_home IS NULL
	BEGIN
		SELECT 	@error_message='No home conversion rate from ' + @inv_currency + '. Amount placed on account. See control# ' + @next_tcn
		INSERT 	autocash_errors (batch_number, 
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
					@customer, 
					@check, 
					@check_date, 
					@check_amount,
					@date_applied, 
					@apply_to_num, 
					@amt_applied, 
					@amt_disc_taken,
					@error_message, 
					@currency_code,
/* Sage */				@amt_applied,
					0,
					@customer_name)
/* Sage */

		/* Exit the procedure */
		RETURN 1
	END

	/* Get exchange rate to home currency for invoice as of the check's date_applied */
	EXEC CVO_Control..mccurate_sp
		@date_applied,
		@inv_currency,	
		@oper_currency,		
		@inv_rate_type_oper,	
		@inv_new_rate_oper OUTPUT,
		0,
		@divide_flag_o	OUTPUT

	/* If no exchange rate to operational currency from invoice currency then error */
	If @inv_new_rate_home IS NULL
	BEGIN
		SELECT @error_message='No oper conversion rate from ' + @inv_currency + '. Amount placed on account. See control# ' + @next_tcn
		INSERT 	autocash_errors (batch_number, 
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
					@customer, 
					@check, 
					@check_date, 
					@check_amount,
					@date_applied, 
					@apply_to_num, 
					@amt_applied, 
					@amt_disc_taken,
					@error_message, 
					@currency_code,
/* Sage */				@amt_applied,
					0,
					@customer_name)
/* Sage */

		/* Exit the procedure */
		RETURN 1
	END

	/* Convert amt_applied to invoice currency if currency of invoice
	   is different from the check */
	If @currency_code <> @inv_currency
	BEGIN
		If @divide_flag_h = 0
			SELECT @inv_amt_applied = round((@home_amt_applied / abs(@inv_new_rate_home)),2)
		Else
			SELECT @inv_amt_applied = round((@home_amt_applied * abs(@inv_new_rate_home)),2)

		/* Convert amt_disc_taken to invoice currency */
		If @divide_flag_h = 0
			SELECT @inv_amt_disc_taken = round((@home_amt_disc_taken / abs(@inv_new_rate_home)),2)
		Else
			SELECT @inv_amt_disc_taken = round((@home_amt_disc_taken * abs(@inv_new_rate_home)),2)
	END
	ELSE
		SELECT 	@inv_amt_applied = @amt_applied,
			@inv_amt_disc_taken = @amt_disc_taken


	/* Check for unposted payments for the invoice */
	SELECT 	@unposted_payments = ISNULL(round(sum(inv_amt_applied),2),0)
	FROM	arinppdt a, arinppyt b
	WHERE	a.apply_to_num=@apply_to_num 
	AND	a.trx_ctrl_num = b.trx_ctrl_num
/* Fix 3802hq	AND	b.customer_code = @customer */

	/* Check for unposted payments for the invoice in this autocash run */
	SELECT 	@unposted_payments = @unposted_payments + ISNULL(round(sum(inv_amt_applied),2),0)
	FROM	#arinppdt_work a, #arinppyt_work b
	WHERE	a.apply_to_num=@apply_to_num 
	AND	a.trx_ctrl_num = b.trx_ctrl_num
/* Fix 3802hq	AND	b.customer_code = @customer*/

	/* If the invoice is partailly paid, pay the rest and put remaining amount of payment on account */
	If ROUND((@amt_tot_chg - @amt_paid_to_date - @amt_disc_taken - @unposted_payments),2) < ROUND(@inv_amt_applied,2)
	BEGIN
		SELECT @error_message='Overpayment of invoice. Overage placed on account. See control# ' + @next_tcn
		INSERT 	autocash_errors (batch_number, 
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
					@customer, 
					@check, 
					@check_date, 
					@check_amount,
					@date_applied, 
					@apply_to_num, 
					@amt_applied, 
					@amt_disc_taken,
					@error_message, 
					@currency_code,
/* Sage */				(ROUND(@inv_amt_applied,2)- ROUND((@amt_tot_chg - @amt_paid_to_date - @amt_disc_taken - @unposted_payments),2)),
					(ROUND((@amt_tot_chg - @amt_paid_to_date - @amt_disc_taken - @unposted_payments),2)),
					@customer_name)
/* Sage */

		/* Recalculate the amount applied to the invoice */
		SELECT @inv_amt_applied = ROUND ((@amt_tot_chg - @amt_paid_to_date - @amt_disc_taken - @unposted_payments),2)
		IF @inv_amt_applied = 0
			RETURN 1

		/* If the invoice currency is not equal to the check currency then 
		   convert the new applied amount to the check currency */
		IF @currency_code <> @inv_currency
		BEGIN
			If @divide_flag_h = 0
				SELECT @home_amt_applied = round((@inv_amt_applied * abs(@inv_new_rate_home)),2)
			Else
				SELECT @home_amt_applied = round((@inv_amt_applied / abs(@inv_new_rate_home)),2)

			If @ck_divide_flag_h = 0
				SELECT @amt_applied = round((@home_amt_applied / abs(@rate_home)),2)
			ELSE
				SELECT @amt_applied = round((@home_amt_applied * abs(@rate_home)),2)
		END
		ELSE
			SELECT @amt_applied = @inv_amt_applied
	END

	/* If the invoice is under paid put out message */
	If ROUND((@amt_tot_chg - @amt_paid_to_date - @amt_disc_taken - @unposted_payments),2) > ROUND(@amt_applied,2)
	BEGIN
		SELECT @error_message='Underpayment of invoice. See control# ' + @next_tcn
		INSERT autocash_errors (batch_number, 
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
					@customer, 
					@check, 
					@check_date, 
					@check_amount,
					@date_applied, 
					@apply_to_num, 
					@amt_applied, 
					@amt_disc_taken,
					@error_message, 
					@currency_code,
/* Sage */				0,
					@amt_applied,
					@customer_name)
/* Sage */
	END

	/* If the rates are not equal to the original rates for the invoice then
	   calculate the gain/loss for the home and operational currencies */
	If @inv_new_rate_home <> @inv_rate_home
	BEGIN
		If @divide_flag_h = 0
			SELECT @inv_new_home = round((abs(@inv_new_rate_home) * @inv_amt_applied),2)
		ELSE
			SELECT @inv_new_home = round((@inv_amt_applied / abs(@inv_new_rate_home)),2)
				  
		If @inv_rate_home < 0
			SELECT @inv_orig_home = round((@inv_amt_applied / abs(@inv_rate_home)),2)
		ELSE
			SELECT @inv_orig_home = round((@inv_amt_applied * abs(@inv_rate_home)),2)
		
		SELECT @gain_loss_home = round((@inv_new_home - @inv_orig_home),2)
				
	END						
	ELSE
		SELECT @gain_loss_home = 0

	If @inv_new_rate_oper <> @inv_rate_oper
	BEGIN
		If @divide_flag_o = 0
			SELECT @inv_new_oper = round((abs(@inv_new_rate_oper) * @inv_amt_applied),2)
		ELSE
			SELECT @inv_new_oper = round((@inv_amt_applied / abs(@inv_new_rate_oper)),2)
				  
		If @inv_rate_oper < 0
			SELECT @inv_orig_oper = round((@inv_amt_applied / abs(@inv_rate_oper)),2)
		ELSE
			SELECT @inv_orig_oper = round((@inv_amt_applied * abs(@inv_rate_oper)),2)
		
		SELECT @gain_loss_oper = round((@inv_new_oper - @inv_orig_oper),2)
					
	END						
	ELSE
		SELECT @gain_loss_oper = 0

	/* Add the payment to the temporary table.  The customer on the payment record 
	   should be the customer on the invoice in case of national accounts */
	SELECT @seq_counter = @seq_counter + 1
	INSERT #arinppdt_work (	trx_ctrl_num,  
				doc_ctrl_num,  
				sequence_id, 
  				trx_type,  
				apply_to_num,  
				apply_trx_type,  
				customer_code,  
				date_aging,  
				amt_applied, 
				amt_disc_taken,  
				wr_off_flag,  
				amt_max_wr_off,  
				void_flag,  
				line_desc,  
				sub_apply_num, 
				sub_apply_type,  
				amt_tot_chg,  
				amt_paid_to_date,  
				terms_code,  
				posting_code,  
				date_doc, 
				amt_inv, 
				gain_home, 
				gain_oper, 
				inv_amt_applied, 
				inv_amt_disc_taken, 
				inv_amt_max_wr_off, 
				inv_cur_code,	
				db_action, 
				temp_flag )
			SELECT 	@next_tcn, 
				@check, 
				@seq_counter, 
				2111, 
				@apply_to_num, 
				2031, 
				a.customer_code, 
				@date_aging,
				@amt_applied, 
				@amt_disc_taken, 
				0, 
				0, 
				0, 
				'AUTOCASH BATCH ' + @batch_number, '', 
				0, 
				@amt_tot_chg, 
				@amt_paid_to_date,
				'', 
				'', 
				@check_date, 
				@amt_gross, 
				@gain_loss_home, 
				@gain_loss_oper,
				@inv_amt_applied, 
				@inv_amt_disc_taken, 
				0, @inv_currency, 
				1, 
				0
			FROM 	artrx a
			WHERE 	a.doc_ctrl_num = @apply_to_num

	/* Accumulate the amount of the payments on the check */
	SELECT @total_payments = ROUND((@total_payments + @amt_applied),2)
		
GO
GRANT EXECUTE ON  [dbo].[accrpymt_sp] TO [public]
GO
