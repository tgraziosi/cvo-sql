SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

 
CREATE PROCEDURE [dbo].[amGetAssetDate_sp] 
( 
 	@co_asset_book_id 		 smSurrogateKey,		
 	@placed_in_service_date smApplyDate OUTPUT, 	
	@debug_level				smDebugLevel	= 0		
)
AS 
 
DECLARE 
	@message smErrorLongDesc,
	@param			smErrorParam


IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amastdt.sp" + ", line " + STR( 102, 5 ) + " -- ENTRY: " 

IF @debug_level >= 5
	SELECT 	co_asset_book_id 	= @co_asset_book_id

SELECT @placed_in_service_date 	= placed_in_service_date 
FROM amastbk 
WHERE co_asset_book_id 		= @co_asset_book_id 
 
IF @@rowcount = 0 
BEGIN 
	SELECT		@param = RTRIM(CONVERT(char(255), @co_asset_book_id))
	
	EXEC 		amGetErrorMessage_sp 20025, "tmp/amastdt.sp", 115, @param, @error_message = @message OUT 
	IF @message IS NOT NULL RAISERROR 	20025 @message 
	RETURN 		20025 
END 
 
IF @debug_level >= 5
	SELECT placed_in_service_date = @placed_in_service_date 
 

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amastdt.sp" + ", line " + STR( 124, 5 ) + " -- EXIT: "

RETURN 0
GO
GRANT EXECUTE ON  [dbo].[amGetAssetDate_sp] TO [public]
GO
