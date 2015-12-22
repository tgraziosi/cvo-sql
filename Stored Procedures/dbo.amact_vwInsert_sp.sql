SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[amact_vwInsert_sp] 
( 
	@company_id smCompanyID, 		
	@journal_ctrl_num				smControlNumber,	
	@co_trx_id smSurrogateKey, 	
	@trx_type smTrxType, 
	@last_modified_date varchar(30), 
	@modified_by smUserID, 
	@apply_date varchar(30), 
	@posting_flag smPostingState, 
	@date_posted varchar(30), 
	@hold_flag						smLogical,
	@trx_description smStdDescription, 
	@doc_reference smDocumentReference, 
	@note_id 	smSurrogateKey,
	@user_field_id					smSurrogateKey,		
	@total_received					smMoneyZero,
	@linked_trx						smSurrogateKey,
	@revaluation_rate				smRevaluationRate,
	@trx_source						smTrxSource,
	@co_asset_id					smSurrogateKey,			
	@change_in_quantity				smQuantity,
	@fixed_asset_account_id			smSurrogateKey,			
	@fixed_asset_account_code		smAccountCode,			
	@fixed_asset_ref_code			smAccountReferenceCode,	
	@imm_exp_account_id				smSurrogateKey,		 	
	@imm_exp_account_code			smAccountCode,			
	@imm_exp_ref_code				smAccountReferenceCode	
) 
AS 

DECLARE
 	@error				smErrorCode,
	@message			smErrorLongDesc,
	@param				smErrorParam,
	@home_currency_code smCurrencyCode,
	@trx_ctrl_num		smControlNumber,
	@asset_ctrl_num		smControlNumber,
	@activity_state		smSystemState,
	@is_new				smLogical,
	@acquisition_date	smApplyDate,
	@apply_date_dt		smApplyDate,
	@valid				smLogical,
	@org_id                 varchar (30)                 

SELECT 	@home_currency_code = home_currency
FROM	glco


SELECT	@is_new				= is_new,
		@activity_state		= activity_state,
		@acquisition_date	= acquisition_date,
		@asset_ctrl_num		= asset_ctrl_num,
		@org_id = org_id
FROM	amasset
WHERE	co_asset_id			= @co_asset_id

IF @@rowcount = 1
BEGIN
	IF 	@is_new			= 0
	AND	@activity_state	= 100
	BEGIN
		SELECT	@apply_date_dt = CONVERT(datetime, @apply_date),
				@valid = 1
		
		IF 	@apply_date_dt	!= @acquisition_date
		OR 	@trx_type		!= 10
	 		SELECT @valid = 0

		IF EXISTS(SELECT co_trx_id
					FROM	amtrxhdr
					WHERE	co_asset_id = @co_asset_id
					AND		trx_type	= 10
					AND		apply_date	= @acquisition_date)
	 		SELECT @valid = 0

		IF @valid = 0
		BEGIN
			SELECT	@param = RTRIM(CONVERT(char(255), @apply_date_dt, 107))

			EXEC 		amGetErrorMessage_sp 
									20579, 'tmp/amactin.sp', 123, 
									@param, @asset_ctrl_num, 
									@error_message = @message OUT 
			IF @message IS NOT NULL RAISERROR 	20572 @message 
			RETURN 		20572
		END
	END
		
END

EXEC @error = amNextControlNumber_sp
				@company_id,
				5,
				@trx_ctrl_num OUTPUT
				
IF @error <> 0
	RETURN @error

BEGIN TRANSACTION

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
		@journal_ctrl_num,
		@co_trx_id,
		@trx_type,
		0,		
		NULL,	
		@last_modified_date,
		@modified_by,
		@apply_date,
		@posting_flag,
		@date_posted,
		@hold_flag,
		@trx_description,
		@doc_reference,
		@note_id,
		@user_field_id,
		0,
		@company_id,
		@home_currency_code,
		0.0,
		@total_received,
		@linked_trx,
		@revaluation_rate,
		0,
		@trx_source,
		@co_asset_id,
		0,
		0,
		@change_in_quantity,
		@org_id
	)

	SELECT @error = @@error
	IF @error <> 0
	BEGIN
		ROLLBACK TRANSACTION
		RETURN @error
	END

	IF @co_trx_id = 0
	BEGIN
		SELECT	@co_trx_id 		= co_trx_id
		FROM	amtrxhdr
		WHERE	company_id		= @company_id
		AND		trx_ctrl_num	= @trx_ctrl_num
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
		@co_trx_id, 	 
		co_asset_book_id, 	 
		@apply_date, 			
		@trx_type,
		@last_modified_date, 			
		@modified_by, 	
		NULL,
		0.0, 			 		
		0.0,			 		
	 0.0, 	 				
		0.0,		 			
		0.00, 			
		0,					
		'',						
		0								
	FROM	amastbk	
	WHERE	co_asset_id		= @co_asset_id		
				
	SELECT @error = @@error
	IF @error <> 0
	BEGIN
		ROLLBACK TRANSACTION
	 RETURN @error 
	END

COMMIT TRANSACTION

RETURN 0 
GO
GRANT EXECUTE ON  [dbo].[amact_vwInsert_sp] TO [public]
GO
