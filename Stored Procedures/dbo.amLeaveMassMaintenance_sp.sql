SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

 
CREATE PROCEDURE [dbo].[amLeaveMassMaintenance_sp] 
( 
	@mass_maintenance_id 	smSurrogateKey,		
	@debug_level			smDebugLevel	= 0		
)
AS 
 
DECLARE 
	@result smErrorCode 


IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amleavem.sp" + ", line " + STR( 61, 5 ) + " -- ENTRY: " 

IF NOT EXISTS(SELECT 	mass_maintenance_id
				FROM 	ammashdr 
				WHERE 	mass_maintenance_id 	= @mass_maintenance_id)
BEGIN
	DELETE 
	FROM 	ammasast
	WHERE	mass_maintenance_id	= @mass_maintenance_id
	
	SELECT	 @result = @@error
	IF @result <> 0
		RETURN @result
END


IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amleavem.sp" + ", line " + STR( 77, 5 ) + " -- EXIT: "
 
RETURN 0 
GO
GRANT EXECUTE ON  [dbo].[amLeaveMassMaintenance_sp] TO [public]
GO
