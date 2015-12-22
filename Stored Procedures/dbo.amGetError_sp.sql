SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[amGetError_sp] 
( 
	@e_code 		smErrorCode, 								
	@client_id 		smClientID 			= "" 			OUTPUT,	
	@e_level 		smErrorLevel 		= 3 	OUTPUT,	
	@e_active 		smErrorActive 		= 1 			OUTPUT,	
	@e_sdesc 		smErrorShortDesc 	= "" 			OUTPUT,	
	@e_ldesc 		smErrorLongDesc 	= "" 			OUTPUT,	
	@debug_level	smDebugLevel 		= 0 					
)
AS 

DECLARE @error 		smErrorCode,
		@rowcount	smCounter
		

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amgeterr.sp" + ", line " + STR( 86, 5 ) + " -- ENTRY: "
 
 
SELECT 	@client_id 	= client_id,
		@e_level 	= e_level,
		@e_active 	= e_active,
		@e_sdesc 	= e_sdesc,
		@e_ldesc 	= e_ldesc 
FROM 	amerrdef 
WHERE 	e_code 		= @e_code 

SELECT @error = @@error, @rowcount = @@rowcount
IF (@error <> 0) OR (@rowcount = 0) 
BEGIN 
	IF @e_code < 20000 
 SELECT @e_ldesc = "SQL Error Code" 
	ELSE 
 SELECT @e_ldesc = "No Message" 
END 

IF @debug_level >= 5
	SELECT error_nessage = @e_ldesc 

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amgeterr.sp" + ", line " + STR( 109, 5 ) + " -- EXIT: "

RETURN 0 
GO
GRANT EXECUTE ON  [dbo].[amGetError_sp] TO [public]
GO
