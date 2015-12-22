SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[amGetAccountCodeMask_sp] 
(
	@company_id 	smCompanyID, 					
 @acct_code_mask 	smAccountCodeMask OUTPUT, 	
	@debug_level 		smDebugLevel	= 0				
)	
AS 

DECLARE 
	@message smErrorLongDesc,
	@result			smErrorCode,
	@rowcount		smCounter,
	@param			smErrorParam

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amactmsk.sp" + ", line " + STR( 54, 5 ) + " -- ENTRY: "

SELECT @acct_code_mask = account_format_mask 
FROM glco 
WHERE company_id = @company_id 

SELECT	@rowcount = @@rowcount, @result = @@error
IF ( @rowcount = 0 )
BEGIN 
	SELECT		@param = RTRIM(CONVERT(char(255), @company_id))
	
	EXEC 		amGetErrorMessage_sp 20204, "tmp/amactmsk.sp", 65, @param, @error_message = @message OUT 
	IF @message IS NOT NULL RAISERROR 	20204 @message 
	RETURN	 	20204 
END 

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amactmsk.sp" + ", line " + STR( 70, 5 ) + " -- EXIT: "

RETURN @result 
GO
GRANT EXECUTE ON  [dbo].[amGetAccountCodeMask_sp] TO [public]
GO
