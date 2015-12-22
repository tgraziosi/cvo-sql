SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[amCreateAccountCodeReport_sp] 
( 	
	@company_id 		smCompanyID, 			
	@org_id1                varchar (30),
	@org_id2                varchar (30),	
	@asset_ctrl_num1 	smControlNumber, 		


	@asset_ctrl_num2 	smControlNumber,		


	@activity_state		smallint,				
	@select_assets		tinyint,				  
	@iso_apply_date		smISODate,				
	@show_errors_only	smLogical		= 1,	


 
	@in_asset_order		smLogical		= 1,	


	@debug_level		smDebugLevel	= 0,	
	@perf_level			smPerfLevel		= 0		
) 
AS 









DECLARE
        @PERF_time_last     datetime

SELECT  @PERF_time_last = GETDATE()

















									







DECLARE 
	@error 				smErrorCode,
	@apply_date			smApplyDate,
	@jul_apply_date		smJulianDate,
	@rowcount			smCounter,
	@is_imported		smLogical,
	@home_currency_code	smCurrencyCode

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "amacctrp.cpp" + ", line " + STR( 180, 5 ) + " -- ENTRY: "
IF ( @perf_level >= 1 ) EXEC perf_sp "Create Accounts", "amacctrp.cpp", 181, "Enter amCreateAccountCodeReport_sp", @PERF_time_last OUTPUT

SELECT 	@apply_date = CONVERT(datetime, @iso_apply_date)
SELECT	@jul_apply_date =  DATEDIFF(dd, "1/1/1980", @apply_date) + 722815

IF @org_id1 = "<Start>"
BEGIN
	SELECT 	@org_id1 	= MIN(organization_id)
	FROM	Organization
END

IF @org_id2 = "<End>"
BEGIN
	SELECT 	@org_id2 	= MAX(organization_id)
	FROM	Organization
END





IF @asset_ctrl_num1 = "<Start>"
BEGIN
	SELECT 	@asset_ctrl_num1 	= MIN(asset_ctrl_num)
	FROM	amasset
	WHERE	company_id			= @company_id
END

IF @asset_ctrl_num2 = "<End>"
BEGIN
	SELECT 	@asset_ctrl_num2 	= MAX(asset_ctrl_num)
	FROM	amasset
	WHERE	company_id			= @company_id
END



 
EXEC @error = amGetCurrencyCode_sp 
					@company_id,
					@home_currency_code OUTPUT 

IF @error <> 0
	RETURN @error





CREATE TABLE #assets
(
	co_asset_id				int			NOT NULL,
	account_reference_code	varchar(32)	NOT NULL,	
	posting_code			char(8)		NOT NULL,
	org_id                  varchar (30)
)

IF @activity_state = -1
BEGIN
	


	IF @select_assets = 0
	BEGIN
		


		INSERT INTO #assets
		(
				co_asset_id,
				account_reference_code,
				posting_code,
				org_id
		)
		SELECT
				a.co_asset_id,
				a.account_reference_code,
				c.posting_code,
				a.org_id
		FROM	amasset a, amcat c, amOrganization_vw o
		WHERE	a.company_id 		= @company_id
		AND		a.asset_ctrl_num 	BETWEEN @asset_ctrl_num1 and @asset_ctrl_num2 
		AND		a.org_id	BETWEEN @org_id1 and @org_id2
		AND		a.category_code		= c.category_code
		AND	a.org_id = o.org_id

		SELECT @rowcount = @@rowcount, @error = @@error
		IF @error <> 0 
			RETURN @error
	END
	ELSE
	BEGIN
		




		SELECT	@is_imported = @select_assets - 1
			
		INSERT INTO #assets
		(
				co_asset_id,
				account_reference_code,
				posting_code,
				org_id
		)
		SELECT
				a.co_asset_id,
				a.account_reference_code,
				c.posting_code,
				a.org_id
		FROM	amasset a, amcat c, amOrganization_vw o
		WHERE	a.company_id 		= @company_id
		AND		a.asset_ctrl_num 	BETWEEN @asset_ctrl_num1 and @asset_ctrl_num2
		AND		a.org_id	BETWEEN @org_id1 and @org_id2
		AND		a.category_code		= c.category_code
		AND		a.is_imported		= @is_imported
		AND	a.org_id = o.org_id

		SELECT @rowcount = @@rowcount, @error = @@error
		IF @error <> 0 
			RETURN @error
	END
