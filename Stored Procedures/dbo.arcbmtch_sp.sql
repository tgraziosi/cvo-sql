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
** Description		:  This procedure matches chargebacks to credit memos with the same 
value in
			   the customer po field.  If there is a match and the chargeback has not 
 			   already been paid in full, an unposted cash receipt is created to apply the 
			   credit memo to the chargeback.
*/
                   
CREATE PROCEDURE [dbo].[arcbmtch_sp] 	
AS

DECLARE @from_trx varchar(16),
	@to_trx varchar(16),
	@today integer,
	@check_number varchar(16),
	@apply_to_number varchar(16),
 	@check_amt float,
	@amt_applied float,
	@tot_applied float,
	@last_check_number varchar(16),
	@total_unposted_apps float,
	@open_amt float,
	@last_cb_number varchar(16),
	@record_id int

/* Get today's date */
EXEC appdate_sp @today OUTPUT

/* Create temp table to hold generated credit applications */
CREATE TABLE #autocash 


(
 	record_id int IDENTITY (1,1), 
	micr_number varchar(20), 
	check_number varchar(16), 
	check_amount float,
 	check_date varchar(12), 
	apply_to_num varchar(16), 
	amt_applied float, 
	amt_disc_taken float, 
	processed_flag int,
 	process_ctrl_num varchar(16), 
	customer_code varchar(8),
	batch_number varchar(20), 
	date_applied varchar(12),
 	currency_code varchar(8)
)
CREATE UNIQUE CLUSTERED INDEX #autocash_ind_0 ON #autocash (record_id)


/* Select open chargebacks all open
 chargebacks that have a 
   matching open credit memo into a temporary table */
INSERT	#autocash 	(micr_number,
			check_number,
			check_amount,
			check_date,
			apply_to_num,
			amt_applied,
			amt_disc_taken,
			processed_flag,
			process_ctrl_num,
			customer_code,
			batch_number,
			date_applied,
			currency_code )
	SELECT 		' ',
			b.doc_ctrl_num,
			c.amt_on_acct,
			convert(varchar(12), dateadd(dd, b.date_doc - 639906, '1/1/1753'),102),
			a.doc_ctrl_num,
			c.amt_on_acct,
			0,
			0,
			' ',
			b.customer_code,
			'CB MATCH',
			convert(varchar(12), dateadd(dd, b.date_applied- 639906, '1/1/1753'),102),
			b.nat_cur_code
	FROM	artrx a, artrx b, artrx c
	WHERE	a.doc_ctrl_num like 'CB%'
	AND	a.trx_type = 2031
	AND	a.paid_flag = 0
	AND	a.void_flag = 0
	AND	round(a.amt_tot_chg - a.amt_paid_to_date,2)<>0
	AND	a.cust_po_num <> ''
	AND	a.cust_po_num = b.cust_po_num
	AND	a.customer_code = b.customer_code
	AND	a.nat_cur_code = b.nat_cur_code
	AND	b.trx_type = 2032
	AND	b.doc_ctrl_num = c.doc_ctrl_num
	AND	b.customer_code = c.customer_code
	AND	c.trx_type = 2111
	AND	round(c.amt_on_acct,2) > 0
	AND	b.doc_ctrl_num <> ''
	AND	b.doc_ctrl_num not in (select doc_ctrl_num from arinppyt)
	AND	a.doc_ctrl_num not in (select apply_to_num from arinppdt)
	AND	a.org_id = b.org_id
	AND	b.org_id = c.org_id
	ORDER BY b.doc_ctrl_num, b.customer_code


/* Check for over-paid chargebacks */
DECLARE autocash_cur CURSOR FOR 
	SELECT 	check_number,
		apply_to_num,
		check_amount,
		amt_applied,
		record_id
	FROM 	#autocash
	ORDER BY apply_to_num, check_number

				        
/* Open the cursor */
OPEN autocash_cur

/* Read the first entry from the autocash table */
FETCH autocash_cur INTO  @check_number,
			 @apply_to_number,
			 @check_amt,
			 @amt_applied,
			 @record_id


SELECT @last_cb_number = ''
/* If the read was successful then enter the While loop */
WHILE @@fetch_status = 0
BEGIN

		IF @apply_to_number <> @last_cb_number
		BEGIN
			/* Select the open amount of the chargeback */
			SELECT 	@last_cb_number = @apply_to_number,

				@tot_applied = 0,
				@open_amt = round(amt_tot_chg - amt_paid_to_date,2)
			FROM	artrx
			WHERE	doc_ctrl_num = @apply_to_number

			/* Deduct any unposted applications */
			SELECT	@total_unposted_apps = ISNULL(sum(amt_applied),0)
			FROM	arinppdt
			WHERE	apply_to_num = @apply_to_number

			SELECT 	@open_amt = @open_amt - @total_unposted_apps
		END

		SELECT 	@tot_applied = @tot_applied + @amt_applied

		IF @check_amt = 0 
			UPDATE 	#autocash
			SET 	amt_applied = 0
			WHERE record_id = @record_id
		ELSE
			IF @tot_applied > @open_amt
			BEGIN

				SELECT @amt_applied = @amt_applied - (@tot_applied - @open_amt)
				SELECT @tot_applied = @tot_applied - (@tot_applied - @open_amt)

				UPDATE 	#autocash
				SET 	amt_applied = @amt_applied
				WHERE record_id = @record_id

			END


		/* Read the next entry from the autocash table */
		FETCH autocash_cur INTO  @check_number,
					 @apply_to_number,
					 @check_amt,
					 @amt_applied,
					 @record_id
	
