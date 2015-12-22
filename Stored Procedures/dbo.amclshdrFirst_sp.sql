SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create procedure [dbo].[amclshdrFirst_sp] 
( 
	@rowsrequested smallint = 1,
	@company_id smCompanyID
	 
) as 

DECLARE @result 				smErrorCode
declare @MSKclassification_name smClassificationName


select @MSKclassification_name = min(classification_name) 
from amclshdr 
where company_id = @company_id 

if @MSKclassification_name is null 
begin 
 return 
end 

SET ROWCOUNT @rowsrequested

select timestamp, company_id, classification_id, classification_name, acct_level , start_col, length , override_default , updated_by
FROM amclshdr
where	company_id = @company_id 
and 	classification_name >= @MSKclassification_name
	
select @result = @@error

SET ROWCOUNT 0	 
return @result

GO
GRANT EXECUTE ON  [dbo].[amclshdrFirst_sp] TO [public]
GO
