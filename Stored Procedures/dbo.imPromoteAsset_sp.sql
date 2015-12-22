SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[imPromoteAsset_sp] 
(
	@company_id			smCompanyID,		
	@co_asset_id 		smSurrogateKey, 	
	@curr_yr_start_date	smApplyDate,			
	@curr_precision		smallint,			
	@debug_level		smDebugLevel	= 0	
)
AS 

DECLARE 
	@ret_status 			smErrorCode, 	
	@message 				smErrorLongDesc,
	@placed_in_service_date	smApplyDate,	
	@disposition_date		smApplyDate,	
	@is_new					smLogical,		
	@acquisition_date		smApplyDate,	
	@co_asset_book_id		smSurrogateKey,	
	@addition_co_trx_id		smSurrogateKey,	
	@depreciated			smLogical,		
	@todays_date			smApplyDate,	
	@home_currency_code		smCurrencyCode

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/imastprm.sp" + ", line " + STR( 148, 5 ) + " -- ENTRY: "


SELECT	@placed_in_service_date = placed_in_service_date,
		@acquisition_date		= acquisition_date,
		@disposition_date		= disposition_date,
		@is_new					= is_new
FROM	amasset
WHERE	co_asset_id				= @co_asset_id


IF @is_new = 1	
BEGIN
	 
	UPDATE 	amasset 
	SET 	activity_state 		= 0,
			rem_quantity		= orig_quantity,
			depreciated			= 0 
	FROM 	amasset 
	WHERE 	co_asset_id	 		= @co_asset_id 

	SELECT @ret_status = @@error 
	IF @ret_status <> 0 
		RETURN 	@ret_status 
		
