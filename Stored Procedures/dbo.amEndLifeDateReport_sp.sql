SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE [dbo].[amEndLifeDateReport_sp] 
( 	


	@include_fully_depr	smLogical,				


	@start_date			datetime,				
	@end_date			datetime,				
	@sort_by_asset		int,				


	@debug_level		smDebugLevel	= 0		

)
AS 

DECLARE 
	@result					smErrorCode,
	@apply_date				smApplyDate,
	@curr_precision			smallint,
	@round_factor			float,
	@co_asset_book_id		smSurrogateKey,
	@placed_date			smApplyDate,
	@adjusted_placed_date	smApplyDate,
	@convention_id			smConventionID

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "ameldrep.cpp" + ", line " + STR( 76, 5 ) + " -- ENTRY: "



 
EXEC @result = amGetCurrencyPrecision_sp 
						@curr_precision 	OUTPUT,
						@round_factor 		OUTPUT 

IF @result <> 0 
	RETURN @result



































































UPDATE 	#end_life_date
SET		depr_rule_code 			= dh.depr_rule_code,
		depr_method_id			= dr.depr_method_id,
		convention_id			= dr.convention_id,
		salvage_value			= dh.salvage_value,
		end_life_date			= dh.end_life_date
FROM	#end_life_date tmp,
		amdprhst	dh,
		amdprrul	dr
WHERE	tmp.co_asset_book_id 	= dh.co_asset_book_id
AND		dh.depr_rule_code		= dr.depr_rule_code
AND		dh.effective_date		= (SELECT 	MAX(effective_date)
									FROM	amdprhst hst,
											amastbk ab,
											amasset a
									WHERE	hst.co_asset_book_id 	= dh.co_asset_book_id
									AND		hst.co_asset_book_id 	= ab.co_asset_book_id
									AND		ab.co_asset_book_id 	= dh.co_asset_book_id
									AND		ab.co_asset_id 			= a.co_asset_id
									AND		effective_date			<= ISNULL(ab.last_posted_depr_date, a.acquisition_date))

SELECT @result = @@error
IF @result <> 0 
	RETURN @result

IF @debug_level >= 5
	SELECT	 
			a.asset_ctrl_num, 
			tmp.depr_rule_code,
			tmp.depr_method_id,
			tmp.convention_id,
			placed_date 		= convert(char(12), tmp.placed_date, 106),
			last_depr_date 		= convert(char(12), tmp.last_depr_date, 106),
			fully_depreciated,
			tmp.slp_years_remaining,
			slp_end_life_date 	= convert(char(12), tmp.slp_end_life_date, 106),
			end_life_date 		= convert(char(12), tmp.end_life_date, 106)
	FROM	#end_life_date tmp,
			amasset a,
			amastbk ab
	WHERE	a.co_asset_id 			= ab.co_asset_id
	AND		tmp.co_asset_book_id	= ab.co_asset_book_id
	ORDER BY	tmp.depr_rule_code, a.asset_ctrl_num
	



UPDATE	#end_life_date
SET		fully_depreciated 			= 1
FROM	#end_life_date tmp,
		amastprf ap
WHERE	tmp.co_asset_book_id 		= ap.co_asset_book_id
AND		tmp.last_depr_date			= ap.fiscal_period_end
AND		(ABS(((SIGN(ap.current_cost + ap.accum_depr - tmp.salvage_value) * ROUND(ABS(ap.current_cost + ap.accum_depr - tmp.salvage_value) + 0.0000001, @curr_precision)))-(0.0)) < 0.0000001)

SELECT @result = @@error
IF @result <> 0 
	RETURN @result























































UPDATE	#end_life_date
SET		slp_years_remaining		= (ap.current_cost - tmp.salvage_value + ap.accum_depr) / 
									((ap.current_cost - tmp.salvage_value) * dr.annual_depr_rate / 100.00 )
FROM	#end_life_date tmp,
		amdprrul dr,
		amastprf ap
WHERE	tmp.co_asset_book_id 	= ap.co_asset_book_id
AND		tmp.last_depr_date		= ap.fiscal_period_end
AND		tmp.depr_rule_code		= dr.depr_rule_code
AND		dr.depr_method_id		IN (1, 3)
AND		(ABS((ap.current_cost - tmp.salvage_value)-(0.0)) > 0.0000001)
AND		dr.annual_depr_rate		!= 0.00
AND		tmp.last_depr_date		IS NOT NULL

SELECT @result = @@error
IF @result <> 0 
	RETURN @result




UPDATE	#end_life_date
SET		slp_years_remaining		= 100.00 / dr.annual_depr_rate 
FROM	#end_life_date tmp,
		amdprrul dr
WHERE	tmp.depr_rule_code		= dr.depr_rule_code
AND		dr.depr_method_id		IN (1, 3)
AND		dr.annual_depr_rate		!= 0.00
AND		tmp.last_depr_date		IS NULL

SELECT @result = @@error
IF @result <> 0 
	RETURN @result





SELECT 	@co_asset_book_id	= MIN(co_asset_book_id)
FROM	#end_life_date
WHERE	depr_method_id		IN (1, 3)
AND		last_depr_date		IS NULL
AND		placed_date			IS NOT NULL

