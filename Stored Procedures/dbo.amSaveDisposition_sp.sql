SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[amSaveDisposition_sp] 
( 
	@company_id				smCompanyID,				
	@co_asset_id 			smSurrogateKey, 			
	@asset_ctrl_num 		smControlNumber, 			
	@disposition_date		smApplyDate,				
	@proceeds				smMoneyZero,				
	@cost_of_removal		smMoneyZero,				
	@user_id				smUserID,					
	@trx_type				smTrxType,					
	@trx_subtype			smTrxSubtype, 				
	@home_currency_code		smCurrencyCode,				
	@disp_trx_ctrl_num		smControlNumber,			
	@depr_trx_ctrl_num		smControlNumber,			
	@disp_co_trx_id			smSurrogateKey,				
	@depr_co_trx_id			smSurrogateKey,				
	@new_disp_date			smApplyDate,				
	@new_activity_state		smSystemState,				
	@num_books				smCounter,					
	@proportion_disposed	smRevaluationRate 	= 100.0,	
	@quantity_disposed		smQuantity			= 0,	
	@debug_level			smDebugLevel 		= 0 	
)
AS 

DECLARE 
	@result		 			smErrorCode, 				
	@message				smErrorLongDesc,			
	@rowcount				smCounter,					
	@org_id                                 varchar (30) 
	
IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amsavdsp.sp" + ", line " + STR( 92, 5 ) + " -- ENTRY: "

IF @debug_level >= 3
BEGIN
	SELECT * FROM #amlstdpr

	SELECT 	* 
	FROM 	amastbk 
	WHERE 	co_asset_id = @co_asset_id
	
	SELECT	quantity_disposed 	= @quantity_disposed,
			depr_co_trx_id		= @depr_co_trx_id,
			disp_co_trx_id		= @disp_co_trx_id
END

SELECT @org_id = org_id
     FROM  amasset
     WHERE co_asset_id	= @co_asset_id


