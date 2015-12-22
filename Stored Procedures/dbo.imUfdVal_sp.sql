SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

 
CREATE PROCEDURE [dbo].[imUfdVal_sp] 
( 
	@action				smallint,
	@company_id			smallint,				
	@asset_ctrl_num		char(16),					
	@user_code_1		varchar(40) 	= "",		
	@user_code_2		varchar(40) 	= "",		
	@user_code_3		varchar(40) 	= "",		
	@user_code_4		varchar(40) 	= "",		
	@user_date_1		char(8) 		= NULL,		
	@user_date_2		char(8) 		= NULL,		
	@user_date_3		char(8) 		= NULL,		
	@user_date_4		char(8) 		= NULL,		
	@user_amount_1		float 			= 0,		
	@user_amount_2		float 			= 0,		
	@user_amount_3		float 			= 0,		
	@user_amount_4		float 			= 0,		
	@stop_on_error		tinyint			= 0,	
	@is_valid			tinyint 		OUTPUT,	
	@debug_level			smallint	= 0		
)
AS 

DECLARE
	@result				int,					
	@does_exist			tinyint,				
	@message			varchar(255),			
	@activity_state		tinyint					

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/imufdval.sp" + ", line " + STR( 78, 5 ) + " -- ENTRY: "

SELECT 	@is_valid = 1


EXEC @result = amassetExists_sp
					@company_id, 
					@asset_ctrl_num, 
					@does_exist 	OUTPUT
IF @result <> 0
	RETURN @result

IF @does_exist = 0 
BEGIN
	EXEC 		amGetErrorMessage_sp 21251, "tmp/imufdval.sp", 94, @asset_ctrl_num, @error_message = @message OUT 
	IF @message IS NOT NULL RAISERROR 	21251 @message 
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
		EXEC 		amGetErrorMessage_sp 21252, "tmp/imufdval.sp", 110, @asset_ctrl_num, @error_message = @message OUT 
		IF @message IS NOT NULL RAISERROR 	21017 @message 
		SELECT 		@is_valid = 0
		
		IF @stop_on_error = 1
			RETURN 0	
	END
END

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/imufdval.sp" + ", line " + STR( 119, 5 ) + " -- EXIT: "

RETURN 0
GO
GRANT EXECUTE ON  [dbo].[imUfdVal_sp] TO [public]
GO
