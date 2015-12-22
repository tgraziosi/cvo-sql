SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE [dbo].[amGetCompanySegments_sp] 
(
	@debug_level			smDebugLevel	= 0	
)
AS 


DECLARE @error 		smErrorCode,
		@rowcount	smCounter,
		@message	smErrorLongDesc 

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amcosegs.sp" + ", line " + STR( 64, 5 ) + " -- ENTRY: " 


SELECT 		acct_format,
			description,
			start_col,
			length,
			natural_acct_flag
FROM 		glaccdef
ORDER BY 	acct_level	

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amcosegs.sp" + ", line " + STR( 75, 5 ) + " -- EXIT: "

RETURN 0 
GO
GRANT EXECUTE ON  [dbo].[amGetCompanySegments_sp] TO [public]
GO
