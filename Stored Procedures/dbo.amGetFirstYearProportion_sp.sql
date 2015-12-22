SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[amGetFirstYearProportion_sp] 
(
 @placed_date smApplyDate, 			
	@convention_id 		smConventionID, 		 
	@proportion 		float 			OUTPUT,	 
	@debug_level		smDebugLevel 	= 0		
)
AS 

DECLARE 
	@error 				smErrorCode, 
	@prd_mid_date 		smApplyDate, 
	@prd_end_date 		smApplyDate, 
	@prd_start_date 	smApplyDate, 
	@nxt_prd_start_date smApplyDate,	 
	@yr_start_date 		smApplyDate, 
	@yr_end_date 		smApplyDate, 
	@qtr_start_date 	smApplyDate, 
	@nxt_qtr_start_date smApplyDate, 
	@num_periods 		smNumPeriods, 
	@prds_in_year 		smNumPeriods, 
	@prds_per_qtr 		smNumPeriods, 
	@days_in_period 	smCounter, 		
	@days_in_use	 	smCounter, 	 	
	@days_per_qtr 		smCounter, 
	@days_per_yr 		smCounter, 
	@days_per_half_qtr 	smCounter, 
	@i 					smCounter,
	@first_prd_prop		float,			 
	@prop_year			float,			
	@from_date 		 smApplyDate,
	@even_spread		smLogical		

 	

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amfstprp.sp" + ", line " + STR( 204, 5 ) + " -- ENTRY: "

IF @debug_level >= 4
	SELECT 	placed_date 	= @placed_date, 
			convention_id 	= @convention_id 

 
IF @convention_id = 0 
	SELECT 	@proportion = 0.5 

ELSE IF @convention_id = 2 
BEGIN 

	EXEC @error = amGetFiscalYear_sp 
							@placed_date, 
							0, 
							@yr_start_date OUT 

	IF @error != 0
		RETURN @error

	EXEC 	@error = amGetNumPeriodsPerYear_sp 
							@yr_start_date, 
							@num_periods OUT 
						 

	IF @error != 0
		RETURN @error

	 
	IF @num_periods % 4 = 0 
	BEGIN 
		 
		SELECT 	@prds_per_qtr 	= @num_periods / 4 
		SELECT 	@qtr_start_date = @yr_start_date 

		SELECT @i = 1 
		WHILE @i < 4 
		BEGIN 
			SELECT @nxt_qtr_start_date = @qtr_start_date 
			EXEC @error = amAddNumPeriods_sp 
								@prds_per_qtr,
								@nxt_qtr_start_date OUT  
			
			IF @error != 0
				RETURN @error

			
			IF @placed_date < @nxt_qtr_start_date 
			BEGIN 
				IF @i = 1 
					SELECT @proportion = .875 
				ELSE 
				BEGIN 
					IF @i = 2 
						SELECT @proportion = .625 
					ELSE 
						SELECT @proportion = .375 
				END 

				IF @debug_level >= 3
					SELECT 	proportion = @proportion 

				IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amfstprp.sp" + ", line " + STR( 269, 5 ) + " -- EXIT: "
				RETURN 0 
			END 
			SELECT @qtr_start_date = @nxt_qtr_start_date
			SELECT @i = @i + 1 

		END 

	 	 
		SELECT @proportion = .125 

		IF @debug_level >= 3
			SELECT 	proportion = @proportion 
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amfstprp.sp" + ", line " + STR( 285, 5 ) + " -- EXIT: "
		RETURN 0 
	
	END 
	ELSE  
	BEGIN 
		 
		EXEC @error = amGetFiscalYear_sp 
								@placed_date, 
								1, 
								@yr_end_date OUT 

		IF @error != 0
			RETURN @error

		SELECT 	@days_per_yr 		= DATEDIFF(day, @yr_start_date, @yr_end_date) + 1 
		SELECT 	@days_per_qtr 		= @days_per_yr / 4 
		SELECT 	@days_per_half_qtr 	= @days_per_qtr / 2 
		SELECT 	@nxt_qtr_start_date = DATEADD(dd, @days_per_qtr, @yr_start_date)

		IF @debug_level >= 5
			SELECT 	days_per_yr			= @days_per_yr,
					days_per_qtr		= @days_per_qtr,
					days_per_half_qtr	= @days_per_half_qtr,
					nxt_qtr_start_date	= @nxt_qtr_start_date

		SELECT 	@i = 1 
		WHILE @i < 4 
		BEGIN 
			IF @placed_date < @nxt_qtr_start_date 
			BEGIN 
				IF @i = 1 
					SELECT @proportion = .875 
				ELSE 
				BEGIN 
					IF @i = 2 
						SELECT @proportion = .625 
					ELSE 
						SELECT @proportion = .375 
				END 

				IF @debug_level >= 3
					SELECT 	proportion = @proportion 

				IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amfstprp.sp" + ", line " + STR( 329, 5 ) + " -- EXIT: "
				RETURN 0 
			END 

			SELECT @qtr_start_date 		= @nxt_qtr_start_date
			SELECT @nxt_qtr_start_date 	= DATEADD(dd, @days_per_qtr, @qtr_start_date)
			SELECT @i = @i + 1 
			
			IF @debug_level >= 5
				SELECT 	i					= @i,
						qtr_start_date		= @qtr_start_date,
						nxt_qtr_start_date	= @nxt_qtr_start_date

		END 
	END 
	
	 
	SELECT @proportion = .125 

	IF @debug_level >= 3
		SELECT 	proportion = @proportion 
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amfstprp.sp" + ", line " + STR( 350, 5 ) + " -- EXIT: "
 	RETURN 0 


