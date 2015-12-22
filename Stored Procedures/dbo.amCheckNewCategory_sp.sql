SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[amCheckNewCategory_sp] 
(
 @asset_ctrl_num		smControlNumber,		
 @co_asset_id smSurrogateKey, 		
 	@acquisition_date	smISODate,				
 	@new_category_code	smCategoryCode, 		 
 	@is_valid			smLogical OUTPUT,	 
	@debug_level		smDebugLevel	= 0		
)
AS 

DECLARE 
	@result 			smErrorCode, 		 	
	@message 			smErrorLongDesc,	 	
	@acq_date			smApplyDate,		 	
	@last_depr_date		smApplyDate,		 	
	@effective_date		smApplyDate,		 	
	@co_asset_book_id 	smSurrogateKey, 	 	
	@book_code 			smBookCode			 	

 
IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amchnwct.sp" + ", line " + STR( 74, 5 ) + " -- ENTRY: "

SELECT	@is_valid = 1,
		@acq_date	= CONVERT(datetime, @acquisition_date)

SELECT	@book_code	= MIN(book_code)
FROM	amastbk
WHERE	co_asset_id = @co_asset_id

WHILE @book_code IS NOT NULL
BEGIN
	IF @debug_level >= 3
		SELECT book_code = @book_code

	
	SELECT	@last_depr_date	= last_posted_depr_date
	FROM	amastbk
	WHERE	co_asset_id 	= @co_asset_id
	AND		book_code		= @book_code

	IF @last_depr_date IS NULL
		SELECT	@effective_date = @acq_date
	ELSE	
		SELECT	@effective_date	= DATEADD(dd, 1, @last_depr_date)

	IF NOT EXISTS(SELECT	book_code
					FROM	amcatbk
					WHERE	category_code	= @new_category_code
					AND		book_code		= @book_code
					AND		effective_date	<= @effective_date)
	BEGIN
		IF @debug_level >= 3
			SELECT "Book not found"

		SELECT		@is_valid = 0
		EXEC 		amGetErrorMessage_sp 20082, "tmp/amchnwct.sp", 116, @new_category_code, @book_code, @asset_ctrl_num, @error_message = @message OUT 
		IF @message IS NOT NULL RAISERROR 	20082 @message 
		BREAK
	END

	
	SELECT	@book_code	= MIN(book_code)
	FROM	amastbk
	WHERE	co_asset_id = @co_asset_id
	AND		book_code	> @book_code
	
END

IF @is_valid = 1
BEGIN
	
	IF EXISTS ( SELECT 	book_code
				FROM 	amcatbk
				WHERE 	category_code 	= @new_category_code
				AND		effective_date	<= @acq_date
				AND		book_code		NOT IN (SELECT 	book_code
												FROM 	amastbk
												WHERE	co_asset_id = @co_asset_id)	)
	BEGIN
		SELECT		@is_valid = 0
		
		EXEC 		amGetErrorMessage_sp 20083, "tmp/amchnwct.sp", 153, @new_category_code, @asset_ctrl_num, @error_message = @message OUT 
		IF @message IS NOT NULL RAISERROR 	20083 @message 
	END
END

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amchnwct.sp" + ", line " + STR( 158, 5 ) + " -- EXIT: "

RETURN 0
GO
GRANT EXECUTE ON  [dbo].[amCheckNewCategory_sp] TO [public]
GO
