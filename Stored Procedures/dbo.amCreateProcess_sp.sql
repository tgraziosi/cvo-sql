SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[amCreateProcess_sp] 
( 
	@user_id			smUserID,						
	@company_code		smCompanyCode,					
	@process_type		smProcessType, 					
	@process_ctrl_num	smProcessCtrlNum 	OUTPUT,		
	@debug_level		smDebugLevel 		= 0			
)

AS 

DECLARE 
	@result				smErrorCode,
	@message			smErrorLongDesc,
	@str_text			smStringText,
	@str_id				smCounter,
	@param				smErrorParam


IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amcrproc.sp" + ", line " + STR( 70, 5 ) + " -- ENTRY: "


IF (@process_type = 0 ) 
	SELECT @str_id = 5

ELSE IF (@process_type = 1 ) 
	SELECT @str_id = 6

ELSE IF (@process_type = 2 ) 
	SELECT @str_id = 7
	
ELSE IF (@process_type = 3 ) 
	SELECT @str_id = 8

ELSE IF (@process_type = 4 ) 
	SELECT @str_id = 9
	
ELSE
BEGIN
	SELECT		@param = CONVERT(char(255), @process_type)

 EXEC	 	amGetErrorMessage_sp 20604, "tmp/amcrproc.sp", 95, @param, @error_message = @message OUTPUT 
 IF @message IS NOT NULL RAISERROR 	20604 @message 
	RETURN 		20604
END

EXEC @result = amGetString_sp
						@str_id,
						@str_text OUTPUT
IF @result <> 0
	RETURN 	@result
 

EXEC @result = pctrladd_sp 
				@process_ctrl_num OUT, 
				@str_text,
				@user_id, 
				10000, 
				@company_code,
				@process_type

		
IF (@result <> 0)
	RETURN @result

IF @debug_level >= 3
BEGIN
	SELECT	"Process Ctrl Num = " + @process_ctrl_num 
END

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amcrproc.sp" + ", line " + STR( 126, 5 ) + " -- EXIT: "

RETURN 0
GO
GRANT EXECUTE ON  [dbo].[amCreateProcess_sp] TO [public]
GO
