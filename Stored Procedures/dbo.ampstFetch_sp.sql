SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create procedure [dbo].[ampstFetch_sp] 
( 
	@rowsrequested smallint = 1,
	@company_id smCompanyID, 
	@posting_code smPostingCode 
) as 

SET ROWCOUNT @rowsrequested


SELECT timestamp, company_id, posting_code, posting_code_description, updated_by
FROM ampst_vw
WHERE	company_id = @company_id
AND		posting_code >= @posting_code

SET ROWCOUNT 0

return @@error 
GO
GRANT EXECUTE ON  [dbo].[ampstFetch_sp] TO [public]
GO
