SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[amChangeAssetSource_sp] 
(
 @co_asset_id smSurrogateKey, 	
	@was_new 	 	smLogical, 		 	 
	@is_new 	 	smLogical, 		 	 
	@debug_level	smDebugLevel	= 0	
)
AS 

DECLARE @result 			smErrorCode 

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amchgsrc.sp" + ", line " + STR( 100, 5 ) + " -- ENTRY: "


IF 	@is_new = 1 
AND @was_new = 0
BEGIN

	DELETE 	amastprf
	FROM 	amastprf 	ap,
			amastbk		ab
	WHERE 	ap.co_asset_book_id = ab.co_asset_book_id 
	AND		ab.co_asset_id		= @co_asset_id

	SELECT @result = @@error 
	IF @result <> 0 
 		RETURN @result 
END 

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amchgsrc.sp" + ", line " + STR( 121, 5 ) + " -- EXIT: "

RETURN 0 
GO
GRANT EXECUTE ON  [dbo].[amChangeAssetSource_sp] TO [public]
GO
