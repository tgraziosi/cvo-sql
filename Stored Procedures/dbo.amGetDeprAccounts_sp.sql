SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE [dbo].[amGetDeprAccounts_sp] 
( 	
	@company_id				smCompanyID,			
	@co_asset_id 		smSurrogateKey, 	
	@apply_date				smApplyDate,			
	@depr_exp_acct_id 	smSurrogateKey OUTPUT, 
	@accum_depr_acct_id		smSurrogateKey OUTPUT, 	
	@debug_level			smDebugLevel	= 0		
) 
AS 

DECLARE 
	@return_status 		smErrorCode, 
	@message				smErrorLongDesc,
	@jul_apply_date			smJulianDate,
	@depr_exp_acct_code 	smAccountCode, 
	@accum_depr_acct_code 	smAccountCode, 
	@account_ref_code 		smAccountReferenceCode 

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amdeprac.sp" + ", line " + STR( 68, 5 ) + " -- ENTRY: "

IF @debug_level	>= 5
	SELECT co_asset_id = @co_asset_id 

SELECT	@jul_apply_date = DATEDIFF(dd, "1/1/1980", @apply_date) + 722815



SELECT 	@depr_exp_acct_code 	= new_account_code,
	@account_ref_code	= account_reference_code
FROM	#amaccts
WHERE	co_asset_id 			= @co_asset_id
AND		account_type_id			= 5
AND		jul_apply_date			= @jul_apply_date
AND		co_trx_id				= 0
 
IF @@rowcount = 0 
BEGIN 
	EXEC 		amGetErrorMessage_sp 20020, "tmp/amdeprac.sp", 86, @error_message = @message out 
	IF @message IS NOT NULL RAISERROR 	20020 @message 
	RETURN 		20020 
END 




SELECT 	@accum_depr_acct_code 	= new_account_code	 
FROM	#amaccts
WHERE	co_asset_id 			= @co_asset_id
AND		account_type_id			= 1
AND		jul_apply_date			= @jul_apply_date
AND		co_trx_id				= 0

IF @@rowcount = 0 
BEGIN 
	EXEC 		amGetErrorMessage_sp 20020, "tmp/amdeprac.sp", 100, @error_message = @message out 
	IF @message IS NOT NULL RAISERROR 	20020 @message 
	RETURN 		20020 
END 

IF @debug_level >= 3
BEGIN
	SELECT 	depr_exp_acct_code 		= @depr_exp_acct_code,
		 	accum_depr_acct_code 	= @accum_depr_acct_code,
	 		account_reference_code	= @account_ref_code,	 
	                co_asset_id = @co_asset_id,
                        jul_apply_date = @jul_apply_date
	IF	@account_ref_code IS NULL
		SELECT "account reference code is null"

END

 
EXEC @return_status = amGetAccountID_sp 
						@company_id,
						@depr_exp_acct_code,
						@account_ref_code,
				 		@depr_exp_acct_id 		OUTPUT,
				 		@debug_level 

IF ( @return_status != 0 )
	RETURN @return_status 

EXEC @return_status = amGetAccountID_sp 
						@company_id,
				 		@accum_depr_acct_code,
				 		@account_ref_code,
						@accum_depr_acct_id 	OUTPUT,
				 		@debug_level 
 

IF ( @return_status != 0 )
	RETURN @return_status 

IF @debug_level >= 3
	SELECT 	depr_exp_acct_id 	= @depr_exp_acct_id,
			accum_depr_acct_id 	= @accum_depr_acct_id 
IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amdeprac.sp" + ", line " + STR( 141, 5 ) + " -- EXIT: "

RETURN 0 
GO
GRANT EXECUTE ON  [dbo].[amGetDeprAccounts_sp] TO [public]
GO
