SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[amaphdr_vwLastFilt_sp]
(
	@rowsrequested                  smallint = 1,
	@company_id_filter           	smCompanyID,
	@trx_ctrl_num_filter         	smControlNumber
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
	amt_net				float			null,
	org_id			varchar(30)	null
)

DECLARE @rowsfound 			smallint
DECLARE @MSKtrx_ctrl_num 	smControlNumber

SELECT @rowsfound = 0

SELECT 	@MSKtrx_ctrl_num 	= MAX(trx_ctrl_num) 
FROM 	amaphdr_vw 
WHERE 	trx_ctrl_num 		LIKE RTRIM(@trx_ctrl_num_filter)
AND 	company_id 			= @company_id_filter

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
		amt_net,
		org_id  
FROM 	amaphdr_vw 
WHERE	company_id 		= @company_id_filter 
AND		trx_ctrl_num 	= @MSKtrx_ctrl_num

SELECT @rowsfound = @@rowcount

SELECT 	@MSKtrx_ctrl_num 	= MAX(trx_ctrl_num) 
FROM 	amaphdr_vw 
WHERE	company_id 			= @company_id_filter 
AND		trx_ctrl_num 		< @MSKtrx_ctrl_num
AND 	trx_ctrl_num 		LIKE RTRIM(@trx_ctrl_num_filter)

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
		amt_net,
		org_id 
	FROM 	amaphdr_vw 
	WHERE	company_id 		= @company_id_filter 
	AND		trx_ctrl_num 	= @MSKtrx_ctrl_num

	SELECT @rowsfound = @rowsfound + @@rowcount
	
	
	SELECT 	@MSKtrx_ctrl_num 	= MAX(trx_ctrl_num) 
	FROM 	amaphdr_vw 
	WHERE	company_id 			= @company_id_filter 
	AND		trx_ctrl_num 		< @MSKtrx_ctrl_num
	AND 	trx_ctrl_num 		LIKE RTRIM(@trx_ctrl_num_filter)
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
	amt_net,
	org_id
FROM #temp
ORDER BY  company_id, trx_ctrl_num

DROP TABLE #temp

RETURN @@error
GO
GRANT EXECUTE ON  [dbo].[amaphdr_vwLastFilt_sp] TO [public]
GO
