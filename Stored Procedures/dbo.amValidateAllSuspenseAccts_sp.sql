SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[amValidateAllSuspenseAccts_sp] 
(	
	@company_id		smCompanyID,			
	@from_date		smApplyDate	= NULL,		
	@to_date		smApplyDate = NULL,		
	@debug_level	smDebugLevel	= 0		
)
AS 

DECLARE 
	@message						smErrorLongDesc,
	@result							smErrorCode,
	@home_currency_code				smCurrencyCode,
	@account_type_id				smAccountTypeID,
	@suspense_acct					smAccountCode
 

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amvldsus.sp" + ", line " + STR( 94, 5 ) + " -- ENTRY: "


 
EXEC @result = amGetCurrencyCode_sp 
					@company_id,
					@home_currency_code OUTPUT 

IF @result <> 0
	RETURN @result


IF @from_date IS NULL
	SELECT	@from_date	= GETDATE()

IF @to_date IS NULL
	SELECT	@to_date	= GETDATE()
	
 

 
SELECT 	@account_type_id = MIN(account_type)
FROM 	ampstact
WHERE 	posting_code 	= "____SUSP"
AND 	company_id 		= @company_id

WHILE NOT @account_type_id IS NULL
BEGIN 
 
	SELECT 	@suspense_acct = account
	FROM 	ampstact
	WHERE 	posting_code 	= "____SUSP"
	AND 	company_id 	= @company_id
	AND 	account_type 	= @account_type_id 

		
	EXEC @result = amValidateAnAccount_sp
						@home_currency_code,
						@suspense_acct,
						@from_date,
						@to_date
					
	IF @result <> 0
		RETURN @result

 SELECT 	@account_type_id = MIN(account_type)
 	FROM 	ampstact
 	WHERE 	posting_code 	= "____SUSP"
	AND 	company_id 		= @company_id
	AND 	account_type 	> @account_type_id
 					 
END 
	
IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amvldsus.sp" + ", line " + STR( 151, 5 ) + " -- EXIT: "

RETURN 0 
GO
GRANT EXECUTE ON  [dbo].[amValidateAllSuspenseAccts_sp] TO [public]
GO
