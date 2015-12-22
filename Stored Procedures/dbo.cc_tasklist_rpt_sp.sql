SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO



CREATE PROCEDURE [dbo].[cc_tasklist_rpt_sp]	@inp_start varchar(18),
																			@inp_finish varchar(18),
																			@option char(1) = '3',
																			@all_priority varchar(3) = '1',
																			@priority_from	varchar(5) = '',
																			@priority_to	varchar(5) = '',
																			@my_id	varchar(255) = '',
																			@user_name	varchar(30) = '',
																			@company_db	varchar(30) = ''
 	

AS
	SET NOCOUNT ON
	IF EXISTS (SELECT name FROM sysobjects WHERE name = 'sm_login_sp' ) EXEC sm_login_sp @user_name, @company_db
	


	DECLARE @balance float
	DECLARE @cust varchar(16)
	DECLARE @company_name varchar(30)
	DECLARE @priority_range varchar(255)

	DECLARE @date_option tinyint

	SELECT @date_option = CONVERT(tinyint,@option)

	SELECT @company_name = company_name FROM arco

	IF @all_priority = '1'
		SELECT @priority_range = ' 0 = 0 '
	ELSE
		SELECT @priority_range = ' priority BETWEEN "' + @priority_from + '" AND "' + @priority_to + '" '


	CREATE TABLE #cust_balance 
	(
		customer_code	varchar(16) NULL,
		balance 	float 	NULL,
		company_name 	varchar(30) NULL,
		report_comment	varchar(255) NULL,
 comment_id int
	)

	EXEC( '	INSERT	#cust_balance
					SELECT 	DISTINCT f.customer_code, 
						 NULL, "' +
						 		@company_name + '",
 		 		"",
 		f.comment_id
 FROM 		cc_followups f, cc_comments c, cc_rpt_user_list u
					WHERE		f.followup_date >= "' + @inp_start + '"
 AND			f.followup_date <= "' + @inp_finish + '"
					AND	' + @priority_range + '
					AND			c.user_name = u.user_name
					AND			my_id = "' + @my_id + '" ' +
				'	AND 		c.comment_id = f.comment_id ' )


	WHILE (SELECT COUNT(*) FROM #cust_balance WHERE balance is null) > 0
		BEGIN
			SELECT @balance = 0
			SELECT @cust = MIN(customer_code) 
			FROM #cust_balance 
			WHERE balance IS NULL

			IF @cust IS NULL
				BREAK

			EXEC	cc_aging_balance_sp 	@cust, 
							@option, 
							@balance OUTPUT

			UPDATE 	#cust_balance 
			SET	balance = ISNULL(@balance, 0)
			WHERE 	customer_code = @cust
		END









	UPDATE 	#cust_balance
	SET	report_comment = comments
	FROM	#cust_balance t, cc_comments r
	WHERE	t.customer_code = r.customer_code
	AND	t.comment_id = r.comment_id


	SELECT DISTINCT	CONVERT(datetime,cc_followups.followup_date) 'follow_up', 
			cc_followups.priority,
			cc_comments.user_name, 
			arcust.customer_code, 
			arcust.customer_name, 
			arcust.attention_name, 
			arcust.attention_phone, 
			arcust.territory_code,
			'amt_balance' = #cust_balance.balance, 
			cc_comments.comment_id, 
			CONVERT(datetime,@inp_start) 'from_date', 
			CONVERT(datetime, @inp_finish) 'to_date', 
			cc_followups.followup_date, 
			company_name,
			report_comment,
			'all_priority' = @all_priority,
			'priority_from' = @priority_from,
			'priority_to' = @priority_to,
			'user_list' = @my_id
	FROM	cc_followups, cc_comments, arcust, #cust_balance
	WHERE	cc_followups.comment_id = cc_comments.comment_id 
	AND	cc_followups.customer_code = cc_comments.customer_code 
	AND	cc_comments.customer_code = arcust.customer_code 
	AND	arcust.customer_code = #cust_balance.customer_code 
	AND	cc_followups.followup_date >= @inp_start 
	AND	cc_followups.followup_date <= @inp_finish
	ORDER BY user_name ASC, followup_date ASC

	DROP TABLE #cust_balance

	IF EXISTS (SELECT name FROM sysobjects WHERE name = 'sm_logoff_sp' ) EXEC sm_logoff_sp 
	SET NOCOUNT OFF

GO
GRANT EXECUTE ON  [dbo].[cc_tasklist_rpt_sp] TO [public]
GO
