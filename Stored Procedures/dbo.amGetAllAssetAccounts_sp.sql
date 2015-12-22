SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[amGetAllAssetAccounts_sp] 
( 	
	@co_asset_id 		smSurrogateKey,	   	
	@debug_level		smDebugLevel  = 0 	
) 
AS 

DECLARE @error 					smErrorCode,
		@company_id				smCompanyID,
		@posting_code			smPostingCode,
		@account_reference_code	smAccountReferenceCode,
		@account_code			smAccountCode, 
		@jul_todays_date		smJulianDate,
		@asset_ctrl_num			smControlNumber,
		@org_id				varchar(30)		

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "amgetaaa.cpp" + ", line " + STR( 122, 5 ) + " -- ENTRY: "

SELECT	@jul_todays_date = DATEDIFF(dd, "1/1/1980", GETDATE()) + 722815


SELECT	@company_id				= a.company_id,
		@account_reference_code = a.account_reference_code,
		@posting_code			= c.posting_code,
		@org_id				= a.org_id		 
FROM	amasset a,
		amcat	c
		
WHERE	a.co_asset_id 			= @co_asset_id
AND		a.category_code			= c.category_code


IF @@rowcount = 0
	RETURN 20020

IF @debug_level >= 3
	SELECT asset_ctrl_num = @asset_ctrl_num




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
SELECT
	@co_asset_id,
	0,
	@jul_todays_date,
	@account_reference_code,
	p.account_type,
	dbo.IBAcctMask_fn( p.account, @org_id),		
	dbo.IBAcctMask_fn( p.account, @org_id),		
	-1
FROM ampstact p
WHERE p.company_id 		= @company_id
AND   p.posting_code 	= @posting_code	


SELECT @error = @@error
IF @error <> 0
	RETURN @error


	
IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "amgetaaa.cpp" + ", line " + STR( 178, 5 ) + " -- EXIT: "

RETURN 0 
GO
GRANT EXECUTE ON  [dbo].[amGetAllAssetAccounts_sp] TO [public]
GO
