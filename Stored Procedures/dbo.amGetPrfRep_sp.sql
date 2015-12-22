SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[amGetPrfRep_sp] 
(
 @co_asset_book_id smSurrogateKey, 		 	
 @apply_date smApplyDate, 			 	 
	@curr_precision		smallint,					
 @cost smMoneyZero OUTPUT,	 	
 @accum_depr smMoneyZero OUTPUT, 	 	
	@debug_level		smDebugLevel	= 0			
)
AS 

DECLARE 
	@rowcount 	smCounter, 
	@error 		smErrorCode,
	@profile_date		smApplyDate,
	@delta_cost			smMoneyZero,
	@delta_accum_depr	smMoneyZero 

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amprdrp.sp" + ", line " + STR( 81, 5 ) + " -- ENTRY: "

SELECT 	@cost = 0.0, 
		@accum_depr = 0.0 


SELECT @cost 			= ISNULL(current_cost,0.0), 
 @accum_depr 	= ISNULL(accum_depr,0.0),
		@profile_date 	= fiscal_period_end
FROM amastprf 
WHERE co_asset_book_id 	= @co_asset_book_id 
AND fiscal_period_end 	= 
			(SELECT MAX(fiscal_period_end)
			FROM 	amastprf 
			WHERE 	co_asset_book_id 	= @co_asset_book_id 
			AND 	fiscal_period_end 	<= @apply_date)

IF @debug_level >= 3
BEGIN
	SELECT 	profile_date 	= @profile_date,
			cost 			= @cost,
			accum_depr		= @accum_depr
END



IF @profile_date IS NULL
BEGIN

		SELECT 	@cost 				= (SIGN(ISNULL(SUM(amount),0.0)) * ROUND(ABS(ISNULL(SUM(amount),0.0)) + 0.0000001, @curr_precision))
		FROM	amvalues
		WHERE	co_asset_book_id 	= @co_asset_book_id
		AND		account_type_id 	= 0
		AND		apply_date 			<= @apply_date
		
		SELECT 	@accum_depr 		= (SIGN(isnull(SUM(amount),0.0)) * ROUND(ABS(isnull(SUM(amount),0.0)) + 0.0000001, @curr_precision))
		FROM	amvalues
		WHERE	co_asset_book_id 	= @co_asset_book_id
		AND		account_type_id 	= 1
		AND		apply_date 			<= @apply_date
		
		IF @debug_level >= 3
		BEGIN
			SELECT 	cost 				= @cost,
					accum_depr			= @accum_depr
		END
END
ELSE
BEGIN
	IF	(@profile_date <> @apply_date)
	BEGIN
		SELECT 	@delta_cost = 0.0,
				@delta_accum_depr = 0.0

		SELECT 	@delta_cost 		= (SIGN(ISNULL(SUM(amount),0.0)) * ROUND(ABS(ISNULL(SUM(amount),0.0)) + 0.0000001, @curr_precision))
		FROM	amvalues
		WHERE	co_asset_book_id 	= @co_asset_book_id
		AND		account_type_id 	= 0
		AND		apply_date 			> @profile_date 
		AND		apply_date 			<= @apply_date
		
		SELECT 	@delta_accum_depr 	= (SIGN(isnull(SUM(amount),0.0)) * ROUND(ABS(isnull(SUM(amount),0.0)) + 0.0000001, @curr_precision))
		FROM	amvalues
		WHERE	co_asset_book_id 	= @co_asset_book_id
		AND		account_type_id 	= 1
		AND		apply_date 			> @profile_date 
		AND		apply_date 			<= @apply_date

		SELECT	@cost 		= (SIGN(@cost + @delta_cost) * ROUND(ABS(@cost + @delta_cost) + 0.0000001, @curr_precision)),
				@accum_depr = (SIGN(@accum_depr + @delta_accum_depr) * ROUND(ABS(@accum_depr + @delta_accum_depr) + 0.0000001, @curr_precision))
		
		IF @debug_level >= 3
		BEGIN
			SELECT 	delta_cost 			= @delta_cost,
					delta_accum_depr	= @delta_accum_depr,
					cost 				= @cost,
					accum_depr			= @accum_depr
		END
	END
END

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amprdrp.sp" + ", line " + STR( 166, 5 ) + " -- EXIT: "

RETURN 0 
GO
GRANT EXECUTE ON  [dbo].[amGetPrfRep_sp] TO [public]
GO
