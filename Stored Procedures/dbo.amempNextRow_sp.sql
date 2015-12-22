SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create procedure [dbo].[amempNextRow_sp] 
( 
	@employee_code 	smEmployeeCode 
) as 


declare @MSKemployee_code smEmployeeCode 
select @MSKemployee_code = @employee_code 
select @MSKemployee_code = min(employee_code) from amemp where 
	employee_code > @MSKemployee_code 
select 
	timestamp,
	employee_code,
	employee_name,
	job_title 
from amemp where 
		employee_code = @MSKemployee_code 

return @@error 
GO
GRANT EXECUTE ON  [dbo].[amempNextRow_sp] TO [public]
GO
