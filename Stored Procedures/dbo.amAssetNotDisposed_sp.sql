SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE [dbo].[amAssetNotDisposed_sp] 
(										
 @co_asset_id	smSurrogateKey,			
	@debug_level	smDebugLevel	= 0		
)
AS 

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amaststt.sp" + ", line " + STR( 45, 5 ) + " -- ENTRY: "

DECLARE 
	@message		smErrorLongDesc,
	@result			smErrorCode,
	@param			smErrorParam,
	@asset_ctrl_num	smControlNumber,
	@activity_state smSystemState

SELECT 	@activity_state = activity_state,
		@asset_ctrl_num	= asset_ctrl_num 
FROM 	amasset
WHERE 	co_asset_id 	= @co_asset_id 

IF @@rowcount = 0
BEGIN
	
	SELECT	@param = RTRIM(CONVERT(char(255), @co_asset_id))

 	EXEC 		amGetErrorMessage_sp 20063, "tmp/amaststt.sp", 64, @param, @error_message = @message OUT 
 	IF @message IS NOT NULL RAISERROR 	20063 @message 
	RETURN		20063

END
ELSE
BEGIN
 	IF @activity_state = 101
 	BEGIN
 		EXEC 		amGetErrorMessage_sp 20098, "tmp/amaststt.sp", 73, @asset_ctrl_num, @error_message = @message OUT 
	 	IF @message IS NOT NULL RAISERROR 	20098 @message 
		RETURN		20098
	END
END

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amaststt.sp" + ", line " + STR( 79, 5 ) + " -- EXIT: "

RETURN 0 
GO
GRANT EXECUTE ON  [dbo].[amAssetNotDisposed_sp] TO [public]
GO
