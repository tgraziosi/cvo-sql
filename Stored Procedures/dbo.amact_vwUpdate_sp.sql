SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[amact_vwUpdate_sp] 
( 
	@timestamp timestamp,
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
	@rowcount 			smCounter, 
	@error 				smErrorCode, 
	@ts 				timestamp, 
	@message	 		smErrorLongDesc,
	@param				smErrorParam,
	@trx_ctrl_num		smControlNumber,
	@asset_ctrl_num		smControlNumber,
	@activity_state		smSystemState,
	@is_new				smLogical,
	@acquisition_date	smApplyDate,
	@apply_date_dt		smApplyDate,
	@valid				smLogical

SELECT	@is_new				= is_new,
		@activity_state		= activity_state,
		@acquisition_date	= acquisition_date,
		@asset_ctrl_num		= asset_ctrl_num
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
					AND		apply_date	= @acquisition_date
					AND		co_trx_id	<> @co_trx_id)
	 		SELECT @valid = 0

		IF @valid = 0
		BEGIN
			SELECT	@param = RTRIM(CONVERT(char(255), @apply_date_dt, 107))

			EXEC 		amGetErrorMessage_sp 
									20580, "tmp/amactup.sp", 135, 
									@param, @asset_ctrl_num, 
									@error_message = @message OUT 
			IF @message IS NOT NULL RAISERROR 	20580 @message 
			RETURN 		20580
		END
	END
		
END

IF @fixed_asset_account_code IS NULL
	SELECT @fixed_asset_account_id = 0
ELSE
BEGIN
	IF @fixed_asset_account_id = -1			
	BEGIN
		IF @fixed_asset_ref_code IS NULL
			SELECT @fixed_asset_ref_code = ""
			
		EXEC @error = amGetAccountID_sp
						@company_id,
						@fixed_asset_account_code,
						@fixed_asset_ref_code,
						@fixed_asset_account_id OUTPUT
		IF @error <> 0
			RETURN @error
	END
END

IF @imm_exp_account_code IS NULL
	SELECT @imm_exp_account_id = 0
ELSE
BEGIN
	IF @imm_exp_account_id = -1
	BEGIN
		IF @imm_exp_ref_code IS NULL
			SELECT @imm_exp_ref_code = ""
	
		EXEC @error = amGetAccountID_sp
						@company_id,
						@imm_exp_account_code,
						@imm_exp_ref_code,
						@imm_exp_account_id OUTPUT
		IF @error <> 0
			RETURN @error
	END
END

UPDATE amtrxhdr 
SET 
	journal_ctrl_num 		= @journal_ctrl_num,
	trx_type				= @trx_type,
	last_modified_date		= @last_modified_date,
	modified_by				= @modified_by,
	apply_date				= @apply_date,
	posting_flag			= @posting_flag,
	date_posted				= @date_posted,
	hold_flag				= @hold_flag,
	trx_description			= @trx_description,
	doc_reference			= @doc_reference,
	note_id					= @note_id, 
	user_field_id	 		= @user_field_id, 
	revaluation_rate 		= @revaluation_rate, 
	trx_source				= @trx_source,
	change_in_quantity		= @change_in_quantity,
	fixed_asset_account_id	= @fixed_asset_account_id,
	imm_exp_account_id		= @imm_exp_account_id 
WHERE	co_asset_id			= @co_asset_id
AND		co_trx_id			= @co_trx_id 
AND		timestamp			= @timestamp 

SELECT @error = @@error, @rowcount = @@rowcount 
IF @error <> 0  
BEGIN
	ROLLBACK 	TRANSACTION
	RETURN 		@error 
END

IF @rowcount = 0  
BEGIN 
	
	 
	SELECT 	@ts 			= timestamp 
	FROM 	amtrxhdr 
	WHERE 	co_asset_id		= @co_asset_id
	AND		co_trx_id		= @co_trx_id

	SELECT @rowcount = @@rowcount 

	IF @rowcount = 0 		 
	BEGIN 
		EXEC 		amGetErrorMessage_sp 20004, "tmp/amactup.sp", 226, "amtrxhdr", @error_message = @message OUT 
		IF @message IS NOT NULL RAISERROR 	20004 @message 
		RETURN 		20004 
	END 

	IF @ts <> @timestamp 	
	BEGIN 
		EXEC 		amGetErrorMessage_sp 20003, "tmp/amactup.sp", 233, "amtrxhdr", @error_message = @message OUT 
		IF @message IS NOT NULL RAISERROR 	20003 @message 
		RETURN 		20003 
	END 
END 


RETURN 0 
GO
GRANT EXECUTE ON  [dbo].[amact_vwUpdate_sp] TO [public]
GO
