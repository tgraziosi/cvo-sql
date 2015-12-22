SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create procedure [dbo].[amtrxdefNext_sp] 
( 
	@rowsrequested smallint = 1,
	@trx_name smName 
) as 


create table #temp ( timestamp varbinary(8) null, trx_type int, system_defined tinyint, create_activity int, display_activity tinyint, display_in_reports int, copy_trx_on_replicate tinyint, allow_to_import tinyint, prd_to_prd_column int, post_to_gl tinyint, summmarize_activity tinyint, trx_name varchar(30), trx_short_name varchar(30), trx_description varchar(40) null, updated_by int )

declare @rowsfound smallint,
		 @MSKtrx_name smName
		 
select @MSKtrx_name = @trx_name
 
select @rowsfound = 0
 
select @MSKtrx_name = min(trx_name) 
from amtrxdef_vw
where trx_name > @MSKtrx_name 

while @MSKtrx_name is not null and @rowsfound < @rowsrequested 
begin 

	insert into #temp 
	select timestamp, trx_type, system_defined, create_activity, display_activity, display_in_reports, copy_trx_on_replicate, allow_to_import, prd_to_prd_column, post_to_gl, summmarize_activity, trx_name, trx_short_name, trx_description, updated_by 				 
	from amtrxdef_vw 
	where trx_name = @MSKtrx_name 

	select @rowsfound = @rowsfound + @@rowcount 
	 
	select @MSKtrx_name = min(trx_name) 
	from amtrxdef_vw 
	where	trx_name > @MSKtrx_name 
end
 
select timestamp, trx_type, system_defined, create_activity, display_activity, display_in_reports, copy_trx_on_replicate, allow_to_import, prd_to_prd_column, post_to_gl, summmarize_activity, trx_name, trx_short_name, trx_description, updated_by		
from #temp
 
drop table #temp 

return @@error 
GO
GRANT EXECUTE ON  [dbo].[amtrxdefNext_sp] TO [public]
GO
