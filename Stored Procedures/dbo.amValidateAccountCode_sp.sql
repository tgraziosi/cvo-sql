SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[amValidateAccountCode_sp] 
(  
    @account_code     	smAccountCode, 				
    @valid            	smLogical = 0  OUTPUT, 	


	@debug_level		smDebugLevel		= 0		
)
AS 

DECLARE @message         	smErrorLongDesc 

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "amckaccd.cpp" + ", line " + STR( 61, 5 ) + " -- ENTRY: "

SELECT @valid = 0 
IF EXISTS ( SELECT  1 
            FROM   am_accounts_access_root_org_vw
            WHERE  account_code = @account_code
	  )
	SELECT @valid = 1 
ELSE 
BEGIN 
    EXEC 		amGetErrorMessage_sp 20052, "amckaccd.cpp", 71, @account_code, @error_message = @message out 
   	IF @message IS NOT NULL RAISERROR 	20052 @message 
    RETURN 		20052 
END 
   
IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "amckaccd.cpp" + ", line " + STR( 76, 5 ) + " -- EXIT: "

RETURN 0 
GO
GRANT EXECUTE ON  [dbo].[amValidateAccountCode_sp] TO [public]
GO
