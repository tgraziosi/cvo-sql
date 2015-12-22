SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[amActivateExistingAsset_sp] 
(
	@company_id 			smCompanyID, 		
	@co_asset_id 			smSurrogateKey, 	
	@asset_ctrl_num 		smControlNumber, 	
	@acquisition_date		smApplyDate,		
	@prev_yr_end_date 		smApplyDate, 		
	@cur_yr_start_date 		smApplyDate, 		
	@home_currency_code		smCurrencyCode,		
	@user_id				smUserID,			
	@debug_level			smDebugLevel 	= 0	
)
AS 

DECLARE 
	@rowcount				smCounter,
	@result 				smErrorCode, 		
	@message 				smErrorLongDesc, 	
	@param 					smErrorParam, 			
	@co_asset_book_id 		smSurrogateKey, 	
	@addition_co_trx_id 	smSurrogateKey, 	
	@asset_ok 				smLogical, 			
	@book_code		 		smBookCode,		 	
	@apply_date				smApplyDate,		
	@placed_in_service_date	smApplyDate,		 
	@asset_account_id		smSurrogateKey,		
	@accum_depr_account_id	smSurrogateKey,		
	@fixed_asset_account_id	smSurrogateKey,		
	@depr_exp_account_id	smSurrogateKey,		
	@adjustment_account_id	smSurrogateKey,		
	@imm_exp_account_id		smSurrogateKey,		
	@cost					smMoneyZero,
	@accum_depr				smMoneyZero,
	@valid					smLogical
			

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amdoexst.sp" + ", line " + STR( 98, 5 ) + " -- ENTRY: "

IF @debug_level >= 5
	SELECT 	co_asset_id 		= @co_asset_id,
			prev_yr_end_date	= @prev_yr_end_date

 
SELECT 	@asset_ok 			= 1,
		@addition_co_trx_id	= 0,
		@cost				= 0.0,
		@accum_depr			= 0.0,
		@valid				= 1,
		@apply_date			= NULL


SELECT 	@apply_date		= MIN(apply_date)
FROM	amtrxhdr
WHERE	co_asset_id 	= @co_asset_id
AND		(	trx_type	!= 10
		OR	apply_date	!= @acquisition_date)

IF @apply_date IS NOT NULL
BEGIN
	SELECT 	@valid = 0,
			@param = RTRIM(CONVERT(char(255), @apply_date, 107))
END
ELSE
BEGIN
	SELECT	@rowcount 		= COUNT(co_trx_id)
	FROM	amtrxhdr
	WHERE	co_asset_id 	= @co_asset_id
	AND		apply_date		= @acquisition_date
	AND		trx_type		= 10

	IF @rowcount > 1
	BEGIN
		SELECT	@valid = 0,
				@param = CONVERT(datetime, @acquisition_date, 107)
	END
END

IF @valid = 0 
BEGIN

	SELECT 		@asset_ok = 0 
	EXEC 		amGetErrorMessage_sp 
							20174, "tmp/amdoexst.sp", 149, 
							@asset_ctrl_num, @param, 
							@error_message = @message OUT 
	IF @message IS NOT NULL RAISERROR 	20174 @message 
END



EXEC	@result = amGetActivityAccountIDs_sp
						@company_id,
						@co_asset_id,
						@asset_account_id 		OUTPUT,
						@accum_depr_account_id	OUTPUT,
						@fixed_asset_account_id	OUTPUT,
						@depr_exp_account_id	OUTPUT,
						@adjustment_account_id	OUTPUT,
						@imm_exp_account_id		OUTPUT,
						@debug_level
					
IF @result <> 0 
		RETURN 	@result 


SELECT	@addition_co_trx_id	= co_trx_id
FROM	amtrxhdr
WHERE	co_asset_id			= @co_asset_id
AND		trx_type			= 10
AND		apply_date			= @acquisition_date

