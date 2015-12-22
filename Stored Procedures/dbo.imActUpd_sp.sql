SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

 
CREATE PROCEDURE [dbo].[imActUpd_sp] 
( 
	@company_id				smallint,			
	@asset_ctrl_num			char(16),				
	@book_code				char(8),			
	@apply_date				char(8),			
	@trx_type				int, 				
	@trx_description		varchar(40) = "", 	
	@doc_reference			varchar(40) = "", 	
	@journal_ctrl_num		char(16)	= "",	
	@date_posted			char(8)		= NULL,	
	@change_in_quantity		int			= 0,	
	@last_modified_date		char(8)		= NULL,	
	@modified_by			int			= 1,	
	@account_1_amount	 	float 		= 0.0,	
	@account_2_amount		float 		= 0.0,	
	@account_3_amount		float 		= 0.0,		
	@account_4_amount		float		= 0.0,	
	@account_5_amount		float		= 0.0,	
	@account_6_amount		float 		= 0.0,	
	@account_7_amount		float 		= 0.0,	
	@account_8_amount		float 		= 0.0,	
	@account_9_amount		float 		= 0.0,	
	@account_10_amount			float 		= 0.0,	
	@stop_on_error			tinyint		= 0,	
	@debug_level			smallint	= 0		
)
AS 

DECLARE
	@result					int,				
	@is_valid				tinyint,			
	@date_posted_dt			datetime,			
	@apply_date_dt			datetime,			
	@apply_date_jul			int,				
	@co_asset_id			int,				
	@co_asset_book_id		int,				
	@disposition_date		datetime,			
	@trx_ctrl_num			char(16),	 		
	@co_trx_id				int,				
	@account_type_id		smallint,			
	@account_amount			float,				
	@str_text				varchar(255),
	@rounding_factor		float,
	@curr_precision			smallint,
	@post_to_gl				tinyint,
	@import_order			smCounter,
	@count					smCounter

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/imactupd.sp" + ", line " + STR( 103, 5 ) + " -- ENTRY: "


IF @last_modified_date IS NULL
	SELECT	@last_modified_date = CONVERT(char(8), GETDATE(), 112)
	
IF @debug_level >= 3
	SELECT last_modified_date = @last_modified_date


EXEC @result = imActVal_sp
					2,
					@company_id,
					@asset_ctrl_num,
					@book_code,
					@apply_date,			 
					@trx_type, 			 
					@trx_description,
					@doc_reference,
					@journal_ctrl_num,
					@date_posted,
					@change_in_quantity,
					@last_modified_date,			
					@modified_by,			 
					@account_1_amount,	
					@account_2_amount,	 
					@account_3_amount, 	
					@account_4_amount, 
					@account_5_amount,	 
					@account_6_amount,	 
					@account_7_amount,	 
					@account_8_amount,	 
					@account_9_amount,						
					@account_10_amount,
					@stop_on_error,		 
					@is_valid		OUTPUT,
					@debug_level	= @debug_level
IF @result <> 0
	RETURN @result

