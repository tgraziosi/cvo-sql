SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

 
create procedure [dbo].[amsusact_vwFirst_sp]
(
 @rowsrequested smallint = 1,
		@company_id 	smCompanyID


) as
 
SELECT timestamp, company_id, posting_code, posting_code_description, updated_by
FROM amsusact_vw
WHERE company_id = @company_id
 
return @@error
GO
GRANT EXECUTE ON  [dbo].[amsusact_vwFirst_sp] TO [public]
GO
