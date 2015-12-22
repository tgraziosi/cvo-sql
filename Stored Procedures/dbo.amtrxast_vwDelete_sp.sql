SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

 
CREATE PROCEDURE [dbo].[amtrxast_vwDelete_sp]
(
	@timestamp 	timestamp,
	@co_trx_id 	smSurrogateKey,
	@company_id 	smCompanyID,
	@asset_ctrl_num 	smControlNumber
)
AS
 
DECLARE	@rowcount	smCounter
DECLARE	@ts		timestamp
DECLARE	@error		smErrorCode
DECLARE	@message	smErrorLongDesc
DECLARE @co_asset_id	smSurrogateKey

SELECT 	@co_asset_id 	= co_asset_id
FROM	amasset
WHERE	company_id	= @company_id
AND	asset_ctrl_num	= @asset_ctrl_num

DELETE amtrxast
FROM	amtrxast
WHERE	co_trx_id 	= @co_trx_id
AND	co_asset_id			= @co_asset_id
AND	timestamp 	= @timestamp
 
SELECT @error = @@error, @rowcount = @@rowcount
IF @error <> 0
	RETURN @error
 
IF @rowcount = 0
BEGIN
	SELECT	@ts	= timestamp
	FROM	amtrxast_vw
	WHERE	co_trx_id	= @co_trx_id
	AND		company_id	= @company_id
	AND		asset_ctrl_num	= @asset_ctrl_num
 
	SELECT @error = @@error, @rowcount = @@rowcount
	IF @error <> 0
		RETURN @error
 
	IF @rowcount = 0
	BEGIN
		EXEC 		amGetErrorMessage_sp 20002, "tmp/amtrasdl.sp", 91, 'amtrxast_vw', @error_message = @message OUT
		IF @message IS NOT NULL RAISERROR 	20002 @message
		RETURN 		20002
	END
 
	IF @ts <> @timestamp
	BEGIN
		EXEC 		amGetErrorMessage_sp 20001, "tmp/amtrasdl.sp", 98, 'amtrxast_vw', @error_message = @message OUT
		IF @message IS NOT NULL RAISERROR 	20001 @message
		RETURN 		20001
	END
END
 
RETURN 0
GO
GRANT EXECUTE ON  [dbo].[amtrxast_vwDelete_sp] TO [public]
GO