IF @is_valid = 1
BEGIN
	IF @date_posted	IS NULL
		SELECT	@date_posted_dt = NULL
	ELSE
		SELECT	@date_posted_dt = CONVERT(datetime, @date_posted)
	
	
	EXEC @result = amGetCurrencyPrecision_sp 
			@curr_precision OUTPUT,	
			@rounding_factor OUTPUT 	

	IF @result <> 0
		RETURN @result

 IF @debug_level >= 3
 	SELECT	rounding_factor = @rounding_factor

	
	SELECT	@co_asset_book_id	= ab.co_asset_book_id,
			@co_asset_id		= ab.co_asset_id,
			@disposition_date	= a.disposition_date,
			@post_to_gl			= b.post_to_gl
	FROM	amasset a,
			amastbk	ab,
			ambook b
	WHERE	a.company_id		= @company_id
	AND		a.asset_ctrl_num	= @asset_ctrl_num
	AND		a.co_asset_id		= ab.co_asset_id
	AND		ab.book_code		= @book_code
	AND		ab.book_code		= b.book_code
	AND		b.book_code			= @book_code

	
	SELECT @apply_date_dt = CONVERT(datetime, @apply_date)
	SELECT @apply_date_jul = DATEDIFF(dd, "1/1/1980", @apply_date_dt) + 722815

	IF @trx_type = 50
	BEGIN
		
		IF NOT EXISTS (SELECT 	period_end_date 
						FROM	glprd
						WHERE	period_end_date = @apply_date_jul)
		BEGIN
			EXEC	@result = amGetFiscalPeriod_sp
									@apply_date_dt,
									1,
									@apply_date_dt 	OUTPUT
		
			IF @result <> 0
				RETURN @result
		
			SELECT @apply_date = CONVERT(char(8), @apply_date_dt, 112)
		END
	END
	ELSE IF @trx_type = 30
	BEGIN
		
		IF @apply_date_dt <> @disposition_date
			SELECT @apply_date_dt = @disposition_date
	END

	
	IF @trx_type = 50
	BEGIN
		EXEC @result = amGetString_sp
						22,
						@str_text OUTPUT

		IF @result <> 0
			RETURN @result
	
		SELECT	@trx_ctrl_num	= RTRIM(@str_text) + @apply_date
		
		SELECT 	@co_trx_id 			= co_trx_id
		FROM	amtrxhdr
		WHERE	apply_date			= @apply_date_dt
		AND		company_id			= @company_id
		AND		trx_ctrl_num		= @trx_ctrl_num
		AND		trx_type			= 50
	END
	ELSE
	BEGIN
		SELECT 	@co_trx_id 			= co_trx_id
		FROM	amtrxhdr
		WHERE	co_asset_id			= @co_asset_id
		AND		apply_date			= @apply_date_dt
		AND		trx_type			= @trx_type
	END

	IF @post_to_gl = 1
	BEGIN
		
		UPDATE 	amtrxhdr
		SET		trx_description 	= @trx_description,
				doc_reference		= @doc_reference,
				date_posted			= @date_posted_dt,
				journal_ctrl_num	= @journal_ctrl_num,
				change_in_quantity	= @change_in_quantity,
				last_modified_date	= @last_modified_date,
				modified_by			= @modified_by
		WHERE	co_trx_id			= @co_trx_id
	 
	 	SELECT	@result = @@error
	 	IF @result <> 0
			RETURN @result
	END

	IF @trx_type <> 50
	BEGIN
		

		UPDATE 	amacthst 
		SET	 last_modified_date	= CONVERT(datetime, @last_modified_date),
		 modified_by			= @modified_by
	 	FROM	amacthst
		WHERE	co_trx_id			= @co_trx_id
		AND		co_asset_book_id	= @co_asset_book_id
		
		SELECT @result = @@error
		IF @result <> 0
			RETURN @result

	END

	
	SELECT 	@import_order = MIN(import_order)  
	FROM 	amtrxact
	WHERE	trx_type = @trx_type

	SELECT @count = 1

	WHILE @import_order IS NOT NULL  
	BEGIN 

		SELECT 	@account_type_id = account_type			 	
		FROM 	amtrxact
		WHERE	trx_type 		= @trx_type
		AND 	import_order 	= @import_order


		IF @count = 1
			SELECT 	@account_amount = @account_1_amount
		ELSE IF @count = 2
			SELECT @account_amount 	= @account_2_amount
		ELSE IF @count = 3
			SELECT @account_amount 	= @account_3_amount
		ELSE IF @count = 4
			SELECT @account_amount 	= @account_4_amount
		ELSE IF @count = 5
			SELECT @account_amount 	= @account_5_amount
		ELSE IF @count = 6
			SELECT @account_amount 	= @account_6_amount
		ELSE IF @count = 7
			SELECT @account_amount 	= @account_7_amount
		ELSE IF @count = 8
			SELECT @account_amount 	= @account_8_amount
		ELSE IF @count = 9
			SELECT @account_amount 	= @account_9_amount
		ELSE IF @count = 10
			SELECT @account_amount 	= @account_10_amount
		
		IF @debug_level >= 3
		 	SELECT	account_amount = @account_amount

		
		 	
		IF (ABS((@account_amount)-(0.0)) < 0.0000001)
		BEGIN
			 IF @debug_level >= 3
			 	SELECT	"Deleting amount"

				DELETE
				FROM	amvalues
				WHERE	co_trx_id			= @co_trx_id
				AND		co_asset_book_id	= @co_asset_book_id
				AND		account_type_id		= @account_type_id

				SELECT @result = @@error
				IF @result <> 0
					RETURN @result
		END
		ELSE
		BEGIN
				IF EXISTS (SELECT co_trx_id
							FROM	amvalues
							WHERE	co_trx_id			= @co_trx_id
							AND		co_asset_book_id	= @co_asset_book_id
							AND		account_type_id		= @account_type_id)
				BEGIN
			 	IF @debug_level >= 3
			 		SELECT	"Updating amount"
				 
				 UPDATE 	amvalues 
				 SET	 	amount				= @account_amount 
					FROM 	amvalues
					WHERE	co_trx_id			= @co_trx_id
					AND		co_asset_book_id	= @co_asset_book_id
					AND		account_type_id		= @account_type_id

					SELECT @result = @@error
					IF @result <> 0
						RETURN @result
										 
				END
				ELSE
				BEGIN
			 	IF @debug_level >= 3
			 		SELECT	"Inserting amount"
				 
				 INSERT amvalues 
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

				 VALUES 
				 ( 
				 	@co_trx_id,
		 	@co_asset_book_id,
		 	@account_type_id,
		 	@apply_date_dt,
		 	@trx_type, 
		 	@account_amount, 
		 	0, 			 
		 	0  
		 )
				 
				 SELECT @result = @@error
				 IF @result <> 0
				 	RETURN @result
				END
		 END 
		 		 
		 SELECT 	@import_order = 	MIN(import_order)
		 FROM 	amtrxact
		 WHERE	import_order 	> 	@import_order
		 AND		trx_type		=	@trx_type

		 SELECT @count = @count + 1
		 					 
		 
	END	
	

		 
END

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/imactupd.sp" + ", line " + STR( 421, 5 ) + " -- EXIT: "

RETURN 0
GO
GRANT EXECUTE ON  [dbo].[imActUpd_sp] TO [public]
GO
