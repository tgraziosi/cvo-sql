SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

 
CREATE PROCEDURE [dbo].[amAPExists_sp] 
( 
	@company_db_name 	varchar(128), 		
 @ap_exists 		smLogical 		OUTPUT,	
	@debug_level		smDebugLevel	= 0		
)
AS 
 
DECLARE 
	@message smErrorLongDesc 


IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amapexst.sp" + ", line " + STR( 57, 5 ) + " -- ENTRY: " 

IF EXISTS(SELECT 	company_db_name
			FROM 	CVO_Control..s2papprg 
			WHERE 	RTRIM(company_db_name) 	= RTRIM(@company_db_name)
			AND 	app_id 				= 4000)
	SELECT @ap_exists = 1
ELSE
	SELECT @ap_exists = 0
 
IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amapexst.sp" + ", line " + STR( 67, 5 ) + " -- EXIT: "
 
RETURN 0 
GO
GRANT EXECUTE ON  [dbo].[amAPExists_sp] TO [public]
GO
