SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[amUpdateDisposition_sp] 
( 
	@company_id				smCompanyID,			
	@co_asset_id 			smSurrogateKey, 		
	@co_asset_book_id 		smSurrogateKey, 		
	@disp_co_trx_id			smSurrogateKey,			
	@user_id				smUserID,				
	@debug_level			smDebugLevel 	= 0 	
)
AS 

DECLARE 
	@result		 			smErrorCode, 		
	@message				smErrorLongDesc,	
	@param1					smErrorParam,		
	@param2					smErrorParam,		
	@book_code				smBookCode,			
	@trx_type				smTrxType,			
	@last_disp_date			smApplyDate,		
	@last_posted_depr_date	smApplyDate,		
	@last_depr_co_trx_id	smSurrogateKey,
	@disposition_date		smApplyDate,		
	@prev_yr_end_date		smApplyDate,		
	@prev_prd_end_date		smApplyDate,		
	@disp_yr_start_date		smApplyDate,		
	@placed_in_service_date	smApplyDate,		
	@asset_ctrl_num 		smControlNumber, 	
	@disp_trx_ctrl_num		smControlNumber,	
	@depr_co_trx_id			smSurrogateKey,		
	@cur_precision 			smallint,			
	@rounding_factor 		float,				
	@full_disposition		smLogical,			
	@proceeds				smMoneyZero,		
	@cost_of_removal		smMoneyZero,		
	@cost_disposed			smMoneyZero, 			
	@depr_expense 			smMoneyZero, 		
	@cost 					smMoneyZero, 		
	@accum_depr 			smMoneyZero, 		
	@depr_ytd				smMoneyZero,
	@gain_or_loss	 		smMoneyZero,
	@posting_flag			smPostingState
 
IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amupddsp.sp" + ", line " + STR( 127, 5 ) + " -- ENTRY: "

SELECT dummy_select = 1



SELECT 	@asset_ctrl_num 	= asset_ctrl_num
FROM	amasset
WHERE	co_asset_id			= @co_asset_id

SELECT 	@last_posted_depr_date	= last_posted_depr_date,
		@last_depr_co_trx_id	= last_depr_co_trx_id,
		@placed_in_service_date	= placed_in_service_date,
		@book_code				= book_code
FROM	amastbk
WHERE	co_asset_book_id		= @co_asset_book_id
	

SELECT 	@posting_flag 		= posting_flag
FROM	amacthst
WHERE	co_asset_book_id 	= @co_asset_book_id
AND		co_trx_id 			= @disp_co_trx_id

IF @posting_flag != 0
BEGIN
	EXEC 		amGetErrorMessage_sp 
							20096, "tmp/amupddsp.sp", 157, 
							@asset_ctrl_num, @book_code,
							@error_message = @message OUT 
	IF @message IS NOT NULL RAISERROR 	20096 @message 
	RETURN		20096

END

 
EXEC @result = amGetCurrencyPrecision_sp 
						@cur_precision 		OUTPUT,
						@rounding_factor 	OUTPUT 

IF @result <> 0 
	RETURN @result 


SELECT	@cost_disposed		= 0.0,
		@proceeds 			= 0.0,
		@cost_of_removal	= 0.0

SELECT	@disposition_date 	= apply_date,
		@trx_type			= trx_type,
		@disp_trx_ctrl_num	= trx_ctrl_num,
		@depr_co_trx_id		= linked_trx
FROM	amtrxhdr
WHERE	co_trx_id			= @disp_co_trx_id
AND		co_asset_id			= @co_asset_id

SELECT	@cost_disposed		= - amount
FROM	amvalues
WHERE	co_trx_id			= @disp_co_trx_id
AND		co_asset_book_id	= @co_asset_book_id
AND		account_type_id		= 0

SELECT	@proceeds			= amount
FROM	amvalues
WHERE	co_trx_id			= @disp_co_trx_id
AND		co_asset_book_id	= @co_asset_book_id
AND		account_type_id		= 4

SELECT	@cost_of_removal	= amount
FROM	amvalues
WHERE	co_trx_id			= @disp_co_trx_id
AND		co_asset_book_id	= @co_asset_book_id
AND		account_type_id		= 6

IF @debug_level >= 3
	SELECT	disp_co_trx_id	= @disp_co_trx_id,
			depr_co_trx_id	= @depr_co_trx_id

EXEC @result = amGetFiscalYear_sp
				@disposition_date,
				0,
				@disp_yr_start_date OUTPUT
IF @result <> 0
	RETURN @result

SELECT 	@prev_yr_end_date = DATEADD(dd, -1, @disp_yr_start_date),
	 	@full_disposition = 1

	
IF @trx_type = 70 
BEGIN
	IF @debug_level >= 3
		SELECT "Partial Disposition. Checking last posted depreciation dates"
	
	SELECT @full_disposition = 0
	
	EXEC @result = amGetFiscalPeriod_sp
					@disposition_date,
					0,
					@prev_prd_end_date OUTPUT
	IF @result <> 0
		RETURN @result
		
	SELECT	@prev_prd_end_date = DATEADD(dd, -1, @prev_prd_end_date)

	
	IF 	(	@last_posted_depr_date IS NOT NULL
		AND @last_posted_depr_date <> @prev_prd_end_date)
	OR	(	@last_posted_depr_date	IS NULL
		AND	@placed_in_service_date	<= @prev_prd_end_date)

	BEGIN
		EXEC 		amGetErrorMessage_sp 
								20129, "tmp/amupddsp.sp", 250, 
								@asset_ctrl_num, 
								@error_message = @message OUT 
		IF @message IS NOT NULL RAISERROR 	20129 @message 
		RETURN		20129
	END

