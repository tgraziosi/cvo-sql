SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE [dbo].[amGetClsDescription_sp] 
(
	@company_id 		smCompanyID, 				
	@classification_id smSurrogateKey, 			
	@classification_code smClassificationCode, 		
	@classification_description	smStdDescription OUTPUT, 	
	@debug_level				smDebugLevel	= 0			
)
AS 

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amgetcld.sp" + ", line " + STR( 65, 5 ) + " -- ENTRY: "

SELECT 	@classification_description = classification_description
FROM	amcls
WHERE	company_id 			= @company_id
AND		classification_id 	= @classification_id
AND		classification_code = @classification_code

IF @classification_description IS NULL
	SELECT @classification_description = " "
	
IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amgetcld.sp" + ", line " + STR( 76, 5 ) + " -- EXIT: "

RETURN 0
GO
GRANT EXECUTE ON  [dbo].[amGetClsDescription_sp] TO [public]
GO
