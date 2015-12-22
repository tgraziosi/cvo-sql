SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE [dbo].[amGetCurrentSalvageValue_sp] 
(	
	@co_asset_book_id 	smSurrogateKey, 	 
	@apply_date 		smApplyDate, 		 
	@acquired_date 		smApplyDate, 		 
	@salvage_value 		smMoneyZero OUTPUT,	 
	@debug_level		smDebugLevel	= 0	
)
AS 


DECLARE @message smErrorLongDesc 

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amcursv.sp" + ", line " + STR( 62, 5 ) + " -- ENTRY: " 

 
IF 	(@acquired_date IS NOT NULL)
AND (@apply_date < @acquired_date)
	SELECT @apply_date = @acquired_date 

SELECT 	@salvage_value 	= NULL 

SELECT 	@salvage_value 	= salvage_value 
FROM 	amdprhst 
WHERE 	co_asset_book_id 	= @co_asset_book_id 
AND 	effective_date 	= 
				(SELECT 	MAX(effective_date)
					FROM 	amdprhst 
					WHERE 	co_asset_book_id = @co_asset_book_id 
					AND 	effective_date 	<= @apply_date)


IF @salvage_value IS NULL
BEGIN 
	DECLARE		
		@param			smErrorParam,
		@asset_ctrl_num	smControlNumber,
		@book_code		smBookCode
				
	SELECT	@book_code			= ab.book_code,
			@asset_ctrl_num		= a.asset_ctrl_num
	FROM	amasset	a,
			amastbk ab
	WHERE	ab.co_asset_book_id	= @co_asset_book_id
	AND		ab.co_asset_id		= a.co_asset_id

	IF @book_code IS NOT NULL
	BEGIN
		SELECT		@param = RTRIM(CONVERT(char(255), @apply_date))
		
		EXEC 		amGetErrorMessage_sp 20026, "tmp/amcursv.sp", 103, @param, @asset_ctrl_num, @book_code, @error_message = @message OUT 
		IF @message IS NOT NULL RAISERROR 	20026 @message 
		RETURN 		20026 
	END
	ELSE
	BEGIN
		SELECT		@param = RTRIM(CONVERT(char(255), @co_asset_book_id))
		
		EXEC 		amGetErrorMessage_sp 20025, "tmp/amcursv.sp", 111, @param, @error_message = @message OUT 
		IF @message IS NOT NULL RAISERROR 	20025 @message 
		RETURN 		20025 
	END
END 


IF @debug_level >= 5
	SELECT @salvage_value 

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amcursv.sp" + ", line " + STR( 121, 5 ) + " -- EXIT: "

RETURN 0 
GO
GRANT EXECUTE ON  [dbo].[amGetCurrentSalvageValue_sp] TO [public]
GO
