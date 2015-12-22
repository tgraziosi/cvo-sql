SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE [dbo].[amDeprRuleUsed_sp] 
(
 @depr_rule_code 	smDeprRuleCode, 		
	@used 	smLogical 	OUTPUT, 	
	@debug_level		smDebugLevel	 = 0	
)
AS 

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amruluse.sp" + ", line " + STR( 51, 5 ) + " -- ENTRY: "

SELECT @used = 0 

IF EXISTS (SELECT depr_rule_code 
 FROM amdprhst 
		 WHERE depr_rule_code = @depr_rule_code )
	SELECT @used = 1 


IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amruluse.sp" + ", line " + STR( 61, 5 ) + " -- EXIT: "

RETURN 0
GO
GRANT EXECUTE ON  [dbo].[amDeprRuleUsed_sp] TO [public]
GO
