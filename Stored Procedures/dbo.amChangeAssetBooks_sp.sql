SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[amChangeAssetBooks_sp] 
(
 @co_asset_id 	smSurrogateKey, 		
	@category_code 			smCategoryCode, 		
	@old_acq_date			smApplyDate,			
	@acq_date 				smApplyDate, 			 
	@placed_date 			smApplyDate, 			 
	@cost					smMoneyZero,			
	@user_id 				smUserID, 				
	@activity_state			smSystemState,			
	@debug_level			smDebugLevel	= 0		
)
AS 

DECLARE 
	@result					smErrorCode,
	@message 				smErrorLongDesc,
	@rowcount				smCounter,
	@book_to_copy			smSurrogateKey,
	@co_trx_id				smSurrogateKey,			
	@book_code 				smBookCode, 
	@co_asset_book_id 		smSurrogateKey, 
	@salvage 				smMoneyZero,
	@yr_end_date			smApplyDate,			 
	@apply_date				smApplyDate,			
	@effective_date			smApplyDate, 			
	@old_depr_rule_code		smDeprRuleCode,			
	@new_depr_rule_code		smDeprRuleCode			
 
IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amchasbk.sp" + ", line " + STR( 94, 5 ) + " -- ENTRY: " 


SELECT 	@book_code 		= MIN(book_code)
FROM 	amastbk
WHERE	co_asset_id		= @co_asset_id 

	
IF @debug_level >= 3
	SELECT copy_book_code = @book_code 

