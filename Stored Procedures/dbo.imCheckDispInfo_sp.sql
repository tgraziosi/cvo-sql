SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[imCheckDispInfo_sp] 
(
	@co_asset_id 			smSurrogateKey, 	
	@asset_ctrl_num 		smControlNumber, 	
	@acquisition_date		smApplyDate,			
	@disposition_date		smApplyDate,		
	@last_profile_date		smApplyDate,		
	@stop_on_error			smLogical,			
	@curr_precision			smallint,			
	@is_valid	 			smLogical 	OUTPUT,	
	@debug_level			smDebugLevel	= 0	
)
AS 

DECLARE
		@co_asset_book_id 		smSurrogateKey, 
		@co_trx_id 				smSurrogateKey, 
		@num_activities 		smCounter, 			
		@sum_asset				smMoneyZero,
		@sum_accum_depr			smMoneyZero,
		@last_depr_date			smApplyDate,		
		@last_legal_date		smApplyDate,		
		@param1 				smErrorParam, 		
		@param2 				smErrorParam, 		
		@message				smErrorLongDesc		

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/imchkdsp.sp" + ", line " + STR( 89, 5 ) + " -- ENTRY: "


SELECT 	@co_trx_id 		= NULL,
		@sum_asset		= 0.0,
		@sum_accum_depr	= 0.0,
		@num_activities	= 0


SELECT	@co_trx_id 			= co_trx_id
FROM	amacthst	ah,
		amastbk		ab
WHERE	ah.co_asset_book_id = ab.co_asset_book_id
AND		ab.co_asset_id		= @co_asset_id
AND		trx_type 			= 30


IF @disposition_date IS NOT NULL 
BEGIN
	
	IF @co_trx_id IS NULL
	BEGIN
		SELECT 		@is_valid = 0 
		EXEC		amGetErrorMessage_sp 
								24005, "tmp/imchkdsp.sp", 119, 
								@asset_ctrl_num, 
								@error_message = @message OUT 
		IF @message IS NOT NULL RAISERROR 	24005 @message

		IF @stop_on_error = 1
			RETURN 0
	END
	ELSE 
	BEGIN
		SELECT	@co_asset_book_id 	= MIN(co_asset_book_id)
		FROM	amastbk
		WHERE	co_asset_id			= @co_asset_id
		
		WHILE @co_asset_book_id IS NOT NULL
		BEGIN
			
			IF @last_profile_date IS NULL
			BEGIN
				
				SELECT 	@sum_asset 			= (SIGN(ISNULL(SUM(amount),0.0)) * ROUND(ABS(ISNULL(SUM(amount),0.0)) + 0.0000001, @curr_precision))
				FROM	amvalues
				WHERE	co_asset_book_id 	= @co_asset_book_id
				AND		account_type_id		= 0

				SELECT 	@sum_accum_depr 	= (SIGN(ISNULL(SUM(amount),0.0)) * ROUND(ABS(ISNULL(SUM(amount),0.0)) + 0.0000001, @curr_precision))
				FROM	amvalues
				WHERE	co_asset_book_id 	= @co_asset_book_id
				AND		account_type_id		= 1
			END
			ELSE
			BEGIN
				
				SELECT	@sum_asset			= current_cost,
						@sum_accum_depr		= accum_depr
				FROM	amastprf
				WHERE	co_asset_book_id	= @co_asset_book_id
				AND		fiscal_period_end	= @last_profile_date

				IF @debug_level >= 3
				BEGIN
					SELECT "last profile used as a starting point for checking zero sum:"
					SELECT	sum_asset 		= @sum_asset,
							sum_accum_depr	= @sum_accum_depr
				END

				SELECT	@sum_asset 			= (SIGN(@sum_asset + ISNULL(SUM(amount),0.0)) * ROUND(ABS(@sum_asset + ISNULL(SUM(amount),0.0)) + 0.0000001, @curr_precision))
				FROM	amvalues
				WHERE	co_asset_book_id 	= @co_asset_book_id
				AND		account_type_id		= 0
				AND		apply_date			> @last_profile_date
			
				SELECT	@sum_accum_depr 	= (SIGN(@sum_accum_depr + ISNULL(SUM(amount),0.0)) * ROUND(ABS(@sum_accum_depr + ISNULL(SUM(amount),0.0)) + 0.0000001, @curr_precision))
				FROM	amvalues
				WHERE	co_asset_book_id 	= @co_asset_book_id
				AND		account_type_id		= 1
				AND		apply_date			> @last_profile_date
			
			END

			IF (ABS((@sum_asset)-(0.0)) > 0.0000001)
			BEGIN
				IF @debug_level >= 3
					SELECT	sum_asset 		= @sum_asset,
							sum_accum_depr	= @sum_accum_depr

				SELECT		@param1 	= CONVERT(char(255), @sum_asset),
					 		@is_valid 	= 0 
				EXEC		amGetErrorMessage_sp 
										24006, "tmp/imchkdsp.sp", 195, 
										@asset_ctrl_num, @param1, 
										@error_message = @message OUT 		
				IF @message IS NOT NULL RAISERROR 	24006 @message

				IF @stop_on_error = 1
					RETURN 0
			END

			IF (ABS((@sum_accum_depr)-(0.0)) > 0.0000001)
			BEGIN
				IF @debug_level >= 3
					SELECT	sum_asset 		= @sum_asset,
							sum_accum_depr	= @sum_accum_depr

				SELECT		@param1 	= CONVERT(char(255), @sum_accum_depr),
				 			@is_valid 	= 0 
				EXEC		amGetErrorMessage_sp 
										24007, "tmp/imchkdsp.sp", 213, 
										@asset_ctrl_num, @param1, 
										@error_message = @message OUT 		
				IF @message IS NOT NULL RAISERROR 	24007 @message

				IF @stop_on_error = 1
					RETURN 0
			END


			
			SELECT	@co_asset_book_id 	= MIN(co_asset_book_id)
			FROM	amastbk
			WHERE	co_asset_id			= @co_asset_id
			AND		co_asset_book_id	> @co_asset_book_id
		END
	END
