SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[amCopyAssetBook_sp]
(
	@co_asset_id			smSurrogateKey,			
	@new_book_code			smBookCode,				
	@old_book_code			smBookCode,				
	@copy_rules				smLogical,				
	@depr_to_date			smApplyDate		OUTPUT,	
	@user_id				smUserID,				
	@debug_level			smDebugLevel	= 0		
) 
AS

DECLARE 
	@result					smErrorCode,
	@message				smErrorLongDesc,
	@num_dispositions		smCounter,
	@todays_date			smApplyDate,
	@new_co_asset_book_id	smSurrogateKey,
	@old_co_asset_book_id	smSurrogateKey,
	@category_code			smCategoryCode,
	@acquisition_date		smApplyDate,
	@placed_date			smApplyDate,
	@last_posted_depr_date	smApplyDate,
	@cur_precision 			smallint,			
	@rounding_factor 		float,				
	@rowcount1				smCounter

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amcpyabk.sp" + ", line " + STR( 92, 5 ) + " -- ENTRY: "

 
EXEC @result = amGetCurrencyPrecision_sp 
						@cur_precision 		OUTPUT,
						@rounding_factor 	OUTPUT 

SELECT @todays_date = GETDATE()

IF @copy_rules = 0
BEGIN
	SELECT 	@category_code 			= category_code,
			@acquisition_date		= acquisition_date
	FROM	amasset			
	WHERE	co_asset_id				= @co_asset_id
END

SELECT 	@old_co_asset_book_id 	= co_asset_book_id,
		@placed_date			= placed_in_service_date,
		@last_posted_depr_date	= last_posted_depr_date
FROM	amastbk			
WHERE	co_asset_id				= @co_asset_id
AND		book_code				= @old_book_code
	

CREATE TABLE #disp_amounts
(
	co_trx_id		int,
	apply_date		datetime,
	trx_type		int,
	cost			float,
	proceeds		float,
	cost_of_removal	float
)

IF 	@depr_to_date	IS NOT NULL
BEGIN
	IF @depr_to_date != @last_posted_depr_date
	BEGIN
		INSERT INTO #disp_amounts
		(
			co_trx_id,
			apply_date,
			trx_type,
			cost,
			proceeds,
			cost_of_removal
		)
		SELECT DISTINCT
			co_trx_id,
			apply_date,
			trx_type,
			0.0,
			0.0,
			0.0
		FROM	amacthst
		WHERE	co_asset_book_id 	= @old_co_asset_book_id
		AND		trx_type			IN (60, 30, 70)
		AND		apply_date			> @depr_to_date

		SELECT @num_dispositions = @@rowcount, @result = @@error
		IF @result <> 0 
			RETURN @result 
	END
END
ELSE
BEGIN
	INSERT INTO #disp_amounts
	(
		co_trx_id,
		apply_date,
		trx_type,
		cost,
		proceeds,
		cost_of_removal
	)
	SELECT DISTINCT
		co_trx_id,
		apply_date,
		trx_type,
		0.0,
		0.0,
		0.0
	FROM	amacthst
	WHERE	co_asset_book_id 	= @old_co_asset_book_id
	AND		trx_type			IN (60, 30, 70)

	SELECT @num_dispositions = @@rowcount, @result = @@error
	IF @result <> 0 
		RETURN @result 
END


IF @num_dispositions > 0
BEGIN

	IF @debug_level >= 5
	BEGIN
		SELECT 	"About to update the dispositions in #disp_amounts"
		SELECT	* 
		FROM 	#disp_amounts

	END

	UPDATE 	#disp_amounts
	SET		cost 				= amount
	FROM	#disp_amounts tmp,
			amvalues v
	WHERE	tmp.co_trx_id		= v.co_trx_id
	AND		v.co_asset_book_id 	= @old_co_asset_book_id
	AND		v.account_type_id 	= 0
	AND		v.trx_type 			IN (30, 70)


	SELECT @result = @@error
	IF @result <> 0 
		RETURN @result 

	UPDATE 	#disp_amounts
	SET		proceeds 			= amount
	FROM	#disp_amounts tmp,
			amvalues v
	WHERE	tmp.co_trx_id		= v.co_trx_id
	AND		v.co_asset_book_id 	= @old_co_asset_book_id
	AND		v.account_type_id	= 4
	AND		v.trx_type 			IN (30, 70)

	SELECT @result = @@error
	IF @result <> 0 
		RETURN @result 

	UPDATE 	#disp_amounts
	SET		cost_of_removal		= amount
	FROM	#disp_amounts tmp,
			amvalues v
	WHERE	tmp.co_trx_id		= v.co_trx_id
	AND		v.co_asset_book_id 	= @old_co_asset_book_id
	AND		v.account_type_id	= 6
	AND		v.trx_type 			IN (30, 70)

	SELECT @result = @@error
	IF @result <> 0 
		RETURN @result 

