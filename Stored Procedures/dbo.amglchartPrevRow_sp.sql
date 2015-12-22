SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[amglchartPrevRow_sp] 
( 
	@account_code	varchar(32 )
) 
AS 

DECLARE @MSKaccount_code varchar(32 )

SELECT 	@MSKaccount_code 	= @account_code 

SELECT 	@MSKaccount_code 	= MAX(account_code) 
FROM 	glchart 
WHERE 	account_code 		< @MSKaccount_code 

SELECT 
	timestamp,
	account_code,
	account_description,
	account_type,
	new_flag,
	seg1_code,
	seg2_code,
	seg3_code,
	seg4_code,
	consol_detail_flag,
	consol_type,
	active_date,
	inactive_date,
	inactive_flag,
	currency_code,
	revaluate_flag 
FROM 	glchart 
WHERE 	account_code = @MSKaccount_code 

RETURN 0 
GO
GRANT EXECUTE ON  [dbo].[amglchartPrevRow_sp] TO [public]
GO
