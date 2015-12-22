SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[amCreateAssetBooks_sp] 
(
 @company_id				smCompanyID,			
 @co_asset_id 	smSurrogateKey, 		
	@category_code 			smCategoryCode, 		
	@acq_date 				smApplyDate, 			 
	@placed_date 			smApplyDate, 			 
	@cost 					smMoneyZero, 			 
	@user_id 				smUserID, 
	@org_id				smOrgId,				
	@debug_level			smDebugLevel	= 0		
)
AS 

DECLARE 
	@result					smErrorCode,
	@message 				smErrorLongDesc,
	@param					smErrorParam, 
	@asset_ctrl_num			smControlNumber, 
	@book_code 				smBookCode, 
	@co_asset_book_id 		smSurrogateKey, 
	@salvage 				smMoneyZero, 
	@ts 					timestamp 
 
IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amcrasbk.sp" + ", line " + STR( 209, 5 ) + " -- ENTRY: "

 
SELECT 	@book_code 		= MIN(book_code)
FROM 	amcatbk 
WHERE 	category_code 	= @category_code 
AND		@acq_date		>= effective_date


IF @book_code IS NULL
BEGIN

	SELECT	@asset_ctrl_num	= asset_ctrl_num
	FROM	amasset
	WHERE	co_asset_id		= @co_asset_id
	
	IF @asset_ctrl_num IS NOT NULL
	BEGIN
		SELECT		@param = RTRIM(CONVERT(char(255), @acq_date, 107))
	
		EXEC	 	amGetErrorMessage_sp 20076, "tmp/amcrasbk.sp", 234, @category_code, @asset_ctrl_num, @param, @error_message = @message OUT 
		IF @message IS NOT NULL RAISERROR 	20076 @message 
		RETURN 		20076 
	END
	ELSE
	BEGIN
		SELECT		@param = RTRIM(CONVERT(char(255), @co_asset_id))
		
		EXEC	 	amGetErrorMessage_sp 20030, "tmp/amcrasbk.sp", 242, @param, @error_message = @message OUT 
		IF @message IS NOT NULL RAISERROR 	20030 @message 
		RETURN 		20030 
	END
END

 
WHILE @book_code IS NOT NULL 
BEGIN 
	
	IF @debug_level >= 5
		SELECT book_code = @book_code 

	 
	EXEC @result = amNextKey_sp 
					6, 
					@co_asset_book_id OUTPUT

	IF @result <> 0 
		RETURN @result 

	INSERT INTO amastbk 
	(
			co_asset_id,
			book_code,
			co_asset_book_id,
			orig_salvage_value,
			orig_amount_capitalised,
			next_entered_activity_date,
			placed_in_service_date
	)
	VALUES 
	(
			@co_asset_id, 
			@book_code,
			@co_asset_book_id,
			0,
			@cost,
			@acq_date,
			@placed_date
	)

	SELECT @result = @@error 
	IF @result <> 0 
		RETURN @result 

	
	EXEC @result = amCreateNewRule_sp
					@co_asset_book_id,
					@book_code,
					@acq_date,
					@category_code,
					@user_id,
					@placed_date

	IF @result <> 0
		RETURN @result
						
	
	UPDATE	amastbk
	SET		orig_salvage_value 	= salvage_value
	FROM	amdprhst dh,
			amastbk ab
	WHERE	dh.co_asset_book_id	= ab.co_asset_book_id
	AND		dh.effective_date	= @acq_date	
	AND		dh.co_asset_book_id	= @co_asset_book_id
	
	SELECT @result = @@error 
	IF @result <> 0 
		RETURN @result 

	 
	SELECT 	@book_code 		= MIN(book_code)
	FROM 	amcatbk 
	WHERE 	category_code 	= @category_code 
	AND 	book_code 		> @book_code 
	AND		@acq_date		>= effective_date

END 

 
EXEC @result = amActivityNew_sp 
				@company_id,
				@co_asset_id,
				@acq_date, 
				10, 
				@cost,
				@user_id,
				@org_id, 
				@debug_level 
IF @result <> 0 
	RETURN @result 

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amcrasbk.sp" + ", line " + STR( 348, 5 ) + " -- EXIT: "

RETURN 0
GO
GRANT EXECUTE ON  [dbo].[amCreateAssetBooks_sp] TO [public]
GO
