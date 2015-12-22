SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create procedure [dbo].[amempInsert_sp] 
( 
	@employee_code 	smEmployeeCode, 
	@employee_name 	smStdDescription, 
	@job_title 	smStdDescription 
) as 

declare @error int 

insert into amemp 
( 
	employee_code,
	employee_name,
	job_title 
)
values 
( 
	@employee_code,
	@employee_name,
	@job_title 
)
return @@error 
GO
GRANT EXECUTE ON  [dbo].[amempInsert_sp] TO [public]
GO
