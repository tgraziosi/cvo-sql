SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO



CREATE PROCEDURE	[dbo].[cc_calllog_sp]		@inp_start varchar(18), 
																	@inp_finish varchar(18),
																	@my_id		varchar(255)


AS
	SET NOCOUNT ON

	DECLARE @period_end int,
					@from_date	int,
					@to_date varchar(15),
					@company_name varchar(30)

	SELECT @company_name 	= company_name FROM arco

	SELECT @from_date = DATEDIFF(dd, '1/1/1753', @inp_start) + 639906
	SELECT @to_date = DATEDIFF(dd, '1/1/1753', @inp_finish) + 639906
	SELECT @period_end = @from_date + 6



	CREATE TABLE #calllog
	(	[user_name]		varchar(20) NULL,
		customer_code		varchar(20) NULL,
		comment_date		varchar(12) NULL,
		[description]		varchar(50) NULL,
		customer_name		varchar(40)	NULL,
		territory_code	varchar(8)	NULL,
		comment		varchar(255) NULL,
		company_name	 varchar(30) NULL,
		log_type	tinyint NULL
	)

	IF (@period_end >= @to_date)
		SELECT @period_end = @to_date

	INSERT #calllog( user_name,	customer_code, comment_date, log_type)
	SELECT 	c.user_name, 
					customer_code, 
					CONVERT(varchar(12),comment_date),
					log_type
	FROM 	cc_comments c, cc_rpt_user_list u
	WHERE 	DATEDIFF(dd, '1/1/1753', comment_date ) + 639906 BETWEEN @from_date AND @period_end
	AND			c.user_name = u.user_name
	AND			my_id = @my_id
	AND			c.from_alerts <> 1 
	ORDER BY c.user_name, comment_date

	IF ( SELECT COUNT(*) FROM #calllog ) = 0
		INSERT 	#calllog (user_name, customer_name, company_name )
		SELECT 	'No users with calls  ', 
						CONVERT(varchar(12), dateadd(dd, @from_date - 639906, '1/1/1753')) + ' - ' + CONVERT(varchar(12), dateadd(dd, @period_end - 639906, '1/1/1753')),
						@company_name



	SELECT @from_date = @period_end + 1
	SELECT @period_end = @from_date + 6

	WHILE ( @period_end < @to_date + 1 )
		BEGIN



			INSERT #calllog( user_name,	customer_code, comment_date, log_type)
			SELECT 	c.user_name, 
							customer_code, 
							CONVERT(varchar(12),comment_date),
							log_type
			FROM 	cc_comments c, cc_rpt_user_list u
			WHERE 	DATEDIFF(dd, '1/1/1753', comment_date ) + 639906 BETWEEN @from_date AND @period_end
			AND			c.user_name = u.user_name
			AND			my_id = @my_id
			AND			c.from_alerts <> 1 
			ORDER BY c.user_name, comment_date
		
		
			IF ( SELECT COUNT(*) FROM #calllog ) = 0
				INSERT 	#calllog (user_name, customer_name, company_name )
				SELECT 	'No users with calls  ', 
						CONVERT(varchar(12), dateadd(dd, @from_date - 639906, '1/1/1753')) + ' - ' + CONVERT(varchar(12), dateadd(dd, @period_end - 639906, '1/1/1753')),
								@company_name

			SELECT @from_date = @period_end + 1
			SELECT @period_end = @from_date + 6
		END



	IF	( @period_end > @to_date + 1 )
		BEGIN
			INSERT #calllog( user_name,	customer_code, comment_date, log_type)
			SELECT 	c.user_name, 
							customer_code, 
							CONVERT(varchar(12),comment_date),
							log_type
			FROM 	cc_comments c, cc_rpt_user_list u
			WHERE 	DATEDIFF(dd, '1/1/1753', comment_date ) + 639906 BETWEEN @from_date AND @to_date
			AND			c.user_name = u.user_name
			AND			my_id = @my_id
			AND			c.from_alerts <> 1 
			ORDER BY c.user_name, comment_date
		
		
			IF ( SELECT COUNT(*) FROM #calllog ) = 0
				INSERT 	#calllog (user_name, customer_name, company_name )
				SELECT 	'No users with calls  ', 
						CONVERT(varchar(12), dateadd(dd, @from_date - 639906, '1/1/1753')) + ' - ' + CONVERT(varchar(12), dateadd(dd, @to_date - 639906, '1/1/1753')),
								@company_name
		END



	UPDATE #calllog
	SET	[description]= l.[description]
	FROM #calllog c LEFT OUTER JOIN  cc_log_types l ON c.log_type = l.log_type
		
	UPDATE #calllog
	SET	customer_name = a.customer_name,
			territory_code = a.territory_code
	FROM #calllog c, arcust a
	WHERE	c.customer_code = a.customer_code
		
	UPDATE #calllog
	SET			comment = r.comment
	FROM #calllog c, cc_rpt_comments r		
	WHERE		c.customer_code = r.customer_code
				
	UPDATE #calllog
	SET	company_name = @company_name


	SELECT	user_name,
		customer_code,
		comment_date,
		[description],
		customer_name,
		territory_code,
		comment,
		company_name
	FROM #calllog

	SET NOCOUNT OFF

GO
GRANT EXECUTE ON  [dbo].[cc_calllog_sp] TO [public]
GO
