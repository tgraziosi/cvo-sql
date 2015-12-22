SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[amDeprTrxReport_sp] 
( 
	@company_id			smCompanyID,
	@trx_ctrl_num		smControlNumber,
	@start_asset		smControlNumber,
	@end_asset			smControlNumber,
	@start_book			smBookCode,
	@end_book			smBookCode,
	@sort_by_asset		smLogical,				


	@debug_level		smDebugLevel	= 0		
)
AS

DECLARE
	@co_trx_id		smSurrogateKey
	
IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'amdprtrx.cpp' + ', line ' + STR( 66, 5 ) + ' -- ENTRY: '




SELECT	@co_trx_id		= co_trx_id
FROM	amtrxhdr
WHERE	company_id		= @company_id
AND		trx_ctrl_num	= @trx_ctrl_num




IF @start_asset = '<Start>'
BEGIN
	SELECT 	@start_asset 	= MIN(asset_ctrl_num)
	FROM	amasset
	WHERE	company_id		= @company_id
END

IF @end_asset = '<End>'
BEGIN
	SELECT 	@end_asset 		= MAX(asset_ctrl_num)
	FROM	amasset
	WHERE	company_id		= @company_id
END




IF @start_book = '<Start>'
BEGIN
	SELECT 	@start_book 	= MIN(book_code)
	FROM	ambook
END

IF @end_book = '<End>'
BEGIN
	SELECT 	@end_book 		= MAX(book_code)
	FROM	ambook
END

IF @debug_level >= 5
	SELECT 	start_asset = @start_asset, 
			end_asset	= @end_asset,
			start_book	= @start_book,
			end_book	= @end_book

CREATE TABLE #activities
(
	co_trx_id			int,
	co_asset_book_id	int
)




INSERT INTO #activities
(
	co_trx_id,
	co_asset_book_id
)
SELECT DISTINCT
	@co_trx_id,
	v.co_asset_book_id
FROM	amvalues	v,
		amastbk		ab,
		amasset		a
WHERE	v.co_trx_id			= @co_trx_id
AND		v.co_asset_book_id	= ab.co_asset_book_id
AND		ab.co_asset_id		= a.co_asset_id
AND		ab.book_code		BETWEEN @start_book AND @end_book
AND		a.asset_ctrl_num	BETWEEN	@start_asset AND @end_asset
AND		a.company_id		= @company_id

INSERT INTO #activities
(
	co_trx_id,
	co_asset_book_id
)
SELECT DISTINCT
	ah.co_trx_id,
	ah.co_asset_book_id
FROM	amacthst	ah,
		amastbk		ab,
		amasset		a
WHERE	ah.journal_ctrl_num	= @trx_ctrl_num
AND		ah.co_asset_book_id	= ab.co_asset_book_id
AND		ab.co_asset_id		= a.co_asset_id
AND		ab.book_code		BETWEEN @start_book AND @end_book
AND		a.asset_ctrl_num	BETWEEN	@start_asset AND @end_asset
AND		a.company_id		= @company_id

IF @debug_level >= 5
	SELECT 	* FROM #activities

INSERT INTO #activities
(
	co_trx_id,
	co_asset_book_id
)
SELECT DISTINCT
	ah.co_trx_id,
	ah.co_asset_book_id
FROM	#activities tmp,
		amacthst	ah
WHERE  	ah.journal_ctrl_num	!= @trx_ctrl_num
AND		ah.co_asset_book_id	= tmp.co_asset_book_id
AND		ah.posting_flag		= 100
AND		ah.trx_type			!= 50

IF @debug_level >= 5
	SELECT 	* FROM #activities

IF @sort_by_asset = 1
BEGIN
	INSERT INTO #ampenddep
	SELECT 	DISTINCT
		a.asset_ctrl_num, 
		a.asset_description, 
		ab.book_code, 
		v.account_type_id, 
		v.apply_date, 
		v.trx_type, 
		v.amount,
		credit		= v.amount, 
		acct.account_code, 
		acct.account_reference_code,
		abs_amount 	= abs(v.amount),
		v.co_trx_id,
		trx.trx_short_name,
		actp.account_type_name,
		a.org_id,
		dbo.IBGetParent_fn (a.org_id)
	FROM	#activities tmp,
			amasset		a,
			amastbk		ab, 
			amvalues	v, 
			amacct		acct,
			amtrxdef    trx,
			amacctyp 	actp,
			region_vw r,
			amOrganization_vw o
	WHERE	tmp.co_trx_id 			= v.co_trx_id
	AND		(a.org_id = r.org_id)
	AND 	(a.org_id = o.org_id)
	AND		tmp.co_asset_book_id 	= v.co_asset_book_id
	AND		a.co_asset_id 			= ab.co_asset_id 
	AND 	ab.co_asset_book_id 	= v.co_asset_book_id 
	AND 	v.account_id 			= acct.account_id
	AND     v.trx_type              = trx.trx_type
	AND     actp.account_type		= v.account_type_id
	ORDER BY
		ab.book_code, 
	 	a.asset_ctrl_num, 
	 	v.apply_date,    
		v.co_trx_id
		
END
ELSE
BEGIN
	INSERT INTO #ampenddep
	SELECT 	DISTINCT
	 	a.asset_ctrl_num, 
		a.asset_description, 
		ab.book_code, 
		v.account_type_id, 
		v.apply_date, 
		v.trx_type, 
		amount		= (sign(v.amount) + 1)/2 * v.amount,
		credit		= (sign(v.amount) - 1)/2 * v.amount, 
		acct.account_code, 
		acct.account_reference_code,
		abs_amount 	= abs(v.amount),
		v.co_trx_id,
		trx.trx_short_name,
		actp.account_type_name,
		a.org_id,
		dbo.IBGetParent_fn (a.org_id)
	FROM	#activities tmp,
			amasset		a,
			amastbk		ab, 
			amvalues	v, 
			amacct		acct,
			amtrxdef    trx,
			amacctyp 	actp,
			region_vw r,
			amOrganization_vw o				
	WHERE	tmp.co_trx_id 			= v.co_trx_id
	AND		(a.org_id = r.org_id)
	AND 	(a.org_id = o.org_id)
	AND		tmp.co_asset_book_id 	= v.co_asset_book_id
	AND		a.co_asset_id 			= ab.co_asset_id 
	AND 	ab.co_asset_book_id 	= v.co_asset_book_id 
	AND 	v.account_id 			= acct.account_id
	AND     v.trx_type              = trx.trx_type
	AND     actp.account_type		= v.account_type_id
	ORDER BY
		ab.book_code, 
	 	acct.account_code,    
		acct.account_reference_code,
	 	a.asset_ctrl_num, 
		v.apply_date,
		v.co_trx_id		
END

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'amdprtrx.cpp' + ', line ' + STR( 272, 5 ) + ' -- EXIT: '

RETURN 0 
GO
GRANT EXECUTE ON  [dbo].[amDeprTrxReport_sp] TO [public]
GO
