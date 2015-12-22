SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[amDepreciationReport_sp] 
( 	
	@classification_id	smSurrogateKey,			
	@book_code 			smBookCode, 			
	@start_asset		smControlNumber,		


	@end_asset			smControlNumber,		


	@include_assets		smCounter,				





	@period_start 		smISODate, 				
	@period_end 		smISODate, 				
	@start_cls_code		smClassificationCode,	
	@end_cls_code		smClassificationCode,	
	@include_null_cls	smLogical,				




	@exclude_cls_code	smClassificationCode = NULL,	
	@start_rule_code	smDeprRuleCode,			
	@end_rule_code		smDeprRuleCode,			
	@business_use_flag	smCounter,				




	@include_disposed	smLogical		= 0,	


	@start_org_id           smOrgId,
	@end_org_id             smOrgId,
	@debug_level		smDebugLevel	= 0		
) 
AS 

DECLARE 
	@result		 				smErrorCode,		
	@fiscal_period_start 		smApplyDate, 		
	@fiscal_period_end 			smApplyDate,		
	@co_asset_book_id 			smSurrogateKey, 	
	@cost 						smMoneyZero, 
	@accum_depr 				smMoneyZero, 
	@depr_expense				smMoneyZero, 
	@curr_precision				smallint,			
	@round_factor				float,	 			
	@company_id					smCompanyID 

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "amdeprrp.cpp" + ", line " + STR( 102, 5 ) + " -- ENTRY: "

IF @start_org_id  = '<Start>'
BEGIN
	SELECT 	@start_org_id  	= MIN(organization_id)
	FROM	Organization
END

IF @end_org_id = '<End>'
BEGIN
	SELECT 	@end_org_id  	= MAX(organization_id)
	FROM	Organization
END

SELECT 	@fiscal_period_start 	= CONVERT(datetime, @period_start)
SELECT 	@fiscal_period_end 		= CONVERT(datetime, @period_end)

EXEC @result = amGetCompanyID_sp
						@company_id OUTPUT
						
IF @result <> 0 
	RETURN @result



 
EXEC @result = amGetCurrencyPrecision_sp 
						@curr_precision 	OUTPUT,
						@round_factor 		OUTPUT 

IF @result <> 0 
	RETURN @result




























CREATE TABLE #selected_assets
(
	co_asset_book_id   	int,			
	org_id                  varchar (30),    
	classification_code	char(8)	NULL,	
	depr_rule_code		char(8),		
	recovery_period		float	NULL,	
	salvage_value		float,			
	ending_cost			float,			
	ending_accum_depr	float,			
	depr_expense		float			
)






EXEC @result = amDeprSelectAssets_sp
					@company_id,
					@classification_id,
					@book_code,
					@start_asset,
					@end_asset,
					@include_assets,
					@fiscal_period_start,
					@fiscal_period_end,
					@start_cls_code,
					@end_cls_code,
					@include_null_cls,
		 			@exclude_cls_code,
					@start_rule_code,
					@end_rule_code,
					@business_use_flag,
					@include_disposed,
					@start_org_id,
	                                @end_org_id,
					@debug_level 

IF @result <> 0 
	RETURN @result

SELECT 	@co_asset_book_id = MIN(co_asset_book_id)
FROM	#selected_assets

WHILE @co_asset_book_id IS NOT NULL
BEGIN 	

	SELECT  @cost 			= 0.0,
			@accum_depr 	= 0.0,
			@depr_expense 	= 0.0 
			
	


 
	EXEC @result = amGetPrfRep_sp 
							@co_asset_book_id,
				 			@fiscal_period_end,
							@curr_precision,
							@cost 				OUTPUT,
							@accum_depr 		OUTPUT 

	IF ( @result != 0 )
		RETURN @result 

	


	SELECT 	@depr_expense		= (SIGN(ISNULL(SUM(amount), 0.0)) * ROUND(ABS(ISNULL(SUM(amount), 0.0)) + 0.0000001, @curr_precision))
	FROM 	amvalues 
	WHERE 	co_asset_book_id 	= @co_asset_book_id 
	AND 	account_type_id  	= 5 
	AND 	apply_date 			BETWEEN @fiscal_period_start AND @fiscal_period_end 
	AND		posting_flag		= 1

	UPDATE 	#selected_assets 
	SET 	ending_cost 		= @cost,
			ending_accum_depr 	= -@accum_depr, 
			depr_expense 		= @depr_expense
	FROM 	#selected_assets  
	WHERE 	co_asset_book_id 	= @co_asset_book_id 

	


	SELECT 	@co_asset_book_id 	= MIN(co_asset_book_id)
	FROM	#selected_assets
	WHERE	co_asset_book_id	> @co_asset_book_id
