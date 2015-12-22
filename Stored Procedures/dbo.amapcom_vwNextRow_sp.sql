SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[amapcom_vwNextRow_sp]
(
	@company_id 	smCompanyID,
	@trx_ctrl_num 	smControlNumber
) 
AS

DECLARE 
	@MSKtrx_ctrl_num smControlNumber

SELECT @MSKtrx_ctrl_num 	= @trx_ctrl_num

SELECT 	@MSKtrx_ctrl_num 	= MIN(trx_ctrl_num) 
FROM 	amapcom_vw 
WHERE	company_id 			= @company_id 
AND		trx_ctrl_num 		> @MSKtrx_ctrl_num

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
WHERE	company_id 		= @company_id 
AND		trx_ctrl_num 	= @MSKtrx_ctrl_num

RETURN @@error
GO
GRANT EXECUTE ON  [dbo].[amapcom_vwNextRow_sp] TO [public]
GO
