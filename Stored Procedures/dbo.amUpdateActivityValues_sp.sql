SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[amUpdateActivityValues_sp] 
(
 @co_asset_book_id smSurrogateKey, 		
 @co_trx_id smSurrogateKey, 		
 @trx_type smTrxType, 				
 @apply_date smApplyDate, 			
 @account_type_1		smAccountTypeID = NULL,	
 @amount_1 smMoneyZero		= 0.0, 	
 @timestamp_1 timestamp		= NULL, 
 @account_type_2		smAccountTypeID	= NULL,	
 @amount_2 smMoneyZero		= 0.0, 	
 @timestamp_2 timestamp		= NULL, 
 @account_type_3		smAccountTypeID	= NULL,	
 @amount_3 smMoneyZero		= 0.0, 	
 @timestamp_3 timestamp		= NULL, 
 @account_type_4		smAccountTypeID	= NULL,	
 @amount_4 smMoneyZero		= 0.0, 	
 @timestamp_4 timestamp		= NULL, 
 @account_type_5		smAccountTypeID	= NULL,	
 @amount_5 smMoneyZero		= 0.0, 	
 @timestamp_5 timestamp		= NULL, 
 @account_type_6		smAccountTypeID	= NULL,	
 @amount_6 smMoneyZero		= 0.0, 	
 @timestamp_6 timestamp	 	= NULL,	
	@debug_level		smDebugLevel	= 0		
)
AS 

DECLARE 
	@result 			smErrorCode 

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amupactv.sp" + ", line " + STR( 77, 5 ) + " -- ENTRY: "

IF @debug_level >= 3
	SELECT 	co_asset_book_id 	= @co_asset_book_id,
			co_trx_id 			= @co_trx_id

BEGIN TRANSACTION

	IF @account_type_1 IS NOT NULL
	BEGIN
		EXEC @result = amBookValuesUpdate_sp
						@co_asset_book_id,
						@co_trx_id,
						@account_type_1,
						@amount_1,
						@trx_type,
						@apply_date,
						@timestamp_1 OUTPUT,
						@debug_level

		IF @result <> 0
		BEGIN
			ROLLBACK 	TRANSACTION
			RETURN		@result
		END
	END
			
	IF @account_type_2 IS NOT NULL
	BEGIN
		EXEC @result = amBookValuesUpdate_sp
						@co_asset_book_id,
						@co_trx_id,
						@account_type_2,
						@amount_2,
						@trx_type,
						@apply_date,
						@timestamp_2 OUTPUT,
						@debug_level


		IF @result <> 0
		BEGIN
			ROLLBACK 	TRANSACTION
			RETURN		@result
		END
	END
			
	IF @account_type_3 IS NOT NULL
	BEGIN
		EXEC @result = amBookValuesUpdate_sp
						@co_asset_book_id,
						@co_trx_id,
						@account_type_3,
						@amount_3,
						@trx_type,
						@apply_date,
						@timestamp_3 OUTPUT,
						@debug_level


		IF @result <> 0
		BEGIN
			ROLLBACK 	TRANSACTION
			RETURN		@result
		END
	END
			
	IF @account_type_4 IS NOT NULL
	BEGIN
		EXEC @result = amBookValuesUpdate_sp
						@co_asset_book_id,
						@co_trx_id,
						@account_type_4,
						@amount_4,
						@trx_type,
						@apply_date,
						@timestamp_4 OUTPUT,
						@debug_level


		IF @result <> 0
		BEGIN
			ROLLBACK 	TRANSACTION
			RETURN		@result
		END
	END
			
	IF @account_type_5 IS NOT NULL
	BEGIN
		EXEC @result = amBookValuesUpdate_sp
						@co_asset_book_id,
						@co_trx_id,
						@account_type_5,
						@amount_5,
						@trx_type,
						@apply_date,
						@timestamp_5 OUTPUT,
						@debug_level


		IF @result <> 0
		BEGIN
			ROLLBACK 	TRANSACTION
			RETURN		@result
		END
	END
			
	IF @account_type_6 IS NOT NULL
	BEGIN
		EXEC @result = amBookValuesUpdate_sp
						@co_asset_book_id,
						@co_trx_id,
						@account_type_6,
						@amount_6,
						@trx_type,
						@apply_date,
						@timestamp_6 OUTPUT,
						@debug_level


		IF @result <> 0
		BEGIN
			ROLLBACK 	TRANSACTION
			RETURN		@result
		END
	END
			
COMMIT TRANSACTION

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amupactv.sp" + ", line " + STR( 206, 5 ) + " -- EXIT: "

RETURN 0 
GO
GRANT EXECUTE ON  [dbo].[amUpdateActivityValues_sp] TO [public]
GO
