SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[amCreateMissingActivity_sp] 
(
 	@company_id				smCompanyID,			
 	@co_asset_id			smSurrogateKey,			
 	@co_asset_book_id 		smSurrogateKey, 		
 	@apply_date				smApplyDate,			
 	@trx_type				smTrxType,				
 	@amount					smMoneyZero,			
	@new_cost				smMoneyZero,			
	@new_accum_depr			smMoneyZero,	 		
	@asset_account_id		smSurrogateKey 	= 0,	
	@accum_depr_account_id	smSurrogateKey 	= 0,	
	@depr_exp_account_id	smSurrogateKey	= 0,	
	@adjustment_account_id	smSurrogateKey 	= 0,	
	@debug_level			smDebugLevel	= 0		

)
AS 

DECLARE 
	@result	 			smErrorCode, 		
	@apply_date_str			smISODate,			
	@trx_ctrl_num			smControlNumber,	
	@co_trx_id				smSurrogateKey,		
	@account_id				smSurrogateKey,		
	@account_type_id		smAccountTypeID,	
	@account_amount			smMoneyZero,		
	@str_text				smStringText,		
	@rounding_factor		float,
	@curr_precision			smallint,
	@home_currency_code		smCurrencyCode,
	@account_type_credit smAccountTypeID,
	@account_type_debit		smAccountTypeID
	 

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amcrmsac.sp" + ", line " + STR( 96, 5 ) + " -- ENTRY: "

SELECT	@co_trx_id = NULL


EXEC @result = amGetCurrencyCode_sp 
				@company_id, 
				@home_currency_code OUTPUT 
IF @result <> 0
	RETURN @result


EXEC @result = amGetCurrencyPrecision_sp 
		@curr_precision OUTPUT,	
		@rounding_factor OUTPUT 	

IF @result <> 0
	RETURN @result

IF @trx_type = 50
BEGIN

	
	EXEC @result = amGetString_sp
					22,
					@str_text OUTPUT

	IF @result <> 0
		RETURN @result
	
	SELECT @apply_date_str	= CONVERT(char(8), @apply_date, 112)
	SELECT @trx_ctrl_num	= RTRIM(@str_text) + @apply_date_str

	
	SELECT 	@co_trx_id 		= co_trx_id
	FROM	amtrxhdr
	WHERE	apply_date		= @apply_date
	AND		trx_ctrl_num	= @trx_ctrl_num
	AND 	company_id		= @company_id

	IF @co_trx_id IS NULL
	BEGIN
		
		EXEC @result = amNextKey_sp 	7, 
	 	@co_trx_id OUTPUT 

		IF @result <> 0
		 RETURN @result 

		
		IF @trx_type = 50
		BEGIN
			INSERT INTO amtrxhdr 
			(
	 	company_id, 
	 	trx_ctrl_num, 
			 	journal_ctrl_num,
	 	co_trx_id, 
	 	trx_type, 
	 	trx_subtype, 
	 	batch_ctrl_num,
	 	last_modified_date, 
	 	modified_by, 
	 	apply_date, 
	 	posting_flag, 
	 	date_posted,
	 	hold_flag, 
	 	trx_description, 
	 	doc_reference, 
	 	note_id, 
	 	user_field_id, 
	 	intercompany_flag, 
	 	source_company_id, 
	 	home_currency_code, 
	 	total_paid, 
	 	total_received, 
	 	linked_trx, 
	 	revaluation_rate, 
	 	process_id,
				trx_source,
				co_asset_id,
				fixed_asset_account_id,
				imm_exp_account_id,
				change_in_quantity
			)

			VALUES 
			( 
				@company_id,
				@trx_ctrl_num,
				"",
				@co_trx_id,
				50,
				0,
				"",
				GETDATE(),
				1,				
				@apply_date,
				1,				
				GETDATE(),		
				0,
				"",				
				"",				
				0,
				0,
				0,
				1,
				@home_currency_code,
				0.0,
				0.0,
				0,
				0.0,
				0,
				3,
				0,
				0,
				0,
				0
				 
			)
			
			SELECT @result = @@error
			IF @result <> 0
				RETURN @result

		END
	END 
	
	
 INSERT #am_new_values 
 ( 
 	co_trx_id,
 	co_asset_book_id,
 	account_type_id,
 	apply_date, 
 	trx_type, 
 	amount, 
 	account_id
 )

 VALUES 
 ( 
 	@co_trx_id,
 	@co_asset_book_id,
 	1,
 	@apply_date,
 	50, 
 	@amount, 
 	@accum_depr_account_id
 )
 SELECT @result = @@error
 IF @result <> 0
 	RETURN @result
	 
 INSERT #am_new_values 
 ( 
 	co_trx_id,
 	co_asset_book_id,
 	account_type_id,
 	apply_date, 
 	trx_type, 
 	amount, 
 	account_id
 )

 VALUES 
 ( 
 	@co_trx_id,
 	@co_asset_book_id,
 	5,
 	@apply_date,
 	50, 
 	-@amount, 
 	@depr_exp_account_id
 )
 SELECT @result = @@error
 IF @result <> 0
 	RETURN @result
	 	
