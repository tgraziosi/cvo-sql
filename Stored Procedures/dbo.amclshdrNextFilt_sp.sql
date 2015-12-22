SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create procedure [dbo].[amclshdrNextFilt_sp] 
( 
	@rowsrequested smallint = 1,
	@company_id smCompanyID, 
	@classification_name smClassificationName, 
	@company_id_filter smCompanyID, 
	@classification_name_filter smClassificationName 
) as 


declare 
	@rowsfound 			smallint, 
	@MSKclassification_name 	smClassificationName 


create table #temp ( timestamp varbinary(8) null, company_id smallint null, classification_id int null, classification_name varchar(40) null, acct_level tinyint null, start_col smallint null, length smallint null, override_default varchar(32) null, updated_by int null )		
 

select @MSKclassification_name = @classification_name 
select @rowsfound = 0 
 

select 	@MSKclassification_name 	= min(classification_name) 
from 	amclshdr 
where 	company_id 			= @company_id 
and 	classification_name 		> @MSKclassification_name 
and 	classification_name 		like RTRIM(@classification_name_filter)

while @MSKclassification_name is not null and @rowsfound < @rowsrequested 
begin 

	insert 	into #temp 
	select timestamp, company_id, classification_id, classification_name, acct_level , start_col, length , override_default , updated_by		
	from 	amclshdr
	where 	company_id 		= @company_id 
	and 	classification_name 	= @MSKclassification_name 

	select @rowsfound = @rowsfound + @@rowcount 
	
	 
	select 	@MSKclassification_name	= min(classification_name) 
	from 	amclshdr 
	where 	company_id 			= @company_id 
	and 	classification_name 		> @MSKclassification_name 
 	and 	classification_name 		like RTRIM(@classification_name_filter)
end 															

select timestamp, company_id, classification_id, classification_name, acct_level , start_col, length , override_default , updated_by															
from #temp 
drop table #temp 

return @@error 
GO
GRANT EXECUTE ON  [dbo].[amclshdrNextFilt_sp] TO [public]
GO
