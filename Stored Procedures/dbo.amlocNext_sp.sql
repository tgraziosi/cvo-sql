SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create procedure [dbo].[amlocNext_sp] 
( 
	@rowsrequested smallint = 1,
	@location_code 	smLocationCode 
) as 


create table #temp ( 
	timestamp varbinary(8) null,
	location_code char(8) null,
	location_description varchar(40) null 
)
declare @rowsfound smallint 
select @rowsfound = 0 
declare @MSKlocation_code smLocationCode 
select @MSKlocation_code = @location_code 
select @MSKlocation_code = min(location_code) from amloc where 
	location_code > @MSKlocation_code 
while @MSKlocation_code is not null and @rowsfound < @rowsrequested 
begin 

	insert into #temp 
	select 
		timestamp,
		location_code,
		location_description 
	from amloc 
	where 
		location_code = @MSKlocation_code 

		select @rowsfound = @rowsfound + @@rowcount 
	 
	select @MSKlocation_code = min(location_code) from amloc where 
	location_code > @MSKlocation_code 
end 
select 
	timestamp,
	location_code,
	location_description 
from #temp order by location_code 
drop table #temp 

return @@error 
GO
GRANT EXECUTE ON  [dbo].[amlocNext_sp] TO [public]
GO
