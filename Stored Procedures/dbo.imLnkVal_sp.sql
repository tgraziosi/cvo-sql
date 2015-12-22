SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

 
CREATE PROCEDURE [dbo].[imLnkVal_sp] 
( 
	@action						smallint,
	@company_id					smallint,				
	@asset_ctrl_num				char(16),					
	@parent_ctrl_num			char(16) 	= NULL,			
	@stop_on_error				tinyint		= 0,		
	@is_valid					tinyint 	OUTPUT,		
	@debug_level				smallint	= 0			
)
AS 

DECLARE
	@result				int,			
	@does_exist			tinyint,		
	@message			varchar(255),	
	@activity_state		tinyint			

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/imlnkval.sp" + ", line " + STR( 78, 5 ) + " -- ENTRY: "

SELECT 	@is_valid = 1


EXEC @result = amassetExists_sp
					@company_id, 
					@asset_ctrl_num, 
					@does_exist 	OUTPUT
IF @result <> 0
	RETURN @result

IF @does_exist = 0 
BEGIN
	EXEC 		amGetErrorMessage_sp 21300, "tmp/imlnkval.sp", 94, @asset_ctrl_num, @error_message = @message OUT 
	IF @message IS NOT NULL RAISERROR 	21300 @message 
	SELECT 		@is_valid = 0
		
	IF @stop_on_error = 1
		RETURN 0	
END
ELSE
BEGIN
	SELECT	@activity_state = activity_state
	FROM	amasset
	WHERE	company_id		= @company_id
	AND		asset_ctrl_num 	= @asset_ctrl_num
	
	IF @activity_state = 101
	BEGIN
		EXEC 		amGetErrorMessage_sp 21301, "tmp/imlnkval.sp", 110, @asset_ctrl_num, @error_message = @message OUT 
		IF @message IS NOT NULL RAISERROR 	21301 @message 
		SELECT 		@is_valid = 0

		IF @stop_on_error = 1
			RETURN 0	
	END
END

IF 	@action = 0 
OR	@action = 2
BEGIN
	
	EXEC @result = amassetExists_sp
						@company_id, 
						@parent_ctrl_num, 
						@does_exist 	OUTPUT
	IF @result <> 0
		RETURN @result

	IF @does_exist = 0 
	BEGIN
		EXEC 		amGetErrorMessage_sp 21302, "tmp/imlnkval.sp", 134, @asset_ctrl_num, @parent_ctrl_num, @error_message = @message OUT 
		IF @message IS NOT NULL RAISERROR 	21302 @message 
		SELECT 		@is_valid = 0
	
		IF @stop_on_error = 1
			RETURN 0	
	END
	ELSE
	BEGIN
		
		SELECT	@activity_state 	= activity_state
		FROM	amasset
		WHERE	company_id			= @company_id
		AND		asset_ctrl_num 		= @parent_ctrl_num
		
		
		IF @activity_state = 101
		BEGIN
			EXEC 		amGetErrorMessage_sp 21303, "tmp/imlnkval.sp", 156, @asset_ctrl_num, @parent_ctrl_num, @error_message = @message OUT 
			IF @message IS NOT NULL RAISERROR 	21303 @message 
			SELECT 		@is_valid = 0
		
			IF @stop_on_error = 1
				RETURN 0	
		END
	END
END

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/imlnkval.sp" + ", line " + STR( 166, 5 ) + " -- EXIT: "

RETURN 0
GO
GRANT EXECUTE ON  [dbo].[imLnkVal_sp] TO [public]
GO
