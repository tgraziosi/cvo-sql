SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

 
CREATE PROCEDURE [dbo].[imActDel_sp] 
( 
	@company_id				smallint,			
	@asset_ctrl_num			char(16),				
	@book_code				char(8),			
	@apply_date				char(8),			
	@trx_type				int,				
	@stop_on_error			tinyint		= 0,	
	@debug_level			smallint	= 0		
)
AS 

DECLARE
	@result					int,				
	@is_valid				tinyint,			
	@apply_date_dt			datetime,			
	@apply_date_jul			int,				
	@co_asset_book_id		int,				
	@co_trx_id				int,				
	@disposition_date		datetime			

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/imactdel.sp" + ", line " + STR( 72, 5 ) + " -- ENTRY: "


EXEC @result = imActVal_sp
					@action 		= 1,
					@company_id		= @company_id,
					@asset_ctrl_num	= @asset_ctrl_num,
					@book_code		= @book_code,
					@apply_date		= @apply_date,	
					@trx_type		= @trx_type,
					@stop_on_error	= @stop_on_error,		 
					@is_valid 		= @is_valid		OUTPUT,
					@debug_level	= @debug_level
IF @result <> 0
	RETURN @result

IF @is_valid = 1
BEGIN
	
	SELECT	@co_asset_book_id	= ab.co_asset_book_id,
			@disposition_date	= disposition_date
	FROM	amasset a,
			amastbk	ab
	WHERE	a.company_id		= @company_id
	AND		a.asset_ctrl_num	= @asset_ctrl_num
	AND		a.co_asset_id		= ab.co_asset_id
	AND		ab.book_code		= @book_code

	
	SELECT @apply_date_dt = CONVERT(datetime, @apply_date)
	SELECT @apply_date_jul = DATEDIFF(dd, "1/1/1980", @apply_date_dt) + 722815

	IF @trx_type = 50
	BEGIN
		
		IF NOT EXISTS (SELECT 	period_start_date 
						FROM	glprd
						WHERE	period_start_date = @apply_date_jul)
		BEGIN
			EXEC	@result = amGetFiscalPeriod_sp
									@apply_date_dt,
									1,
									@apply_date_dt 	OUTPUT
		
			IF @result <> 0
				RETURN @result

		END
	END
	ELSE IF @trx_type = 30
	BEGIN
		
		IF @apply_date_dt <> @disposition_date
			SELECT @apply_date_dt = @disposition_date
	END

	
	IF @trx_type = 50
	BEGIN
		
		DELETE 	 
		FROM	amvalues
		WHERE	apply_date			= @apply_date_dt
		AND		co_asset_book_id	= @co_asset_book_id
		AND		trx_type			= 50
		
		SELECT @result = @@error
		IF @result <> 0
			RETURN @result
	END
	ELSE
	BEGIN
		IF @debug_level >= 3
			SELECT	apply_date 			= @apply_date_dt, 
					co_asset_book_id 	= @co_asset_book_id
	
		SELECT	@co_trx_id	 		= co_trx_id
		FROM	amacthst
		WHERE	co_asset_book_id	= @co_asset_book_id
		AND		apply_date			= @apply_date_dt
		AND		trx_type			= @trx_type
		
		
		IF EXISTS(SELECT	co_asset_book_id
					FROM	amacthst
					WHERE	co_trx_id			= @co_trx_id
					AND		co_asset_book_id	<> @co_asset_book_id)
					
		BEGIN
			
			DELETE 	 
			FROM	amacthst
			WHERE	co_trx_id			= @co_trx_id
			AND		co_asset_book_id	= @co_asset_book_id
			
			SELECT @result = @@error
			IF @result <> 0
				RETURN @result
		END
		ELSE
		BEGIN
			
			DELETE
			FROM	amtrxhdr
			WHERE	co_trx_id	= @co_trx_id
			
			SELECT @result = @@error
			IF @result <> 0
				RETURN @result
		END
	END

END

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/imactdel.sp" + ", line " + STR( 209, 5 ) + " -- EXIT: "

RETURN 0
GO
GRANT EXECUTE ON  [dbo].[imActDel_sp] TO [public]
GO
