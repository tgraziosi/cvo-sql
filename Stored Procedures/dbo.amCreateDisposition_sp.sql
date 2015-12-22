SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[amCreateDisposition_sp] 
( 
	@company_id				smCompanyID,				
	@co_asset_id 			smSurrogateKey, 			
	@disp_date				smISODate,					
	@proceeds				smMoneyZero,				
	@cost_of_removal		smMoneyZero,				
	@user_id				smUserID,					
	@full_disposition		smLogical			= 1,	
	@trx_subtype			smTrxSubtype 		= 0, 	
	@proportion_disposed	smRevaluationRate 	= 100.0,	
	@debug_level			smDebugLevel 		= 0 	
)
AS 

DECLARE 
	@result		 			smErrorCode, 		
	@message				smErrorLongDesc,	
	@param1					smErrorParam,		
	@param2					smErrorParam,		
	@rowcount				smCounter,			
	@num_books				smCounter,			
	@book_code				smBookCode,			
	@trx_type				smTrxType,			
	@last_disp_date			smApplyDate,		
	@last_posted_depr_date	smApplyDate,		
	@disposition_date		smApplyDate,		
	@prev_yr_end_date		smApplyDate,		
	@prev_prd_end_date		smApplyDate,		
	@disp_yr_start_date		smApplyDate,		
	@acquisition_date		smApplyDate,		
	@placed_in_service_date	smApplyDate,		
	@asset_ctrl_num 		smControlNumber, 	
	@home_currency_code		smCurrencyCode,		
	@depr_expense 			smMoneyZero, 		
	@cost 					smMoneyZero, 		
	@accum_depr 			smMoneyZero, 		
	@disp_trx_ctrl_num		smControlNumber,	
	@depr_trx_ctrl_num		smControlNumber,	
	@disp_co_trx_id			smSurrogateKey,		
	@depr_co_trx_id			smSurrogateKey,		
	@activity_state			smSystemState,		
	@percent_disposed		smRevaluationRate,	
	@cur_precision 			smallint,			
	@rounding_factor 		float,				
	@new_disp_date			smApplyDate,		
	@new_activity_state		smSystemState,		
	@current_quantity		smQuantity,			
	@quantity_disposed		smQuantity			
	
IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amcredsp.sp" + ", line " + STR( 149, 5 ) + " -- ENTRY: "

SELECT dummy_select = 1

 
EXEC @result = amGetCurrencyPrecision_sp 
						@cur_precision 		OUTPUT,
						@rounding_factor 	OUTPUT 

IF @result <> 0 
	RETURN @result 

SELECT @disp_date = RTRIM(@disp_date)

IF @disp_date IS NULL OR @disp_date = ""
	SELECT @disposition_date = GETDATE()
ELSE
	SELECT @disposition_date = CONVERT(datetime, @disp_date)


SELECT 	@asset_ctrl_num 	= asset_ctrl_num,
		@activity_state		= activity_state,
		@acquisition_date	= acquisition_date
FROM	amasset
WHERE	co_asset_id			= @co_asset_id

EXEC @result = amGetFiscalYear_sp
				@disposition_date,
				0,
				@disp_yr_start_date OUTPUT
IF @result <> 0
	RETURN @result

SELECT @prev_yr_end_date = DATEADD(dd, -1, @disp_yr_start_date)
	
