SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create procedure [dbo].[ampstFirst_sp] 
( 
	@rowsrequested smallint = 1,
	@company_id smCompanyID
	 
) as 

DECLARE @result 				smErrorCode
declare @MSKposting_code smPostingCode


select @MSKposting_code = min(posting_code) 
from ampst_vw 
where company_id = @company_id 

if @MSKposting_code is null 
begin 
 return 
end 

SET ROWCOUNT @rowsrequested

select timestamp, company_id, posting_code, posting_code_description, updated_by
FROM ampst_vw
where	company_id = @company_id 
and 	posting_code >= @MSKposting_code
	
select @result = @@error

SET ROWCOUNT 0	 
return @result

GO
GRANT EXECUTE ON  [dbo].[ampstFirst_sp] TO [public]
GO
