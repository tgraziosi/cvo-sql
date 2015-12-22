SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[imCheckAssetForPromotion_sp] 
(
	@co_asset_id 			smSurrogateKey, 	
	@cur_yr_start_date		smApplyDate,		
	@stop_on_error			smLogical,			
	@curr_precision			smallint,			
	@is_valid	 			smLogical 	OUTPUT,	
	@debug_level			smDebugLevel	= 0	
)
AS 

DECLARE 
	@result					smErrorCode,
	@min_co_asset_book_id 	smSurrogateKey, 
	@co_asset_book_id 		smSurrogateKey, 
	@co_trx_id 				smSurrogateKey, 
	@asset_ctrl_num 		smControlNumber, 	
	@prev_yr_end_date 		smApplyDate, 
	@apply_date 			smApplyDate, 
	@acquisition_date		smApplyDate,			
	@placed_in_service_date	smApplyDate,			
	@disposition_date		smApplyDate,		
	@is_new					smLogical,			
	@profile_date			smApplyDate,		
	@first_profile_date		smApplyDate,		
	@last_profile_date		smApplyDate,		
	@trx_type				smTrxType,			
	@num_books 				smCounter, 			
	@num_books_placed		smCounter, 			
	@num_activities 		smCounter, 			
	@num_profiles 			smCounter, 			
	@param1 				smErrorParam, 		
	@param2 				smErrorParam, 		
	@param3 				smErrorParam, 		
	@message				smErrorLongDesc		
	
IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/imchaspr.sp" + ", line " + STR( 137, 5 ) + " -- ENTRY: "

 
SELECT 	@co_asset_book_id	= NULL,
		@is_valid			= 1,
		@first_profile_date	= NULL,
		@last_profile_date	= NULL,
		@prev_yr_end_date 	= DATEADD(dd, -1, @cur_yr_start_date)


SELECT 	@asset_ctrl_num		= asset_ctrl_num,
		@acquisition_date	= acquisition_date,
		@disposition_date	= disposition_date,
		@is_new				= is_new
FROM 	amasset 
WHERE 	co_asset_id 		= @co_asset_id 


SELECT 	@co_asset_book_id 	= MIN(co_asset_book_id)
FROM	amastbk
WHERE	co_asset_id 		= @co_asset_id

WHILE @co_asset_book_id IS NOT NULL
BEGIN
	
	IF NOT EXISTS (SELECT 	depr_rule_code
					FROM 	amdprhst
					WHERE	co_asset_book_id 	= @co_asset_book_id
					AND		effective_date 		<= @acquisition_date)

	BEGIN 
		SELECT 		@is_valid = 0 
		EXEC		amGetErrorMessage_sp 24012, "tmp/imchaspr.sp", 178, @asset_ctrl_num, @error_message = @message OUT 
		IF @message IS NOT NULL RAISERROR 	24012 @message

		IF @stop_on_error = 1
			RETURN 0
	END 

	
	SELECT 	@co_asset_book_id 	= MIN(co_asset_book_id)
	FROM	amastbk
	WHERE	co_asset_id 		= @co_asset_id
	AND		co_asset_book_id 	> @co_asset_book_id

END


SELECT 	@num_books 		= COUNT(co_asset_book_id)
FROM	amastbk
WHERE	co_asset_id 	= @co_asset_id


SELECT 	@first_profile_date	= MIN(fiscal_period_end)
FROM 	amastprf	ap,
		amastbk		ab
WHERE	ap.co_asset_book_id	= ab.co_asset_book_id
AND		ab.co_asset_id		= @co_asset_id

IF 	@is_new 			= 1 
BEGIN
	
	IF	@first_profile_date IS NOT NULL
	BEGIN
		SELECT 		@is_valid = 0 	 
		EXEC		amGetErrorMessage_sp 24013, "tmp/imchaspr.sp", 217, @asset_ctrl_num, @first_profile_date, @error_message = @message OUT 
		IF @message IS NOT NULL RAISERROR 	24013 @message

		IF @stop_on_error = 1
			RETURN 0
	END
 
 	
	IF	@acquisition_date <	@cur_yr_start_date	
	BEGIN
		SELECT 		@is_valid = 0 	 
		EXEC		amGetErrorMessage_sp 24009, "tmp/imchaspr.sp", 230, @asset_ctrl_num, @error_message = @message OUT 
		IF @message IS NOT NULL RAISERROR 	24009 @message

		IF @stop_on_error = 1
			RETURN 0
	END
END

	

SELECT 	@co_asset_book_id 	= MIN(co_asset_book_id)
FROM	amastbk
WHERE	co_asset_id 		= @co_asset_id

