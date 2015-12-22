SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


CREATE proc [dbo].[cc_create_invoice_alerts_sp]	@number_days 			int = 28,
																				@date_type				smallint = 0,	
																				@create_fu 				smallint = 1,	
																				@create_reminder	smallint = 1,	
																				@recurrance			smallint = 1,	
																				@user_name				varchar(20),
																				@user_id 					int,
																				@use_workload			smallint = 0,
																				@workload_code 		varchar(8) = NULL


AS
	SET NOCOUNT ON









	


	CREATE TABLE #inv_alerts 
	( number_days 	int, 
		date_type 		smallint, 
		date_created	int,
		created_by		varchar(20),
		trx_ctrl_num 	varchar(16), 
		doc_ctrl_num	varchar(16),
		date_applied 	int, 
		date_doc 			int, 
		date_due 			int, 
		date_aging 		int, 
		customer_code varchar(8), 
		balance 			float,
		workload_code	varchar(8) NULL ) 

	DECLARE	@today 					int, 
					@date_type_str 	varchar(30),
					@comment_id 		int,
					@comment				varchar(50),
					@customer_code	varchar(8),
					@last_doc				varchar(16),
					@comment_date		smalldatetime,
					@wl_clause 			varchar(255),
					@y 							varchar(4), 
					@m 							char(2), 
					@d 							varchar(2), 
					@date						varchar(20),
					@last_cust			varchar(8) 

	SELECT @today = DATEDIFF(dd, '1/1/1753', CONVERT(datetime, GETDATE())) + 639906

	IF ( @use_workload = 1 )
		BEGIN
			IF ( 	SELECT COUNT(*) 
						FROM cc_invoice_alerts 
						WHERE date_created = @today
						AND	workload_code = @workload_code ) > 0
				RETURN -1
		END
	ELSE
		BEGIN
			IF ( 	SELECT COUNT(*) 
						FROM cc_invoice_alerts 
						WHERE date_created = @today	 ) > 0
				RETURN -1
		END


	SELECT @comment_id = NULL

	SELECT @y = CONVERT(varchar(4), DATEPART(yy,GETDATE() ) )
	SELECT @m = CONVERT(char(2), DATEPART(mm, GETDATE()) )
	IF ( LEN(@m) = 1 )
		SELECT @m = '0' + @m
	SELECT @d = CONVERT(varchar(2), DATEPART(dd, GETDATE()) )
	SELECT @date = @y + '-' + @m + '-' + @d
	SELECT @date = @date + ' 00:01:00'
	SELECT @comment_date = @date


	IF ( @use_workload = 1 )
		SELECT @wl_clause = ' AND customer_code IN ( 	SELECT customer_code 
																									FROM ccwrkmem 
																									WHERE workload_code = "' + @workload_code + '" ) '
	ELSE
		SELECT @wl_clause = ' AND 0 = 0 '

	SELECT @date_type_str = CASE @date_type 
														WHEN 0 THEN 'date_doc < ' + CONVERT(varchar(15), @today - @number_days )
														WHEN 1 THEN 'date_applied < ' + CONVERT(varchar(15), @today - @number_days )
														WHEN 2 THEN 'date_aging < ' + CONVERT(varchar(15), @today - @number_days )
														WHEN 3 THEN 'date_due < ' + CONVERT(varchar(15), @today - @number_days )
													END


