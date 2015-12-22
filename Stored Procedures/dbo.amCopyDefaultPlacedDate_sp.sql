SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[amCopyDefaultPlacedDate_sp] 
(
 @co_asset_id 		smSurrogateKey, 		
	@def_placed_date		smISODate,				
	@debug_level			smDebugLevel	= 0		
)
AS 

DECLARE 
	@result						smErrorCode,
	@message 					smErrorLongDesc,
	@param						smErrorParam,
	@co_asset_book_id			smSurrogateKey,
	@asset_ctrl_num				smControlNumber,			
	@book_code					smBookCode,
	@last_posted_depr_date 		smApplyDate,
	@new_placed_date			smApplyDate
 
IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amcpdfpd.sp" + ", line " + STR( 65, 5 ) + " -- ENTRY: "

SELECT	@new_placed_date	= CONVERT(datetime, @def_placed_date) 
	
SELECT	@co_asset_book_id	= MIN(co_asset_book_id)
FROM	amastbk
WHERE	co_asset_id			= @co_asset_id

WHILE @co_asset_book_id IS NOT NULL
BEGIN
	SELECT	@last_posted_depr_date	= last_posted_depr_date
	FROM	amastbk
	WHERE	co_asset_book_id		= @co_asset_book_id
		
	
	IF @last_posted_depr_date IS NOT NULL
	BEGIN 
				
		SELECT	@book_code			= ab.book_code,
				@asset_ctrl_num		= a.asset_ctrl_num
		FROM	amasset	a,
				amastbk ab
		WHERE	ab.co_asset_book_id	= @co_asset_book_id
		AND		ab.co_asset_id		= a.co_asset_id

		IF @book_code IS NOT NULL
		BEGIN
			EXEC 		amGetErrorMessage_sp 20180, "tmp/amcpdfpd.sp", 95, @book_code, @asset_ctrl_num, @error_message = @message OUT 
			IF @message IS NOT NULL RAISERROR 	20180 @message 
		END
		ELSE
		BEGIN
			SELECT		@param = RTRIM(CONVERT(char(255), @co_asset_book_id))
			
			EXEC 		amGetErrorMessage_sp 20025, "tmp/amcpdfpd.sp", 102, @param, @error_message = @message OUT 
			IF @message IS NOT NULL RAISERROR 	20025 @message 
			RETURN 		20025 
		END
	END
	ELSE
	BEGIN
		UPDATE	amastbk
		SET		placed_in_service_date 	= @new_placed_date
		FROM	amastbk
		WHERE	co_asset_book_id		= @co_asset_book_id
		
		SELECT	@result = @@error
		IF	@result <> 0
			RETURN @result	
	END
	
	
	SELECT	@co_asset_book_id	= MIN(co_asset_book_id)
	FROM	amastbk
	WHERE	co_asset_book_id	> @co_asset_book_id
	AND		co_asset_id			= @co_asset_id
END 

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amcpdfpd.sp" + ", line " + STR( 128, 5 ) + " -- EXIT: "

RETURN 0
GO
GRANT EXECUTE ON  [dbo].[amCopyDefaultPlacedDate_sp] TO [public]
GO
