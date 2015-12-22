SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

 
CREATE PROCEDURE [dbo].[amta_vwExists_sp]
(
	@trx_type 		smTrxType,
	@account_type_name 	smName,
	@valid							int OUTPUT
)
AS
 
IF EXISTS (SELECT 1 FROM amta_vw
		 WHERE	trx_type 	= @trx_type
	 	 AND		account_type_name 	= @account_type_name
			)
	SELECT @valid = 1
ELSE
	SELECT @valid = 0
 
RETURN 0
GO
GRANT EXECUTE ON  [dbo].[amta_vwExists_sp] TO [public]
GO
