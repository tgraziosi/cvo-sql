SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[amLoadAllAddAccounts_sp] 
( 	
	@company_id 	smCompanyID,
	@start_org_id   smOrgId,
	@end_org_id     smOrgId,
	@debug_level	smDebugLevel	= 0	
) 
AS 

DECLARE @error 			smErrorCode

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amldalaa.sp" + ", line " + STR( 60, 5 ) + " -- ENTRY: "

IF ( @debug_level >= 3 ) 
   SELECT 'Start amLoadAllAddAccounts_sp'


UPDATE 	#amastnum
SET		posting_code 	= c.posting_code
FROM	#amastnum tmp,
		amasset a,
		amcat	c,
		amOrganization_vw o
WHERE	a.co_asset_id		= tmp.co_asset_id
AND		a.category_code		= c.category_code
AND     a.org_id    = o.org_id
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
		DATEDIFF(dd, "1/1/1980", a.acquisition_date) + 722815,
		a.account_reference_code,
		p.account_type,
		p.account,		 
		p.account,
		-1
FROM	#amastnum tmp,
		amasset	 a,
		ampstact p,
		amOrganization_vw o
WHERE	a.co_asset_id		= tmp.co_asset_id
AND		p.posting_code		= tmp.posting_code
AND 	p.company_id		= @company_id
AND     a.org_id    = o.org_id
AND     a.org_id  BETWEEN @start_org_id AND @end_org_id


SELECT @error = @@error
IF @error <> 0
	RETURN 	@error

 

IF @debug_level >= 3
BEGIN
        SELECT 'Exit from amLoadAllAddAccounts_sp'
	SELECT * FROM #amaccts
END	
IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amldalaa.sp" + ", line " + STR( 114, 5 ) + " -- EXIT: "

RETURN 0 
GO
GRANT EXECUTE ON  [dbo].[amLoadAllAddAccounts_sp] TO [public]
GO
