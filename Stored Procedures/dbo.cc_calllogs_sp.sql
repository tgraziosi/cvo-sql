SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE	[dbo].[cc_calllogs_sp]	@inp_start varchar(18), 
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

	CREATE TABLE 	#results 
	(		user_name 	varchar(30)	NULL,
			total		smallint	NULL,
			start_date 	int	NULL,
			end_date 	int	NULL,
			company_name 	varchar(30)	NULL,
			start_date_dt 	smalldatetime	NULL,
			end_date_dt 	smalldatetime	NULL,
	)


	IF (@period_end >= @to_date)
		SELECT @period_end = @to_date


	INSERT 	#results( user_name, total, start_date, end_date, company_name )			
	SELECT	c.user_name, 
					COUNT(distinct comment_id), 
					@from_date, 
					@period_end, 
					@company_name
	FROM 		cc_comments c, cc_rpt_user_list u
	WHERE 	DATEDIFF(dd, '1/1/1753', comment_date ) + 639906 BETWEEN @from_date AND @period_end
	AND			c.user_name = u.user_name
	AND			my_id = @my_id
	AND			c.from_alerts <> 1 
	GROUP BY c.user_name

	IF ( SELECT COUNT(*) FROM #results ) = 0
		INSERT 	#results( user_name, total, start_date, end_date, company_name )			
		SELECT 	"No users with calls  ", 
						0 , 
						@from_date,
						@period_end, 
						@company_name


	SELECT @from_date = @period_end + 1
	SELECT @period_end = @from_date + 6

	IF (@period_end >= @to_date)
		SELECT @period_end = @to_date

	IF ( @to_date >= @from_date )
		BEGIN
			WHILE ( @period_end < @to_date + 1 )
				BEGIN
					INSERT 	#results( user_name, total, start_date, end_date, company_name )			
					SELECT	c.user_name, 
									COUNT(distinct comment_id), 
									@from_date, 
									@period_end, 
									@company_name
					FROM 		cc_comments c, cc_rpt_user_list u
					WHERE 	DATEDIFF(dd, '1/1/1753', comment_date ) + 639906 BETWEEN @from_date AND @period_end
					AND			c.user_name = u.user_name
					AND			my_id = @my_id
					AND			c.from_alerts <> 1 
					GROUP BY c.user_name
		
					IF ( SELECT COUNT(*) FROM #results WHERE start_date = @from_date AND end_date = @period_end ) = 0
						INSERT 	#results( user_name, total, start_date, end_date, company_name )			
						SELECT 	"No users with calls  ", 
							0 , 
							@from_date, 
							@period_end, 
							@company_name
		
					SELECT @from_date = @period_end + 1
					SELECT @period_end = @from_date + 6
				END
		END
		
	IF ( @period_end > @to_date + 1 )
		BEGIN
			INSERT 	#results( user_name, total, start_date, end_date, company_name )			
			SELECT	c.user_name, 
							COUNT(distinct comment_id), 
							@from_date, 
							@to_date, 
							@company_name
			FROM 		cc_comments c, cc_rpt_user_list u
			WHERE 	DATEDIFF(dd, '1/1/1753', comment_date ) + 639906 BETWEEN @from_date AND @to_date
			AND			c.user_name = u.user_name
			AND			my_id = @my_id
			AND			c.from_alerts <> 1 
			GROUP BY c.user_name

			IF ( SELECT COUNT(*) FROM #results WHERE start_date = @from_date AND end_date = @to_date ) = 0
				INSERT 	#results( user_name, total, start_date, end_date, company_name )			
				SELECT 	"No users with calls  ", 
					0 , 
					@from_date, 
					@to_date, 
					@company_name
		END

	UPDATE 	#results
	SET 		start_date_dt = CASE WHEN start_date > 639906 THEN CONVERT(DATETIME, DATEADD(dd, start_date - 639906, '1/1/1753')) ELSE GETDATE() END,
					end_date_dt = CASE WHEN end_date > 639906 THEN CONVERT(DATETIME, DATEADD(dd, end_date - 639906, '1/1/1753')) ELSE GETDATE() END


	SELECT	user_name,
		total,
		start_date_dt,
		end_date_dt,
		company_name
	FROM 	#results

	SET NOCOUNT OFF

GO
GRANT EXECUTE ON  [dbo].[cc_calllogs_sp] TO [public]
GO
