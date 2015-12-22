SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[amActivityNew_sp] 
(
 @company_id				smCompanyID,					
 @co_asset_id			smSurrogateKey,					
 @apply_date 	smApplyDate, 					
 @trx_type 	smTrxType, 						
 @cost					smMoneyZero,					
 @user_id 	smUserID,
 @org_id	smOrgId, 						
	@debug_level			smDebugLevel	= 0				
)
AS 

DECLARE 
	@result	 	smErrorCode, 
	@trx_ctrl_num			smControlNumber,
	@co_trx_id				smSurrogateKey,
	@home_currency_code		smCurrencyCode,
	@cur_precision 			smallint,			
	@round_factor 			float,				
	@account_type_credit smAccountTypeID,
	@account_type_debit		smAccountTypeID,
	@trx_description		smStdDescription,/*added to SP*/
	@doc_reference				varchar(16)/*added to SP*/
	 

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amactnew.sp" + ", line " + STR( 81, 5 ) + " -- ENTRY: "


EXEC @result = amGetCurrencyCode_sp
						@company_id,
						@home_currency_code OUTPUT

IF @result <> 0
 	RETURN @result 

 
EXEC @result = amGetCurrencyPrecision_sp 
						@cur_precision 	OUTPUT,
						@round_factor 	OUTPUT 

IF @result <> 0 
	RETURN @result 


SELECT @cost = (SIGN(@cost) * ROUND(ABS(@cost) + 0.0000001, @cur_precision))

IF (ABS((@cost)-(0.0)) > 0.0000001)
BEGIN

	set @trx_description = (select asset_description from amasset where co_asset_id = @co_asset_id)	/*added to SP*/
	SET @doc_reference = (select asset_ctrl_num from amasset where co_asset_id = @co_asset_id)	/*added to SP*/
	EXEC @result = amNextControlNumber_sp
						@company_id,
						5,
						@trx_ctrl_num OUTPUT,
						@debug_level

	IF @result <> 0
	 	RETURN @result 

	EXEC @result = amNextKey_sp 	
							7, 
	 @co_trx_id OUTPUT 

	IF @result != 0 
	 RETURN @result 

	
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
		change_in_quantity, 
		org_id	
	)
	VALUES
	( 
		@company_id,
		@trx_ctrl_num,
		"",
		@co_trx_id,
		@trx_type,
		0,
		NULL,				
		GETDATE(),
		@user_id,
		@apply_date,
		0,				
		NULL,				
		0,				
		@trx_description, /*Added to SP*/
		@doc_reference,/*Added to SP*/
		0,					
		0,					
		0,					
		@company_id,		
		@home_currency_code,
		0.0,				
		0.0,				
		0,
		0.00,				
		0,
		3,
		@co_asset_id,
		0,
		0,
		0,
		@org_id
	)

	SELECT @result = @@error
	IF @result <> 0
	BEGIN
		IF @debug_level >= 1
			SELECT "Insert into amtrxhdr failed"
		ROLLBACK TRANSACTION
	 RETURN @result 
	END
		
	
	INSERT amacthst 
	(
			co_trx_id,
	 co_asset_book_id, 
	 apply_date, 
	 trx_type, 
	 last_modified_date,
	 modified_by, 
	 effective_date, 
	 revised_cost, 
	 revised_accum_depr,
	 delta_cost, 
	 delta_accum_depr, 
	 percent_disposed, 
	 posting_flag,
	 journal_ctrl_num,
	 created_by_trx
	)

	SELECT 
			@co_trx_id,
	 	co_asset_book_id,
	 	@apply_date,
	 	@trx_type,
	 	GETDATE(), 	 	 
	 @user_id,
	 NULL, 	 
	 0.0, 	 
	 0.0, 	 
	 0.0, 	 
	 0.0, 	 
	 0.0, 	 
	 0, 	 
	 "",		 	
	 0		 		
	 			 	
	FROM	amastbk
	WHERE	co_asset_id 	= @co_asset_id

	SELECT @result = @@error
	IF @result <> 0
		RETURN @result

	IF (@cost > 0.0)
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
		
		INSERT amvalues 
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
		SELECT 
			@co_trx_id,
		 	co_asset_book_id,
		 	@account_type_debit,
		 	@apply_date,
		 	@trx_type, 
		 	@cost, 	 	 
		 	0, 					
		 	0	 	 
		FROM	amastbk
		WHERE	co_asset_id = @co_asset_id

		SELECT @result = @@error
		IF @result <> 0
			RETURN @result

	END


	IF @account_type_credit IS NOT NULL
	BEGIN
	
		INSERT amvalues 
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
		SELECT 
			@co_trx_id,
		 	co_asset_book_id,
		 	@account_type_credit,
		 	@apply_date,
		 	@trx_type, 
		 	-@cost, 	 	 
		 	0, 					
		 	0	 	 
		FROM	amastbk
		WHERE	co_asset_id = @co_asset_id

		SELECT @result = @@error
		IF @result <> 0
			RETURN @result
	END
	
END

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amactnew.sp" + ", line " + STR( 360, 5 ) + " -- EXIT: "

RETURN 0 
GO
GRANT EXECUTE ON  [dbo].[amActivityNew_sp] TO [public]
GO
