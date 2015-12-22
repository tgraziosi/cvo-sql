SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create procedure [dbo].[ampstLastFilt_sp] 
( 
	@rowsrequested smallint = 1,
	@company_id 		smCompanyID, 
	@posting_code_filter smPostingCode 
) as 


declare
 	@rowsfound 			smallint, 
	@MSKposting_code 	smPostingCode 
	
select @rowsfound = 0 


select 	@MSKposting_code 	= max(posting_code) 
from 	ampst_vw 
where 	posting_code 		like RTRIM(@posting_code_filter)
and 	company_id 			= @company_id 

if @MSKposting_code is null 
begin 
 return 
end 

create table #temp ( timestamp varbinary(8) null, company_id smallint null, posting_code char(8) null, posting_code_description char(40) null, updated_by int )

insert into #temp 
select timestamp, company_id, posting_code, posting_code_description, updated_by			 
from 	ampst_vw 
where 	company_id 		= @company_id 
and 	posting_code 	= @MSKposting_code 

select @rowsfound = @@rowcount 

select 	@MSKposting_code 	= max(posting_code) 
from 	ampst_vw 
where 	company_id 			= @company_id 
and 	posting_code 		< @MSKposting_code 
and 	posting_code 		like RTRIM(@posting_code_filter)

while @MSKposting_code is not null and @rowsfound < @rowsrequested 
begin 

	insert 	into #temp 
	select timestamp, company_id, posting_code, posting_code_description, updated_by	 
	from 	ampst_vw 
	where 	company_id = @company_id 
	and 	posting_code = @MSKposting_code 

	select @rowsfound = @rowsfound + @@rowcount 

	 
	select 	@MSKposting_code = max(posting_code) 
	from 	ampst_vw 
	where 	company_id = @company_id 
	and 	posting_code < @MSKposting_code 
 	and 	posting_code like RTRIM(@posting_code_filter)
end 

select timestamp, company_id, posting_code, posting_code_description, updated_by		 
from #temp 
order by company_id, posting_code 

drop table #temp 

return @@error 
GO
GRANT EXECUTE ON  [dbo].[ampstLastFilt_sp] TO [public]
GO
