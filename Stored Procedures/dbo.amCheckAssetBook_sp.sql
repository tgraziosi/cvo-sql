SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[amCheckAssetBook_sp]
(
	@co_asset_id			smSurrogateKey,		
	@new_book_code			smBookCode,			
	@old_book_code			smBookCode,			
	@copy_depreciation		smLogical,			
	@depr_to_copied_bk		smLogical,			
	@depr_up_to				smApplyDate	OUTPUT,	
	@is_valid				smLogical	OUTPUT,	
	@debug_level			smDebugLevel	= 0	
) 
AS

DECLARE 
	@result					smErrorCode,
	@message				smErrorLongDesc,
	@param					smErrorParam,
	@asset_ctrl_num			smControlNumber,	
	@category_code			smCategoryCode,		
	@acquisition_date		smApplyDate,		
	@depr_on_date			smApplyDate, 		
	@co_asset_book_id		smSurrogateKey,
	@last_posted_depr_date	smApplyDate,
	@activity_state			smSystemState

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amchkabk.sp" + ", line " + STR( 100, 5 ) + " -- ENTRY: "

SELECT 	@is_valid = 1


SELECT 	@category_code 		= category_code,
		@asset_ctrl_num		= asset_ctrl_num,
		@acquisition_date	= acquisition_date,
		@activity_state		= activity_state
FROM	amasset
WHERE	co_asset_id			= @co_asset_id

SELECT 	@co_asset_book_id		= co_asset_book_id,
		@last_posted_depr_date	= last_posted_depr_date
FROM	amastbk
WHERE	co_asset_id				= @co_asset_id
AND		book_code				= @old_book_code
		
IF @@rowcount = 0
BEGIN
	
	EXEC	 	amGetErrorMessage_sp 
					26003, "tmp/amchkabk.sp", 126, 
					@old_book_code, @asset_ctrl_num, 
					@error_message = @message OUT
	IF @message IS NOT NULL RAISERROR 	26003 @message

	SELECT @is_valid = 0
	RETURN 0
END


IF @activity_state = 101
BEGIN
	EXEC	 	amGetErrorMessage_sp 
					20095, "tmp/amchkabk.sp", 141, 
					@new_book_code, @asset_ctrl_num, 
					@error_message = @message OUT
	IF @message IS NOT NULL RAISERROR 	20095 @message

	SELECT @is_valid = 0
	RETURN 20095
END


IF EXISTS (SELECT co_asset_book_id
			FROM	amastbk
			WHERE	co_asset_id		= @co_asset_id
			AND		book_code		= @new_book_code)
BEGIN
	EXEC	 	amGetErrorMessage_sp 
				26002, "tmp/amchkabk.sp", 159, 
					@new_book_code, @asset_ctrl_num, 
					@error_message = @message OUT
	IF @message IS NOT NULL RAISERROR 	26002 @message

	SELECT @is_valid = 0
	RETURN 0
END

IF @copy_depreciation = 0
BEGIN
	
	IF NOT EXISTS (SELECT depr_rule_code
					FROM	amcatbk cb
					WHERE	cb.category_code	= @category_code
					AND		cb.book_code		= @new_book_code
					AND		cb.effective_date	< @acquisition_date)
	BEGIN
		EXEC	 	amGetErrorMessage_sp 
						20187, "tmp/amchkabk.sp", 182, 
						@new_book_code, @category_code, @asset_ctrl_num,
						@error_message = @message OUT
		IF @message IS NOT NULL RAISERROR 	20187 @message
	
		SELECT @is_valid = 0
		RETURN 0
	END
END
ELSE 
BEGIN
 	IF @depr_to_copied_bk = 0
 		SELECT 	@depr_up_to			= @last_posted_depr_date
 		
 	ELSE IF @depr_to_copied_bk = 2
 		SELECT 	@depr_up_to			= NULL
 	ELSE
 	BEGIN
	 		
		IF 	@depr_up_to IS NOT NULL
		BEGIN
			SELECT @depr_on_date	= NULL
			
			
			SELECT 	@depr_on_date 		= MAX(apply_date)
			FROM	amvalues
			WHERE	co_asset_book_id 	= @co_asset_book_id
			AND		trx_type			= 50
			AND		apply_date			<= @depr_up_to
			AND		account_type_id		= 5

			
			IF @depr_on_date IS NULL
			BEGIN
				SELECT @param 		= CONVERT(varchar(255), @depr_up_to, 107)
				
				EXEC	 	amGetErrorMessage_sp 
								20188, "tmp/amchkabk.sp", 226, 
								@asset_ctrl_num, @param, @old_book_code, @new_book_code,
								@error_message = @message OUT
				IF @message IS NOT NULL RAISERROR 	20188 @message
			END
			ELSE
			BEGIN
				IF @depr_on_date < @depr_up_to
				BEGIN
					SELECT @param 		= CONVERT(varchar(255), @depr_on_date, 107)
				 	SELECT @depr_up_to 	= @depr_on_date

					EXEC	 	amGetErrorMessage_sp 
									20189, "tmp/amchkabk.sp", 239, 
									@asset_ctrl_num, @param, @new_book_code,
									@error_message = @message OUT
					IF @message IS NOT NULL RAISERROR 	20189 @message

				END
			END
		END
	END		
END

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amchkabk.sp" + ", line " + STR( 250, 5 ) + " -- EXIT: "

RETURN 0
GO
GRANT EXECUTE ON  [dbo].[amCheckAssetBook_sp] TO [public]
GO
