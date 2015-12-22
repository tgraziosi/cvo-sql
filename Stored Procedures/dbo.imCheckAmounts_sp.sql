SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

 
CREATE PROCEDURE [dbo].[imCheckAmounts_sp] 
( 
	@asset_ctrl_num			char(16),				
	@book_code				char(8),			
	@apply_date_dt			datetime,			
	@trx_type				int, 				
	@account_1_amount	 	float 		= 0.0,	
	@account_2_amount		float 		= 0.0,	
	@account_3_amount		float 		= 0.0,		
	@account_4_amount		float		= 0.0,	
	@account_5_amount		float		= 0.0,	
	@account_6_amount		float 		= 0.0,	
	@account_7_amount		float 		= 0.0,	
	@account_8_amount		float 		= 0.0,	
	@account_9_amount		float 		= 0.0,	
	@account_10_amount	 	float 		= 0.0,	
	@stop_on_error			tinyint		= 0,	
	@is_valid				tinyint 	OUTPUT,	
	@debug_level			smallint	= 0		
)
AS 

DECLARE
	@result					int,				
	@param1					varchar(255),		
	@message				varchar(255),		
	@activity_sum			float,				
	@cur_precision 			smallint,			
	@round_factor 			float ,				
	@nr_accounts			smCounter,
	@disp					smCounter,
	@count					smCounter,	
	@account_amount			float

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/imchkamt.sp" + ", line " + STR( 80, 5 ) + " -- ENTRY: "

		

IF @trx_type NOT IN (SELECT trx_type FROM amtrxdef WHERE allow_to_import = 1)
BEGIN
	SELECT @param1 = RTRIM(CONVERT(char(255), @trx_type))
	
	EXEC 		amGetErrorMessage_sp 
							21154, "tmp/imchkamt.sp", 91, 
							@asset_ctrl_num, @book_code, @apply_date_dt, @param1, 
							@error_message = @message OUT 
	IF @message IS NOT NULL RAISERROR 	21154 @message 
	SELECT 		@is_valid = 0
	
	IF @stop_on_error = 1
		RETURN 0
END

 
EXEC @result = amGetCurrencyPrecision_sp 
						@cur_precision 	OUTPUT,
						@round_factor 	OUTPUT 

IF @result <> 0 
	RETURN @result 



SELECT @nr_accounts= COUNT(*) 
FROM 	amtrxact
WHERE	trx_type	= @trx_type	

IF @debug_level >= 3
	SELECT nr_accounts = @nr_accounts

SELECT @account_amount = 0.0
SELECT @count = 1

WHILE @count <= @nr_accounts
BEGIN

		IF @count = 1
			SELECT 	@account_amount = @account_amount + @account_1_amount
		ELSE IF @count = 2
			SELECT @account_amount 	= @account_amount + @account_2_amount
		ELSE IF @count = 3
			SELECT @account_amount 	= @account_amount + @account_3_amount
		ELSE IF @count = 4
			SELECT @account_amount 	= @account_amount + @account_4_amount
		ELSE IF @count = 5
			SELECT @account_amount 	= @account_amount + @account_5_amount
		ELSE IF @count = 6
			SELECT @account_amount 	= @account_amount + @account_6_amount
		ELSE IF @count = 7
			SELECT @account_amount 	= @account_amount + @account_7_amount
		ELSE IF @count = 8
			SELECT @account_amount 	= @account_amount + @account_8_amount
		ELSE IF @count = 9
			SELECT @account_amount 	= @account_amount + @account_9_amount
		ELSE IF @count = 10
			SELECT @account_amount 	= @account_amount + @account_10_amount

		SELECT @count = @count + 1
END

IF @debug_level >= 3
	SELECT	activity_sum = @account_amount


SELECT @activity_sum = (SIGN(@account_amount) * ROUND(ABS(@account_amount) + 0.0000001, @cur_precision))


IF @debug_level >= 3
	SELECT rounded = @activity_sum



IF (ABS((@activity_sum)-(0.0)) > 0.0000001)
BEGIN
	EXEC 		amGetErrorMessage_sp 
							21150, "tmp/imchkamt.sp", 165, 
							@asset_ctrl_num, @book_code, @apply_date_dt, 
							@error_message = @message OUT 
	IF @message IS NOT NULL RAISERROR 	21150 @message 
	SELECT 		@is_valid = 0
	
	IF @stop_on_error = 1
		RETURN 0
END



SELECT @account_amount = 0.0 
SELECT @count = @nr_accounts + 1

WHILE @count < 11
BEGIN

		IF @count = 1
			SELECT 	@account_amount = @account_amount + @account_1_amount
		ELSE IF @count = 2
			SELECT @account_amount 	= @account_amount + @account_2_amount
		ELSE IF @count = 3
			SELECT @account_amount 	= @account_amount + @account_3_amount
		ELSE IF @count = 4
			SELECT @account_amount 	= @account_amount + @account_4_amount
		ELSE IF @count = 5
			SELECT @account_amount 	= @account_amount + @account_5_amount
		ELSE IF @count = 6
			SELECT @account_amount 	= @account_amount + @account_6_amount
		ELSE IF @count = 7
			SELECT @account_amount 	= @account_amount + @account_7_amount
		ELSE IF @count = 8
			SELECT @account_amount 	= @account_amount + @account_8_amount
		ELSE IF @count = 9
			SELECT @account_amount 	= @account_amount + @account_9_amount
		ELSE IF @count = 10
			SELECT @account_amount 	= @account_amount + @account_10_amount

		SELECT @count = @count + 1
END

SELECT @activity_sum = (SIGN(@account_amount) * ROUND(ABS(@account_amount) + 0.0000001, @cur_precision))


IF (ABS((@activity_sum)-(0.0)) > 0.0000001)
BEGIN

	SELECT 	@param1 = trx_name + ': '
	FROM	amtrxdef
	WHERE	trx_type = @trx_type

	
			
	SELECT @disp = 1

	WHILE @disp <= @nr_accounts
	BEGIN

			IF @disp > 1 
				SELECT @param1 = @param1 + ',' + account_type_name
				FROM	amacctyp a, amtrxact b
				WHERE a.account_type = b.account_type
				AND b.trx_type 	 = @trx_type
				AND		b.import_order = @disp
 
			ELSE
				SELECT @param1 = @param1 + account_type_name 
				FROM	amacctyp a, amtrxact b
				WHERE a.account_type = b.account_type
				AND b.trx_type 	 = @trx_type
				AND		b.import_order = @disp

		 SELECT @disp	 = @disp + 1
	END
		
				
	EXEC 		amGetErrorMessage_sp 
								21150, "tmp/imchkamt.sp", 264, 
								@asset_ctrl_num, @book_code, @apply_date_dt, @param1, 
								@error_message = @message OUT

									 
			 
	SELECT 		@is_valid = 0
		
	IF @stop_on_error = 1
			RETURN 0 			
	
END

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/imchkamt.sp" + ", line " + STR( 277, 5 ) + " -- EXIT: "

RETURN 0
GO
GRANT EXECUTE ON  [dbo].[imCheckAmounts_sp] TO [public]
GO