WHILE @co_asset_book_id IS NOT NULL
BEGIN
	SELECT 	@convention_id 		= convention_id,
			@placed_date		= placed_date
	FROM	#end_life_date
	WHERE	co_asset_book_id	= @co_asset_book_id
	
	EXEC @result = amGetConventionDate_sp 
						@placed_date,
					 	@convention_id,
					 	@adjusted_placed_date OUTPUT
	IF @result <> 0 
		RETURN @result

	UPDATE	#end_life_date
	SET		last_depr_date	 	= @adjusted_placed_date
	WHERE	co_asset_book_id	= @co_asset_book_id

 	SELECT @result = @@error
	IF @result <> 0 
		RETURN @result

	SELECT 	@co_asset_book_id	= MIN(co_asset_book_id)
	FROM	#end_life_date
	WHERE	depr_method_id		IN (1, 3)
	AND		last_depr_date		IS NULL
	AND		placed_date			IS NOT NULL
	AND		co_asset_book_id	> @co_asset_book_id

	
END




UPDATE 	#end_life_date
SET		slp_end_life_date	 = DATEADD(dd, (slp_years_remaining - floor(slp_years_remaining))*366, 
												DATEADD(yy, slp_years_remaining, last_depr_date))
WHERE	depr_method_id		IN (1, 3)
AND		last_depr_date		IS NOT NULL

SELECT @result = @@error
IF @result <> 0 
	RETURN @result

UPDATE	#end_life_date
SET		end_life_date		= slp_end_life_date
WHERE	depr_method_id		IN (1, 3)
AND		(	end_life_date		IS NULL
	OR		end_life_date		> slp_end_life_date)

SELECT @result = @@error
IF @result <> 0 
	RETURN @result




IF @include_fully_depr = 1
BEGIN
	UPDATE	#end_life_date
	SET		end_life_date		= NULL
	WHERE	fully_depreciated 	= 1

	SELECT @result = @@error
	IF @result <> 0 
		RETURN @result
END
ELSE
BEGIN
	DELETE
	FROM	#end_life_date
	WHERE	fully_depreciated 	= 1

	SELECT @result = @@error
	IF @result <> 0 
		RETURN @result
END




IF @sort_by_asset = 1
BEGIN
	INSERT INTO #amndlf
	SELECT	distinct
			tmp.classification_code,
			a.asset_ctrl_num, 
			a.asset_description,
			tmp.placed_date,
			tmp.depr_rule_code,
			tmp.fully_depreciated,
			tmp.end_life_date,
			a.org_id,
			dbo.IBGetParent_fn (a.org_id)
	FROM	#end_life_date tmp,
			amasset a,
			amastbk ab,
			amOrganization_vw o,
			region_vw r
	WHERE	a.co_asset_id 			= ab.co_asset_id
	AND	a.org_id			= o.org_id
	AND     a.org_id 			= r.org_id 
	AND		tmp.co_asset_book_id	= ab.co_asset_book_id
	AND		(	end_life_date		BETWEEN @start_date AND @end_date
			OR 	end_life_date		IS NULL)
	ORDER BY	 a.asset_ctrl_num, tmp.classification_code
END
IF @sort_by_asset = 0
BEGIN
	INSERT INTO #amndlf
	SELECT	distinct
			tmp.classification_code,
			a.asset_ctrl_num, 
			a.asset_description,
			tmp.placed_date,
			tmp.depr_rule_code,
			tmp.fully_depreciated,
			tmp.end_life_date,
			a.org_id,
			dbo.IBGetParent_fn (a.org_id)
	FROM	#end_life_date tmp,
			amasset a,
			amastbk ab,
			amOrganization_vw o,
			region_vw r
	WHERE	a.co_asset_id 			= ab.co_asset_id
	AND	a.org_id			= o.org_id
	AND     a.org_id 			= r.org_id 
	AND		tmp.co_asset_book_id	= ab.co_asset_book_id
	AND		(	end_life_date		BETWEEN @start_date AND @end_date
			OR 	end_life_date		IS NULL)
	ORDER BY	tmp.end_life_date,tmp.classification_code, tmp.fully_depreciated DESC, a.asset_ctrl_num
END
IF @sort_by_asset = 2
BEGIN
	INSERT INTO #amndlf
	SELECT	distinct
			tmp.classification_code,
			a.asset_ctrl_num, 
			a.asset_description,
			tmp.placed_date,
			tmp.depr_rule_code,
			tmp.fully_depreciated,
			tmp.end_life_date,
			a.org_id,
			dbo.IBGetParent_fn (a.org_id)
	FROM	#end_life_date tmp,
			amasset a,
			amastbk ab,
			amOrganization_vw o,
			region_vw r
	WHERE	a.co_asset_id 			= ab.co_asset_id
	AND	a.org_id			= o.org_id
	AND     a.org_id 			= r.org_id 
	AND		tmp.co_asset_book_id	= ab.co_asset_book_id
	AND		(	end_life_date		BETWEEN @start_date AND @end_date
			OR 	end_life_date		IS NULL)
	ORDER BY	 a.org_id, tmp.classification_code
END

--DROP TABLE #end_life_date

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "ameldrep.cpp" + ", line " + STR( 474, 5 ) + " -- EXIT: "

RETURN 0 
GO
GRANT EXECUTE ON  [dbo].[amEndLifeDateReport_sp] TO [public]
GO
