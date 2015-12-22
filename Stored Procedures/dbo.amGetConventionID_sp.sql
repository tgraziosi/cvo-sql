SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE [dbo].[amGetConventionID_sp] 
(	
	@co_asset_book_id 	smSurrogateKey,			 
	@apply_date 		smApplyDate, 			
	@convention_id 		smConventionID OUTPUT,	
	@debug_level		smDebugLevel	= 0		
)
AS 

DECLARE @message smErrorLongDesc,
		@depr_rule_code	smDeprRuleCode 

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amconvid.sp" + ", line " + STR( 67, 5 ) + " -- ENTRY: " 

SELECT @convention_id = NULL 

SELECT 	@depr_rule_code 	= depr_rule_code 
FROM 	amdprhst 
WHERE 	co_asset_book_id 	= @co_asset_book_id 
AND 	effective_date 	= 
			(SELECT 	MAX(effective_date)
			FROM 		amdprhst 
			WHERE 		co_asset_book_id = @co_asset_book_id 
			AND 		effective_date <= @apply_date)

IF @depr_rule_code IS NOT NULL 
BEGIN 

	SELECT 	@convention_id = convention_id 
	FROM 	amdprrul 
	WHERE 	depr_rule_code 	= @depr_rule_code 

	IF @@rowcount = 0 
	BEGIN 
		EXEC 		amGetErrorMessage_sp 20027, "tmp/amconvid.sp", 89, @depr_rule_code, @error_message = @message OUT 
		IF @message IS NOT NULL RAISERROR 	20027 @message 
		RETURN 		20027 
	END 
END

ELSE  
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
		
		EXEC 		amGetErrorMessage_sp 20026, "tmp/amconvid.sp", 113, @param, @asset_ctrl_num, @book_code, @error_message = @message OUT 
		IF @message IS NOT NULL RAISERROR 	20026 @message 
		RETURN 		20026 
	END
	ELSE
	BEGIN
		SELECT		@param = RTRIM(CONVERT(char(255), @co_asset_book_id))
		
		EXEC 		amGetErrorMessage_sp 20025, "tmp/amconvid.sp", 121, @param, @error_message = @message OUT 
		IF @message IS NOT NULL RAISERROR 	20025 @message 
		RETURN 		20025 
	END

END 

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amconvid.sp" + ", line " + STR( 128, 5 ) + " -- EXIT: "

RETURN 0 
GO
GRANT EXECUTE ON  [dbo].[amGetConventionID_sp] TO [public]
GO
