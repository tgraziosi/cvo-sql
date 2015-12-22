SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

 
CREATE PROCEDURE [dbo].[imABkVal_sp] 
( 
	@action					smallint,
	@company_id				smallint,			
	@asset_ctrl_num			char(16),				
	@book_code				char(8),			
	@placed_in_service_date	char(8)		= NULL,	
	@stop_on_error			tinyint		= 0,	
	@is_valid				tinyint 	OUTPUT,	
	@debug_level			smallint	= 0		
)
AS 

DECLARE
	@result					int,				
	@does_exist				tinyint,			
	@message				varchar(255),		
	@acquisition_date		datetime,			
	@co_asset_id			int,				
	@co_asset_book_id		int,				
	@is_imported			tinyint,			
	@activity_state			tinyint,			
	@param1					varchar(255),
	@param2					varchar(255),
	@dates_valid			tinyint

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/imabkval.sp" + ", line " + STR( 96, 5 ) + " -- ENTRY: "

SELECT 	@is_valid = 1

EXEC @result = amassetExists_sp
					@company_id, 
					@asset_ctrl_num, 
					@does_exist 	OUTPUT
IF @result <> 0
	RETURN @result


IF @does_exist = 0 
BEGIN
	EXEC 		amGetErrorMessage_sp 21403, "tmp/imabkval.sp", 112, @asset_ctrl_num, @error_message = @message OUT 
	IF @message IS NOT NULL RAISERROR 	21403 @message 
	SELECT 		@is_valid = 0

	IF @stop_on_error = 1
		RETURN 0
END
ELSE
BEGIN
	
	SELECT	@co_asset_id		= co_asset_id,
			@activity_state		= activity_state,
			@is_imported		= is_imported,
			@acquisition_date	= acquisition_date
	FROM	amasset
	WHERE	company_id			= @company_id
	AND		asset_ctrl_num		= @asset_ctrl_num

	IF @activity_state != 100
	BEGIN
		EXEC 		amGetErrorMessage_sp 21401, "tmp/imabkval.sp", 134, @asset_ctrl_num, @error_message = @message OUT 
		IF @message IS NOT NULL RAISERROR 	21401 @message 
		SELECT 		@is_valid = 0

		IF @stop_on_error = 1
			RETURN 0
	END

	IF @is_imported != 1
	BEGIN
		EXEC 		amGetErrorMessage_sp 21400, "tmp/imabkval.sp", 144, @asset_ctrl_num, @error_message = @message OUT 
		IF @message IS NOT NULL RAISERROR 	21400 @message 
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
	EXEC 		amGetErrorMessage_sp 21404, "tmp/imabkval.sp", 164, @asset_ctrl_num, @book_code, @error_message = @message OUT 
	IF @message IS NOT NULL RAISERROR 	21404 @message 
	SELECT 		@is_valid = 0

	IF @stop_on_error = 1
		RETURN 0
END
ELSE IF @is_valid = 1	
BEGIN
	
	SELECT	@co_asset_book_id	= NULL
	
	SELECT 	@co_asset_book_id 		= co_asset_book_id
	FROM	amastbk
	WHERE	co_asset_id 			= @co_asset_id
	AND		book_code				= @book_code

	IF @co_asset_book_id IS NULL
	BEGIN
		EXEC 		amGetErrorMessage_sp 21405, "tmp/imabkval.sp", 185, @asset_ctrl_num, @book_code, @error_message = @message OUT 
		IF @message IS NOT NULL RAISERROR 	21405 @message 
		SELECT 		@is_valid = 0

		IF @stop_on_error = 1
			RETURN 0
	END
	ELSE
	BEGIN
		
		EXEC 	@result = amValidatePlacedDate_sp
							@co_asset_book_id,
							@placed_in_service_date,
							@dates_valid OUTPUT
		IF @result <> 0
			RETURN @result

		IF	@dates_valid = 0	
			SELECT	@is_valid = 0

		IF @stop_on_error = 1
			RETURN 0
	END

END

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/imabkval.sp" + ", line " + STR( 213, 5 ) + " -- EXIT: "

RETURN 0
GO
GRANT EXECUTE ON  [dbo].[imABkVal_sp] TO [public]
GO
