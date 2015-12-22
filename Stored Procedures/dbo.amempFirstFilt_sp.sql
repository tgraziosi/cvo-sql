SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create procedure [dbo].[amempFirstFilt_sp] 
( 
	@rowsrequested smallint = 1,
	@employee_code_filter 	smEmployeeCode 
) 
as 


create table #temp 
( 
	timestamp 		varbinary(8) null,
	employee_code 	char(9) null,
	employee_name 	varchar(40) null,
	job_title 		varchar(40) null 
)
declare @rowsfound smallint 
declare @MSKemployee_code smEmployeeCode 

select @rowsfound = 0 

select 	@MSKemployee_code 	= min(employee_code) 
from 	amemp 
where 	employee_code 		like RTRIM(@employee_code_filter)
 
if @MSKemployee_code is null 
begin 
 drop table #temp 
 return 
end 

insert 	into #temp 
select 	 
		timestamp,
		employee_code,
		employee_name,
		job_title 
from 	amemp 
where 	employee_code = @MSKemployee_code 

select @rowsfound = @@rowcount 

select 	@MSKemployee_code 	= min(employee_code) 
from 	amemp 
where 	employee_code 	> @MSKemployee_code 
and 	employee_code 	like RTRIM(@employee_code_filter)

while @MSKemployee_code is not null and @rowsfound < @rowsrequested 
begin 

	insert 	into #temp 
	select 	 
		timestamp,
		employee_code,
		employee_name,
		job_title 
	from 	amemp 
	where 	employee_code = @MSKemployee_code 

	select @rowsfound = @rowsfound + @@rowcount 

	 
	select 	@MSKemployee_code 	= min(employee_code) 
	from 	amemp 
	where 	employee_code 		> @MSKemployee_code 
 	and 	employee_code 		like RTRIM(@employee_code_filter)
end 

select 
	timestamp,
	employee_code,
	employee_name,
	job_title 
from #temp 
order by employee_code 
drop table #temp 

return @@error 
GO
GRANT EXECUTE ON  [dbo].[amempFirstFilt_sp] TO [public]
GO