IF @full_disposition = 0 
BEGIN
	IF @debug_level >= 3
		SELECT "Partial Disposition. Checking last posted depreciation dates"
	
	
	EXEC @result = amGetFiscalPeriod_sp
					@disposition_date,
					0,
					@prev_prd_end_date OUTPUT
	IF @result <> 0
		RETURN @result
		
	SELECT	@prev_prd_end_date = DATEADD(dd, -1, @prev_prd_end_date)

	IF EXISTS(SELECT	last_posted_depr_date
				FROM	amastbk
				WHERE	co_asset_id				= @co_asset_id
				AND		(	(	last_posted_depr_date IS NOT NULL
							AND	last_posted_depr_date 	<> @prev_prd_end_date)
					OR		(last_posted_depr_date	IS NULL
							AND		placed_in_service_date	<= @prev_prd_end_date)))
	BEGIN
		EXEC 		amGetErrorMessage_sp 
								20129, "tmp/amcredsp.sp", 213, 
								@asset_ctrl_num, 
								@error_message = @message OUT 
		IF @message IS NOT NULL RAISERROR 	20129 @message 
		RETURN		20129
	END

	SELECT	@last_disp_date 	= NULL
	
	SELECT	@last_disp_date		= MAX(apply_date)
	FROM	amtrxhdr
	WHERE	co_asset_id			= @co_asset_id
	AND		trx_type			= 70
				
	IF 	@last_disp_date 	IS NOT NULL
	AND	@disposition_date 	<= @last_disp_date
	BEGIN
		SELECT		@param1 = RTRIM(CONVERT(varchar(255), @disposition_date, 107))

		EXEC 		amGetErrorMessage_sp 
								20577, "tmp/amcredsp.sp", 233, 
								@param1, @asset_ctrl_num, 
								@error_message = @message OUT 
		IF @message IS NOT NULL RAISERROR 	20577 @message 
		RETURN 		20577
	END			

	SELECT	@trx_type		 		= 70,
			@new_disp_date			= NULL,
			@new_activity_state		= 0
	
END
ELSE 
BEGIN
	
	IF EXISTS (SELECT 	co_trx_id
				FROM	amtrxhdr
				WHERE	co_asset_id 	= @co_asset_id
				AND		apply_date		>= @disposition_date)
	BEGIN
		EXEC 		amGetErrorMessage_sp 
								20118, "tmp/amcredsp.sp", 256, 
								@asset_ctrl_num, 
								@error_message = @message OUT 
		IF @message IS NOT NULL RAISERROR 	20118 @message 
		RETURN		20118
	END
	
	SELECT	@last_posted_depr_date 	= MAX(last_posted_depr_date)
	FROM	amastbk
	WHERE	co_asset_id 			= @co_asset_id
	
	IF @disposition_date <= @last_posted_depr_date
	BEGIN
		SELECT 		@param1 = RTRIM(CONVERT(varchar(255), @last_posted_depr_date, 107))

		EXEC 		amGetErrorMessage_sp 
								20081, "tmp/amcredsp.sp", 272, 
								@asset_ctrl_num, @param1, 
								@error_message = @message OUT 
		IF @message IS NOT NULL RAISERROR 	20081 @message 
		RETURN		20081
	END

	SELECT	@trx_type				= 30,
			@new_disp_date			= @disposition_date,
			@new_activity_state		= 1
END


IF @disposition_date < @acquisition_date
BEGIN
	SELECT 		@param1 = RTRIM(CONVERT(varchar(255), @disposition_date, 107)),
				@param2 = RTRIM(CONVERT(varchar(255), @acquisition_date, 107))

	EXEC 		amGetErrorMessage_sp 
							20087, "tmp/amcredsp.sp", 298, 
							@asset_ctrl_num, @param1, @param2,
							@error_message = @message OUT 
	IF @message IS NOT NULL RAISERROR 	20087 @message 
	RETURN		20087
END

IF EXISTS(SELECT 	co_asset_id
			FROM 	amastbk 	ab,
					amvalues	v
			WHERE	ab.co_asset_id 		= @co_asset_id
			AND		ab.co_asset_book_id	= v.co_asset_book_id
			AND		v.trx_type			= 50
			AND		v.posting_flag		!= 1)
BEGIN
	EXEC 		amGetErrorMessage_sp 
							20126, "tmp/amcredsp.sp", 314, 
							@asset_ctrl_num, 
							@error_message = @message OUT 
	IF @message IS NOT NULL RAISERROR 	20126 @message 
	RETURN		20126
