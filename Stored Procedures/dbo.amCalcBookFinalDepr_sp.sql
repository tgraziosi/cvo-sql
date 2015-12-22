SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[amCalcBookFinalDepr_sp] 
( 
	@co_asset_id			smSurrogateKey,		
	@co_asset_book_id 	smSurrogateKey,  
	@disposition_date		smApplyDate, 		 
	@disp_yr_start_date		smApplyDate,		
						
	@acquisition_date		smApplyDate,		 
	@full_disposition		smLogical	= 1,	
	@disp_co_trx_id			smSurrogateKey,		
	@cur_precision	 		smallint,			
	@round_factor 			float,				
	@cost_when_disp 	 	smMoneyZero OUTPUT,	
	@accum_depr_when_disp	smMoneyZero OUTPUT,	
	@depr_ytd				smMoneyZero OUTPUT,	
	@depr_expense 			smMoneyZero OUTPUT,	
	@debug_level			smDebugLevel = 0	
)
AS 

DECLARE 
	@result 				smErrorCode, 
	@message 				smErrorLongDesc, 
	@prd_end_before_disp	smApplyDate,		
	@disp_prd_start_date	smApplyDate,		
	@disp_yr_end_date		smApplyDate,		
	@start_date				smApplyDate,		 
	@last_posted_depr_date	smApplyDate,		 
	@placed_date 			smApplyDate, 		 
	@yearly_depr 			smMoneyZero, 
	@prior_prd_depr_expense	smMoneyZero,		
	@salvage_value 			smMoneyZero, 
	@method_id 				smDeprMethodID,		
	@convention_id			smConventionID, 	
	@depr_if_less_than_yr	smLogical,			
	@in_first_yr			smLogical, 
	@first_time_depr 		smLogical, 		
	@num_prd_before_disp	smCounter,			
	@num_prd_in_yr			smCounter,			
	@proportion_taken		float,
	@proportion				float				



IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/ambkfldp.sp" + ", line " + STR( 120, 5 ) + " -- ENTRY: "

IF @debug_level >= 3
	SELECT 	co_asset_book_id 	= @co_asset_book_id,
			disposition_date 	= @disposition_date

 
SELECT 	@depr_expense 			= 0.0,
	 	@prior_prd_depr_expense	= 0.0,
		@cost_when_disp			= 0.0,
		@accum_depr_when_disp	= 0.0,
		@depr_ytd				= 0.0

 

SELECT 	@depr_if_less_than_yr	= b.depr_if_less_than_yr,
		@last_posted_depr_date 	= ab.last_posted_depr_date,
		@placed_date			= ab.placed_in_service_date
FROM 	amastbk ab,
		ambook b 
WHERE 	ab.co_asset_book_id 	= @co_asset_book_id 
AND		ab.book_code			= b.book_code

IF @debug_level >= 3
	SELECT 	last_posted_depr_date 	= @last_posted_depr_date,
			placed_date 			= @placed_date

IF (@last_posted_depr_date IS NULL)
BEGIN 
	 
	IF @placed_date IS NOT NULL
	BEGIN
		EXEC @result = amSetFirstDeprDate_sp 
							@co_asset_book_id,
							@placed_date 
		IF ( @result != 0 ) 
		 	RETURN @result 
		SELECT 	@first_time_depr 		= 1
	
	END

END 
ELSE
BEGIN 
	SELECT	@start_date 			= DATEADD(dd, 1, @last_posted_depr_date)
	SELECT	@first_time_depr 		= 0

	SELECT 	@cost_when_disp			= ISNULL(current_cost, 0.0),
			@accum_depr_when_disp	= ISNULL(accum_depr, 0.0)
	FROM	amastprf
	WHERE	co_asset_book_id		= @co_asset_book_id
	AND		fiscal_period_end		= @last_posted_depr_date
END 

