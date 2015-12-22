SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create procedure [dbo].[amempNext_sp] 
( 
	@rowsrequested smallint = 1,
	@employee_code 	smEmployeeCode 
) as 


create table #temp ( 
	timestamp varbinary(8) null,
	employee_code char(9) null,
	employee_name varchar(40) null,
	job_title varchar(40) null 
)
declare @rowsfound smallint 
select @rowsfound = 0 
declare @MSKemployee_code smEmployeeCode 
select @MSKemployee_code = @employee_code 
select @MSKemployee_code = min(employee_code) from amemp where 
	employee_code > @MSKemployee_code 
while @MSKemployee_code is not null and @rowsfound < @rowsrequested 
begin 

	insert into #temp 
	select 
		timestamp,
		employee_code,
		employee_name,
		job_title 
	from amemp 
	where 
		employee_code = @MSKemployee_code 

		select @rowsfound = @rowsfound + @@rowcount 
	 
	select @MSKemployee_code = min(employee_code) from amemp where 
	employee_code > @MSKemployee_code 
end 
select 
	timestamp,
	employee_code,
	employee_name,
	job_title 
from #temp order by employee_code 
drop table #temp 

return @@error 
GO
GRANT EXECUTE ON  [dbo].[amempNext_sp] TO [public]
GO