END
ELSE
BEGIN
	

	IF 	@placed_in_service_date IS NOT NULL
	AND	@placed_in_service_date < @disp_yr_start_date
	AND	@last_posted_depr_date < @prev_yr_end_date
	BEGIN
		EXEC 		amGetErrorMessage_sp 
								20127, "tmp/amupddsp.sp", 271, 
								@asset_ctrl_num, 
								@error_message = @message OUT 
		IF @message IS NOT NULL RAISERROR 	20127 @message 
		RETURN		20127
	END
END



IF EXISTS(SELECT 	co_asset_book_id
			FROM 	amvalues	v
			WHERE	v.co_asset_book_id	= @co_asset_book_id
			AND		v.trx_type			= 50
			AND		v.posting_flag		!= 1)
BEGIN
	EXEC 		amGetErrorMessage_sp 
							20126, "tmp/amupddsp.sp", 292, 
							@asset_ctrl_num, 
							@error_message = @message OUT 
	IF @message IS NOT NULL RAISERROR 	20126 @message 
	RETURN		20126
END

IF EXISTS (SELECT 	process_id
			FROM 	amco
			WHERE 	process_id != 0)
BEGIN
	EXEC 		amGetErrorMessage_sp 
							20122, "tmp/amupddsp.sp", 304, 
							@error_message = @message OUT 
	IF @message IS NOT NULL RAISERROR 	20122 @message 
	RETURN		20122
END


UPDATE 	amacthst
SET		disposed_depr		= 0.0
WHERE	co_trx_id			= @disp_co_trx_id
AND		co_asset_book_id	= @co_asset_book_id

SELECT @result = @@error
IF @result <> 0
	RETURN @result

UPDATE 	amvalues
SET		amount 				= 0.0
WHERE	co_trx_id			= @depr_co_trx_id
AND		co_asset_book_id	= @co_asset_book_id

SELECT @result = @@error
IF @result <> 0
	RETURN @result


EXEC @result = amCalcOneBookFinalDepr_sp 
					@co_asset_id,
					@co_asset_book_id,
					@disp_co_trx_id,
					@depr_co_trx_id,
					@disp_trx_ctrl_num,
					@disposition_date,
					@full_disposition,
					@cur_precision,
					@rounding_factor,
					@depr_expense	OUTPUT, 
					@cost 		 	OUTPUT, 
					@accum_depr 	OUTPUT, 
					@depr_ytd	 	OUTPUT,
					@debug_level

IF ( @result != 0 ) 
 	RETURN 		@result 

IF @trx_type = 70 
BEGIN
	IF @debug_level >= 5
		SELECT cost = @cost
		
	
	IF (ABS((@cost)-(0.0)) > 0.0000001)
	BEGIN
		SELECT
				@accum_depr		= (SIGN(@accum_depr * (@cost_disposed/@cost)) * ROUND(ABS(@accum_depr * (@cost_disposed/@cost)) + 0.0000001, @cur_precision)),
				@depr_expense	= (SIGN(@depr_expense * (@cost_disposed/@cost)) * ROUND(ABS(@depr_expense * (@cost_disposed/@cost)) + 0.0000001, @cur_precision)),
				@depr_ytd		= (SIGN(@depr_ytd * (@cost_disposed/@cost)) * ROUND(ABS(@depr_ytd * (@cost_disposed/@cost)) + 0.0000001, @cur_precision))
	END
	ELSE
	BEGIN
		SELECT
				@accum_depr		= 0.0,
				@depr_expense	= 0.0,
				@depr_ytd		= 0.0
	END
END



SELECT		@gain_or_loss	= (SIGN(@cost_disposed + @accum_depr - @proceeds - @cost_of_removal) * ROUND(ABS(@cost_disposed + @accum_depr - @proceeds - @cost_of_removal) + 0.0000001, @cur_precision))	

IF @debug_level >= 3
	SELECT 	cost			= @cost,
			accum_depr 		= @accum_depr,
			cost_disposed	= @cost_disposed,
			depr_ytd		= @depr_ytd,
			depr_expense	= @depr_expense


EXEC @result = amSaveBookDisposition_sp
					@co_asset_book_id,
					@asset_ctrl_num,
					@disposition_date,
					@trx_type,
					@disp_co_trx_id,
					@depr_co_trx_id,
					@depr_expense, 
					@accum_depr, 
					@depr_ytd,
					@gain_or_loss,
					@last_posted_depr_date,
					@last_depr_co_trx_id,
					@debug_level

IF @result <> 0
 	RETURN 		@result 



IF EXISTS (SELECT	co_asset_book_id
			FROM	amdprhst dh,
					amdprrul dr
			WHERE	dh.co_asset_book_id	= @co_asset_book_id
			AND		dh.effective_date	= (SELECT MAX(effective_date)
												FROM	amdprhst
												WHERE	co_asset_book_id	= @co_asset_book_id
												AND		effective_date		<= @disposition_date)
			AND		dh.depr_rule_code	= dr.depr_rule_code
			AND		dr.depr_method_id	= 7)

BEGIN
	EXEC 		amGetErrorMessage_sp 
							20181, "tmp/amupddsp.sp", 432, 
							@asset_ctrl_num, @book_code, 
							@error_message = @message OUT 
	IF @message IS NOT NULL RAISERROR 	20181 @message 

END

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amupddsp.sp" + ", line " + STR( 439, 5 ) + " -- EXIT: "

RETURN 0 
GO
GRANT EXECUTE ON  [dbo].[amUpdateDisposition_sp] TO [public]
GO
