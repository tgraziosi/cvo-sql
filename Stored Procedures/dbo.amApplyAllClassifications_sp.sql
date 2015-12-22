SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[amApplyAllClassifications_sp] 
(
	@company_id				smCompanyID,		 	
	@debug_level			smDebugLevel	= 0,	
	@perf_level				smPerfLevel		= 0		
)
AS 







DECLARE
 @PERF_time_last datetime

SELECT @PERF_time_last = GETDATE()















									







DECLARE 
	@error 						smErrorCode,
	@message					smErrorLongDesc,
	@acct_len 					smSmallCounter,
	@classification_id 			smSurrogateKey,
	@start_col_part2			smSmallCounter,
	@length_part1				smSmallCounter,
	@length_part2				smSmallCounter				

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amapacls.sp" + ", line " + STR( 107, 5 ) + " -- ENTRY: "
IF ( @perf_level >= 1 ) EXEC perf_sp "Create Accounts", "tmp/amapacls.sp", 108, "Enter amApplyAllClassifications_sp", @PERF_time_last OUTPUT



SELECT 	@classification_id 	= MIN(classification_id)
FROM	amclshdr
WHERE	length 				> 0			
AND		company_id 			= @company_id


IF @@rowcount = 0
	RETURN 0
 
WHILE @classification_id IS NOT NULL
BEGIN
	
	
	SELECT
			@start_col_part2			= start_col + length,
			@length_part1				= start_col - 1,
			@length_part2				= 32 - (start_col + length) + 1
		
	FROM	amclshdr
	WHERE	classification_id 			= @classification_id
	AND		company_id					= @company_id

	INSERT INTO #amacctid(account_type_id)
 	SELECT	a.account_type
 	FROM 	amclsact a
	WHERE 	a.classification_id 		= @classification_id
	AND		a.company_id				= @company_id
	AND		a.override_account_flag 	= 1


	SELECT @error = @@error
	IF @error <> 0
	BEGIN
		DROP TABLE #amacctid
		RETURN @error
	END
		
	 
	IF (SELECT COUNT(*) FROM #amacctid) > 0
	BEGIN

		EXEC	@error = amApplyClassification_sp 
							@company_id,
							@classification_id,
							10,
							@start_col_part2,
							@length_part1,
							@length_part2
							WITH RECOMPILE
		IF @error <> 0
		BEGIN
			DROP TABLE #amacctid
			RETURN @error
		END
	END
	
	
	SELECT 	@classification_id = MIN(classification_id)
	FROM	amclshdr
	WHERE	length 				> 0				
	AND		classification_id 	> @classification_id
	AND		company_id			= @company_id

	
	TRUNCATE TABLE #amacctid

END

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amapacls.sp" + ", line " + STR( 188, 5 ) + " -- EXIT: "
IF ( @perf_level >= 1 ) EXEC perf_sp "Create Accounts", "tmp/amapacls.sp", 189, "Exit amApplyAllClassifications_sp", @PERF_time_last OUTPUT

RETURN 0 
GO
GRANT EXECUTE ON  [dbo].[amApplyAllClassifications_sp] TO [public]
GO
