SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[amUpdateActivityAccountIDs_sp] 
(
 @company_id				smCompanyID,			
 @co_asset_id 		smSurrogateKey, 		
	@debug_level			smDebugLevel	= 0		
)
AS 


DECLARE 
	@result 	 	smErrorCode, 			
	@account_reference_code	smAccountReferenceCode,	 
	@account_type_id 	smAccountTypeID, 		
	@account_code 	smAccountCode, 			
	@account_id 	smSurrogateKey,			
	@apply_date				smApplyDate,			
	@jul_apply_date			smJulianDate,			
	@co_trx_id				smSurrogateKey			

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amupacct.sp" + ", line " + STR( 69, 5 ) + " -- ENTRY: "

IF @debug_level >= 3
	SELECT	co_asset_id	= @co_asset_id


SET ROWCOUNT 1
SELECT	@account_reference_code = account_reference_code
FROM	#amaccts
WHERE	co_asset_id				= @co_asset_id
SET ROWCOUNT 0

SELECT	@jul_apply_date			= MIN(jul_apply_date)
FROM	#amaccts
WHERE	co_asset_id				= @co_asset_id


WHILE @jul_apply_date IS NOT NULL
BEGIN

	SELECT	@apply_date	= DATEADD(dd, @jul_apply_date - 722815, "1/1/1980")

	IF @debug_level >= 2
		SELECT	jul_apply_date	= @jul_apply_date,
				apply_date		= @apply_date

	 
	SELECT @account_type_id = MIN(account_type)
	FROM amacctyp
	 
	WHILE @account_type_id IS NOT NULL  
	BEGIN 
	 
	 SELECT	@account_code	= NULL
	 
	 SELECT 	@account_code 	= new_account_code
	 FROM	#amaccts
	 	WHERE	co_asset_id		= @co_asset_id
		AND		jul_apply_date	= @jul_apply_date
		AND		account_type_id	= @account_type_id
		AND		co_trx_id		= 0

		IF @debug_level >= 2
		 SELECT 	account_type_id	= @account_type_id,
		 		account_code 	= @account_code
	
		
		IF @account_code IS NOT NULL
		BEGIN

			IF @debug_level >= 2
				SELECT account_code = @account_code 
		
		 EXEC @result = amGetAccountID_sp 	
								@company_id,
		 	@account_code,
		 @account_reference_code,
		 @account_id OUTPUT 
			IF (@result <> 0)
			 RETURN @result 

			IF @debug_level >= 2
			BEGIN
				SELECT 	account_id = @account_id 
			END

		  
		 UPDATE 	amvalues 
			SET 	account_id 			= @account_id 
			FROM 	amvalues 	v,
					amastbk		ab
			WHERE 	ab.co_asset_book_id = v.co_asset_book_id 
			AND 	ab.co_asset_id		= @co_asset_id
			AND		@jul_apply_date		= DATEDIFF(dd, "1/1/1980", v.apply_date) + 722815
			AND 	v.account_type_id 	= @account_type_id 
			AND		v.posting_flag 		= 100
			AND		v.trx_type			!= 50

		 SELECT @result = @@error 
			IF (@result <> 0)
				RETURN @result 
		END

		
		IF @account_type_id IN (3, 9)
		BEGIN
		 SELECT @co_trx_id = NULL
		 
		 SELECT	@co_trx_id		= MIN(co_trx_id)
		 FROM	#amaccts
		 	WHERE	co_asset_id		= @co_asset_id
			AND		jul_apply_date	= @jul_apply_date
			AND		account_type_id	= @account_type_id
			AND		co_trx_id		> 0
			
			WHILE	@co_trx_id IS NOT NULL
			BEGIN
			 SELECT	@account_code	= NULL
			 
			 SELECT 	@account_code 			= new_account_code,
						@account_reference_code = account_reference_code
			 FROM	#amaccts
			 	WHERE	co_asset_id				= @co_asset_id
				AND		jul_apply_date			= @jul_apply_date
				AND		account_type_id			= @account_type_id
				AND		co_trx_id				= @co_trx_id
			
				
				IF @account_code IS NOT NULL
				BEGIN

				 EXEC @result = amGetAccountID_sp 	
										@company_id,
				 	@account_code,
				 @account_reference_code,
				 @account_id OUTPUT 
					IF (@result <> 0)
					 RETURN @result 

					IF @debug_level >= 2
					BEGIN
					 SELECT 	co_asset_id				= @co_asset_id,
					 			co_trx_id				= @co_trx_id,
					 			apply_date				= @apply_date,
					 			account_type_id			= @account_type_id,
					 		account_code 			= @account_code,
								account_reference_code 	= @account_reference_code,
						 		account_id 				= @account_id 

						SELECT	trx_type, posting_flag
						FROM	amvalues
						WHERE 	co_trx_id 		= @co_trx_id
						AND		account_type_id = @account_type_id
						AND		apply_date		= @apply_date
				 END
				 
				  
				 UPDATE 	amvalues 
					SET 	account_id 			= @account_id 
					FROM 	amvalues 	v,
							amastbk		ab
					WHERE 	ab.co_asset_book_id = v.co_asset_book_id 
					AND 	ab.co_asset_id		= @co_asset_id
					AND		v.co_trx_id			= @co_trx_id
					AND		@jul_apply_date		= DATEDIFF(dd, "1/1/1980", v.apply_date) + 722815
					AND 	v.account_type_id 	= @account_type_id 
					AND		v.posting_flag 		IN (100, -103, -1)
					AND		v.trx_type			!= 50

				 SELECT @result = @@error 
					IF (@result <> 0)
						RETURN @result 
				END
				
			 SELECT	@co_trx_id		= MIN(co_trx_id)
			 FROM	#amaccts
			 	WHERE	co_asset_id		= @co_asset_id
				AND		jul_apply_date	= @jul_apply_date
				AND		account_type_id	= @account_type_id
				AND		co_trx_id		> @co_trx_id
			
				
			END
	 END

	 
	 SELECT @account_type_id = MIN(account_type)
		FROM 	amacctyp
		WHERE 	account_type > @account_type_id
 
	 					 
	END
			
	
	SELECT	@jul_apply_date			= MIN(jul_apply_date)
	FROM	#amaccts
	WHERE	co_asset_id				= @co_asset_id
	AND		jul_apply_date			> @jul_apply_date

END

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amupacct.sp" + ", line " + STR( 290, 5 ) + " -- EXIT: "

RETURN 0 
GO
GRANT EXECUTE ON  [dbo].[amUpdateActivityAccountIDs_sp] TO [public]
GO