END

IF EXISTS(SELECT	co_asset_book_id
			FROM	amastbk
			WHERE	co_asset_id				= @co_asset_id
			AND		placed_in_service_date 	IS NOT NULL
			AND		placed_in_service_date	< @disp_yr_start_date
			AND		last_posted_depr_date	< @prev_yr_end_date)
			
BEGIN
	EXEC 		amGetErrorMessage_sp 
							20127, "tmp/amcredsp.sp", 330, 
							@asset_ctrl_num, 
							@error_message = @message OUT 
	IF @message IS NOT NULL RAISERROR 	20127 @message 
	RETURN		20127
END

IF EXISTS (SELECT 	process_id
			FROM 	amco
			WHERE 	process_id != 0)
BEGIN
	EXEC 		amGetErrorMessage_sp 
							20122, "tmp/amcredsp.sp", 342, 
							@error_message = @message OUT 
	IF @message IS NOT NULL RAISERROR 	20122 @message 
	RETURN		20122
END

SELECT 	@activity_state = activity_state
FROM	amasset
WHERE	co_asset_id		= @co_asset_id

IF 	@activity_state 	!= 0
AND	@full_disposition 	= 1
BEGIN
	EXEC 		amGetErrorMessage_sp 
							20128, "tmp/amcredsp.sp", 356, 
							@asset_ctrl_num, 
							@error_message = @message OUT 
	IF @message IS NOT NULL RAISERROR 	20128 @message 
	RETURN		20128
END

		
EXEC 	@result = amGetCurrencyCode_sp
					@company_id,
					@home_currency_code OUTPUT
IF @result <> 0
	RETURN @result


EXEC @result = amNextControlNumber_sp
				@company_id,
				5,
				@depr_trx_ctrl_num OUTPUT,
				@debug_level

IF @result <> 0
 	RETURN @result 

EXEC @result = amNextControlNumber_sp
				@company_id,
				5,
				@disp_trx_ctrl_num OUTPUT,
				@debug_level

IF @result <> 0
 	RETURN @result 

EXEC @result = amNextKey_sp
				7,
				@depr_co_trx_id OUTPUT
				
IF @result <> 0
 	RETURN @result 

EXEC @result = amNextKey_sp
				7,
				@disp_co_trx_id OUTPUT
				
IF @result <> 0
 	RETURN @result 

IF @debug_level >= 3
	SELECT	disp_co_trx_id	= @disp_co_trx_id,
			depr_co_trx_id	= @depr_co_trx_id
			



CREATE TABLE #amdspamt
(	
	co_asset_book_id			int,			
	cost						float,			
	accum_depr					float,			
	depr_expense 				float,			
	gain_or_loss				float,			
	depr_ytd					float			
)






CREATE TABLE #amlstdpr
(
	co_asset_book_id		int 		NOT NULL,
	last_posted_depr_date	datetime 	NULL,
	last_depr_co_trx_id		int			NOT NULL
)






INSERT INTO	#amlstdpr
(
		co_asset_book_id,
		last_posted_depr_date,
		last_depr_co_trx_id
)
SELECT
		co_asset_book_id,
		last_posted_depr_date,
		last_depr_co_trx_id
FROM	amastbk
WHERE	co_asset_id 	= @co_asset_id

SELECT @result = @@error, @num_books = @@rowcount
IF @result <> 0
BEGIN
 	DROP TABLE 	#amdstamt
 	DROP TABLE 	#amlstdpr
 	RETURN @result 
END

EXEC @result = amCalcAssetFinalDepr_sp 
					@company_id,
					@co_asset_id,
					@disp_trx_ctrl_num,
					@disposition_date,
					@full_disposition,
					@cur_precision,
					@rounding_factor,
					@debug_level

