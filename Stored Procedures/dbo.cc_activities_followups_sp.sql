SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO



CREATE PROCEDURE [dbo].[cc_activities_followups_sp] @user_name varchar(255)
		

AS
	SET NOCOUNT ON
	DECLARE 	@today	int, 
				@future int, 
				@past_due int,
				@balance float,
				@cust varchar(16),
				@curr_code varchar(8),
				@last_payment_date datetime,
				@last_customer varchar(8)

	CREATE TABLE #cust_balance 
	(
		customer_code	varchar(16) NULL,
		comment_id	int NULL,
		balance 	float 	NULL,
		report_comment	varchar(255) NULL,
		customer_name	varchar(40) NULL,
		contact_name	varchar(40) NULL,
		contact_phone	varchar(30) NULL,
		followup_date	datetime NULL,
		last_payment_date	datetime NULL
	)

	INSERT	#cust_balance
	SELECT 	DISTINCT customer_code, 
				comment_id,
				NULL, 
				'',
				'',
				'',
				'',
				followup_date,
				''
		FROM 	cc_followups

		WHERE	comment_id IN ( SELECT comment_id FROM cc_comments WHERE [user_name] = @user_name )

	SELECT 	@today = COUNT(f.followup_date) 
	FROM 		cc_followups f, #cust_balance c
	WHERE 	DATEDIFF(dd, '1/1/1753', f.followup_date) + 639906 = datediff(dd, '1/1/1753', convert(datetime, getdate())) + 639906
	AND		f.comment_id = c.comment_id

	AND		f.followup_date = c.followup_date

	SELECT 	@future = COUNT(f.followup_date) 
	FROM 		cc_followups f, #cust_balance c
	WHERE 	DATEDIFF(dd, '1/1/1753', f.followup_date) + 639906 > datediff(dd, '1/1/1753', convert(datetime, getdate())) + 639906
	AND		f.comment_id = c.comment_id

	AND		f.followup_date = c.followup_date

	SELECT 	@past_due = COUNT(f.followup_date) 
	FROM 		cc_followups f, #cust_balance c
	WHERE 	DATEDIFF(dd, '1/1/1753', f.followup_date) + 639906 < datediff(dd, '1/1/1753', convert(datetime, getdate())) + 639906
	AND		f.comment_id = c.comment_id

	AND		f.followup_date = c.followup_date


	WHILE (SELECT COUNT(*) FROM #cust_balance WHERE balance is null) > 0
		BEGIN
			SELECT @balance = 0
			SELECT @cust = MIN(customer_code) 
			FROM #cust_balance 
			WHERE balance IS NULL

			IF @cust IS NULL
				BREAK

			IF ( SELECT COUNT(*) FROM artrxage WHERE customer_code = @cust ) > 0
				EXEC	cc_aging_balance_sp 	@cust, 
													'3', 
													@balance OUTPUT

			UPDATE 	#cust_balance 
			SET		balance = ISNULL(@balance, 0 )
			WHERE 	customer_code = @cust
		END


	UPDATE 	#cust_balance
	SET	report_comment = comments
	FROM	#cust_balance t, cc_comments r
	WHERE	t.customer_code = r.customer_code
	AND		t.comment_id = r.comment_id

	UPDATE 	#cust_balance
	SET	customer_name = c.customer_name,
			contact_name = c.contact_name,
			contact_phone = c.contact_phone
	FROM	#cust_balance t, arcust c
	WHERE	t.customer_code = c.customer_code

	SELECT @last_customer = MIN(customer_code) FROM #cust_balance 
	WHILE ( @last_customer IS NOT NULL )
		BEGIN
			SET ROWCOUNT 1

			SELECT @last_payment_date = CASE WHEN date_doc > 639906 THEN CONVERT(datetime, DATEADD(dd, date_doc - 639906, '1/1/1753')) else '' end
			FROM 		artrx h, #cust_balance c	
		 	WHERE 	h.customer_code = c.customer_code
			AND		h.customer_code = @last_customer
			AND 		trx_type = 2111
			AND 		void_flag = 0
			AND 		payment_type <> 3	
			ORDER BY date_doc DESC, trx_ctrl_num DESC 
		

			UPDATE 	#cust_balance
			SET		last_payment_date = @last_payment_date
			WHERE 	customer_code = @last_customer

			SET ROWCOUNT 0
			SELECT @last_customer = MIN(customer_code) FROM #cust_balance WHERE customer_code > @last_customer
		END

		

	SELECT @curr_code = home_currency FROM glco

	SELECT 	'Today' = @today, 
				'Past Due' = @past_due,
				'Future' = @future, 
				customer_code,
				comment_id,
				ISNULL(balance,0),
				ISNULL(report_comment,' '),
				ISNULL(customer_name,' '),
				ISNULL(contact_name,' '),
				ISNULL(contact_phone,' '),
				@curr_code,
				followup_date,
				last_payment_date
	FROM 		#cust_balance
	ORDER BY followup_date



	DROP TABLE #cust_balance
	SET NOCOUNT OFF

GO
GRANT EXECUTE ON  [dbo].[cc_activities_followups_sp] TO [public]
GO
