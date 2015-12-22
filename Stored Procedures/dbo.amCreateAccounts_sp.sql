SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[amCreateAccounts_sp] 
( 	
	@company_id			smCompanyID,			
	@debug_level		smDebugLevel = 0,		
	@perf_level			smPerfLevel	= 0			
) 
AS 

DECLARE 	
	@result 			smErrorCode,
	@rowcount			smCounter,
	@start_date 		smApplyDate







DECLARE
 @PERF_time_last datetime

SELECT @PERF_time_last = GETDATE()





IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amcreact.sp" + ", line " + STR( 125, 5 ) + " -- ENTRY: "
IF ( @perf_level >= 1 ) EXEC perf_sp "Create Accounts", "tmp/amcreact.sp", 126, "Enter amCreateAccounts_sp", @PERF_time_last OUTPUT




CREATE CLUSTERED INDEX amaccts_ind_0 ON #amaccts (co_asset_id, jul_apply_date, account_type_id)



SELECT @start_date = GETDATE()

UPDATE 	#amaccts
SET		new_account_code	= aa.account_code,
		error_code			= 0			
FROM	#amaccts 	tmp,
		amastact 	aa
WHERE	tmp.co_asset_id		= aa.co_asset_id
AND		tmp.account_type_id	= aa.account_type_id
AND		aa.up_to_date		= 1

SELECT @result = @@error
IF @result <> 0
	RETURN @result





CREATE TABLE #amcreact
(	
	co_asset_id				int,				
	account_type_id			smallint,			
	account_code			char(32)
	    
)





CREATE TABLE #amacctid
(	
	account_type_id		smallint 	NOT NULL	
)




SET ROWCOUNT 100000

INSERT INTO #amcreact
(
	co_asset_id,
	account_type_id,
	account_code
)
SELECT DISTINCT
	co_asset_id,
	account_type_id,
	original_account_code
FROM	#amaccts tmp
WHERE	tmp.error_code = -1


SELECT @rowcount = @@rowcount, @result = @@error
IF @result <> 0
	RETURN @result

SET ROWCOUNT 0





CREATE CLUSTERED INDEX #amcreact_ind_0 ON #amcreact (co_asset_id, account_type_id)





WHILE @rowcount > 0
BEGIN

	IF @debug_level >= 5
		SELECT * FROM #amcreact

	IF @debug_level >= 3
	BEGIN
		SELECT "Number of accounts to recalculate:"
		SELECT COUNT(co_asset_id) FROM #amcreact
	END	
		
	
	EXEC @result = amApplyAssetType_sp
						@debug_level,
						@perf_level 
						WITH RECOMPILE
	IF @result <> 0
	BEGIN
		IF @debug_level >= 1
			SELECT "Exit amCreateAccounts: amApplyAssetType_sp failed"
		RETURN @result
	END


        
	
	EXEC @result = amApplyAllClassifications_sp
						@company_id,
						@debug_level,
						@perf_level
	IF @result <> 0
	BEGIN
		IF @debug_level >= 1
			SELECT "Exit amCreateAccounts: amApplyAllClassifications_sp failed"
		RETURN @result
	END

	IF @debug_level >= 3
		SELECT "Updating temp table and permanent table with latest accounts."
	
	 
	UPDATE 	#amaccts
	SET		new_account_code =tmp.account_code,
			error_code				= 0
	FROM	#amaccts accts, #amcreact tmp
	WHERE	accts.co_asset_id		= tmp.co_asset_id
	AND		accts.account_type_id	= tmp.account_type_id

	SELECT @result = @@error
	IF @result <> 0
		RETURN @result
		
	IF ( @debug_level > 1 )
	    SELECT * FROM #amcreact
	
	UPDATE 	amastact
	SET		account_code			= tmp.account_code,
			up_to_date				= 1,
			last_modified_date		= @start_date
	FROM	#amcreact tmp,
			amastact	aa
	WHERE	aa.co_asset_id			= tmp.co_asset_id
	AND		aa.account_type_id		= tmp.account_type_id
	AND		aa.up_to_date			= 0
	AND		aa.last_modified_date	< @start_date

	SELECT @result = @@error
	IF @result <> 0
		RETURN @result
	
	
	TRUNCATE TABLE #amcreact
	
	SET ROWCOUNT 100000

	INSERT INTO #amcreact
	(
		co_asset_id,
		account_type_id,
		account_code
	)
	SELECT DISTINCT
		co_asset_id,
		account_type_id,
		original_account_code
	FROM	#amaccts tmp
	WHERE	tmp.error_code = -1


	SELECT @rowcount = @@rowcount, @result = @@error
	IF @result <> 0
		RETURN @result

	SET ROWCOUNT 0

END

DROP TABLE #amcreact
DROP TABLE #amacctid

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amcreact.sp" + ", line " + STR( 300, 5 ) + " -- EXIT: "
IF ( @perf_level >= 1 ) EXEC perf_sp "Create Accounts", "tmp/amcreact.sp", 301, "Exit amCreateAccounts_sp", @PERF_time_last OUTPUT

RETURN 0 
GO
GRANT EXECUTE ON  [dbo].[amCreateAccounts_sp] TO [public]
GO
