SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE [dbo].[amGetAccountID_sp] 
(
 	@company_id 			smSurrogateKey, 		
 	@account_code 			smAccountCode, 			
 	@account_reference_code smAccountReferenceCode, 
 	@account_id 			smSurrogateKey OUTPUT, 	
	@debug_level			smDebugLevel	= 0		
)
AS 


DECLARE 
	@error 		smErrorCode,
	@rowcount 	smCounter

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amacctid.sp" + ", line " + STR( 71, 5 ) + " -- ENTRY: " 

SELECT @account_reference_code = ISNULL(RTRIM(@account_reference_code),"")

IF @debug_level >= 5
BEGIN
	SELECT 	account_code 			= @account_code 
	SELECT 	account_reference_code 	= @account_reference_code 
END

SELECT @account_id = NULL 

SELECT 	@account_id				 = account_id 
FROM 	amacct 
WHERE 	company_id 	 			= @company_id 
AND 	account_code 			= @account_code 
AND 	account_reference_code 	= @account_reference_code 

IF ( @@rowcount = 0 ) 
BEGIN 
	
	EXEC @error = amNextKey_sp 	8,
					 				@account_id OUTPUT 

	IF @error > 0 
	BEGIN 
		IF @debug_level >= 5
			SELECT "amNextKey_sp failed" 
		RETURN @error 
		
	END 
	IF ( @account_id != 0 )
	BEGIN 
 		INSERT amacct 	 			 	 
		(
				timestamp,
				company_id,
		 	 	account_code, 
				account_reference_code, 
				account_id 
		) 
		VALUES 	
		( 
				NULL,
				@company_id,
			 	@account_code,
			 @account_reference_code,
			 @account_id
		)

		SELECT @error = @@error 
		IF 	@error 	<> 0
		BEGIN 
			IF @debug_level >= 5
				SELECT "Insert into amacct failed" 
 
			RETURN @error 
		
		END 
 END 
END 
		
IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amacctid.sp" + ", line " + STR( 133, 5 ) + " -- EXIT: "

RETURN 0 
GO
GRANT EXECUTE ON  [dbo].[amGetAccountID_sp] TO [public]
GO
