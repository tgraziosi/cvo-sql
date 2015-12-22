SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO




CREATE PROCEDURE [dbo].[cc_query_list_s_rpt] 
	@from_cust		varchar(8) = '',
	@thru_cust		varchar(8) = '',	
	@from_terr		varchar(8) = '',
	@thru_terr		varchar(8) = '',	
	@from_balance		varchar(20) = '',
	@thru_balance		varchar(20) = '',	
	@from_name		varchar(40) = '',
	@thru_name		varchar(40) = '',
	@from_workload		varchar(8) = '',
	@thru_workload		varchar(8) = '',
	@from_status		varchar(8) = '',
	@thru_status		varchar(8) = '',


	@all_cust_flag		varchar(8) = '1',
	@all_terr_flag		varchar(8) = '1',
	@all_bal_flag		varchar(8) = '1',
	@all_name_flag		varchar(8) = '1',
	@all_workload_flag	varchar(8) = '1',
	@all_status_flag	varchar(8) = '1',
	@all_org_flag			varchar(8) = '0',
	@from_org varchar(30) = '',
	@to_org varchar(30) = '',
	@user_name	varchar(30) = '',
	@company_db	varchar(30) = ''
 	

AS
	SET NOCOUNT ON
	IF EXISTS (SELECT name FROM sysobjects WHERE name = 'sm_login_sp' ) EXEC sm_login_sp @user_name, @company_db
	

	SET NOCOUNT ON
	DECLARE @where_clause1	varchar(1000)
	DECLARE @where_clause2	varchar(1000)
	DECLARE @last_cust_code varchar(8)
	DECLARE @balance float
	DECLARE	@company	varchar(30)

	SELECT @company = company_name FROM arco

	CREATE TABLE #invoices 
	(
		doc_ctrl_num	varchar(16) 	NULL,
		status		varchar(5) 	NULL,
		status_date	int 		NULL,
		customer_code	varchar(8) 	NULL,
		customer_name	varchar(40) 	NULL,
		balance		float 		NULL,
		aging_date	int 		NULL,
		territory_code	varchar(8) 	NULL,
		paid_flag	smallint	NULL,

		status_type	smallint NULL,
		org_id	varchar(30) NULL
	)


	SELECT @where_clause1 = ' AND 0 = 0 ', @where_clause2 = ' AND 0 = 0 '

	
	IF @all_terr_flag = '0'
		SELECT @where_clause1 = @where_clause1 + ' AND territory_code between "' + @from_terr + '" AND "' + @thru_terr + '" '

	IF 	@all_name_flag = '0'
		SELECT @where_clause1 = @where_clause1 + ' AND customer_name between "' + @from_name + '" AND "' + @thru_name  + '" '

	IF @all_cust_flag = '0'
		SELECT @where_clause1 = @where_clause1 + ' AND customer_code between "' + @from_cust + '" AND "'  + @thru_cust  + '" '

	IF @all_bal_flag = '0'
		SELECT @where_clause1 = @where_clause1 + ' AND balance between ' + @from_balance + ' AND ' + @thru_balance  


	IF @all_status_flag = '0'
		SELECT @where_clause2 = ' AND h.status_code between "' + @from_status  + '" AND "' + @thru_status + '" '



	EXEC ( 'INSERT #invoices
		SELECT 	"", 
			h.status_code, 
			date, 
			customer_code,
			NULL,
			NULL,
			NULL,
	 		NULL,
			NULL,
			1,
			NULL
		FROM cc_cust_status_hist h LEFT OUTER JOIN cc_status_codes c ON (h.status_code = c.status_code)
		WHERE clear_date IS NULL '
		+ @where_clause2 )

	DELETE #invoices
	WHERE ISNULL(DATALENGTH(RTRIM(LTRIM(status))),0) = 0

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



	EXEC ( 'INSERT #invoices
		SELECT 	doc_ctrl_num, 
			h.status_code, 
			date, 
			NULL,
			NULL,
			NULL,
			NULL,
	 		NULL,
			NULL,
			2,
			NULL
		FROM cc_inv_status_hist h LEFT OUTER JOIN cc_status_codes c ON (h.status_code = c.status_code)
		WHERE clear_date IS NULL '
		+ @where_clause2 )


DELETE #invoices
WHERE ISNULL(DATALENGTH(RTRIM(LTRIM(status))),0) = 0



	UPDATE #invoices 
	SET	customer_code = t.customer_code,
			balance = amt_net - amt_paid_to_date,
			aging_date = date_aging,
			paid_flag = t.paid_flag,
			org_id = t.org_id
	FROM #invoices i, artrx t
	WHERE t.doc_ctrl_num = i.doc_ctrl_num

	AND status_type = 2
		
	UPDATE #invoices 
	SET	customer_name = c.customer_name,
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
		customer_code	varchar(8) 	NULL,
		status_type	smallint NULL,
		status		varchar(5) 	NULL,
		customer_name	varchar(40) 	NULL,
		territory_code	varchar(8) 	NULL,
		balance		float 		NULL		
	)


	EXEC ('	INSERT #final_table
				SELECT 	customer_code,
							1,
							status,
							customer_name,
							territory_code,
							balance
				FROM #invoices i
				WHERE i.status_type = 1 ' + @where_clause1
		 + ' 	GROUP BY customer_code,	customer_name, territory_code, status, balance')

	EXEC ('	INSERT #final_table
				SELECT 	customer_code,
							2,
							status,
							customer_name,
							territory_code,
							sum(balance)		
				FROM #invoices i
				WHERE i.status_type = 2 ' + @where_clause1
		 + ' 	GROUP BY customer_code,	customer_name, territory_code, status')

IF @all_workload_flag = '1'
	SELECT 	f.status,
		customer = convert(char(8),f.customer_code) + '   ' + customer_name,			
		f.balance,	
		'company_name' = @company,
		'FromCust' = @from_cust,
		'ThruCust' = @thru_cust,
		'FromTerr' = @from_terr,
		'ThruTerr' = @thru_terr,
		'FromBal'  = @from_balance,
		'ThruBal'  = @thru_balance,
		'FromWorkload' = @from_workload,
		'ThruWorkload' = @thru_workload,
		'FromStatus' = @from_status,
		'ThruStatus' = @thru_status,
		territory_code,
		f.status_type,
			'all_org_flag' = @all_org_flag,
			'from_org' = @from_org,
			'to_org' = @to_org
	FROM #final_table f
	ORDER BY f.status_type, f.balance DESC, f.status
ELSE
	SELECT 	f.status,
		customer = convert(char(8),f.customer_code) + '   ' + customer_name,			
		f.balance,	
		'company_name' = @company,
		'FromCust' = @from_cust,
		'ThruCust' = @thru_cust,
		'FromTerr' = @from_terr,
		'ThruTerr' = @thru_terr,
		'FromBal'  = @from_balance,
		'ThruBal'  = @thru_balance,
		'FromWorkload' = @from_workload,
		'ThruWorkload' = @thru_workload,
		'FromStatus' = @from_status,
		'ThruStatus' = @thru_status,
		territory_code,
		f.status_type,
			'all_org_flag' = @all_org_flag,
			'from_org' = @from_org,
			'to_org' = @to_org
	FROM #final_table f, ccwrkmem m
	WHERE f.customer_code = m.customer_code
	AND workload_code between @from_workload and @thru_workload
	ORDER BY f.status_type, f.balance DESC, f.status

DROP TABLE #invoices
DROP TABLE #final_table

	SET NOCOUNT OFF

GO
GRANT EXECUTE ON  [dbo].[cc_query_list_s_rpt] TO [public]
GO