END  

ELSE IF @convention_id IN (1, 3, 4, 5)
BEGIN 

		
	
	EXEC @error = amGetFiscalPeriod_sp 
						@placed_date, 
						1, 
						@prd_end_date OUT 

	IF @error != 0
		RETURN @error

	
	EXEC @error = amGetFiscalPeriod_sp 
						@placed_date, 
						0, 
						@prd_start_date OUT 

	IF @error != 0
		RETURN @error

	
	SELECT @nxt_prd_start_date = dateadd(dd, 1, @prd_end_date)
	
	
	EXEC @error = amGetFiscalYear_sp 
						@placed_date, 
						1, 
						@yr_end_date OUT 

	IF @error != 0
		RETURN @error

	EXEC @error = amGetFiscalYear_sp 
							@placed_date, 
							0, 
							@yr_start_date OUT 

	IF @error != 0
		RETURN @error


	IF @debug_level >= 4
	 SELECT 	yr_start_date	= @yr_start_date,
	 		yr_end_date		= @yr_end_date,
	 		prd_start_date	= @prd_start_date,
			 prd_end_date	= @prd_end_date

	
	IF EXISTS(SELECT period_percentage 
			FROM	glprd
			WHERE	period_start_date	BETWEEN 	DATEDIFF(dd, "1/1/1980", @yr_start_date) + 722815
										AND 		DATEDIFF(dd, "1/1/1980", @yr_end_date) + 722815
			AND		period_percentage 	IS NOT NULL
			AND		(ABS((period_percentage)-(0.00)) > 0.0000001)
			)
		SELECT	@even_spread = 0
	ELSE	

		SELECT	@even_spread = 1	


	IF @even_spread = 1
	BEGIN
			
		
		EXEC 	@error = amGetNumPeriodsPerYear_sp 
						@placed_date,
						@prds_in_year OUT 
	
		IF @error != 0
			RETURN @error
	

		IF @convention_id = 1
		BEGIN
			 
			EXEC @error = amGetNumPeriodsInRange_sp 
								@nxt_prd_start_date, 
								@yr_end_date, 
								@num_periods OUT 
	
			IF @error != 0
				RETURN @error

			 
			SELECT 	@proportion = (@num_periods + .5) / @prds_in_year 

		END  

		ELSE IF @convention_id = 3 
		BEGIN 
		 
			 

			EXEC @error = amGetNumPeriodsInRange_sp 
								@nxt_prd_start_date, 
								@yr_end_date, 
								@num_periods OUT 
		
			IF @error != 0
				RETURN @error

			 
			EXEC @error = amGetPeriodMidPoint_sp 
								@placed_date, 
								@prd_mid_date OUT 

			IF @error != 0
				RETURN @error

			IF @placed_date < @prd_mid_date 
				SELECT @num_periods = @num_periods + 1 
			
			IF @debug_level >= 4
				SELECT 	prd_start_date 	= @nxt_prd_start_date,
						yr_end_date 	= @yr_end_date,
						num_periods 	= @num_periods 

			SELECT 	@proportion = @num_periods 	  
			SELECT @proportion = @proportion / @prds_in_year 

		END 
		 
		ELSE IF @convention_id = 4 
		BEGIN 
		 
			 
			EXEC @error = amGetNumPeriodsInRange_sp 
								@prd_start_date, 
								@yr_end_date, 
								@num_periods OUT 
		
			IF @error != 0
				RETURN @error

			IF @debug_level >= 4
				SELECT 	prd_start_date 	= @prd_start_date,
						yr_end_date 	= @yr_end_date,
						num_periods 	= @num_periods 

			SELECT 	@proportion = @num_periods 	  
			SELECT 	@proportion = @proportion / @prds_in_year 

		END  

		ELSE IF @convention_id = 5 
		BEGIN 
		 
			IF @prd_start_date = @placed_date
			BEGIN
				
				EXEC @error = amGetNumPeriodsInRange_sp 
								@prd_start_date, 
								@yr_end_date, 
								@num_periods OUT 
			
				IF @error != 0
					RETURN @error

				 
				SELECT 	@proportion = @num_periods 	  
				SELECT @proportion = @proportion / @prds_in_year 
			END
			ELSE
			BEGIN
				
				EXEC @error = amGetNumPeriodsInRange_sp 
									@nxt_prd_start_date, 
									@yr_end_date, 
									@num_periods OUT 
			
				IF @error != 0
					RETURN @error

				IF @debug_level >= 4
					SELECT 	prd_start_date 		= @prd_start_date,
							yr_end_date 		= @yr_end_date,
							num_whole_periods 	= @num_periods 

				SELECT 	@proportion = @num_periods 	  
				SELECT 	@proportion = @proportion / @prds_in_year 

				
				SELECT	@days_in_period = DATEDIFF(dd, @prd_start_date, @prd_end_date) + 1,
						@days_in_use = DATEDIFF(dd, @placed_date, @prd_end_date)	+ 1

				SELECT	@first_prd_prop = @days_in_use 
				SELECT	@first_prd_prop = @first_prd_prop / ( @days_in_period * @prds_in_year)


				IF @debug_level >= 4
					SELECT 	days_in_use 		= @days_in_use,
							first_prd_prop 		= @first_prd_prop,
							proportion 			= @proportion 

				SELECT @proportion = @proportion + @first_prd_prop

			END

		END 

	END	
	ELSE
	BEGIN 

		SELECT @first_prd_prop = 0.0

		IF @convention_id = 1
		BEGIN
			
			SELECT 	@first_prd_prop 	= ISNULL(period_percentage, 0.0) * 0.5
			FROM	glprd
			WHERE	period_start_date	= DATEDIFF(dd, "1/1/1980", @prd_start_date) + 722815

			
			SELECT @from_date = @nxt_prd_start_date

		
			IF @debug_level >= 5
				SELECT "Mid Month",
						first_prd_prop 	= @first_prd_prop,
						from_date 		= @from_date
		END
		ELSE IF @convention_id = 3 
		BEGIN 
		 
			
			 
			EXEC @error = amGetPeriodMidPoint_sp 
								@placed_date, 
								@prd_mid_date OUT 

			IF @error != 0
				RETURN @error

			IF @placed_date < @prd_mid_date
				SELECT @from_date 	= @prd_start_date
			ELSE	
				SELECT @from_date 	= @nxt_prd_start_date

						
			IF @debug_level >= 4
				SELECT "Full Month",
						first_prd_prop 	= @first_prd_prop,
						from_date 		= @from_date
						

			
		END 

		ELSE IF @convention_id = 4 
		BEGIN 
		 
			SELECT @from_date	= @prd_start_date

			IF @debug_level >= 4
				SELECT "Entire Month",
						first_prd_prop 	= @first_prd_prop,
						from_date 		= @from_date


		END  


		ELSE IF @convention_id = 5
		BEGIN
			SELECT 	@first_prd_prop 	= ISNULL(period_percentage, 0.0) 
			FROM	glprd
			WHERE	period_start_date	= DATEDIFF(dd, "1/1/1980", @prd_start_date) + 722815
			
			SELECT	@days_in_period = DATEDIFF(dd, @prd_start_date, @prd_end_date) + 1,
					@days_in_use = DATEDIFF(dd, @placed_date, @prd_end_date)	+ 1

			SELECT	@first_prd_prop = @first_prd_prop * @days_in_use / @days_in_period
		
			SELECT 	@from_date = @nxt_prd_start_date

		
			IF @debug_level >= 5
				SELECT "Placed in service date",
						first_prd_prop 	= @first_prd_prop,
						from_date 		= @from_date,
						days_in_period = @days_in_period,
						days_in_use		= @days_in_use
		END


		

		SELECT @proportion = @first_prd_prop + ISNULL(SUM(ISNULL(period_percentage, 0.0)), 0.0) 
		FROM	glprd
		WHERE	period_start_date		BETWEEN 	DATEDIFF(dd, "1/1/1980", @from_date) + 722815
										AND 		DATEDIFF(dd, "1/1/1980", @yr_end_date) + 722815

		
 		SELECT 	@prop_year 			= ISNULL(SUM(ISNULL(period_percentage, 0.0)), 0.0) 
 		FROM	glprd
		WHERE	period_start_date	BETWEEN 	DATEDIFF(dd, "1/1/1980", @yr_start_date) + 722815		
										AND 	DATEDIFF(dd, "1/1/1980", @yr_end_date) + 722815

	
		IF @debug_level >= 5
			select from_date 	= @from_date,
			first_prd_prop 		= @first_prd_prop,
			prop_year			= @prop_year,
			proportion			= @proportion

	 SELECT @proportion = @proportion / @prop_year

	END	

END	


IF @debug_level >= 3
	SELECT 	proportion = @proportion 

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amfstprp.sp" + ", line " + STR( 714, 5 ) + " -- EXIT: "
RETURN 0 
GO
GRANT EXECUTE ON  [dbo].[amGetFirstYearProportion_sp] TO [public]
GO
