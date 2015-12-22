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

/* 	This procedure validates the currency information for the check
**
*/

CREATE PROCEDURE [dbo].[acvalchk_sp] 	@customer varchar(8),
				@check varchar(16),  
				@check_date int, 
				@check_amount float, 
				@date_applied int,	
				@currency_code varchar(8) OUTPUT,
				@batch_number varchar(20),
				@micr_number varchar(20),
				@mc_flag smallint,
				@def_curr_code varchar(8),
				@oper_currency varchar(8),
				@customer_currency varchar(8),
				@one_cur_cust smallint,
				@payment_code varchar(8) OUTPUT,
				@rate_type_home	varchar(8) OUTPUT,			 
				@rate_type_oper varchar(8) OUTPUT,	
				@rate_home float OUTPUT,
				@rate_oper float OUTPUT,
				@ck_divide_flag_h smallint OUTPUT,
				@ck_divide_flag_o smallint OUTPUT,
				@asset_acct_code varchar(32) OUTPUT,
				@check_error int OUTPUT,
/* Sage */
				@customer_name varchar(40)
/* Sage */

AS

DECLARE @error_message varchar(120)

	/* If the currency code of the check is blank then use the 
	   default currency_code from the customer */
	If @currency_code = "" OR
	   @currency_code = ' '
		SELECT @currency_code = @customer_currency

	/* If the database is single currency and the check's currency
	   is not equal to the database's currency then do not load
	   the check.  Write out an error.  */
	If @mc_flag = 0 AND 
	   @currency_code <> @def_curr_code
	BEGIN
		SELECT @error_message = 'Currency not valid in single currency environment.'
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
					'', 
					0, 
					0,
					@error_message,
					@currency_code,
/* Sage */				0,
					0,
					@customer_name)
/* Sage */

		/* Set the check error flag 'on' so the check will not be loaded */
		SELECT 	@check_error = 1
		RETURN 1
	END

	/* Validate the currency_code */
	If @currency_code <> @def_curr_code 
	BEGIN
		If NOT EXISTS	(SELECT currency_code 
				FROM CVO_Control..mccurr 
				WHERE currency_code=@currency_code)
		BEGIN
			SELECT @error_message = 'Invalid currency code.'
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
						0, 
						0,
						@error_message, 
						@currency_code,
/* Sage */					0,
						0,
						@customer_name)
/* Sage */

			/* Set the check error flag "on" so the check will not be loaded */
			SELECT @check_error = 1
			RETURN 1
		END
	END

	/* If the customer is single currency and the check is not in the customer's currency then error */
	If @currency_code <> @customer_currency AND 
	   @one_cur_cust = 1
	BEGIN
		SELECT @error_message = 'Currency not valid for single currency customer.'
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

		/* Set the check error flag "on" so the check will not be loaded */
		SELECT @check_error = 1
		RETURN 1
	END

	/* Get exchange rate to home currency for check */
	EXEC CVO_Control..mccurate_sp
		@date_applied,
		@currency_code,	
		@def_curr_code,		
		@rate_type_home,	
		@rate_home		OUTPUT,
		0,
		@ck_divide_flag_h	OUTPUT

	/* If no conversion then error */
	If @rate_home IS NULL
	BEGIN
		SELECT @error_message = 'No conversion rate to home currency.'
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

		/* Set the check error flag "on" so the check will not be loaded */
		SELECT @check_error = 1
		RETURN 1
	END

	/* Get exchange rate to  oper currency for check */
	EXEC CVO_Control..mccurate_sp
		@date_applied,
		@currency_code,	
		@oper_currency,		
		@rate_type_oper,	
		@rate_oper		OUTPUT,
		0,
		@ck_divide_flag_o	OUTPUT

	/* If no conversion then error */
	If @rate_oper IS NULL
	BEGIN
		SELECT @error_message = 'No conversion rate to operational currency.'
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

		/* Set the check error flag "on" so the check will not be loaded */
		SELECT @check_error = 1
		RETURN 1
	END	
	
	/* Validate the customer's default payment code for the currency of the check */
	IF NOT EXISTS(	SELECT nat_cur_code 
			FROM 	arpymeth 
			WHERE 	payment_code = @payment_code 
			AND 	(nat_cur_code=@currency_code OR nat_cur_code = "" ))
	BEGIN
		SELECT  @payment_code = ""
		SELECT 	@payment_code = payment_code, 
			@asset_acct_code = asset_acct_code 
		FROM 	arpymeth 
		WHERE 	nat_cur_code = @currency_code

		IF @payment_code = ""
			SELECT 	@payment_code = payment_code, 
				@asset_acct_code = asset_acct_code 
			FROM 	arpymeth 
			WHERE 	nat_cur_code = ""

		
		IF @payment_code = ""
		BEGIN
			SELECT @error_message = 'No payment code found for currency code.'
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
						0, 
						0,
						@error_message, 
						@currency_code,
/* Sage */					0,
						0,
						@customer_name)
/* Sage */

			/* Set the check error flag "on" so the check will not be loaded */
			SELECT @check_error = 1
			RETURN 1
		END
	END

GO
GRANT EXECUTE ON  [dbo].[acvalchk_sp] TO [public]
GO