END 

SELECT 
		a.asset_ctrl_num,
		a.org_id,
		a.asset_description,
		tmp.classification_code,
		tmp.depr_rule_code,
		dr.rule_description,
		dr.depr_method_id,
		dr.convention_id,
		dr.annual_depr_rate,
		tmp.recovery_period,
		ab.placed_in_service_date,
		tmp.salvage_value,
		a.business_usage,
		tmp.ending_cost,
		tmp.ending_accum_depr,
		tmp.depr_expense,
		business_cost 		= (SIGN(tmp.ending_cost * a.business_usage/100.00) * ROUND(ABS(tmp.ending_cost * a.business_usage/100.00) + 0.0000001, @curr_precision)),
		business_depr_exp	= (SIGN(tmp.depr_expense * a.business_usage/100.00) * ROUND(ABS(tmp.depr_expense * a.business_usage/100.00) + 0.0000001, @curr_precision))
FROM	#selected_assets tmp,
		amasset	a,
		amastbk ab,
		amdprrul dr,
		amOrganization_vw o
WHERE	a.co_asset_id 		= ab.co_asset_id
AND		ab.co_asset_book_id = tmp.co_asset_book_id
AND		tmp.depr_rule_code	= dr.depr_rule_code		
AND     a.org_id = o.org_id
ORDER BY tmp.classification_code, tmp.depr_rule_code, a.asset_ctrl_num
		

IF @debug_level >= 5
BEGIN
	SELECT 
			tmp.classification_code,
			tmp.depr_rule_code,
			a.asset_ctrl_num,
			a.org_id,
			ab.placed_in_service_date,
			a.business_usage
	FROM	#selected_assets tmp,
			amasset	a,
			amastbk ab,
			amOrganization_vw o
	WHERE	a.co_asset_id 		= ab.co_asset_id
	AND		ab.co_asset_book_id = tmp.co_asset_book_id
	AND     a.org_id = o.org_id
	ORDER BY tmp.classification_code, tmp.depr_rule_code, a.asset_ctrl_num

	SELECT 
			a.asset_ctrl_num,
			a.org_id,
			tmp.ending_cost,
			tmp.ending_accum_depr,
			tmp.depr_expense
	FROM	#selected_assets tmp,
			amasset	a,
			amastbk ab,
			amOrganization_vw o
	WHERE	a.co_asset_id 		= ab.co_asset_id
	AND		ab.co_asset_book_id = tmp.co_asset_book_id
	AND     a.org_id = o.org_id
	ORDER BY tmp.classification_code, tmp.depr_rule_code, a.asset_ctrl_num

	SELECT 	DISTINCT
			tmp.depr_rule_code,
			tmp.recovery_period,
			dr.depr_method_id,
			dr.convention_id,
			dr.annual_depr_rate,
			dr.service_life,
			dr.useful_life_end_date
	FROM	#selected_assets tmp,
			amdprrul dr
	WHERE	tmp.depr_rule_code	= dr.depr_rule_code		
	ORDER BY tmp.depr_rule_code
END

DROP TABLE #selected_assets 

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "amdeprrp.cpp" + ", line " + STR( 296, 5 ) + " -- EXIT: "

RETURN 
GO
GRANT EXECUTE ON  [dbo].[amDepreciationReport_sp] TO [public]
GO
