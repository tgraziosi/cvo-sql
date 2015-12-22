SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[amSaveBookDisposition_sp] 
( 
	@co_asset_book_id 		smSurrogateKey, 			
	@asset_ctrl_num 		smControlNumber, 			
	@disposition_date		smApplyDate,				
	@trx_type				smTrxType,					
	@disp_co_trx_id			smSurrogateKey,				
	@depr_co_trx_id			smSurrogateKey,				
	@depr_expense 			smMoneyZero, 				
	@accum_depr 			smMoneyZero, 				
	@depr_ytd				smMoneyZero,
	@gain_or_loss			smMoneyZero,
	@last_posted_depr_date	smApplyDate,
	@last_depr_co_trx_id	smSurrogateKey,
	@debug_level			smDebugLevel 		= 0 	
)
AS 

DECLARE 
	@result		 			smErrorCode, 				
	@message				smErrorLongDesc,			
	@rowcount				smCounter					
	
IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amsvbdsp.sp" + ", line " + STR( 71, 5 ) + " -- ENTRY: "
IF @debug_level >= 5
	SELECT 	depr_expense	= @depr_expense,
			accum_depr		= @accum_depr,
			depr_ytd		= @depr_ytd,
			gain_or_loss	= @gain_or_loss


BEGIN TRANSACTION

	UPDATE	amacthst
	SET		disposed_depr		= @depr_ytd
	WHERE	co_trx_id			= @disp_co_trx_id
	AND		co_asset_book_id	= @co_asset_book_id


	SELECT @result = @@error
	IF @result <> 0
	BEGIN
		IF @debug_level >= 1
			SELECT "Update of amacthst failed"
		ROLLBACK TRANSACTION
	 RETURN @result 
	END
	
	UPDATE 	amvalues
	SET		amount 				= - @accum_depr
	FROM	amvalues v
	WHERE	v.co_trx_id			= @disp_co_trx_id
	AND		v.co_asset_book_id	= @co_asset_book_id
	AND		v.account_type_id	= 1

	SELECT @result = @@error
	IF @result <> 0
	BEGIN
		IF @debug_level >= 1
			SELECT "Update of amvalues failed"
		ROLLBACK TRANSACTION
	 RETURN @result 
	END

	UPDATE 	amvalues
	SET		amount 				= @gain_or_loss
	FROM	amvalues v
	WHERE	v.co_trx_id			= @disp_co_trx_id
	AND		v.co_asset_book_id	= @co_asset_book_id
	AND		v.account_type_id	= 8

	SELECT @result = @@error
	IF @result <> 0
	BEGIN
		IF @debug_level >= 1
			SELECT "Update of amvalues failed"
		ROLLBACK TRANSACTION
	 RETURN @result 
	END

	UPDATE 	amvalues
	SET		amount 				= @depr_expense
	FROM	amvalues v
	WHERE	v.co_trx_id			= @depr_co_trx_id
	AND		v.co_asset_book_id	= @co_asset_book_id
	AND		v.account_type_id	= 5

	SELECT @result = @@error
	IF @result <> 0
	BEGIN
		IF @debug_level >= 1
			SELECT "Update of amvalues failed"
		ROLLBACK TRANSACTION
	 RETURN @result 
	END

	UPDATE 	amvalues
	SET		amount 				= - @depr_expense
	FROM	amvalues v
	WHERE	v.co_trx_id			= @depr_co_trx_id
	AND		v.co_asset_book_id	= @co_asset_book_id
	AND		v.account_type_id	= 1

	SELECT @result = @@error
	IF @result <> 0
	BEGIN
		IF @debug_level >= 1
			SELECT "Update of amvalues failed"
		ROLLBACK 	TRANSACTION
	 RETURN 		@result 
	END

	
	IF @trx_type = 30
	BEGIN
		UPDATE	amastbk
		SET		last_depr_co_trx_id				= @depr_co_trx_id
		FROM	amastbk	ab
		WHERE	@co_asset_book_id 			= ab.co_asset_book_id
		AND		@last_depr_co_trx_id		= ab.last_depr_co_trx_id
		AND		ab.placed_in_service_date		<= @disposition_date
		AND	 (	@last_posted_depr_date	= ab.last_posted_depr_date
				OR (	@last_posted_depr_date 		IS NULL
					AND ab.last_posted_depr_date 	IS NULL))
		
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
		FROM	amastbk	ab
		WHERE	@co_asset_book_id 		= ab.co_asset_book_id
		AND		(ab.placed_in_service_date		> @disposition_date
				OR ab.placed_in_service_date	IS NULL)
		AND	 (	@last_posted_depr_date	= ab.last_posted_depr_date
				OR (	@last_posted_depr_date 	IS NULL
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
		FROM	amastbk	ab
		WHERE	@co_asset_book_id 			= ab.co_asset_book_id
		AND		@last_depr_co_trx_id		= ab.last_depr_co_trx_id
		AND	 (	@last_posted_depr_date		= ab.last_posted_depr_date
				OR (	@last_posted_depr_date IS NULL
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

	
	IF @rowcount <> 1
	BEGIN
		IF @debug_level >= 3
		BEGIN
			SELECT	rows_updated 	= @rowcount
			SELECT 	* 
			FROM 	amastbk 
			WHERE 	co_asset_book_id = @co_asset_book_id
		END
		EXEC 		amGetErrorMessage_sp 20119, "tmp/amsvbdsp.sp", 264, @asset_ctrl_num, @error_message = @message OUT 
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

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amsvbdsp.sp" + ", line " + STR( 279, 5 ) + " -- EXIT: "

RETURN 0 
GO
GRANT EXECUTE ON  [dbo].[amSaveBookDisposition_sp] TO [public]
GO
