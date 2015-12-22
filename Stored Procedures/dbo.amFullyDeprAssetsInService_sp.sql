SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE [dbo].[amFullyDeprAssetsInService_sp] 
( 	
	@book_code			smBookCode,				
	@iso_apply_date		smISODate,				
	@start_org_id		smOrgId,							
	@end_org_id		smOrgId,				
	@start_asset		smControlNumber,		
	@end_asset			smControlNumber,		
	@debug_level		smDebugLevel	= 0		

)
AS 

DECLARE @apply_date		smApplyDate,
		@curr_precision	smallint,
		@round_factor	float,
		@return_status	smErrorCode		

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "amfdais.cpp" + ", line " + STR( 108, 5 ) + " -- ENTRY: "

SELECT	@apply_date = CONVERT(datetime, @iso_apply_date)



 
EXEC @return_status = amGetCurrencyPrecision_sp 
						@curr_precision 	OUTPUT,
						@round_factor 		OUTPUT 

IF @debug_level	>= 5
	SELECT 	book_code 		= @book_code,
			apply_date 		= @apply_date,
			start_asset 	= @start_asset,
			end_asset 		= @end_asset 



IF RTRIM(@start_org_id) = "<Start>"
BEGIN
	SELECT 	@start_org_id 	= MIN(org_id)
	FROM	amasset
END

IF RTRIM(@end_org_id) = "<End>"
BEGIN
	SELECT 	@end_org_id 	= MAX(org_id)
	FROM	amasset
END




IF @start_asset = "<Start>"
BEGIN
	SELECT 	@start_asset 	= MIN(asset_ctrl_num)
	FROM	amasset
END

IF @end_asset = "<End>"
BEGIN
	SELECT 	@end_asset 	= MAX(asset_ctrl_num)
	FROM	amasset
END

CREATE TABLE #asset_book
(
	co_asset_id			int,
	status_code			char(8),
	location_code		char(8) null,
	co_asset_book_id	int,
	fiscal_period_end	datetime,
	current_cost		float,
	accum_depr			float,
	effective_date		datetime,
	depr_rule_code		char(8),
	salvage_value		float,
	fully_depreciated	smallint

)

INSERT INTO #asset_book
(
	co_asset_id, 
	status_code,
	location_code,
	co_asset_book_id,
	fiscal_period_end,
	current_cost,
	accum_depr,
	effective_date,
	depr_rule_code,
	salvage_value,
	fully_depreciated
)
SELECT
	a.co_asset_id,
	"",		
	null,
	ab.co_asset_book_id,
	ap.fiscal_period_end,
	ap.current_cost,
	ap.accum_depr,
	ap.effective_date,
	dh.depr_rule_code,
	dh.salvage_value,
	0
FROM
	amasset		a,
	amastbk		ab,
	amdprhst 	dh,
	amastprf 	ap,
	amOrganization_vw o
WHERE		a.org_id 		= o.org_id
AND		a.asset_ctrl_num	BETWEEN @start_asset AND @end_asset
AND		a.org_id 		BETWEEN @start_org_id AND @end_org_id
AND		a.co_asset_id 			= ab.co_asset_id
AND		ab.book_code			= @book_code
AND		ab.co_asset_book_id		= dh.co_asset_book_id
AND		ab.co_asset_book_id 	= ap.co_asset_book_id
AND		ap.co_asset_book_id 	= dh.co_asset_book_id
AND		dh.effective_date		= ap.effective_date
AND		ap.fiscal_period_end 	= (	SELECT	MAX (amst.fiscal_period_end)
									FROM	amastprf amst
									WHERE	amst.fiscal_period_end 	<= @apply_date
									AND		amst.co_asset_book_id 	= ap.co_asset_book_id)

AND		(										
			a.disposition_date 	IS NULL
		OR	a.disposition_date 	> @apply_date
		)
AND		a.activity_state		<> 100		


IF @debug_level >= 3
	SELECT 	
		a.asset_ctrl_num, 
		a.disposition_date,
		fiscal_period_end,
		current_cost,
		accum_depr,
		salvage_value,
		effective_date,
		depr_rule_code,
		fully_depreciated 
	FROM	#asset_book ab,
			amasset a,
			amOrganization_vw o
	WHERE	a.co_asset_id = ab.co_asset_id
	AND	a.org_id = o.org_id
	ORDER BY asset_ctrl_num




UPDATE	#asset_book
SET		fully_depreciated = 1
WHERE	(ABS(((SIGN(current_cost + accum_depr - salvage_value) * ROUND(ABS(current_cost + accum_depr - salvage_value) + 0.0000001, @curr_precision)))-(0.0)) < 0.0000001)




UPDATE 	#asset_book
SET		location_code 		= new_value
FROM	#asset_book 	ab,
		amastchg		ac
WHERE	ab.co_asset_id 		= ac.co_asset_id
AND		ab.fully_depreciated = 1
AND		ac.field_type		= 1
AND		ac.apply_date		= (	SELECT	MAX (amsub.apply_date)
									FROM	amastchg amsub
									WHERE	amsub.co_asset_id 	= ac.co_asset_id
									AND		amsub.field_type	= 1
									AND		amsub.apply_date 	<= @apply_date
								)

UPDATE 	#asset_book
SET		status_code 		= new_value
FROM	#asset_book 	ab,
		amastchg		ac
WHERE	ab.co_asset_id 		= ac.co_asset_id
AND		ab.fully_depreciated = 1
AND		ac.field_type		= 4
AND		ac.apply_date		= (	SELECT	MAX (amsub.apply_date)
									FROM	amastchg amsub
									WHERE	amsub.co_asset_id 	= ac.co_asset_id
									AND		amsub.field_type	= 4
									AND		amsub.apply_date 	<= @apply_date
								)

SELECT
		asset_ctrl_num			= a.asset_ctrl_num,
		asset_description		= a.asset_description,
		status_code				= ab.status_code,
		location_code			= ab.location_code,
		location_description 	= l.location_description,
		book_code 				= @book_code,
		depr_rule_code			= ab.depr_rule_code,
		salvage_value			= ab.salvage_value,
		current_cost			= ab.current_cost,
		accum_depr 				= -ab.accum_depr,
		book_value 				= (SIGN(ab.current_cost + ab.accum_depr) * ROUND(ABS(ab.current_cost + ab.accum_depr) + 0.0000001, @curr_precision)),
		a.org_id








FROM	#asset_book ab,
		amasset	a left outer join 	amloc l on a.location_code = l.location_code ,
		amOrganization_vw o
WHERE	ab.co_asset_id 			= a.co_asset_id
AND		a.org_id		= o.org_id
AND		ab.fully_depreciated 	= 1


IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "amfdais.cpp" + ", line " + STR( 308, 5 ) + " -- EXIT: "

RETURN 0 
GO
GRANT EXECUTE ON  [dbo].[amFullyDeprAssetsInService_sp] TO [public]
GO
