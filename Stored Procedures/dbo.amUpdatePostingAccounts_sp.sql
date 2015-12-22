SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[amUpdatePostingAccounts_sp] 
(
	@account_from 		smAccountTypeID, 		
	@account_to 		smAccountTypeID, 		
	@debug_level		smDebugLevel	= 0		
)
AS 

 

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/ampstact.sp" + ", line " + STR( 57, 5 ) + " -- ENTRY: "

IF NOT EXISTS(SELECT account_type FROM amacctyp WHERE account_type = @account_from)
	RETURN 1

IF NOT EXISTS(SELECT account_type FROM amacctyp WHERE account_type = @account_to)
	RETURN 1


UPDATE a
SET	 a.account = b.account
FROM ampstact a,
	 ampstact b	
WHERE b.account_type = @account_from
AND a.account_type = @account_to
AND	 a.posting_code = b.posting_code	
AND a.company_id = b.company_id
AND b.account 	 <> ""
AND b.account 	 IS NOT NULL


IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/ampstact.sp" + ", line " + STR( 78, 5 ) + " -- EXIT: "
 
RETURN 0 
GO
GRANT EXECUTE ON  [dbo].[amUpdatePostingAccounts_sp] TO [public]
GO