IF @debug_level >= 5
	SELECT 	addition_co_trx_id 	= @addition_co_trx_id,
			asset_account_id		= @asset_account_id,
			accum_depr_account_id	= @accum_depr_account_id,
			fixed_asset_account_id	= @fixed_asset_account_id,
			depr_exp_account_id		= @depr_exp_account_id,
			adjustment_account_id	= @adjustment_account_id,
			imm_exp_account_id		= @imm_exp_account_id


SELECT 	@co_asset_book_id 	= MIN(co_asset_book_id)
FROM	amastbk
WHERE	co_asset_id 		= @co_asset_id

WHILE @co_asset_book_id IS NOT NULL
BEGIN
	
	SELECT	@placed_in_service_date = placed_in_service_date,
			@book_code				= book_code
	FROM	amastbk
	WHERE	co_asset_book_id		= @co_asset_book_id

	
	IF NOT EXISTS (SELECT 	depr_rule_code
					FROM 	amdprhst
					WHERE	co_asset_book_id 	= @co_asset_book_id
					AND		effective_date 		<= @acquisition_date)

	BEGIN 
		SELECT 		@asset_ok = 0 
		EXEC	 	amGetErrorMessage_sp 
								20170, "tmp/amdoexst.sp", 219,
								@asset_ctrl_num, 
								@error_message = @message OUT 
		IF @message IS NOT NULL RAISERROR 	20170 @message 
		IF @debug_level >= 3
			SELECT	error_message		= @message
		BREAK		
	END 

	IF @debug_level >= 3
		SELECT	co_asset_book_id		= @co_asset_book_id,
				placed_in_service_date 	= @placed_in_service_date
	
	 
	IF 	(@placed_in_service_date IS NOT NULL)
	BEGIN 

		
		IF (@placed_in_service_date < @cur_yr_start_date)
		AND NOT EXISTS (SELECT 	fiscal_period_end
						FROM 	amastprf 	 
						WHERE 	fiscal_period_end 	= @prev_yr_end_date 
						AND 	co_asset_book_id 	= @co_asset_book_id ) 

		BEGIN 
			SELECT 		@param 	= RTRIM(CONVERT(char(255), @prev_yr_end_date, 107))
			SELECT 		@asset_ok 	= 0 

			EXEC 		amGetErrorMessage_sp 
								20171, "tmp/amdoexst.sp", 259, 
								@asset_ctrl_num, @book_code, @param, 
								@error_message = @message OUT 
			IF @message IS NOT NULL RAISERROR 	20171 @message 
			IF @debug_level >= 3
				SELECT	error_message		= @message
		END 
		
	END
	ELSE 
	BEGIN

		IF @debug_level >= 3
			SELECT	*
			FROM 	amastprf 	 
			WHERE 	co_asset_book_id 	= @co_asset_book_id

		
		IF EXISTS (SELECT 		fiscal_period_end
						FROM 	amastprf 	 
						WHERE 	co_asset_book_id 	= @co_asset_book_id ) 

		BEGIN 
			SELECT 		@asset_ok 	= 0 

			EXEC 		amGetErrorMessage_sp 
								20173, "tmp/amdoexst.sp", 288, 
								@asset_ctrl_num, @book_code, 
								@error_message = @message OUT 
			IF @message IS NOT NULL RAISERROR 	20173 @message 
			IF @debug_level >= 3
				SELECT	error_message		= @message
		END 

	END

	IF @asset_ok = 1 
	BEGIN
		
		
		EXEC @result = amCreateActForProfiles_sp 
						 	@company_id,			
						 	@co_asset_id, 			
						 	@co_asset_book_id, 	 	
						 	@addition_co_trx_id, 	
						 	@acquisition_date,		
							@asset_account_id,
							@accum_depr_account_id,
							@depr_exp_account_id,
							@adjustment_account_id,
							@debug_level
		
		IF @result <> 0 
	 		RETURN 	@result 
	END
		 
	
	SELECT 	@co_asset_book_id 	= MIN(co_asset_book_id)
	FROM	amastbk
	WHERE	co_asset_id 		= @co_asset_id
	AND		co_asset_book_id 	> @co_asset_book_id

