SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[amDeleteDisposition_sp] 
( 
	@co_asset_id 			smSurrogateKey, 	
	@disp_co_trx_id	 		smSurrogateKey, 	
	@debug_level			smDebugLevel = 0 	
)
AS 

DECLARE 
	@result		 			smErrorCode, 		
	@message				smErrorLongDesc,	
	@rowcount				smCounter,			
	@asset_ctrl_num 		smControlNumber, 	
	@disp_trx_ctrl_num		smControlNumber,	
	@depr_co_trx_id			smSurrogateKey,		
	@trx_type				smTrxType,			
	@disposition_date		smApplyDate,		
	@disp_prd_start_date	smApplyDate,		
	@back_up_to_date		smApplyDate			
	
IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amdeldsp.sp" + ", line " + STR( 71, 5 ) + " -- ENTRY: "

SELECT 	@asset_ctrl_num = asset_ctrl_num
FROM	amasset
WHERE	co_asset_id		= @co_asset_id


SELECT 	@disposition_date	= apply_date,
		@depr_co_trx_id		= linked_trx,
		@disp_trx_ctrl_num	= trx_ctrl_num,
		@trx_type			= trx_type
FROM	amtrxhdr	
WHERE	co_trx_id			= @disp_co_trx_id

IF @debug_level >= 3
	SELECT	asset_ctrl_num		= @asset_ctrl_num,
			depr_co_trx_id		= @depr_co_trx_id,
			disp_trx_ctrl_num	= @disp_trx_ctrl_num
				

IF @trx_type = 30
BEGIN
	BEGIN TRANSACTION
	
		UPDATE	amasset
		SET		activity_state		= 0,
				disposition_date	= NULL
		WHERE	co_asset_id			= @co_asset_id
		AND		activity_state		= 1

		SELECT @result = @@error, @rowcount = @@rowcount
		IF @result <> 0
		BEGIN
			IF @debug_level >= 1
				SELECT "Update of amasset failed"
			ROLLBACK 	TRANSACTION
		 RETURN 		@result 
		END

		IF @rowcount > 0 
		BEGIN

		 	
		 	DELETE
			FROM	amtrxhdr
			WHERE	co_trx_id IN (@disp_co_trx_id, @depr_co_trx_id)
			
			SELECT @result = @@error,@rowcount = @@rowcount
			IF @result <> 0
			BEGIN
				IF @debug_level >= 1
					SELECT "Delete from amtrxhdr failed"
				ROLLBACK TRANSACTION
			 RETURN @result 
			END

			UPDATE 	amtrxhdr 
			SET 	posting_flag 		= 0,
					journal_ctrl_num	= ""
			FROM 	amtrxhdr 
			WHERE 	apply_date 			<= @disposition_date
			AND		co_asset_id			= @co_asset_id 
			AND		posting_flag 		= 100
			AND		journal_ctrl_num	= @disp_trx_ctrl_num 

			SELECT @result = @@error 
			IF @result <> 0 
			BEGIN
				IF @debug_level >= 1
					SELECT "Update from amtrxhdr failed"
				ROLLBACK TRANSACTION
			 RETURN @result 
			END

			IF @debug_level >= 3
				SELECT rows_deleted = @rowcount
			
			UPDATE 	amastbk
			SET		last_depr_co_trx_id		= 0
			FROM	amastbk
			WHERE	co_asset_id				= @co_asset_id

			
			SELECT @result = @@error
			IF @result <> 0
			BEGIN
				IF @debug_level >= 1
					SELECT "Update of amastbk failed"
				ROLLBACK TRANSACTION
			 RETURN @result 
			END
		
			
			UPDATE	ammandpr 
			SET		posting_flag 				= 0
			FROM	amastbk		ab,
					ammandpr	md
			WHERE	ab.co_asset_id		 		= @co_asset_id
			AND		ab.co_asset_book_id 		= md.co_asset_book_id
			AND		ab.last_posted_depr_date	IS NULL

			SELECT @result = @@error
			IF @result <> 0
			BEGIN
				IF @debug_level >= 1
					SELECT "Update of ammandpr failed"
				ROLLBACK TRANSACTION
			 RETURN @result 
			END

			UPDATE	ammandpr 
			SET		posting_flag 				= 0
			FROM	ammandpr	md,
					amastbk		ab
			WHERE	ab.co_asset_id				= @co_asset_id
			AND		ab.co_asset_book_id 		= md.co_asset_book_id
			AND		ab.prev_posted_depr_date 	IS NOT NULL
			AND		md.fiscal_period_end		> ab.last_posted_depr_date

			SELECT @result = @@error
			IF @result <> 0
			BEGIN
				IF @debug_level >= 1
					SELECT "Update of ammandpr failed"
				ROLLBACK TRANSACTION
			 RETURN @result 
			END

			
			UPDATE	amdprhst	
			SET		posting_flag 				= 0
			FROM	amastbk		ab,
					amdprhst	dh
			WHERE	ab.co_asset_id				= @co_asset_id
			AND		ab.co_asset_book_id 		= dh.co_asset_book_id
			AND		ab.last_posted_depr_date	IS NULL

			SELECT @result = @@error
			IF @result <> 0
			BEGIN
				IF @debug_level >= 1
					SELECT "Update of amdprhst failed"
				ROLLBACK TRANSACTION
			 RETURN @result 
			END

			UPDATE	amdprhst 
			SET		posting_flag 				= 0
			FROM	amastbk		ab,
					amdprhst	dh
			WHERE	ab.co_asset_id				= @co_asset_id
			AND		ab.co_asset_book_id 		= dh.co_asset_book_id
			AND		ab.last_posted_depr_date	IS NOT NULL
			AND		dh.effective_date			> ab.last_posted_depr_date

			SELECT @result = @@error
			IF @result <> 0
			BEGIN
				IF @debug_level >= 1
					SELECT "Update of amdprhst failed"
				ROLLBACK TRANSACTION
			 RETURN @result 
			END

			
			UPDATE	amacthst 					
			SET		delta_cost					= 0.0,
					delta_accum_depr			= 0.0,
					revised_cost				= 0.0,
					revised_accum_depr			= 0.0,
					posting_flag 				= 0,
					journal_ctrl_num			= ""
			FROM	amacthst
			WHERE	journal_ctrl_num 			= @disp_trx_ctrl_num
			AND		posting_flag 				= 100

			SELECT @result = @@error
			IF @result <> 0
			BEGIN
				IF @debug_level >= 1
					SELECT "Update of amacthst failed"
				ROLLBACK TRANSACTION
			 RETURN @result 
			END
		END

	COMMIT TRANSACTION

