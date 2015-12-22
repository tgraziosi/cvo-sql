SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[acldtbls_sp] 

AS

DECLARE @customer varchar(8), 	
	@check varchar(16), 	
	@check_date int, 	 
	@check_amount float, 		
	@apply_to_num varchar(16), 	
	@amt_applied float, 	
	@amt_disc_taken float, 	 
	@last_check varchar(16),	
	@last_check_amount float,
	@last_check_date int,	
	@last_customer varchar(8), 
	@micr_number varchar(20),
	@batch_number varchar(20),			 
	@payment_count int,
	@date_applied int,
	@currency_code varchar(8) 

BEGIN /**/

	DECLARE load_cur CURSOR FOR 
		SELECT 	micr_number, 
			batch_number, 
			customer_code, 
			check_number, 
			check_amount, 
			check_date,
			date_applied, 
			apply_to_num, 
			amt_applied, 
			amt_disc_taken, 
			currency_code 
		FROM 	autocash 
		WHERE 	customer_code <> '' 
		AND 	customer_code <> ' ' 
		AND 	customer_code <> 'missing' 
		AND 	customer_code <> 'invalid' 
		AND 	apply_to_num <> '' 
		AND 	apply_to_num <> ' '
		ORDER BY record_id

	/* Open the load cursor */
	OPEN 	load_cur

	/* Initialize variables */
	SELECT 	@last_check=null, 
		@last_check_date=0, 
		@last_check_amount=0, 
		@last_customer=null

	/* Read the first entry from the autocash table */
	FETCH 	load_cur 
	INTO 	@micr_number, 
		@batch_number, 
		@customer, 
		@check, 
		@check_amount, 
		@check_date, 
		@date_applied, 
		@apply_to_num,
		@amt_applied, 
		@amt_disc_taken, 
		@currency_code

	/* If the read of autocash table was successful then enter the While loop */
	WHILE @@fetch_status = 0
   	BEGIN
		IF @check<>@last_check OR 
		   @check_date<>@last_check_date OR 
		   @check_amount<>@last_check_amount
		BEGIN
		     SELECT 	@last_check=@check, 
				@last_check_date=@check_date, 
				@last_check_amount=@check_amount,
			    	@last_customer=@customer

		     INSERT INTO #checks 
		     	SELECT 	@batch_number, 
				@micr_number, 
				@customer, 
				@check, 
				@check_amount, 
				datediff(dd,'1/1/1753',convert(varchar(12),@check_date,102)) + 639906,
				datediff(dd,'1/1/1753',convert(varchar(12),@date_applied,102)) + 639906,
				@currency_code
		END 

		/* Check for duplicate payment */
		SELECT 	@payment_count=count(check_number) 
		FROM 	autocash 
		WHERE 	check_number=@check 
		AND	apply_to_num=@apply_to_num 
		AND 	check_date=@check_date
		AND	amt_applied > 0


		/* Create table to hold each payment */
		INSERT INTO #payments
			SELECT 	@batch_number, 
				@micr_number, 
				@last_customer, 
				@check, 
				@apply_to_num, 
				@amt_applied, 
				@amt_disc_taken,
		       		@payment_count

	
		/* Read the next entry from the autocash table */
		FETCH 	load_cur 
		INTO 	@micr_number, 
			@batch_number, 
			@customer, 
			@check, 
			@check_amount, 
			@check_date, 
			@date_applied,
			@apply_to_num, 
			@amt_applied, 
			@amt_disc_taken, 
			@currency_code

	END
	CLOSE 	load_cur
	DEALLOCATE load_cur

END /**/
GO
GRANT EXECUTE ON  [dbo].[acldtbls_sp] TO [public]
GO
