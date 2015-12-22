SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[amValidateActivityAccounts_sp] 
( 	
	@company_id				smCompanyID,			
	@co_trx_id 				smSurrogateKey,			



	@co_asset_id			smSurrogateKey,
	@apply_date_str			smISODate,				
    @debug_level			smDebugLevel	= 0		
) 
AS 

DECLARE 
	@error 					smErrorCode,
	@home_currency_code		smCurrencyCode,
   	@jul_apply_date			smJulianDate,
	@fixed_asset_account_id	smSurrogateKey,
	@imm_exp_account_id		smSurrogateKey

	
IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "amvlacac.cpp" + ", line " + STR( 77, 5 ) + " -- ENTRY: "



 
EXEC @error = amGetCurrencyCode_sp 
					@company_id,
					@home_currency_code OUTPUT 

IF @error <> 0
	RETURN @error




IF @apply_date_str IS NOT NULL
	SELECT 	@jul_apply_date		= DATEDIFF(dd, "1/1/1980", CONVERT(datetime, @apply_date_str)) + 722815
	



SELECT	
		@fixed_asset_account_id	= fixed_asset_account_id,
		@imm_exp_account_id		= imm_exp_account_id
FROM	amtrxhdr
WHERE	co_trx_id				= @co_trx_id

IF @@rowcount = 0
BEGIN
	SELECT 	
			@fixed_asset_account_id = 0,
			@imm_exp_account_id		= 0
END

IF @debug_level > 3
	SELECT 	fixed_asset_account_id	= @fixed_asset_account_id,
			imm_exp_account_id		= @imm_exp_account_id	



 











































CREATE TABLE #amaccts
(	
	co_asset_id				int,				
	co_trx_id				int,				


	jul_apply_date			int,				
	account_reference_code	varchar(32),		
	account_type_id			smallint,			
	original_account_code	char(32),			 
	new_account_code		char(32),			
	error_code				int,					
	org_id                  varchar (30)
)

























CREATE TABLE #amaccerr
(	
	error_code					int,			
	error_message				varchar(255)	
)





EXEC @error = amGetAllAssetAccounts_sp
				@co_asset_id,
				@debug_level
				
IF @error <> 0
BEGIN
	DROP TABLE #amaccts
	DROP TABLE #amaccerr
	RETURN @error
END





EXEC @error = amCreateAccounts_sp
				@company_id,
				@debug_level
IF @error <> 0
BEGIN
	DROP TABLE #amaccts
	DROP TABLE #amaccerr
	RETURN @error
END


 

IF @imm_exp_account_id <> 0
BEGIN

	IF EXISTS(SELECT * FROM #amaccts WHERE account_type_id = 9)
	BEGIN

		UPDATE #amaccts
		SET new_account_code		= a.account_code,
			original_account_code 	= a.account_code,
			account_reference_code  = a.account_reference_code
		FROM amacct a
		WHERE #amaccts.account_type_id 	= 9
		AND 	a.account_id 			= @imm_exp_account_id

		SELECT @error = @@error
		IF @error <> 0
		BEGIN
			DROP TABLE #amaccts
			DROP TABLE #amaccerr 
			RETURN @error
		END
	END	
	ELSE
	BEGIN
		
		INSERT INTO #amaccts
		(
			co_asset_id,
			co_trx_id,
			jul_apply_date,
			account_reference_code,
			account_type_id,
			original_account_code,
			new_account_code,
			error_code
		)
		SELECT
			@co_asset_id,
			0,
			@jul_apply_date,
			a.account_reference_code,
			9,
			a.account_code,
			a.account_code,
			0
		FROM amacct a
		WHERE a.account_id = @imm_exp_account_id

		SELECT @error = @@error
		IF @error <> 0
		BEGIN
			DROP TABLE #amaccts
			DROP TABLE #amaccerr 
			RETURN @error
		END


	END
END


IF @fixed_asset_account_id <> 0
BEGIN

	IF EXISTS(SELECT * FROM #amaccts WHERE account_type_id = 3)
	BEGIN

		UPDATE #amaccts
		SET new_account_code		= a.account_code,
			original_account_code 	= a.account_code,
			account_reference_code  = a.account_reference_code
		FROM amacct a
		WHERE #amaccts.account_type_id 	= 3
		AND   a.account_id 				= @fixed_asset_account_id


		SELECT @error = @@error
		IF @error <> 0
		BEGIN
			DROP TABLE #amaccts
			DROP TABLE #amaccerr
			RETURN @error
		END
	END
	ELSE
	BEGIN

		INSERT INTO #amaccts
		(
			co_asset_id,
			co_trx_id,
			jul_apply_date,
			account_reference_code,
			account_type_id,
			original_account_code,
			new_account_code,
			error_code
		)
		SELECT
			@co_asset_id,
			0,
			@jul_apply_date,
			a.account_reference_code,
			3,
			a.account_code,
			a.account_code,
			0
		FROM amacct a
		WHERE a.account_id 			= @fixed_asset_account_id

		SELECT @error = @@error
		IF @error <> 0
			BEGIN
			DROP TABLE #amaccts
			DROP TABLE #amaccerr

			RETURN @error
		END


	END	
END



UPDATE #amaccts
SET    jul_apply_date = @jul_apply_date




EXEC @error = amValidateAllAccounts_sp  
					@home_currency_code,
					@debug_level
					WITH RECOMPILE
IF @error <> 0
BEGIN
	DROP TABLE #amaccts
	DROP TABLE #amaccerr

	RETURN @error
END

 
SELECT 		account_type_id,
			new_account_code,
			account_reference_code,
			error_message 
FROM 		#amaccts a LEFT OUTER JOIN #amaccerr e
		ON a.error_code = e.error_code
ORDER BY 	account_type_id






 
DROP TABLE #amaccts
DROP TABLE #amaccerr

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "amvlacac.cpp" + ", line " + STR( 313, 5 ) + " -- EXIT: "

RETURN 0 
GO
GRANT EXECUTE ON  [dbo].[amValidateActivityAccounts_sp] TO [public]
GO
