SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[amLoadAllAccounts_sp] 
( 	
	@company_id 	smCompanyID, 						
	@apply_date		smApplyDate,	  				 	


	@trx_type		smTrxType		= 50,	


	@start_book		smBookCode		= NULL,				

														
	@end_book		smBookCode		= NULL,				



	@start_org_id                   smOrgId,					
	@end_org_id                     smOrgId,					
	@debug_level	smDebugLevel 	= 0,				
	@perf_level		smPerfLevel		= 0					
) 
AS 









DECLARE
        @PERF_time_last     datetime

SELECT  @PERF_time_last = GETDATE()

















									







DECLARE 
	@result 			smErrorCode,
	@jul_end_date		smJulianDate

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "amldalac.cpp" + ", line " + STR( 93, 5 ) + " -- ENTRY: "
IF ( @perf_level >= 1 ) EXEC perf_sp "Create Accounts", "amldalac.cpp", 94, "Enter amLoadAllAccounts_sp", @PERF_time_last OUTPUT

IF @debug_level >= 5
BEGIN
	SELECT	trx_type	= @trx_type,
			apply_date	= @apply_date
	
	SELECT * FROM #amastnum
END	

SELECT	@jul_end_date = DATEDIFF(dd, "1/1/1980", @apply_date) + 722815







IF @trx_type = 50
BEGIN

	


	UPDATE 	#amastnum
	SET		posting_code 	= c.posting_code
	FROM	#amastnum tmp,
			amasset a,
			amcat	c,
			amOrganization_vw o
	WHERE	a.co_asset_id		= tmp.co_asset_id
	AND		a.category_code		= c.category_code
	AND     a.org_id   = o.org_id
        AND     a.org_id  BETWEEN @start_org_id AND @end_org_id



	INSERT INTO #amaccts
	(
			co_asset_id,
			co_trx_id,
			jul_apply_date,
			account_reference_code,
			account_type_id,
			original_account_code,
			new_account_code,
			error_code
	)
	SELECT	a.co_asset_id,
			0,						
			@jul_end_date,
			a.account_reference_code,
			p.account_type,
			dbo.IBAcctMask_fn( p.account, a.org_id),	 
			dbo.IBAcctMask_fn( p.account, a.org_id),	
			-1
	FROM	#amastnum tmp,
			amasset a,
			ampstact p,
			amtrxact ta,
			amOrganization_vw o
	WHERE	a.co_asset_id	= tmp.co_asset_id
	AND     a.org_id   = o.org_id
	AND     a.org_id      BETWEEN @start_org_id AND @end_org_id
	AND		p.posting_code		= tmp.posting_code
	AND 	p.company_id		= @company_id
	AND		p.account_type		= ta.account_type
	AND		ta.trx_type 		= 50

	SELECT @result = @@error
	IF @result <> 0
		RETURN 	@result

END
				
IF ( @perf_level >= 2 ) EXEC perf_sp "Create Accounts", "amldalac.cpp", 169, "Loaded Depreciation accounts", @PERF_time_last OUTPUT












CREATE TABLE #am_asset_activity
(
	co_asset_id			int,		
	trx_type			tinyint,	
	jul_apply_date		int,
	posting_code		char(8) NULL
)

IF @trx_type = 50
BEGIN
	




	INSERT INTO #am_asset_activity
	(
			co_asset_id,
			trx_type,
			jul_apply_date
	)
	SELECT	DISTINCT
			tmp.co_asset_id,
			ah.trx_type,
			DATEDIFF(dd, "1/1/1980", ah.apply_date) + 722815
	FROM	#amastnum	 	tmp,
			amastbk			ab,
			amacthst		ah
	WHERE 	ab.co_asset_id		= tmp.co_asset_id
	AND		ab.book_code		BETWEEN @start_book AND @end_book
	AND		ab.co_asset_book_id	= ah.co_asset_book_id
	AND		(
				ah.apply_date				> ab.last_posted_depr_date
			OR	ab.last_posted_depr_date 	IS NULL
			)
	AND		ah.apply_date		<= @apply_date

	SELECT @result = @@error
	IF @result <> 0
	BEGIN
		DROP TABLE 	#am_asset_activity
		RETURN 		@result
	END

END
ELSE
BEGIN
	



	INSERT INTO #am_asset_activity
	(
			co_asset_id,
			trx_type,
			jul_apply_date
	)
	SELECT	DISTINCT
			tmp.co_asset_id,
			ah.trx_type,
			DATEDIFF(dd, "1/1/1980", ah.apply_date) + 722815
	FROM	#amastnum	 	tmp,
			amastbk			ab,
			amacthst		ah
	WHERE 	tmp.co_asset_id		= ab.co_asset_id
	AND		ab.co_asset_book_id	= ah.co_asset_book_id
	AND		ah.posting_flag		!= 1

	SELECT @result = @@error
	IF @result <> 0
	BEGIN
		DROP TABLE #am_asset_activity
		RETURN 	@result
	END
