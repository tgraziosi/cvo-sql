SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

 
CREATE PROCEDURE [dbo].[imClsVal_sp] 
( 
	@action					smallint,			
	@company_id				smallint,			
	@classification_name	varchar(40),		
	@asset_ctrl_num			char(16),				
	@classification_code	char(8)		= "",	
	@last_modified_date		char(8)		= NULL,	
	@modified_by			int			= 1,	
	@stop_on_error			tinyint		= 0,	
	@is_valid				tinyint 	OUTPUT,	
	@debug_level			smallint	= 0		
)
AS 

DECLARE
	@result					int,				
	@does_exist				tinyint,			
	@message				varchar(255),		
	@co_asset_id			int,				
	@activity_state			tinyint,			
	@classification_id		int					

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/imclsval.sp" + ", line " + STR( 91, 5 ) + " -- ENTRY: "

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
	EXEC 		amGetErrorMessage_sp 21354, "tmp/imclsval.sp", 111, @asset_ctrl_num, @error_message = @message OUT 
	IF @message IS NOT NULL RAISERROR 	21354 @message 
	SELECT 		@is_valid = 0
		
	IF @stop_on_error = 1
		RETURN 0	
END
ELSE
BEGIN
	
	SELECT	@activity_state		= activity_state,
			@co_asset_id		= co_asset_id
	FROM	amasset
	WHERE	company_id			= @company_id
	AND		asset_ctrl_num		= @asset_ctrl_num

	IF @activity_state = 101
	BEGIN
		EXEC 		amGetErrorMessage_sp 21355, "tmp/imclsval.sp", 131, @asset_ctrl_num, @error_message = @message OUT 
		IF @message IS NOT NULL RAISERROR 	21355 @message 
		SELECT 		@is_valid = 0
		
		IF @stop_on_error = 1
			RETURN 0	
	END
END


SELECT 	@classification_id = NULL

SELECT 	@classification_id = classification_id
FROM	amclshdr
WHERE	classification_name	= @classification_name


IF @classification_id IS NULL 
BEGIN
	EXEC 		amGetErrorMessage_sp 21350, "tmp/imclsval.sp", 152, @asset_ctrl_num, @classification_name, @error_message = @message OUT 
	IF @message IS NOT NULL RAISERROR 	21350 @message 
	SELECT 		@is_valid = 0
		
	IF @stop_on_error = 1
		RETURN 0	
END
ELSE 
BEGIN
	IF @action = 0
	BEGIN
		
		IF EXISTS (SELECT	classification_code
					FROM	amastcls
					WHERE	co_asset_id 		= @co_asset_id
					AND		classification_id 	= @classification_id
					)
		BEGIN
			EXEC 		amGetErrorMessage_sp 21352, "tmp/imclsval.sp", 172, @asset_ctrl_num, @classification_name, @error_message = @message OUT 
			IF @message IS NOT NULL RAISERROR 	21352 @message 
			SELECT 		@is_valid = 0
			
			IF @stop_on_error = 1
				RETURN 0	
		END

	END
	ELSE
	BEGIN
		
		IF NOT EXISTS (SELECT classification_code
						FROM	amastcls
						WHERE	co_asset_id 		= @co_asset_id
						AND		classification_id 	= @classification_id
						)
		BEGIN
			EXEC 		amGetErrorMessage_sp 21351, "tmp/imclsval.sp", 192, @asset_ctrl_num, @classification_name, @error_message = @message OUT 
			IF @message IS NOT NULL RAISERROR 	21351 @message 
			SELECT 		@is_valid = 0
			
			IF @stop_on_error = 1
				RETURN 0	
		END
	END
END

IF @action = 0
OR @action = 2
BEGIN
	
	IF NOT EXISTS (SELECT 	classification_code 
					FROM	amcls
					WHERE	classification_code = @classification_code)
	BEGIN
		EXEC 		amGetErrorMessage_sp 21353, "tmp/imclsval.sp", 212, @asset_ctrl_num, @classification_name, @classification_code, @error_message = @message OUT 
		IF @message IS NOT NULL RAISERROR 	21353 @message 
		SELECT 		@is_valid = 0

		IF @stop_on_error = 1
			RETURN 0	
	END
END

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/imclsval.sp" + ", line " + STR( 221, 5 ) + " -- EXIT: "

RETURN 0
GO
GRANT EXECUTE ON  [dbo].[imClsVal_sp] TO [public]
GO