IF ( @use_workload = 1 )
	EXEC(	'	INSERT 	#inv_alerts( trx_ctrl_num, number_days, date_type, date_created, created_by, doc_ctrl_num, date_applied, date_doc, date_due, date_aging, customer_code, balance, workload_code ) 
					SELECT DISTINCT trx_ctrl_num, ' +	@number_days + ', ' + @date_type + ', ' + @today + ', "' + @user_name + '",doc_ctrl_num, date_applied, date_doc, date_due, date_aging, customer_code, amt_net - amt_paid_to_date, "' + @workload_code + '"
					FROM	 	artrx
					WHERE		paid_flag = 0
					AND			void_flag = 0
					AND			trx_type IN ( 2021, 2031 )
					AND	' + @date_type_str + ' ' + @wl_clause )
ELSE
	EXEC(	'	INSERT 	#inv_alerts( trx_ctrl_num, number_days, date_type, date_created, created_by, doc_ctrl_num, date_applied, date_doc, date_due, date_aging, customer_code, balance, workload_code ) 
					SELECT DISTINCT trx_ctrl_num, ' +	@number_days + ', ' + @date_type + ', ' + @today + ', "' + @user_name + '",doc_ctrl_num, date_applied, date_doc, date_due, date_aging, customer_code, amt_net - amt_paid_to_date, NULL
					FROM	 	artrx
					WHERE		paid_flag = 0
					AND			void_flag = 0
					AND			trx_type IN ( 2021, 2031 )
					AND	' + @date_type_str + ' ' + @wl_clause  )

	IF ( @@ERROR <> 0 )
		RETURN -2



	IF ( @recurrance = 1 )
		DELETE 	#inv_alerts
		WHERE		trx_ctrl_num IN ( SELECT trx_ctrl_num FROM cc_invoice_alerts )

	IF ( @@ERROR <> 0 )
		RETURN -3

	IF ( @recurrance = 2 )
		DELETE 	#inv_alerts
		WHERE		customer_code IN ( SELECT customer_code FROM cc_invoice_alerts WHERE date_created = @today )

	IF ( @@ERROR <> 0 )
		RETURN -3









	BEGIN TRAN
		IF ( @recurrance = 2 )
			BEGIN
				
				SELECT @last_cust = MIN( customer_code ) FROM #inv_alerts
				WHILE ( @last_cust IS NOT NULL )
					BEGIN
						
						SELECT @comment = 'Customer ' + @last_cust + ' has invoices ' + CONVERT(varchar(10), @number_days ) + ' past due '
						SELECT @customer_code = customer_code FROM #inv_alerts WHERE customer_code = @last_cust
						SELECT @comment_id = NULL
			
						EXEC cc_comments_i_sp 1, @customer_code, @user_name, @comment_date, @comment, @comment_id OUTPUT, NULL, NULL
						IF ( @@ERROR <> 0 )
							BEGIN
								ROLLBACK TRAN
								RETURN -4
							END
			
						
						IF ( @create_fu = 1 )
							EXEC cc_followups_i_sp @customer_code, @comment_id, @comment_date, 'A'
			
						IF ( @@ERROR <> 0 )
							BEGIN
								ROLLBACK TRAN
								RETURN -5
							END
		
						
						IF ( @create_reminder = 1 )
							BEGIN
								SELECT @comment = @customer_code + ' - has Invoices ' + CONVERT(varchar(10), @number_days ) + ' past due '
								EXEC cc_reminders_i_sp @user_id, @comment_date, @comment
								IF ( @@ERROR <> 0 )
									BEGIN
										ROLLBACK TRAN
										RETURN -6
									END
							END
						SELECT @last_cust = MIN( customer_code ) FROM #inv_alerts WHERE customer_code > @last_cust
					END
			END
		ELSE
			BEGIN
				
				SELECT @last_doc = MIN( doc_ctrl_num ) FROM #inv_alerts
				WHILE ( @last_doc IS NOT NULL )
					BEGIN
						
						SELECT @comment = 'Invoice ' + @last_doc + ' is ' + CONVERT(varchar(10), @number_days ) + ' past due '
						SELECT @customer_code = customer_code FROM #inv_alerts WHERE doc_ctrl_num = @last_doc
						SELECT @comment_id = NULL
			
						EXEC cc_comments_i_sp 1, @customer_code, @user_name, @comment_date, @comment, @comment_id OUTPUT, NULL, @last_doc
						IF ( @@ERROR <> 0 )
							BEGIN
								ROLLBACK TRAN
								RETURN -4
							END
			
						
						IF ( @create_fu = 1 )
							EXEC cc_followups_i_sp @customer_code, @comment_id, @comment_date, 'A'
			
						IF ( @@ERROR <> 0 )
							BEGIN
								ROLLBACK TRAN
								RETURN -5
							END
		
						
						IF ( @create_reminder = 1 )
							BEGIN
								SELECT @comment = @customer_code + ' - Invoice ' + @last_doc + ' is ' + CONVERT(varchar(10), @number_days ) + ' past due '
								EXEC cc_reminders_i_sp @user_id, @comment_date, @comment
								IF ( @@ERROR <> 0 )
									BEGIN
										ROLLBACK TRAN
										RETURN -6
									END
							END
						SELECT @last_doc = MIN( doc_ctrl_num ) FROM #inv_alerts WHERE doc_ctrl_num > @last_doc
					END
			END


		INSERT cc_invoice_alerts( number_days, date_type, date_created, created_by, trx_ctrl_num, doc_ctrl_num, date_applied, date_doc, date_due, date_aging, customer_code, balance, workload_code ) 
		SELECT	number_days, date_type, date_created, created_by, trx_ctrl_num, doc_ctrl_num, date_applied, date_doc, date_due, date_aging, customer_code, balance, workload_code
		FROM 		#inv_alerts
		IF ( @@ERROR <> 0 )
			BEGIN
				ROLLBACK TRAN
				RETURN -7
			END
	
	DROP TABLE #inv_alerts

	COMMIT TRAN

	SET NOCOUNT OFF

	RETURN 0
GO
GRANT EXECUTE ON  [dbo].[cc_create_invoice_alerts_sp] TO [public]
GO
