SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[amUpdateWithSuspenseAccts_sp] 
(
	@company_id						smCompanyID,
	@debug_level					smDebugLevel	= 0		
)
AS 

DECLARE 
	@result							smErrorCode,
	@message						smErrorLongDesc,
	@account_type_id				smAccountTypeID,
	@suspense_acct					smAccountCode
    


IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "amupwsus.cpp" + ", line " + STR( 70, 5 ) + " -- ENTRY: "








IF @debug_level >= 5
BEGIN
	SELECT 	*
	FROM 	#amaccts

	SELECT "Updating #amaccts with suspense accounts"

END

 
SELECT @account_type_id = MIN(account_type)  
FROM amacctyp

WHILE @account_type_id IS NOT NULL  
BEGIN 
	    
	IF @debug_level >= 5
		SELECT	* 
		FROM	#amaccts
		WHERE	account_type_id 	= @account_type_id
		AND		error_code			!= 0

	SELECT 	@suspense_acct = account
	FROM 	ampstact
	WHERE 	account_type	= @account_type_id
	AND 	posting_code	= "____SUSP"
	AND		company_id		= @company_id


	IF @@rowcount = 1
	BEGIN
	
		UPDATE 	#amaccts
		SET 	account_reference_code	= "",				
				new_account_code 		= dbo.IBAcctMask_fn( @suspense_acct , accts.org_id )
		FROM 	#amaccts accts
		WHERE	error_code 				<> 0
		AND		account_type_id 		= @account_type_id

		SELECT @result = @@error
		IF @result <> 0
			RETURN 	@result
	END

    SELECT 	@account_type_id = MIN(account_type)  
	FROM 	amacctyp
	WHERE 	account_type 	> @account_type_id
     					      
END 

IF @debug_level >= 5
	SELECT 	*
	FROM 	#amaccts

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "amupwsus.cpp" + ", line " + STR( 133, 5 ) + " -- EXIT: "

RETURN 0 
GO
GRANT EXECUTE ON  [dbo].[amUpdateWithSuspenseAccts_sp] TO [public]
GO
