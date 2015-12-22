SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create procedure [dbo].[amdprcrtFetch_sp] 
( 
	@rowsrequested smallint = 1,
	@co_trx_id 					smSurrogateKey, 
	@field_type 					smFieldType 
) as 


create table #temp ( 
	timestamp varbinary(8) null,
	co_trx_id int null,
	field_type int null,
	from_code char(16) null,
	to_code char(16) null 
)
declare @rowsfound smallint 
select @rowsfound = 0 

declare @MSKco_trx_id smSurrogateKey 
select @MSKco_trx_id = @co_trx_id 

declare @MSKfield_type smFieldType 
select @MSKfield_type = @field_type 

if exists (select * from amdprcrt where 
	co_trx_id = @MSKco_trx_id and 
	field_type = @MSKfield_type)
begin 
while @MSKco_trx_id is not null and @rowsfound < @rowsrequested 
begin 

	insert into #temp 
	select 
		timestamp,
		co_trx_id,
		field_type,
		from_code,
		to_code 
	from amdprcrt where 
	co_trx_id = @MSKco_trx_id and 
	field_type = @MSKfield_type 

	select @rowsfound = @rowsfound + @@rowcount
	 
	 
	select @MSKfield_type = min(field_type) from amdprcrt where 
	co_trx_id = @MSKco_trx_id and 
	field_type > @MSKfield_type 
end 
end 


select 
	timestamp,
	co_trx_id,
	field_type,
	from_code,
	to_code 
from #temp order by co_trx_id,	field_type 
drop table #temp 

return @@error 
GO
GRANT EXECUTE ON  [dbo].[amdprcrtFetch_sp] TO [public]
GO
