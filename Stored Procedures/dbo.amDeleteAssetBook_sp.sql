SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[amDeleteAssetBook_sp]
(
	@co_asset_id		smSurrogateKey,		
	@book_code			smBookCode,			
	@debug_level		smDebugLevel	= 0	
) 
AS

DECLARE 
	@result				smErrorCode,
	@message			smErrorLongDesc,
	@post_to_gl			smLogical,
	@co_asset_book_id	smSurrogateKey		

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amdelabk.sp" + ", line " + STR( 60, 5 ) + " -- ENTRY: "


SELECT	@post_to_gl 		= b.post_to_gl
FROM	ambook b
WHERE	b.book_code			= @book_code

IF @post_to_gl = 1
BEGIN
	EXEC	 	amGetErrorMessage_sp 20094, "tmp/amdelabk.sp", 71, @book_code, @error_message = @message OUT
	IF @message IS NOT NULL RAISERROR 	20094 @message
	RETURN 		20094
END


SELECT	@co_asset_book_id	= ab.co_asset_book_id
FROM	amastbk ab
WHERE	ab.co_asset_id		= @co_asset_id
AND		ab.book_code		= @book_code


DELETE
FROM	amastbk
WHERE	co_asset_book_id	= @co_asset_book_id

SELECT @result = @@error
IF @result <> 0
	RETURN @result


IF NOT EXISTS(SELECT book_code
				FROM	amastbk
				WHERE	co_asset_id = @co_asset_id)
BEGIN
	DELETE 
	FROM	amtrxhdr
	WHERE	co_asset_id = @co_asset_id

	SELECT @result = @@error
	IF @result <> 0
		RETURN @result
END

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amdelabk.sp" + ", line " + STR( 119, 5 ) + " -- EXIT: "

RETURN 0
GO
GRANT EXECUTE ON  [dbo].[amDeleteAssetBook_sp] TO [public]
GO
