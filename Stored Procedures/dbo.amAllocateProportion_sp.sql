SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE [dbo].[amAllocateProportion_sp] 
( 	
	@first_year			smLogical,			
	@years_depr_exp	 	smMoneyZero,		
	@ytd_depr_exp	 	smMoneyZero,		
	@from_date 			smApplyDate, 		 
	@to_date 			smApplyDate, 		 
	@convention_id 		smConventionID, 	 
	@curr_precision		smallint,			
	@calc_depr_exp		smMoneyZero OUTPUT,	
	@debug_level		smDebugLevel 	= 0 
)
AS 

DECLARE 
	@result			 			smErrorCode, 
	@prop_first_prd				float, 				
	@prop_depreciated			float, 				
	@prop_year					float,				
	@prop_year_remaining		float,				
	@even_spread				smLogical,			
	@period_depr_exp			smMoneyZero, 		
	@prd_start_date				smApplyDate,	 	
	@prd_end_date				smApplyDate,		
	@year_start_date 			smApplyDate, 		
	@year_end_date 				smApplyDate, 		
	@days_in_period				smCounter,			
	@days_in_use				smCounter,			
	@num_periods				float				


IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amalcprp.sp" + ", line " + STR( 122, 5 ) + " -- ENTRY: "

IF @debug_level >= 3
	SELECT 	years_depr_exp 		= @years_depr_exp,
			from_date		 	= @from_date, 
			to_date 			= @to_date, 
			year_end_date 		= @year_end_date, 
			convention_id 		= @convention_id 

	
 
EXEC @result = amGetFiscalYear_sp 
						@from_date,
						0,
						@year_start_date OUTPUT 

IF @result <> 0
	RETURN @result

EXEC @result = amGetFiscalYear_sp 
						@from_date,
						1,
						@year_end_date OUTPUT 

IF @result <> 0
	RETURN @result
	

IF EXISTS(SELECT period_percentage 
			FROM	glprd
			WHERE	period_start_date	BETWEEN 	DATEDIFF(dd, "1/1/1980", @year_start_date) + 722815
										AND 		DATEDIFF(dd, "1/1/1980", @year_end_date) + 722815
			AND		period_percentage 	IS NOT NULL
			AND		(ABS((period_percentage)-(0.00)) > 0.0000001))
	SELECT	@even_spread = 0
ELSE
	SELECT	@even_spread = 1
	
IF @even_spread = 1
BEGIN
	 
	IF @first_year = 1
	BEGIN
		 
		EXEC @result = amGetNumPeriods_sp 
								@convention_id,
								@from_date,
								@year_end_date,
								@num_periods OUTPUT,
								@debug_level 

		IF ( @result != 0 )
			RETURN @result

		 
		SELECT @period_depr_exp = (SIGN((@years_depr_exp - @ytd_depr_exp) / @num_periods) * ROUND(ABS((@years_depr_exp - @ytd_depr_exp) / @num_periods) + 0.0000001, @curr_precision)) 
	END
	ELSE
	BEGIN
		

		EXEC @result = amGetNumPeriodsPerYear_sp 
								@from_date,
								@num_periods OUTPUT 
		IF ( @result != 0 )
			RETURN @result

		 
		SELECT @period_depr_exp = (SIGN(@years_depr_exp / @num_periods) * ROUND(ABS(@years_depr_exp / @num_periods) + 0.0000001, @curr_precision)) 
	END

	
	
	EXEC @result = amGetNumPeriods_sp 
							@convention_id,
							@from_date,
							@to_date,
							@num_periods OUTPUT,
							@debug_level 

	IF ( @result != 0 )
		RETURN @result

	 
	SELECT 	@calc_depr_exp = (SIGN(@period_depr_exp * @num_periods) * ROUND(ABS(@period_depr_exp * @num_periods) + 0.0000001, @curr_precision))
	
	IF @debug_level >= 3
		SELECT 	period_depr_exp 	= @period_depr_exp,
				num_periods 		= @num_periods,
				calc_depr_exp 		= @calc_depr_exp 

