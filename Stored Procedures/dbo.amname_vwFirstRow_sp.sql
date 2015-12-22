SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[amname_vwFirstRow_sp] 
AS 

DECLARE 
	@MSKcompany_id smCompanyID 

SELECT 	@MSKcompany_id = MIN(company_id) 
FROM 	amname_vw 

SELECT 
	timestamp,
	company_id,
	addr1,
	addr2,
	addr3,
	addr4,
	addr5,
	addr6,
	ap_interface,
	post_depreciation,
	post_additions,
	post_disposals,
	post_other_activities,
	last_modified_date = CONVERT(char(8),last_modified_date, 112),
	modified_by 
FROM 	amname_vw 
WHERE 	company_id = @MSKcompany_id 

RETURN 0 
GO
GRANT EXECUTE ON  [dbo].[amname_vwFirstRow_sp] TO [public]
GO
