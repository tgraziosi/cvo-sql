SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE [dbo].[amGetRate_sp] 
(
 @co_asset_book_id 	smSurrogateKey, 		
 @apply_date 	smApplyDate, 			
 	@rate_type 	 		tinyint,				
 @rate 	smRate = NULL OUTPUT, 	
	@debug_level			smDebugLevel	= 0		
)
AS 

DECLARE 
	@message smErrorLongDesc, 
	@depr_rule_code smDeprRuleCode, 
	@rowcount 		smCounter 

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amrate.sp" + ", line " + STR( 74, 5 ) + " -- ENTRY: " 

IF @debug_level >= 3
	SELECT 	co_asset_book_id 	= @co_asset_book_id,
			apply_date 			= @apply_date,
			rate_type 			= @rate_type 
 

 
SELECT @depr_rule_code 		= depr_rule_code 
FROM amdprhst 
WHERE co_asset_book_id 	= @co_asset_book_id 
AND effective_date = 
			(SELECT 	MAX(effective_date)
				FROM 	amdprhst 
				WHERE 	co_asset_book_id 	= @co_asset_book_id 
				AND 	effective_date 		<= @apply_date)

 
IF @depr_rule_code IS NOT NULL 
BEGIN 
	IF (@rate_type = 0)
	BEGIN 
	 SELECT 	@rate 			= annual_depr_rate 
		FROM amdprrul 
		WHERE 	depr_rule_code 	= @depr_rule_code 
	END 
	ELSE 
	BEGIN 
		IF (@rate_type = 1)
		BEGIN 
		 SELECT 	@rate 			= first_year_depr_rate 
			FROM amdprrul 
			WHERE 	depr_rule_code 	= @depr_rule_code 
		END 
		ELSE  
		BEGIN 
		 SELECT 	@rate 			= immediate_depr_rate 
			FROM amdprrul 
			WHERE 	depr_rule_code 	= @depr_rule_code 
		END 
	END 
	
	IF @rate IS NULL 
	BEGIN 
		EXEC 		amGetErrorMessage_sp 20027, "tmp/amrate.sp", 119, @depr_rule_code, @error_message = @message OUT 
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
			amastbk ab,
			amOrganization_vw  o
	WHERE	ab.co_asset_book_id	= @co_asset_book_id
	AND		ab.co_asset_id		= a.co_asset_id
	AND     a.org_id  = o.org_id      

	IF @book_code IS NOT NULL
	BEGIN
		SELECT		@param = RTRIM(CONVERT(char(255), @apply_date))
		
		EXEC 		amGetErrorMessage_sp 20026, "tmp/amrate.sp", 143, @param, @asset_ctrl_num, @book_code, @error_message = @message OUT 
		IF @message IS NOT NULL RAISERROR 	20026 @message 
		RETURN 		20026 
	END
	ELSE
	BEGIN
		SELECT		@param = RTRIM(CONVERT(char(255), @co_asset_book_id))
		
		EXEC 		amGetErrorMessage_sp 20025, "tmp/amrate.sp", 151, @param, @error_message = @message OUT 
		IF @message IS NOT NULL RAISERROR 	20025 @message 
		RETURN 		20025 
	END

END 


IF @debug_level >= 3
	SELECT rate = @rate 

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amrate.sp" + ", line " + STR( 162, 5 ) + " -- EXIT: "

RETURN 0 
GO
GRANT EXECUTE ON  [dbo].[amGetRate_sp] TO [public]
GO