END
ELSE 				
BEGIN
	
	SELECT 	@todays_date 		= GETDATE(),
			@addition_co_trx_id	= NULL

	
	EXEC @ret_status = amGetCurrencyCode_sp 
					@company_id, 
					@home_currency_code OUTPUT 
	IF @ret_status <> 0
		RETURN @ret_status


	
	UPDATE	amastprf
	SET		effective_date =
				(SELECT MAX(effective_date)
				FROM	amdprhst 
				WHERE	amdprhst.co_asset_book_id 	= amastprf.co_asset_book_id
				AND		effective_date				<= amastprf.fiscal_period_end)
	FROM	amastprf,
			amastbk 
	WHERE	amastprf.co_asset_book_id 	= amastbk.co_asset_book_id
	AND		amastbk.co_asset_id			= @co_asset_id

	SELECT @ret_status = @@error 
	IF @ret_status <> 0 
		RETURN @ret_status 

	
	SELECT	@addition_co_trx_id = co_trx_id
	FROM	amtrxhdr
	WHERE	co_asset_id 		= @co_asset_id
	AND		trx_type			= 10
	AND		apply_date			= @acquisition_date

	
	UPDATE 	amtrxhdr
	SET		linked_trx = ISNULL((SELECT 	co_trx_id
								FROM 	amtrxhdr adj
								WHERE	adj.trx_type 	= 60
								AND		adj.apply_date	= dsp.apply_date
								AND		adj.co_asset_id	= dsp.co_asset_id), 0)
	FROM	amtrxhdr dsp
	WHERE	co_asset_id	= @co_asset_id
	AND		trx_type	IN (30, 70)

	SELECT @ret_status = @@error 
	IF @ret_status <> 0 
		RETURN @ret_status 

	UPDATE 	amtrxhdr
	SET		linked_trx = ISNULL(
							(SELECT 	co_trx_id
								FROM 	amtrxhdr dsp
								WHERE	dsp.trx_type 	IN (30, 70)
								AND		dsp.apply_date	= adj.apply_date
								AND		dsp.co_asset_id	= adj.co_asset_id), 0)
	FROM	amtrxhdr adj
	WHERE	co_asset_id	= @co_asset_id
	AND		trx_type	= 60

	SELECT @ret_status = @@error 
	IF @ret_status <> 0 
		RETURN @ret_status 

	SELECT 	@co_asset_book_id 	= MIN(co_asset_book_id)
	FROM 	amastbk 
	WHERE 	co_asset_id 		= @co_asset_id 

	
	WHILE 	@co_asset_book_id IS NOT NULL 
	BEGIN 
		IF @debug_level >= 3
			SELECT co_asset_book_id = @co_asset_book_id
		
		SELECT	@placed_in_service_date	= placed_in_service_date
		FROM	amastbk
		WHERE	co_asset_book_id 		= @co_asset_book_id
	
		
		IF 	@addition_co_trx_id IS NOT NULL
		BEGIN
			EXEC 	@ret_status = imApplyAdditionActivity_sp 
										@co_asset_book_id,		 
										@acquisition_date,
										@placed_in_service_date,
										@addition_co_trx_id,
										@debug_level	= @debug_level

			IF @ret_status <> 0 
			BEGIN
				IF @debug_level >= 3
					SELECT "imApplyAdditionActivity_sp failed"
				RETURN @ret_status 
			END
		END

		
		IF @placed_in_service_date IS NOT NULL
		BEGIN
			EXEC @ret_status = amSetFirstDeprDate_sp 
									@co_asset_book_id,
									@placed_in_service_date, 
									@debug_level	= @debug_level

			IF @ret_status <> 0
				RETURN @ret_status
		END

		
		EXEC 	@ret_status = amCreateActForProfiles_sp 
									@company_id,
									@co_asset_id,
									@co_asset_book_id,			 
									@addition_co_trx_id,
									@acquisition_date,
									@debug_level		= @debug_level

		IF ( @ret_status <> 0 )
			RETURN @ret_status 
		
		EXEC 	@ret_status = imUpdateActivities_sp 
									@co_asset_book_id,			 
									@addition_co_trx_id,
									@acquisition_date,
									@placed_in_service_date,
									@curr_precision,
									@debug_level 		= @debug_level

		IF ( @ret_status <> 0 )
			RETURN @ret_status 

		
		EXEC 	@ret_status = imCheckDBToSLSwitch_sp 
									@co_asset_book_id,			 
									@acquisition_date,
									@curr_yr_start_date,
									@curr_precision,
									@debug_level 		= @debug_level

		IF ( @ret_status <> 0 )
			RETURN @ret_status 

	 	
	 	SELECT 	@co_asset_book_id 	= MIN(co_asset_book_id)
		FROM 	amastbk 
		WHERE 	co_asset_id 		= @co_asset_id 
		AND 	co_asset_book_id 	> @co_asset_book_id 
	END
	
	IF EXISTS (SELECT last_depr_date
				FROM	#imbkinfo
				WHERE	last_depr_date IS NOT NULL)
		SELECT	@depreciated = 1
	ELSE
		SELECT	@depreciated = 0

	
	EXEC @ret_status = imUpdateAllAccountIDs_sp
	 		 @co_asset_id, 				
							@debug_level	= @debug_level
	IF @ret_status <> 0 
		RETURN 	@ret_status 


	IF @debug_level >= 3
		SELECT 	* 
		FROM	#imbkinfo


	

	BEGIN TRANSACTION 
		 
		IF @disposition_date IS NULL
		BEGIN
			UPDATE 	amasset 
			SET 	activity_state 	= 0,
					depreciated		= @depreciated
			FROM 	amasset 	
			WHERE 	co_asset_id 	= @co_asset_id 

			SELECT @ret_status = @@error 
		END
		ELSE
		BEGIN
			UPDATE 	amasset 
			SET 	activity_state 	= 101,
					depreciated		= @depreciated
			FROM 	amasset 
			WHERE 	co_asset_id	 	= @co_asset_id 

			SELECT @ret_status = @@error 
		END
		
		IF @ret_status <> 0 
		BEGIN 
			ROLLBACK TRAN 
			RETURN 	@ret_status 
		END 
					
		
		UPDATE 	amtrxhdr
		SET		posting_flag 	= 1
		WHERE	co_asset_id		= @co_asset_id

		SELECT @ret_status = @@error 
		IF @ret_status <> 0 
		BEGIN 
			ROLLBACK TRAN 
			RETURN 	@ret_status 
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

		SELECT @ret_status = @@error 
		IF @ret_status <> 0 
		BEGIN 
			ROLLBACK TRAN 
	 		RETURN 	@ret_status 
		END 
	 	
	 	
		UPDATE	amacthst
		SET		posting_flag 		= 1
		FROM	amacthst	ah,
				amastbk 	ab
		WHERE	ah.co_asset_book_id	= ab.co_asset_book_id
		AND		ab.co_asset_id		= @co_asset_id
		
		SELECT @ret_status = @@error 
		IF @ret_status <> 0 
		BEGIN 
			ROLLBACK TRAN 
	 		RETURN 	@ret_status 
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
	 @todays_date, 
	 1, 				
	 effective_date,
	 revised_cost, 
	 revised_accum_depr, 
	 delta_cost, 
	 delta_accum_depr, 
	 0.0, 				
	 1,
	 "",
	 0		
		FROM	#am_new_activities

		SELECT @ret_status = @@error 
		IF @ret_status <> 0 
		BEGIN 
			ROLLBACK TRAN 
	 		RETURN 	@ret_status 
		END 
		
		
		UPDATE	amvalues
		SET		posting_flag 		= 1
		FROM	amvalues	v,
				amastbk 	ab
		WHERE	v.co_asset_book_id	= ab.co_asset_book_id
		AND		ab.co_asset_id		= @co_asset_id
		AND		v.trx_type			= 50
		
		SELECT @ret_status = @@error 
		IF ( @ret_status <> 0 ) 
		BEGIN 
			ROLLBACK TRAN 
	 		RETURN 	@ret_status 
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

		SELECT @ret_status = @@error 
		IF @ret_status <> 0 
		BEGIN 
			ROLLBACK TRAN 
	 		RETURN 	@ret_status 
		END 
				
		IF @debug_level >= 3
		BEGIN
			SELECT 	* 
			FROM 	amastprf	ap,
					amastbk 	ab
			WHERE	ap.co_asset_book_id	= ab.co_asset_book_id
			AND		ab.co_asset_id		= @co_asset_id

			SELECT 	* 
			FROM 	#imastprf
		END

		
		INSERT amastprf 
		( 
				co_asset_book_id,
			 	fiscal_period_end,
			 	current_cost,
			 	accum_depr,
			 	effective_date 
		)
		SELECT 
				co_asset_book_id,
				fiscal_period_end,
				current_cost,
				accum_depr,
				effective_date 
		FROM 	#imastprf

		SELECT @ret_status = @@error 
		IF ( @ret_status <> 0 ) 
		BEGIN 
			ROLLBACK TRAN 
	 		RETURN 	@ret_status 
		END 
		
		
		UPDATE	amdprhst
		SET		posting_flag 			= 1
		FROM	#imbkinfo	tmp,
				amdprhst	dh
		WHERE	dh.co_asset_book_id		= tmp.co_asset_book_id
		AND		dh.effective_date		<= tmp.last_depr_date
		AND		tmp.last_depr_date		IS NOT NULL
		
		SELECT @ret_status = @@error 
		IF ( @ret_status <> 0 ) 
		BEGIN 
			ROLLBACK TRAN 
	 		RETURN 	@ret_status 
		END 
		
		
		UPDATE	ammandpr
		SET		posting_flag 			= 1
		FROM	#imbkinfo	tmp,
				ammandpr	md
		WHERE	md.co_asset_book_id		= tmp.co_asset_book_id
		AND		md.fiscal_period_end	<= tmp.last_depr_date
		AND		tmp.last_depr_date		IS NOT NULL
		
		SELECT @ret_status = @@error 
		IF ( @ret_status <> 0 ) 
		BEGIN 
			ROLLBACK TRAN 
	 		RETURN 	@ret_status 
		END 
		
		
		UPDATE	amastbk
		SET		last_posted_depr_date 	= tmp.last_depr_date
		FROM	#imbkinfo 	tmp,
				amastbk 	ab
		WHERE	ab.co_asset_book_id	 	= tmp.co_asset_book_id
		
		SELECT @ret_status = @@error 
		IF @ret_status <> 0 
		BEGIN 
			ROLLBACK TRAN 
	 		RETURN 	@ret_status 
		END 
		
	COMMIT TRANSACTION 

	
	DELETE 
	FROM 	#imbkinfo

	SELECT @ret_status = @@error 
	IF @ret_status <> 0 
		RETURN 	@ret_status 

	DELETE 
	FROM 	#imastprf

	SELECT @ret_status = @@error 
	IF @ret_status <> 0 
		RETURN 	@ret_status 

	DELETE 
	FROM 	#am_new_activities

	SELECT @ret_status = @@error 
	IF @ret_status <> 0 
		RETURN 	@ret_status 

	DELETE 
	FROM 	#am_new_values

	SELECT @ret_status = @@error 
	IF @ret_status <> 0 
		RETURN 	@ret_status 

END
IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/imastprm.sp" + ", line " + STR( 785, 5 ) + " -- EXIT: "

RETURN 0 
GO
GRANT EXECUTE ON  [dbo].[imPromoteAsset_sp] TO [public]
GO
