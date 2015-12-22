SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[amDeprSelectAssets_sp] 
( 	
	@company_id				smCompanyID,			 
	@classification_id		smSurrogateKey,			
	@book_code 				smBookCode, 			
	@start_asset			smControlNumber,		


	@end_asset				smControlNumber,		


	@include_assets			smCounter,				





	@fiscal_period_start 	smApplyDate, 			
	@fiscal_period_end 		smApplyDate,			
	@start_cls_code			smClassificationCode,	
	@end_cls_code			smClassificationCode,	
	@include_null_cls		smLogical,				




	@exclude_cls_code		smClassificationCode,	
	@start_rule_code		smDeprRuleCode,			
	@end_rule_code			smDeprRuleCode,			
	@business_use_flag  	smCounter,				




	@include_disposed		smLogical		= 0,	


	@start_org_id                   smOrgId,
	@end_org_id                     smOrgId,
	@debug_level			smDebugLevel	= 0		
) 
AS 

DECLARE 
	@result		 				smErrorCode,		
	@jul_start_placed_date 		smJulianDate, 		
	@start_placed_date	 		smApplyDate, 		
	@end_placed_date 			smApplyDate			

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "amdprsel.cpp" + ", line " + STR( 102, 5 ) + " -- ENTRY: "




IF RTRIM(@start_asset) = "<Start>"
BEGIN
	SELECT 	@start_asset 	= MIN(asset_ctrl_num)
	FROM	amasset
	WHERE	company_id		= @company_id AND
	        org_id    BETWEEN  @start_org_id AND @end_org_id 
END

IF RTRIM(@end_asset) = "<End>"
BEGIN
	SELECT 	@end_asset 		= MAX(asset_ctrl_num)
	FROM	amasset
	WHERE	company_id		= @company_id AND
	        org_id    BETWEEN  @start_org_id AND @end_org_id
END

IF @debug_level >= 5
	SELECT 	start_asset 	= @start_asset,
			end_asset  		= @end_asset

IF RTRIM(@start_cls_code) = "<Start>"
BEGIN
	SELECT 	@start_cls_code 	= MIN(classification_code)
	FROM	amcls
	WHERE	company_id	   		= @company_id
	AND		classification_id	= @classification_id
END

IF RTRIM(@end_cls_code) = "<End>"
BEGIN
	SELECT 	@end_cls_code 		= MAX(classification_code)
	FROM	amcls
	WHERE	company_id			= @company_id
	AND		classification_id	= @classification_id
END

IF @debug_level >= 5
	SELECT 	start_cls_code 	= @start_cls_code,
			end_cls_code  	= @end_cls_code

IF @include_assets = 0
	SELECT	@start_placed_date 	= @fiscal_period_start,
			@end_placed_date	= @fiscal_period_end
ELSE 
BEGIN
	



	SELECT	@jul_start_placed_date = MIN(period_start_date)
	FROM	glprd
	
	IF @include_assets = 1
		SELECT	@start_placed_date 	= DATEADD(dd, @jul_start_placed_date - 722815, "1/1/1980"),
				@end_placed_date	= DATEADD(dd, -1, @fiscal_period_start)
	ELSE
		SELECT	@start_placed_date 	= DATEADD(dd, @jul_start_placed_date - 722815, "1/1/1980"),
				@end_placed_date	= @fiscal_period_end
	
END


IF @debug_level >= 5
	SELECT 	start_placed_date 	= @start_placed_date,
			end_placed_date  	= @end_placed_date

