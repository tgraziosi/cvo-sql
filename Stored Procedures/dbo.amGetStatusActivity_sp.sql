SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE [dbo].[amGetStatusActivity_sp] 
(
 @status_code 	smStatusCode, 			
 @activity_state smSystemState OUTPUT, 	
	@debug_level	smDebugLevel	= 0		
)
AS 

DECLARE 
	@message smErrorLongDesc

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amsttact.sp" + ", line " + STR( 50, 5 ) + " -- ENTRY: "

SELECT 	@activity_state = activity_state 
FROM 	amstatus 
WHERE 	status_code 	= @status_code 

IF @@rowcount = 0 
BEGIN 
	EXEC 		amGetErrorMessage_sp 20028, "tmp/amsttact.sp", 58, @status_code, @error_message = @message OUT 
	IF @message IS NOT NULL RAISERROR 	20028 @message 
	RETURN 		20028 
END 

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amsttact.sp" + ", line " + STR( 63, 5 ) + " -- EXIT: "

RETURN 0 
GO
GRANT EXECUTE ON  [dbo].[amGetStatusActivity_sp] TO [public]
GO
