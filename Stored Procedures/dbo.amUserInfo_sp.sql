SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[amUserInfo_sp] 
(
 @user_name	 	varchar(30), 			
 @user_id 		smallint OUTPUT,	
 @manager 		smallint OUTPUT, 	
	@debug_level	smDebugLevel	= 0		
)
AS 

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amusrinf.sp" + ", line " + STR( 52, 5 ) + " -- ENTRY: " 

SELECT 	@user_id = 0, 
		@manager = 0 

SELECT 	@user_id	= user_id, 
		@manager	= manager 
FROM 	CVO_Control..smusers 
WHERE 	user_name	= @user_name 

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amusrinf.sp" + ", line " + STR( 62, 5 ) + " -- EXIT: "

RETURN 0
GO
GRANT EXECUTE ON  [dbo].[amUserInfo_sp] TO [public]
GO
