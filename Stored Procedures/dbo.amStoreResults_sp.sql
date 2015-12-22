SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[amStoreResults_sp] 
( 
	@co_asset_id			smSurrogateKey,		
	@co_asset_book_id 		smSurrogateKey, 	
	@apply_date				smApplyDate,		
	@to_date				smApplyDate,		
	@depr_exp_acct_id 		smSurrogateKey, 	
	@accum_depr_acct_id 	smSurrogateKey, 	
	@init_cost				smMoneyZero,		
	@init_accum_depr		smMoneyZero,		
	@cost					smMoneyZero,		
	@accum_depr				smMoneyZero,		
	@depr_expense			smMoneyZero,		
	@cur_precision			smallint,			
	@do_post 			smLogical,			
	@break_down_by_prd		smLogical	= 0,
	@debug_level			smDebugLevel = 0 	
)
AS 

DECLARE 
	@result		 			smErrorCode, 		
	@yr_end_date			smApplyDate,		
	@row_apply_date			smApplyDate,		
	@prev_depr_expense		smMoneyZero			

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amstrres.sp" + ", line " + STR( 88, 5 ) + " -- ENTRY: "

IF @debug_level >= 5
	SELECT 	do_post 			= @do_post,
			apply_date			= @apply_date,
			to_date				= @to_date,
			co_asset_id			= @co_asset_id,
			co_asset_book_id	= @co_asset_book_id,
			depr_expense		= @depr_expense,
			depr_exp_acct_id	= @depr_exp_acct_id, 
			accum_depr_acct_id	= @accum_depr_acct_id


EXEC @result = amGetFiscalYear_sp 
						@to_date,
						1,
						@yr_end_date OUTPUT 

IF ( @result != 0 ) 
 	RETURN @result

IF (@do_post = 1)
BEGIN

	
	IF @apply_date = @to_date
	BEGIN
	 	SELECT @depr_expense = (SIGN(@depr_expense) * ROUND(ABS(@depr_expense) + 0.0000001, @cur_precision))

		INSERT into #amvalues 
		( 
			co_asset_book_id,
			co_asset_id,
			account_type_id,
			apply_date,
			trx_type,
			cost,
			accum_depr,
			amount,
			account_id 
		)
		VALUES 
		( 
			@co_asset_book_id,
			@co_asset_id,
			5,
			@to_date,
			50,
			@init_cost,
			@init_accum_depr,
			@depr_expense,
			@depr_exp_acct_id 
		)

		SELECT @result = @@error
		IF ( @result != 0 ) 
		 	RETURN @result 

		 
		INSERT into #amvalues 
		( 
			co_asset_book_id,
			co_asset_id,
			account_type_id,
			apply_date,
			trx_type,
			cost,
			accum_depr,
			amount,
			account_id 
		)
		VALUES 
		( 
			@co_asset_book_id,
			@co_asset_id,
			1,
			@to_date,
			50,
			@init_cost,
			@init_accum_depr,
			- @depr_expense,
			@accum_depr_acct_id 
		) 
		SELECT @result = @@error
		IF ( @result != 0 ) 
		 	RETURN @result 
	END
END
ELSE 
BEGIN
	
	
	IF @break_down_by_prd = 1
		SELECT	@row_apply_date = @to_date
	ELSE
	BEGIN
		IF 	@to_date 	= @apply_date
		OR	@apply_date < @yr_end_date
			SELECT	@row_apply_date = @apply_date
		ELSE
		 	SELECT 	@row_apply_date = @yr_end_date 
	END

	SELECT	@prev_depr_expense = 0.0
	
	SELECT	@prev_depr_expense 	= (SIGN(ISNULL(SUM(ytd_depr), 0.0)) * ROUND(ABS(ISNULL(SUM(ytd_depr), 0.0)) + 0.0000001, @cur_precision))
	FROM	#amcalval
	WHERE	co_asset_book_id	= @co_asset_book_id
	AND		apply_date			< @row_apply_date

		
	IF EXISTS (SELECT ytd_depr
				FROM	#amcalval
				WHERE	co_asset_book_id 	= @co_asset_book_id
				AND		apply_date			= @row_apply_date)
	BEGIN
		
		UPDATE 	#amcalval
		SET		end_cost 			= @cost,
				end_accum_depr		= @accum_depr,
				ytd_depr			= (SIGN(@depr_expense - @prev_depr_expense) * ROUND(ABS(@depr_expense - @prev_depr_expense) + 0.0000001, @cur_precision))
		FROM	#amcalval
		WHERE	co_asset_book_id	= @co_asset_book_id
		AND		apply_date			= @row_apply_date

		SELECT	@result = @@error
		IF @result <> 0
			RETURN @result


	END
	ELSE
	BEGIN
	 
		
		IF @break_down_by_prd = 1
		BEGIN
			INSERT INTO #amcalval
			(
				co_asset_book_id,
				apply_date,
				beg_cost,
				beg_accum_depr,
				end_cost, 
				end_accum_depr,
				ytd_depr,
				year_end_date
			)
			VALUES
			(
				@co_asset_book_id,
				@row_apply_date,
				isnull(@init_cost,0.0),
				isnull(@init_accum_depr,0.0),
				isnull(@cost,0.0),
				isnull(@accum_depr,0.0),
				isnull((SIGN(@depr_expense - @prev_depr_expense) * ROUND(ABS(@depr_expense - @prev_depr_expense) + 0.0000001, @cur_precision)),0.0),
				@yr_end_date
			)

			SELECT	@result = @@error
			IF @result <> 0
				RETURN @result
		END
		ELSE
		BEGIN
			
			INSERT INTO #amcalval
			(
				co_asset_book_id,
				apply_date,
				beg_cost,
				beg_accum_depr,
				end_cost, 
				end_accum_depr,
				ytd_depr,
				year_end_date
			)
			VALUES
			(
				@co_asset_book_id,
				@row_apply_date,
				isnull(@init_cost,0.0),
				isnull(@init_accum_depr,0.0),
				isnull(@cost,0.0),
				isnull(@accum_depr,0.0),
			 isnull((SIGN(@depr_expense - @prev_depr_expense) * ROUND(ABS(@depr_expense - @prev_depr_expense) + 0.0000001, @cur_precision)),0.0),
				NULL
			)

			SELECT	@result = @@error
			IF @result <> 0
				RETURN @result
		END
		
	END
END


SELECT @accum_depr = ISNULL(@accum_depr,0.0)
 
IF	(@do_post = 1)
AND	((@to_date = @apply_date) OR (@to_date = @yr_end_date))
BEGIN 
	
	EXEC @result = amCreateProfile_sp 
							@co_asset_book_id, 
							@to_date,
							@cost,
						 @accum_depr,
							1		 
	
	IF ( @result != 0 ) 
	 	RETURN @result 
END
ELSE
BEGIN

	EXEC @result = amCreateProfile_sp 
							@co_asset_book_id, 
							@to_date,
							@cost,
							@accum_depr,
							0	 	 

	IF ( @result != 0 ) 
	 	RETURN @result 
END


IF @debug_level >= 3
BEGIN
	SELECT 	*
	FROM	#amvalues
	WHERE	co_asset_book_id = @co_asset_book_id

	SELECT 	*
	FROM	#amcalval
	WHERE	co_asset_book_id = @co_asset_book_id

END
	
IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amstrres.sp" + ", line " + STR( 350, 5 ) + " -- EXIT: "

RETURN 0 
GO
GRANT EXECUTE ON  [dbo].[amStoreResults_sp] TO [public]
GO
