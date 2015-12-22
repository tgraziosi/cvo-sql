SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

 
CREATE PROCEDURE [dbo].[imActVal_sp] 
( 
	@action					smallint,			
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
	@is_valid				tinyint 	OUTPUT,	
	@debug_level			smallint	= 0		
)
AS 

DECLARE
	@result					int,			
	@does_exist				tinyint,		
	@param1					varchar(255),	
	@message				varchar(255),	
	@apply_date_dt			datetime,		
	@apply_date_jul			int,			
	@trx_ctrl_num			char(16),		
	@co_trx_id				int,			
	@co_asset_id			int,			
	@co_asset_book_id		int,			
	@activity_state			int,			
	@acquisition_date		datetime,		
	@disposition_date		datetime,		
	@placed_in_service_date	datetime,		
	@last_posted_depr_date	datetime,		
	@cur_prd_end			datetime,		
	@is_imported			tinyint,		
	@is_new					tinyint,		
	@activity_sum			float,			
	@cur_precision 			smallint,		
	@round_factor 			float,			
	@str_text				smStringText,	
	@str_id					smCounter,		
	@cur_trx_type			tinyint			

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/imactval.sp" + ", line " + STR( 155, 5 ) + " -- ENTRY: "

SELECT 	@is_valid 			= 1,
		@acquisition_date 	= NULL

SELECT 	@apply_date_dt = CONVERT(datetime, @apply_date)
SELECT 	@apply_date_jul = DATEDIFF(dd, "1/1/1980", @apply_date_dt) + 722815


EXEC @result = amassetExists_sp
					@company_id, 
					@asset_ctrl_num, 
					@does_exist 	OUTPUT
IF @result <> 0
	RETURN @result

IF @does_exist = 0 
BEGIN
	EXEC 		amGetErrorMessage_sp 
							21160, "tmp/imactval.sp", 176, 
							@asset_ctrl_num, 
							@error_message = @message OUT 
	IF @message IS NOT NULL RAISERROR 	21160 @message 
	SELECT 		@is_valid = 0

	IF @stop_on_error = 1
		RETURN 0
END
ELSE 
BEGIN
	
	SELECT	@co_asset_id			= co_asset_id,
			@activity_state			= activity_state,
			@acquisition_date		= acquisition_date,
			@disposition_date		= disposition_date,
			@is_imported			= is_imported,
			@is_new					= is_new
	FROM	amasset
	WHERE	company_id				= @company_id
	AND		asset_ctrl_num			= @asset_ctrl_num

	IF @activity_state <> 100
	BEGIN
		EXEC 		amGetErrorMessage_sp 
								21153, "tmp/imactval.sp", 203, 
								@asset_ctrl_num, @book_code, @apply_date, 
								@error_message = @message OUT 
		IF @message IS NOT NULL RAISERROR 	21153 @message 
		SELECT 		@is_valid = 0

		IF @stop_on_error = 1
			RETURN 0
	END

	IF @is_imported = 0
	BEGIN
		EXEC 		amGetErrorMessage_sp 
								21152, "tmp/imactval.sp", 216, 
								@asset_ctrl_num, @book_code, @apply_date, 
								@error_message = @message OUT 
		IF @message IS NOT NULL RAISERROR 	21152 @message 
		SELECT 		@is_valid = 0

		IF @stop_on_error = 1
			RETURN 0
	END
	
	IF 	@action = 0 
	BEGIN
		
		IF @apply_date_dt < @acquisition_date
		BEGIN
			EXEC 		amGetErrorMessage_sp 
									21157, "tmp/imactval.sp", 234, 
									@asset_ctrl_num, @book_code, @apply_date_dt, @acquisition_date, 
									@error_message = @message OUT 
			IF @message IS NOT NULL RAISERROR 	21157 @message 
			SELECT 		@is_valid = 0
			
			IF @stop_on_error = 1
				RETURN 0
		END
	END
END


EXEC @result = ambookExists_sp
					@book_code, 
					@does_exist 	OUTPUT
IF @result <> 0
	RETURN @result

IF @does_exist = 0 
BEGIN
	EXEC 		amGetErrorMessage_sp 
							21161, "tmp/imactval.sp", 258, 
							@asset_ctrl_num, @book_code, @apply_date_dt, 
							@error_message = @message OUT 
	IF @message IS NOT NULL RAISERROR 	21161 @message 
	SELECT 		@is_valid = 0

	IF @stop_on_error = 1
		RETURN 0