IF ( @result != 0 ) 
BEGIN 
	DROP TABLE 	#amdspamt 
 	DROP TABLE 	#amlstdpr
 	RETURN 		@result 
END 

SELECT	@placed_in_service_date = MIN(placed_in_service_date)
FROM	amastbk
WHERE	co_asset_id				= @co_asset_id


SELECT 	@current_quantity 	= orig_quantity
FROM	amasset
WHERE	co_asset_id			= @co_asset_id

SELECT	@current_quantity	= @current_quantity + ISNULL(SUM(change_in_quantity), 0)
FROM	amtrxhdr 	th,
		amastbk 	ab,
		ambook		b
WHERE	th.co_asset_id		= @co_asset_id
AND		th.posting_flag		!= 1		
AND		ab.co_asset_id 		= @co_asset_id
AND		th.co_asset_id		= ab.co_asset_id
AND		ab.book_code		= b.book_code
AND		b.post_to_gl 		= 1
AND		th.apply_date		<= @disposition_date

IF @full_disposition = 0
BEGIN
	
	IF @debug_level >= 3
		SELECT * FROM #amdspamt

	IF @debug_level >= 3
		SELECT 	trx_subtype			= @trx_subtype,
				proportion_disposed = @proportion_disposed,
				current_quantity	= @current_quantity
	
	IF @trx_subtype = 0
	BEGIN
		UPDATE	#amdspamt
		SET		accum_depr		= (SIGN(accum_depr * @proportion_disposed / 100.00) * ROUND(ABS(accum_depr * @proportion_disposed / 100.00) + 0.0000001, @cur_precision)),
				depr_expense	= (SIGN(depr_expense * @proportion_disposed / 100.00) * ROUND(ABS(depr_expense * @proportion_disposed / 100.00) + 0.0000001, @cur_precision)),
				cost			= (SIGN(cost * @proportion_disposed / 100.00) * ROUND(ABS(cost * @proportion_disposed / 100.00) + 0.0000001, @cur_precision)),
				depr_ytd		= (SIGN(depr_ytd * @proportion_disposed / 100.00) * ROUND(ABS(depr_ytd * @proportion_disposed / 100.00) + 0.0000001, @cur_precision))
		FROM	#amdspamt

		SELECT	@result = @@error
		IF @result <> 0
		BEGIN 
			DROP TABLE 	#amdspamt 
		 	DROP TABLE 	#amlstdpr
		 	RETURN 		@result 
		END 

		SELECT	@quantity_disposed = - @current_quantity * (@proportion_disposed/100.00)
	END
	ELSE IF @trx_subtype = 2
	BEGIN
		DECLARE	@percentage_disposed 	smPercentage
		
		SELECT	@percentage_disposed = 0.0
		
		SELECT	@percentage_disposed 	= (ABS(@proportion_disposed / cost))
		FROM	#amdspamt tmp,
				amastbk ab,
				ambook	b
		WHERE	tmp.co_asset_book_id 	= ab.co_asset_book_id
		AND		ab.book_code			= b.book_code
		AND		b.post_to_gl			= 1
		AND		(ABS((cost)-(0.0)) > 0.0000001) 
		
		UPDATE	#amdspamt
		SET		accum_depr		= (SIGN(accum_depr * (ABS(@proportion_disposed/cost))) * ROUND(ABS(accum_depr * (ABS(@proportion_disposed/cost))) + 0.0000001, @cur_precision)),
				depr_expense	= (SIGN(depr_expense * (ABS(@proportion_disposed/cost))) * ROUND(ABS(depr_expense * (ABS(@proportion_disposed/cost))) + 0.0000001, @cur_precision)),
				cost			= (SIGN(@proportion_disposed * (SIGN(cost))) * ROUND(ABS(@proportion_disposed * (SIGN(cost))) + 0.0000001, @cur_precision)),
				depr_ytd		= (SIGN(depr_ytd * (ABS(@proportion_disposed/cost))) * ROUND(ABS(depr_ytd * (ABS(@proportion_disposed/cost))) + 0.0000001, @cur_precision))
		FROM	#amdspamt
		WHERE	(ABS((cost)-(0.0)) > 0.0000001)

		SELECT	@result = @@error
		IF @result <> 0
		BEGIN 
			DROP TABLE 	#amdspamt 
		 	DROP TABLE 	#amlstdpr
		 	RETURN 		@result 
		END 
		
		UPDATE	#amdspamt
		SET		accum_depr		= (SIGN(0.0) * ROUND(ABS(0.0) + 0.0000001, @cur_precision)),
				depr_expense	= (SIGN(0.0) * ROUND(ABS(0.0) + 0.0000001, @cur_precision)),
				cost			= (SIGN(0.0) * ROUND(ABS(0.0) + 0.0000001, @cur_precision)),
				depr_ytd		= (SIGN(0.0) * ROUND(ABS(0.0) + 0.0000001, @cur_precision))
		FROM	#amdspamt
		WHERE	(ABS((cost)-(0.0)) < 0.0000001)

		SELECT	@result = @@error
		IF @result <> 0
		BEGIN 
			DROP TABLE 	#amdspamt 
		 	DROP TABLE 	#amlstdpr
		 	RETURN 		@result 
		END 
		
		IF @debug_level >= 3
			SELECT 	current_quantity	= @current_quantity,
					percentage_disposed = @percentage_disposed
		
		SELECT	@quantity_disposed = - @current_quantity * @percentage_disposed
	END
	ELSE
	BEGIN
		IF @current_quantity > 0
		BEGIN
			IF @proportion_disposed > @current_quantity
			BEGIN
				EXEC 		amGetErrorMessage_sp 
										20182, "tmp/amcredsp.sp", 579, 
										@error_message = @message OUT 
				IF @message IS NOT NULL RAISERROR 	20182 @message 

				SELECT	@proportion_disposed 	= @current_quantity,
						@quantity_disposed		= -@current_quantity
			END
			ELSE
				SELECT	@quantity_disposed		= -@proportion_disposed
				
		
			UPDATE	#amdspamt
			SET		accum_depr		= (SIGN(accum_depr * (@proportion_disposed/@current_quantity)) * ROUND(ABS(accum_depr * (@proportion_disposed/@current_quantity)) + 0.0000001, @cur_precision)),
					depr_expense	= (SIGN(depr_expense * (@proportion_disposed/@current_quantity)) * ROUND(ABS(depr_expense * (@proportion_disposed/@current_quantity)) + 0.0000001, @cur_precision)),
					cost			= (SIGN(cost * @proportion_disposed/@current_quantity) * ROUND(ABS(cost * @proportion_disposed/@current_quantity) + 0.0000001, @cur_precision)),
					depr_ytd		= (SIGN(depr_ytd * @proportion_disposed/@current_quantity) * ROUND(ABS(depr_ytd * @proportion_disposed/@current_quantity) + 0.0000001, @cur_precision))
			FROM	#amdspamt

			SELECT	@result = @@error
			IF @result <> 0
			BEGIN 
				DROP TABLE 	#amdspamt 
			 	DROP TABLE 	#amlstdpr
			 	RETURN 		@result 
			END
		END
		ELSE 
		BEGIN
			IF @proportion_disposed	!= 0
			BEGIN
				EXEC 		amGetErrorMessage_sp 
										20182, "tmp/amcredsp.sp", 610, 
										@error_message = @message OUT 
				IF @message IS NOT NULL RAISERROR 	20182 @message 
			END
			
			SELECT	@quantity_disposed = 0

			UPDATE	#amdspamt
			SET		accum_depr		= (SIGN(0.0) * ROUND(ABS(0.0) + 0.0000001, @cur_precision)),
					depr_expense	= (SIGN(0.0) * ROUND(ABS(0.0) + 0.0000001, @cur_precision)),
					cost			= (SIGN(0.0) * ROUND(ABS(0.0) + 0.0000001, @cur_precision)),
					depr_ytd		= (SIGN(0.0) * ROUND(ABS(0.0) + 0.0000001, @cur_precision))
			FROM	#amdspamt

			SELECT	@result = @@error
			IF @result <> 0
			BEGIN 
				DROP TABLE 	#amdspamt 
			 	DROP TABLE 	#amlstdpr
			 	RETURN 		@result 
			END
		END 
	END
