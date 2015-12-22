SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[amGetAssetAccounts_sp] 
( 	
	@company_id		smCompanyID,		
	@co_asset_id 	smSurrogateKey,		
	@debug_level	smDebugLevel = 0	
) 
AS 

DECLARE 
	@result			smErrorCode

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amastac.sp" + ", line " + STR( 59, 5 ) + " -- ENTRY: "

 


CREATE TABLE #amaccts
(	
	co_asset_id				int,				
	co_trx_id				int,				
	jul_apply_date			int,				
	account_reference_code	varchar(32),		
	account_type_id			smallint,			
	original_account_code	char(32),			 
	new_account_code		char(32),			
	error_code				int					
)





EXEC @result = amGetAllAssetAccounts_sp
				@co_asset_id,
				@debug_level
				
IF @result <> 0
BEGIN
	DROP TABLE #amaccts
	RETURN @result
END


EXEC @result = amCreateAccounts_sp
				@company_id,
				@debug_level
IF @result <> 0
BEGIN
	DROP TABLE #amaccts
	RETURN @result
END

 
SELECT 		account_type_id,
			account_code 	= new_account_code
FROM 		#amaccts 
ORDER BY 	account_type_id

 
DROP TABLE #amaccts

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amastac.sp" + ", line " + STR( 102, 5 ) + " -- EXIT: "

RETURN 0 
GO
GRANT EXECUTE ON  [dbo].[amGetAssetAccounts_sp] TO [public]
GO
