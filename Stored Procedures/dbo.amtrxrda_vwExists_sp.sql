SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

 
CREATE PROCEDURE [dbo].[amtrxrda_vwExists_sp]
(
	@company_id 	smCompanyID,
	@trx_ctrl_num 	smControlNumber,
	@valid		int OUTPUT
)
AS
 
IF EXISTS (SELECT 1 FROM amtrxrda_vw
			WHERE	company_id 	= @company_id
	 		AND	trx_ctrl_num 	= @trx_ctrl_num
			)
	SELECT @valid = 1
ELSE
	SELECT @valid = 0
 
RETURN 0
GO
GRANT EXECUTE ON  [dbo].[amtrxrda_vwExists_sp] TO [public]
GO
