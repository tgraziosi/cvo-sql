SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[amCreateProfExistAssets_sp] 
(
 @company_id				smCompanyID,			
 @co_asset_id 	smSurrogateKey, 		
	@acq_date 				smISODate, 				 
	@placed_date 			smISODate, 				 
	@cost 					smMoneyZero, 			 
	@debug_level			smDebugLevel	= 0		
)
AS 

DECLARE 
	@result 				smErrorCode, 
	@message 				smErrorLongDesc,
	@co_asset_book_id 		smSurrogateKey, 
	@acquisition_date		smApplyDate, 
	@prd_end_date 			smApplyDate, 
	@cur_yr_start 			smApplyDate, 
	@prev_yr_end 			smApplyDate,
	@effective_date			smApplyDate,
	@placed_in_service_date	smApplyDate,
	@asset_ctrl_num			smControlNumber,
	@book_code				smBookCode 
 
IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amcrprex.sp" + ", line " + STR( 112, 5 ) + " -- ENTRY: " 

SELECT	@acquisition_date = CONVERT(datetime, @acq_date)

 
EXEC @result = amGetCurrentFiscalPeriod_sp 
					@company_id, 
					@prd_end_date 	OUT 
IF @result <> 0 
	RETURN @result 


EXEC @result = amGetFiscalYear_sp 
					@prd_end_date, 
					0,
					@cur_yr_start OUT 

IF @result <> 0 
	RETURN @result 

SELECT @prev_yr_end = DATEADD(dd, -1, @cur_yr_start)

IF @debug_level >= 3
	SELECT 	cur_yr_start 	= @cur_yr_start,
			prev_yr_end		= @prev_yr_end 


IF 	@acquisition_date < @cur_yr_start 
BEGIN 
	
	IF NOT EXISTS(SELECT 	ab.co_asset_book_id
					FROM	amastprf ap,
							amastbk ab
					WHERE	ap.co_asset_book_id = ab.co_asset_book_id
					AND		ab.co_asset_id		= @co_asset_id )
	BEGIN
		 
		SELECT 	@co_asset_book_id 	= MIN(co_asset_book_id)
		FROM 	amastbk 
		WHERE 	co_asset_id 		= @co_asset_id 

		 
		WHILE @co_asset_book_id IS NOT NULL 
		BEGIN 
			
			SELECT 	@placed_in_service_date = placed_in_service_date
			FROM	amastbk
			WHERE	co_asset_book_id		= @co_asset_book_id

			IF 	@placed_in_service_date IS NOT NULL
			AND	@placed_in_service_date < @cur_yr_start 
			BEGIN
				 
				SELECT @effective_date 	= MAX(effective_date)
				FROM 	amdprhst 
				WHERE 	co_asset_book_id 	= @co_asset_book_id 
				AND 	effective_date 		<= @acquisition_date 
			
				 
				INSERT INTO amastprf 
				(
					co_asset_book_id,
					fiscal_period_end,
					current_cost,
					accum_depr,
					effective_date
				)
				VALUES 
				(
					@co_asset_book_id,
					@prev_yr_end,
					@cost,
					0,
					@effective_date
				)

				SELECT	@result = @@error
				IF @result <> 0
					RETURN @result 
			END
			
			ELSE
			BEGIN
				SELECT		@asset_ctrl_num = asset_ctrl_num
				FROM		amasset
				WHERE		co_asset_id		= @co_asset_id

				SELECT		@book_code			= book_code
				FROM		amastbk	
				WHERE		co_asset_book_id	= @co_asset_book_id
				
				IF @asset_ctrl_num IS NULL
					SELECT	@asset_ctrl_num = ""
					
				IF @book_code IS NULL
					SELECT	@book_code = ""
					
				EXEC 		amGetErrorMessage_sp 20402, "tmp/amcrprex.sp", 227, @asset_ctrl_num, @book_code, @error_message = @message OUT 
				IF @message IS NOT NULL RAISERROR 	20402 @message 
				RETURN 		20402 
			END

			 
			SELECT 	@co_asset_book_id 	= MIN(co_asset_book_id)
			FROM 	amastbk 
			WHERE 	co_asset_id 		= @co_asset_id 
			AND 	co_asset_book_id 	> @co_asset_book_id 
		END

	END
END 
ELSE
BEGIN
	
	SELECT		@asset_ctrl_num = asset_ctrl_num
	FROM		amasset
	WHERE		co_asset_id		= @co_asset_id
	
	IF @asset_ctrl_num IS NULL
		SELECT	@asset_ctrl_num = ""
		
	EXEC 		amGetErrorMessage_sp 20401, "tmp/amcrprex.sp", 253, @asset_ctrl_num, @error_message = @message OUT 
	IF @message IS NOT NULL RAISERROR 	20401 @message 
	RETURN 		20401 
END

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amcrprex.sp" + ", line " + STR( 258, 5 ) + " -- EXIT: "

RETURN 0
GO
GRANT EXECUTE ON  [dbo].[amCreateProfExistAssets_sp] TO [public]
GO
