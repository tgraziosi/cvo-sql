SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create procedure [dbo].[ampstPrev_sp] 
( 
	@rowsrequested smallint = 1,
	@company_id smCompanyID, 
	@posting_code smPostingCode 
) as 


create table #temp ( timestamp varbinary(8) null, company_id smallint null, posting_code char(8) null, posting_code_description char(40) null, updated_by int )

declare @rowsfound smallint, 
		@MSKposting_code smPostingCode
		
select @rowsfound = 0 
select @MSKposting_code = @posting_code 

select @MSKposting_code = max(posting_code) 
from ampst_vw 
where 	company_id = @company_id 
and 	posting_code < @MSKposting_code 

while @MSKposting_code is not null and @rowsfound < @rowsrequested 
begin 

	insert into #temp 
	select timestamp, company_id, posting_code, posting_code_description, updated_by 	 		 
	from ampst_vw 
	where 		company_id = @company_id
	and 	 	posting_code = @MSKposting_code 

	select @rowsfound = @rowsfound + @@rowcount 

	 
	select @MSKposting_code = max(posting_code)
	from ampst_vw 
	where company_id = @company_id 
	and posting_code < @MSKposting_code 
end
 
select timestamp, company_id, posting_code, posting_code_description, updated_by	
from #temp 
order by company_id, posting_code 

drop table #temp 

return @@error 
GO
GRANT EXECUTE ON  [dbo].[ampstPrev_sp] TO [public]
GO
