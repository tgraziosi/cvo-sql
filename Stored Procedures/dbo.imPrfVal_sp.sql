SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

 
CREATE PROCEDURE [dbo].[imPrfVal_sp] 
( 
	@action					smallint,
	@company_id				smallint,			
	@asset_ctrl_num			char(16),				
	@book_code				char(8),			
	@fiscal_period_end		char(8),			
	@current_cost			float 		= 0, 	
	@accum_depr				float		= 0,	
	@stop_on_error			tinyint		= 0,	
	@is_valid				tinyint		OUTPUT,	
	@debug_level			smallint	= 0		
)
AS 

DECLARE
	@result					int,				
	@does_exist				tinyint,			
	@param1					varchar(255),		
	@message				varchar(255),		
	@fiscal_period_end_dt	datetime,			
	@fiscal_period_end_jul	int,				
	@cur_prd_end_date		datetime,			
	@co_asset_id			int,				
	@co_asset_book_id		int,				
	@activity_state			tinyint,			
	@is_new					tinyint,			
	@acquisition_date		datetime,			
	@placed_in_service_date	datetime,			
	@last_posted_depr_date	datetime,			
	@is_imported			tinyint				

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/imprfval.sp" + ", line " + STR( 109, 5 ) + " -- ENTRY: "

SELECT 	@is_valid = 1
SELECT 	@fiscal_period_end_dt = CONVERT(datetime, @fiscal_period_end)
SELECT	@fiscal_period_end_jul = DATEDIFF(dd, "1/1/1980", @fiscal_period_end_dt) + 722815

 
EXEC @result = amGetCurrentFiscalPeriod_sp 
						@company_id,
						@cur_prd_end_date OUTPUT 
IF @result <> 0 
	RETURN @result 

EXEC @result = amassetExists_sp
					@company_id, 
					@asset_ctrl_num, 
					@does_exist 	OUTPUT
IF @result <> 0
	RETURN @result


IF @does_exist = 0 
BEGIN
	EXEC 		amGetErrorMessage_sp 21107, "tmp/imprfval.sp", 136, @asset_ctrl_num, @error_message = @message OUT 
	IF @message IS NOT NULL RAISERROR 	21107 @message 
	SELECT 		@is_valid = 0

	IF @stop_on_error = 1
		RETURN 0
END
ELSE
BEGIN
	
	SELECT	@co_asset_id			= co_asset_id,
			@activity_state			= activity_state,
			@acquisition_date		= acquisition_date,
			@is_imported			= is_imported,
			@is_new					= is_new
	FROM	amasset
	WHERE	company_id				= @company_id
	AND		asset_ctrl_num			= @asset_ctrl_num

	IF @activity_state <> 100
	BEGIN
		EXEC 		amGetErrorMessage_sp 21101, "tmp/imprfval.sp", 159, @asset_ctrl_num, @book_code, @fiscal_period_end_dt, @error_message = @message OUT 
		IF @message IS NOT NULL RAISERROR 	21101 @message 
		SELECT 		@is_valid = 0

		IF @stop_on_error = 1
			RETURN 0
	END

	IF @is_imported = 0
	BEGIN
		EXEC 		amGetErrorMessage_sp 21100, "tmp/imprfval.sp", 169, @asset_ctrl_num, @book_code, @fiscal_period_end_dt, @error_message = @message OUT 
		IF @message IS NOT NULL RAISERROR 	21100 @message 
		SELECT 		@is_valid = 0

		IF @stop_on_error = 1
			RETURN 0
	END

	IF	(@action = 0 OR @action = 2)
	BEGIN
		
		IF @is_new = 1
		BEGIN
			EXEC 		amGetErrorMessage_sp 21106, "tmp/imprfval.sp", 184, @asset_ctrl_num, @book_code, @fiscal_period_end_dt, @error_message = @message OUT 
			IF @message IS NOT NULL RAISERROR 	21106 @message 
			SELECT 		@is_valid = 0

			IF @stop_on_error = 1
				RETURN 0
		END

	END
END


EXEC @result = ambookExists_sp
					@book_code, 
					@does_exist 	OUTPUT
IF @result <> 0
	RETURN @result

IF @does_exist = 0 
BEGIN
	EXEC 		amGetErrorMessage_sp 21108, "tmp/imprfval.sp", 206, @asset_ctrl_num, @book_code, @fiscal_period_end_dt, @error_message = @message OUT 
	IF @message IS NOT NULL RAISERROR 	21108 @message 
	SELECT 		@is_valid = 0

	IF @stop_on_error = 1
		RETURN 0
