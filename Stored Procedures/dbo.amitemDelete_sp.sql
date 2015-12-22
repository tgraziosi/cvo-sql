SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[amitemDelete_sp] 
( 
	@timestamp		timestamp,
	@co_asset_id	smSurrogateKey, 
	@sequence_id	smSurrogateKey 
) 
AS 

DECLARE 
	@rowcount 	smCounter,
	@error 		smErrorCode, 
	@ts 		timestamp, 
	@message 	smErrorLongDesc

DELETE 
FROM 	amitem 
WHERE 	timestamp	= @timestamp 
AND 	co_asset_id	= @co_asset_id 
AND 	sequence_id	= @sequence_id 

SELECT @error = @@error, @rowcount = @@rowcount 

IF @error <> 0  
	RETURN @error 

IF @rowcount = 0  
BEGIN 
	 
	SELECT 	@ts 		= timestamp 
	FROM 	amitem 
	WHERE 	co_asset_id = @co_asset_id 
	AND 	sequence_id	= @sequence_id 

	SELECT @error = @@error, @rowcount = @@rowcount 
	IF @error <> 0  
		RETURN @error 

	IF @rowcount = 0  
	BEGIN 
		EXEC 		amGetErrorMessage_sp 20002, "tmp/amitemdl.sp", 83, amitem, @error_message = @message OUT 
		IF @message IS NOT NULL RAISERROR 	20002 @message 
		RETURN 		20002 
	END 

	IF @ts <> @timestamp 
	BEGIN 
		EXEC 		amGetErrorMessage_sp 20001, "tmp/amitemdl.sp", 90, amitem, @error_message = @message OUT 
		IF @message IS NOT NULL RAISERROR 	20001 @message 
		RETURN 		20001 
	END 
END 

RETURN 0 
GO
GRANT EXECUTE ON  [dbo].[amitemDelete_sp] TO [public]
GO