END

IF ( @perf_level >= 2 ) EXEC perf_sp "Create Accounts", "amldalac.cpp", 258, "Collected activities", @PERF_time_last OUTPUT

IF @debug_level >= 3
BEGIN
	SELECT	* 
	FROM	#am_asset_activity

END

UPDATE 	#am_asset_activity
SET	   	posting_code = c.posting_code
FROM   	#am_asset_activity tmp,
		amcat c,
	   	amasset a,
		amOrganization_vw o
WHERE 	tmp.co_asset_id = a.co_asset_id
AND	a.category_code = c.category_code
AND     a.org_id   = o.org_id
AND     a.org_id      BETWEEN @start_org_id AND @end_org_id 



  


















IF @trx_type = 50
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
			error_code
	)
	SELECT DISTINCT 
			a.co_asset_id,
			0,
			tmp.jul_apply_date,
			a.account_reference_code,
			p.account_type,
			dbo.IBAcctMask_fn( p.account, a.org_id),	 
			dbo.IBAcctMask_fn( p.account, a.org_id),	 
			-1
	FROM	#am_asset_activity 	tmp,
			amasset 	a,
			ampstact	p,
			amtrxact    ta,
			amOrganization_vw o
	WHERE	a.co_asset_id		= tmp.co_asset_id
	AND     a.org_id   = o.org_id
	AND     a.org_id      BETWEEN @start_org_id AND @end_org_id
	AND		p.posting_code		= tmp.posting_code
	AND 	p.company_id		= @company_id
	AND		ta.account_type     = p.account_type
	AND     ta.trx_type			= tmp.trx_type
	AND     tmp.jul_apply_date	!= @jul_end_date 

	




	INSERT INTO #amaccts
	(
			co_asset_id,
			co_trx_id,
			jul_apply_date,
			account_reference_code,
			account_type_id,
			original_account_code,
			new_account_code,
			error_code
	)
	SELECT DISTINCT 
			a.co_asset_id,
			0,
			tmp.jul_apply_date,
			a.account_reference_code,
			p.account_type,
			dbo.IBAcctMask_fn( p.account, a.org_id), 	 
			dbo.IBAcctMask_fn( p.account, a.org_id),	 
			-1
	FROM	#am_asset_activity 	tmp,
			amasset 	a,
			ampstact	p,
			amtrxact    ta,
			amOrganization_vw o
	WHERE	a.co_asset_id		= tmp.co_asset_id
	AND     a.org_id   = o.org_id
	AND     a.org_id      BETWEEN @start_org_id AND @end_org_id
	AND		p.posting_code		= tmp.posting_code
	AND 	p.company_id		= @company_id
	AND		ta.account_type     = p.account_type
	AND     ta.trx_type			= tmp.trx_type
	AND     tmp.jul_apply_date  = @jul_end_date 
	AND		ta.trx_type		   != 50


END
ELSE
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
			error_code
	)
	SELECT DISTINCT 
			a.co_asset_id,
			0,
			tmp.jul_apply_date,
			a.account_reference_code,
			p.account_type,
			dbo.IBAcctMask_fn( p.account, a.org_id), 	 
			dbo.IBAcctMask_fn( p.account, a.org_id),	 
			-1
	FROM	#am_asset_activity 	tmp,
			amasset 	a,
			ampstact	p,
			amtrxact    ta,
			amOrganization_vw o
	WHERE	a.co_asset_id		= tmp.co_asset_id
	AND     a.org_id   = o.org_id
	AND     a.org_id      BETWEEN @start_org_id AND @end_org_id
	AND		p.posting_code		= tmp.posting_code
	AND 	p.company_id		= @company_id
	AND		ta.account_type     = p.account_type
	AND     ta.trx_type			= tmp.trx_type
END



SELECT @result = @@error
IF @result <> 0
BEGIN
	DROP TABLE 	#am_asset_activity
	RETURN 		@result
END

IF ( @perf_level >= 2 ) EXEC perf_sp "Create Accounts", "amldalac.cpp", 437, "Loaded accounts", @PERF_time_last OUTPUT





DROP TABLE #am_asset_activity

IF @debug_level >= 3
BEGIN
        SELECT 'EXIT amLoadAllAccounts_sp'
	SELECT * FROM #amaccts
END

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "amldalac.cpp" + ", line " + STR( 451, 5 ) + " -- EXIT: "
IF ( @perf_level >= 1 ) EXEC perf_sp "Create Accounts", "amldalac.cpp", 452, "Exit amLoadAllAccounts_sp", @PERF_time_last OUTPUT

RETURN 0 
GO
GRANT EXECUTE ON  [dbo].[amLoadAllAccounts_sp] TO [public]
GO
