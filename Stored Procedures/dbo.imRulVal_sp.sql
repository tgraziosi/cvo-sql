SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

 
CREATE PROCEDURE [dbo].[imRulVal_sp] 
( 
	@action					smallint,
	@company_id				smallint,				
	@asset_ctrl_num			char(16),					
	@book_code				char(8),				
	@effective_date			char(8),				
	@last_modified_date		char(8) 	= NULL,		
	@modified_by			int 		= 1,		
	@depr_rule_code			char(8) 	= NULL, 	
	@salvage_value			float		= 0,		
	@stop_on_error			tinyint		= 0,		
	@is_valid				tinyint 	OUTPUT,		
	@debug_level			smallint	= 0			
)
AS 

DECLARE
	@result					int,					
	@does_exist				tinyint,				
	@message				varchar(255),			
	@effective_date_dt		datetime,				
	@effective_date_jul		int,					
	@co_asset_id			int,					
	@co_asset_book_id		int,					
	@activity_state			tinyint,				
	@acquisition_date		datetime,				
	@last_posted_depr_date	datetime,				
	@posting_flag			tinyint					

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/imrulval.sp" + ", line " + STR( 116, 5 ) + " -- ENTRY: "

SELECT 	@is_valid = 1

IF @last_modified_date IS NULL
	SELECT	@last_modified_date = CONVERT(char(8), GETDATE(), 112)

SELECT @effective_date_dt 	= CONVERT(datetime, @effective_date)
SELECT @effective_date_jul 	= DATEDIFF(dd, "1/1/1980", @effective_date_dt) + 722815


EXEC @result = amassetExists_sp
					@company_id, 
					@asset_ctrl_num, 
					@does_exist 	OUTPUT
IF @result <> 0
	RETURN @result


IF @does_exist = 0 
BEGIN
	EXEC 		amGetErrorMessage_sp 21055, "tmp/imrulval.sp", 139, @asset_ctrl_num, @error_message = @message OUT 
	IF @message IS NOT NULL RAISERROR 	21055 @message 
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
		EXEC 		amGetErrorMessage_sp 21056, "tmp/imrulval.sp", 160, @asset_ctrl_num, @error_message = @message OUT 
		IF @message IS NOT NULL RAISERROR 	21056 @message 
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
	EXEC 		amGetErrorMessage_sp 21057, "tmp/imrulval.sp", 180, @asset_ctrl_num, @book_code, @error_message = @message OUT 
	IF @message IS NOT NULL RAISERROR 	21057 @message 
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
		EXEC 		amGetErrorMessage_sp 21058, "tmp/imrulval.sp", 202, @asset_ctrl_num, @book_code, @effective_date_dt, @error_message = @message OUT 
		IF @message IS NOT NULL RAISERROR 	21058 @message 
		SELECT 		@is_valid = 0
		
		IF @stop_on_error = 1
			RETURN 0	
	END
END


IF @action = 0
BEGIN
	
	IF NOT EXISTS (SELECT 	period_start_date
					FROM	glprd
					WHERE	period_start_date = @effective_date_jul)
	BEGIN
		IF @effective_date_dt <> @acquisition_date
		BEGIN
			EXEC 		amGetErrorMessage_sp 21050, "tmp/imrulval.sp", 224, @asset_ctrl_num, @effective_date_dt, @error_message = @message OUT 
			IF @message IS NOT NULL RAISERROR 	21050 @message 
			SELECT 		@is_valid = 0
			
			IF @stop_on_error = 1
				RETURN 0	
		END
	END

	
	IF 	@last_posted_depr_date IS NOT NULL
	AND @effective_date_dt <= @last_posted_depr_date
	BEGIN
		EXEC 		amGetErrorMessage_sp 21051, "tmp/imrulval.sp", 239, @asset_ctrl_num, @book_code, @effective_date_dt, @error_message = @message OUT 
		IF @message IS NOT NULL RAISERROR 	21051 @message 
		SELECT 		@is_valid = 0
			
		IF @stop_on_error = 1
			RETURN 0	
	END
END


IF @action = 0 
OR @action = 2
BEGIN
	EXEC @result = amdprrulExists_sp
						@depr_rule_code, 
						@does_exist 	OUTPUT
	IF @result <> 0
		RETURN @result

	IF @does_exist = 0 
	BEGIN
		EXEC 		amGetErrorMessage_sp 21054, "tmp/imrulval.sp", 262, @asset_ctrl_num, @book_code, @effective_date_dt, @depr_rule_code, @error_message = @message OUT 
		IF @message IS NOT NULL RAISERROR 	21054 @message 
		SELECT 		@is_valid = 0
		
		IF @stop_on_error = 1
			RETURN 0	
	END
END


IF @action = 0
BEGIN
	IF EXISTS (SELECT	effective_date
					FROM 	amdprhst
					WHERE	co_asset_book_id 	= @co_asset_book_id
					AND		effective_date		= @effective_date_dt)
	BEGIN
		EXEC 		amGetErrorMessage_sp 21052, "tmp/imrulval.sp", 282, @asset_ctrl_num, @book_code, @effective_date_dt, @error_message = @message OUT 
		IF @message IS NOT NULL RAISERROR 	21052 @message 
		SELECT 		@is_valid = 0
		
		IF @stop_on_error = 1
			RETURN 0	
	END
END
ELSE 
BEGIN
	
	IF NOT EXISTS (SELECT	effective_date
					FROM 	amdprhst
					WHERE	co_asset_book_id 	= @co_asset_book_id
					AND		effective_date		= @effective_date_dt)
	BEGIN
		EXEC 		amGetErrorMessage_sp 21053, "tmp/imrulval.sp", 300, @asset_ctrl_num, @book_code, @effective_date_dt, @error_message = @message OUT 
		IF @message IS NOT NULL RAISERROR 	21053 @message 
		SELECT 		@is_valid = 0
		
		IF @stop_on_error = 1
			RETURN 0	
	END
	ELSE
	BEGIN
		
		SELECT	@posting_flag		= posting_flag
		FROM	amdprhst
		WHERE	co_asset_book_id 	= @co_asset_book_id
		AND		effective_date		= @effective_date_dt
	 
		IF @posting_flag = 1
		BEGIN
			EXEC 		amGetErrorMessage_sp 21059, "tmp/imrulval.sp", 319, @asset_ctrl_num, @book_code, @effective_date_dt, @error_message = @message OUT 
			IF @message IS NOT NULL RAISERROR 	21059 @message 
			SELECT 		@is_valid = 0
			
			IF @stop_on_error = 1
				RETURN 0	
		END
	END
END

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/imrulval.sp" + ", line " + STR( 329, 5 ) + " -- EXIT: "

RETURN 0
GO
GRANT EXECUTE ON  [dbo].[imRulVal_sp] TO [public]
GO
