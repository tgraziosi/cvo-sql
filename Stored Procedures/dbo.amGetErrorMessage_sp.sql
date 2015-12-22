SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[amGetErrorMessage_sp] 
( 
	@error_code 	smErrorCode, 				
	@file_name 	smFilename 	= NULL,		
	@line_number 	smCounter 	= NULL,		

	@char_param_1 	smErrorParam 	= NULL,		
	@char_param_2 	smErrorParam 	= NULL,		
	@char_param_3 	smErrorParam 	= NULL,		
	@char_param_4 	smErrorParam 	= NULL,		

	@error_message 	smErrorLongDesc = "" OUTPUT,
	@debug_level	smDebugLevel 	= 0 		
)
AS 

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amerrmsg.sp" + ", line " + STR( 137, 5 ) + " -- ENTRY: "

DECLARE @e_level 	smErrorLevel, 
		@client_id 	smClientID, 
		@e_active 	smErrorActive, 
		@e_sdesc 	smErrorShortDesc, 
		@severity varchar(40),
	 	@index 		int,	
 		@error 		int 

 
EXEC 	@error = amGetError_sp @error_code, 
								@client_id 		OUTPUT,
								@e_level 		OUTPUT,
								@e_active 		OUTPUT,
								@e_sdesc 		OUTPUT,
								@error_message 	OUTPUT 
IF @error <> 0
	RETURN @error
	
IF @debug_level >= 5
	SELECT error_message = @error_message


 
SELECT @severity = CONVERT(varchar(6),@error_code) + ":" + CONVERT(char(1), @e_level) + ":" 

 
IF @char_param_1 IS NOT NULL 
BEGIN 
 SELECT 	@index = PATINDEX ("%[%]1!%", @error_message)
 IF @index > 0 
 SELECT 	@error_message = STUFF(@error_message, @index, 3, RTRIM(@char_param_1))
END 

IF @char_param_2 IS NOT NULL 
BEGIN 
 SELECT 	@index = PATINDEX ("%[%]2!%", @error_message)
 IF @index > 0 
 SELECT 	@error_message = STUFF(@error_message, @index, 3, RTRIM(@char_param_2))
END 

IF @char_param_3 IS NOT NULL 
BEGIN 
 SELECT 	@index = PATINDEX ("%[%]3!%", @error_message)
 IF @index > 0 
 SELECT 	@error_message = STUFF(@error_message, @index, 3, RTRIM(@char_param_3))
END 

IF @char_param_4 IS NOT NULL 
BEGIN 
 SELECT 	@index = PATINDEX ("%[%]4!%", @error_message)
 IF @index > 0 
 SELECT 	@error_message = STUFF(@error_message, @index, 3, RTRIM(@char_param_4))
END 



SELECT @error_message = @severity + @error_message
 

IF @debug_level >= 3
BEGIN
	
	 
	IF @file_name IS NOT NULL 	BEGIN 
	 SELECT @error_message = @error_message + " " + "[" + "Procedure" + 
	 				":" + " " + @file_name 
	 
	 IF @line_number IS NOT NULL 
	 SELECT @error_message = @error_message + "," + " " + "Line" + ":" + 
	 			" " + RTRIM(CONVERT(char(4), @line_number)) 
	 
	 SELECT @error_message = @error_message + "]" 
	END 
 
END

 
SELECT error_message = @error_message
SELECT @error_message = NULL


IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amerrmsg.sp" + ", line " + STR( 229, 5 ) + " -- EXIT: "

RETURN 0 
GO
GRANT EXECUTE ON  [dbo].[amGetErrorMessage_sp] TO [public]
GO