SELECT 	@book_to_copy 	= co_asset_book_id
FROM 	amastbk
WHERE	co_asset_id		= @co_asset_id
AND		book_code		= @book_code 


 
SELECT 	@book_code 		= MIN(book_code)
FROM 	amcatbk 
WHERE 	category_code 	= @category_code 
AND		effective_date	<= @acq_date

 
WHILE @book_code IS NOT NULL 
BEGIN 
	
	IF @debug_level >= 3
		SELECT book_code = @book_code 

	SELECT	@co_asset_book_id = 0
	
	SELECT	@co_asset_book_id 	= co_asset_book_id
	FROM	amastbk
	WHERE	co_asset_id			= @co_asset_id
	AND		book_code			= @book_code

	IF @co_asset_book_id = 0
	BEGIN
		
		IF @activity_state = 100
		BEGIN
			 
			EXEC @result = amNextKey_sp 
							6, 
							@co_asset_book_id OUTPUT

			IF @result <> 0 
				RETURN @result 

			INSERT INTO amastbk 
			(
					co_asset_id,
					book_code,
					co_asset_book_id,
					orig_salvage_value,
					orig_amount_capitalised,
					next_entered_activity_date,
					placed_in_service_date
			)
			VALUES 
			(
					@co_asset_id, 
					@book_code,
					@co_asset_book_id,
					0,
					@cost,
					@acq_date,
					@placed_date
			)

			SELECT @result = @@error 
			IF @result <> 0 
				RETURN @result 

			
			EXEC @result = amCreateNewRule_sp
							@co_asset_book_id,
							@book_code,
							@acq_date,
							@category_code,
							@user_id,
							@placed_date

			IF @result <> 0
				RETURN @result
								
			
			UPDATE	amastbk
			SET		orig_salvage_value 	= salvage_value
			FROM	amdprhst dh,
					amastbk ab
			WHERE	ab.co_asset_book_id	= @co_asset_book_id
			AND		dh.co_asset_book_id	= ab.co_asset_book_id
			AND		dh.effective_date	= @acq_date	
			
			SELECT @result = @@error 
			IF @result <> 0 
				RETURN @result 

			
			IF @placed_date IS NULL
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
					created_by_trx			
				)
				SELECT
					co_trx_id, 	 
					@co_asset_book_id, 	 
					apply_date, 			
					trx_type, 				
					GETDATE(), 			
					@user_id, 	
					NULL,	
					revised_cost, 			
					revised_accum_depr,				 
				 	delta_cost, 						
					delta_accum_depr,					 
					percent_disposed, 			
					posting_flag,			 
					journal_ctrl_num,						
					created_by_trx			
				FROM	amacthst
				WHERE	co_asset_book_id	= @book_to_copy

				SELECT @result = @@error
				IF @result <> 0 
					RETURN @result 
			END
			ELSE
			BEGIN
				EXEC @result = amGetFiscalYear_sp 
								@placed_date,
						 		1,
								@yr_end_date OUTPUT 

				IF ( @result <> 0 )
					RETURN @result 


				
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
					@co_asset_book_id, 	 
					apply_date, 			
					trx_type, 				
					GETDATE(), 			
					@user_id, 	
					@acq_date,	
					revised_cost, 			
					revised_accum_depr,				 
				 	delta_cost, 						
					delta_accum_depr,					 
					percent_disposed, 			
					posting_flag,			 
					journal_ctrl_num,						
					created_by_trx			
				FROM	amacthst
				WHERE	co_asset_book_id	= @book_to_copy
				AND		apply_date			<= @yr_end_date

				SELECT @result = @@error
				IF @result <> 0 
					RETURN @result 

				
				SELECT 	@co_trx_id			= MIN(co_trx_id)
				FROM	amacthst
				WHERE	co_asset_book_id	= @book_to_copy
				AND		apply_date			> @yr_end_date

				WHILE @co_trx_id IS NOT NULL
				BEGIN
					SELECT 	@apply_date 		= apply_date
					FROM	amacthst
					WHERE	co_trx_id			= @co_trx_id
					AND		co_asset_book_id 	= @book_to_copy
					
					EXEC @result = amGetFiscalPeriod_sp 
										@apply_date, 
										0, 
										@effective_date OUT 

					IF (@result <> 0)
						RETURN @result 
					
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
						@co_asset_book_id, 	 
						apply_date, 			
						trx_type, 				
						GETDATE(), 			
						@user_id, 	
						@effective_date,	
						revised_cost, 			
						revised_accum_depr,				 
					 	delta_cost, 						
						delta_accum_depr,					 
						percent_disposed, 			
						posting_flag,			 
						journal_ctrl_num,						
						created_by_trx			
					FROM	amacthst
					WHERE	co_asset_book_id	= @book_to_copy
					AND		co_trx_id			= @co_trx_id

					SELECT @result = @@error
					IF @result <> 0 
						RETURN @result 

					SELECT 	@co_trx_id			= MIN(co_trx_id)
					FROM	amacthst
					WHERE	co_asset_book_id	= @book_to_copy
					AND		apply_date			> @yr_end_date
					AND		co_trx_id			> @co_trx_id
				END
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
					@co_asset_book_id, 	 
			 account_type_id, 
			 apply_date, 
			 trx_type, 
			 amount, 
			 account_id,			 
			 posting_flag		 
			FROM	amvalues
			WHERE	co_asset_book_id	= @book_to_copy

			SELECT @result = @@error
			IF @result <> 0 
				RETURN @result 

		END
	END
	ELSE 
	BEGIN
		

		SELECT @effective_date = @old_acq_date
		
		IF @acq_date > @effective_date
			SELECT	@effective_date = @acq_date
			
		DELETE 
		FROM 	amdprhst
		WHERE	co_asset_book_id 	= @co_asset_book_id
		AND		effective_date		<= @effective_date
		
		SELECT	@result = @@error
		IF @result <> 0
			RETURN @result

		EXEC @result = amCreateNewRule_sp
						@co_asset_book_id,
						@book_code,
						@acq_date,
						@category_code,
						@user_id,
						@placed_date

		IF @result <> 0
			RETURN @result
							
		
		UPDATE	amastbk
		SET		orig_salvage_value 	= salvage_value
		FROM	amdprhst dh,
				amastbk ab
		WHERE	ab.co_asset_book_id	= @co_asset_book_id
		AND		dh.co_asset_book_id	= ab.co_asset_book_id
		AND		dh.effective_date	= @acq_date	
		
		SELECT @result = @@error 
		IF @result <> 0 
			RETURN @result 

	END

	 
	SELECT 	@book_code 		= MIN(book_code)
	FROM 	amcatbk 
	WHERE 	category_code 	= @category_code 
	AND		effective_date	<= @acq_date
	AND		book_code		> @book_code
END 


DELETE	
FROM	amastbk 
WHERE	co_asset_id 	= @co_asset_id
AND		book_code		NOT IN (SELECT 	book_code
								FROM 	amcatbk
								WHERE	category_code 	= @category_code
								AND		effective_date	<= @acq_date)



IF NOT EXISTS(SELECT 	book_code
				FROM	amastbk
				WHERE	co_asset_id = @co_asset_id)
BEGIN
	DELETE 
	FROM	amtrxhdr
	WHERE	co_asset_id = @co_asset_id

	SELECT @result = @@error
	IF @result <> 0
		RETURN @result
END

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amchasbk.sp" + ", line " + STR( 520, 5 ) + " -- EXIT: " 

RETURN 0
GO
GRANT EXECUTE ON  [dbo].[amChangeAssetBooks_sp] TO [public]
GO
