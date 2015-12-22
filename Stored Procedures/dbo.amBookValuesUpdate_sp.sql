SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[amBookValuesUpdate_sp] 
(
 @co_asset_book_id smSurrogateKey, 		
 @co_trx_id smSurrogateKey, 		
 @account_type_id smAccountTypeID, 		
 @amount smMoneyZero, 			
 @trx_type smTrxType, 				
 @apply_date smApplyDate, 			
 @timestamp timestamp 		OUTPUT, 
	@debug_level		smDebugLevel	= 0		
)
AS 

DECLARE 
	@ts 		timestamp, 
	@rowcount 	smCounter,
	@error 		smErrorCode, 
	@message 	smErrorLongDesc

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/ambkvupd.sp" + ", line " + STR( 74, 5 ) + " -- ENTRY: "

IF @debug_level >= 3
	SELECT 	timestamp 			= @timestamp,
			co_asset_book_id 	= @co_asset_book_id,
			co_trx_id 			= @co_trx_id,
			account_type_id 	= @account_type_id

			
IF @amount = 0.0

	DELETE amvalues 
	WHERE co_trx_id = @co_trx_id 
	AND co_asset_book_id = @co_asset_book_id 
	AND account_type_id = @account_type_id 
	AND timestamp = @timestamp 
	
ELSE



	UPDATE amvalues 
	SET apply_date = @apply_date,
		 trx_type = @trx_type,
		 amount = @amount 
	WHERE co_trx_id = @co_trx_id 
	AND co_asset_book_id = @co_asset_book_id 
	AND account_type_id = @account_type_id 
	AND timestamp = @timestamp 

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

	IF @rowcount = 0 AND @amount <> 0.0
	BEGIN 
		
		INSERT INTO amvalues
		(
			co_trx_id, 
			co_asset_book_id, 
			account_type_id, 
			apply_date, 
			trx_type, 
			amount, 
			account_id, 
			posting_flag
		)
		VALUES
		(
			@co_trx_id, 
			@co_asset_book_id, 
			@account_type_id, 
			@apply_date, 
			@trx_type, 
			@amount, 
			0, 				
			0			
		)
		SELECT	@error = @@error
		IF @error <> 0
			RETURN @error
				 
	END 

	ELSE IF @ts <> @timestamp 
	BEGIN 
		EXEC 		amGetErrorMessage_sp 20003, "tmp/ambkvupd.sp", 170, amvalues, @error_message = @message OUT 
		IF @message IS NOT NULL RAISERROR 	20003 @message 
		RETURN 		20003 
	END 
END 

SELECT @timestamp = timestamp 
FROM amvalues 
WHERE co_trx_id = @co_trx_id 
AND co_asset_book_id = @co_asset_book_id 
AND account_type_id = @account_type_id 

IF @timestamp IS NULL 
	SELECT @timestamp = 0

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/ambkvupd.sp" + ", line " + STR( 185, 5 ) + " -- EXIT: "

RETURN 0 
GO
GRANT EXECUTE ON  [dbo].[amBookValuesUpdate_sp] TO [public]
GO
