SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

 
CREATE PROCEDURE [dbo].[ampa_vwExists_sp]
(
	@company_id 	smCompanyID,
	@posting_code 	smPostingCode,
	@account_type				 	smAccountTypeID,
	@valid							int OUTPUT
)
AS
 
IF EXISTS (SELECT 1 FROM ampstact
			WHERE	company_id	 	= @company_id
			AND		posting_code				= @posting_code
	 		AND		account_type 	= @account_type
			)
	SELECT @valid = 1
ELSE
	SELECT @valid = 0
 
RETURN 0
GO
GRANT EXECUTE ON  [dbo].[ampa_vwExists_sp] TO [public]
GO