END
ELSE 
	SELECT	@quantity_disposed = - @current_quantity 



UPDATE 	#amdspamt
SET		gain_or_loss	= (SIGN(cost + accum_depr - @proceeds - @cost_of_removal) * ROUND(ABS(cost + accum_depr - @proceeds - @cost_of_removal) + 0.0000001, @cur_precision))	

SELECT	@result = @@error
IF @result <> 0
BEGIN 
	DROP TABLE 	#amdspamt 
 	DROP TABLE 	#amlstdpr
 	RETURN 		@result 
END 

IF @debug_level >= 3
	SELECT * FROM #amdspamt
	

EXEC @result = amSaveDisposition_sp
					@company_id,
					@co_asset_id,
					@asset_ctrl_num,
					@disposition_date,
					@proceeds,
					@cost_of_removal,
					@user_id,
					@trx_type,
					@trx_subtype,
					@home_currency_code,
					@disp_trx_ctrl_num,
					@depr_trx_ctrl_num,
					@disp_co_trx_id,
					@depr_co_trx_id,
					@new_disp_date,
					@new_activity_state,
					@num_books,
					@proportion_disposed,
					@quantity_disposed,
					@debug_level

IF @result <> 0
BEGIN 
	DROP TABLE 	#amdspamt 
 	DROP TABLE 	#amlstdpr
 	RETURN 		@result 
