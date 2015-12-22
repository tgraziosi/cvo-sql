SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[imUpdateActivities_sp] 
(
	@co_asset_book_id 		smSurrogateKey, 	
	@addition_co_trx_id		smSurrogateKey,		
	@acquisition_date		smApplyDate,		
	@placed_in_service_date	smApplyDate,		
	@curr_precision			smallint,			
	@debug_level			smDebugLevel	= 0	
)
AS 

DECLARE 
	@result	 			smErrorCode, 		
	@from_date				smApplyDate,		
	@apply_date				smApplyDate,		
	@fiscal_period_end		smApplyDate,		
	@last_profile_date		smApplyDate,		
	@current_cost			smMoneyZero,		
	@accum_depr				smMoneyZero,		
	@co_trx_id				smSurrogateKey,		
	@trx_type				smTrxType,			 
	@disposition_date		smApplyDate,		
	@last_depr_date			smApplyDate,		
	@last_activity_date		smApplyDate			

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/imupdact.sp" + ", line " + STR( 117, 5 ) + " -- ENTRY: "


SELECT	@last_profile_date 	= NULL,
		@co_trx_id 			= NULL,
		@last_depr_date		= NULL,
		@disposition_date	= NULL,
		@last_activity_date	= @acquisition_date,
		@current_cost		= 0.0,
		@accum_depr			= 0.0


SELECT	@last_profile_date 	= MAX(fiscal_period_end)
FROM	amastprf
WHERE	co_asset_book_id	= @co_asset_book_id

IF @debug_level	>= 3
	SELECT	last_profile_date = @last_profile_date

IF @last_profile_date IS NULL
BEGIN
	
	SELECT	@from_date 	= @acquisition_date
	
	
	SELECT	@current_cost		= ISNULL(revised_cost, 0.0),
			@accum_depr			= ISNULL(revised_accum_depr, 0.0)
	FROM	amacthst
	WHERE	co_asset_book_id	= @co_asset_book_id
	AND		co_trx_id			= @addition_co_trx_id

	IF @debug_level	>= 3
	BEGIN
		SELECT "No profiles found: start with addition information"
		SELECT	current_cost 	= @current_cost,
				accum_depr		= @accum_depr
	END

	
	EXEC @result = amGetFiscalPeriod_sp
						@acquisition_date,
						1,
						@fiscal_period_end OUTPUT
	IF ( @result <> 0 ) 
		 RETURN @result 

	EXEC @result = imCreateProfile_sp
						@co_asset_book_id,
						@fiscal_period_end,
						@current_cost,
						@accum_depr,
						@debug_level	= @debug_level

	IF ( @result <> 0 ) 
		 RETURN @result 

END
ELSE
BEGIN
	
	SELECT	@from_date = @last_profile_date	

	
	SELECT	@current_cost		= current_cost,
			@accum_depr			= accum_depr
	FROM	amastprf
	WHERE	co_asset_book_id	= @co_asset_book_id
	AND		fiscal_period_end	= @last_profile_date

	IF @debug_level	>= 3
	BEGIN
		PRINT "Use last profile"
		SELECT	current_cost 	= @current_cost,
				accum_depr		= @accum_depr
	END
END


SELECT	@last_depr_date		= MAX(apply_date)
FROM	amvalues
WHERE	co_asset_book_id	= @co_asset_book_id
AND		account_type_id 	= 1	 
AND		trx_type			= 50
AND		apply_date			> @from_date

IF @debug_level	>= 3
BEGIN
	SELECT "Last depreciation activity found following profiles:"
	SELECT	last_depr_date 	= @last_depr_date
END 

IF @last_depr_date IS NOT NULL
	SELECT	@last_activity_date	= @last_depr_date


SELECT	@disposition_date	= apply_date
FROM	amvalues
WHERE	co_asset_book_id 	= @co_asset_book_id
AND		account_type_id 	= 0			
AND		trx_type			= 30

IF @disposition_date IS NOT NULL
	SELECT	@last_activity_date = @disposition_date


IF @last_depr_date IS NOT NULL
OR @disposition_date IS NOT NULL
BEGIN
	
	IF @debug_level	>= 3
	BEGIN
		SELECT "About to process all activity on or before:"
		SELECT 	last_activity_date 	= @last_activity_date,
				from_date 			= @from_date,
				last_depr_date		= @last_depr_date
	END

	
	SELECT	@apply_date			= MIN(apply_date)
	FROM	amvalues
	WHERE	co_asset_book_id 	= @co_asset_book_id
	AND		apply_date			> @from_date
	AND		apply_date			<= @last_activity_date

	WHILE @apply_date IS NOT NULL
	BEGIN

		
		SELECT 	@co_trx_id			= MIN(co_trx_id)
		FROM	amvalues
		WHERE	co_asset_book_id	= @co_asset_book_id
		AND		apply_date 			= @apply_date

		WHILE @co_trx_id IS NOT NULL
		BEGIN
			
			
			SELECT	@trx_type 			= MIN(trx_type)	
			FROM	amvalues
			WHERE	co_trx_id			= @co_trx_id
			AND		co_asset_book_id	= @co_asset_book_id
			AND		apply_date			= @apply_date
			
			IF @debug_level	>= 3
			BEGIN
				SELECT "Found another activity to process:"
				SELECT	co_trx_id 	= @co_trx_id,
						trx_type	= @trx_type,
						apply_date 	= @apply_date
			END
			
			IF @trx_type <> 30
			BEGIN
				
				EXEC @result = imApplyActivity_sp
								@co_asset_book_id,
								@co_trx_id,
								@trx_type,
								@apply_date,
								@curr_precision,
								@current_cost	OUTPUT,
								@accum_depr		OUTPUT,
								@debug_level	= @debug_level

				IF @result <> 0
					 RETURN @result 

			END
			ELSE
			BEGIN
				EXEC @result = imApplyDisposalActivity_sp
									@co_asset_book_id,
									@co_trx_id,
									@disposition_date,
									@curr_precision,	
									@current_cost 	OUTPUT,
									@accum_depr		OUTPUT,
									@debug_level	= @debug_level
				IF @result <> 0
					 RETURN @result 
			END
			
			
			SELECT 	@co_trx_id			= MIN(co_trx_id)
			FROM	amvalues
			WHERE	co_asset_book_id	= @co_asset_book_id
			AND		apply_date 			= @apply_date
			AND		co_trx_id			> @co_trx_id

		END
		
		
		SELECT	@apply_date			= MIN(apply_date)
		FROM	amvalues
		WHERE	co_asset_book_id 	= @co_asset_book_id
		AND		apply_date			> @apply_date
		AND		apply_date			<= @last_activity_date

	END
END

IF @last_depr_date IS NULL
BEGIN
	
	IF @placed_in_service_date IS NOT NULL
	AND @placed_in_service_date <= @last_profile_date
		SELECT @last_depr_date = @last_profile_date
END
		

INSERT INTO	#imbkinfo
(
	co_asset_book_id,
	last_depr_date
)
VALUES
(
	@co_asset_book_id,
	@last_depr_date
)

SELECT @result = @@error
IF @result <> 0
	 RETURN @result 

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/imupdact.sp" + ", line " + STR( 387, 5 ) + " -- EXIT: "

RETURN 0 
GO
GRANT EXECUTE ON  [dbo].[imUpdateActivities_sp] TO [public]
GO
