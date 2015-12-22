SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create procedure [dbo].[amstatusFirstFilt_sp] 
( 
	@rowsrequested smallint = 1,
	@status_code_filter 	smStatusCode 
) as 


create table #temp 
( 
	timestamp 			varbinary(8) null,
	status_code 		char(8) null,
	status_description 	varchar(40) null,
	activity_state 	tinyint null 
)
declare @rowsfound 		smallint 
declare @MSKstatus_code smStatusCode 

select @rowsfound = 0 

select 	@MSKstatus_code 	= min(status_code) 
from 	amstatus 
where	 status_code 		like RTRIM(@status_code_filter)
if @MSKstatus_code is null 
begin 
 drop table #temp 
 return 
end 

insert 	into #temp 
select 	 
		timestamp,
	 status_code,
		status_description,
		activity_state 
from 	amstatus 
where 	status_code = @MSKstatus_code 

select @rowsfound = @@rowcount 

select 	@MSKstatus_code 	= min(status_code) 
from 	amstatus 
where 	status_code 		> @MSKstatus_code 
and 	status_code 		like RTRIM(@status_code_filter)

while @MSKstatus_code is not null and @rowsfound < @rowsrequested 
begin 

	insert 	into #temp 
	select 	 
		timestamp,
	 status_code,
		status_description,
		activity_state 
	from 	amstatus 
	where 	status_code = @MSKstatus_code 

	select @rowsfound = @rowsfound + @@rowcount 
	
	 
	select 	@MSKstatus_code 	= min(status_code) 
	from 	amstatus 
	where 	status_code 		> @MSKstatus_code 
 	and 	status_code 		like RTRIM(@status_code_filter)
end 
select 
	timestamp,
	status_code,
	status_description,
	activity_state 
from #temp 
order by status_code 
drop table #temp 

return @@error 
GO
GRANT EXECUTE ON  [dbo].[amstatusFirstFilt_sp] TO [public]
GO
