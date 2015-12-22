SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[amastactAll_sp] 
( 	@company_id				smCompanyID,		
	@co_asset_id 			smSurrogateKey,		
	@debug_level			smDebugLevel = 0	
) 
AS 

DECLARE 
	@result					smErrorCode,
	@asset_ctrl_num			smControlNumber,
	@posting_code			smPostingCode,
	@account_reference_code	smAccountReferenceCode,
	@home_currency_code		smCurrencyCode

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "amgtacal.cpp" + ", line " + STR( 120, 5 ) + " -- ENTRY: "




 
EXEC @result = amGetCurrencyCode_sp 
					@company_id,
					@home_currency_code OUTPUT 

IF @result <> 0
	RETURN @result

 











































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

























CREATE TABLE #amaccerr
(	
	error_code					int,			
	error_message				varchar(255)	
)





EXEC @result = amGetAllAssetAccounts_sp
				@co_asset_id,
				@debug_level
				
IF @result <> 0
BEGIN
	DROP TABLE #amaccts
	DROP TABLE #amaccerr
	RETURN @result
END




EXEC @result = amCreateAccounts_sp
				@company_id,
				@debug_level
IF @result <> 0
BEGIN
	DROP TABLE #amaccts
	DROP TABLE #amaccerr
	RETURN @result
END





EXEC @result = amValidateAllAccounts_sp  
					@home_currency_code,
					@debug_level
					WITH RECOMPILE
IF @result <> 0
BEGIN
	DROP TABLE #amaccts
	DROP TABLE #amaccerr
	RETURN @result
END

 
SELECT 		account_type_id,
			c.account_type_name,
			original_account_code,
			new_account_code,
			error_message 
FROM 		#amaccts  a LEFT OUTER JOIN #amaccerr e ON 	a.error_code = e.error_code
		INNER JOIN amacctyp c  ON c.account_type = a.account_type_id
ORDER BY 	c.display_order







 
DROP TABLE #amaccts
DROP TABLE #amaccerr

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "amgtacal.cpp" + ", line " + STR( 199, 5 ) + " -- EXIT: "

RETURN 0 
GO
GRANT EXECUTE ON  [dbo].[amastactAll_sp] TO [public]
GO
