SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create procedure [dbo].[amempExists_sp] 
( 
	@employee_code 	smEmployeeCode, 
	@valid int output 
) as 


if exists (select 1 from amemp where 
	employee_code 	= @employee_code 
)
 select @valid = 1 
else 
 select @valid = 0 
return @@error 
GO
GRANT EXECUTE ON  [dbo].[amempExists_sp] TO [public]
GO
