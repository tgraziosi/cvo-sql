SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create procedure [dbo].[amclshdrPrevRow_sp] 
( 
	@company_id smCompanyID, 
	@classification_name smClassificationName 
) as 


declare @MSKclassification_name smClassificationName

select @MSKclassification_name = @classification_name 

select @MSKclassification_name = max(classification_name)
from amclshdr 
where company_id = @company_id 
and classification_name < @MSKclassification_name 

select timestamp, company_id, classification_id, classification_name, acct_level , start_col, length , override_default , updated_by
from amclshdr 
where company_id = @company_id 
and classification_name = @MSKclassification_name 

return @@error 
GO
GRANT EXECUTE ON  [dbo].[amclshdrPrevRow_sp] TO [public]
GO