IF 	(@placed_date IS NOT NULL)
AND (@placed_date <= @disposition_date)
BEGIN 	
	
	IF 	@disp_yr_start_date <= @acquisition_date
	AND	(	((@full_disposition = 1) AND (@depr_if_less_than_yr = 0))
		OR 	(@full_disposition = 0))
	BEGIN
		IF @debug_level >= 5
			SELECT "No depr allowed if disposed in first yr. Reversing depr taken YTD on the disposed portion."

			
		IF @last_posted_depr_date IS NULL
			SELECT 	@first_time_depr 	= 1,
					@start_date			= @acquisition_date
		ELSE
			SELECT 	@first_time_depr 	= 0,
					@start_date			= DATEADD(dd, 1, @last_posted_depr_date)


		
		EXEC @result = amApplyStartPeriodActivity_sp 
								@co_asset_book_id, 
								@first_time_depr,
								@start_date,
								@disposition_date,
								@cur_precision,
				 				@cost_when_disp 	 	OUTPUT,
				 				@accum_depr_when_disp 	OUTPUT,
								@disp_co_trx_id,
				 				@debug_level 

		IF ( @result != 0 )
			RETURN @result 
		
		
	 	EXEC @result = amGetDeprYTD_sp 
								@co_asset_book_id,
								@disp_yr_start_date,
								@disposition_date,
								@cur_precision,
								@depr_ytd OUTPUT,
								@debug_level
								
		IF ( @result != 0 )
			RETURN @result

		SELECT @depr_expense = (SIGN(-@depr_ytd) * ROUND(ABS(-@depr_ytd) + 0.0000001, @cur_precision))
		
			
	END
	ELSE	
	BEGIN
		EXEC @result = amGetFiscalPeriod_sp
						@disposition_date,
						0,
						@disp_prd_start_date OUTPUT
		IF @result <> 0
			RETURN @result
		
		SELECT	@prd_end_before_disp = DATEADD(dd, -1, @disp_prd_start_date)
		
		IF @debug_level >= 3
			SELECT	last_posted_depr_date	= @last_posted_depr_date,
					cost_when_disp			= @cost_when_disp,
				 	start_date				= @start_date,
				 	accum_depr_when_disp	= @accum_depr_when_disp,
					disp_prd_start_date		= @disp_prd_start_date,
					first_time_depr			= @first_time_depr


		
		IF 	@last_posted_depr_date IS NULL
		OR	@last_posted_depr_date < @prd_end_before_disp
		BEGIN

			 
			EXEC @result = amCalcAssetBookDepr_sp 	
							@co_asset_id,
							@co_asset_book_id,
							0,
							@start_date, 					 
							@prd_end_before_disp, 			 
							0,
							0,
							@acquisition_date,				
							@placed_date,					 
							1,		 					 
							0,
							@cur_precision,					 
							@round_factor, 					 
			 				@cost_when_disp			OUTPUT,  
				 			@accum_depr_when_disp	OUTPUT,  
				 			@prior_prd_depr_expense OUTPUT,	 
							@debug_level

			IF ( @result <> 0 )
				RETURN 		@result 

			SELECT @start_date = @disp_prd_start_date
		END

		
		IF @placed_date > @prd_end_before_disp
			SELECT	@first_time_depr = 1
		ELSE
			SELECT	@first_time_depr = 0
		
		EXEC @result = amApplyStartPeriodActivity_sp 
								@co_asset_book_id, 
								@first_time_depr,
								@start_date,
								@disposition_date,
								@cur_precision,
				 				@cost_when_disp 	 	OUTPUT,
				 				@accum_depr_when_disp 	OUTPUT,
								@disp_co_trx_id,
				 				@debug_level 

		IF ( @result != 0 )
			RETURN @result 

		 
		EXEC @result = amGetCurrentSalvageValue_sp 
								@co_asset_book_id,
								@disposition_date,
								@placed_date,
								@salvage_value OUTPUT 
		IF ( @result <> 0 )
			RETURN 	@result 

		IF 	(@placed_date > @start_date)
		BEGIN 
			
			EXEC @result = amGetDepreciationInfo_sp 
									@co_asset_book_id, 
									@placed_date,
					 				@method_id 		OUTPUT,
					 				@convention_id	OUTPUT,
					 				@debug_level 
			IF ( @result != 0 )
				RETURN @result

		END 
		ELSE 
		BEGIN 
			EXEC @result = amGetDepreciationInfo_sp 
									@co_asset_book_id, 
									@start_date,
					 				@method_id 		OUTPUT,
					 				@convention_id	OUTPUT,
					 				@debug_level 


			IF ( @result != 0 )
				RETURN @result

		END 

		IF @debug_level >= 3
			SELECT 	method_id 		= @method_id 

		IF @method_id IN (0, 7)
		BEGIN
			
			SELECT	@depr_expense = (SIGN(@prior_prd_depr_expense) * ROUND(ABS(@prior_prd_depr_expense) + 0.0000001, @cur_precision))

			IF @debug_level >= 3
			BEGIN
				SELECT "Manual or None method"
				SELECT 	prior_prd_depr_expense 	= @prior_prd_depr_expense,
						depr_expense 			= @depr_expense 
			END
		END 
		ELSE  
		BEGIN 
			

			 
			EXEC @result = amUseFirstYearMethod_sp 
									@start_date,
									@placed_date,
									@in_first_yr 	OUTPUT,
									@debug_level 
			IF ( @result != 0 )
				RETURN @result

			EXEC @result = amCalcYearlyDepr_sp 
									@co_asset_book_id,
									@method_id,	
									@convention_id,
									@start_date,
									@salvage_value,
									@acquisition_date,
									@placed_date,
									@in_first_yr,
									1,					
									@cur_precision,
									@yearly_depr OUTPUT,
									@debug_level
									 
			IF ( @result != 0 )
				RETURN @result

			IF @debug_level >= 3
				SELECT yearly_depr = @yearly_depr 

			EXEC @result = amGetLastYearProportion_sp 
									@placed_date,
									@disposition_date,
									@convention_id,
									@proportion OUTPUT,
									@debug_level 

			IF ( @result != 0 )
				RETURN @result

			IF @in_first_yr = 1
			BEGIN
				
				SELECT @yearly_depr = @yearly_depr * @proportion
				
			 	EXEC @result = amGetDeprYTD_sp 
										@co_asset_book_id,
										@disp_yr_start_date,
										@disposition_date,
										@cur_precision,
										@depr_ytd OUTPUT,
										@debug_level
										
				IF ( @result != 0 )
					RETURN @result
				
				SELECT @depr_expense = (SIGN(@yearly_depr - @depr_ytd) * ROUND(ABS(@yearly_depr - @depr_ytd) + 0.0000001, @cur_precision))
			
				IF @debug_level >= 3
				BEGIN
					SELECT 	"Disposition in First Year"
					SELECT 	yearly_depr = @yearly_depr,
							depr_ytd	= @depr_ytd,
							depr_expr	= @depr_expense 	 
				END
			END
			ELSE
			BEGIN
				


				
				DECLARE
					@even_spread		smLogical	

				
				EXEC @result = amGetFiscalYear_sp 
											@disposition_date, 
											1, 
											@disp_yr_end_date OUT 
		
				IF @result != 0
					RETURN @result
																		

				IF EXISTS(SELECT period_percentage 
					FROM	glprd
					WHERE	period_start_date	BETWEEN 	DATEDIFF(dd, "1/1/1980", @disp_yr_start_date) + 722815
										AND 		DATEDIFF(dd, "1/1/1980", @disp_yr_end_date) + 722815
					AND		period_percentage 	IS NOT NULL
					AND		(ABS((period_percentage)-(0.00)) > 0.0000001)
					)
					SELECT	@even_spread = 0
				ELSE	

					SELECT	@even_spread = 1

				IF @debug_level >= 3
					SELECT even_spread = @even_spread


				IF @even_spread = 1
				BEGIN
					 


					EXEC @result = amGetNumPeriods_sp 
										4,	
										@disp_yr_start_date,
										@prd_end_before_disp,
										@num_prd_before_disp OUTPUT,
										@debug_level 

					IF @result != 0
						RETURN @result
			
					 
					EXEC @result = amGetNumPeriodsPerYear_sp 
										@disp_yr_start_date,
										@num_prd_in_yr OUTPUT,
										@debug_level 

					IF @result != 0
						RETURN @result

					SELECT 	@proportion_taken 	= @num_prd_before_disp
					SELECT	@proportion_taken 	= @proportion_taken / @num_prd_in_yr

					IF @debug_level >= 3
					BEGIN
						SELECT 	"Disposition in Second or Subsequent year"
						SELECT 	prior_prd_depr_expense 	= @prior_prd_depr_expense,
								yearly_depr				= @yearly_depr,
								proportion				= @proportion,
								proportion_taken		= @proportion_taken,
								num_prd_before_disp		= @num_prd_before_disp,
							 	num_prd_in_yr			= @num_prd_in_yr
							 	 
					END


				END
				ELSE 
				BEGIN

					DECLARE @proportion_year float					

					IF @debug_level >= 3
					BEGIN
						SELECT 	disp_yr_start_date = @disp_yr_start_date,
								as_julian			= DATEDIFF(dd, "1/1/1980", @disp_yr_start_date) + 722815,

								prd_end_before_disp = @prd_end_before_disp,
								as_julian			= DATEDIFF(dd, "1/1/1980", @prd_end_before_disp) + 722815
					END


					
					SELECT @proportion_year = ISNULL(SUM(ISNULL(period_percentage, 0.0)), 0.0) 
					FROM	glprd
					WHERE	period_start_date		BETWEEN 	DATEDIFF(dd, "1/1/1980", @disp_yr_start_date) + 722815
					AND 	DATEDIFF(dd, "1/1/1980", @disp_yr_end_date) + 722815


					SELECT @proportion_taken = ISNULL(SUM(ISNULL(period_percentage, 0.0)), 0.0) 
					FROM	glprd
					WHERE	period_start_date		BETWEEN 	DATEDIFF(dd, "1/1/1980", @disp_yr_start_date) + 722815
					AND 	DATEDIFF(dd, "1/1/1980", @prd_end_before_disp) + 722815

		
				 	SELECT @proportion_taken = @proportion_taken / @proportion_year

					IF @debug_level >= 3
					BEGIN
						SELECT 	"Disposition in Second or Subsequent year"
						SELECT 	prior_prd_depr_expense 	= @prior_prd_depr_expense,
							yearly_depr				= @yearly_depr,
							proportion				= @proportion,
							proportion_taken		= @proportion_taken,
							proportion_year			= @proportion_year
						 								 	 
					END


				END	

				SELECT 	@depr_expense 		= @prior_prd_depr_expense + @yearly_depr * (@proportion - @proportion_taken )
			
			 END	

			
			SELECT 	@depr_expense = (SIGN(@depr_expense) * ROUND(ABS(@depr_expense) + 0.0000001, @cur_precision))
		END 
	
		 
		SELECT	@accum_depr_when_disp = (SIGN(@accum_depr_when_disp + @prior_prd_depr_expense) * ROUND(ABS(@accum_depr_when_disp + @prior_prd_depr_expense) + 0.0000001, @cur_precision))
		If @depr_expense < 0
		BEGIN 	
			SET @depr_expense = 0.0	
		END
	END

	
	IF @debug_level >= 3
		SELECT depr_expense 		= @depr_expense,
		 	 accum_depr_when_disp	= @accum_depr_when_disp

	 
	IF @cost_when_disp >= 0.0
	BEGIN
		IF @cost_when_disp + @accum_depr_when_disp - @depr_expense < @salvage_value
		BEGIN
			SELECT	@depr_expense = (SIGN(@cost_when_disp + @accum_depr_when_disp - @salvage_value) * ROUND(ABS(@cost_when_disp + @accum_depr_when_disp - @salvage_value) + 0.0000001, @cur_precision))

			IF @debug_level >= 3
			BEGIN
				SELECT "salvage value exceeded"
				SELECT	@depr_expense = @depr_expense
			END
		END
			
	END
	ELSE 
	BEGIN
		IF @cost_when_disp + @accum_depr_when_disp - @depr_expense > @salvage_value
		BEGIN
			SELECT	@depr_expense = (SIGN(@cost_when_disp + @accum_depr_when_disp - @salvage_value) * ROUND(ABS(@cost_when_disp + @accum_depr_when_disp - @salvage_value) + 0.0000001, @cur_precision))

			IF @debug_level >= 3
			BEGIN
				SELECT "salvage value exceeded"
				SELECT	depr_expense = @depr_expense
			END
		END
	END

END
ELSE
BEGIN
	
			
	SELECT 	@first_time_depr 	= 1,
			@start_date			= @acquisition_date

	EXEC @result = amApplyStartPeriodActivity_sp 
							@co_asset_book_id, 
							@first_time_depr,
							@start_date,
							@disposition_date,
							@cur_precision,
			 				@cost_when_disp			OUTPUT,
			 				@accum_depr_when_disp 	OUTPUT,
							@disp_co_trx_id,
			 				@debug_level 

	IF ( @result != 0 )
		RETURN @result 

END


IF @debug_level >= 3
	SELECT 	
			depr_expense 			= @depr_expense,
			cost_when_disp 			= @cost_when_disp,
			accum_depr_when_disp 	= @accum_depr_when_disp
IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/ambkfldp.sp" + ", line " + STR( 739, 5 ) + " -- EXIT: "

RETURN 0
GO
GRANT EXECUTE ON  [dbo].[amCalcBookFinalDepr_sp] TO [public]
GO
