SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE [dbo].[amGetCompanyID_sp] 
(	
	@company_id 	smCompanyID OUTPUT, 	
	@debug_level	smDebugLevel	= 0		
)
AS 

DECLARE 	
	@message smErrorLongDesc 

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amcoid.sp" + ", line " + STR( 67, 5 ) + " -- ENTRY: " 

SELECT @company_id = company_id 
FROM amco 

IF ( @@rowcount = 0 ) 
BEGIN 
	EXEC 		amGetErrorMessage_sp 20206, "tmp/amcoid.sp", 74, @error_message = @message OUT 
	IF @message IS NOT NULL RAISERROR 	20206 @message 
	RETURN 		20206 
END 

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amcoid.sp" + ", line " + STR( 79, 5 ) + " -- EXIT: "

RETURN 0 
GO
GRANT EXECUTE ON  [dbo].[amGetCompanyID_sp] TO [public]
GO
