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
** Description		:  Add amount actually applied and amount on account columns to report.  Add new
**			:  warning message if bill-to does not match customer on invoice.
**/
/* Sage */
CREATE PROCEDURE [dbo].[acgetcst_sp] @customer_name varchar(40)
/* Sage */ 
AS

DECLARE @customer varchar(8), 	
	@check varchar(16), 	 
	@check_date int, 	 
	@check_amount float, 		
	@apply_to_num varchar(16), 	
	@micr_number varchar(20) 
 
BEGIN /**/

/**** Validate customer codes sent on bank file *****/
	DECLARE customer_cur 
		 CURSOR FOR 	SELECT DISTINCT check_number, 
						customer_code 
			  	FROM 	autocash 
				WHERE 	customer_code <> '' 
				AND	customer_code <> ' ' 
				AND 	customer_code <> 'missing'
				AND 	customer_code <> 'invalid'

	/* Open the customer cursor */
	OPEN 	customer_cur

	/* Read the first entry from the autocash table */
	FETCH 	customer_cur 
	INTO 	@check,  
		@customer

	/* If the read of autocash table was successful then enter the While loop */
	WHILE @@fetch_status = 0
   	BEGIN
		/* Determine if the customer code is on the database */
		IF NOT EXISTS (SELECT customer_code FROM armaster WHERE customer_code=@customer)
			BEGIN
				INSERT autocash_errors (micr_number,
							batch_number, 
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

					SELECT		micr_number, 
							batch_number, 
							customer_code, 
							check_number, 
							(datediff(dd,'1/1/1753',convert(varchar(12),check_date,102)) + 639906), check_amount,
							(datediff(dd,'1/1/1753',convert(varchar(12),date_applied,102)) + 639906),
							apply_to_num, 
							amt_applied, 
							0, 
							'Invalid customer code supplied.', 
							currency_code,
/* Sage */						0,
							0,
							@customer_name
/* Sage */
					FROM	autocash
					WHERE	processed_flag = 0 
					AND 	customer_code=@customer 
					AND 	check_number=@check

				/* Set the customer code to invalid in the autocash table */
				UPDATE 	autocash 
				SET 	customer_code='invalid'
				WHERE 	check_number=@check
				AND	customer_code=@customer

				/* Reset cursor due to update of autocash table */
				CLOSE 	customer_cur
				OPEN 	customer_cur
			END

		/* Read the next entry from the autocash table */
		FETCH 	customer_cur 
		INTO 	@check, 
			@customer
					
	END
	CLOSE 		customer_cur
	DEALLOCATE 	customer_cur	


/**** Retrieve the Platinum customer code for each check without a customer code based on MICR number ****/

	UPDATE 	autocash 
	SET 	customer_code=b.customer_code 
	FROM 	autocash a, armicr b 
	WHERE 	a.micr_number = b.micr_number 
	AND	a.processed_flag = 0 
	AND 	(a.customer_code = "" 
	OR	 a.customer_code =' ' 
	OR	 a.customer_code = 'invalid')


/**** Retrieve the Platinum customer code for those that did not have a customer code by ****/
/****  	   looking for the apply to invoice 					 	 ****/

	DECLARE autocash_cur 
		CURSOR FOR 	SELECT 	micr_number, 
					check_number, 
					apply_to_num, 
					customer_code, 
					check_date, 
					check_amount 
				FROM 	autocash 
				WHERE 	customer_code='' 
				OR	customer_code = ' ' 
				OR 	customer_code = 'missing' 
				OR	customer_code='invalid'

	/* Open the autocash cursor */
	OPEN 	autocash_cur

	/* Read the first entry from the autocash table */
	FETCH 	autocash_cur 
	INTO 	@micr_number, 
		@check, 
		@apply_to_num, 
		@customer, 
		@check_date, 
		@check_amount

	/* If the read of autocash table was successful then enter the While loop */
	WHILE @@fetch_status = 0
   	BEGIN
		/* Determine if the invoice exists on the database */		
		IF EXISTS (	SELECT 	doc_ctrl_num 
				FROM 	artrx 
				WHERE 	doc_ctrl_num=@apply_to_num)
			BEGIN
				/* Set the customer code to the customer from the invoice */
				UPDATE 	autocash 
				SET 	customer_code=b.customer_code
				FROM 	autocash a, artrx b
				WHERE 	a.check_number=@check 
				AND 	a.check_date=@check_date 
				AND 	a.check_amount=@check_amount 
				AND	b.doc_ctrl_num=@apply_to_num

				SELECT 	@customer=customer_code 
				FROM 	artrx 
				WHERE 	doc_ctrl_num=@apply_to_num
		
				/* Add the MICR# for the customer_code if it doesn't exist */
				IF @micr_number <> "" AND @micr_number <> ' '
				BEGIN
					IF NOT EXISTS (	SELECT 	micr_number 
							FROM 	armicr 
							WHERE 	micr_number=@micr_number)
						INSERT 	armicr
						VALUES 	(@customer, @micr_number)
				END

				/* Reset cursor due to update of autocash table */
				CLOSE 	autocash_cur
				OPEN 	autocash_cur
			END

		/* Read the next entry from the autocash table */
		FETCH 	autocash_cur 
		INTO 	@micr_number, 
			@check, 
			@apply_to_num, 
			@customer, 
			@check_date, 
			@check_amount
					
	END
	CLOSE autocash_cur
	DEALLOCATE autocash_cur	


/*** If the customer number was found for an ivalid customer code, delete error ***/
	DELETE 	autocash_errors 
	WHERE 	error_message = 'Invalid customer code supplied.' 
	AND	check_number+str(check_amount)+apply_to_num+str(amt_applied) 
	IN	(SELECT check_number+str(check_amount)+apply_to_num+str(amt_applied)  
		 FROM 	autocash 
		 WHERE 	customer_code <> 'invalid')


/**** Write out an error for all records without a matching customer number ****/
	IF EXISTS (	SELECT 	customer_code 
			FROM 	autocash 
			WHERE ( customer_code="" 
			OR 	customer_code='missing') 
			AND 	processed_flag = 0)
		INSERT 	autocash_errors (micr_number, 
					batch_number, 
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
				SELECT	micr_number, 
					batch_number, 
					customer_code, 
					check_number, 
					(datediff(dd,'1/1/1753',convert(varchar(12),check_date,102)) + 639906), check_amount,
					(datediff(dd,'1/1/1753',convert(varchar(12),date_applied,102)) + 639906),
					apply_to_num, 
					amt_applied, 
					0, 
					'No matching customer code found. ', 
					currency_code,
/* Sage */				0,
					0,
					@customer_name
/* Sage */
				FROM	autocash
				WHERE	processed_flag = 0 
				AND 	(customer_code="" 
				OR 	customer_code='missing')

END

/**/                                              
GO
GRANT EXECUTE ON  [dbo].[acgetcst_sp] TO [public]
GO
