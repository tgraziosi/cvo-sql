SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

 
CREATE PROCEDURE [dbo].[amtrxrda_vwFirstRow_sp]
AS
 
DECLARE	@MSKtrx_ctrl_num	smControlNumber
DECLARE	@MSKcompany_id	smCompanyID
 
 
 
SELECT	@MSKcompany_id	= MIN(company_id)
FROM	amtrxrda_vw
 
SELECT	@MSKtrx_ctrl_num	= MIN(trx_ctrl_num)
FROM	amtrxrda_vw
WHERE	company_id	= @MSKcompany_id
 
SELECT
	timestamp,
	company_id,
	trx_ctrl_num,
	co_trx_id,
	trx_type,
	last_modified_date = convert(char(8),last_modified_date, 112),
	modified_by,
	apply_date = convert(char(8),apply_date, 112),
	from_code,
	to_code,
	group_code,
	from_org_id,				
	to_org_id					
FROM	amtrxrda_vw
WHERE	company_id	= @MSKcompany_id
AND	trx_ctrl_num	= @MSKtrx_ctrl_num
 
RETURN 0
GO
GRANT EXECUTE ON  [dbo].[amtrxrda_vwFirstRow_sp] TO [public]
GO
