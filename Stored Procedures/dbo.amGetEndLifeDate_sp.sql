SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE [dbo].[amGetEndLifeDate_sp] 
(
	@co_asset_book_id 	smSurrogateKey, 	
	@apply_date 		smApplyDate, 		
	@end_life_date 		smApplyDate OUTPUT,	
	@debug_level		smDebugLevel	= 0	
)
AS 


DECLARE 
	@result				smErrorCode,		
	@message 	 	smErrorLongDesc,	
	@param				smErrorParam,		
	@placed_date		smApplyDate,		
	@depr_rule_code		smDeprRuleCode,		
	@asset_ctrl_num		smControlNumber,	
	@book_code			smBookCode			

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amedlfdt.sp" + ", line " + STR( 69, 5 ) + " -- ENTRY: " 

IF @debug_level >= 5
	SELECT	co_asset_book_id 	= @co_asset_book_id,
			apply_date 			= @apply_date
	
SELECT 	@end_life_date = NULL 

SELECT 	@end_life_date 	= end_life_date 
FROM 	amdprhst 
WHERE 	co_asset_book_id 	= @co_asset_book_id 
AND 	effective_date 	= 
			(SELECT MAX(effective_date)
			FROM 	amdprhst 
			WHERE 	co_asset_book_id = @co_asset_book_id 
			AND 	effective_date 	<= @apply_date)

IF ( @@rowcount = 0 )
BEGIN 
				
	SELECT	@book_code			= ab.book_code,
			@asset_ctrl_num		= a.asset_ctrl_num
	FROM	amasset	a,
			amastbk ab,
			amOrganization_vw o
	WHERE	ab.co_asset_book_id	= @co_asset_book_id
	AND		ab.co_asset_id		= a.co_asset_id
	AND     a.org_id   =  o.org_id

	IF @book_code IS NOT NULL
	BEGIN
		SELECT		@param = RTRIM(CONVERT(char(255), @apply_date))
		
		EXEC 		amGetErrorMessage_sp 20026, "tmp/amedlfdt.sp", 100, @param, @asset_ctrl_num, @book_code, @error_message = @message OUT 
		IF @message IS NOT NULL RAISERROR 	20026 @message 
		RETURN 		20026 
	END
	ELSE
	BEGIN
		SELECT		@param = RTRIM(CONVERT(char(255), @co_asset_book_id))
		
		EXEC 		amGetErrorMessage_sp 20025, "tmp/amedlfdt.sp", 108, @param, @error_message = @message OUT 
		IF @message IS NOT NULL RAISERROR 	20025 @message 
		RETURN 		20025 
	END

END 

IF @end_life_date IS NULL
BEGIN
	
	SELECT	@placed_date		= placed_in_service_date
	FROM	amastbk
	WHERE	co_asset_book_id	= @co_asset_book_id

	EXEC @result = amUpdateEndLifeDate_sp 
 						@co_asset_book_id,
							@placed_date,
							@debug_level 							
	IF @result <> 0 
		RETURN @result

	
	SELECT 	@end_life_date 	= end_life_date,
			@depr_rule_code		= depr_rule_code 
	FROM 	amdprhst 
	WHERE 	co_asset_book_id 	= @co_asset_book_id 
	AND 	effective_date 	= 
				(SELECT MAX(effective_date)
				FROM 	amdprhst 
				WHERE 	co_asset_book_id = @co_asset_book_id 
				AND 	effective_date 	<= @apply_date)

	IF @end_life_date IS NULL
	BEGIN
		SELECT	@book_code			= ab.book_code,
				@asset_ctrl_num		= a.asset_ctrl_num
		FROM	amasset	a,
				amastbk ab,
				amOrganization_vw o
		WHERE	ab.co_asset_book_id	= @co_asset_book_id
		AND		ab.co_asset_id		= a.co_asset_id
		AND     a.org_id  = o.org_id
		
		EXEC 		amGetErrorMessage_sp 
						20207, "tmp/amedlfdt.sp", 158, 
						@asset_ctrl_num, @book_code, @depr_rule_code,
						@error_message = @message OUT 
		IF @message IS NOT NULL RAISERROR 	20207 @message 
		RETURN 		20207 
	END
		
END


IF @debug_level >= 5
	SELECT @end_life_date 

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amedlfdt.sp" + ", line " + STR( 171, 5 ) + " -- EXIT: "

RETURN 0
GO
GRANT EXECUTE ON  [dbo].[amGetEndLifeDate_sp] TO [public]
GO
