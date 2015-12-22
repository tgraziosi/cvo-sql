SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[imUpdateAllAccountIDs_sp] 
(
	@co_asset_id 	smSurrogateKey, 		
	@debug_level		smDebugLevel	= 0		
)
AS 

DECLARE 
	@result 	 			smErrorCode, 
	@account_id 				smSurrogateKey, 
	@account_reference_code smAccountReferenceCode, 
	@account_type_id 		smAccountTypeID, 
	@account_code 		smAccountCode,
	@company_id 				smCompanyID 


IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/imupalac.sp" + ", line " + STR( 66, 5 ) + " -- ENTRY: "


 


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


SELECT 	@company_id = company_id
FROM 	amasset
WHERE 	co_asset_id = @co_asset_id


EXEC @result = amCreateAccounts_sp
				@company_id,
				@debug_level
IF @result <> 0
BEGIN
	DROP TABLE #amaccts
	DROP TABLE #amaccerr
	RETURN @result
END


IF @debug_level >= 4
	SELECT * FROM #amaccts
	
 
SELECT @account_type_id = MIN(account_type)  
FROM amacctyp


WHILE @account_type_id IS NOT NULL 
BEGIN 
 
	 
 SELECT 	@account_code 			= new_account_code,
			@account_reference_code = account_reference_code
 FROM	#amaccts
 	WHERE	account_type_id	= @account_type_id
 
	IF @debug_level >= 4
 		SELECT account_code = @account_code 

 EXEC @result = amGetAccountID_sp 	
						@company_id,
 	@account_code,
 @account_reference_code,
 @account_id 			OUTPUT 

	IF @result <> 0 
	BEGIN 
		DROP TABLE #amaccts
		DROP TABLE #amaccerr
	 RETURN @result 
	END 
	
	IF @debug_level >= 4
 		SELECT account_id = @account_id 

	

  
 UPDATE 	amvalues 
	SET 	account_id 			= @account_id 
	FROM 	amvalues 	v,
			amastbk		ab	
	WHERE 	v.account_type_id 	= @account_type_id 
	AND		v.co_asset_book_id	= ab.co_asset_book_id
	AND		ab.co_asset_id		= @co_asset_id

 SELECT @result = @@error 
	IF @result <> 0
	BEGIN
		DROP TABLE #amaccts
		DROP TABLE #amaccerr
		RETURN @result 
	END

 UPDATE 	#am_new_values 
	SET 	account_id 			= @account_id 
	FROM 	#am_new_values 	v,
			amastbk			ab	
	WHERE 	v.account_type_id 	= @account_type_id 
	AND		v.co_asset_book_id	= ab.co_asset_book_id
	AND		ab.co_asset_id		= @co_asset_id

 SELECT @result = @@error 
	IF @result <> 0
	BEGIN
		DROP TABLE #amaccts
		DROP TABLE #amaccerr 
		RETURN @result 
	END

 
 SELECT 	@account_type_id = MIN(account_type)
	FROM 	amacctyp
	WHERE	account_type > @account_type_id
END 

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/imupalac.sp" + ", line " + STR( 196, 5 ) + " -- EXIT: "
DROP TABLE #amaccts
DROP TABLE #amaccerr


RETURN 0 
GO
GRANT EXECUTE ON  [dbo].[imUpdateAllAccountIDs_sp] TO [public]
GO