BEGIN TRANSACTION


	
	IF 	@trx_type = 30
	BEGIN
		UPDATE	amasset
		SET		activity_state 		= @new_activity_state,	
				disposition_date	= @new_disp_date		
		WHERE	co_asset_id			= @co_asset_id
		AND		activity_state		= 0 

		SELECT	@result = @@error, @rowcount= @@rowcount
		IF @result <> 0
		BEGIN
			IF @debug_level >= 1
				SELECT "Update of amasset failed"
			ROLLBACK 	TRANSACTION
		 RETURN 		@result 
		END
		
		IF @rowcount <> 1
		BEGIN
			EXEC 		amGetErrorMessage_sp 20128, "tmp/amsavdsp.sp", 138, @asset_ctrl_num, @error_message = @message OUT 
			IF @message IS NOT NULL RAISERROR 	20128 @message 
			ROLLBACK 	TRANSACTION
			RETURN		20128
		END

	END
 	
 	
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
		@disp_trx_ctrl_num,
		"",
		@disp_co_trx_id,
		@trx_type,
		@trx_subtype,
		NULL,				
		GETDATE(),
		@user_id,
		@disposition_date,
		0,				
		NULL,
		0,				
		"",
		"",
		0,					
		0,					
		0,					
		@company_id,		
		@home_currency_code,
		0.0,
		@proceeds,
		@depr_co_trx_id,
		@proportion_disposed,	 
		0,
		1,
		@co_asset_id,
		0,
		0,
		@quantity_disposed,
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
		@depr_trx_ctrl_num,
		"",
		@depr_co_trx_id,
		60,
		0,					
		NULL,				
		GETDATE(),
		@user_id,
		@disposition_date,
		0,				
		NULL,
		0,				
		"",
		"",
		0,					
		0,					
		0,					
		@company_id,		
		@home_currency_code,
		0.0,
		0.0,
		@disp_co_trx_id,
		0,
		0,
		1,
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
	
	INSERT INTO amacthst
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
		created_by_trx,
		disposed_depr			
	)
	SELECT
		@disp_co_trx_id, 	 
		tmp.co_asset_book_id, 	 
		@disposition_date, 			
		@trx_type,
		GETDATE(), 			
		@user_id, 	
		NULL,					
		0.0, 			 		
		0.0,			 		
	 0.0, 	 				
		0.0,		 			
		100.00, 			
		0,					
		"",						
		0,					
		depr_ytd			
	FROM	#amdspamt	tmp
	
	SELECT @result = @@error
	IF @result <> 0
	BEGIN
		IF @debug_level >= 1
			SELECT "Insert of disposition into amacthst failed"

		ROLLBACK TRANSACTION
	 RETURN @result 
	END


	INSERT INTO amacthst
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
		@depr_co_trx_id, 	 
		tmp.co_asset_book_id, 	 
		@disposition_date, 			
		60,
		GETDATE(), 			
		@user_id, 	
		NULL,					
		0.0, 			 		
		0.0,			 		
		0.0, 
		0.0,
		0.00, 			
		0,					
		"",						
		0					
	FROM	#amdspamt	tmp
	
	SELECT @result = @@error
	IF @result <> 0
	BEGIN
		IF @debug_level >= 1
			SELECT "Insert of depreciation adjustment into amacthst failed"
		ROLLBACK TRANSACTION
	 RETURN @result 
	END

	
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
	SELECT
		@disp_co_trx_id, 	 
		tmp.co_asset_book_id, 	 
 0, 
 @disposition_date, 
		@trx_type,
 - tmp.cost, 
 0,					
 0				
	FROM	#amdspamt	tmp

	SELECT @result = @@error
	IF @result <> 0
	BEGIN
		IF @debug_level >= 1
			SELECT "Insert into amvalues failed"
		ROLLBACK TRANSACTION
	 RETURN @result 
	END

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
	SELECT
		@disp_co_trx_id, 	 
		tmp.co_asset_book_id, 	 
 1, 
 @disposition_date, 
		@trx_type,
 - tmp.accum_depr, 
 0,					
 0				
	FROM	#amdspamt	tmp

	SELECT @result = @@error
	IF @result <> 0
	BEGIN
		IF @debug_level >= 1
			SELECT "Insert into amvalues failed"
		ROLLBACK TRANSACTION
	 RETURN @result 
	END

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
	SELECT
		@disp_co_trx_id, 	 
		tmp.co_asset_book_id, 	 
 4, 
 @disposition_date, 
		@trx_type,
 @proceeds, 
 0,					
 0				
	FROM	#amdspamt	tmp

	SELECT @result = @@error
	IF @result <> 0
	BEGIN
		IF @debug_level >= 1
			SELECT "Insert into amvalues failed"
		ROLLBACK TRANSACTION
	 RETURN @result 
	END


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
	SELECT
		@disp_co_trx_id, 	 
		tmp.co_asset_book_id, 	 
 6, 
 @disposition_date, 
		@trx_type,
 @cost_of_removal, 
 0,					
 0				
	FROM	#amdspamt	tmp

	SELECT @result = @@error
	IF @result <> 0
	BEGIN
		IF @debug_level >= 1
			SELECT "Insert into amvalues failed"
		ROLLBACK TRANSACTION
	 RETURN @result 
	END

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
	SELECT
		@disp_co_trx_id, 	 
		tmp.co_asset_book_id, 	 
 8, 
 @disposition_date, 
		@trx_type,
 tmp.gain_or_loss, 
 0,					
 0				
	FROM	#amdspamt	tmp

	SELECT @result = @@error
	IF @result <> 0
	BEGIN
		IF @debug_level >= 1
			SELECT "Insert into amvalues failed"
		ROLLBACK TRANSACTION
	 RETURN @result 
	END

	
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
	SELECT
		@depr_co_trx_id, 	 
		tmp.co_asset_book_id, 	 
 5, 
 @disposition_date, 
 60, 
 tmp.depr_expense, 
 0,					
 0				
	FROM	#amdspamt	tmp

	SELECT @result = @@error
	IF @result <> 0
	BEGIN
		IF @debug_level >= 1
			SELECT "Insert into amvalues failed"
		ROLLBACK TRANSACTION
	 RETURN @result 
	END

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
	SELECT
		@depr_co_trx_id, 	 
		tmp.co_asset_book_id, 	 
 1, 
 @disposition_date, 
 60, 
 - tmp.depr_expense, 
 0,					
 0				
	FROM	#amdspamt	tmp

	SELECT @result = @@error
	IF @result <> 0
	BEGIN
		IF @debug_level >= 1
			SELECT "Insert into amvalues failed"
		ROLLBACK 	TRANSACTION
	 RETURN 		@result 
	END

	
	IF @trx_type = 30
	BEGIN
		UPDATE	amastbk
		SET		last_depr_co_trx_id				= @depr_co_trx_id
		FROM	#amlstdpr old_ab,
				amastbk	ab
		WHERE	old_ab.co_asset_book_id 		= ab.co_asset_book_id
		AND		old_ab.last_depr_co_trx_id		= ab.last_depr_co_trx_id
		AND		ab.placed_in_service_date		<= @disposition_date
		AND	 (	old_ab.last_posted_depr_date	= ab.last_posted_depr_date
				OR (	old_ab.last_posted_depr_date 	IS NULL
					AND ab.last_posted_depr_date 		IS NULL))
		
		SELECT 	@result 	= @@error, 
				@rowcount 	= @@rowcount
		IF @result <> 0
		BEGIN
			IF @debug_level >= 1
				SELECT "Update of amastbk failed"
			ROLLBACK 	TRANSACTION
		 RETURN 		@result 
		END

		IF @debug_level >= 3
			SELECT	rows_updated 	= @rowcount 
		
		UPDATE	amastbk							
		SET		last_depr_co_trx_id				= @depr_co_trx_id
		FROM	#amlstdpr old_ab,
				amastbk	ab
		WHERE	old_ab.co_asset_book_id 		= ab.co_asset_book_id
		AND		(ab.placed_in_service_date		> @disposition_date
				OR ab.placed_in_service_date	IS NULL)
		AND	 (	old_ab.last_posted_depr_date	= ab.last_posted_depr_date
				OR (	old_ab.last_posted_depr_date 	IS NULL
					AND ab.last_posted_depr_date 		IS NULL))
		
		SELECT 	@result 	= @@error,
				@rowcount 	= @rowcount + @@rowcount
		IF @result <> 0
		BEGIN
			IF @debug_level >= 1
				SELECT "Update of amastbk failed"
			ROLLBACK 	TRANSACTION
		 RETURN 		@result 
		END
		
		IF @debug_level >= 3
			SELECT	rows_updated 	= @rowcount 
		
	END
	ELSE
	BEGIN
		
		UPDATE	amastbk
		SET		last_depr_co_trx_id				= @depr_co_trx_id
		FROM	#amlstdpr old_ab,
				amastbk	ab
		WHERE	old_ab.co_asset_book_id 		= ab.co_asset_book_id
		AND		old_ab.last_depr_co_trx_id		= ab.last_depr_co_trx_id
		AND	 (	old_ab.last_posted_depr_date	= ab.last_posted_depr_date
				OR (	old_ab.last_posted_depr_date IS NULL
					AND ab.last_posted_depr_date IS NULL))
		
		SELECT @result = @@error, @rowcount = @@rowcount
		IF @result <> 0
		BEGIN
			IF @debug_level >= 1
				SELECT "Update of amastbk failed"
			ROLLBACK 	TRANSACTION
		 RETURN 		@result 
		END

		IF @debug_level >= 3
	 		SELECT	rows_updated 	= @rowcount 

	END

	
	IF @rowcount <> @num_books
	BEGIN
		IF @debug_level >= 3
		BEGIN
			SELECT	rows_updated 	= @rowcount, 
					num_books 		= @num_books
			SELECT * FROM #amdspamt
			SELECT * FROM #amlstdpr
			SELECT * FROM amastbk where co_asset_id = @co_asset_id
		END
		EXEC 		amGetErrorMessage_sp 20119, "tmp/amsavdsp.sp", 727, @asset_ctrl_num, @error_message = @message OUT 
		IF @message IS NOT NULL RAISERROR 	20119 @message 
		ROLLBACK 	TRANSACTION
		RETURN		20119
	END

COMMIT TRANSACTION

IF @debug_level >= 5
	SELECT 	co_trx_id,
			trx_type,
			linked_trx
	FROM	amtrxhdr
	WHERE	co_trx_id IN (@depr_co_trx_id, @disp_co_trx_id)

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amsavdsp.sp" + ", line " + STR( 742, 5 ) + " -- EXIT: "

RETURN 0 
GO
GRANT EXECUTE ON  [dbo].[amSaveDisposition_sp] TO [public]
GO
