SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[amApplyClassification_sp] 
( 	
	@company_id			smCompanyID,		
	@classification_id	smSurrogateKey,	   	
	@account_type_id	smAccountTypeID,   	
	@start_col_part2	smSmallCounter,		
	@length_part1		smSmallCounter,		
	@length_part2		smSmallCounter,					
	@debug_level		smDebugLevel	= 0,
	@perf_level			smPerfLevel		= 0	
) 
AS 


DECLARE 
	@error 			smErrorCode









DECLARE
        @PERF_time_last     datetime

SELECT  @PERF_time_last = GETDATE()

















									







IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "amappcls.cpp" + ", line " + STR( 120, 5 ) + " -- ENTRY: "
IF ( @perf_level >= 1 ) EXEC perf_sp "Create Accounts", "amappcls.cpp", 121, "Enter amApplyClassification_sp", @PERF_time_last OUTPUT
































UPDATE 	#amcreact
SET 	account_code 		= 	dbo.IBReplaceBranchMask_fn( 
					SUBSTRING(account_code, 1, @length_part1)
								+ c.gl_override 
								+ SUBSTRING(account_code, @start_col_part2, @length_part2)
		       		  	,  ams.org_id)
FROM 	#amcreact 	tmp, #amacctid tmp_acct,
		amcls 		c, 
		amastcls 	ac 
		,amasset	ams
WHERE   tmp.co_asset_id 		= ac.co_asset_id
AND     ac.company_id 			= c.company_id
AND     ac.classification_id 	= c.classification_id
AND     ac.classification_code 	= c.classification_code
AND     c.gl_override 			IS NOT NULL
AND		tmp.account_type_id		= tmp_acct.account_type_id
AND		c.company_id			= @company_id
AND		c.classification_id		= @classification_id
AND		ac.company_id			= @company_id
AND		ac.classification_id	= @classification_id
AND	ams.co_asset_id = ac.co_asset_id
SELECT @error = @@error
IF @error <> 0
	RETURN @error

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "amappcls.cpp" + ", line " + STR( 179, 5 ) + " -- EXIT: "
IF ( @perf_level >= 1 ) EXEC perf_sp "Create Accounts", "amappcls.cpp", 180, "Exit amApplyClassification_sp", @PERF_time_last OUTPUT

RETURN 0 
GO
GRANT EXECUTE ON  [dbo].[amApplyClassification_sp] TO [public]
GO
