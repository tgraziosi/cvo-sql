SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

 
CREATE PROCEDURE [dbo].[amtrxast_vwInsert_sp]
(
	@co_trx_id 	smSurrogateKey,
	@company_id 	smCompanyID,
	@asset_ctrl_num 	smControlNumber,
	@asset_description 	smStdDescription
)
AS

DECLARE @co_asset_id smSurrogateKey,
		@message 	smErrorLongDesc,
		@org_id         varchar (30 )
	 
SELECT 	@co_asset_id 	= co_asset_id ,
        @org_id = org_id
FROM	amasset
WHERE	company_id	= @company_id
AND	asset_ctrl_num	= @asset_ctrl_num

IF @co_asset_id IS NULL
BEGIN
	EXEC 		amGetErrorMessage_sp 20030, "tmp/amtrasin.sp", 65,@asset_ctrl_num, @error_message = @message OUT 
	IF @message IS NOT NULL RAISERROR 	20030 @message 
	RETURN 0
END



INSERT INTO amtrxast
(
	co_trx_id,
	company_id,
	asset_ctrl_num,
	co_asset_id,
	org_id
)
VALUES
(
	@co_trx_id,
	@company_id,
	@asset_ctrl_num,
	@co_asset_id,
	@org_id
)
 
RETURN @@error
GO
GRANT EXECUTE ON  [dbo].[amtrxast_vwInsert_sp] TO [public]
GO
