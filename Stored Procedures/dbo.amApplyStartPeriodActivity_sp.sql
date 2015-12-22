SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[amApplyStartPeriodActivity_sp] 
( 
	@co_asset_book_id smSurrogateKey, 
	@first_time_depr	smLogical, 			
	@start_date 		smApplyDate, 		
	@end_date 			smApplyDate, 		
	@curr_precision		smallint,			
	@cost 				smMoneyZero OUTPUT,	
	@accum_depr 		smMoneyZero OUTPUT,	
	@disp_co_trx_id		smSurrogateKey = 0,	
	@debug_level		smDebugLevel 	= 0,
	@perf_level			smPerfLevel 	= 0	
)
AS 

DECLARE 
	@result				smErrorCode, 		
	@co_trx_id 			smSurrogateKey, 	
	@apply_date			smApplyDate			 








DECLARE
 @PERF_time_last datetime

SELECT @PERF_time_last = GETDATE()















									







IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amstract.sp" + ", line " + STR( 78, 5 ) + " -- ENTRY: "
IF ( @perf_level >= 1 ) EXEC perf_sp "", "tmp/amstract.sp", 79, "Entry amApplyStartPeriodActivity_sp", @PERF_time_last OUTPUT

IF @debug_level >= 3
	SELECT 	start_date	= @start_date,
			end_date	= @end_date,
			cost 		= @cost,
			accum_depr 	= @accum_depr 

	

CREATE TABLE #amdeprtmp
(
	co_trx_id		int 		NOT NULL,
	apply_date		datetime	NOT NULL
)

IF ( @perf_level >= 1 ) EXEC perf_sp "", "tmp/amstract.sp", 97, "Created Temp Table", @PERF_time_last OUTPUT

IF @first_time_depr = 1
BEGIN
	
	INSERT INTO #amdeprtmp
	(
		co_trx_id,
		apply_date
	)
	SELECT 	co_trx_id,
			apply_date 
	FROM 	amacthst 
	WHERE 	co_asset_book_id 	= @co_asset_book_id 
	AND 	apply_date 			<= @end_date 

	SELECT @result = @@error
	IF ( @result <> 0 )
		RETURN @result 
END
ELSE
BEGIN
	IF @disp_co_trx_id = 0
	BEGIN
		INSERT INTO #amdeprtmp
		(
			co_trx_id,
			apply_date
		)
		SELECT 	co_trx_id,
				apply_date 
		FROM 	amacthst 
		WHERE 	co_asset_book_id 	= @co_asset_book_id 
		AND 	apply_date	 		BETWEEN @start_date AND @end_date

		SELECT @result = @@error
		IF ( @result <> 0 )
			RETURN @result
		IF ( @perf_level >= 1 ) EXEC perf_sp "", "tmp/amstract.sp", 139, "No Disposition: Populated Temp Table", @PERF_time_last OUTPUT
	END
	ELSE
	BEGIN
		SELECT @apply_date = DATEADD(dd, -1, @end_date)
		
		INSERT INTO #amdeprtmp
		(
			co_trx_id,
			apply_date
		)
		SELECT 	co_trx_id,
				apply_date 
		FROM 	amacthst 
		WHERE 	co_asset_book_id 	= @co_asset_book_id 
		AND 	apply_date	 		BETWEEN @start_date AND @apply_date

		SELECT @result = @@error
		IF ( @result <> 0 )
			RETURN @result
		
		INSERT INTO #amdeprtmp
		(
			co_trx_id,
			apply_date
		)
		SELECT 	co_trx_id,
				apply_date 
		FROM 	amacthst 
		WHERE 	co_asset_book_id 	= @co_asset_book_id 
		AND 	apply_date	 		= @end_date
		AND		co_trx_id			< @disp_co_trx_id

		SELECT @result = @@error
		IF ( @result <> 0 )
			RETURN @result


	END
	 
END

IF @debug_level >= 3
	SELECT 	co_trx_id,
			apply_date 
	FROM	#amdeprtmp


IF ( @perf_level >= 1 ) EXEC perf_sp "", "tmp/amstract.sp", 187, "Populated Temp Table", @PERF_time_last OUTPUT

SELECT	@apply_date = MIN(apply_date)
FROM	#amdeprtmp

WHILE @apply_date IS NOT NULL 
BEGIN 

	SELECT 	@co_trx_id 	= MIN(co_trx_id)
	FROM 	#amdeprtmp 
	WHERE	apply_date	= @apply_date

	WHILE @co_trx_id IS NOT NULL
	BEGIN
		EXEC @result = amApplyActivity_sp 
								@co_asset_book_id,
				 				@co_trx_id,
								@curr_precision,
								@cost 			OUTPUT,
							 	@accum_depr 	OUTPUT,
							 	@debug_level 

		IF ( @result <> 0 )
			RETURN @result 

		IF ( @perf_level >= 1 ) EXEC perf_sp "", "tmp/amstract.sp", 216, "Apply an activity", @PERF_time_last OUTPUT
	
		IF @debug_level >= 3
			SELECT 	co_trx_id 	= @co_trx_id,
					cost 		= @cost,
					accum_depr 	= @accum_depr 

		SELECT 	@co_trx_id 		= MIN(co_trx_id)
		FROM 	#amdeprtmp 
		WHERE	apply_date		= @apply_date
		AND		co_trx_id		> @co_trx_id

	END	 
	
	SELECT	@apply_date = MIN(apply_date)
	FROM	#amdeprtmp
	WHERE	apply_date	> @apply_date

END  

DROP TABLE #amdeprtmp

IF @debug_level >= 3
	SELECT 	cost 		= @cost,
			accum_depr 	= @accum_depr 

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amstract.sp" + ", line " + STR( 242, 5 ) + " -- EXIT: "
IF ( @perf_level >= 1 ) EXEC perf_sp "", "tmp/amstract.sp", 243, "Exit amApplyStartPeriodActivity_sp", @PERF_time_last OUTPUT

RETURN 0 
GO
GRANT EXECUTE ON  [dbo].[amApplyStartPeriodActivity_sp] TO [public]
GO
