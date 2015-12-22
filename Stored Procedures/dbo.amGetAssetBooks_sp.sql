SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[amGetAssetBooks_sp] 
(
	@co_asset_id 	smSurrogateKey, 	
	@debug_level	smDebugLevel	= 0	
)
AS 

DECLARE 
	@message smErrorLongDesc,
	@asset_ctrl_num	smControlNumber,
	@param			smErrorParam

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amassbks.sp" + ", line " + STR( 53, 5 ) + " -- ENTRY: " 

SELECT a.book_code, 
		co_asset_book_id,
		post_to_gl 
FROM amastbk a,ambook b
WHERE co_asset_id 	= @co_asset_id
and 	a.book_code =b.book_code

IF @@rowcount = 0 
BEGIN 
	SELECT	@asset_ctrl_num	= asset_ctrl_num
	FROM	amasset
	WHERE	co_asset_id		= @co_asset_id
	
	IF @@rowcount = 0 
	BEGIN
		SELECT		@param = RTRIM(CONVERT(char(255), @co_asset_id))

		EXEC 		amGetErrorMessage_sp 20030, "tmp/amassbks.sp", 72, @param, @error_message = @message OUT 
		IF @message IS NOT NULL RAISERROR 	20030 @message 
		RETURN 		20030 
	END
	ELSE
	BEGIN
		EXEC 		amGetErrorMessage_sp 20061, "tmp/amassbks.sp", 78, @asset_ctrl_num, @error_message = @message OUT 
		IF @message IS NOT NULL RAISERROR 	20061 @message 
		RETURN 		20061 
	END
END 

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amassbks.sp" + ", line " + STR( 84, 5 ) + " -- EXIT: "

RETURN 0
GO
GRANT EXECUTE ON  [dbo].[amGetAssetBooks_sp] TO [public]
GO