WHILE @co_asset_book_id IS NOT NULL
BEGIN
	SELECT 	@placed_in_service_date = placed_in_service_date,
			@param1					= book_code
	FROM	amastbk
	WHERE	co_asset_book_id		= @co_asset_book_id
			
	
	IF 	@placed_in_service_date <= @prev_yr_end_date
	AND	@disposition_date 	IS NULL
	BEGIN
		
		IF NOT EXISTS(SELECT 	co_asset_book_id 
						FROM 	amvalues
						WHERE	co_asset_book_id 	= @co_asset_book_id
						AND		apply_date			= @prev_yr_end_date
						AND		trx_type			= 50)
		BEGIN
			
			IF NOT EXISTS(SELECT 	co_asset_book_id 
							FROM 	amastprf
							WHERE	co_asset_book_id 	= @co_asset_book_id
							AND		fiscal_period_end	= @prev_yr_end_date)
			BEGIN
				SELECT 		@is_valid = 0 
				EXEC		amGetErrorMessage_sp 24008, "tmp/imchaspr.sp", 279, @asset_ctrl_num, @param1, @error_message = @message OUT 		
				IF @message IS NOT NULL RAISERROR 	24008 @message

				IF @stop_on_error = 1
					RETURN 0
			END
		END
	END

	
	SELECT @profile_date = @first_profile_date
	WHILE @profile_date IS NOT NULL
	BEGIN
		SELECT	@param2		= CONVERT(char(255), @profile_date)

		IF @placed_in_service_date IS NULL
		OR	@placed_in_service_date > @profile_date
		BEGIN
			
			IF EXISTS(SELECT co_asset_book_id
							FROM	amastprf
							WHERE	co_asset_book_id	= @co_asset_book_id
							AND		fiscal_period_end	= @profile_date
							AND		(ABS((accum_depr)-(0.00)) > 0.0000001) )
			BEGIN
				SELECT 		@is_valid = 0 
				EXEC		amGetErrorMessage_sp 
										24021, "tmp/imchaspr.sp", 311, 
										@asset_ctrl_num, @param1, @param2, 
										@error_message = @message OUT 
				IF @message IS NOT NULL RAISERROR 	24021 @message

				IF @stop_on_error = 1
					RETURN 0
			END
		END
		ELSE
		BEGIN
			
			IF NOT EXISTS(SELECT co_asset_book_id
							FROM	amastprf
							WHERE	co_asset_book_id	= @co_asset_book_id
							AND		fiscal_period_end	= @profile_date)
			BEGIN
				SELECT 		@is_valid = 0 
				EXEC		amGetErrorMessage_sp 
										24020, "tmp/imchaspr.sp", 333, 
										@asset_ctrl_num, @param1, @param2, 
										@error_message = @message OUT 
				IF @message IS NOT NULL RAISERROR 	24020 @message

				IF @stop_on_error = 1
					RETURN 0

			END
		END


		
		SELECT 	@profile_date		= MIN(fiscal_period_end)
		FROM 	amastprf	ap,
				amastbk 	ab
		WHERE	ab.co_asset_book_id	= ap.co_asset_book_id
		AND		ab.co_asset_id		= @co_asset_id
		AND		fiscal_period_end	> @profile_date

	END

	
	SELECT 	@co_asset_book_id 	= MIN(co_asset_book_id)
	FROM	amastbk
	WHERE	co_asset_book_id	> @co_asset_book_id
	AND		co_asset_id			= @co_asset_id
END


IF @disposition_date IS NOT NULL
BEGIN
	SELECT 	@min_co_asset_book_id 	= MIN(co_asset_book_id)
	FROM	amastbk
	WHERE	co_asset_id				= @co_asset_id

	
	SELECT 	@last_profile_date	= MAX(fiscal_period_end)
	FROM 	amastprf
	WHERE	co_asset_book_id	= @min_co_asset_book_id

	
	IF 	@last_profile_date 	> @disposition_date
	BEGIN
		SELECT 		@param1 	= CONVERT(char(255), @last_profile_date),
			 		@param2		= CONVERT(char(255), @disposition_date),
		 			@is_valid = 0 
		EXEC		amGetErrorMessage_sp 
								24016, "tmp/imchaspr.sp", 391, 
								@asset_ctrl_num, @param1, @param2, 
								@error_message = @message OUT 
		IF @message IS NOT NULL RAISERROR 	24016 @message

		IF @stop_on_error = 1
			RETURN 0
	END


	IF @debug_level >= 3
		SELECT	min_co_asset_book_id	= @min_co_asset_book_id,
				last_profile_date		= @last_profile_date
END


SELECT	@co_trx_id		= MIN(co_trx_id)
FROM	amtrxhdr
WHERE	co_asset_id		= @co_asset_id

