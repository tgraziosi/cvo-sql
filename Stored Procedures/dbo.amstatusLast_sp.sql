SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create procedure [dbo].[amstatusLast_sp] 
( 
	@rowsrequested smallint = 1 
) as 


create table #temp ( 
	timestamp varbinary(8) null,
	status_code char(8) null,
	status_description varchar(40) null,
	activity_state tinyint null 
)
declare @rowsfound smallint 
select @rowsfound = 0 
declare @MSKstatus_code smStatusCode 

select @MSKstatus_code = max(status_code) from amstatus 
if @MSKstatus_code is null 
begin 
 drop table #temp 
 return 
end 

insert into #temp 
select 
		timestamp,
	 status_code,
		status_description,
		activity_state 
from amstatus 
where 
		status_code = @MSKstatus_code 

select @rowsfound = @@rowcount 

select @MSKstatus_code = max(status_code) from amstatus where 
	status_code < @MSKstatus_code 
while @MSKstatus_code is not null and @rowsfound < @rowsrequested 
begin 

	insert into #temp 
	select 
		timestamp,
	 status_code,
		status_description,
		activity_state 
	from amstatus 
	where 
		status_code = @MSKstatus_code 

		select @rowsfound = @rowsfound + @@rowcount 
	 
	select @MSKstatus_code = max(status_code) from amstatus where 
	status_code < @MSKstatus_code 
end 
select 
	timestamp,
	status_code,
	status_description,
	activity_state 
from #temp order by status_code 
drop table #temp 

return @@error 
GO
GRANT EXECUTE ON  [dbo].[amstatusLast_sp] TO [public]
GO
