SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[cc_calc_statistics_sp]	@from_cust					varchar(8),	
																				@thru_cust					varchar(8),	
																				@all_cust_flag			smallint = 1,
																				@all_workload_flag	smallint = 1,
																				@from_workload			varchar(8) = '',
																				@thru_workload			varchar(8) = '',
																				@period_type				smallint = 1,
																				@start_date_str			varchar(10) = '0',
																				@end_date_str				varchar(10) = '0',
																				@my_id							varchar(255) = '0',
																				@all_org_flag			smallint = 0,	 
																				@from_org varchar(30) = '',
																				@to_org varchar(30) = ''


AS
	SET NOCOUNT ON
	
	DECLARE	@e_age_bracket_1			smallint,
					@e_age_bracket_2			smallint,
					@e_age_bracket_3			smallint,
					@e_age_bracket_4			smallint,
					@e_age_bracket_5			smallint,

					@b_age_bracket_1	smallint,
					@b_age_bracket_2			smallint,
					@b_age_bracket_3			smallint,
					@b_age_bracket_4			smallint,
					@b_age_bracket_5			smallint,
					@b_age_bracket_6			smallint,
					@precision_home				smallint,
					@symbol								varchar(8),
					@home_currency				varchar(8),
					@multi_currency_flag	smallint,
					@where_clause					varchar(255),
					@str_age_bracket_1		varchar(20),
					@str_age_bracket_2		varchar(20),
					@str_age_bracket_3		varchar(20),
					@str_age_bracket_4		varchar(20),
					@str_age_bracket_5		varchar(20),
					@str_age_bracket_6		varchar(20),
					@company_name					varchar(30),
					@where_clause2				varchar(255),
					@bucket_increment			smallint,
					@counter							smallint,
					@new_end_date					int,
					@new_start_date				int,
					@period_type_str			varchar(5),
					@glco_company_id 			smallint,
					@glco_period_end_date	int,
					@period_start_date 		int,
					@last_period					int,
					@min_date 						int, 
					@max_date 						int, 
					@min_date_str 				varchar(10), 
					@max_date_str 				varchar(10),
					@last_end_date 				int, 
					@prev_end_date 				int,
					@period_num 					smallint, 
					@last_end_date_str 		varchar(12), 
					@prev_end_date_str 		varchar(12), 
					@period_num_str 			varchar(5),	
					@period_sales 				float,
					@num_periods					smallint,
					@cust_code 						varchar(8),
					@last_cust	 					varchar(8),
					@sum_net_days 				int,
					@today								int,
					@max_periods 					int,
					@min_cust_date 				int,
					@min_co_date					int,
					@total_cust_sales 		float,
					@total_co_sales				float,
					@total_cust_days 			int,
					@total_co_days 				int,
					@total_cust_ar 				float,
					@total_co_ar 					float,
					@cust_dso							int,
					@co_dso								int,
					@days_increment 			int,
					@total 								float,
					@age1 								float,
					@age2 								float,
					@age3 								float,
					@age4 								float,
					@age5 								float,
					@age6 								float,
					@last_customer 				varchar(8),
					@last_start_date 			int,
					@where_clause_org		varchar(255),

					@age0								float,
					@str_age_bracket_0		varchar(20),
					@date_to_age_on			int

	IF	( ISNULL(DATALENGTH(LTRIM(RTRIM(@end_date_str))),0) ) = 0
		SELECT @end_date_str = CONVERT(varchar(12), GETDATE(),101)

	SELECT @today = DATEDIFF(dd, '1/1/1753', CONVERT(datetime, GETDATE())) + 639906



	
	IF @all_cust_flag = 0
		BEGIN
			IF (( SELECT CHARINDEX( "_", @from_cust )) = 0 AND ( SELECT CHARINDEX( "%", @from_cust )) = 0 )	 
				SELECT @where_clause = "(( c.customer_code >= '" + @from_cust + "' "
			ELSE
				SELECT @where_clause = "(( c.customer_code LIKE '" + @from_cust + "' "

			IF (( SELECT CHARINDEX( "_", @thru_cust )) = 0 AND ( SELECT CHARINDEX( "%", @thru_cust )) = 0 )
				SELECT @where_clause = @where_clause + " AND c.customer_code <= '" + @thru_cust + "' ))"
			ELSE
				SELECT @where_clause = @where_clause + " AND c.customer_code LIKE '" + @thru_cust + "' ))"
		END
 	ELSE
		SELECT @where_clause = '0=0'


	SELECT @where_clause2 = ''

	IF @all_workload_flag = 0
		BEGIN
			
			IF (( SELECT CHARINDEX( "_", @from_workload )) = 0 AND ( SELECT CHARINDEX( "%", @from_workload )) = 0 )
				SELECT @where_clause2 = " AND (( workload_code >= '" + @from_workload + "' "
			ELSE
				SELECT @where_clause2 = " AND (( workload_code LIKE '" + @from_workload + "' " 

			IF (( SELECT CHARINDEX( "_", @thru_workload )) = 0 AND ( SELECT CHARINDEX( "%", @thru_workload )) = 0 )
				SELECT @where_clause2 = @where_clause2 + " AND workload_code <= '" + @thru_workload + "' ))"
			ELSE
				SELECT @where_clause2 = " AND workload_code LIKE '" + @thru_workload + "' ))"
		END


	SELECT @where_clause_org = ' AND 0 = 0 '

	IF @all_org_flag = 0
		BEGIN
			
			IF ( ( SELECT CHARINDEX( "_", @from_org ) ) = 0
			 AND ( SELECT CHARINDEX( "%", @from_org ) ) = 0 )
				SELECT @where_clause_org = @where_clause_org + " AND ( ( a.org_id >= '" + @from_org + "' "
			ELSE
				SELECT @where_clause_org = @where_clause_org + " AND ( ( a.org_id LIKE '" + @from_org + "' " 

			IF ( ( SELECT CHARINDEX( "_", @to_org ) ) = 0
			 AND ( SELECT CHARINDEX( "%", @to_org ) ) = 0 )
				SELECT @where_clause_org = @where_clause_org + " AND a.org_id <= '" + @to_org + "' ) )"
			ELSE
				SELECT @where_clause_org = @where_clause_org + " AND a.org_id LIKE '" + @to_org + "' ) )"
		END
	

	
	SELECT	@precision_home 	= curr_precision,
					@multi_currency_flag 	= multi_currency_flag,
					@home_currency 		= home_currency,
					@symbol 		= symbol,
					@company_name		= company_name
	FROM		glcurr_vw, glco
	WHERE		glco.home_currency 	= glcurr_vw.currency_code

	
	SELECT 	@e_age_bracket_1 	= age_bracket1,
					@e_age_bracket_2 	= age_bracket2,
					@e_age_bracket_3 	= age_bracket3,
					@e_age_bracket_4 	= age_bracket4,
					@e_age_bracket_5 	= age_bracket5 
	FROM arco

	
	SELECT 	@b_age_bracket_2 	= @e_age_bracket_1 + 1,
					@b_age_bracket_3 	= @e_age_bracket_2 + 1,
					@b_age_bracket_4 	= @e_age_bracket_3 + 1,
					@b_age_bracket_5 	= @e_age_bracket_4 + 1,
					@b_age_bracket_6 	= @e_age_bracket_5 + 1 



		SELECT 	@e_age_bracket_1 	= 30,
						@e_age_bracket_2 	= 60,
						@e_age_bracket_3 	= 90,
						@e_age_bracket_4 	= 120,
						@e_age_bracket_5 	= 150


		SELECT 	@b_age_bracket_1 	= 1,
						@b_age_bracket_2 	= 31,
						@b_age_bracket_3 	= 61,
						@b_age_bracket_4 	= 91,
						@b_age_bracket_5 	= 121,
						@b_age_bracket_6 	= 151

	CREATE TABLE #statistics_age
	(
		start_date 			int NULL,
		end_date 				int NULL,
		period_number 	tinyint NULL,
		period_desc 		varchar(255) NULL,
		start_date_dt		datetime NULL,
		end_date_dt			datetime NULL
	)

	SELECT @period_type_str = CONVERT(varchar(5),@period_type)

	SELECT @period_start_date = ISNULL(DATEDIFF(dd, '1/1/1753', CONVERT(datetime, @start_date_str)) + 639906, 0)
	IF @period_start_date = 0
		SET @period_start_date = @today

	SELECT @num_periods = ISNULL(DATEDIFF(mm, @period_start_date, @today), 1)
	
	IF @period_type = 2
		SELECT 	@bucket_increment = 3,
						@days_increment = 90,
						@num_periods = DATEDIFF(q, @start_date_str, @end_date_str ) + 1
	ELSE IF @period_type = 3
		BEGIN
			DECLARE @num_float float
			SELECT 	@bucket_increment = 6,
							@days_increment = 180,
							@num_float = CONVERT(float,(( DATEDIFF(mm, @start_date_str, @end_date_str )) + 1 ))/6.0
			SELECT 	@num_periods = ceiling(@num_float)
		END		
	ELSE IF @period_type = 4
		SELECT 	@bucket_increment = 12,
						@days_increment = 360,
						@num_periods = DATEDIFF(yy, @start_date_str, @end_date_str ) + 1
	ELSE 
		SELECT 	@bucket_increment = 1,
						@days_increment = 30,
						@num_periods = DATEDIFF(m, @start_date_str, @end_date_str ) + 1
	
	INSERT 	#statistics_age(start_date,end_date,period_number)
	SELECT 	@period_start_date - @days_increment, 
					@period_start_date, 
					1

	SELECT @last_period = 1
	WHILE @last_period < @num_periods
		BEGIN
			SELECT @last_period = @last_period + 1

			SELECT @new_start_date = MAX(end_date) + 1 from #statistics_age WHERE period_number = @last_period - 1
			SELECT @new_end_date = @new_start_date + @days_increment
			
			INSERT 	#statistics_age(start_date,end_date,period_number) 
			SELECT 	@new_start_date, 
							@new_end_date, 
							@last_period
		END
		


	SELECT @new_end_date = MIN( start_date ) - 1 from #statistics_age 
	SELECT @new_start_date = @new_end_date - @days_increment


	INSERT	#statistics_age(start_date,end_date,period_number) 
	SELECT	@new_start_date, 
					@new_end_date, 
					0

	UPDATE 	#statistics_age
	SET	start_date_dt = CONVERT(datetime, dateadd(dd, start_date - 639906, '1/1/1753') ),
			end_date_dt = CONVERT(datetime, dateadd(dd, end_date - 639906, '1/1/1753') )



	CREATE TABLE #age_summary
	(	customer_code			varchar(8)	NULL,
		period_number			smallint	NULL,
		end_date					int		NULL,
		start_date				int		NULL,
		amount						float	NULL,
		amt_age_bracket1	float	NULL,
		amt_age_bracket2	float	NULL,
		amt_age_bracket3	float	NULL,
		amt_age_bracket4	float	NULL,
		amt_age_bracket5	float	NULL,
		amt_age_bracket6	float	NULL,
		period_sales			float	NULL,
		workload_code			varchar(8) NULL,
		workload_desc			varchar(65) NULL,
		end_ar_bal				float	NULL,
		avg_days_pay			int	NULL,
		min_cust_date 		int 	NULL,
		min_co_date				int 	NULL,
		total_cust_sales 	float 	NULL,
		total_co_sales		float 	NULL,
		total_cust_days 	int 	NULL,
		total_co_days 		int 	NULL,
		total_cust_ar 		float 	NULL,
		total_co_ar 			float 	NULL,
		cust_dso					int	NULL,
		co_dso						int	NULL,

		date_required			int	NULL,
		amt_age_bracket0	float	NULL	)



	CREATE TABLE #customers
	(
		customer_code		varchar(8)
	)




	IF @all_workload_flag = 0
		EXEC	(	"	INSERT #customers
							SELECT 	c.customer_code
							FROM 		arcust c, ccwrkmem m	
							WHERE "	+ @where_clause + " " + @where_clause2 +
						"	AND 		c.customer_code = m.customer_code ")
	ELSE
		EXEC	(	"	INSERT #customers
							SELECT 	c.customer_code
							FROM 		arcust c
							WHERE "	+ @where_clause )

CREATE INDEX #customers_idx1 ON #customers(customer_code)


	CREATE TABLE #artrxage_tmp
	(
		customer_code 		varchar(8)	NULL, 
		doc_ctrl_num			varchar(16)	NULL,
		ref_id						smallint	NULL,
		date_applied 			int		NULL, 
		amount 						float		NULL,	
		amt_age_bracket1	float		NULL,	
		amt_age_bracket2 	float		NULL,
		amt_age_bracket3	float		NULL,
		amt_age_bracket4	float		NULL,
		amt_age_bracket5	float		NULL,
		amt_age_bracket6	float		NULL,		 
		nat_cur_code 			varchar(8)	NULL, 
		rate_home 				float		NULL, 
		rate_type 				varchar(8)	NULL, 
		company_name			varchar(30)	NULL,
		period_sales			float		NULL,
		start_date				int		NULL,
		end_date					int		NULL,
		period_number			smallint	NULL,
		org_id						varchar(30) NULL,

		date_required			int	NULL,
		amt_age_bracket0	float	NULL	)

	CREATE TABLE #artrxage_sum
	(
		amount 						float		NULL,	
		amt_age_bracket1	float		NULL,	
		amt_age_bracket2 	float		NULL,
		amt_age_bracket3	float		NULL,
		amt_age_bracket4	float		NULL,
		amt_age_bracket5	float		NULL,
		amt_age_bracket6	float		NULL,		 
		start_date				int		NULL,
		customer_code 		varchar(8)	NULL,

		amt_age_bracket0	float	)

	SELECT @min_date = MIN(start_date) FROM #statistics_age
	SELECT @max_date = MAX(end_date) FROM #statistics_age
	SELECT @min_date_str = CONVERT(varchar(10), @min_date )
	SELECT @max_date_str = CONVERT(varchar(10), @max_date )

	SELECT @last_end_date = 0, @period_num = 0
	
	BEGIN
		SELECT @last_end_date = MIN(end_date) FROM #statistics_age 
		WHILE (@last_end_date IS NOT NULL)
			BEGIN	
				SELECT @last_end_date_str = CONVERT(varchar(10), @last_end_date )
				SELECT @period_num_str = CONVERT(varchar(5), @period_num )

				
				EXEC (	" INSERT #artrxage_tmp 
									SELECT	a.customer_code, 
									a.doc_ctrl_num,
									a.ref_id,
									a.date_applied, 
									a.amount, 
									0,
									0,
									0,
									0,
									0,
									0,
									a.nat_cur_code, 
									a.rate_home, 
									' ', '" + 
									@company_name + "', 
									0,
									0,
									0, " +
									@period_num_str + ", " +
								" a.org_id,

									h.date_required,
									0 
								FROM 	artrxage a, #customers c, artrx_all h
								WHERE a.customer_code = c.customer_code 
								AND 	a.date_applied <= " + @last_end_date_str + " " + @where_clause_org	+

							"	AND 	a.trx_ctrl_num = h.trx_ctrl_num " )

				SELECT @period_num = @period_num + 1
				SELECT @last_end_date = MIN(end_date) FROM #statistics_age WHERE end_date > @last_end_date		
			END
	END

	CREATE INDEX #artrxage_tmp_idx1 ON #artrxage_tmp(doc_ctrl_num)

	UPDATE 	#artrxage_tmp
	SET			start_date = s.start_date,
					end_date = s.end_date
	FROM		#statistics_age s, #artrxage_tmp t
	WHERE		t.period_number = s.period_number


	UPDATE 	#artrxage_tmp 
	SET 		date_applied = b.date_applied
	FROM 		#artrxage_tmp , #artrxage_tmp b
	WHERE 	#artrxage_tmp.doc_ctrl_num = b.doc_ctrl_num
	AND 		#artrxage_tmp.ref_id = -1
	AND 		b.ref_id = 0
	AND 		#artrxage_tmp.date_applied = 0
	AND			b.period_number = #artrxage_tmp.period_number




















































	SELECT @date_to_age_on = DATEDIFF(dd, '1/1/1753', GETDATE()) + 639906
	SELECT @last_customer = MIN(customer_code) FROM #artrxage_tmp
	WHILE @last_customer IS NOT NULL
		BEGIN
			EXEC cc_statistics_aging_sp @last_customer,
																	4,								
																	@date_to_age_on,
																	@total OUTPUT, 	
																	@age1	 OUTPUT, 	
																	@age2	 OUTPUT, 	
																	@age3	 OUTPUT, 	
																	@age4	 OUTPUT, 	
																	@age5	 OUTPUT, 	
																	@age6	 OUTPUT,
																	@all_org_flag,
																	@from_org,
																	@to_org,
																	@age0		OUTPUT



			INSERT	#artrxage_sum
			SELECT	@total,
							@age1,
							@age2,
							@age3,
							@age4,
							@age5,
							@age6,
							@date_to_age_on,
							@last_customer,
							@age0

			SELECT @last_customer = MIN(customer_code) 
			FROM #artrxage_tmp
			WHERE customer_code > @last_customer
		END







		UPDATE 	#artrxage_tmp
		SET			amount = s.amount,
						amt_age_bracket1 = s.amt_age_bracket1,
						amt_age_bracket2 = s.amt_age_bracket2,
						amt_age_bracket3 = s.amt_age_bracket3,
						amt_age_bracket4 = s.amt_age_bracket4,
						amt_age_bracket5 = s.amt_age_bracket5,
						amt_age_bracket6 = s.amt_age_bracket6,
						amt_age_bracket0 = s.amt_age_bracket0
		FROM		#artrxage_tmp, #artrxage_sum s
		WHERE		
			#artrxage_tmp.customer_code = s.customer_code











	SELECT @str_age_bracket_0 = 'Future'
	SELECT @str_age_bracket_1 = 'Current'
	SELECT @str_age_bracket_2 = '1-30 Days Over'
	SELECT @str_age_bracket_3 = '31-60 Days Over'
	SELECT @str_age_bracket_4 = '61-90 Days Over'
	SELECT @str_age_bracket_5 = '91-120 Days Over'
	SELECT @str_age_bracket_6 = '120 + Days Over'


	IF ( ISNULL( DATALENGTH( RTRIM( LTRIM( @from_workload ))), 0 ) = 0 )
		SELECT @from_workload = min(workload_code) from ccwrkhdr where workload_code IS NOT NULL
	IF ( ISNULL( DATALENGTH( RTRIM( LTRIM( @thru_workload ))), 0 ) = 0 )
		SELECT @thru_workload = max(workload_code) from ccwrkhdr


	INSERT	#age_summary
	(	customer_code,
		period_number,
		end_date,
		amount,
		amt_age_bracket1,
		amt_age_bracket2,
		amt_age_bracket3,
		amt_age_bracket4,
		amt_age_bracket5,
		amt_age_bracket6,
		amt_age_bracket0	)		
	SELECT 	customer_code,
					t.period_number, 
					s.end_date,
					amount,
					amt_age_bracket1,
					amt_age_bracket2,
					amt_age_bracket3,
					amt_age_bracket4,
					amt_age_bracket5,
					amt_age_bracket6,			
					amt_age_bracket0
	FROM 	#artrxage_tmp t, #statistics_age s
	WHERE	t.period_number = s.period_number
	GROUP BY t.customer_code, t.period_number, s.end_date, s.start_date,amount,		amt_age_bracket0, amt_age_bracket1,		amt_age_bracket2,		amt_age_bracket3,		amt_age_bracket4,		amt_age_bracket5,		amt_age_bracket6

	UPDATE 	#age_summary
	SET			workload_code = w.workload_code
	FROM		ccwrkmem w, #age_summary t
	WHERE		w.customer_code = t.customer_code
	AND			w.workload_code BETWEEN @from_workload AND @thru_workload

	
	UPDATE 	#age_summary
	SET			workload_desc = w.workload_desc
	FROM		ccwrkhdr w, #age_summary t
	WHERE		w.workload_code = t.workload_code


	UPDATE 	#age_summary
	SET			workload_desc = 'Not Assigned to Any Workload'
	WHERE		ISNULL(DATALENGTH(LTRIM(RTRIM(workload_code))),0) = 0

	UPDATE 	#age_summary
	SET			start_date = s.start_date	
	FROM		#statistics_age s, #age_summary t
	WHERE		s.period_number = t.period_number




	CREATE TABLE #sales_tmp
	(
		customer_code 	varchar(8)	NULL, 
		date_applied 		int		NULL, 
		amount 					float		NULL,	
		nat_cur_code 		varchar(8)	NULL, 
		rate_home 			float		NULL, 
		period_sales		float		NULL,
		start_date			int		NULL,
		end_date				int		NULL,
		period_number		smallint	NULL
	)

	SELECT @min_date = MIN(start_date) FROM #statistics_age
	SELECT @max_date = MAX(end_date) FROM #statistics_age
	SELECT @min_date_str = CONVERT(varchar(10), @min_date )
	SELECT @max_date_str = CONVERT(varchar(10), @max_date )


	
	SELECT @last_end_date = MIN(end_date) FROM #statistics_age 
	SELECT @last_end_date_str = CONVERT(varchar(10), @last_end_date )
	SELECT @period_num = 1
	SELECT @period_num_str = CONVERT(varchar(5), @period_num )

	WHILE (@last_end_date IS NOT NULL)
		BEGIN	

		
			IF @all_org_flag = 1
				EXEC (	" INSERT #sales_tmp 
									SELECT	a.customer_code, 
													a.date_applied, 
													a.amount, 
													a.nat_cur_code, 
													a.rate_home, 
													0,
													0,
													0, " +
													@period_num_str + "
									FROM 	artrxage a, #customers c, #statistics_age s 
									WHERE a.customer_code = c.customer_code 
									AND		date_applied BETWEEN start_date AND end_date 
									AND		trx_type IN (2031, 2021) 
									AND 	s.period_number = " + @period_num_str )
				ELSE
					EXEC (	" INSERT #sales_tmp 
										SELECT	a.customer_code, 
														a.date_applied, 
														a.amount, 
														a.nat_cur_code, 
														a.rate_home, 
														0,
														0,
														0, " +
														@period_num_str + "
										FROM 	artrxage a, #customers c, #statistics_age s 
										WHERE a.customer_code = c.customer_code 
										AND		date_applied BETWEEN start_date AND end_date 
										AND		trx_type IN (2031, 2021) 
										AND		org_id BETWEEN '" + @from_org + "' AND '" + @to_org + "' " +
									"	AND 	s.period_number = " + @period_num_str )


				SELECT @prev_end_date = @last_end_date
				SELECT @period_num = @period_num + 1
				SELECT @last_end_date = MIN(end_date) FROM #statistics_age WHERE end_date > @last_end_date	

				SELECT @last_end_date_str = CONVERT(varchar(10), @last_end_date )
				SELECT @prev_end_date_str = CONVERT(varchar(10), @prev_end_date )
				SELECT @period_num_str = CONVERT(varchar(5), @period_num )				
		END
			
	UPDATE 	#sales_tmp
	SET			start_date = s.start_date,
					end_date = s.end_date
	FROM		#statistics_age s, #sales_tmp t
	WHERE		t.period_number = s.period_number

		
	UPDATE #sales_tmp
	SET amount = (SELECT ROUND(amount * ( SIGN(1 + SIGN(rate_home))*(rate_home) + (SIGN(ABS(SIGN(ROUND(rate_home,6))))/(rate_home + SIGN(1 - ABS(SIGN(ROUND(rate_home,6)))))) * SIGN(SIGN(rate_home) - 1) ), @precision_home))



	CREATE TABLE #sales_summary
	(
		customer_code varchar(8)	NULL, 
		period_number	smallint	NULL,
		amount 				float		NULL	
	)

	INSERT	#sales_summary
	(	
		customer_code,
		period_number,
		amount
	)		
	SELECT 	customer_code,
					period_number, 
					SUM(amount)
	FROM 	#sales_tmp
	GROUP BY customer_code, period_number


	UPDATE 	#age_summary
	SET			period_sales = s.amount
	FROM 	#age_summary t, #sales_summary s
	WHERE		s.customer_code = t.customer_code
	AND			s.period_number = t.period_number



	


	CREATE TABLE #avgdays_tmp
	(
		customer_code 	varchar(8)	NULL, 
		date_paid 			int		NULL,
		date_aging 			int		NULL, 
		customer_count	int		NULL,
		sum_date_paid 	int		NULL, 
		sum_date_aging 	int		NULL, 
		sum_net_days 		int		NULL, 
		period_number		smallint	NULL
	)

	SELECT @min_date = MIN(start_date) FROM #statistics_age
	SELECT @max_date = MAX(end_date) FROM #statistics_age
	SELECT @min_date_str = CONVERT(varchar(10), @min_date )
	SELECT @max_date_str = CONVERT(varchar(10), @max_date )
	SELECT @max_periods = MAX(period_number) FROM #statistics_age

	SELECT @last_end_date = MIN(end_date) FROM #statistics_age 
	SELECT @last_end_date_str = CONVERT(varchar(10), @last_end_date )
	SELECT @period_num = 1
	SELECT @period_num_str = CONVERT(varchar(5), @period_num )


	







































	IF @all_org_flag = 1
			INSERT #avgdays_tmp (customer_code,date_paid,date_aging,period_number)
			SELECT	a.customer_code, 
							ISNULL(a.date_paid,0),
							ISNULL(a.date_aging,0),
							@period_num
			FROM 	artrx a, #customers c
			WHERE a.customer_code = c.customer_code 



			AND	trx_type IN (2031, 2021) 
			AND paid_flag = 1
	ELSE
			INSERT #avgdays_tmp (customer_code,date_paid,date_aging,period_number)
			SELECT	a.customer_code, 
							ISNULL(a.date_paid,0),
							ISNULL(a.date_aging,0),
							@period_num
			FROM 	artrx a, #customers c
			WHERE a.customer_code = c.customer_code 



			AND	trx_type IN (2031, 2021) 
			AND paid_flag = 1
			AND		org_id BETWEEN @from_org AND @to_org
			


	UPDATE #avgdays_tmp
	SET	sum_net_days = date_paid - date_aging



	CREATE TABLE #avgdays_summary
	(
		customer_code 	varchar(8)	NULL, 
		period_number		smallint	NULL,
		sum_net_days 		int		NULL 
	)

	
	SELECT @last_cust = MIN(customer_code) FROM #avgdays_tmp
	WHILE (@last_cust IS NOT NULL)
		BEGIN	
			SELECT @period_num = 1
			WHILE ( @period_num <= @max_periods )
				BEGIN
					IF (SELECT COUNT(*) FROM #avgdays_tmp WHERE customer_code = @last_cust ) > 0
						SELECT	@sum_net_days = SUM(sum_net_days )/ COUNT(customer_code)
						FROM 	#avgdays_tmp
						WHERE	customer_code = @last_cust




					ELSE
						SELECT	@sum_net_days = 0

				
					INSERT	#avgdays_summary
					SELECT 	@last_cust,
									@period_num, 
									@sum_net_days

					SELECT @period_num = @period_num + 1
				END

			SELECT	@total_cust_ar = SUM(ROUND(amount * ( SIGN(1 + SIGN(rate_home))*(rate_home) + (SIGN(ABS(SIGN(ROUND(rate_home,6))))/(rate_home + SIGN(1 - ABS(SIGN(ROUND(rate_home,6)))))) * SIGN(SIGN(rate_home) - 1) ), @precision_home)),
							@min_cust_date = MIN(date_aging),
							@total_cust_days = @today - MIN(date_aging)				
			FROM		artrxage
			WHERE		customer_code = @last_cust

			SELECT	@total_cust_sales = SUM(ROUND(amount * ( SIGN(1 + SIGN(rate_home))*(rate_home) + (SIGN(ABS(SIGN(ROUND(rate_home,6))))/(rate_home + SIGN(1 - ABS(SIGN(ROUND(rate_home,6)))))) * SIGN(SIGN(rate_home) - 1) ), @precision_home))
			FROM		artrxage
			WHERE		customer_code = @last_cust
			AND			trx_type in (2021, 2031 )

			UPDATE	#age_summary
			SET	min_cust_date = @min_cust_date,
					total_cust_days = @total_cust_days,
					total_cust_ar = @total_cust_ar,
					total_cust_sales = @total_cust_sales 
			FROM	artrxage a, #age_summary t
			WHERE	a.customer_code = t.customer_code
			AND	a.customer_code = @last_cust

			SELECT @last_cust = MIN(customer_code) FROM #avgdays_tmp
			WHERE customer_code > @last_cust	
		END



	UPDATE 	#age_summary
	SET			avg_days_pay = ISNULL(sum_net_days,0)
	FROM 	#age_summary t, #avgdays_summary a
	WHERE		a.customer_code = t.customer_code
	AND			a.period_number = t.period_number


	SELECT	@total_co_ar = SUM(ROUND(amount * ( SIGN(1 + SIGN(rate_home))*(rate_home) + (SIGN(ABS(SIGN(ROUND(rate_home,6))))/(rate_home + SIGN(1 - ABS(SIGN(ROUND(rate_home,6)))))) * SIGN(SIGN(rate_home) - 1) ), @precision_home)),
					@min_co_date = MIN(date_aging),
					@total_co_days = @today - MIN(date_aging)		
	FROM		artrxage

	SELECT	@total_co_sales = SUM(ROUND(amount * ( SIGN(1 + SIGN(rate_home))*(rate_home) + (SIGN(ABS(SIGN(ROUND(rate_home,6))))/(rate_home + SIGN(1 - ABS(SIGN(ROUND(rate_home,6)))))) * SIGN(SIGN(rate_home) - 1) ), @precision_home))
	FROM		artrxage
	WHERE		trx_type in (2021, 2031 )

	UPDATE	#age_summary
	SET	min_co_date = @min_co_date,
			total_co_days = @total_co_days,
			total_co_ar = @total_co_ar,
			total_co_sales = @total_co_sales
	FROM	artrxage

	
	UPDATE	#age_summary
	SET	cust_dso = total_cust_days / ( total_cust_sales / ( total_cust_ar / 2 ) )	
	WHERE	total_cust_days > 0
	AND	total_cust_sales > 0
	AND 	total_cust_ar > 0
		
	UPDATE	#age_summary
	SET	co_dso = total_co_days / ( total_co_sales / ( total_co_ar / 2 ) )		
	WHERE	total_co_days > 0
	AND	total_co_sales > 0
	AND 	total_co_ar > 0
		







	
	INSERT calc_stats
	(	workload_code,
		customer_code,
		customer_name,
		period_number,
		EndDate,
		end_date,
		period_sales,
		total_home,
		amt_age_bracket1,
		amt_age_bracket2,
		amt_age_bracket3,
		amt_age_bracket4,
		amt_age_bracket5,
		amt_age_bracket6,
		ab1,
		ab2,
		ab3,
		ab4,
		ab5,
		ab6,
		fromcust,
		thrucust,
		CompanyName,
		AllCust,
		AllWorkload,
		CurSymbol,
		FromWkld,
		ThruWkld,
		workload_desc,
		avg_days_pay,
		min_cust_date,
		min_co_date,
		total_cust_sales,
		total_co_sales,
		total_cust_days,
		total_co_days,
		total_cust_ar,
		total_co_ar,
		cust_dso,
		co_dso,
		PeriodType,
		start_date_str,
		end_date_str,
		my_id,
		all_org_flag,
		from_org,
		thru_org,
		amt_age_bracket0,
		ab0	)
	
	SELECT	workload_code,
					c.customer_code,
					address_name, 
					period_number,
					CASE WHEN end_date > 639906 THEN CONVERT(datetime, DATEADD(dd, end_date - 639906, '1/1/1753')) ELSE end_date END,
					end_date,
					period_sales,
					amount, 
					amt_age_bracket1,
					amt_age_bracket2,
					amt_age_bracket3,
					amt_age_bracket4,
					amt_age_bracket5,
					amt_age_bracket6,
					@str_age_bracket_1,
					@str_age_bracket_2,
					@str_age_bracket_3,
					@str_age_bracket_4,
					@str_age_bracket_5,
					@str_age_bracket_6,
					@from_cust,
					@thru_cust,
					@company_name,
					@all_cust_flag,
					@all_workload_flag,
					@symbol,
					@from_workload,
					@thru_workload,
					workload_desc,
					avg_days_pay,
					min_cust_date,
					min_co_date,
					total_cust_sales,
					total_co_sales,
					total_cust_days,
					total_co_days,
					total_cust_ar,
					total_co_ar,
					cust_dso,
					co_dso,
					@period_type,
					@start_date_str,	 
					@end_date_str,
					@my_id,
					@all_org_flag,
					@from_org,
					@to_org,
					amt_age_bracket0,
					@str_age_bracket_0
			FROM #age_summary s, armaster c 	
			WHERE s.customer_code = c.customer_code 
			AND address_type = 0
			AND period_number > 0
			ORDER BY workload_code, s.customer_code, period_number 

		DROP TABLE #artrxage_tmp 
		DROP TABLE #age_summary
		DROP TABLE #sales_tmp 
		DROP TABLE #sales_summary
		DROP TABLE #avgdays_tmp 
		DROP TABLE #avgdays_summary
		
	SET NOCOUNT OFF

GO
GRANT EXECUTE ON  [dbo].[cc_calc_statistics_sp] TO [public]
GO
