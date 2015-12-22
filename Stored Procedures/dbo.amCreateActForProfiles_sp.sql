SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[amCreateActForProfiles_sp] 
(
 	@company_id				smCompanyID,			
 	@co_asset_id 			smSurrogateKey, 		
 	@co_asset_book_id 		smSurrogateKey, 		
 	@addition_co_trx_id		smSurrogateKey,			
 	@acquisition_date		smApplyDate,			
	@asset_account_id		smSurrogateKey 	= 0,	
	@accum_depr_account_id	smSurrogateKey 	= 0,	
	@depr_exp_account_id	smSurrogateKey 	= 0,	
	@adjustment_account_id	smSurrogateKey 	= 0,	
	@debug_level			smDebugLevel 	= 0		
)
AS 

DECLARE 
	@result	 			smErrorCode, 		
	@fiscal_period_start	smApplyDate,		
	@prev_profile_date		smApplyDate,		
	@profile_date			smApplyDate,		
	@prev_cost				smMoneyZero,		
	@prev_accum_depr		smMoneyZero,		
	@cost					smMoneyZero,		
	@accum_depr				smMoneyZero,		
	@diff_cost				smMoneyZero,		
	@diff_accum_depr		smMoneyZero,		
	@curr_precision 		smallint,			
	@rounding_factor 		float 				

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amcracpr.sp" + ", line " + STR( 125, 5 ) + " -- ENTRY: "


SELECT	@profile_date		= NULL,
		@prev_profile_date	= NULL,
		@prev_cost			= 0.0,
		@cost				= 0.0,
		@prev_accum_depr	= 0.0,
		@accum_depr			= 0.0

EXEC @result = amGetCurrencyPrecision_sp 
					@curr_precision 	OUTPUT,	
					@rounding_factor 	OUTPUT 	
IF @result <> 0
	RETURN @result


SELECT	@profile_date 		= MIN(fiscal_period_end)
FROM	amastprf
WHERE	co_asset_book_id	= @co_asset_book_id

IF @debug_level >= 3
	SELECT	profile_date 	= @profile_date

IF @profile_date IS NOT NULL
BEGIN
	
	SELECT	@prev_cost			= ISNULL(amount, 0.0)
	FROM	amvalues
	WHERE	co_asset_book_id	= @co_asset_book_id
	AND		co_trx_id			= @addition_co_trx_id
	AND		account_type_id		= 0

	SELECT	@prev_accum_depr	= ISNULL(amount, 0.0)
	FROM	amvalues
	WHERE	co_asset_book_id	= @co_asset_book_id
	AND		co_trx_id			= @addition_co_trx_id
	AND		account_type_id		= 1

END

WHILE @profile_date IS NOT NULL
BEGIN
	
	
	SELECT	@cost 				= current_cost,
			@accum_depr			= accum_depr
	FROM	amastprf
	WHERE	co_asset_book_id	= @co_asset_book_id
	AND		fiscal_period_end	= @profile_date

	IF @debug_level >= 3
		SELECT	prev_cost		= @prev_cost,
				prev_accum_depr	= @prev_accum_depr,
				cost 			= @cost,
				accum_depr		= @accum_depr,
				profile_date	= @profile_date

	
	IF (ABS((@cost - @prev_cost)-(0.0)) > 0.0000001)
	BEGIN
		IF @debug_level >= 3
			SELECT "Adding an extra adjustment activity"
		
		SELECT	@diff_cost = (SIGN(@cost - @prev_cost) * ROUND(ABS(@cost - @prev_cost) + 0.0000001, @curr_precision))

		IF @debug_level >= 3
			SELECT	diff_cost		= @diff_cost

		EXEC @result = amGetFiscalPeriod_sp
							@profile_date,
							0,
							@fiscal_period_start OUTPUT
		IF ( @result <> 0 ) 
			 RETURN @result 
		
		
		IF @fiscal_period_start < @acquisition_date
			SELECT 	@fiscal_period_start = @acquisition_date
			
		IF @debug_level >= 3
			SELECT	diff_cost		= @diff_cost,
					activity_date 	= @fiscal_period_start

		EXEC 	@result = amCreateMissingActivity_sp
							@company_id,
							@co_asset_id,
							@co_asset_book_id,
							@fiscal_period_start,
							42,
							@diff_cost,
							@cost,
							@accum_depr,
							@asset_account_id,		
							@accum_depr_account_id,	
							@depr_exp_account_id,	
							@adjustment_account_id	

		IF @result <> 0
			RETURN @result
	
	END

	
	IF (ABS((@accum_depr - @prev_accum_depr)-(0.0)) > 0.0000001)
	BEGIN
		IF @debug_level >= 3
			SELECT "Adding an extra depreciation activity"

		SELECT	@diff_accum_depr = (SIGN(@accum_depr - @prev_accum_depr) * ROUND(ABS(@accum_depr - @prev_accum_depr) + 0.0000001, @curr_precision))

		EXEC 	@result = amCreateMissingActivity_sp
							@company_id,
							@co_asset_id,
							@co_asset_book_id,
							@profile_date,
							50,
							@diff_accum_depr,
							@cost,
							@accum_depr,
							@asset_account_id,		
							@accum_depr_account_id,	
							@depr_exp_account_id,	
							@adjustment_account_id	

		IF @result <> 0
			RETURN @result
		
	END

	
	SELECT	@prev_cost 			= @cost,
			@prev_accum_depr	= @accum_depr,
			@prev_profile_date	= @profile_date
	
	SELECT	@profile_date 		= MIN(fiscal_period_end)
	FROM	amastprf
	WHERE	co_asset_book_id	= @co_asset_book_id
	AND		fiscal_period_end	> @profile_date
	
END

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amcracpr.sp" + ", line " + STR( 288, 5 ) + " -- EXIT: "

RETURN 0 
GO
GRANT EXECUTE ON  [dbo].[amCreateActForProfiles_sp] TO [public]
GO
