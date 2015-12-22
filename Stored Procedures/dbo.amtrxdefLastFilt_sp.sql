SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create procedure [dbo].[amtrxdefLastFilt_sp] 
( 
	@rowsrequested smallint = 1,
	@trx_name_filter varchar(30) 
) as 


declare
 	@rowsfound 			smallint, 
	@MSKtrx_name 	smName 
	
select @rowsfound = 0 
SELECT @trx_name_filter = RTRIM(@trx_name_filter)


select 	@MSKtrx_name 	= max(trx_name) 
from 	amtrxdef_vw 
where 	RTRIM(CONVERT(char(30),trx_name)) 		like @trx_name_filter


if @MSKtrx_name is null 
begin 
 return 
end 

create table #temp ( timestamp varbinary(8) null, trx_type int, system_defined tinyint, create_activity int, display_activity tinyint, display_in_reports int, copy_trx_on_replicate tinyint, allow_to_import tinyint, prd_to_prd_column int, post_to_gl tinyint, summmarize_activity tinyint, trx_name varchar(30), trx_short_name varchar(30), trx_description varchar(40) null, updated_by int )

insert into #temp 
select timestamp, trx_type, system_defined, create_activity, display_activity, display_in_reports, copy_trx_on_replicate, allow_to_import, prd_to_prd_column, post_to_gl, summmarize_activity, trx_name, trx_short_name, trx_description, updated_by			 
from 	amtrxdef_vw 
where 	trx_name 	= @MSKtrx_name 

select @rowsfound = @@rowcount 

select 	@MSKtrx_name 	= max(trx_name) 
from 	amtrxdef_vw 
where 	trx_name 		< @MSKtrx_name 
and 	RTRIM(CONVERT(char(30),trx_name)) 		like @trx_name_filter

while @MSKtrx_name is not null and @rowsfound < @rowsrequested 
begin 

	insert 	into #temp 
	select timestamp, trx_type, system_defined, create_activity, display_activity, display_in_reports, copy_trx_on_replicate, allow_to_import, prd_to_prd_column, post_to_gl, summmarize_activity, trx_name, trx_short_name, trx_description, updated_by	 
	from 	amtrxdef_vw 
	where 	trx_name = @MSKtrx_name 

	select @rowsfound = @rowsfound + @@rowcount 

	 
	select 	@MSKtrx_name = max(trx_name) 
	from 	amtrxdef_vw 
	where 	trx_name < @MSKtrx_name 
 	and 	RTRIM(CONVERT(char(30),trx_name)) 		like @trx_name_filter
end 

select timestamp, trx_type, system_defined, create_activity, display_activity, display_in_reports, copy_trx_on_replicate, allow_to_import, prd_to_prd_column, post_to_gl, summmarize_activity, trx_name, trx_short_name, trx_description, updated_by		 
from #temp 
order by trx_name 

drop table #temp 

return @@error 
GO
GRANT EXECUTE ON  [dbo].[amtrxdefLastFilt_sp] TO [public]
GO