END

/* Close and deallocate the cursor */
CLOSE autocash_cur
DEALLOCATE autocash_cur	

/* Check for over-a
pplied credit memos */
DECLARE autocash_cur CURSOR FOR 
	SELECT 	check_number,
		apply_to_num,
		check_amount,
		amt_applied,
		record_id
	FROM 	#autocash
	ORDER BY check_number, apply_to_num
				        
/* Open the cursor */
OPEN autocash_cur

/* Read the first entry from the autocash table */
FETCH autocash_cur INTO  @check_number,
			 @apply_to_number,
			 @check_amt,
			 @amt_applied,
			 @record_id


SELECT @last_check_number = ''
/* If the read was successful then enter 
the While loop */
WHILE @@fetch_status = 0
BEGIN

		IF @check_number <> @last_check_number
		BEGIN
			SELECT 	@last_check_number = @check_number,
				@tot_applied = 0,
				@open_amt = amt_on_acct
			FROM	artrx
			WHERE	doc_ctrl_num= @check_number
			AND	trx_type = 2111
			AND	payment_type = 3

			/* Deduct any unposted applications from the amount of the credit memo */
			SELECT	@total_unposted_apps = ISNULL(sum(amt_applied),0)
			FROM	arinppdt
			WHERE	doc_ctrl_num = @check_number



			SELECT 	@open_amt = @open_amt - @total_unposted_apps
			
			IF @check_amt <> @open_amt
			BEGIN
				UPDATE 	#autocash
				SET 	check_amount = @open_amt
				WHERE record_id = @record_id

				SELECT @check_amt = @open_amt
			END
			
	
	END

		SELECT 	@tot_applied = @tot_applied + @amt_applied

		IF @tot_applied > @check_amt
		BEGIN

			SELECT @amt_applied = @amt_applied - (@tot_applied - @check_amt)
			SELECT @tot_applied = @tot_applied - (@tot_applied - @check_amt)

			UPDATE 	#autocash
			SET 	amt_applied = @amt_applied
			WHERE record_id = @record_id

		END


		/* Read the next entry from the autocash table */
		FETCH autocash_cur INTO  @check_number,
					 @apply_to_number,
					 @check_amt,
					 @amt_applied,
					 @record_id
	
END

/* Close and deallocate the cursor */
CLOSE autocash_cur
DEALLOCATE autocash_cur	



/* Delete entries with amount applied of zero */
/* Begin Fix: 050901 - Change to less than or equal to zero*/
DELETE #autocash
WHERE amt_applied <= 0
/* End Fix: 050901 */

/* Begin Fix: 050901 */
DELETE #autocash
WHERE apply_to_num is NULL
OR apply_to_num = ''
/* End Fix: 050901 */

/* Put dates in yyyymmdd format */
UPDATE	#autocash
SET	check_date = substring(check_date,1,4) + substring(check_date,6,2) + substring(check_date,9,2),
	date_applied =  substring(date_applied,1,4) + substring(date_applied,6,2) + substring(date_applied,9,2)

/* Transfer the records
 to the live autocash table for processing */
INSERT	autocash 	(record_id,
			micr_number,
			check_number,
			check_amount,
			check_date,
			apply_to_num,
			amt_applied,
			amt_disc_taken,
			processed_flag,
			process_ctrl_num,
			customer_code,
			batch_number,
			date_applied,
			currency_code)
SELECT			record_id,
			micr_number,
			check_number,
			check_amount,
			convert(int,check_date),
			apply_to_num,
			amt_applied,
			amt_disc_taken,
			processed_flag,
			process_ctrl_num,
			customer_code,
			batch_number,
			convert(int,date_applied),
			currency_code
FROM 	#autocash
/* Begin Fix: 050901 */
	ORDER BY record_id
/* End Fix: 050901 */

/* Create the unposted cash receipt applications */
EXEC autocash_sp 0, 0, 0, 0, 0, 3, @from_trx OUTPUT, @to_trx OUTPUT, 
		0, '', '0000000000'


DROP TABLE #autocash

/* Succesful completion */
RETURN 0
GO
GRANT EXECUTE ON  [dbo].[arcbmtch_sp] TO [public]
GO
