SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

 
CREATE PROCEDURE [dbo].[ampst_ampa_vwChildFetch_sp]
(
	@rowsrequested		smCounter = 1,
	@company_id                  	smCompanyID,
	@posting_code                	smPostingCode,
	@account_type                	smAccountTypeID
	
)
AS
 

SELECT timestamp, company_id, posting_code, account_type, account, account_type_name, display_order, income_account, updated_by
	, permission = case
		when 	account in ('')
			then 1
		when 	account in (select account_code from am_glchart_root_vw) 
			and 
			account in (select account_code from sm_accounts_access_vw) 
			then 1
			else 0
	end						
FROM ampa_vw
WHERE	company_id	= @company_id
AND		posting_code	= @posting_code
AND		account_type	= @account_type

 

RETURN 0
GO
GRANT EXECUTE ON  [dbo].[ampst_ampa_vwChildFetch_sp] TO [public]
GO
