SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[amapcom_vwLastRow_sp] 
AS 

DECLARE @MSKtrx_ctrl_num 	smControlNumber, 
		@MSKcompany_id 		smCompanyID 

SELECT 	@MSKcompany_id 		= MAX(company_id) 
FROM 	amapcom_vw 

SELECT 	@MSKtrx_ctrl_num 	= MAX(trx_ctrl_num) 
FROM 	amapcom_vw 
WHERE 	company_id 			= @MSKcompany_id 

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
FROM 	amapcom_vw 
WHERE 	company_id 		= @MSKcompany_id 
AND 	trx_ctrl_num 	= @MSKtrx_ctrl_num 

RETURN @@error 
GO
GRANT EXECUTE ON  [dbo].[amapcom_vwLastRow_sp] TO [public]
GO
