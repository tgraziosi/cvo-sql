SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[amCalcEndLifeDate_sp] 
(
 @depr_rule_code 	smDeprRuleCode, 		
	@placed_date 		smApplyDate, 			 
	@end_life_date 		smApplyDate = NULL OUT,	
	@debug_level		smDebugLevel	= 0		
)
AS 

DECLARE 
	@ret_status 		smErrorCode, 
	@convention_id 		smConventionID, 		
	@depr_method_id 	smDeprMethodID, 
	@service_life 		smLife, 
	@end_useful_life 	smApplyDate, 
	@service_years 		int, 
	@service_days 		int 

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amclceld.sp" + ", line " + STR( 119, 5 ) + " -- ENTRY: "

IF @debug_level >= 5
	SELECT 	depr_rule_code 	= @depr_rule_code,
			placed 			= @placed_date 

SELECT 	@depr_method_id 	= depr_method_id,
		@convention_id		= convention_id,
		@service_life 		= service_life,
		@end_useful_life 	= useful_life_end_date 
FROM 	amdprrul 
WHERE 	depr_rule_code 		= @depr_rule_code 

IF @debug_level >= 5
	SELECT 	depr_method_id 	= @depr_method_id,
			service_life 	= @service_life,
			end_useful_life = @end_useful_life 

IF (@depr_method_id = 2) 
OR (@depr_method_id = 3)
OR (@depr_method_id = 5)
BEGIN 
	IF @end_useful_life IS NOT NULL 
		SELECT @end_life_date = @end_useful_life 
	ELSE 
	BEGIN 
		IF @placed_date IS NOT NULL
		BEGIN
			EXEC 	@ret_status = amGetConventionDate_sp 
									@placed_date, 
									@convention_id, 
									@end_life_date OUT 
			IF @ret_status <> 0 
				RETURN @ret_status 
				
			 
			SELECT 	@service_years = @service_life 
			SELECT 	@end_life_date = DATEADD(yy, @service_years, @end_life_date)
			
			 
			SELECT 	@service_days = (@service_life - @service_years) * 365 
			SELECT 	@end_life_date = DATEADD(dd, @service_days, @end_life_date)
			
			 
			SELECT 	@end_life_date = DATEADD(dd, -1, @end_life_date)
		END
		ELSE
			SELECT @end_life_date = NULL 
	END 
END 
ELSE 
	SELECT @end_life_date = @end_useful_life 

IF @debug_level >= 5
	SELECT end_life_date = @end_life_date 

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amclceld.sp" + ", line " + STR( 175, 5 ) + " -- EXIT: "

RETURN 0 
GO
GRANT EXECUTE ON  [dbo].[amCalcEndLifeDate_sp] TO [public]
GO
