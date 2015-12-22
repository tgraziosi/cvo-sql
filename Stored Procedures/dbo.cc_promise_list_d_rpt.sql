SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO




CREATE PROCEDURE [dbo].[cc_promise_list_d_rpt] 
	@from_cust		varchar(8) 	= '',
	@thru_cust		varchar(8) 	= '',	
	@from_terr		varchar(8) 	= '',
	@thru_terr		varchar(8) 	= '',		
	@from_name		varchar(40) 	= '',
	@thru_name		varchar(40) 	= '',	
	@period			int 		= 0,
	@from_workload		varchar(8) 	= '',
	@thru_workload		varchar(8) 	= '',
	@all_cust		varchar(3) 	= '1',
	@all_terr		varchar(3) 	= '1',
	@all_name		varchar(3) 	= '1',
	@all_workload		varchar(3) 	= '1',
	@all_org_flag			varchar(3) = '0',	 
	@from_org varchar(30) = '',
	@to_org varchar(30) = ''

	
AS
	SET NOCOUNT ON
	DECLARE @where_clause1	varchar(255)
	DECLARE @where_clause2	varchar(255)

	DECLARE @last_cust_code varchar(8)
	DECLARE @balance float

	IF @period = 0 
		SELECT @period = datediff(dd, "1/1/1753", convert(datetime, getdate())) + 639906

	CREATE table #invoices 
	(
		doc_ctrl_num	varchar(16)	NULL,
		status_date	int 		NULL,
		customer_code	varchar(8) 	NULL,
		customer_name	varchar(40) 	NULL,

		customer	varchar(60) 	NULL,
		balance		float 		NULL,
		territory_code	varchar(8) 	NULL,
		paid_flag	smallint	NULL,

		status_type	smallint NULL,
		org_id	varchar(30) NULL
	)

	CREATE table #age 
	(
		lowdate 	int	NULL,
		hidate 		int	NULL,
		period_1	int	NULL,
		period_2 	int	NULL,
		period_3 	int	NULL,

		future		int	NULL,
		prior_p		int	NULL
	)

	SET rowcount 1


	INSERT into #age 
		SELECT max(period_start_date), max(period_end_date),1,0,0,0,0
		FROM glprd
		WHERE period_end_date <= @period		

	INSERT into #age 
		SELECT max(period_start_date), max(period_end_date),0,1,0,0,0
		FROM glprd
		WHERE period_end_date < (SELECT lowdate FROM #age WHERE period_1 = 1)		

	INSERT into #age 
		SELECT max(period_start_date),max(period_end_date),0,0,1,0,0 
		FROM glprd
		WHERE period_end_date < (SELECT lowdate FROM #age WHERE period_2 = 1)


	INSERT into #age 
		SELECT MIN(period_start_date), MAX(period_end_date),0,0,0,1,0 
		FROM glprd
		WHERE period_end_date > @period		

	INSERT into #age 
		SELECT MIN(period_start_date), MAX(period_end_date),0,0,0,0,1 
		FROM glprd
		WHERE period_end_date < (SELECT lowdate FROM #age WHERE period_3 = 1)	

	SET rowcount 0



	SELECT @where_clause1 = ' AND 0 = 0 ', @where_clause2 = ' AND 0 = 0 '

	IF @all_terr = '0'
		SELECT @where_clause1 = @where_clause1 + ' AND territory_code between "' + @from_terr + '" AND "' + @thru_terr + '" '

	IF @all_name = '0'
		SELECT @where_clause1 = @where_clause1 + ' AND customer_name between "' + @from_name + '" AND "' + @thru_name + '" '

	IF @all_cust = '0'
		SELECT @where_clause2 = ' AND customer_code between "' + @from_cust + '" AND "' + @thru_cust + '" '



	INSERT #invoices
	SELECT 	'', 
				[date], 
				customer_code,
				NULL,
				NULL,
				NULL,
		 		NULL,
		 		NULL,
				1,
				NULL
	FROM cc_cust_status_hist
	WHERE UPPER(status_code) = 'P'
	AND clear_date IS NULL

	SELECT @last_cust_code = MIN(customer_code) FROM #invoices
	WHILE @last_cust_code IS NOT NULL
		BEGIN
			SELECT 	@balance = 	SUM(amount) 
			FROM 	artrxage
			WHERE 	customer_code = @last_cust_code

			UPDATE #invoices 
			SET	balance = @balance
			WHERE customer_code = @last_cust_code
				
			UPDATE #invoices 
			SET	customer_name = c.customer_name,
					territory_code = c.territory_code
			FROM #invoices i,arcust c
			WHERE c.customer_code = i.customer_code

			SELECT @last_cust_code = MIN(customer_code) 
			FROM #invoices
			WHERE customer_code > @last_cust_code
		END


	INSERT #invoices
	SELECT 	doc_ctrl_num, 
				[date],
				NULL,
				NULL,
				NULL,
				NULL,
				NULL,
		 		NULL,
				2,
				NULL
	FROM cc_inv_status_hist
	WHERE UPPER(status_code) = 'P'
	AND clear_date IS NULL
	


	UPDATE #invoices 
	SET 	customer_code = t.customer_code,
			balance = amt_net - amt_paid_to_date,
			paid_flag = t.paid_flag,
			org_id = t.org_id
	FROM #invoices i, artrx t
	WHERE t.doc_ctrl_num = i.doc_ctrl_num

	AND status_type = 2
		

	UPDATE #invoices 
	SET 	customer_name = c.customer_name,
			territory_code = c.territory_code
	FROM #invoices i,arcust c
	WHERE c.customer_code = i.customer_code

	UPDATE #invoices 
	SET 	customer = convert(char(8),customer_code) + '   ' + customer_name


DELETE #invoices
WHERE paid_flag = 1

IF @all_org_flag = '0'
	DELETE #invoices
	WHERE	org_id NOT BETWEEN @from_org AND @to_org


	CREATE TABLE #final_table
	(
		customer	varchar(52)	NULL,
		period_1	float	NULL,
		period_2	float	NULL,
		period_3	float	NULL,
		date_1		datetime 	NULL,
		date_2		datetime 	NULL,
		date_3		datetime 	NULL,
		customer_code	varchar(8) 	NULL,

		status_type	smallint NULL,
		future_due	float NULL,
		prior_due	float NULL

	)


	EXEC ('	INSERT #final_table 
				(	customer, 
					period_1, 
					period_2, 
					period_3, 
					customer_code,
					status_type,
					future_due,
					prior_due )
				SELECT	customer,
							SUM(balance * period_1),
							SUM(balance * period_2),
							SUM(balance * period_3),
							customer_code,
							1,
							SUM(balance * future),
							SUM(balance * prior_p)
				FROM #invoices, #age 
				WHERE status_type = 1 ' + @where_clause1 + ' ' + @where_clause2
		 + ' AND status_date <= hidate AND status_date >= lowdate  
		 GROUP BY customer_code, customer 
				ORDER BY customer ')

	EXEC ('	INSERT #final_table 
				(	customer, 
					period_1, 
					period_2, 
					period_3, 
					customer_code,
					status_type,
					future_due,
					prior_due )
				SELECT	customer,
							SUM(balance * period_1),
							SUM(balance * period_2),
							SUM(balance * period_3),
							customer_code,
							2,
							SUM(balance * future),
							SUM(balance * prior_p)
				FROM #invoices, #age 
				WHERE status_type = 2 ' + @where_clause1 + ' ' + @where_clause2
		 + ' AND status_date <= hidate AND status_date >= lowdate  
		 GROUP BY customer_code, customer 
				ORDER BY customer ')

	UPDATE #final_table
	SET 	date_1 = (SELECT convert(datetime, dateadd(dd, hidate - 639906, '1/1/1753'))
						 FROM #age WHERE period_1 = 1 ),
			date_2 = (SELECT convert(datetime, dateadd(dd, hidate - 639906, '1/1/1753'))
						 FROM #age WHERE period_2 = 1 ),
			date_3 = (SELECT convert(datetime, dateadd(dd, hidate - 639906, '1/1/1753'))
						 FROM #age WHERE period_3 = 1 )

IF @all_workload = '1'
	SELECT 	customer, 
		period_1, 
		period_2,
		period_3,
		date_1,
		date_2,
		date_3, 
		company_name,
		'FromCust' = @from_cust,
		'ThruCust' = @thru_cust,
		'FromTerr' = @from_terr,
		'ThruTerr' = @thru_terr,
		'FromName' = @from_name,
		'ThruName' = @thru_name,
		'FromWorkload' = @from_workload,
	 	'ThruWorkload' = @thru_workload,
		status_type,
		future_due,
		prior_due,
		'all_org_flag' = @all_org_flag,
		'from_org' = @from_org,
		'to_org' = @to_org
	FROM #final_table f, arco
	ORDER BY status_type
ELSE
	SELECT 	customer, 
		period_1, 
		period_2,
		period_3,
		date_1,
		date_2,
		date_3, 
		company_name,
		'FromCust' = @from_cust,
		'ThruCust' = @thru_cust,
		'FromTerr' = @from_terr,
		'ThruTerr' = @thru_terr,
		'FromName' = @from_name,
		'ThruName' = @thru_name,
		'FromWorkload' = @from_workload,
	 	'ThruWorkload' = @thru_workload,
		status_type,
		future_due,
		prior_due,
		'all_org_flag' = @all_org_flag,
		'from_org' = @from_org,
		'to_org' = @to_org
	FROM #final_table f, arco, ccwrkmem m
	WHERE f.customer_code = m.customer_code
	AND workload_code between @from_workload and @thru_workload
	ORDER BY status_type

DROP TABLE #invoices
DROP TABLE #final_table
DROP TABLE #age
SET NOCOUNT OFF
GO
GRANT EXECUTE ON  [dbo].[cc_promise_list_d_rpt] TO [public]
GO
