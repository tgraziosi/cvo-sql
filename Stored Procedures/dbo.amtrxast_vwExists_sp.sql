SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

 
CREATE PROCEDURE [dbo].[amtrxast_vwExists_sp]
(
	@co_trx_id 	smSurrogateKey,
	@company_id 	smCompanyID,
	@asset_ctrl_num 	smControlNumber,
	@valid		int OUTPUT
)
AS
 
IF EXISTS (SELECT 1 FROM amtrxast_vw
			WHERE	co_trx_id 	= @co_trx_id
	 		AND	company_id 	= @company_id
	 		AND	asset_ctrl_num 	= @asset_ctrl_num
			)
	SELECT @valid = 1
ELSE
	SELECT @valid = 0
 
RETURN 0
GO
GRANT EXECUTE ON  [dbo].[amtrxast_vwExists_sp] TO [public]
GO
