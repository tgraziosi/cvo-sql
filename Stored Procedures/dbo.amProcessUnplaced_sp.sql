SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[amProcessUnplaced_sp] 
( 
	@trx_apply_date		smApplyDate,		
	@co_asset_book_id smSurrogateKey, 
	@curr_precision		smallint,			
	@cost 				smMoneyZero OUTPUT,	
	@accum_depr 		smMoneyZero OUTPUT,	
	@debug_level		smDebugLevel = 0	
)
AS 

DECLARE 
	@result				smErrorCode, 		
	@co_trx_id 			smSurrogateKey, 	
	@apply_date			smApplyDate,		 
	@next_apply_date	smApplyDate,		 
	@fiscal_period_end	smApplyDate			 


IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amprcunp.sp" + ", line " + STR( 75, 5 ) + " -- ENTRY: "

IF @debug_level >= 3
	SELECT 	cost 		= @cost,
			accum_depr 	= @accum_depr 

	

CREATE TABLE #amdeprtmp
(
	co_trx_id		int 		NOT NULL,
	apply_date		datetime	NOT NULL
)


INSERT INTO #amdeprtmp
(
	co_trx_id,
	apply_date
)
SELECT 	co_trx_id,
		apply_date 
FROM 	amacthst 
WHERE 	co_asset_book_id 	= @co_asset_book_id 
AND 	apply_date 			<= @trx_apply_date 

SELECT @result = @@error
IF ( @result != 0 ) 
BEGIN
	DROP TABLE #amdeprtmp
	RETURN @result 
END


SELECT	@apply_date = MIN(apply_date)
FROM	#amdeprtmp

WHILE @apply_date IS NOT NULL 
BEGIN 

	SELECT 	@co_trx_id 	= MIN(co_trx_id)
	FROM 	#amdeprtmp 
	WHERE	apply_date	= @apply_date

	WHILE @co_trx_id IS NOT NULL
	BEGIN
		IF @debug_level >= 5
			SELECT	apply_date	= @apply_date,
					co_trx_id	= @co_trx_id
					
		EXEC @result = amApplyActivity_sp 
								@co_asset_book_id,
				 				@co_trx_id,
								@curr_precision,
								@cost 			OUTPUT,
							 	@accum_depr 	OUTPUT,
							 	@debug_level 

		IF ( @result != 0 ) 
		BEGIN
			DROP TABLE #amdeprtmp
		 	RETURN @result 
		END

		IF @debug_level >= 3
			SELECT 	co_trx_id 	= @co_trx_id,
					cost 		= @cost,
					accum_depr 	= @accum_depr 

		SELECT 	@co_trx_id 		= MIN(co_trx_id)
		FROM 	#amdeprtmp 
		WHERE	apply_date		= @apply_date
		AND		co_trx_id		> @co_trx_id

	END	 
	
	SELECT	@next_apply_date 	= MIN(apply_date)
	FROM	#amdeprtmp
	WHERE	apply_date			> @apply_date

	
	IF @next_apply_date IS NOT NULL
	BEGIN
		SELECT 	@fiscal_period_end = NULL
		
		SELECT 	@fiscal_period_end	= MIN(fiscal_period_end)
		FROM	amastprf
		WHERE	co_asset_book_id	= @co_asset_book_id
		AND		fiscal_period_end	>= @apply_date 
		AND 	fiscal_period_end	< @next_apply_date
	
		IF @fiscal_period_end IS NOT NULL
		BEGIN
			IF @debug_level >= 5
				SELECT	fiscal_period_end	= @fiscal_period_end

			EXEC @result = amCreateProfile_sp 
									@co_asset_book_id, 
									@fiscal_period_end,
									@cost,
									@accum_depr,
									1,		 
									@debug_level = @debug_level
			IF ( @result != 0 ) 
			BEGIN
				DROP TABLE #amdeprtmp
			 	RETURN @result 
			END
		END
	END
	
	SELECT	@apply_date = @next_apply_date

END  

IF @debug_level >= 5
	SELECT	trx_apply_date	= @trx_apply_date

EXEC @result = amCreateProfile_sp 
						@co_asset_book_id, 
						@trx_apply_date,
						@cost,
						@accum_depr,
						1,		 
						@debug_level = @debug_level
DROP TABLE #amdeprtmp

IF @debug_level >= 3
	SELECT 	cost 		= @cost,
			accum_depr 	= @accum_depr 

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amprcunp.sp" + ", line " + STR( 216, 5 ) + " -- EXIT: "

RETURN 0 
GO
GRANT EXECUTE ON  [dbo].[amProcessUnplaced_sp] TO [public]
GO
