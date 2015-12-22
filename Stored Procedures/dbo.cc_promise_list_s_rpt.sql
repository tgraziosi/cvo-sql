SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO




CREATE PROCEDURE [dbo].[cc_promise_list_s_rpt] 
	@from_cust		varchar(8) 	= '',
	@thru_cust		varchar(8) 	= '',	
	@from_terr		varchar(8) 	= '',
	@thru_terr		varchar(8) 	= '',		
	@from_name		varchar(40)	= '',
	@thru_name		varchar(40) 	= '',
	@period		 int 		= 0,
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
	DECLARE @period_start_str 	varchar(10)
	DECLARE @period_end_str	varchar(10)

	DECLARE @last_cust_code varchar(8)
	DECLARE @balance float

	IF @period = 0 
		SELECT @period = datediff(dd, "1/1/1753", convert(datetime, getdate())) + 639906

	SELECT 	@period_start_str = CONVERT(varchar(10), period_start_date),
		@period_end_str = CONVERT(varchar(10), @period)
	FROM glprd 
	WHERE period_end_date = @period


	CREATE TABLE #invoices 
	(
		doc_ctrl_num	varchar(16)	NULL,
		status_date	int 		NULL,
		customer_code	varchar(8) 	NULL,
		customer_name	varchar(40) 	NULL,
		balance		float 		NULL,
		territory_code	varchar(8) 	NULL,
		paid_flag	smallint	NULL,

		status_type	smallint NULL,
		org_id	varchar(30) NULL
	)


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


	DELETE #invoices
	WHERE paid_flag = 1

IF @all_org_flag = '0'
	DELETE #invoices
	WHERE	org_id NOT BETWEEN @from_org AND @to_org

	CREATE TABLE #final_table
	(
		status_date	datetime,
		total		float,
		per_end_date	datetime NULL,
		customer_code	varchar(8) 	NULL,
		status_type	smallint NULL,
		future_due	float NULL
	)

	EXEC ('	INSERT #final_table (status_date, total, customer_code, status_type)
				SELECT 	CONVERT(datetime,DATEADD(dd, status_date - 639906, "01/01/1753")),
							balance,
							customer_code,
							1
				FROM #invoices
				WHERE status_type = 1 ' + @where_clause1 + ' ' + @where_clause2
		 + ' 	GROUP BY status_date, customer_code, balance 
				ORDER BY status_date' )


	EXEC ('	INSERT #final_table (status_date, total, customer_code, status_type)
				SELECT 	CONVERT(datetime,DATEADD(dd, status_date - 639906, "01/01/1753")),
							SUM(balance),
							customer_code,
							2
				FROM #invoices
				WHERE status_type = 2 ' + @where_clause1 + ' ' + @where_clause2

		 + ' 	GROUP BY status_date, customer_code 
				ORDER BY status_date' )

	SELECT @last_cust_code = MIN(customer_code) FROM #invoices
	WHILE	@last_cust_code IS NOT NULL
		BEGIN
			SELECT @balance = ISNULL(SUM(balance),0)
			FROM	#invoices
			WHERE status_date > @period_end_str 
			AND status_type = 2
			AND customer_code = @last_cust_code

			UPDATE #final_table
			SET	future_due = @balance
			WHERE status_type = 2
			AND customer_code = @last_cust_code

			SELECT @last_cust_code = MIN(customer_code) 
			FROM #invoices
			WHERE customer_code > @last_cust_code
		END


	UPDATE #final_table
	SET per_end_date = (SELECT convert(datetime, dateadd(dd, @period - 639906, '1/1/1753')))

IF @all_workload = '1'
	SELECT 	status_date, 
		total, 
		per_end_date,
		company_name,
		'FromCust' = @from_cust,
		'ThruCust' = @thru_cust,
		'FromTerr' = @from_terr,
		'ThruTerr' = @thru_terr,
		'FromWorkload' = @from_workload,
	 	'ThruWorkload' = @thru_workload,
		status_type,
		future_due,
		'all_org_flag' = @all_org_flag,
		'from_org' = @from_org,
		'to_org' = @to_org
	FROM #final_table, arco 
	ORDER BY status_date			
ELSE
	SELECT 	status_date, 
		total, 
		per_end_date, 
		company_name,
		'FromCust' = @from_cust,
		'ThruCust' = @thru_cust,
		'FromTerr' = @from_terr,
		'ThruTerr' = @thru_terr,
		'FromWorkload' = @from_workload,
	 	'ThruWorkload' = @thru_workload,
		status_type,
		future_due,
		'all_org_flag' = @all_org_flag,
		'from_org' = @from_org,
		'to_org' = @to_org
	FROM #final_table f, arco, ccwrkmem m
	WHERE f.customer_code = m.customer_code
	AND workload_code between @from_workload and @thru_workload
	ORDER BY status_date















DROP TABLE #invoices
DROP TABLE #final_table

SET NOCOUNT OFF
GO
GRANT EXECUTE ON  [dbo].[cc_promise_list_s_rpt] TO [public]
GO
