SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[amBookValuesDelete_sp] 
(
 @timestamp timestamp, 			
 @co_asset_book_id smSurrogateKey, 	
 @co_trx_id smSurrogateKey, 	
 @account_type_id smAccountTypeID, 	
	@debug_level		smDebugLevel	= 0	
)
AS 

DECLARE 
	@ts 		timestamp, 
	@rowcount 	smCounter,
	@error 		smErrorCode, 
	@message 	smErrorLongDesc

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/ambkvdel.sp" + ", line " + STR( 57, 5 ) + " -- ENTRY: "

IF @debug_level >= 3
	SELECT 	timestamp 			= @timestamp,
			co_asset_book_id 	= @co_asset_book_id,
			co_trx_id 			= @co_trx_id,
			account_type_id 	= @account_type_id 	

DELETE
FROM	amvalues 
WHERE 	co_trx_id = @co_trx_id 
AND 	co_asset_book_id = @co_asset_book_id 
AND 	account_type_id = @account_type_id 
AND 	timestamp = @timestamp 

SELECT @error = @@error, 
 @rowcount = @@rowcount 

IF @debug_level >= 3
	SELECT 	error_code = @error,
			num_rows = @rowcount 
		
IF @error <> 0  
	RETURN @error 

IF ( @rowcount = 0 )  
BEGIN 
	 
	SELECT @ts 				= timestamp 
	FROM amvalues 
	WHERE co_trx_id = @co_trx_id 
 AND co_asset_book_id	= @co_asset_book_id 
	AND account_type_id = @account_type_id 

	SELECT @error = @@error, 
	 @rowcount = @@rowcount 

	IF @error <> 0  
		RETURN @error 

	IF	@rowcount > 0
	AND	@ts <> @timestamp 
	BEGIN 
		EXEC 		amGetErrorMessage_sp 20001, "tmp/ambkvdel.sp", 100, amvalues, @error_message = @message OUT 
		IF @message IS NOT NULL RAISERROR 	20001 @message 
		RETURN 		20001 
	END 
END 

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/ambkvdel.sp" + ", line " + STR( 106, 5 ) + " -- EXIT: "

RETURN 0 
GO
GRANT EXECUTE ON  [dbo].[amBookValuesDelete_sp] TO [public]
GO