END
ELSE IF @is_valid = 1	
BEGIN
	
	SELECT	@co_asset_book_id	= NULL
	
	SELECT 	@co_asset_book_id 		= co_asset_book_id,
			@last_posted_depr_date	= last_posted_depr_date,
			@placed_in_service_date	= placed_in_service_date
	FROM	amastbk
	WHERE	co_asset_id 			= @co_asset_id
	AND		book_code				= @book_code

	IF @co_asset_book_id IS NULL
	BEGIN
		EXEC 		amGetErrorMessage_sp 21109, "tmp/imprfval.sp", 229, @asset_ctrl_num, @book_code, @fiscal_period_end_dt, @error_message = @message OUT 
		IF @message IS NOT NULL RAISERROR 	21109 @message 
		SELECT 		@is_valid = 0

		IF @stop_on_error = 1
			RETURN 0
	END
	
	
	ELSE IF @placed_in_service_date IS NULL
	BEGIN
		EXEC 		amGetErrorMessage_sp 21111, "tmp/imprfval.sp", 242, @asset_ctrl_num, @book_code, @fiscal_period_end_dt, @error_message = @message OUT 
		IF @message IS NOT NULL RAISERROR 	21111 @message 
		SELECT 		@is_valid = 0

		IF @stop_on_error = 1
			RETURN 0
	END

END


IF NOT EXISTS (SELECT 	period_end_date
				FROM	glprd
				WHERE	period_end_date = @fiscal_period_end_jul)
BEGIN
	EXEC 		amGetErrorMessage_sp 21110, "tmp/imprfval.sp", 259, @asset_ctrl_num, @book_code, @fiscal_period_end_dt, @error_message = @message OUT 
	IF @message IS NOT NULL RAISERROR 	21110 @message 
	SELECT 		@is_valid = 0

	IF @stop_on_error = 1
		RETURN 0
END


IF @action = 0 
OR @action = 2
BEGIN
	IF @fiscal_period_end_dt < @acquisition_date
	BEGIN
		EXEC 		amGetErrorMessage_sp 21104, "tmp/imprfval.sp", 275, @asset_ctrl_num, @book_code, @fiscal_period_end_dt, @acquisition_date, @error_message = @message OUT 
		IF @message IS NOT NULL RAISERROR 	21104 @message 
		SELECT 		@is_valid = 0

		IF @stop_on_error = 1
			RETURN 0
	END

	
	IF @fiscal_period_end_dt > @cur_prd_end_date
	BEGIN
		EXEC 		amGetErrorMessage_sp 21105, "tmp/imprfval.sp", 288, @asset_ctrl_num, @book_code, @fiscal_period_end_dt, @cur_prd_end_date, @error_message = @message OUT 
		IF @message IS NOT NULL RAISERROR 	21105 @message 
		SELECT 		@is_valid = 0

		IF @stop_on_error = 1
			RETURN 0
	END
END

IF @co_asset_book_id <> NULL
BEGIN
	IF @action = 0
	BEGIN
		
		IF EXISTS(SELECT 	* 
					FROM 	amastprf
					WHERE	co_asset_book_id 	= @co_asset_book_id
					AND		fiscal_period_end	= @fiscal_period_end_dt)
		BEGIN
			EXEC 		amGetErrorMessage_sp 21103, "tmp/imprfval.sp", 309, @asset_ctrl_num, @book_code, @fiscal_period_end_dt, @error_message = @message OUT 
			IF @message IS NOT NULL RAISERROR 	21103 @message 
			SELECT 		@is_valid = 0

			IF @stop_on_error = 1
				RETURN 0
		END
	END
	ELSE
	BEGIN
		
		IF NOT EXISTS(SELECT 	* 
						FROM 	amastprf
						WHERE	co_asset_book_id 	= @co_asset_book_id
						AND		fiscal_period_end	= @fiscal_period_end_dt)
		BEGIN
			EXEC 		amGetErrorMessage_sp 21102, "tmp/imprfval.sp", 327, @asset_ctrl_num, @book_code, @fiscal_period_end_dt, @error_message = @message OUT 
			IF @message IS NOT NULL RAISERROR 	21102 @message 
			SELECT 		@is_valid = 0

			IF @stop_on_error = 1
				RETURN 0
		END
	END
END

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/imprfval.sp" + ", line " + STR( 337, 5 ) + " -- EXIT: "

RETURN 0
GO
GRANT EXECUTE ON  [dbo].[imPrfVal_sp] TO [public]
GO
