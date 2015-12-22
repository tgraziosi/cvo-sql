SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO




CREATE PROCEDURE [dbo].[cc_query_list_rpt] 
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

	@style	char(1) = 'D',

	@include_pif smallint = 0

	
AS
	SET NOCOUNT ON
	DECLARE @where_clause1	varchar(1000)
	DECLARE @where_clause2	varchar(1000)
	DECLARE @last_cust_code varchar(8)
	DECLARE @balance float
	DECLARE	@ret_code int
	
	CREATE TABLE #invoices 
	(
		doc_ctrl_num	varchar(16) 	NULL,
		status		varchar(5) 	NULL,
		status_date	int 		NULL,
		customer_code	varchar(8) 	NULL,
		customer_name	varchar(40) 	NULL,

		cust_balance		float 		NULL,
		aging_date	int 		NULL,
		territory_code	varchar(8) 	NULL,
		paid_flag	smallint	NULL,

		status_type	smallint NULL,

		inv_balance float NULL,

		trx_type int NULL)

	CREATE TABLE #final_1
	(
		doc_ctrl_num	varchar(16) 	NULL,
		status		varchar(5) 	NULL,
		status_datetime	datetime 	NULL,
		customer_code	varchar(8) 	NULL,
		customer_name	varchar(40) 	NULL,
		cust_balance		float 		NULL,
		aging_datetime	datetime 	NULL,
		territory_code	varchar(8) 	NULL,
		status_type	smallint NULL,
		inv_balance float NULL	)

	CREATE TABLE #final_table
	(
		doc_ctrl_num	varchar(16) 	NULL,
		status		varchar(5) 	NULL,
		status_datetime	datetime 	NULL,
		customer_code	varchar(8) 	NULL,
		customer_name	varchar(40) 	NULL,
		cust_balance		float 		NULL,
		aging_datetime	datetime 	NULL,
		territory_code	varchar(8) 	NULL,
		status_type	smallint NULL,

		inv_balance float NULL	)

	CREATE INDEX #final_1_idx1 ON #final_1 (territory_code, cust_balance )
 	CREATE INDEX #final_1_idx2 ON #final_1 (customer_code, customer_name )


	SELECT @where_clause1 = ' AND 0 = 0 ', @where_clause2 = ' AND 0 = 0 '

	
	IF @all_terr_flag = '0'
		SELECT @where_clause1 = @where_clause1 + ' AND territory_code between "' + @from_terr + '" AND "' + @thru_terr + '" '

	IF 	@all_name_flag = '0'
		SELECT @where_clause1 = @where_clause1 + ' AND customer_name between "' + @from_name + '" AND "' + @thru_name + '" '

	IF @all_cust_flag = '0'
		SELECT @where_clause1 = @where_clause1 + ' AND customer_code between "' + @from_cust + '" AND "' + @thru_cust + '" '

	IF @all_bal_flag = '0'

		SELECT @where_clause1 = @where_clause1 + ' AND cust_balance between ' + @from_balance + ' AND ' + @thru_balance 


	IF @all_status_flag = '0'
		SELECT @where_clause2 = ' AND h.status_code between "' + @from_status + '" AND "' + @thru_status + '" '



	EXEC ( 'INSERT #invoices
		SELECT 	"", 
			h.status_code, 
			date, 
			customer_code,
			NULL,
			0,
			NULL,
	 		NULL,
			NULL,
			1,
			0,
			0
		FROM cc_cust_status_hist h LEFT OUTER JOIN cc_status_codes c ON (h.status_code = c.status_code)
		WHERE clear_date IS NULL '
		+ @where_clause2 )



	EXEC ( 'INSERT #invoices
		SELECT 	doc_ctrl_num, 
			h.status_code, 
			date, 
			NULL,
			NULL,
			0,
			NULL,
	 		NULL,
			NULL,
			2,
			0,
			0
		FROM cc_inv_status_hist h LEFT OUTER JOIN cc_status_codes c ON (h.status_code = c.status_code)
		WHERE clear_date IS NULL '
		+ @where_clause2 )







	DELETE #invoices
	WHERE ISNULL(DATALENGTH(RTRIM(LTRIM(status))),0) = 0



	UPDATE #invoices 
	SET	customer_code = t.customer_code
	FROM #invoices i, artrx t
	WHERE t.doc_ctrl_num = i.doc_ctrl_num
	AND ISNULL(DATALENGTH(LTRIM(RTRIM(i.customer_code))), 0 ) = 0


	UPDATE #invoices 
	SET	trx_type = t.trx_type
	FROM #invoices i, artrx t
	WHERE t.doc_ctrl_num = i.doc_ctrl_num

	CREATE INDEX #invoices_idx1 ON #invoices( doc_ctrl_num )
	CREATE INDEX #invoices_idx2 ON #invoices( customer_code )

	IF ( UPPER( @style ) = 'D' )
		EXEC @ret_code = cc_query_list_d_rpt	@where_clause1,
																					@where_clause2,
																					@include_pif
	ELSE
		EXEC @ret_code = cc_query_list_s_rpt	@where_clause1,
																					@where_clause2,
																					@include_pif



	IF ( @ret_code <> 0 )
		RETURN

	IF @all_workload_flag = '1'
		SELECT 	f.status,
		customer = convert(char(8),f.customer_code) + '   ' + customer_name,			

		'balance' = f.cust_balance,	
		company_name,
		'FromCust' = @from_cust,
		'ThruCust' = @thru_cust,
		'FromTerr' = @from_terr,
		'ThruTerr' = @thru_terr,
		'FromBal' = @from_balance,
		'ThruBal' = @thru_balance,
		'FromWorkload' = @from_workload,
		'ThruWorkload' = @thru_workload,
		'FromStatus' = @from_status,
		'ThruStatus' = @thru_status,
		territory_code,
		f.status_type,

		f.inv_balance,
		aging_datetime,
		status_datetime,
		doc_ctrl_num	 
	FROM #final_table f, arco
	ORDER BY f.status_type, f.cust_balance DESC, f.status
ELSE
	SELECT 	f.status,
		customer = convert(char(8),f.customer_code) + '   ' + f.customer_name,			

		'balance' = f.cust_balance,	
		company_name,
		'FromCust' = @from_cust,
		'ThruCust' = @thru_cust,
		'FromTerr' = @from_terr,
		'ThruTerr' = @thru_terr,
		'FromBal' = @from_balance,
		'ThruBal' = @thru_balance,
		'FromWorkload' = @from_workload,
		'ThruWorkload' = @thru_workload,
		'FromStatus' = @from_status,
		'ThruStatus' = @thru_status,
		f.territory_code,
		f.status_type,

		f.inv_balance,
		aging_datetime,
		status_datetime,
		doc_ctrl_num	 
	FROM #final_table f, arcust c, arco, ccwrkmem m
	WHERE f.customer_code = m.customer_code
	AND workload_code between @from_workload and @thru_workload
	ORDER BY f.status_type, f.cust_balance DESC, f.status

DROP TABLE #invoices
DROP TABLE #final_table
DROP TABLE #final_1

	SET NOCOUNT OFF

GO
GRANT EXECUTE ON  [dbo].[cc_query_list_rpt] TO [public]
GO