END
ELSE IF @is_valid = 1	
BEGIN
	
	SELECT	@co_asset_book_id	= NULL
	
	SELECT 	@co_asset_book_id 		= co_asset_book_id,
			@last_posted_depr_date	= last_posted_depr_date,
			@placed_in_service_date	= placed_in_service_date
	FROM	amastbk
	WHERE	co_asset_id 			= @co_asset_id
	AND		book_code				= @book_code

	IF @co_asset_book_id IS NULL
	BEGIN
		EXEC 		amGetErrorMessage_sp 
								21162, "tmp/imactval.sp", 284, 
								@asset_ctrl_num, @book_code, @apply_date_dt, 
								@error_message = @message OUT 
		IF @message IS NOT NULL RAISERROR 	21162 @message 
		SELECT 		@is_valid = 0
	
		IF @stop_on_error = 1
			RETURN 0
	END
	
	ELSE IF @action 	= 0 
	BEGIN
		
		IF 	@trx_type 	= 50
		BEGIN
			IF 	@placed_in_service_date IS NULL
			BEGIN
				EXEC 		amGetErrorMessage_sp 
										21164, "tmp/imactval.sp", 305, 
										@asset_ctrl_num, @book_code, @apply_date_dt, 
										@error_message = @message OUT 
				IF @message IS NOT NULL RAISERROR 	21164 @message 
				SELECT 		@is_valid = 0
			
				IF @stop_on_error = 1
					RETURN 0
			END
			ELSE
			BEGIN
				IF	@apply_date_dt < @placed_in_service_date
				BEGIN
					EXEC 		amGetErrorMessage_sp 
										21165, "tmp/imactval.sp", 319, 
										@asset_ctrl_num, @book_code, @apply_date_dt, 
										@error_message = @message OUT 
					IF @message IS NOT NULL RAISERROR 	21165 @message 
					SELECT 		@is_valid = 0
				
					IF @stop_on_error = 1
						RETURN 0

				END
			END
		END
	END
END


IF 	@action 	IN (0,2)
AND	@is_new 	= 1
AND	@trx_type 	IN (50, 60, 30, 70)
BEGIN
	EXEC 		amGetErrorMessage_sp 
							21158, "tmp/imactval.sp", 343, 
							@asset_ctrl_num, @book_code, @apply_date_dt, 
							@error_message = @message OUT 
	IF @message IS NOT NULL RAISERROR 	21158 @message 
	SELECT 		@is_valid = 0

	IF @stop_on_error = 1
		RETURN 0
END


SELECT @apply_date_jul = DATEDIFF(dd, "1/1/1980", @apply_date_dt) + 722815

IF @trx_type = 30
BEGIN
	
	IF 	@disposition_date IS NULL
	BEGIN
		EXEC 		amGetErrorMessage_sp 
								21163, "tmp/imactval.sp", 368, 
								@asset_ctrl_num, @book_code, @apply_date_dt, 
								@error_message = @message OUT 
		IF @message IS NOT NULL RAISERROR 	21163 @message 
		SELECT 		@is_valid = 0

		IF @stop_on_error = 1
			RETURN 0

	END
	ELSE IF	@apply_date_dt <> @disposition_date
	BEGIN
		EXEC 		amGetErrorMessage_sp 
								21173, "tmp/imactval.sp", 381, 
								@asset_ctrl_num, @book_code, @apply_date_dt, 
								@error_message = @message OUT 
		IF @message IS NOT NULL RAISERROR 	21173 @message 

		SELECT @apply_date_dt = @disposition_date
		SELECT @apply_date_jul = DATEDIFF(dd, "1/1/1980", @apply_date_dt) + 722815
	END
END
ELSE IF @trx_type = 50
BEGIN
	
	IF NOT EXISTS (SELECT 	period_end_date 
					FROM	glprd
					WHERE	period_end_date = @apply_date_jul)
	BEGIN
		EXEC 		amGetErrorMessage_sp 
								21170, "tmp/imactval.sp", 400, 
								@asset_ctrl_num, @book_code, @apply_date_dt, 
								@error_message = @message OUT 
		IF @message IS NOT NULL RAISERROR 	21170 @message 
		
		EXEC	@result = amGetFiscalPeriod_sp
								@apply_date_dt,
								1,
								@apply_date_dt 	OUTPUT
	
		IF @result <> 0
			RETURN @result
		
		SELECT @apply_date_jul = DATEDIFF(dd, "1/1/1980", @apply_date_dt) + 722815

	END
END



SELECT @str_text = trx_name 
FROM amtrxdef
WHERE trx_type = @trx_type

SELECT	@str_text = ISNULL(RTRIM(@str_text), '')
		
