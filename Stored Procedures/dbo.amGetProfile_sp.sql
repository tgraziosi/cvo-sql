SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[amGetProfile_sp] 
(
 @co_asset_book_id	smSurrogateKey, 		
 @apply_date			smApplyDate, 			
 @cost				smMoneyZero		OUTPUT,	
 @accum_depr			smMoneyZero		OUTPUT,	
 @period_date		smApplyDate		OUTPUT,	
	@debug_level		smDebugLevel 	= 0		
)
AS 

DECLARE 
 	@error 		smErrorCode, 			
	@message 	smErrorLongDesc, 		
 	@rowcount 	smCounter, 				
 @temp_cost smMoneyZero, 			
 @temp_accum_depr smMoneyZero, 
 @temp_period_date 	smApplyDate 

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amprofil.sp" + ", line " + STR( 91, 5 ) + " -- ENTRY: "

SELECT 	@cost 			= 0.0, 
		@accum_depr 	= 0.0, 
		@period_date 	= NULL 

 
SELECT @cost 				= current_cost,
 @accum_depr 		= accum_depr,
		@period_date 		= fiscal_period_end 
FROM amastprf 
WHERE co_asset_book_id 	= @co_asset_book_id 
AND fiscal_period_end 	= (SELECT MAX(fiscal_period_end)
								FROM 	amastprf 
								WHERE 	co_asset_book_id 	= @co_asset_book_id 
								AND 	fiscal_period_end 	<= @apply_date)


SELECT 	@rowcount 	= @@rowcount

IF ( @rowcount = 0 ) 
OR ( @period_date != @apply_date )
BEGIN 

	 
	SELECT 	@temp_cost 			= 0.0, 
			@temp_accum_depr 	= 0.0,
			@temp_period_date 	= NULL 

	SELECT @temp_cost 			= current_cost,
	 @temp_accum_depr 	= accum_depr,
			@temp_period_date 	= fiscal_period_end 
	FROM #amastprf 
	WHERE co_asset_book_id 	= @co_asset_book_id 
	AND fiscal_period_end 	= (SELECT 	MAX(fiscal_period_end)
									FROM 	#amastprf 
									WHERE 	co_asset_book_id 	= @co_asset_book_id 
									AND 	fiscal_period_end 	<= @apply_date)
		
	IF 	(@temp_period_date IS NULL) 
	AND (@period_date IS NULL)
	BEGIN 
		IF @debug_level >= 3
			SELECT "Can't find any profile at all - use cost = 0, accum = 0"
		
		 
		SELECT 	@cost 				= 0.0, 
				@accum_depr 		= 0.0
				
		SELECT	@period_date		= DATEADD(dd, -1, acquisition_date)
		FROM	amastbk ab,
				amasset a,
				amOrganization_vw o
		WHERE 	ab.co_asset_book_id = @co_asset_book_id 
		AND		ab.co_asset_id		= a.co_asset_id
		AND     a.org_id  =  o.org_id
	END 
	ELSE 
	BEGIN 
		IF @period_date IS NULL AND @temp_period_date IS NOT NULL 
			SELECT 	@cost 			= @temp_cost,
					@accum_depr 	= @temp_accum_depr,
					@period_date 	= @temp_period_date 
		ELSE 
		BEGIN 
			 
			IF 	(@temp_period_date IS NOT NULL )
			AND (@temp_period_date > @period_date)
				SELECT @cost 			= @temp_cost,
						@accum_depr 	= @temp_accum_depr,
						@period_date 	= @temp_period_date 

		END 
	END 
END 

IF @debug_level >= 3
 SELECT 	cost 		= @cost, 
 			accum_depr 	= @accum_depr, 
 			period_date = @period_date 

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amprofil.sp" + ", line " + STR( 180, 5 ) + " -- EXIT: "

RETURN 0 
GO
GRANT EXECUTE ON  [dbo].[amGetProfile_sp] TO [public]
GO
