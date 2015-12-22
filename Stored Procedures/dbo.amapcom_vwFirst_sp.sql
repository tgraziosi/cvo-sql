SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[amapcom_vwFirst_sp]
(
	@rowsrequested smallint = 1
) 
AS

CREATE TABLE #temp 
(
	timestamp 			varbinary(8) 	null,
	company_id 			smallint 		null,
	trx_ctrl_num 		char(16) 		null,
	doc_ctrl_num 		char(16) 		null,
	vendor_code 		varchar(12) 	null,
	apply_date			datetime		null,
	nat_currency_code	varchar(8)		null,
	nat_currency_mask	varchar(100)	null,
	nat_curr_precision	smallint		null,
	amt_net				float			null
)

DECLARE @rowsfound 			smallint
DECLARE @MSKtrx_ctrl_num 	smControlNumber
DECLARE @MSKcompany_id 		smCompanyID

SELECT @rowsfound = 0

SELECT 	@MSKcompany_id = MIN(company_id) 
FROM 	amapcom_vw

IF @MSKcompany_id IS NULL
BEGIN
 DROP TABLE #temp
 RETURN
END

SELECT 	@MSKtrx_ctrl_num = MIN(trx_ctrl_num) 
FROM 	amapcom_vw 
WHERE 	company_id		= @MSKcompany_id

IF @MSKtrx_ctrl_num IS NULL
BEGIN
 DROP TABLE #temp
 RETURN
END

INSERT INTO #temp 
SELECT 	 
		timestamp,
		company_id,
		trx_ctrl_num,
		doc_ctrl_num,
		vendor_code,
		apply_date,
		nat_currency_code,
		nat_currency_mask,
		nat_curr_precision,
		amt_net 
FROM 	amapcom_vw 
WHERE	company_id 		= @MSKcompany_id 
AND		trx_ctrl_num 	= @MSKtrx_ctrl_num

SELECT @rowsfound = @@rowcount

SELECT 	@MSKtrx_ctrl_num 	= MIN(trx_ctrl_num) 
FROM 	amapcom_vw 
WHERE	company_id 			= @MSKcompany_id 
AND		trx_ctrl_num 		> @MSKtrx_ctrl_num

WHILE @MSKtrx_ctrl_num IS NOT NULL AND @rowsfound < @rowsrequested
BEGIN

	INSERT INTO #temp 
	SELECT 	
		timestamp,
		company_id,
		trx_ctrl_num,
		doc_ctrl_num,
		vendor_code,
		apply_date,
		nat_currency_code,
		nat_currency_mask,
		nat_curr_precision,
		amt_net 
	FROM 	amapcom_vw 
	WHERE	company_id 		= @MSKcompany_id 
	AND		trx_ctrl_num 	= @MSKtrx_ctrl_num
		
	SELECT @rowsfound = @rowsfound + @@rowcount
	
	
	SELECT 	@MSKtrx_ctrl_num 	= MIN(trx_ctrl_num) 
	FROM 	amapcom_vw 
	WHERE	company_id 			= @MSKcompany_id 
	AND		trx_ctrl_num 		> @MSKtrx_ctrl_num
	
END

SELECT
	timestamp,
	company_id,
	trx_ctrl_num,
	doc_ctrl_num,
	vendor_code,
	apply_date			= CONVERT(char(8), apply_date, 112),
	nat_currency_code,
	nat_currency_mask,
	nat_curr_precision,
	amt_net
FROM #temp 
ORDER BY company_id, trx_ctrl_num

DROP TABLE #temp

RETURN @@error
GO
GRANT EXECUTE ON  [dbo].[amapcom_vwFirst_sp] TO [public]
GO
