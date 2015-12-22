SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

 
CREATE PROCEDURE [dbo].[amca_vwExists_sp]
(
	@company_id 	smCompanyID,
	@classification_id 	smSurrogateKey,
	@account_type				 	smAccountTypeID,
	@valid							int OUTPUT
)
AS
 
IF EXISTS (SELECT 1 FROM amclsact
			WHERE	company_id	 	= @company_id
			AND		classification_id			= @classification_id
	 		AND		account_type 	= @account_type
			)
	SELECT @valid = 1
ELSE
	SELECT @valid = 0
 
RETURN 0
GO
GRANT EXECUTE ON  [dbo].[amca_vwExists_sp] TO [public]
GO
