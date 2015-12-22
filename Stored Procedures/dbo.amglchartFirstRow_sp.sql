SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create procedure [dbo].[amglchartFirstRow_sp] 
as 


declare @MSKaccount_code varchar(32 )

select @MSKaccount_code = min(account_code) 
from 	glchart 

select 
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
from 	glchart 
where 	account_code = @MSKaccount_code 

return 0
GO
GRANT EXECUTE ON  [dbo].[amglchartFirstRow_sp] TO [public]
GO
