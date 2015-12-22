SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[amCalcAssetBookDepr_sp] 
( 
	@co_asset_id		smSurrogateKey,		
	@co_asset_book_id smSurrogateKey,  
	@is_new				int,
	@from_date 			smApplyDate, 		
	@to_date 			smApplyDate, 		 
	@depr_exp_acct_id 	smSurrogateKey, 	
	@accum_depr_acct_id smSurrogateKey, 	
	@acquisition_date	smApplyDate,		 
	@placed_date 		smApplyDate, 		 
	@do_post 		smLogical, 			
	@break_down_by_prd	smLogical	= 0,
	@cur_precision 		smallint,			
	@round_factor 		float,				
	@cost 				smMoneyZero OUTPUT,	
	@accum_depr 		smMoneyZero OUTPUT,	
	@depr_expense 		smMoneyZero OUTPUT,	
	@debug_level		smDebugLevel 	= 0,
	@perf_level			smPerfLevel 	= 0	
)
AS 






DECLARE
 @PERF_time_last datetime

SELECT @PERF_time_last = GETDATE()















									







DECLARE 
	@result 			smErrorCode, 
	@message 			smErrorLongDesc, 
	@prd_start_date 	smApplyDate, 
	@prd_end_date 		smApplyDate, 
	@find_boundary_from	smApplyDate, 
	@last_date 			smApplyDate, 
	@next_date 			smApplyDate, 
	@last_depr_date 	smApplyDate, 
	@init_cost 			smMoneyZero, 		 
	@init_accum_depr 	smMoneyZero,		 
	@range_depr_expense smMoneyZero, 
	@yearly_depr 		smMoneyZero, 
	@salvage_value 		smMoneyZero, 
	@depr_ytd			smMoneyZero,		
	@rowcount 			smCounter, 
	@num_periods 		float,
	@boundary_type 		smBoundaryType, 
	@method_id 			smDeprMethodID,		
	@convention_id		smConventionID, 	
	@use_first 			smLogical, 
	@first_time 		smLogical, 			
	@first_time_depr 	smLogical, 		
	@flag				smControlNumber	



IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amclasbk.sp" + ", line " + STR( 128, 5 ) + " -- ENTRY: "
SELECT @flag = CONVERT(char(16), @co_asset_book_id)
IF ( @perf_level >= 1 ) EXEC perf_sp @flag, "tmp/amclasbk.sp", 130, "Entry amCalcAssetBookDepr_sp", @PERF_time_last OUTPUT


IF @debug_level >= 3
	SELECT 	co_asset_book_id 	= @co_asset_book_id,
			from_date 			= @from_date,
			to_date 			= @to_date,
			do_post 			= @do_post,
			cost 				= @cost,
			depr_expense 		= @depr_expense,
			accum_depr 			= @accum_depr 

SELECT 	@last_date 	= @from_date,
		@first_time = 1 

 
IF @last_date IS NULL 
BEGIN 
	SELECT @first_time_depr = 1
	EXEC @result = amGetFirstDeprDate_sp 
							@co_asset_book_id,
							@last_date OUTPUT 
	IF ( @result <> 0 )
		RETURN 	@result 

END 
ELSE
	SELECT @first_time_depr = 0

 
EXEC @result = amGetCurrentSalvageValue_sp 
						@co_asset_book_id,
						@to_date,
						@placed_date,
						@salvage_value OUTPUT 
IF ( @result <> 0 )
	RETURN 	@result 

SELECT @salvage_value = (SIGN(@salvage_value) * ROUND(ABS(@salvage_value) + 0.0000001, @cur_precision))

IF @debug_level >= 3
	SELECT 	last_date 			= @last_date,
			to_date				= @to_date,
			salvage_value		= @salvage_value


IF 	@last_date 	> @to_date
AND	@to_date	>= @acquisition_date
AND @do_post	= 1
BEGIN
	EXEC @result = amProcessUnplaced_sp 
							@to_date,
							@co_asset_book_id,
							@cur_precision, 
			 				@cost 			OUTPUT,
			 				@accum_depr 	OUTPUT,
			 				@debug_level = @debug_level

	IF @result <> 0
		RETURN 	@result 


	 
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
		@cost,
		@accum_depr,
		0.00,
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
		@cost,
		@accum_depr,
		0.00,
		@accum_depr_acct_id 
	) 
	SELECT @result = @@error
	IF ( @result != 0 ) 
	 	RETURN @result 