END

ELSE 
BEGIN
	
	
	SET ROWCOUNT 1
	SELECT 	@co_trx_id 			= co_trx_id,
			@trx_ctrl_num		= trx_ctrl_num
	FROM	#am_new_activities	
	WHERE	co_asset_id 		= @co_asset_id
	AND		apply_date			= @apply_date
	AND		trx_type			= @trx_type
	SET ROWCOUNT 0

	IF @co_trx_id IS NULL
	BEGIN
		EXEC @result = amNextKey_sp 	7, 
	 	@co_trx_id OUTPUT 
		IF @result <> 0
		 RETURN @result 

		EXEC @result = amNextControlNumber_sp
						@company_id,
						5,
						@trx_ctrl_num OUTPUT,
						@debug_level

		IF @result <> 0
		 	RETURN @result 
	END
	
	
	INSERT #am_new_activities 
	(
			co_trx_id,
	 trx_ctrl_num,
	 co_asset_id,
	 co_asset_book_id, 
	 apply_date, 
	 trx_type, 
	 effective_date, 
	 revised_cost, 
	 revised_accum_depr,
	 delta_cost, 
	 delta_accum_depr 
	)

	VALUES 
	( 
			@co_trx_id,
	 	@trx_ctrl_num,
	 	@co_asset_id,
	 	@co_asset_book_id,
	 	@apply_date,		
	 	@trx_type,
	 @apply_date, 	 
	 @new_cost, 		 
	 @new_accum_depr,  
	 @amount, 		 
	 0.0 		 
	)
	
	SELECT @result = @@error
	IF @result <> 0
		RETURN @result
	 

	
	
	IF (ABS((@amount)-(0.0)) > 0.0000001)
	BEGIN
		IF (@amount > 0.0)
		BEGIN 

				
				SELECT 	@account_type_credit = account_type			
				FROM	amtrxact
				WHERE	trx_type			= @trx_type
				AND		credit_positive		= 1

				SELECT 	@account_type_debit = account_type			
				FROM	amtrxact
				WHERE	trx_type			= @trx_type
				AND		debit_positive		= 1

		END
		ELSE
		BEGIN


				
				SELECT 	@account_type_credit = account_type			
				FROM	amtrxact
				WHERE	trx_type			= @trx_type
				AND		credit_negative		= 1

				SELECT 	@account_type_debit = account_type			
				FROM	amtrxact
				WHERE	trx_type			= @trx_type
				AND		debit_negative		= 1
 
		 END

		 IF @account_type_debit IS NOT NULL
		 BEGIN
		 	INSERT #am_new_values 
			 ( 
		 		co_trx_id,
		 	co_asset_book_id,
		 	account_type_id,
	 	 	apply_date, 
	 	 	trx_type, 
	 		amount, 
		 	account_id
		 )
			
		 	VALUES 
			 ( 
			 	@co_trx_id,
	 	 	@co_asset_book_id,
	 		@account_type_debit,
		 	@apply_date,
	 	 	@trx_type, 
	 	 	@amount,
	 		@asset_account_id
 
		 )
		 
		 	SELECT @result = @@error
			 IF @result <> 0
			 	RETURN @result
		 END

		 IF @account_type_credit IS NOT NULL
		 BEGIN

				INSERT #am_new_values 
			 ( 
			 	co_trx_id,
	 	 	co_asset_book_id,
	 	 	account_type_id,
	 		apply_date, 
		 	trx_type, 
		 	amount, 
	 	 	account_id
	 	)

			 VALUES 
			 ( 
			 	@co_trx_id,
	 	 	@co_asset_book_id,
	 		@account_type_credit,
		 	@apply_date,
		 	@trx_type, 
	 	 	-@amount, 
	 	 	@accum_depr_account_id
		 )
		 
			 SELECT @result = @@error
			 IF @result <> 0
		 		RETURN @result

		 END

	END
	 	
	 
	 					 
	
END

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amcrmsac.sp" + ", line " + STR( 478, 5 ) + " -- EXIT: "

RETURN 0 
GO
GRANT EXECUTE ON  [dbo].[amCreateMissingActivity_sp] TO [public]
GO