END
ELSE
BEGIN
	


	IF @select_assets = 0
	BEGIN
		


		INSERT INTO #assets
		(
				co_asset_id,
				account_reference_code,
				posting_code,
				org_id
		)
		SELECT
				a.co_asset_id,
				a.account_reference_code,
				c.posting_code,
				a.org_id
		FROM	amasset a, amcat c, amOrganization_vw o
		WHERE	a.company_id 		= @company_id
		AND		a.asset_ctrl_num 	BETWEEN @asset_ctrl_num1 and @asset_ctrl_num2
		AND		a.org_id	BETWEEN @org_id1 and @org_id2
		AND		a.category_code		= c.category_code
		AND		a.activity_state	= @activity_state
		AND	a.org_id = o.org_id

		SELECT @rowcount = @@rowcount, @error = @@error
		IF @error <> 0 
			RETURN @error
	END
	ELSE
	BEGIN
		




		SELECT	@is_imported = @select_assets - 1
			
		INSERT INTO #assets
		(
				co_asset_id,
				account_reference_code,
				posting_code,
				org_id
		)
		SELECT
				a.co_asset_id,
				a.account_reference_code,
				c.posting_code,
				a.org_id
		FROM	amasset a, amcat c, amOrganization_vw o
		WHERE	a.company_id 		= @company_id
		AND		a.asset_ctrl_num 	BETWEEN @asset_ctrl_num1 and @asset_ctrl_num2
		AND		a.org_id	BETWEEN @org_id1 and @org_id2
		AND		a.category_code		= c.category_code
		AND		a.is_imported		= @is_imported
		AND		a.activity_state 	= @activity_state
		AND	a.org_id = o.org_id

		SELECT @rowcount = @@rowcount, @error = @@error
		IF @error <> 0 
			RETURN @error
	END
END

IF ( @perf_level >= 2 ) EXEC perf_sp "Create Accounts", "amacctrp.cpp", 375, "Loaded Assets", @PERF_time_last OUTPUT
IF @debug_level >= 3
	SELECT "Loaded Assets"



 











































CREATE TABLE #amaccts
(	
	co_asset_id				int,				
	co_trx_id				int,				


	jul_apply_date			int,				
	account_reference_code	varchar(32),		
	account_type_id			smallint,			
	original_account_code	char(32),			 
	new_account_code		char(32),			
	error_code				int,					
	org_id                  varchar (30)
)




IF @rowcount > 0
BEGIN
	


	INSERT INTO #amaccts
	(
		co_asset_id,
		co_trx_id,
		jul_apply_date,
		account_reference_code,
		account_type_id,
		original_account_code,
		new_account_code,
		error_code,
		org_id 
	)
	SELECT	a.co_asset_id,
			0,
			@jul_apply_date,
			a.account_reference_code,
			p.account_type,
			p.account,
			p.account,
			-1,
			a.org_id
	FROM	#assets a,
			ampstact	p
	WHERE	a.posting_code		= p.posting_code
	AND 	p.company_id		= @company_id

	SELECT @error = @@error
	IF @error <> 0 
	BEGIN
		DROP TABLE #amaccts
		DROP TABLE #amaccerr
		RETURN @error
	END
		
	IF @debug_level >= 3
		SELECT "Loaded Accounts"
	
	
	


	DROP TABLE #assets

	IF @debug_level > 3
		SELECT * FROM #amaccts

	IF ( @perf_level >= 2 ) EXEC perf_sp "Create Accounts", "amacctrp.cpp", 435, "Loaded Base Accounts", @PERF_time_last OUTPUT
	
	


	EXEC @error = amCreateAccounts_sp
					   @company_id,
					   @debug_level
	IF @error <> 0
	BEGIN
		DROP TABLE #amaccts
		RETURN @error
	END

	IF ( @perf_level >= 2 ) EXEC perf_sp "Create Accounts", "amacctrp.cpp", 449, "Dynamically Created Accounts", @PERF_time_last OUTPUT

