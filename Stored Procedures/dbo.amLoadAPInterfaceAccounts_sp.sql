SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[amLoadAPInterfaceAccounts_sp] 
( 	
	@company_id 	smCompanyID, 						
	@apply_date		smApplyDate,	 				 	
	@trx_type		smTrxType		= 50,	
	@start_book		smBookCode		= NULL,																		
	@end_book		smBookCode		= NULL,				
	@debug_level	smDebugLevel 	= 0					
) 
AS 

DECLARE 
	@result 			smErrorCode,
	@jul_end_date		smJulianDate

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amldapac.sp" + ", line " + STR( 76, 5 ) + " -- ENTRY: "

IF @debug_level >= 5
BEGIN
	SELECT	trx_type	= @trx_type,
			apply_date	= @apply_date
	
	SELECT * FROM #amastnum
END	

SELECT	@jul_end_date = DATEDIFF(dd, "1/1/1980", @apply_date) + 722815

				


CREATE TABLE #am_ap_activity
(
	co_asset_id				int,		
	co_trx_id				int,
	jul_apply_date			int,			
	fixed_asset_account_id	int,
	imm_exp_account_id		int
)

IF @trx_type = 50
BEGIN
	
	INSERT INTO #am_ap_activity
	(
			co_asset_id,
			co_trx_id,
			jul_apply_date,
			fixed_asset_account_id,
			imm_exp_account_id
	)
	SELECT	DISTINCT
			tmp.co_asset_id,
			th.co_trx_id,
			DATEDIFF(dd, "1/1/1980", th.apply_date) + 722815,
			th.fixed_asset_account_id,
			th.imm_exp_account_id
	FROM	#amastnum	 	tmp,
			amastbk			ab,
			amtrxhdr		th
	WHERE 	tmp.co_asset_id		= ab.co_asset_id
	AND		tmp.co_asset_id		= th.co_asset_id
	AND		ab.co_asset_id		= th.co_asset_id
	AND		(
				th.apply_date				> ab.last_posted_depr_date
			OR	ab.last_posted_depr_date 	IS NULL
			)
	AND		th.apply_date					<= @apply_date
	AND		trx_source						= 4
	AND		(	th.fixed_asset_account_id	!= 0
			OR 	th.imm_exp_account_id		!= 0)

	SELECT @result = @@error
	IF @result <> 0
	BEGIN
		DROP TABLE 	#am_ap_activity
		RETURN 		@result
	END

END
ELSE
BEGIN
	
	INSERT INTO #am_ap_activity
	(
			co_asset_id,
			co_trx_id,
			jul_apply_date,
			fixed_asset_account_id,
			imm_exp_account_id
	)
	SELECT	DISTINCT
			tmp.co_asset_id,
			th.co_trx_id,
			DATEDIFF(dd, "1/1/1980", th.apply_date) + 722815,
			th.fixed_asset_account_id,
			th.imm_exp_account_id
	FROM	#amastnum	 	tmp,
			amastbk			ab,
			amacthst		ah,
			amtrxhdr		th
	WHERE 	tmp.co_asset_id		= ab.co_asset_id
	AND		tmp.co_asset_id		= th.co_asset_id
	AND		ab.co_asset_id		= th.co_asset_id
	AND		(
				th.apply_date				> ab.last_posted_depr_date
			OR	ab.last_posted_depr_date 	IS NULL
			)
	AND		trx_source						= 4
	AND		(	th.fixed_asset_account_id	!= 0
			OR 	th.imm_exp_account_id		!= 0)


	SELECT @result = @@error
	IF @result <> 0
	BEGIN
		DROP TABLE #am_ap_activity
		RETURN 	@result
	END
END

IF @debug_level >= 3
BEGIN
	SELECT	* 
	FROM	#am_ap_activity

END


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
		tmp.co_asset_id,
		tmp.co_trx_id,
		tmp.jul_apply_date,
		acct.account_reference_code,
		3,
		acct.account_code,				
		acct.account_code,
		0
FROM	#am_ap_activity 	tmp,
		amacct				acct
WHERE	tmp.fixed_asset_account_id	= acct.account_id
AND		tmp.fixed_asset_account_id	!= 0

SELECT @result = @@error
IF @result <> 0
BEGIN
	DROP TABLE 	#am_ap_activity
	RETURN 		@result
END

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
		tmp.co_asset_id,
		tmp.co_trx_id,
		tmp.jul_apply_date,
		acct.account_reference_code,
		9,
		acct.account_code,			 
		acct.account_code,
		0
FROM	#am_ap_activity 	tmp,
		amacct				acct
WHERE	tmp.imm_exp_account_id	= acct.account_id
AND		tmp.imm_exp_account_id	!= 0


SELECT @result = @@error
IF @result <> 0
BEGIN
	DROP TABLE #am_ap_activity
	RETURN 	@result
END

DROP TABLE #am_ap_activity

IF @debug_level >= 3
	SELECT * FROM #amaccts

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amldapac.sp" + ", line " + STR( 292, 5 ) + " -- EXIT: "

RETURN 0 
GO
GRANT EXECUTE ON  [dbo].[amLoadAPInterfaceAccounts_sp] TO [public]
GO
