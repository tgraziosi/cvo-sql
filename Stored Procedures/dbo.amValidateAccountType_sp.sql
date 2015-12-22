SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[amValidateAccountType_sp] 
(	
 	@account_code			smAccountCode,			
	@income_account			smLogicalTrue, 
	@debug_level			smDebugLevel	= 0		
)
AS 

DECLARE 
	@account_type			int			
		

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amvldacttp.sp" + ", line " + STR( 57, 5 ) + " -- ENTRY: "


IF @debug_level >= 3
	SELECT 	account_code	= @account_code,
			income_account 	= @income_account
	 

SELECT 	@account_type = account_type
FROM 	glchart
WHERE	account_code	= @account_code

IF @debug_level >= 3
		SELECT @account_type

IF @account_type IS NULL
BEGIN
	IF @debug_level >= 3
		SELECT "NULL"

	RETURN 1
END


IF (@income_account = 1) 
BEGIN
 	IF (@account_type < 400)
	BEGIN
		IF @debug_level >= 3 
			SELECT "wrong account-type"
		RETURN 1 
	END
	
END
ELSE
BEGIN
	IF (@account_type > 399)
	BEGIN
		IF @debug_level >= 3 
			SELECT "wrong account-type"
		RETURN 1 
	END

END

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amvldacttp.sp" + ", line " + STR( 104, 5 ) + " -- EXIT: "

RETURN 0 
GO
GRANT EXECUTE ON  [dbo].[amValidateAccountType_sp] TO [public]
GO