END
ELSE
BEGIN
	


	DROP TABLE #assets
END



 






















CREATE TABLE #amaccerr
(	
	error_code					int,			
	error_message				varchar(255)	
)


IF @rowcount > 0
BEGIN
	



	EXEC @error = amValidateAllAccounts_sp  
						@home_currency_code,
						@debug_level
						WITH RECOMPILE
	IF @error <> 0
	BEGIN
		DROP TABLE #amaccts
		DROP TABLE #amaccerr
		RETURN @error
	END

	IF ( @perf_level >= 2 ) EXEC perf_sp "Create Accounts", "amacctrp.cpp", 482, "Validated Accounts", @PERF_time_last OUTPUT
END



 
IF @in_asset_order = 1
BEGIN
	IF @show_errors_only = 1
	BEGIN
		SELECT 	
					a.asset_ctrl_num,
					a.asset_description,
					accounts.account_reference_code,
					accounts.account_type_id,
					accounts.original_account_code,
					accounts.new_account_code,
					accerr.error_message,
					acct.account_type_name,
					a.org_id 
		FROM 		#amaccts 	accounts, #amaccerr accerr,
					amasset		a,amacctyp acct 
		WHERE		accounts.co_asset_id 	= a.co_asset_id
		AND			accounts.error_code		= accerr.error_code
		AND			accounts.account_type_id= acct.account_type
		ORDER BY 	a.asset_ctrl_num, 
					acct.display_order
	END
	ELSE
	BEGIN
		SELECT 	
					a.asset_ctrl_num,
					a.asset_description,
					accounts.account_reference_code,
					accounts.account_type_id,
					accounts.original_account_code,
					accounts.new_account_code,
					accerr.error_message,
					acct.account_type_name,
					a.org_id 
		FROM 		#amaccts 	accounts 	LEFT OUTER JOIN #amaccerr 	accerr ON accounts.error_code	= accerr.error_code
				INNER JOIN	amasset		a 	ON accounts.co_asset_id 	= a.co_asset_id
				INNER JOIN 	amacctyp	acct	ON accounts.account_type_id 	= acct.account_type
		ORDER BY 	a.asset_ctrl_num, 
					acct.display_order








	END
END
ELSE
BEGIN
	IF @show_errors_only = 1
	BEGIN
		SELECT 	
					a.asset_ctrl_num,
					a.asset_description,
					accounts.account_reference_code,
					accounts.account_type_id,
					accounts.original_account_code,
					accounts.new_account_code,
					accerr.error_message,
					acct.account_type_name,
					a.org_id 
		FROM 		#amaccts 	accounts,#amaccerr accerr,
					amasset		a,	amacctyp	acct 
		WHERE		accounts.co_asset_id 	= a.co_asset_id
		AND			accounts.error_code		= accerr.error_code
		AND			accounts.account_type_id = acct.account_type
		ORDER BY 	accounts.new_account_code, 
					accounts.account_reference_code
	END
	ELSE
	BEGIN
		SELECT 	
					a.asset_ctrl_num,
					a.asset_description,
					accounts.account_reference_code,
					accounts.account_type_id,
					accounts.original_account_code,
					accounts.new_account_code,
					accerr.error_message,
					acct.account_type_name,
					a.org_id 
		FROM 		#amaccts 	accounts 	LEFT OUTER JOIN #amaccerr 	accerr ON accounts.error_code	= accerr.error_code
				INNER JOIN	amasset		a 	ON accounts.co_asset_id 	= a.co_asset_id
				INNER JOIN 	amacctyp	acct	ON accounts.account_type_id 	= acct.account_type
		ORDER BY 	a.asset_ctrl_num, 
					acct.display_order








	END
END

 
DROP TABLE #amaccts
DROP TABLE #amaccerr

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "amacctrp.cpp" + ", line " + STR( 591, 5 ) + " -- EXIT: "
IF ( @perf_level >= 1 ) EXEC perf_sp "Create Accounts", "amacctrp.cpp", 592, "Exit amCreateAccountCodeReport_sp", @PERF_time_last OUTPUT

RETURN 0 
GO
GRANT EXECUTE ON  [dbo].[amCreateAccountCodeReport_sp] TO [public]
GO