IF @include_null_cls = 1
BEGIN
	IF @exclude_cls_code IS NOT NULL
	BEGIN
		




		INSERT INTO #selected_assets
		(
				co_asset_book_id,
				org_id,
				classification_code,
				depr_rule_code,
				recovery_period,
				salvage_value,
				ending_cost,
				ending_accum_depr,
				depr_expense
		)
		SELECT
				ab.co_asset_book_id,
				a.org_id,				
				ac.classification_code,
				"",
				NULL,
				0.0,
				0.0,
				0.0,
				0.0
		FROM 	amasset a LEFT OUTER JOIN amastcls ac 	ON (a.co_asset_id = ac.co_asset_id 		
								AND	ac.company_id			= @company_id
								AND	ac.classification_id		= @classification_id
								AND	ac.classification_code		BETWEEN @start_cls_code AND @end_cls_code)
			INNER JOIN amastbk ab 			ON a.co_asset_id = ab.co_asset_id
		WHERE 	a.company_id				= @company_id
		AND		a.asset_ctrl_num		BETWEEN @start_asset AND @end_asset
		AND             a.org_id                        BETWEEN  @start_org_id AND @end_org_id 
		AND		ab.book_code 			= @book_code
		AND		ab.placed_in_service_date	BETWEEN @start_placed_date AND @end_placed_date



		SELECT @result = @@error
		IF @result <> 0 
			RETURN @result

		



		DELETE 	
		FROM	#selected_assets 
		WHERE 	classification_code		= @exclude_cls_code

		SELECT @result = @@error
		IF @result <> 0 
			RETURN @result

		
		
	END
	ELSE
	BEGIN
		





		INSERT INTO #selected_assets
		(
				co_asset_book_id,
				org_id,
				classification_code,
				depr_rule_code,
				recovery_period,
				salvage_value,
				ending_cost,
				ending_accum_depr,
				depr_expense
		)
		SELECT
				ab.co_asset_book_id,
				a.org_id,
				ac.classification_code,
				"",
				NULL,
				0.0,
				0.0,
				0.0,
				0.0
		FROM 	amasset a LEFT OUTER JOIN amastcls ac 	ON (a.co_asset_id = ac.co_asset_id
							 		AND		ac.company_id			= @company_id
									AND		ac.classification_id		= @classification_id
									AND		ac.classification_code		BETWEEN @start_cls_code AND @end_cls_code)
			INNER JOIN amastbk ab 			ON a.co_asset_id = ab.co_asset_id
		WHERE 	a.company_id				= @company_id
		AND		a.asset_ctrl_num		BETWEEN @start_asset AND @end_asset
		AND             a.org_id                        BETWEEN  @start_org_id AND @end_org_id
		AND		ab.book_code 			= @book_code
		AND		ab.placed_in_service_date	BETWEEN @start_placed_date AND @end_placed_date

		SELECT @result = @@error
		IF @result <> 0 
			RETURN @result
	END
END
ELSE
BEGIN
	IF @exclude_cls_code IS NOT NULL
	BEGIN
		






		INSERT INTO #selected_assets
		(
				co_asset_book_id,
				org_id,
				classification_code,
				depr_rule_code,
				recovery_period,
				salvage_value,
				ending_cost,
				ending_accum_depr,
				depr_expense
		)
		SELECT
				ab.co_asset_book_id,
				a.org_id,
				ac.classification_code,
				"",
				NULL,
				0.0,
				0.0,
				0.0,
				0.0
		FROM 	amastbk ab,
				amasset a,
				amastcls ac	
		WHERE 	a.company_id				= @company_id
		AND		a.asset_ctrl_num			BETWEEN @start_asset AND @end_asset
		AND             a.org_id                        BETWEEN  @start_org_id AND @end_org_id		
		AND		a.co_asset_id				= ab.co_asset_id
		AND		ab.book_code 				= @book_code
		AND		ab.placed_in_service_date	BETWEEN @start_placed_date AND @end_placed_date
		AND		a.co_asset_id				= ac.co_asset_id
		AND		ac.company_id				= @company_id
		AND		ac.classification_id		= @classification_id
		AND		ac.classification_code		BETWEEN @start_cls_code AND @end_cls_code
		AND		ac.classification_code		!= @exclude_cls_code

		SELECT @result = @@error
		IF @result <> 0 
			RETURN @result
	END
	ELSE
	BEGIN
		





		INSERT INTO #selected_assets
		(
				co_asset_book_id,
				org_id,
				classification_code,
				depr_rule_code,
				recovery_period,
				salvage_value,
				ending_cost,
				ending_accum_depr,
				depr_expense
		)
		SELECT
				ab.co_asset_book_id,
				a.org_id,
				ac.classification_code,
				"",
				NULL,
				0.0,
				0.0,
				0.0,
				0.0
		FROM 	amastbk ab,
				amasset a,
				amastcls ac	
		WHERE 	a.company_id				= @company_id
		AND		a.asset_ctrl_num			BETWEEN @start_asset AND @end_asset
		AND             a.org_id                        BETWEEN  @start_org_id AND @end_org_id		
		AND		a.co_asset_id				= ab.co_asset_id
		AND		ab.book_code 				= @book_code
		AND		ab.placed_in_service_date	BETWEEN @start_placed_date AND @end_placed_date
		AND		a.co_asset_id				= ac.co_asset_id
		AND		ac.company_id				= @company_id
		AND		ac.classification_id		= @classification_id
		AND		ac.classification_code		BETWEEN @start_cls_code AND @end_cls_code

		SELECT @result = @@error
		IF @result <> 0 
			RETURN @result
	END