END
ELSE 
BEGIN
	
	EXEC @result = amGetFiscalPeriod_sp 
						@from_date, 
						0, 
						@prd_start_date OUT
	IF @result != 0
		RETURN @result

	SELECT @prop_first_prd = 0.0

	IF @debug_level >= 5
		SELECT from_date 	 	= @from_date,
				prd_start_date 	= @prd_start_date,
				prd_end_date 	= @prd_end_date

	IF 	@from_date != @prd_start_date
	BEGIN
		
		EXEC @result = amGetFiscalPeriod_sp 
							@from_date, 
							1, 
							@prd_end_date OUT 

		IF @result != 0
			RETURN @result
		
		
		IF @debug_level >= 5
			SELECT	convention_id 	= @convention_id,
					prd_start_date 	= @prd_start_date,
					prd_end_date 	= @prd_end_date
		
		IF @convention_id = 1
		BEGIN
			
			SELECT 	@prop_first_prd 	= ISNULL(period_percentage, 0.0) / 100.00 * 0.5
			FROM	glprd
			WHERE	period_start_date	= DATEDIFF(dd, "1/1/1980", @prd_start_date) + 722815

			SELECT @from_date = DATEADD(dd, 1, @prd_end_date)
		
			IF @debug_level >= 5
				SELECT "Mid Month",
						prop_first_prd 	= @prop_first_prd,
						from_date 		= @from_date
		END

		ELSE IF @convention_id = 5
		BEGIN
			SELECT 	@prop_first_prd 	= ISNULL(period_percentage, 0.0) / 100.00
			FROM	glprd
			WHERE	period_start_date	= DATEDIFF(dd, "1/1/1980", @prd_start_date) + 722815
			
			SELECT	@days_in_period = DATEDIFF(dd, @prd_start_date, @prd_end_date) + 1,
					@days_in_use = DATEDIFF(dd, @from_date, @prd_end_date)	+ 1

			SELECT	@prop_first_prd = @prop_first_prd * @days_in_use / @days_in_period
		
			SELECT 	@from_date = DATEADD(dd, 1, @prd_end_date)
		
			IF @debug_level >= 5
				SELECT "Placed in service date",
						prop_first_prd 	= @prop_first_prd,
						from_date 		= @from_date
		END
		
	END

	
	SELECT 	@prop_depreciated 		= @prop_first_prd + ISNULL(SUM(ISNULL(period_percentage, 0.0)), 0.0)	/ 100.00
	FROM	glprd
	WHERE	period_start_date		BETWEEN 	DATEDIFF(dd, "1/1/1980", @from_date) + 722815
										AND 		DATEDIFF(dd, "1/1/1980", @to_date) + 722815
	IF @first_year = 1
	BEGIN
		
		SELECT 	@prop_year 			= ISNULL(SUM(ISNULL(period_percentage, 0.0)), 0.0) / 100.00
		FROM	glprd
		WHERE	period_start_date	BETWEEN 	DATEDIFF(dd, "1/1/1980", @year_start_date) + 722815
										AND 	DATEDIFF(dd, "1/1/1980", @year_end_date) + 722815
	 	
		SELECT 	@prop_year_remaining 	= @prop_first_prd + ISNULL(SUM(ISNULL(period_percentage, 0.0)), 0.0) / 100.00
		FROM	glprd
		WHERE	period_start_date		BETWEEN 	DATEDIFF(dd, "1/1/1980", @from_date) + 722815
										AND 		DATEDIFF(dd, "1/1/1980", @year_end_date) + 722815
		 
		IF @prop_depreciated <> 0.0
			SELECT @calc_depr_exp = 
(SIGN((@years_depr_exp * @prop_year - @ytd_depr_exp) * @prop_depreciated / @prop_year_remaining) * ROUND(ABS((@years_depr_exp * @prop_year - @ytd_depr_exp) * @prop_depreciated / @prop_year_remaining) + 0.0000001, @curr_precision))
		ELSE
			SELECT @calc_depr_exp = 0.0
		
		IF @debug_level >= 5
			SELECT 	prop_year				= @prop_year,
					prop_depreciated 		= @prop_depreciated,
					prop_year_remaining 	= @prop_year_remaining
	END
	ELSE
	BEGIN
		 
		SELECT @calc_depr_exp = (SIGN(@years_depr_exp * @prop_depreciated) * ROUND(ABS(@years_depr_exp * @prop_depreciated) + 0.0000001, @curr_precision))
		
		IF @debug_level >= 5
			SELECT 	prop_depreciated 		= @prop_depreciated
	END

END

IF @debug_level >= 3
	SELECT 	even_spread 		= @even_spread,
			years_depr_exp		= @years_depr_exp,
			prop_depreciated 	= @prop_depreciated, 
			num_periods		 	= @num_periods, 
			calc_depr_exp 		= @calc_depr_exp 

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amalcprp.sp" + ", line " + STR( 374, 5 ) + " -- EXIT: "

RETURN 0 
GO
GRANT EXECUTE ON  [dbo].[amAllocateProportion_sp] TO [public]
GO
