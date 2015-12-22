SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

 
CREATE PROCEDURE [dbo].[imActIns_sp] 
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
	@debug_level		 	smallint	= 0		
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
	@acquisition_date		datetime,			
	@disposition_date		datetime,			
	@placed_date			datetime,			
	@yr_end_date			datetime,			
	@effective_date			datetime,			
	@trx_ctrl_num			char(16),			
	@co_trx_id				int,				
	@account_type_id		smallint,			
	@import_order 			smCounter,			
	@count					smCounter,
	@account_amount			float,				
	@str_text				varchar(255),
	@home_currency_code		varchar(8),			
	@rounding_factor		float,
	@curr_precision			smallint,
	@post_to_gl				tinyint				


IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/imactins.sp" + ", line " + STR( 113, 5 ) + " -- ENTRY: "

IF @last_modified_date IS NULL
	SELECT	@last_modified_date = CONVERT(char(8), GETDATE(), 112)
	

EXEC @result = imActVal_sp
					0,
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
	
	
	EXEC @result = amGetCurrencyCode_sp 
					@company_id, 
					@home_currency_code OUTPUT 
	IF @result <> 0
		RETURN @result

	
	EXEC @result = amGetCurrencyPrecision_sp 
			@curr_precision OUTPUT,	
			@rounding_factor OUTPUT 	

	IF @result <> 0
		RETURN @result

	
	SELECT	@co_asset_book_id	= ab.co_asset_book_id,
			@co_asset_id		= ab.co_asset_id,
			@acquisition_date	= a.acquisition_date,
			@disposition_date	= a.disposition_date,
			@placed_date		= ab.placed_in_service_date,
			@post_to_gl			= b.post_to_gl
	FROM	amasset a,
			amastbk	ab,
			ambook	b
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

	IF @debug_level >= 3
		SELECT	apply_date = @apply_date_dt

	IF @trx_type = 50
	BEGIN
		EXEC @result = amGetString_sp
						22,
						@str_text OUTPUT

		IF @result <> 0
			RETURN @result
	
		SELECT	@trx_ctrl_num	= RTRIM(@str_text) + @apply_date

		
		SELECT 	@co_trx_id 		= co_trx_id
		FROM	amtrxhdr
		WHERE	company_id		= @company_id
		AND		trx_ctrl_num	= @trx_ctrl_num
		AND		apply_date		= @apply_date_dt
		AND		trx_type		= @trx_type
	END
	ELSE
	BEGIN
		
		SELECT 	@co_trx_id 			= co_trx_id
		FROM	amtrxhdr	
		WHERE	co_asset_id 		= @co_asset_id
		AND		apply_date			= @apply_date_dt
		AND		trx_type			= @trx_type

	END

	IF @co_trx_id IS NULL
	BEGIN
		
		EXEC @result = amNextKey_sp 	7, 
	 	@co_trx_id OUTPUT 

		IF @result <> 0
		 RETURN @result 

		IF @trx_type != 50
		BEGIN
			EXEC @result = amNextControlNumber_sp
							@company_id,
							5,
							@trx_ctrl_num OUTPUT,
							@debug_level

			IF @result <> 0
			 	RETURN @result 
		END

		
		
		IF @post_to_gl = 0
			SELECT	
				@trx_description 	= "",
				@doc_reference		= "",
				@journal_ctrl_num	= "",
				@date_posted_dt		= NULL,
				@change_in_quantity	= 0
		
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

		VALUES 
		( 
			@company_id,
			@trx_ctrl_num,
			@journal_ctrl_num,
			@co_trx_id,
			@trx_type,
			0,				
			"",				
			@last_modified_date,
			@modified_by,
			@apply_date_dt,
			0,				
			@date_posted_dt,		
			0,					
			@trx_description,
			@doc_reference,
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
			2,
			@co_asset_id,
			0,
			0,
			@change_in_quantity
		)						
		
		SELECT @result = @@error
		IF @result <> 0
			RETURN @result

	END
	ELSE
	BEGIN
		IF @post_to_gl = 1
		BEGIN
			UPDATE amtrxhdr
			SET
				trx_description 	= @trx_description,
				doc_reference 		= @doc_reference,
				journal_ctrl_num	= @journal_ctrl_num,
				date_posted			= @date_posted_dt,
				change_in_quantity	= @change_in_quantity
			FROM	amtrxhdr
			WHERE	co_trx_id		= @co_trx_id

			SELECT @result = @@error
			IF @result <> 0
				RETURN @result
		END
	END

	IF @trx_type <> 50
	BEGIN
		IF @placed_date IS NULL
			SELECT	@effective_date = NULL
		ELSE
		BEGIN
			EXEC @result = amGetFiscalYear_sp 
							@placed_date,
					 		1,
							@yr_end_date OUTPUT 

			IF ( @result <> 0 )
				RETURN @result 
			
			IF @apply_date_dt <= @yr_end_date
				SELECT	@effective_date = @acquisition_date
			ELSE
			BEGIN
				EXEC @result = amGetFiscalPeriod_sp 
									@apply_date_dt, 
									0, 
									@effective_date OUT 

				IF (@result <> 0)
					RETURN @result 
				
		 	
			END	
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

		VALUES 
		( 
				@co_trx_id,
		 	@co_asset_book_id,
		 	@apply_date_dt,
		 	@trx_type,
		 	CONVERT(datetime, @last_modified_date), 	 
		 @modified_by,
		 @effective_date, 
		 0.0, 	 
		 0.0, 	 
		 0.0, 	 
		 0.0, 	 
		 0.0, 	 
		 0, 	 
		 @journal_ctrl_num, 	
		 0		 		
		)
		
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

		IF (ABS((@account_amount)-(0.0)) > 0.0000001)
		BEGIN

			SELECT 	@account_type_id = account_type			 	
			FROM 	amtrxact
			WHERE	trx_type 		= @trx_type
			AND 	import_order 	= @import_order

			
		
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

		SELECT 	@import_order = 	MIN(import_order)
			FROM 	amtrxact
			WHERE	import_order 	> 	@import_order
			AND		trx_type		=	@trx_type

		SELECT @count = @count + 1

	END	
							 
	 		 	
 END

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/imactins.sp" + ", line " + STR( 569, 5 ) + " -- EXIT: "

RETURN 0
GO
GRANT EXECUTE ON  [dbo].[imActIns_sp] TO [public]
GO