END




IF @business_use_flag != 0
BEGIN
	IF @business_use_flag = 1
	BEGIN
		


		DELETE #selected_assets
		FROM	#selected_assets tmp,
				amasset a,
				amastbk ab
		WHERE	tmp.co_asset_book_id 	= ab.co_asset_book_id
		AND		ab.co_asset_id			= a.co_asset_id
		AND		a.business_usage		!= 100.00
	
		SELECT @result = @@error
		IF @result <> 0 
			RETURN @result

	END
	ELSE
	BEGIN
		


		DELETE 	#selected_assets
		FROM	#selected_assets tmp,
				amasset a,
				amastbk ab
		WHERE	tmp.co_asset_book_id 	= ab.co_asset_book_id
		AND		ab.co_asset_id			= a.co_asset_id
		AND		a.business_usage		= 100.00
	
		SELECT @result = @@error
		IF @result <> 0 
			RETURN @result

	END
END

IF @include_disposed = 0
BEGIN
	


	DELETE 	#selected_assets
	FROM	#selected_assets tmp,
			amasset a,
			amastbk ab
	WHERE	tmp.co_asset_book_id 	= ab.co_asset_book_id
	AND		ab.co_asset_id			= a.co_asset_id
	AND		a.activity_state		= 101

	SELECT @result = @@error
	IF @result <> 0 
		RETURN @result
END





UPDATE 	#selected_assets
SET		depr_rule_code 			= dh.depr_rule_code,
		salvage_value			= dh.salvage_value
FROM	#selected_assets tmp,
		amdprhst	dh
WHERE	tmp.co_asset_book_id 	= dh.co_asset_book_id
AND		dh.effective_date		= (SELECT 	MAX(effective_date)
									FROM	amdprhst
									WHERE	co_asset_book_id 	= dh.co_asset_book_id
									AND		effective_date		<= @fiscal_period_end)

SELECT @result = @@error
IF @result <> 0 
	RETURN @result

IF 	RTRIM(@start_rule_code) != "<Start>"
OR	RTRIM(@end_rule_code) != "<End>"
BEGIN
	IF 	RTRIM(@end_rule_code) != "<End>"
	BEGIN
		


		DELETE 	#selected_assets
		WHERE	depr_rule_code 	> @end_rule_code

		SELECT @result = @@error
		IF @result <> 0 
			RETURN @result
	END
	
	IF 	RTRIM(@start_rule_code) != "<Start>"
	BEGIN
		


		DELETE 	#selected_assets
		WHERE	depr_rule_code 	< @start_rule_code

		SELECT @result = @@error
		IF @result <> 0 
			RETURN @result
	END
END

















UPDATE 	#selected_assets
SET		recovery_period 	= service_life
FROM	#selected_assets tmp,
		amdprrul dr
WHERE	tmp.depr_rule_code 	= dr.depr_rule_code
AND		((dr.depr_method_id	IN (4, 5))
		OR (	dr.depr_method_id	   = 2
			AND dr.useful_life_end_date IS NULL))

