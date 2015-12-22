SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE [dbo].[amValidateStatus_sp] 
(
 	@co_asset_id 		smSurrogateKey, 	
 	@current_state		smSystemState,		
	@status_code		smStatusCode,		
	@is_valid 			smLogical 	OUTPUT,	
	@debug_level		smDebugLevel = 0	
)
AS 

DECLARE
	@message		smErrorLongDesc

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amvldstt.sp" + ", line " + STR( 89, 5 ) + " -- ENTRY: "

SELECT 	@is_valid 	= 0

IF 	RTRIM(@status_code) <> ""
AND	@status_code IS NOT NULL
BEGIN

	IF NOT EXISTS (SELECT status_code
					FROM 	amstatus
					WHERE	status_code = @status_code)
	BEGIN
		
		EXEC 		amGetErrorMessage_sp 20078, "tmp/amvldstt.sp", 102, @status_code, @error_message = @message OUT 
		IF @message IS NOT NULL RAISERROR 	20078 @message 
		RETURN		20078
	END
END

SELECT @is_valid = 1

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amvldstt.sp" + ", line " + STR( 110, 5 ) + " -- EXIT: "

RETURN 0
GO
GRANT EXECUTE ON  [dbo].[amValidateStatus_sp] TO [public]
GO
