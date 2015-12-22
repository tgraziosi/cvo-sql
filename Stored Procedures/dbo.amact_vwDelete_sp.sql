SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[amact_vwDelete_sp] 
( 
	@timestamp			timestamp,
	@co_trx_id			smSurrogateKey,
	@co_asset_id		smSurrogateKey
) 
AS 

DECLARE 
	@rowcount 	smCounter, 
	@error 		smErrorCode, 
	@ts 		timestamp, 
	@message 	smErrorLongDesc


DELETE 
FROM 	amtrxhdr 
WHERE 	co_asset_id		= @co_asset_id
AND		co_trx_id 	= @co_trx_id 
AND 	timestamp 	= @timestamp 

SELECT @error = @@error, @rowcount = @@rowcount 
IF @error <> 0
	RETURN @error 

IF @rowcount = 0  
BEGIN 
	 
	SELECT 	@ts 			= timestamp 
	FROM 	amtrxhdr 
	WHERE 	co_asset_id		= @co_asset_id
	AND		co_trx_id 	= @co_trx_id 

	SELECT @error = @@error, @rowcount = @@rowcount 
	IF @error <> 0  
		RETURN @error 

	IF @rowcount = 0  
	BEGIN 
		EXEC 		amGetErrorMessage_sp 20002, "tmp/amactdl.sp", 86, amtrxhdr, @error_message = @message OUT 
		IF @message IS NOT NULL RAISERROR 	20002 @message 
		RETURN 		20002 
	END 

	IF @ts <> @timestamp 
	BEGIN 
		EXEC 		amGetErrorMessage_sp 20001, "tmp/amactdl.sp", 93, amtrxhdr, @error_message = @message OUT 
		IF @message IS NOT NULL RAISERROR 	20001 @message 
		RETURN 		20001 
	END 
END
 
RETURN 0 
GO
GRANT EXECUTE ON  [dbo].[amact_vwDelete_sp] TO [public]
GO