WHILE @co_trx_id IS NOT NULL
BEGIN
	
		
	SELECT 	@apply_date 		= apply_date,
			@trx_type			= trx_type
	FROM	amtrxhdr
	WHERE	co_trx_id 			= @co_trx_id
	AND		co_asset_id			= @co_asset_id

	IF @debug_level >= 3
		SELECT	co_trx_id			= @co_trx_id,
				trx_type			= @trx_type,
				apply_date			= @apply_date

	
	IF @is_new = 1 
	AND	@trx_type IN (30, 70, 50, 60)
	BEGIN
		SELECT 		@is_valid = 0 	 
		EXEC		amGetErrorMessage_sp 
								24014, "tmp/imchaspr.sp", 442, 
								@asset_ctrl_num, @apply_date, 
								@error_message = @message OUT 
		IF @message IS NOT NULL RAISERROR 	24014 @message

		IF @stop_on_error = 1
			RETURN 0
	END
	
	IF @trx_type <> 50
	BEGIN
			
		SELECT 	@num_activities = COUNT(co_trx_id)
		FROM	amacthst
		WHERE	co_trx_id 		= @co_trx_id

		IF @num_books <> @num_activities
		BEGIN

			SELECT	@param1 	= CONVERT(char(255), @num_books),
					@param2		= CONVERT(char(255), @num_activities),
					@param3		= CONVERT(char(255), @apply_date)
			SELECT 		@is_valid = 0 
			EXEC		amGetErrorMessage_sp 
									24001, "tmp/imchaspr.sp", 469, 
									@asset_ctrl_num, @param1, @param2, @param3, 
									@error_message = @message OUT 
			IF @message IS NOT NULL RAISERROR 	24001 @message

			IF @stop_on_error = 1
				RETURN 0
		END
	END

	
	IF 	@first_profile_date IS NOT NULL
	AND @first_profile_date < @acquisition_date
	BEGIN
		SELECT		@param1 	= CONVERT(char(255), @first_profile_date),
					@param2		= CONVERT(char(255), @acquisition_date),
			 		@is_valid = 0 
		EXEC		amGetErrorMessage_sp 
							24003, "tmp/imchaspr.sp", 490, 
							@asset_ctrl_num, @param1, @param2, 
							@error_message = @message OUT 
		IF @message IS NOT NULL RAISERROR 	24003 @message

		IF @stop_on_error = 1
			RETURN 0
	END
	
	IF (@trx_type != 10)
	OR (@trx_type = 10 AND @apply_date <> @acquisition_date)
	BEGIN
		IF 	(@last_profile_date IS NOT NULL)
		AND (@apply_date < @last_profile_date)
		BEGIN
			SELECT		@param1 	= CONVERT(char(255), @apply_date),
						@param2		= CONVERT(char(255), @last_profile_date),
				 		@is_valid = 0 
			EXEC		amGetErrorMessage_sp 
									24004, "tmp/imchaspr.sp", 509,
									@asset_ctrl_num, @param1, @param2, 
									@error_message = @message OUT 
			IF @message IS NOT NULL RAISERROR 	24004 @message

			IF @stop_on_error = 1
				RETURN 0
		END
	
	END
	
	IF 	@trx_type 			NOT IN (30, 60)
	AND	@disposition_date 	IS NOT NULL
	BEGIN
		
		IF @apply_date > @disposition_date
		BEGIN
			SELECT 		@param1 	= CONVERT(char(255), @apply_date),
				 		@param2		= CONVERT(char(255), @disposition_date),
			 			@is_valid = 0 
			EXEC		amGetErrorMessage_sp 
								24015, "tmp/imchaspr.sp", 532, 
								@asset_ctrl_num, @param1, @param2, 
								@error_message = @message OUT 
			IF @message IS NOT NULL RAISERROR 	24015 @message

			IF @stop_on_error = 1
				RETURN 0
		END
	END

	IF @trx_type = 60
	BEGIN
		IF NOT EXISTS(SELECT co_trx_id
						FROM	amtrxhdr
						WHERE	co_asset_id = @co_asset_id
						AND		apply_date	= @apply_date
						AND		trx_type	IN (30, 70))
		BEGIN
			SELECT 		@param1 	= CONVERT(char(255), @apply_date)
			
			EXEC		amGetErrorMessage_sp 
								24018, "tmp/imchaspr.sp", 553, 
								@asset_ctrl_num, @param1, 
								@error_message = @message OUT 
			IF @message IS NOT NULL RAISERROR 	24018 @message

			IF @stop_on_error = 1
				RETURN 0
		END
	END
	
	
	SELECT	@co_trx_id			= MIN(co_trx_id)
	FROM	amacthst	ah,
			amastbk		ab
	WHERE	ah.co_asset_book_id	= ab.co_asset_book_id
	AND		ab.co_asset_id		= @co_asset_id
	AND		co_trx_id			> @co_trx_id


END


IF @is_new = 0
BEGIN
	
	EXEC @result = imCheckDispInfo_sp 
						@co_asset_id, 			
						@asset_ctrl_num, 		
						@acquisition_date,			
						@disposition_date,		
						@last_profile_date,		
						@stop_on_error,			
						@curr_precision,		
						@is_valid 	OUTPUT,		
						@debug_level	= @debug_level

	IF @result <> 0
		RETURN @result
END
	
	
IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/imchaspr.sp" + ", line " + STR( 598, 5 ) + " -- EXIT: "

RETURN 0 
GO
GRANT EXECUTE ON  [dbo].[imCheckAssetForPromotion_sp] TO [public]
GO
