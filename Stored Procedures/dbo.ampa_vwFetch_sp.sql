SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

 
CREATE PROCEDURE [dbo].[ampa_vwFetch_sp]
(
	@rowsrequested		smCounter = 1,
	@company_id 	smCompanyID,
	@posting_code 	smPostingCode,
	@account_type 	smAccountTypeID
	
)
AS
 

SELECT timestamp, company_id, posting_code, account_type, account, account_type_name, display_order, income_account, updated_by
FROM ampa_vw
			WHERE	company_id	= @company_id
			AND		posting_code	= @posting_code
			AND		account_type	= @account_type

 

RETURN 0
GO
GRANT EXECUTE ON  [dbo].[ampa_vwFetch_sp] TO [public]
GO
