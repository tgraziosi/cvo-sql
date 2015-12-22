SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE [dbo].[amClassificationUsed_sp] 
(
	@company_id			smCompanyID,			
	@classification_id	smSurrogateKey,			
	@used 				smLogical 		OUTPUT, 
	@debug_level		smDebugLevel	= 0		
)
AS 

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amcdfuse.sp" + ", line " + STR( 66, 5 ) + " -- ENTRY: "

SELECT @used = 0 

IF EXISTS ( SELECT 	company_id 
			FROM 	amcls 
			WHERE 	company_id 			= @company_id
			AND		classification_id 	= @classification_id)
	SELECT @used = 	1 

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amcdfuse.sp" + ", line " + STR( 76, 5 ) + " -- EXIT: "

RETURN 0 
GO
GRANT EXECUTE ON  [dbo].[amClassificationUsed_sp] TO [public]
GO
