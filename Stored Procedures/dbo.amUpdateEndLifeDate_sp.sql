SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[amUpdateEndLifeDate_sp] 
(
	@co_asset_book_id	smSurrogateKey, 	
	@placed_date 	 	smApplyDate, 
	@debug_level		smDebugLevel	= 0	
)
AS 

DECLARE 
	@result					smErrorCode, 
	@effective_date smApplyDate, 
	@depr_rule_code smDeprRuleCode, 
	@end_life_date smApplyDate,
	@old_end_life_date		smApplyDate 

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amupeld.sp" + ", line " + STR( 87, 5 ) + " -- ENTRY: "
	

SELECT @effective_date 	= MIN(effective_date)
FROM 	amdprhst 
WHERE 	co_asset_book_id 	= @co_asset_book_id 

WHILE @effective_date IS NOT NULL 
BEGIN 
	 
	SELECT 	@depr_rule_code 	= depr_rule_code,
			@old_end_life_date	= end_life_date
	FROM 	amdprhst 
	WHERE 	co_asset_book_id 	= @co_asset_book_id 
	AND effective_date 		= @effective_date 

	EXEC @result = amCalcEndLifeDate_sp 
						@depr_rule_code,
						@placed_date,
						@end_life_date 	OUTPUT,
						@debug_level	= @debug_level
	IF @result <> 0 
		RETURN @result 
		
	
	IF (@old_end_life_date <> @end_life_date)
	OR (	@old_end_life_date IS NULL 		
		AND @end_life_date IS NOT NULL)		
	BEGIN

		UPDATE amdprhst 
		SET end_life_date 		= @end_life_date,
				modified_by			= -1 * ABS(modified_by)		
		FROM 	amdprhst 
		WHERE 	co_asset_book_id 	= @co_asset_book_id 
		AND effective_date 		= @effective_date

		SELECT @result = @@error
		IF @result <> 0 
			RETURN @result 
	END

	SELECT @effective_date 	= MIN(effective_date)
	FROM 	amdprhst 
	WHERE 	co_asset_book_id 	= @co_asset_book_id 
	AND effective_date 		> @effective_date 
END 

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amupeld.sp" + ", line " + STR( 146, 5 ) + " -- EXIT: "

RETURN 0 
GO
GRANT EXECUTE ON  [dbo].[amUpdateEndLifeDate_sp] TO [public]
GO