END
ELSE	
BEGIN
	EXEC @result = amGetFiscalPeriod_sp
					@disposition_date,
					0,
					@disp_prd_start_date OUTPUT
					
	IF @result <> 0
		RETURN @result

	SELECT	@back_up_to_date	= MAX(apply_date)
	FROM	amtrxhdr
	WHERE	co_asset_id			= @co_asset_id
	AND		trx_type			= 70
	AND		co_trx_id			!= @disp_co_trx_id

	IF 	@back_up_to_date < @disp_prd_start_date
		SELECT	@back_up_to_date = @disp_prd_start_date

	BEGIN TRANSACTION
		BEGIN
			
			UPDATE	ammandpr 
			SET		posting_flag 				= 0
			FROM	amastbk		ab,
					ammandpr	md
			WHERE	ab.co_asset_id		 		= @co_asset_id
			AND		ab.co_asset_book_id 		= md.co_asset_book_id
			AND		md.fiscal_period_end		BETWEEN @back_up_to_date AND @disposition_date

			SELECT @result = @@error
			IF @result <> 0
			BEGIN
				IF @debug_level >= 1
					SELECT "Update of ammandpr failed"
				ROLLBACK TRANSACTION
			 RETURN @result 
			END

			
			UPDATE	amdprhst	
			SET		posting_flag 				= 0
			FROM	amastbk		ab,
					amdprhst	dh
			WHERE	ab.co_asset_id				= @co_asset_id
			AND		ab.co_asset_book_id 		= dh.co_asset_book_id
			AND		dh.effective_date			BETWEEN @back_up_to_date AND @disposition_date

			SELECT @result = @@error
			IF @result <> 0
			BEGIN
				IF @debug_level >= 1
					SELECT "Update of amdprhst failed"
				ROLLBACK TRANSACTION
			 RETURN @result 
			END

		END
		
		UPDATE	amacthst 					
		SET		delta_cost					= 0.0,
				delta_accum_depr			= 0.0,
				revised_cost				= 0.0,
				revised_accum_depr			= 0.0,
				posting_flag 				= 0,
				journal_ctrl_num			= ""
		FROM	amacthst
		WHERE	journal_ctrl_num 			= @disp_trx_ctrl_num
		AND		posting_flag 				= 100

		SELECT @result = @@error
		IF @result <> 0
		BEGIN
			IF @debug_level >= 1
				SELECT "Update of amacthst failed"
			ROLLBACK TRANSACTION
		 RETURN @result 
		END

	 	
	 	DELETE
		FROM	amtrxhdr
		WHERE	co_trx_id IN (@disp_co_trx_id, @depr_co_trx_id)
		
		SELECT @result = @@error,@rowcount = @@rowcount
		IF @result <> 0
		BEGIN
			IF @debug_level >= 1
				SELECT "Delete from amtrxhdr failed"
			ROLLBACK TRANSACTION
		 RETURN @result 
		END

		IF @debug_level >= 3
			SELECT rows_deleted = @rowcount
		
		
		UPDATE 	amtrxhdr 
		SET 	posting_flag 		= 0,
				journal_ctrl_num	= ""
		FROM 	amtrxhdr 
		WHERE 	apply_date 			<= @disposition_date
		AND		co_asset_id			= @co_asset_id 
		AND		posting_flag 		= 100
		AND		journal_ctrl_num	= @disp_trx_ctrl_num 

		SELECT @result = @@error 
		IF @result <> 0 
		BEGIN
			IF @debug_level >= 1
				SELECT "Update from amtrxhdr failed"
			ROLLBACK TRANSACTION
		 RETURN @result 
		END

		
		UPDATE 	amastbk
		SET		last_depr_co_trx_id		= 0				 
		FROM	amastbk
		WHERE	co_asset_id				= @co_asset_id

		
		SELECT @result = @@error
		IF @result <> 0
		BEGIN
			IF @debug_level >= 1
				SELECT "Update of amastbk failed"
			ROLLBACK TRANSACTION
		 RETURN @result 
		END

	COMMIT TRANSACTION

END

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amdeldsp.sp" + ", line " + STR( 433, 5 ) + " -- EXIT: "

RETURN 0 
GO
GRANT EXECUTE ON  [dbo].[amDeleteDisposition_sp] TO [public]
GO