IF @trx_type <> 50
BEGIN
	IF @co_asset_book_id IS NOT NULL
	BEGIN 
		IF @action = 0
		BEGIN
			
			IF EXISTS (SELECT 	co_trx_id
						FROM	amacthst
						WHERE	co_asset_book_id 	= @co_asset_book_id
						AND		apply_date 			= @apply_date_dt
						AND		trx_type			= @trx_type
						)
			BEGIN
				EXEC 		amGetErrorMessage_sp 
										21156, "tmp/imactval.sp", 445, 
										@asset_ctrl_num, @book_code, @apply_date_dt, @str_text,
										@error_message = @message OUT 
				IF @message IS NOT NULL RAISERROR 	21156 @message 
				SELECT 		@is_valid = 0

				IF @stop_on_error = 1
					RETURN 0
			END

		END
		ELSE
		BEGIN
			
			IF NOT EXISTS (SELECT 	co_trx_id
							FROM	amacthst
							WHERE	co_asset_book_id 	= @co_asset_book_id
							AND		apply_date 			= @apply_date_dt
							AND		trx_type			= @trx_type
							)
			BEGIN
				EXEC 		amGetErrorMessage_sp 
										21155, "tmp/imactval.sp", 469, 
										@asset_ctrl_num, @book_code, @apply_date_dt, @str_text,
										@error_message = @message OUT 
				IF @message IS NOT NULL RAISERROR 	21155 @message 
				SELECT 		@is_valid = 0
			
				IF @stop_on_error = 1
					RETURN 0
			END
		END
	END
END
ELSE 	
BEGIN

 	IF @co_asset_book_id IS NOT NULL
	BEGIN 
		IF @action = 0
		BEGIN
			
			IF EXISTS(SELECT co_trx_id
						FROM	amvalues
						WHERE 	co_asset_book_id	= @co_asset_book_id
						AND		apply_date			= @apply_date_dt
						AND		trx_type			= 50
						AND		account_type_id		= 1)
			BEGIN
				EXEC 		amGetErrorMessage_sp 
										21156, "tmp/imactval.sp", 500, 
										@asset_ctrl_num, @book_code, @apply_date_dt, @str_text,
										@error_message = @message OUT 
				IF @message IS NOT NULL RAISERROR 	21156 @message 
				SELECT 		@is_valid = 0
				
				IF @stop_on_error = 1
					RETURN 0
			END
		END
		ELSE
		BEGIN
			
			IF NOT EXISTS(SELECT co_trx_id
							FROM	amvalues
							WHERE	co_asset_book_id	= @co_asset_book_id
							AND		apply_date			= @apply_date_dt
							AND		trx_type			= 50
							AND		account_type_id		= 1)
			BEGIN
				EXEC 		amGetErrorMessage_sp 
										21155, "tmp/imactval.sp", 524, 
										@asset_ctrl_num, @book_code, @apply_date_dt, @str_text,
										@error_message = @message OUT 
				IF @message IS NOT NULL RAISERROR 	21155 @message 
				SELECT 		@is_valid = 0
				
				IF @stop_on_error = 1
					RETURN 0
			END
		END
	END
END

IF @action = 0
BEGIN
	
	SELECT	@cur_prd_end = DATEADD(dd, period_end_date-722815, "1/1/1980")
	FROM	glco
	
	IF @apply_date_dt > @cur_prd_end
	BEGIN
		EXEC	 	amGetErrorMessage_sp 
								21166, "tmp/imactval.sp", 548, 
								@asset_ctrl_num, @book_code, @apply_date_dt, 
								@error_message = @message OUT 
		IF @message IS NOT NULL RAISERROR 	21166 @message 
		SELECT 		@is_valid = 0
		
		IF @stop_on_error = 1
			RETURN 0	
	END
	
	
	IF 	@disposition_date IS NOT NULL
	AND @apply_date_dt > @disposition_date
	BEGIN
		EXEC	 	amGetErrorMessage_sp 
								21167, "tmp/imactval.sp", 565, 
								@asset_ctrl_num, @book_code, @apply_date_dt, 
								@error_message = @message OUT 
		IF @message IS NOT NULL RAISERROR 	21167 @message
		SELECT 		@is_valid = 0
		
		IF @stop_on_error = 1
			RETURN 0	
	END
	
END

IF @action = 0
OR @action = 2
BEGIN
	EXEC 	@result = imCheckAmounts_sp
						@asset_ctrl_num,
						@book_code,
						@apply_date_dt,
						@trx_type,
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
						@is_valid	OUTPUT,
						@debug_level

							 
	
	IF @result <> 0
		RETURN @result
		
	IF @is_valid = 0
	AND	@stop_on_error = 1
		RETURN 0
		
END

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/imactval.sp" + ", line " + STR( 610, 5 ) + " -- EXIT: "

RETURN 0
GO
GRANT EXECUTE ON  [dbo].[imActVal_sp] TO [public]
GO