END
ELSE
BEGIN
	SELECT @depr_ytd = 0.0	

	 
	WHILE @last_date <= @to_date 
	BEGIN 

		IF @debug_level >= 3
			SELECT 	last_date 	= @last_date,
					to_date 	= @to_date 

		EXEC @result = amGetFiscalPeriod_sp 
								@last_date,
						 		0,
			 					@prd_start_date OUTPUT 

		IF ( @result <> 0 )
			RETURN 	@result 
		
		
		EXEC @result = amGetFiscalPeriod_sp 
								@prd_start_date,
						 		1,
				 				@prd_end_date OUTPUT

		IF @result <> 0
			RETURN @result

		IF 	@first_time_depr = 1
		AND	@first_time = 1
		BEGIN
			
			EXEC @result = amApplyStartPeriodActivity_sp 
									@co_asset_book_id, 
									1,
									@prd_start_date,
									@prd_end_date,
									@cur_precision,
					 				@cost 			OUTPUT,
					 				@accum_depr 	OUTPUT,
									0,				
					 				@debug_level,
					 				@perf_level 

			IF ( @result != 0 )
				RETURN @result 

			
			IF @do_post = 1
			BEGIN
				INSERT INTO #amfstdpr
				(
					co_asset_id,
					co_asset_book_id,
					original_cost,
					post_to_gl
				)
				SELECT
					@co_asset_id,
					@co_asset_book_id,
					@cost,
					post_to_gl
				FROM	amastbk	ab,
						ambook	b
				WHERE	ab.co_asset_book_id = @co_asset_book_id
				AND		ab.book_code 		= b.book_code
				
				SELECT @result = @@error
				IF @result <> 0
					RETURN @result
			END
		END
		ELSE
		BEGIN
			
			IF ( @perf_level >= 2 ) EXEC perf_sp @flag, "tmp/amclasbk.sp", 364, "Starting a period", @PERF_time_last OUTPUT
			
			IF @last_date = @prd_start_date 
			BEGIN 

				EXEC @result = amApplyStartPeriodActivity_sp 
										@co_asset_book_id, 
										0,
										@prd_start_date,
										@prd_end_date,
										@cur_precision,
						 				@cost 			OUTPUT,
						 				@accum_depr 	OUTPUT,
										0,				
					 					@debug_level 
	 

				IF ( @result != 0 )
					RETURN @result 

				IF ( @perf_level >= 2 ) EXEC perf_sp @flag, "tmp/amclasbk.sp", 384, "Applied starting activities", @PERF_time_last OUTPUT
			END 
		END

		 
		SELECT 	@init_cost 			= @cost,
				@init_accum_depr 	= @accum_depr 

		IF @debug_level >= 3
			SELECT 	init_cost 			= @init_cost,
					init_accum_depr 	= @init_accum_depr 

		IF 	(@from_date IS NULL)
		AND (@first_time = 1)
		BEGIN 
			
			EXEC @result = amGetDepreciationInfo_sp 
									@co_asset_book_id, 
									@placed_date,
					 				@method_id 		OUTPUT,
					 				@convention_id	OUTPUT,
					 				@debug_level 
			IF ( @result != 0 )
				RETURN @result
			
			IF	@placed_date > @last_date
				SELECT	@find_boundary_from	= @placed_date
			ELSE
				SELECT	@find_boundary_from	= @last_date
		END 
		ELSE 
		BEGIN 
			EXEC @result = amGetDepreciationInfo_sp 
									@co_asset_book_id, 
									@last_date,
					 				@method_id 		OUTPUT,
					 				@convention_id	OUTPUT,
					 				@debug_level 


			IF ( @result != 0 )
				RETURN @result

			SELECT	@find_boundary_from	= @last_date

		END 
		IF ( @perf_level >= 2 ) EXEC perf_sp @flag, "tmp/amclasbk.sp", 441, "Got depreciation info", @PERF_time_last OUTPUT

	 	
	 	IF 	@do_post = 0 
	 	AND @break_down_by_prd = 1
	 	BEGIN
			
			SELECT @next_date = @prd_end_date

			IF @debug_level >= 3
				SELECT 	next_date 		= @next_date
	 	END
	 	ELSE
	 	BEGIN
		 	EXEC @result = amGetNextActivityDate_sp 	
										@co_asset_book_id, 
						 				@find_boundary_from,
										@method_id,
						 				@to_date,
										@next_date 		OUTPUT,
										@boundary_type 	OUTPUT,
										@debug_level 

			IF ( @result != 0 )
				RETURN @result

			IF @debug_level >= 3
				SELECT 	method_id 		= @method_id,
						next_date 		= @next_date,
						boundary_type 	= @boundary_type 
			IF ( @perf_level >= 2 ) EXEC perf_sp @flag, "tmp/amclasbk.sp", 484, "Got next activity date", @PERF_time_last OUTPUT
		END

		IF @method_id = 0 
			SELECT @range_depr_expense = 0.0 

		ELSE IF @method_id = 7 
		BEGIN 
			EXEC @result = amManual_sp 
									@co_asset_book_id,
									@last_date,
									@next_date,
									@cur_precision,
									@range_depr_expense OUTPUT,
									@debug_level 
			IF ( @result != 0 )
				RETURN @result
		END 
		ELSE  
		BEGIN 

			

		 

				 
				EXEC @result = amUseFirstYearMethod_sp 
									@last_date,
									@placed_date,
									@use_first 	OUTPUT,
									@debug_level 
				IF ( @result != 0 )
					RETURN @result

		 	
					
			IF ( @perf_level >= 2 ) EXEC perf_sp @flag, "tmp/amclasbk.sp", 532, "Checked for first year", @PERF_time_last OUTPUT
			
			IF @use_first = 1 
			BEGIN 
				
				IF @first_time = 1
				BEGIN
					
					EXEC @result = amGetDeprYTD_sp 
											@co_asset_book_id,
											@placed_date,		
											@next_date,			
											@cur_precision,
											@depr_ytd OUTPUT,
											@debug_level,
											@perf_level 

					IF ( @result != 0 )
						RETURN @result
					
					IF ( @perf_level >= 2 ) EXEC perf_sp @flag, "tmp/amclasbk.sp", 554, "Got YTD depr", @PERF_time_last OUTPUT
				
				END
				
				EXEC @result = amCalcFirstYearDepr_sp 
										@co_asset_book_id,
										@last_date,
										@salvage_value,
										@acquisition_date,
										@placed_date,
										@method_id,
										@convention_id,	
										@do_post,
										@first_time_depr,
										@cur_precision,
										@yearly_depr OUTPUT,
										@debug_level
				IF ( @result != 0 )
					RETURN @result
				
			END 
			ELSE  
			BEGIN 
				
				EXEC @result = amCalcYearlyDepr_sp 
										@co_asset_book_id,
										@method_id,	
										@convention_id,
										@last_date,
										@salvage_value,
										@acquisition_date,
										@placed_date,
										0,
										@do_post,
										@cur_precision,
										@yearly_depr OUTPUT,
										@debug_level,
										@perf_level
										 
				IF ( @result != 0 )
					RETURN @result 

				SELECT @depr_ytd = 0.0	

			END 
		
			IF ( @perf_level >= 2 ) EXEC perf_sp @flag, "tmp/amclasbk.sp", 600, "Calculated years depreciation", @PERF_time_last OUTPUT

			EXEC @result= amAllocateProportion_sp 
						 	@first_year	 		= @use_first,
							@years_depr_exp	 	= @yearly_depr,
							@ytd_depr_exp		= @depr_ytd,
							@from_date 			= @last_date,	
							@to_date 			= @next_date,
							@convention_id 	 	= @convention_id,	 
							@curr_precision	 	= @cur_precision,
							@calc_depr_exp	 	= @range_depr_expense	 OUTPUT,	
							@debug_level	 	= @debug_level

			IF ( @result != 0 )
				RETURN @result
		
			IF ( @perf_level >= 2 ) EXEC perf_sp @flag, "tmp/amclasbk.sp", 616, "Allocated depreciation", @PERF_time_last OUTPUT
		
		END 

		 
		EXEC @result = amIsFullyDepreciated_sp 
								@co_asset_book_id,
								@method_id, 
								@next_date,
								@salvage_value,
								@cost,
								@accum_depr,
								@cur_precision,
								@range_depr_expense OUTPUT,
								@debug_level 

		IF ( @result != 0 )
			RETURN @result

		IF @debug_level >= 3
			SELECT 	adjusted_range_depr_expense 	= @range_depr_expense,
					depr_expense_was 				= @depr_expense,
					accum_depr_was 					= @accum_depr 

		 
		SELECT 	@depr_expense 	= (SIGN(@depr_expense + @range_depr_expense) * ROUND(ABS(@depr_expense + @range_depr_expense) + 0.0000001, @cur_precision))
		SELECT 	@accum_depr 	= (SIGN(@accum_depr - @range_depr_expense) * ROUND(ABS(@accum_depr - @range_depr_expense) + 0.0000001, @cur_precision))
		SELECT 	@depr_ytd 		= (SIGN(@depr_ytd + @range_depr_expense) * ROUND(ABS(@depr_ytd + @range_depr_expense) + 0.0000001, @cur_precision))

		IF @debug_level >= 3
			SELECT 	depr_expense 	= @depr_expense,
					accum_depr 		= @accum_depr, 
					depr_ytd		= @depr_ytd
					
		 
		SELECT @last_date 	= DATEADD(dd, 1, @next_date)
		SELECT @first_time 	= 0  

		EXEC @result = amStoreResults_sp
								@co_asset_id,
								@co_asset_book_id,
								@to_date,				
								@next_date,
								@depr_exp_acct_id,
								@accum_depr_acct_id,
								@init_cost,
								@init_accum_depr,
								@cost,
								@accum_depr,
								@depr_expense,
								@cur_precision,
								@do_post,
								@break_down_by_prd,
								@debug_level
		IF @result != 0
			RETURN @result

	END  
END

IF @debug_level >= 3
	SELECT 	depr_expense 		= @depr_expense,
			cost 				= @cost,
			accum_depr 			= @accum_depr,
			init_cost 			= @init_cost,
			init_accum_depr 	= @init_accum_depr 

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amclasbk.sp" + ", line " + STR( 689, 5 ) + " -- EXIT: "
IF ( @perf_level >= 1 ) EXEC perf_sp @flag, "tmp/amclasbk.sp", 690, "Exit amCalcAssetBookDepr_sp", @PERF_time_last OUTPUT

RETURN 0
GO
GRANT EXECUTE ON  [dbo].[amCalcAssetBookDepr_sp] TO [public]
GO