END	 
ELSE
BEGIN 
	
	IF @co_trx_id IS NOT NULL
	BEGIN
		SELECT 		@is_valid = 0 
		EXEC		amGetErrorMessage_sp 
								24011, "tmp/imchkdsp.sp", 242, 
								@asset_ctrl_num, 
								@error_message = @message OUT 
		IF @message IS NOT NULL RAISERROR 	24011 @message

		IF @stop_on_error = 1
			RETURN 0
	END

	SELECT	@co_asset_book_id 	= MIN(co_asset_book_id)
	FROM	amastbk
	WHERE	co_asset_id			= @co_asset_id
	
	WHILE @co_asset_book_id IS NOT NULL
	BEGIN
		
		SELECT 	@last_depr_date 	= MAX(apply_date)
		FROM	amvalues								 
		WHERE	co_asset_book_id	= @co_asset_book_id
		AND		trx_type			= 50
		AND		account_type_id		= 1

		IF 	@last_depr_date IS NULL
		BEGIN
			IF	@last_profile_date IS NULL
				SELECT	@last_legal_date = @acquisition_date		
			ELSE
				SELECT	@last_legal_date = @last_profile_date	 	
		END
		ELSE
			SELECT	@last_legal_date = @last_depr_date				
				
		IF @debug_level >= 3
		BEGIN
			SELECT	"Last legal date for imported activities for this non-disposed asset is:"
			SELECT	last_legal_date 	= @last_legal_date,
					last_depr_date		= @last_depr_date,
					last_profile_date 	= @last_profile_date,
					acquisition_date	= @acquisition_date
		END

		IF @last_legal_date IS NOT NULL
		BEGIN
			SELECT	@num_activities 	= COUNT(co_trx_id)
			FROM	amacthst
			WHERE	co_asset_book_id	= @co_asset_book_id
			AND		apply_date			> @last_legal_date

			IF @num_activities > 0
			BEGIN
				SELECT	@param1 			= book_code
				FROM	amastbk
				WHERE	co_asset_book_id 	= @co_asset_book_id
				
				SELECT		@param2	= CONVERT(char(255), @last_legal_date),
					 		@is_valid = 0 
				EXEC		amGetErrorMessage_sp 
										24010, "tmp/imchkdsp.sp", 302, 
										@asset_ctrl_num, @param1, @param2, 
										@error_message = @message OUT 		
				IF @message IS NOT NULL RAISERROR 	24010 @message

				IF @stop_on_error = 1
					RETURN 0
			END
		END

		
		SELECT	@co_asset_book_id 	= MIN(co_asset_book_id)
		FROM	amastbk
		WHERE	co_asset_id			= @co_asset_id
		AND		co_asset_book_id	> @co_asset_book_id

	END
END

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/imchkdsp.sp" + ", line " + STR( 323, 5 ) + " -- EXIT: "
	
RETURN 0 
GO
GRANT EXECUTE ON  [dbo].[imCheckDispInfo_sp] TO [public]
GO
