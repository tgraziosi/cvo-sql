SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE [dbo].[amUserPerm_sp] 
(
    @app_id 		smallint,			
	@company_id 	smCompanyID, 		
    @user_id 		smUserID, 			
	@debug_level	smDebugLevel	= 0	
) 
AS 

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "amusrprm.cpp" + ", line " + STR( 62, 5 ) + " -- ENTRY: " 

SELECT DISTINCT	form_id,write
FROM 	CVO_Control..smperm p 
WHERE 	p.app_id  		= @app_id 
AND 	p.company_id 	= @company_id 
AND   	p.user_id 		= @user_id 
ORDER BY form_id 

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "amusrprm.cpp" + ", line " + STR( 71, 5 ) + " -- EXIT: "

RETURN 0
GO
GRANT EXECUTE ON  [dbo].[amUserPerm_sp] TO [public]
GO