END	

IF	(@asset_ok = 1)
BEGIN

	
	IF EXISTS (SELECT 	amastbk.co_asset_id	
				FROM 	amastprf,
						amastbk 
				WHERE 	amastprf.co_asset_book_id 	= amastbk.co_asset_book_id 
				AND 	amastbk.co_asset_id 		= @co_asset_id)
	BEGIN
		UPDATE 	amasset 
		SET 	depreciated 	= 1 
		WHERE 	co_asset_id 	= @co_asset_id 
	
		SELECT @result = @@error 
		IF @result <> 0 
	 		RETURN 	@result 
	END
	
	
	UPDATE	amastprf
	SET		effective_date =
				(SELECT MAX(effective_date)
				FROM	amdprhst dh
				WHERE	dh.co_asset_book_id = amastprf.co_asset_book_id
				AND		effective_date		<= amastprf.fiscal_period_end)
	FROM	amastprf,
			amastbk 
	WHERE	amastprf.co_asset_book_id 	= amastbk.co_asset_book_id
	AND		amastbk.co_asset_id			= @co_asset_id
	
	SELECT @result = @@error 
	IF @result <> 0 
 		RETURN 	@result 


	IF @addition_co_trx_id != 0
	BEGIN
		 
		SELECT 	@cost 				= amount 
		FROM 	amvalues 
		WHERE 	co_trx_id			= @addition_co_trx_id
		AND 	co_asset_book_id 	= @co_asset_book_id 
		AND		account_type_id 	= 0 

		SELECT 	@accum_depr 		= amount 
		FROM 	amvalues 
		WHERE 	co_trx_id			= @addition_co_trx_id
		AND 	co_asset_book_id 	= @co_asset_book_id 
		AND 	account_type_id 	= 1 
		
		 
		UPDATE 	amtrxhdr 
		SET 	posting_flag 		= 1,			
				journal_ctrl_num	= ""				
		WHERE 	co_trx_id			= @addition_co_trx_id

		SELECT @result = @@error
		IF @result <> 0 
	 		RETURN 	@result 
		
	 	UPDATE 	amacthst 
		SET 	revised_cost 		= @cost,
				revised_accum_depr 	= @accum_depr,
				delta_cost 			= @cost,
				delta_accum_depr 	= @accum_depr,
				posting_flag 		= 1,			
				journal_ctrl_num	= ""
		FROM	amastbk ab,
				amacthst ah
		WHERE 	ah.co_trx_id			= @addition_co_trx_id
		AND 	ah.co_asset_book_id 	= ab.co_asset_book_id 
		AND		ab.co_asset_id			= @co_asset_id

		SELECT @result = @@error
		IF @result <> 0 
	 		RETURN 	@result 
		
		
		UPDATE	amvalues
		SET		account_id 			= @asset_account_id
		FROM	amastbk ab,
				amvalues v
		WHERE 	v.co_trx_id			= @addition_co_trx_id
		AND 	v.co_asset_book_id 	= ab.co_asset_book_id 
		AND		ab.co_asset_id		= @co_asset_id
		AND		v.account_type_id	= 0
	
		SELECT @result = @@error
		IF @result <> 0 
	 		RETURN 	@result 
		
		UPDATE	amvalues
		SET		account_id 			= @accum_depr_account_id
		FROM	amastbk ab,
				amvalues v
		WHERE 	v.co_trx_id			= @addition_co_trx_id
		AND 	v.co_asset_book_id 	= ab.co_asset_book_id 
		AND		ab.co_asset_id		= @co_asset_id
		AND		v.account_type_id		= 1
	
		SELECT @result = @@error
		IF @result <> 0 
	 		RETURN 	@result 
		
		
		UPDATE	amvalues
		SET		account_id 			= @fixed_asset_account_id
		FROM	amastbk ab,
				amvalues v
		WHERE 	v.co_trx_id			= @addition_co_trx_id
		AND 	v.co_asset_book_id 	= ab.co_asset_book_id 
		AND		ab.co_asset_id		= @co_asset_id
		AND		v.account_type_id		= 3
	
		SELECT @result = @@error
		IF @result <> 0 
	 		RETURN 	@result 
		
		
		UPDATE	amvalues
		SET		account_id 			= @imm_exp_account_id
		FROM	amastbk ab,
				amvalues v
		WHERE 	v.co_trx_id			= @addition_co_trx_id
		AND 	v.co_asset_book_id 	= ab.co_asset_book_id 
		AND		ab.co_asset_id		= @co_asset_id
		AND		v.account_type_id		= 9
	
		SELECT @result = @@error
		IF @result <> 0 
	 		RETURN 	@result 
		
	END

	
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
			change_in_quantity
		)
		SELECT	DISTINCT
			@company_id,
			trx_ctrl_num,
			"",
			co_trx_id,
			trx_type,
			0,					
			"",					
			GETDATE(),
			1,
			apply_date,
			1,				
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
			0,					
			0.0,					
			0, 					
			3,
			co_asset_id,
			0,
			0,
			0					
		FROM	#am_new_activities

		SELECT @result = @@error 
		IF @result <> 0 
		BEGIN 
			ROLLBACK TRAN 
	 		RETURN 	@result 
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
	 co_trx_id, 
	 co_asset_book_id, 
	 apply_date, 
	 trx_type, 
	 GETDATE(), 
	 @user_id,
	 effective_date,
	 revised_cost, 
	 revised_accum_depr, 
	 delta_cost, 
	 delta_accum_depr, 
	 0, 				
	 1,		
	 "",				
	 0				
		FROM	#am_new_activities

		SELECT @result = @@error 
		IF @result <> 0 
		BEGIN 
			ROLLBACK TRAN 
	 		RETURN 	@result 
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
	 co_trx_id, 
	 co_asset_book_id, 
	 account_type_id,
	 apply_date, 
	 trx_type, 
	 amount,
	 account_id,
	 1		
		FROM	#am_new_values

		SELECT @result = @@error 
		IF @result <> 0 
		BEGIN 
			ROLLBACK TRAN 
	 		RETURN 	@result 
		END 
							

		 
		UPDATE 	amasset 
		SET 	activity_state 		= 0,
				rem_quantity		= orig_quantity 
		WHERE 	co_asset_id	 		= @co_asset_id 

		SELECT @result = @@error 
		IF @result <> 0 
		BEGIN 
			ROLLBACK TRAN 
			RETURN 	@result 
		END 

		
		UPDATE 	amastbk 
		SET 	last_posted_depr_date = (SELECT MAX(fiscal_period_end)
											FROM 	amastprf
											WHERE 	co_asset_book_id = amastbk.co_asset_book_id)
		FROM 	amastbk
		WHERE 	co_asset_id 	= @co_asset_id 

		SELECT @result = @@error 
		IF @result <> 0 
	 		RETURN 	@result 


	 
	COMMIT TRANSACTION 
		
	
	EXEC 		amGetErrorMessage_sp 
						20400, "tmp/amdoexst.sp", 696, 
						@asset_ctrl_num, 
						@error_message = @message OUT 
	IF @message IS NOT NULL RAISERROR 	20400 @message 

END


DELETE 
FROM 	#am_new_activities

SELECT @result = @@error 
IF @result <> 0 
		RETURN 	@result 

DELETE 
FROM 	#am_new_values

SELECT @result = @@error 
IF @result <> 0 
		RETURN 	@result 

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amdoexst.sp" + ", line " + STR( 720, 5 ) + " -- EXIT: "

RETURN 	0 
GO
GRANT EXECUTE ON  [dbo].[amActivateExistingAsset_sp] TO [public]
GO
