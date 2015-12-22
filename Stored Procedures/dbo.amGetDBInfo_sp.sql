SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[amGetDBInfo_sp] 
(
 @co_asset_book_id 	smSurrogateKey, 		
 @apply_date 	smApplyDate, 			
 @annual_depr_rate 	smRate 		OUTPUT,	 	
 @service_life 	smLife 			OUTPUT,	
	@debug_level		smDebugLevel 	= 0 	
)
AS 

DECLARE 									
	@message 	smErrorLongDesc, 		
	@param				smErrorParam,			
	@depr_rule_code 	smDeprRuleCode, 		
	@rowcount 			smCounter, 					
	@asset_ctrl_num		smControlNumber,		
	@book_code			smBookCode				

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amdbinfo.sp" + ", line " + STR( 61, 5 ) + " -- ENTRY: "

IF @debug_level >= 5
	SELECT 	co_asset_book_id 	= @co_asset_book_id,
			apply_date 			= @apply_date

 
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
	 
 SELECT 	@annual_depr_rate	= annual_depr_rate,
 		@service_life		= service_life 
	FROM amdprrul 
	WHERE 	depr_rule_code 		= @depr_rule_code 
	
	SELECT	@rowcount = @@rowcount

	IF @rowcount = 0 
	BEGIN 
		EXEC 		amGetErrorMessage_sp 20027, "tmp/amdbinfo.sp", 93, @depr_rule_code, @error_message = @message OUT 
		IF @message IS NOT NULL RAISERROR 	20027 @message 
		RETURN 		20027 
	END 

END 
ELSE  
BEGIN 
				
	SELECT	@book_code			= ab.book_code,
			@asset_ctrl_num		= a.asset_ctrl_num
	FROM	amasset	a,
			amastbk ab,
			amOrganization_vw o
	WHERE	ab.co_asset_book_id	= @co_asset_book_id
	AND		ab.co_asset_id		= a.co_asset_id
	AND     a.org_id  = o.org_id

	IF @book_code IS NOT NULL
	BEGIN
		SELECT		@param = RTRIM(CONVERT(char(255), @apply_date))
		
		EXEC 		amGetErrorMessage_sp 20026, "tmp/amdbinfo.sp", 113, @param, @asset_ctrl_num, @book_code, @error_message = @message OUT 
		IF @message IS NOT NULL RAISERROR 	20026 @message 
		RETURN 		20026 
	END
	ELSE
	BEGIN
		SELECT		@param = RTRIM(CONVERT(char(255), @co_asset_book_id))
		
		EXEC 		amGetErrorMessage_sp 20025, "tmp/amdbinfo.sp", 121, @param, @error_message = @message OUT 
		IF @message IS NOT NULL RAISERROR 	20025 @message 
		RETURN 		20025 
	END

END 


IF @debug_level >= 3
	SELECT 	annual_depr_rate 	= @annual_depr_rate,
			service_life 		= @service_life 
IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amdbinfo.sp" + ", line " + STR( 132, 5 ) + " -- EXIT: "

RETURN 0 
GO
GRANT EXECUTE ON  [dbo].[amGetDBInfo_sp] TO [public]
GO
