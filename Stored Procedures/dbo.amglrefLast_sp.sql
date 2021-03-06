SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create procedure [dbo].[amglrefLast_sp]
(
	@rowsrequested smallint = 1
) as


create table #temp 
(
	timestamp 		varbinary(8) null,
	reference_code 	varchar(32) null,
	description 	varchar(40) null,
	reference_type 	varchar(8) null,
	status_flag 	smallint null
)
declare @rowsfound smallint
select @rowsfound = 0
declare @MSKreference_code varchar(32 )

select @MSKreference_code = max(reference_code) 
from 	glref
WHERE	status_flag			= 0

if @MSKreference_code is null
begin
 drop table #temp
 return
end

insert into #temp 
select 
		timestamp,
		reference_code,
		description,
		reference_type,
		status_flag 
from 	glref 
where	reference_code = @MSKreference_code
AND		status_flag			= 0

select @rowsfound = @@rowcount

select @MSKreference_code = max(reference_code) from glref where
	reference_code < @MSKreference_code
while @MSKreference_code is not null and @rowsfound < @rowsrequested
begin

	insert into #temp 
	select 
			timestamp,
			reference_code,
			description,
			reference_type,
			status_flag
	from 	glref 
	where	reference_code = @MSKreference_code
	AND		status_flag			= 0

	select @rowsfound = @rowsfound + @@rowcount
	
	
	select @MSKreference_code = max(reference_code) 
	from 	glref 
	where	reference_code < @MSKreference_code
	AND		status_flag			= 0

end

select
	timestamp,
	reference_code,
	description,
	reference_type,
	status_flag
from #temp order by reference_code
drop table #temp

return @@error
GO
GRANT EXECUTE ON  [dbo].[amglrefLast_sp] TO [public]
GO
