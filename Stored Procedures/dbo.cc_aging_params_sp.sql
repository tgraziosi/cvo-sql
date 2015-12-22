SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE [dbo].[cc_aging_params_sp] 

AS

SET NOCOUNT ON

	CREATE TABLE #ageparams
	(
		min_cust_code	varchar(8),
		max_cust_code	varchar(8) NULL,
		min_terr_code	varchar(8) NULL,
		max_terr_code	varchar(8) NULL,
		min_cust_name	varchar(40) NULL,
		max_cust_name	varchar(40) NULL,
		min_post_code	varchar(8) NULL,
		max_post_code	varchar(8) NULL,
		min_stat_code	varchar(8) NULL,
		max_stat_code	varchar(8) NULL,
		min_work_code	varchar(8) NULL,
		max_work_code	varchar(8) NULL,
		min_apply_to	varchar(16) NULL,
		max_apply_to	varchar(16) NULL,
		min_gl_acct		varchar(32) NULL,
		max_gl_acct		varchar(32) NULL,
		min_nat_acct	varchar(32) NULL,
		max_nat_acct	varchar(32) NULL,
		min_price_code	varchar(8) NULL,
		max_price_code	varchar(8) NULL,
		min_sales_code	varchar(8) NULL,
		max_sales_code	varchar(8) NULL,
		min_org_id		varchar(30) NULL,
		max_org_id		varchar(30) NULL
	)
	
	INSERT #ageparams (min_cust_code)
		SELECT MIN(customer_code)
		FROM	arcust 
		WHERE	ISNULL(DATALENGTH(LTRIM(RTRIM(customer_code))),0) > 0


	UPDATE 	#ageparams
	SET 	max_cust_code = (SELECT MAX(customer_code)
				 FROM	arcust 
				 WHERE	ISNULL(DATALENGTH(LTRIM(RTRIM(customer_code))),0) > 0	)

	UPDATE 	#ageparams
	SET min_terr_code = 	(SELECT MIN(territory_code)
				 FROM 	arterr
				 WHERE	ISNULL(DATALENGTH(LTRIM(RTRIM(territory_code))),0) > 0 )

	UPDATE 	#ageparams
 	SET max_terr_code = 	(SELECT MAX(territory_code)
				 FROM 	arterr
				 WHERE	ISNULL(DATALENGTH(LTRIM(RTRIM(territory_code))),0) > 0 )	

	UPDATE 	#ageparams
 	SET min_cust_name = 	(SELECT MIN(customer_name)
				 FROM 	arcust
				 WHERE	ISNULL(DATALENGTH(LTRIM(RTRIM(customer_name))),0) > 0 )

	UPDATE 	#ageparams
 	SET max_cust_name = 	(SELECT MAX(customer_name)
				 FROM 	arcust
				 WHERE	ISNULL(DATALENGTH(LTRIM(RTRIM(customer_name))),0) > 0 )

	UPDATE 	#ageparams
	SET min_post_code = 	(SELECT MIN(posting_code)
				 FROM 	araccts
				 WHERE	ISNULL(DATALENGTH(LTRIM(RTRIM(posting_code))),0) > 0 )

	UPDATE 	#ageparams
 	SET max_post_code = 	(SELECT MAX(posting_code)
				 FROM 	araccts
				 WHERE	ISNULL(DATALENGTH(LTRIM(RTRIM(posting_code))),0) > 0 )

	UPDATE 	#ageparams
	SET min_stat_code = 	(SELECT MIN(status_code)
				 FROM 	cc_status_codes
				 WHERE	ISNULL(DATALENGTH(LTRIM(RTRIM(status_code))),0) > 0 )

	UPDATE 	#ageparams
 	SET max_stat_code = 	(SELECT MAX(status_code)
				 FROM 	cc_status_codes
				 WHERE	ISNULL(DATALENGTH(LTRIM(RTRIM(status_code))),0) > 0 )

	UPDATE 	#ageparams
	SET min_work_code = 	(SELECT MIN(workload_code)
				 FROM 	ccwrkhdr
				 WHERE	ISNULL(DATALENGTH(LTRIM(RTRIM(workload_code))),0) > 0 )

	UPDATE 	#ageparams
 	SET max_work_code = 	(SELECT MAX(workload_code)
				 FROM 	ccwrkhdr
				 WHERE	ISNULL(DATALENGTH(LTRIM(RTRIM(workload_code))),0) > 0 )

	UPDATE 	#ageparams
 	SET min_apply_to = 	(SELECT MIN(apply_to_num)
				 FROM 	artrxage
				 WHERE	ISNULL(DATALENGTH(LTRIM(RTRIM(apply_to_num))),0) > 0 )

	UPDATE 	#ageparams
 	SET max_apply_to = 	(SELECT MAX(apply_to_num)
				 FROM 	artrxage
				 WHERE	ISNULL(DATALENGTH(LTRIM(RTRIM(apply_to_num))),0) > 0 )

	UPDATE 	#ageparams
 	SET min_gl_acct = 	(SELECT MIN(account_code)
				 FROM 	glchart
				 WHERE	ISNULL(DATALENGTH(LTRIM(RTRIM(account_code))),0) > 0 )

	UPDATE 	#ageparams
 	SET max_gl_acct = 	(SELECT MAX(account_code)
				 FROM 	glchart
				 WHERE	ISNULL(DATALENGTH(LTRIM(RTRIM(account_code))),0) > 0 )

	UPDATE 	#ageparams
 	SET min_nat_acct = 	(SELECT MIN(parent)
				 FROM 	artierrl
				 WHERE	ISNULL(DATALENGTH(LTRIM(RTRIM(parent))),0) > 0 )
		
	UPDATE 	#ageparams
 	SET max_nat_acct = 	(SELECT MAX(parent)
				 FROM 	artierrl
				 WHERE	ISNULL(DATALENGTH(LTRIM(RTRIM(parent))),0) > 0 )

	UPDATE 	#ageparams
 	SET min_price_code = 	(SELECT MIN(price_code)
				 FROM 	arprice
				 WHERE	ISNULL(DATALENGTH(LTRIM(RTRIM(price_code))),0) > 0 )

	UPDATE 	#ageparams
 	SET max_price_code = 	(SELECT MAX(price_code)
				 FROM 	arprice
				 WHERE	ISNULL(DATALENGTH(LTRIM(RTRIM(price_code))),0) > 0 )
		
	UPDATE 	#ageparams
 	SET min_sales_code = 	(SELECT MIN(salesperson_code)
				 FROM 	arsalesp
				 WHERE	ISNULL(DATALENGTH(LTRIM(RTRIM(salesperson_code))),0) > 0	)

	UPDATE 	#ageparams
 	SET max_sales_code = 	(SELECT MAX(salesperson_code)
				 FROM 	arsalesp
				 WHERE	ISNULL(DATALENGTH(LTRIM(RTRIM(salesperson_code))),0) > 0	)

	UPDATE 	#ageparams
 	SET min_org_id = 	(SELECT MIN(organization_id)
				 FROM 	Organization
				 WHERE	ISNULL(DATALENGTH(LTRIM(RTRIM(organization_id))),0) > 0	)

	UPDATE 	#ageparams
 	SET max_org_id = 	(SELECT MAX(organization_id)
				 FROM 	Organization
				 WHERE	ISNULL(DATALENGTH(LTRIM(RTRIM(organization_id))),0) > 0	)

	SELECT	min_cust_code,
		max_cust_code,
		min_terr_code,
		max_terr_code,
		min_cust_name,
		max_cust_name,
		min_post_code,
		max_post_code,
		min_stat_code,
		max_stat_code,
		min_work_code,
		max_work_code,
		min_apply_to,
		max_apply_to,
		min_gl_acct,
		max_gl_acct,
		min_nat_acct,
		max_nat_acct,
		min_price_code,
		max_price_code,
		min_sales_code,
		max_sales_code,
		min_org_id,
		max_org_id
	FROM	#ageparams

SET NOCOUNT OFF

GO
GRANT EXECUTE ON  [dbo].[cc_aging_params_sp] TO [public]
GO