SELECT @result = @@error
IF @result <> 0 
	RETURN @result

UPDATE 	#selected_assets
SET		recovery_period 		= (SIGN(100.00/annual_depr_rate) * ROUND(ABS(100.00/annual_depr_rate) + 0.0000001, 4))
FROM	#selected_assets tmp,
		amdprrul dr
WHERE	tmp.depr_rule_code 		= dr.depr_rule_code
AND		dr.depr_method_id		IN (1, 3) 
AND 	dr.useful_life_end_date IS NULL
AND		dr.annual_depr_rate 	!= 0.00

SELECT @result = @@error
IF @result <> 0 
	RETURN @result






UPDATE 	#selected_assets
SET		recovery_period 		= (SIGN((DATEDIFF(dd, ab.first_depr_date, dr.useful_life_end_date)) / 365.00) * ROUND(ABS((DATEDIFF(dd, ab.first_depr_date, dr.useful_life_end_date)) / 365.00) + 0.0000001, 4)) 
FROM	#selected_assets tmp,
		amdprrul dr,
		amastbk ab
WHERE	ab.co_asset_book_id		= tmp.co_asset_book_id
AND		tmp.depr_rule_code 		= dr.depr_rule_code
AND		dr.depr_method_id		= 2 
AND 	dr.useful_life_end_date IS NOT NULL

SELECT @result = @@error
IF @result <> 0 
	RETURN @result





UPDATE 	#selected_assets
SET		recovery_period 		= (SIGN(100.00/annual_depr_rate) * ROUND(ABS(100.00/annual_depr_rate) + 0.0000001, 4)) 
FROM	#selected_assets tmp,
		amdprrul dr
WHERE	tmp.depr_rule_code 		= dr.depr_rule_code
AND		dr.depr_method_id		= 3 
AND 	dr.useful_life_end_date IS NOT NULL
AND 	dr.annual_depr_rate		!= 0.00

SELECT @result = @@error
IF @result <> 0 
	RETURN @result

UPDATE 	#selected_assets
SET		recovery_period 		= (SIGN((DATEDIFF(dd, ab.first_depr_date, dr.useful_life_end_date)) / 365.00) * ROUND(ABS((DATEDIFF(dd, ab.first_depr_date, dr.useful_life_end_date)) / 365.00) + 0.0000001, 4)) 
FROM	#selected_assets tmp,
		amdprrul dr,
		amastbk ab
WHERE	ab.co_asset_book_id		= tmp.co_asset_book_id
AND		tmp.depr_rule_code 		= dr.depr_rule_code
AND		dr.depr_method_id		= 3 
AND 	dr.useful_life_end_date IS NOT NULL
AND		tmp.recovery_period		> (SIGN((DATEDIFF(dd, ab.first_depr_date, dr.useful_life_end_date)) / 365.00) * ROUND(ABS((DATEDIFF(dd, ab.first_depr_date, dr.useful_life_end_date)) / 365.00) + 0.0000001, 4))

SELECT @result = @@error
IF @result <> 0 
	RETURN @result


IF @debug_level >= 5
	SELECT	a.asset_ctrl_num,
	        a.org_id,
			ab.placed_in_service_date, 
			ab.first_depr_date, 
			tmp.depr_rule_code,
			tmp.recovery_period,
			tmp.salvage_value,
			dr.useful_life_end_date,
			dr.annual_depr_rate
	FROM	#selected_assets tmp,
			amasset a,
			amastbk ab,
			amdprrul dr
	WHERE	a.co_asset_id 			= ab.co_asset_id
	AND		tmp.co_asset_book_id	= ab.co_asset_book_id
	AND		tmp.depr_rule_code		= dr.depr_rule_code
	ORDER BY a.asset_ctrl_num


IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "amdprsel.cpp" + ", line " + STR( 608, 5 ) + " -- EXIT: "

RETURN 
GO
GRANT EXECUTE ON  [dbo].[amDeprSelectAssets_sp] TO [public]
GO