END

 
EXEC @result = amNextKey_sp 
				6, 
				@new_co_asset_book_id OUTPUT

IF @result <> 0 
	RETURN @result 

IF @debug_level >= 4
BEGIN
	SELECT 	 new_co_asset_book_id 	= @new_co_asset_book_id,
			 old_co_asset_book_id	= @old_co_asset_book_id
END



BEGIN TRANSACTION

	IF @depr_to_date IS NOT NULL
	BEGIN
		

		INSERT INTO amastbk 
		(
			co_asset_id,
			book_code,
			co_asset_book_id,
			orig_salvage_value,
			orig_amount_expensed,
			orig_amount_capitalised,
			placed_in_service_date,
			last_posted_activity_date,
			next_entered_activity_date,
			last_posted_depr_date,
			prev_posted_depr_date,
			first_depr_date,
			last_modified_date,
			proceeds,
			gain_loss,
			last_depr_co_trx_id,
			process_id 
		)
		SELECT 
			co_asset_id,
			@new_book_code,
			@new_co_asset_book_id,
			orig_salvage_value,
			orig_amount_expensed,
			orig_amount_capitalised,
			placed_in_service_date,
			last_posted_activity_date,
			next_entered_activity_date,
			NULL, 
			NULL,					
			first_depr_date,
			@todays_date,
			proceeds,
			gain_loss,
			0,
			process_id 
		FROM 	amastbk 	ab
		WHERE	ab.co_asset_book_id		= @old_co_asset_book_id

		SELECT @result = @@error 
		IF @result <> 0 
		BEGIN
			ROLLBACK TRANSACTION
			RETURN @result 
		END
 END
 ELSE
 BEGIN
		
		INSERT INTO amastbk 
		(
			co_asset_id,
			book_code,
			co_asset_book_id,
			orig_salvage_value,
			orig_amount_expensed,
			orig_amount_capitalised,
			placed_in_service_date,
			last_posted_activity_date,
			next_entered_activity_date,
			last_posted_depr_date,
			prev_posted_depr_date,
			first_depr_date,
			last_modified_date,
			proceeds,
			gain_loss,
			last_depr_co_trx_id,
			process_id 
		)
		SELECT 
			co_asset_id,
			@new_book_code,
			@new_co_asset_book_id,
			orig_salvage_value,
			orig_amount_expensed,
			orig_amount_capitalised,
			placed_in_service_date,
			NULL,
			next_entered_activity_date,
			NULL,
			NULL,
			NULL,
			@todays_date,
			0.0,
			0.0,
			0,
			0 
		FROM 	amastbk 	ab
		WHERE	ab.co_asset_book_id		= @old_co_asset_book_id

		SELECT @result = @@error 
		IF @result <> 0 
		BEGIN
			ROLLBACK TRANSACTION
			RETURN @result 
		END
 	END

	IF @debug_level >= 5
		SELECT 	"About to populate amdprhst"

	IF @copy_rules = 1
	BEGIN
		
		INSERT INTO amdprhst
		(
			co_asset_book_id,
			effective_date,
			last_modified_date,
			modified_by,
			posting_flag,
			depr_rule_code,
			limit_rule_code,
			salvage_value,
			catch_up_diff,
			end_life_date,
			switch_to_sl_date
		)
		SELECT
			@new_co_asset_book_id,
			effective_date,
			@todays_date,
			@user_id,
			posting_flag,
			depr_rule_code,
			limit_rule_code,
			salvage_value,
			catch_up_diff,
			end_life_date,
			switch_to_sl_date
		FROM 	amdprhst 	dh
		WHERE	dh.co_asset_book_id		= @old_co_asset_book_id

		SELECT @result = @@error 
		IF @result <> 0 
		BEGIN
			ROLLBACK TRANSACTION
			RETURN @result 
		END
	END
	ELSE
	BEGIN
		EXEC @result = amCreateNewRule_sp 
						 @new_co_asset_book_id,
							@new_book_code,
							@acquisition_date,
							@category_code,
							@user_id,
							@placed_date,
							@debug_level

		IF @result <> 0 
		BEGIN
			ROLLBACK TRANSACTION
			RETURN @result 
		END

	END

	IF @debug_level >= 5
		SELECT 	"About to populate amacthst"

	IF @depr_to_date IS NULL
	BEGIN
		
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
			co_trx_id,
			@new_co_asset_book_id,
			apply_date,
			trx_type,
			@todays_date,
			@user_id,
			effective_date,
			0.0,
			0.0,
			0.0,
			0.0,
			percent_disposed,
			0,
			"",
			created_by_trx,
			0.0 
		FROM	amacthst ah
		WHERE	ah.co_asset_book_id = @old_co_asset_book_id

		SELECT @result = @@error 
		IF @result <> 0 
		BEGIN
			ROLLBACK TRANSACTION
			RETURN @result 
		END
	END
	ELSE
	BEGIN

		
		
		UPDATE amastbk
		SET last_posted_depr_date = @depr_to_date
		WHERE co_asset_book_id = @new_co_asset_book_id

		SELECT @result = @@error 
		IF @result <> 0 
		BEGIN
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
			co_trx_id,
			@new_co_asset_book_id,
			apply_date,
			trx_type,
			@todays_date,
			@user_id,
			effective_date,
			revised_cost,
			revised_accum_depr,
			delta_cost,
			delta_accum_depr,
			percent_disposed,
			1,				
			"",
			created_by_trx,
			disposed_depr 
		FROM	amacthst ah
		WHERE	ah.co_asset_book_id = @old_co_asset_book_id
		AND		apply_date			<= @depr_to_date

		SELECT @result = @@error 
		IF @result <> 0 
		BEGIN
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
			co_trx_id,
			@new_co_asset_book_id,
			apply_date,
			trx_type,
			@todays_date,
			@user_id,
			effective_date,
			0.0,
			0.0,
			0.0,
			0.0,
			percent_disposed,
			0,
			"",
			created_by_trx,
			0.0 
		FROM	amacthst ah
		WHERE	ah.co_asset_book_id = @old_co_asset_book_id
		AND		apply_date			> @depr_to_date

		SELECT @result = @@error 
		IF @result <> 0 
		BEGIN
			ROLLBACK TRANSACTION
			RETURN @result 
		END

	END

	IF @debug_level >= 5
		SELECT 	"About to populate amvalues"

	IF @depr_to_date IS NULL
	BEGIN

		
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
			@new_co_asset_book_id,
			account_type_id,
			apply_date,
			trx_type,
			amount,
			0,
			0
		FROM	amvalues v
		WHERE	v.co_asset_book_id 	= @old_co_asset_book_id
		AND		trx_type 			!= 50

		SELECT @result = @@error 
		IF @result <> 0 
		BEGIN
			ROLLBACK TRANSACTION
			RETURN @result 
		END

	END
	ELSE
	BEGIN
		
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
			@new_co_asset_book_id,
			account_type_id,
			apply_date,
			trx_type,
			amount,
			account_id,
			1
		FROM	amvalues v
		WHERE	v.co_asset_book_id 	= @old_co_asset_book_id
		AND		apply_date			<= @depr_to_date

		SELECT @result = @@error 
		IF @result <> 0 
		BEGIN
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
			co_trx_id,
			@new_co_asset_book_id,
			account_type_id,
			apply_date,
			trx_type,
			amount,
			0,
			0
		FROM	amvalues v
		WHERE	v.co_asset_book_id 	= @old_co_asset_book_id
		AND		trx_type 			!= 50
		AND		apply_date			> @depr_to_date

		SELECT @result = @@error 
		IF @result <> 0 
		BEGIN
			ROLLBACK TRANSACTION
			RETURN @result 
		END
	
	END
	
 	IF @num_dispositions > 0
 	BEGIN

		IF @debug_level >= 5
			SELECT 	"About to update the dispositions in amvalues"
	
		
		UPDATE 	amvalues
		SET	 	amount 				= 0.0
		FROM	#disp_amounts tmp,
				amvalues v
		WHERE	v.co_asset_book_id 	= @new_co_asset_book_id
		AND		v.co_trx_id			= tmp.co_trx_id
		AND		v.trx_type			= 60
		AND		tmp.trx_type		= 60
		
		SELECT @result = @@error 
		IF @result <> 0 
		BEGIN
			ROLLBACK TRANSACTION
			RETURN @result 
		END

 		
 		
 		UPDATE 	amvalues
		SET	 	amount 				= 0.0
		FROM	#disp_amounts tmp,
				amvalues v
		WHERE	v.co_asset_book_id 	= @new_co_asset_book_id
		AND		v.co_trx_id			= tmp.co_trx_id
		AND		v.trx_type			IN (30, 70)
		AND		tmp.trx_type		IN (30, 70)
		AND		v.account_type_id	= 1
	
		SELECT @result = @@error 
		IF @result <> 0 
		BEGIN
			ROLLBACK TRANSACTION
			RETURN @result 
		END
		
		
		UPDATE 	amvalues
		SET		amount				= (SIGN(-cost - proceeds - cost_of_removal) * ROUND(ABS(-cost - proceeds - cost_of_removal) + 0.0000001, @cur_precision))	
		FROM	#disp_amounts tmp,
				amvalues v
		WHERE	v.co_asset_book_id 	= @new_co_asset_book_id
		AND		v.co_trx_id			= tmp.co_trx_id
		AND		v.trx_type			IN (30, 70)
		AND		tmp.trx_type		IN (30, 70)
		AND		account_type_id		= 8
	
		SELECT @rowcount1 = @@rowcount, @result = @@error 
		IF @result <> 0 
		BEGIN
			ROLLBACK TRANSACTION
			RETURN @result 
		END

		IF @rowcount1 <> @num_dispositions
		BEGIN
			
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
				tmp.co_trx_id,
				@new_co_asset_book_id,
				8,
				tmp.apply_date,
				tmp.trx_type,
				(SIGN(-tmp.cost - tmp.proceeds - tmp.cost_of_removal) * ROUND(ABS(-tmp.cost - tmp.proceeds - tmp.cost_of_removal) + 0.0000001, @cur_precision)),
				0,
				0
			FROM	#disp_amounts tmp
			WHERE	tmp.trx_type 	IN (30, 70) 
			AND		tmp.co_trx_id 	NOT IN 	(SELECT v.co_trx_id
												FROM	#disp_amounts tmp,
														amvalues v
												WHERE	tmp.co_trx_id		= v.co_trx_id
												AND		v.co_asset_book_id	= @new_co_asset_book_id
												AND		v.account_type_id	= 8)

			SELECT @result = @@error 
			IF @result <> 0 
			BEGIN
				ROLLBACK TRANSACTION
				RETURN @result 
			END
		END
	END
	
	IF @debug_level >= 5
		SELECT 	"About to populate amastprf"

	IF @depr_to_date IS NOT NULL
	BEGIN
		
		INSERT INTO amastprf
		(
			co_asset_book_id,
			fiscal_period_end,
			current_cost,
			accum_depr,
			effective_date
		)
		SELECT
			@new_co_asset_book_id,
			fiscal_period_end,
			current_cost,
			accum_depr,
			effective_date
		FROM	amastprf ap
		WHERE	ap.co_asset_book_id = @old_co_asset_book_id
		AND		fiscal_period_end	<= @depr_to_date

		SELECT @result = @@error 
		IF @result <> 0 
		BEGIN
			ROLLBACK TRANSACTION
			RETURN @result 
		END

	END

COMMIT TRANSACTION

DROP TABLE #disp_amounts

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amcpyabk.sp" + ", line " + STR( 875, 5 ) + " -- EXIT: "

RETURN 0
GO
GRANT EXECUTE ON  [dbo].[amCopyAssetBook_sp] TO [public]
GO
