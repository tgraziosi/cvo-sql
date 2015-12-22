SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

 
CREATE PROCEDURE [dbo].[imMnlVal_sp] 
( 
	@action					smallint,
	@company_id				smallint,			
	@asset_ctrl_num			char(16),				
	@book_code				char(8),			
	@fiscal_period_end		char(8),			
	@last_modified_date		char(8) 	= NULL,	
	@modified_by			int 		= 1,	
	@depr_expense			float 		= 0, 	
	@stop_on_error			tinyint		= 0,	
	@is_valid				tinyint 	OUTPUT,	
	@debug_level			smallint	= 0		
)
AS 

DECLARE
	@result					int,				
	@does_exist				tinyint,			
	@message				varchar(255),		
	@period_end				datetime,			
	@period_end_jul			int,				
	@co_asset_id			int,				
	@co_asset_book_id		int,				
	@activity_state			tinyint,			
	@acquisition_date		datetime,			
	@last_posted_depr_date	datetime,			
	@posting_flag			tinyint				

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/immnlval.sp" + ", line " + STR( 112, 5 ) + " -- ENTRY: "

SELECT 	@is_valid = 1

IF @last_modified_date IS NULL
	SELECT	@last_modified_date = CONVERT(char(8), GETDATE(), 112)

SELECT @period_end = CONVERT(datetime, @fiscal_period_end)
SELECT @period_end_jul = DATEDIFF(dd, "1/1/1980", @period_end) + 722815


EXEC @result = amassetExists_sp
					@company_id, 
					@asset_ctrl_num, 
					@does_exist 	OUTPUT
IF @result <> 0
	RETURN @result


IF @does_exist = 0 
BEGIN
	EXEC 		amGetErrorMessage_sp 21204, "tmp/immnlval.sp", 135, @asset_ctrl_num, @error_message = @message OUT 
	IF @message IS NOT NULL RAISERROR 	21204 @message 
	SELECT 		@is_valid = 0

	IF @stop_on_error = 1
		RETURN 0
END
ELSE
BEGIN
	
	SELECT	@co_asset_id		= co_asset_id,
			@activity_state		= activity_state,
			@acquisition_date	= acquisition_date
	FROM	amasset
	WHERE	company_id			= @company_id
	AND		asset_ctrl_num		= @asset_ctrl_num

	IF @activity_state = 101
	BEGIN
		EXEC 		amGetErrorMessage_sp 21208, "tmp/immnlval.sp", 156, @asset_ctrl_num, @error_message = @message OUT 
		IF @message IS NOT NULL RAISERROR 	21208 @message 
		SELECT 		@is_valid = 0

		IF @stop_on_error = 1
			RETURN 0
	END
END

EXEC @result = ambookExists_sp
					@book_code, 
					@does_exist 	OUTPUT
IF @result <> 0
	RETURN @result


IF @does_exist = 0 
BEGIN
	EXEC 		amGetErrorMessage_sp 21205, "tmp/immnlval.sp", 176, @asset_ctrl_num, @book_code, @period_end, @error_message = @message OUT 
	IF @message IS NOT NULL RAISERROR 	21205 @message 
	SELECT 		@is_valid = 0

	IF @stop_on_error = 1
		RETURN 0
END
ELSE IF @is_valid = 1	
BEGIN
	
	SELECT	@co_asset_book_id	= NULL
	
	SELECT 	@co_asset_book_id 		= co_asset_book_id,
			@last_posted_depr_date	= last_posted_depr_date
	FROM	amastbk
	WHERE	co_asset_id 			= @co_asset_id
	AND		book_code				= @book_code

	IF @co_asset_book_id IS NULL
	BEGIN
		EXEC 		amGetErrorMessage_sp 21206, "tmp/immnlval.sp", 198, @asset_ctrl_num, @book_code, @period_end, @error_message = @message OUT 
		IF @message IS NOT NULL RAISERROR 	21206 @message 
		SELECT 		@is_valid = 0

		IF @stop_on_error = 1
			RETURN 0
	END
END


IF NOT EXISTS (SELECT 	period_end_date
				FROM	glprd
				WHERE	period_end_date = @period_end_jul)
BEGIN
	EXEC 		amGetErrorMessage_sp 21207, "tmp/immnlval.sp", 214, @asset_ctrl_num, @book_code, @period_end, @error_message = @message OUT 
	IF @message IS NOT NULL RAISERROR 	21207 @message 
	SELECT 		@is_valid = 0

	IF @stop_on_error = 1
		RETURN 0
END


IF @period_end < @acquisition_date
BEGIN
	EXEC 		amGetErrorMessage_sp 21200, "tmp/immnlval.sp", 227, @asset_ctrl_num, @book_code, @period_end, @acquisition_date, @error_message = @message OUT 
	IF @message IS NOT NULL RAISERROR 	21200 @message 
	SELECT 		@is_valid = 0

	IF @stop_on_error = 1
		RETURN 0
END


IF 	@last_posted_depr_date IS NOT NULL
AND @period_end <= @last_posted_depr_date
BEGIN
	EXEC 		amGetErrorMessage_sp 21201, "tmp/immnlval.sp", 241, @asset_ctrl_num, @book_code, @period_end, @error_message = @message OUT 
	IF @message IS NOT NULL RAISERROR 	21201 @message 
	SELECT 		@is_valid = 0

	IF @stop_on_error = 1
		RETURN 0
END


IF @action = 0
BEGIN
	IF EXISTS (SELECT	fiscal_period_end
					FROM 	ammandpr
					WHERE	co_asset_book_id 	= @co_asset_book_id
					AND		fiscal_period_end	= @period_end)
	BEGIN
		EXEC 		amGetErrorMessage_sp 21202, "tmp/immnlval.sp", 260, @asset_ctrl_num, @book_code, @period_end, @error_message = @message OUT 
		IF @message IS NOT NULL RAISERROR 	21202 @message 
		SELECT 		@is_valid = 0
	
		IF @stop_on_error = 1
			RETURN 0
	END
END
ELSE 
BEGIN
	IF NOT EXISTS (SELECT	fiscal_period_end
					FROM 	ammandpr
					WHERE	co_asset_book_id 	= @co_asset_book_id
					AND		fiscal_period_end	= @period_end)
	BEGIN
		EXEC 		amGetErrorMessage_sp 21203, "tmp/immnlval.sp", 275, @asset_ctrl_num, @book_code, @period_end, @error_message = @message OUT 
		IF @message IS NOT NULL RAISERROR 	21203 @message 
		SELECT 		@is_valid = 0

		IF @stop_on_error = 1
			RETURN 0
	END
	ELSE
	BEGIN
		
		SELECT	@posting_flag 		= posting_flag
		FROM	ammandpr
		WHERE	co_asset_book_id 	= @co_asset_book_id
		AND		fiscal_period_end	= @period_end

		IF @posting_flag = 1
		BEGIN
			EXEC 		amGetErrorMessage_sp 21209, "tmp/immnlval.sp", 294, @asset_ctrl_num, @book_code, @period_end, @error_message = @message OUT 
			IF @message IS NOT NULL RAISERROR 	21209 @message 
			SELECT 		@is_valid = 0

			IF @stop_on_error = 1
				RETURN 0
		END
	END
END

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/immnlval.sp" + ", line " + STR( 304, 5 ) + " -- EXIT: "

RETURN 0
GO
GRANT EXECUTE ON  [dbo].[imMnlVal_sp] TO [public]
GO
