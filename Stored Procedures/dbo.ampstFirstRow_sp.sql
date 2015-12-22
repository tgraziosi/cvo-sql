SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create procedure [dbo].[ampstFirstRow_sp](
	@company_id	smCompanyID
	)	 
as 


declare @MSKposting_code smPostingCode

select @MSKposting_code = min(posting_code) 
from ampst_vw
where company_id = @company_id
 
select timestamp, company_id, posting_code, posting_code_description, updated_by 	 
from ampst_vw 
where 	company_id = @company_id
and 	posting_code = @MSKposting_code 

return @@error 
GO
GRANT EXECUTE ON  [dbo].[ampstFirstRow_sp] TO [public]
GO
