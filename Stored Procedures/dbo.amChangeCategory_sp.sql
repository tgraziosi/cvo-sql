SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[amChangeCategory_sp] 
(
 @co_asset_id 	smSurrogateKey, 	
	@acquisition_date 	smApplyDate,	 	
	@category_code 		smCategoryCode,	 	 
	@user_id		 	smUserID,		 	
	@debug_level		smDebugLevel = 0	
)
AS 

DECLARE 
	@result 			smErrorCode, 	 	
	@co_asset_book_id 	smSurrogateKey, 	
	@book_code 			smBookCode,		 	
	@placed_date	 	smApplyDate,	 	
	@last_depr_date		smApplyDate,	 	
	@effective_date		smApplyDate		 	

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amchgcat.sp" + ", line " + STR( 85, 5 ) + " -- ENTRY: "


SELECT	@book_code	= MIN(book_code)
FROM	amastbk
WHERE	co_asset_id = @co_asset_id

WHILE @book_code IS NOT NULL
BEGIN
	IF @debug_level >= 3
		SELECT book_code = @book_code

	
	SELECT	@co_asset_book_id	= co_asset_book_id,
			@last_depr_date		= last_posted_depr_date,
			@placed_date		= placed_in_service_date
	FROM	amastbk
	WHERE	co_asset_id			= @co_asset_id
	AND		book_code			= @book_code
	
	IF @last_depr_date IS NULL
		SELECT	@effective_date	= @acquisition_date
	ELSE
		SELECT	@effective_date	= DATEADD(dd, 1, @last_depr_date)
		
	EXEC	@result = amCreateNewRule_sp
						@co_asset_book_id,
						@book_code,
						@effective_date,
						@category_code,
						@user_id,
						@placed_date
	
	SELECT	@book_code	= MIN(book_code)
	FROM	amastbk
	WHERE	co_asset_id = @co_asset_id
	AND		book_code	> @book_code
	
END

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amchgcat.sp" + ", line " + STR( 134, 5 ) + " -- EXIT: "

RETURN 0
GO
GRANT EXECUTE ON  [dbo].[amChangeCategory_sp] TO [public]
GO
