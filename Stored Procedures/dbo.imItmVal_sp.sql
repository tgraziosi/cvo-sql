SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

 
CREATE PROCEDURE [dbo].[imItmVal_sp] 
( 
	@action						smallint,
	@company_id					smallint,				
	@asset_ctrl_num				char(16),					
	@sequence_id				int,					
	@manufacturer				varchar(40) 	= "",	
	@model_num					varchar(32) 	= "",	
	@serial_num					varchar(32) 	= "",	
	@item_code					varchar(22) 	= "",	
	@item_description			varchar(40) 	= "",	
	@item_tag					varchar(32) 	= "",	
	@po_ctrl_num				char(16) 		= "",	
	@contract_number			char(16) 		= "",	
	@vendor_code				char(12) 		= "",	
	@vendor_description			varchar(40) 	= "",	
	@invoice_num				varchar(32) 	= "",	
	@invoice_date				char(8) 		= NULL,	
	@item_cost					float 			= 0,	
	@item_quantity				int				= 1,	
	@item_disposition_date		char(8)			= NULL,	
	@last_modified_date			char(8) 		= NULL,	
	@modified_by				int 			= 1,	
	@stop_on_error				tinyint			= 1,	
	@is_valid					tinyint 		OUTPUT,	
	@debug_level				smallint	= 0			
)
AS 

DECLARE
	@result						int,					
	@does_exist					tinyint,				
	@message					varchar(255),			
	@param1						varchar(255),			
	@param2						varchar(255),			
	@param3						varchar(255),			
	@co_asset_id				int,
	@activity_state				tinyint			

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/imitmval.sp" + ", line " + STR( 103, 5 ) + " -- ENTRY: "

SELECT 	@is_valid = 1

IF @last_modified_date IS NULL
	SELECT	@last_modified_date = CONVERT(char(8), GETDATE(), 112)

EXEC @result = amassetExists_sp
					@company_id, 
					@asset_ctrl_num, 
					@does_exist 	OUTPUT
IF @result <> 0
	RETURN @result


IF @does_exist = 0 
BEGIN
	EXEC 		amGetErrorMessage_sp 21452, "tmp/imitmval.sp", 122, @asset_ctrl_num, @error_message = @message OUT 
	IF @message IS NOT NULL RAISERROR 	21452 @message 
	SELECT 		@is_valid = 0

	IF @stop_on_error = 1
		RETURN 0
END
ELSE
BEGIN
	
	SELECT	@co_asset_id		= co_asset_id,
			@activity_state		= activity_state
	FROM	amasset
	WHERE	company_id			= @company_id
	AND		asset_ctrl_num		= @asset_ctrl_num

	IF @activity_state = 101
	BEGIN
		EXEC 		amGetErrorMessage_sp 21453, "tmp/imitmval.sp", 142, @asset_ctrl_num, @error_message = @message OUT 
		IF @message IS NOT NULL RAISERROR 	21453 @message 
		SELECT 		@is_valid = 0

		IF @stop_on_error = 1
			RETURN 0
	END
END

IF @sequence_id < 0 
BEGIN
	
	SELECT		@param1	= RTRIM(CONVERT(char(255), @sequence_id))
	EXEC 		amGetErrorMessage_sp 21454, "tmp/imitmval.sp", 159, @asset_ctrl_num, @param1, @error_message = @message OUT 
	IF @message IS NOT NULL RAISERROR 	21454 @message 
	SELECT 		@is_valid = 0

	IF @stop_on_error = 1
		RETURN 0
END


IF @action = 0
BEGIN
	IF EXISTS (SELECT	sequence_id
				FROM 	amitem
				WHERE	co_asset_id 	= @co_asset_id
				AND		sequence_id		= @sequence_id)
	BEGIN
		SELECT		@param1	= RTRIM(CONVERT(char(255), @sequence_id))

		EXEC 		amGetErrorMessage_sp 21450, "tmp/imitmval.sp", 180, @asset_ctrl_num, @param1, @error_message = @message OUT 
		IF @message IS NOT NULL RAISERROR 	21450 @message 
		SELECT 		@is_valid = 0
	
		IF @stop_on_error = 1
			RETURN 0
	END
END
ELSE 
BEGIN
	IF NOT EXISTS (SELECT	sequence_id
					FROM 	amitem
					WHERE	co_asset_id 	= @co_asset_id
					AND		sequence_id		= @sequence_id)
	BEGIN
		SELECT		@param1	= RTRIM(CONVERT(char(255), @sequence_id))

		EXEC 		amGetErrorMessage_sp 21451, "tmp/imitmval.sp", 197, @asset_ctrl_num, @param1, @error_message = @message OUT 
		IF @message IS NOT NULL RAISERROR 	21451 @message 
		SELECT 		@is_valid = 0

		IF @stop_on_error = 1
			RETURN 0
	END

END

IF @action = 0
OR @action = 2
BEGIN
	
	IF @item_quantity < 0
	BEGIN
		SELECT @param1 = RTRIM(convert(char(255), @sequence_id))
		SELECT @param2 = RTRIM(convert(char(255), @item_quantity))
		
		EXEC	 	amGetErrorMessage_sp 21455, "tmp/imitmval.sp", 218, @asset_ctrl_num, @param1, @param2, @error_message = @message OUT 
		IF @message IS NOT NULL RAISERROR 	21455 @message 
		SELECT 		@is_valid = 0	
		
		IF @stop_on_error = 1
			RETURN 0	
	END
END

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/imitmval.sp" + ", line " + STR( 227, 5 ) + " -- EXIT: "

RETURN 0
GO
GRANT EXECUTE ON  [dbo].[imItmVal_sp] TO [public]
GO
