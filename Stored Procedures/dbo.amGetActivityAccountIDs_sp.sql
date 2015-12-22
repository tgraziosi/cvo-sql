SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[amGetActivityAccountIDs_sp] 
(
 @company_id				smCompanyID,			
 @co_asset_id 		 	smSurrogateKey, 		
	@asset_account_id		smSurrogateKey OUTPUT,	
	@accum_depr_account_id	smSurrogateKey 	OUTPUT,	
	@fixed_asset_account_id	smSurrogateKey	OUTPUT,	
	@depr_exp_account_id	smSurrogateKey 	OUTPUT,	
	@adjustment_account_id	smSurrogateKey 	OUTPUT,	
	@imm_exp_account_id		smSurrogateKey	OUTPUT,	
	@debug_level			smDebugLevel	= 0		
)
AS 

DECLARE 
	@result	 		smErrorCode, 
	@account_reference_code smAccountReferenceCode, 
	@account_code 	smAccountCode 

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amgtacid.sp" + ", line " + STR( 67, 5 ) + " -- ENTRY: "


SELECT 	@account_code 			= new_account_code,
		@account_reference_code	= account_reference_code
FROM	#amaccts
WHERE	co_asset_id				= @co_asset_id
AND		account_type_id			= 0

EXEC @result = amGetAccountID_sp 	
					@company_id,
 	@account_code,
 @account_reference_code,
 @asset_account_id 	OUTPUT 
IF (@result <> 0)
 RETURN @result 

IF @debug_level >= 4
	SELECT 	account_code		= @account_code,
			asset_account_id 	= @asset_account_id 


SELECT 	@account_code 			= new_account_code,
		@account_reference_code	= account_reference_code
FROM	#amaccts
WHERE	co_asset_id				= @co_asset_id
AND		account_type_id			= 1

EXEC @result = amGetAccountID_sp 	
					@company_id,
 	@account_code,
 @account_reference_code,
 @accum_depr_account_id 	OUTPUT 
IF (@result <> 0)
 RETURN @result 

IF @debug_level >= 4
	SELECT 	account_code			= @account_code,
			accum_depr_account_id 	= @accum_depr_account_id 


SELECT 	@account_code 			= new_account_code,
		@account_reference_code	= account_reference_code
FROM	#amaccts
WHERE	co_asset_id				= @co_asset_id
AND		account_type_id			= 3

EXEC @result = amGetAccountID_sp 	
					@company_id,
 	@account_code,
 @account_reference_code,
 @fixed_asset_account_id 	OUTPUT 
IF (@result <> 0)
 RETURN @result 

IF @debug_level >= 4
	SELECT 	account_code			= @account_code,
			fixed_asset_account_id 	= @fixed_asset_account_id 


SELECT 	@account_code 			= new_account_code,
		@account_reference_code	= account_reference_code
FROM	#amaccts
WHERE	co_asset_id				= @co_asset_id
AND		account_type_id			= 5

EXEC @result = amGetAccountID_sp 	
					@company_id,
 	@account_code,
 @account_reference_code,
 @depr_exp_account_id 	OUTPUT 
IF (@result <> 0)
 RETURN @result 

IF @debug_level >= 4
	SELECT 	account_code		= @account_code,
			depr_exp_account_id = @depr_exp_account_id 


SELECT 	@account_code 			= new_account_code,
		@account_reference_code	= account_reference_code
FROM	#amaccts
WHERE	co_asset_id				= @co_asset_id
AND		account_type_id			= 7

EXEC @result = amGetAccountID_sp 	
					@company_id,
 	@account_code,
 @account_reference_code,
 @adjustment_account_id 	OUTPUT 
IF (@result <> 0)
 RETURN @result 

IF @debug_level >= 2
	SELECT 	account_code			= @account_code,
			adjustment_account_id 	= @adjustment_account_id 


SELECT 	@account_code 			= new_account_code,
		@account_reference_code	= account_reference_code
FROM	#amaccts
WHERE	co_asset_id				= @co_asset_id
AND		account_type_id			= 9

EXEC @result = amGetAccountID_sp 	
					@company_id,
 	@account_code,
 @account_reference_code,
 @imm_exp_account_id 	OUTPUT 
IF (@result <> 0)
 RETURN @result 

IF @debug_level >= 2
	SELECT 	account_code			= @account_code,
			imm_exp_account_id 		= @imm_exp_account_id 

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amgtacid.sp" + ", line " + STR( 195, 5 ) + " -- EXIT: "

RETURN 0 
GO
GRANT EXECUTE ON  [dbo].[amGetActivityAccountIDs_sp] TO [public]
GO
