SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create procedure [dbo].[amclshdrFetch_sp] 
( 
	@rowsrequested smallint = 1,
	@company_id smCompanyID, 
	@classification_name				smClassificationName 
) as 

SET ROWCOUNT @rowsrequested


SELECT timestamp, company_id, classification_id, classification_name, acct_level , start_col, length , override_default , updated_by
FROM amclshdr
WHERE	company_id = @company_id
AND		classification_name >= @classification_name

SET ROWCOUNT 0

return @@error 
GO
GRANT EXECUTE ON  [dbo].[amclshdrFetch_sp] TO [public]
GO
