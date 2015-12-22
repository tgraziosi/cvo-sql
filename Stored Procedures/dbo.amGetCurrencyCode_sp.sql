SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE [dbo].[amGetCurrencyCode_sp] 
(
	@company_id 	smCompanyID,				
	@home_currency 	smCurrencyCode OUTPUT, 	
	@debug_level		smDebugLevel = 0			
)
AS 

DECLARE 
	@message smErrorLongDesc,
	@result			smErrorCode,
	@rowcount		smCounter

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amcurcd.sp" + ", line " + STR( 56, 5 ) + " -- ENTRY: "

SELECT 	@home_currency = home_currency 
FROM 	glco 
WHERE 	company_id = @company_id 

SELECT	@rowcount = @@rowcount, @result = @@error

IF @rowcount = 0 
BEGIN 
	DECLARE		@param	smErrorParam
	
	SELECT		@param	= RTRIM(CONVERT(char(255), @company_id))
	EXEC 		amGetErrorMessage_sp 20204, "tmp/amcurcd.sp", 69, @param, @error_message = @message OUT 
	IF @message IS NOT NULL RAISERROR 	20204 @message 
	RETURN 		20204 
END 

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amcurcd.sp" + ", line " + STR( 74, 5 ) + " -- EXIT: "

RETURN 0
GO
GRANT EXECUTE ON  [dbo].[amGetCurrencyCode_sp] TO [public]
GO