END 

 
DROP TABLE #amdspamt
DROP TABLE #amlstdpr



SELECT	@book_code 			= MIN(book_code)
FROM	amastbk ab,
		amdprhst dh,
		amdprrul dr
WHERE	ab.co_asset_id 		= @co_asset_id
AND		ab.co_asset_book_id	= dh.co_asset_book_id
AND		dh.effective_date	= (SELECT MAX(effective_date)
									FROM	amdprhst
									WHERE	co_asset_book_id	= dh.co_asset_book_id
									AND		co_asset_book_id	= ab.co_asset_book_id
									AND		effective_date		<= @disposition_date)
AND		dh.depr_rule_code	= dr.depr_rule_code
AND		dr.depr_method_id	= 7

WHILE @book_code IS NOT NULL
BEGIN
	EXEC 		amGetErrorMessage_sp 
							20181, "tmp/amcredsp.sp", 713, 
							@asset_ctrl_num, @book_code, 
							@error_message = @message OUT 
	IF @message IS NOT NULL RAISERROR 	20181 @message 
	
	SELECT	@book_code 			= MIN(book_code)
	FROM	amastbk ab,
			amdprhst dh,
			amdprrul dr
	WHERE	ab.co_asset_id 		= @co_asset_id
	AND		ab.co_asset_book_id	= dh.co_asset_book_id
	AND		dh.effective_date	= (SELECT MAX(effective_date)
										FROM	amdprhst
										WHERE	co_asset_book_id	= dh.co_asset_book_id
										AND		co_asset_book_id	= ab.co_asset_book_id
										AND		effective_date		<= @disposition_date)
	AND		dh.depr_rule_code	= dr.depr_rule_code
	AND		dr.depr_method_id	= 7
	AND		ab.book_code		> @book_code

END

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amcredsp.sp" + ", line " + STR( 735, 5 ) + " -- EXIT: "

RETURN 0 
GO
GRANT EXECUTE ON  [dbo].[amCreateDisposition_sp] TO [public]
GO
