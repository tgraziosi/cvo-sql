SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[amGetLastYearProportion_sp] 
(
 @placed_date smApplyDate, 			
	@disposed_date		smApplyDate,			
	@convention_id 		smConventionID, 		 
	@proportion 		float 			OUTPUT,	 
	@debug_level		smDebugLevel 	= 0		
)
AS 

DECLARE 
	@result 				smErrorCode, 	
	@nxt_prd_start_date 	smApplyDate,	 
	@disp_yr_start_date 	smApplyDate, 	
	@disp_yr_end_date 		smApplyDate, 	
	@prd_start_after_placed	smApplyDate,	
	@prd_end_before_disp	smApplyDate,	
	@disp_prd_start_date	smApplyDate,	
	@disp_prd_end_date		smApplyDate,	
	@placed_prd_start_date	smApplyDate,	
	@placed_prd_end_date	smApplyDate,	
	@disp_prd_mid_point		smApplyDate, 	
	@placed_prd_mid_point	smApplyDate, 	
	@num_prds_in_yr_disp	smNumPeriods, 	
	@num_periods 			smNumPeriods
	
DECLARE
	@days_in_period 		float, 			
	@days_in_use	 		float, 	 		
	@first_prd_prop			float,	 		 
	@last_prd_prop			float	 		 
	
DECLARE 
	@from_start_date 		smApplyDate, 	
	@to_start_date 		smApplyDate,
	@proportion_year		float		 	
	
 

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amlstprp.sp" + ", line " + STR( 183, 5 ) + " -- ENTRY: "

IF @debug_level >= 4
	SELECT 	placed_date 	= @placed_date, 
			disposed_date	= @disposed_date,
			convention_id 	= @convention_id 

IF 	@placed_date IS NULL
OR	@placed_date > @disposed_date
BEGIN
	SELECT 	@proportion = 0.0			 

	IF @debug_level >= 3
		SELECT 	proportion 	= @proportion 

	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amlstprp.sp" + ", line " + STR( 198, 5 ) + " -- EXIT: "
	RETURN 0			
END

 
IF @convention_id = 0 
BEGIN
	SELECT 	@proportion = 0.5 

	IF @debug_level >= 3
		SELECT 	proportion 	= @proportion 

	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amlstprp.sp" + ", line " + STR( 213, 5 ) + " -- EXIT: "
	RETURN 0			
END


EXEC @result = amGetFiscalYear_sp 
						@disposed_date, 
						0, 
						@disp_yr_start_date OUT 

IF @result != 0
	RETURN @result

EXEC @result = amGetFiscalYear_sp 
						@disposed_date, 
						1, 
						@disp_yr_end_date OUT 

IF @result != 0
	RETURN @result


EXEC @result = amGetNumPeriodsPerYear_sp 
						@disp_yr_start_date, 
						@num_prds_in_yr_disp OUT 
					 

IF @result != 0
	RETURN @result


IF @convention_id = 2 
BEGIN 
	IF @debug_level >= 3
		SELECT "Mid QTR"

	DECLARE 
		@qtr_start_date 		smApplyDate, 
		@nxt_qtr_start_date 	smApplyDate, 
		@prds_per_qtr 			smNumPeriods, 
		@days_per_qtr 			smCounter, 
		@days_per_yr 			smCounter, 
		@days_per_half_qtr 		smCounter, 
		@i 				 		smCounter,
		@first_prop				float

	 
	IF @num_prds_in_yr_disp % 4 = 0 
	BEGIN 
		IF @debug_level >= 3
			SELECT "Periods divisable by 4"

		SELECT 	@prds_per_qtr 	= @num_prds_in_yr_disp / 4 
		SELECT 	@qtr_start_date = @disp_yr_start_date 

		SELECT @i = 1 
		WHILE @i < 4 
		BEGIN 
			SELECT @nxt_qtr_start_date = @qtr_start_date 
			EXEC @result = amAddNumPeriods_sp 
								@prds_per_qtr,
								@nxt_qtr_start_date OUT  
			
			IF @result != 0
				RETURN @result

			
			IF @disposed_date < @nxt_qtr_start_date 
			BEGIN 
				IF @i = 1 
					SELECT @proportion = .125 
				ELSE 
				BEGIN 
					IF @i = 2 
						SELECT @proportion = .375 
					ELSE 
						SELECT @proportion = .625 
				END 

				IF @debug_level >= 3
					SELECT 	proportion = @proportion 

				BREAK 
			END 
			SELECT @qtr_start_date = @nxt_qtr_start_date
			SELECT @i = @i + 1 

		END 

	 	 
		IF @i = 4
			SELECT @proportion = .875 
	END 
	ELSE  
	BEGIN
		IF @debug_level >= 3
		 SELECT "Periods not divisable by 4" 

		 
		SELECT 	@days_per_yr 		= DATEDIFF(day, @disp_yr_start_date, @disp_yr_end_date) + 1 
		SELECT 	@days_per_qtr 		= @days_per_yr / 4 
		SELECT 	@days_per_half_qtr 	= @days_per_qtr / 2 
		SELECT 	@nxt_qtr_start_date = DATEADD(dd, @days_per_qtr, @disp_yr_start_date)
		SELECT @i = 1 

		WHILE @i < 4 
		BEGIN 
			IF @debug_level >= 3
				SELECT placed_date=@placed_date,nxt_qtr_start_date=@nxt_qtr_start_date,days_per_qtr=@days_per_qtr

			IF @disposed_date < @nxt_qtr_start_date 
			BEGIN 
				IF @i = 1 
					SELECT @proportion = .125 
				ELSE 
				BEGIN 
					IF @i = 2 
						SELECT @proportion = .375 
					ELSE 
						SELECT @proportion = .625 
				END 

				IF @debug_level >= 3
					SELECT 	proportion = @proportion 

				BREAK 
			END 

			SELECT @qtr_start_date 		= @nxt_qtr_start_date
			SELECT @nxt_qtr_start_date 	= DATEADD(dd, @days_per_qtr, @qtr_start_date)
			SELECT @i = @i + 1 
		END 

	END 
	
	 
	IF @i = 4
		SELECT @proportion = .875 

	IF @placed_date >= @disp_yr_start_date
	BEGIN

		IF @debug_level >= 2
			SELECT "Asset placed in same year disposed"
			
		

		IF @num_prds_in_yr_disp % 4 = 0 
		BEGIN 
			SELECT 	@qtr_start_date = @disp_yr_start_date 

			SELECT @i = 1 
			WHILE @i < 4 
			BEGIN 
				SELECT @nxt_qtr_start_date = @qtr_start_date 
				EXEC @result = amAddNumPeriods_sp 
									@prds_per_qtr,
									@nxt_qtr_start_date OUT  
				
				IF @result != 0
					RETURN @result

				IF @debug_level >= 3
				 SELECT placed_date = @placed_date,nxt_qtr_start_date=@nxt_qtr_start_date,prds_per_qtr = @prds_per_qtr

				IF @placed_date < @nxt_qtr_start_date 
				BEGIN 
					IF @i = 1 
						SELECT @first_prop = 0.125
					ELSE 
					BEGIN 
						IF @i = 2 
							SELECT @first_prop = 0.375
						ELSE 
							SELECT @first_prop = 0.625
					END 

					
					BREAK 
				END 
				SELECT @qtr_start_date = @nxt_qtr_start_date
				SELECT @i = @i + 1 

			END 

		 	 
			IF @i = 4
				SELECT @first_prop = 0.875 

			IF @debug_level >= 3
					SELECT 	proportion = @proportion,first_prop = @first_prop 


		END 
		ELSE  
		BEGIN 
			SELECT @nxt_qtr_start_date = DATEADD(dd, @days_per_qtr, @disp_yr_start_date)
			SELECT @i = 1 

			WHILE @i < 4 
			BEGIN 
				IF @placed_date < @nxt_qtr_start_date 
				BEGIN 
					IF @i = 1 
						SELECT @first_prop = 0.125
					ELSE 
					BEGIN 
						IF @i = 2 
							SELECT @first_prop = 0.375 
						ELSE 
							SELECT @first_prop = 0.625 
					END 

					IF @debug_level >= 3
						SELECT 	first_prop = @first_prop 

					BREAK
				END 

				SELECT @qtr_start_date 		= @nxt_qtr_start_date
				SELECT @nxt_qtr_start_date 	= DATEADD(dd, @days_per_qtr, @qtr_start_date)
				SELECT @i 					= @i + 1 
			END 

		END 
		
		IF @i = 4
			SELECT @first_prop = 0.875
			
		SELECT @proportion = @proportion - @first_prop 

	END
	
END  

ELSE IF @convention_id IN (1, 3, 4, 5)
BEGIN 
	
	DECLARE
		@even_spread		smLogical,	


		@num_full_prds	smCounter	
									
	
	EXEC @result = amGetFiscalPeriod_sp 
						@disposed_date, 
						0, 
						@disp_prd_start_date OUT 

	IF @result != 0
		RETURN @result

	EXEC @result = amGetFiscalPeriod_sp 
						@disposed_date, 
						1, 
						@disp_prd_end_date OUT 

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


	IF @even_spread = 1
	BEGIN

		
		
		SELECT @prd_end_before_disp = DATEADD(dd, -1, @disp_prd_end_date)


		
		

		IF @placed_date < @disp_yr_start_date
		BEGIN
			 
			EXEC @result = amGetNumPeriodsInRange_sp 
							@disp_yr_start_date, 
							@prd_end_before_disp, 
							@num_full_prds OUT 

			IF @result != 0
				RETURN @result
		END
		ELSE
		BEGIN
			EXEC @result = amGetFiscalPeriod_sp 
							@placed_date, 
							1, 
							@prd_start_after_placed OUT 

			IF @result != 0
				RETURN @result

			SELECT @prd_start_after_placed = DATEADD( dd, 1, @prd_start_after_placed)
		
			EXEC @result = amGetNumPeriodsInRange_sp 
							@prd_start_after_placed, 
							@prd_end_before_disp, 
							@num_full_prds OUT 

			IF @result != 0
				RETURN @result


		END

		IF @debug_level >= 2
			SELECT	prd_start_after_placed 	= @prd_start_after_placed,
					num_full_prds 			= @num_full_prds,
					num_prds_in_yr_disp		= @num_prds_in_yr_disp
				
		
 	
		
	
		IF @convention_id = 1
		BEGIN
			IF @placed_date < @disp_yr_start_date
				 
				SELECT 	@proportion = @num_full_prds + .5 
			ELSE 	
			BEGIN
				IF @placed_date < @disp_prd_start_date		
					SELECT 	@proportion = @num_full_prds + 1 	 	  
				ELSE 
					SELECT 	@proportion = 0.5 
			END		
	
			SELECT	@proportion = @proportion / @num_prds_in_yr_disp

		END 	 

		ELSE IF @convention_id = 3 
		BEGIN 
			EXEC @result = amGetPeriodMidPoint_sp 
							@disposed_date, 
							@disp_prd_mid_point OUT 

			IF @result != 0
				RETURN @result
		 
			IF @placed_date < @disp_yr_start_date
			BEGIN	
				 
				IF @disposed_date >= @disp_prd_mid_point 
					SELECT 	@num_periods = @num_full_prds + 1 
				ELSE	
					SELECT	@num_periods = @num_full_prds
				
			END
			ELSE	
			BEGIN
				IF @placed_date < @disp_prd_start_date
				BEGIN
					 
					IF @disposed_date >= @disp_prd_mid_point 
						SELECT @num_periods = @num_full_prds + 1 
					ELSE	
						SELECt	@num_periods = @num_full_prds
						
					 
					EXEC @result = amGetPeriodMidPoint_sp 
									@placed_date, 
									@placed_prd_mid_point OUT 

					IF @result != 0
						RETURN @result

					IF @placed_date < @placed_prd_mid_point 
						SELECT @num_periods = @num_periods + 1 
				END	
				ELSE	
				BEGIN
					IF 	@disposed_date 	>= @disp_prd_mid_point 
					AND	@placed_date	< @disp_prd_mid_point
						SELECT 	@num_periods = 1 
					ELSE
						SELECT	@num_periods = 0
				END 
			END

			IF @debug_level >= 4
				SELECT 	num_periods 		= @num_periods 

		 	SELECT 	@proportion = @num_periods 	  
			SELECT @proportion = @proportion / @num_prds_in_yr_disp 

		END 
	 
		ELSE IF @convention_id = 4 
		BEGIN 
		 
			IF @placed_date < @disp_yr_start_date
				SELECT @num_periods = @num_full_prds + 1

			ELSE
			BEGIN
				IF @placed_date < @disp_prd_start_date
					SELECT @num_periods = @num_full_prds + 2	
				ELSE										 
					SELECT @num_periods = 1					 	

			END

			IF @debug_level >= 4
				SELECT 	disp_prd_start_date 	= @disp_prd_start_date,
						disp_yr_end_date 		= @disp_yr_end_date,
						num_periods 			= @num_periods 

			SELECT 	@proportion = @num_periods 	  
			SELECT 	@proportion = @proportion / @num_prds_in_yr_disp 

		END  

		ELSE IF @convention_id = 5 
		BEGIN 

		 	IF @placed_date < @disp_yr_start_date
			BEGIN 
				
				IF @debug_level >= 4
					SELECT 	disp_prd_start_date = @disp_prd_start_date,
							disp_yr_end_date 	= @disp_yr_end_date,
							num_full_prds 		= @num_full_prds 
				
				SELECT	@days_in_period = DATEDIFF(dd, @disp_prd_start_date, @disp_prd_end_date) + 1,
						@days_in_use = DATEDIFF(dd, @disp_prd_start_date, @disposed_date)	

				IF @days_in_use = @days_in_period
					SELECT	@num_periods 	= @num_full_prds + 1,
							@last_prd_prop	= 0.0
						
				ELSE
				BEGIN
					SELECT	@num_periods 	= @num_full_prds,
							@last_prd_prop 	= @days_in_use 
					SELECT	@last_prd_prop 	= @last_prd_prop / ( @days_in_period * @num_prds_in_yr_disp)
				END


				SELECT 	@proportion = @num_periods 	  
				SELECT 	@proportion = @proportion / @num_prds_in_yr_disp 

				SELECT @proportion = @proportion + @last_prd_prop

				IF @debug_level >= 4
					SELECT 	days_in_use 		= @days_in_use,
							last_prd_prop 		= @last_prd_prop,
							proportion 			= @proportion 

			END
			ELSE	
			BEGIN
				IF @placed_date < @disp_prd_start_date
				BEGIN

					IF @debug_level >= 4
						SELECT 	disp_prd_start_date = @disp_prd_start_date,
								disp_yr_end_date 	= @disp_yr_end_date,
								num_full_prds	 	= @num_full_prds 
					
					EXEC @result = amGetFiscalPeriod_sp 
											@placed_date, 
											0, 
											@placed_prd_start_date OUT 

					IF @result != 0
						RETURN @result

					EXEC @result = amGetFiscalPeriod_sp 
											@placed_date, 
											1, 
											@placed_prd_end_date OUT 

					IF @result != 0
						RETURN @result

					SELECT	@days_in_period = DATEDIFF(dd, @placed_prd_start_date, @placed_prd_end_date) + 1,
							@days_in_use = DATEDIFF(dd, @placed_date, @placed_prd_end_date)	+ 1

					IF @days_in_use = @days_in_period
						SELECT	@num_periods 	= @num_full_prds + 1,
								@first_prd_prop	= 0.0
							
					ELSE
					BEGIN
						SELECT	@num_periods 	= @num_full_prds,
								@first_prd_prop = @days_in_use 
						SELECT	@first_prd_prop = @first_prd_prop / ( @days_in_period * @num_prds_in_yr_disp)
					END


					
					SELECT	@days_in_period = DATEDIFF(dd, @disp_prd_start_date, @disp_prd_end_date) + 1,
							@days_in_use = DATEDIFF(dd, @disp_prd_start_date, @disposed_date)	

					IF @days_in_use = @days_in_period
						SELECT	@num_periods 	= @num_periods + 1,
								@last_prd_prop	= 0.0
							
					ELSE
					BEGIN
						SELECT	@last_prd_prop = @days_in_use 
						SELECT	@last_prd_prop = @last_prd_prop / ( @days_in_period * @num_prds_in_yr_disp)
					END


					SELECT 	@proportion = @num_periods 	  
					SELECT 	@proportion = @proportion / @num_prds_in_yr_disp 

					SELECT @proportion = @proportion + @last_prd_prop + @first_prd_prop

					IF @debug_level >= 4
						SELECT 	days_in_use 		= @days_in_use,
								first_prd_prop 		= @first_prd_prop,
								last_prd_prop 		= @last_prd_prop,
								proportion 			= @proportion 
				END
				ELSE 
				BEGIN
					SELECT	@days_in_period = DATEDIFF(dd, @disp_prd_start_date, @disp_prd_end_date) + 1,
							@days_in_use = DATEDIFF(dd, @placed_date, @disposed_date)	

					SELECT	@proportion = @days_in_use 
					SELECT	@proportion = @proportion / ( @days_in_period * @num_prds_in_yr_disp)

				END
			END

		END 
	END	
	ELSE 
	BEGIN 

		
		SELECT	@last_prd_prop = 0.0,
				@first_prd_prop = 0.0

		
		SELECT @prd_end_before_disp = DATEADD(dd, -1, @disp_prd_start_date)


		

		SELECT @from_start_date	= @disp_yr_start_date
	 	
		IF @debug_level >= 2
			SELECT "***** Uneven Spread",
				 disp_yr_start_date=	 @disp_yr_start_date,
				 disp_yr_end_date= @disp_yr_end_date,
				 disp_prd_start_date=	 @disp_prd_start_date,
				 disp_prd_end_date= @disp_prd_end_date
	
		
		IF @convention_id = 1
		BEGIN

			IF @debug_level >= 2
				SELECT "Mid Month"

			


			 			
			SELECT 	@last_prd_prop 	= ISNULL(period_percentage, 0.0) * 0.5
			FROM	glprd
			WHERE	period_start_date	= DATEDIFF(dd, "1/1/1980", @disp_prd_start_date) + 722815
	
				
			SELECT @to_start_date = @prd_end_before_disp	
		
		 			 
			
			IF @placed_date >= @disp_yr_start_date
			BEGIN

				IF @placed_date < @disp_prd_start_date
				BEGIN
			
					 
					EXEC @result = amGetFiscalPeriod_sp 
								@placed_date, 
								0, 
								@from_start_date OUT

					IF @result != 0
					BEGIN
						IF @debug_level >= 2
							SELECT "*Error: amGetFiscalPeriod_sp DATE_START:",placed_date=@placed_date,disp_yr_start_date=@disp_yr_start_date, disp_prd_start_date= @disp_prd_start_date

						RETURN @result
					END

		
					SELECT 	@first_prd_prop 	= ISNULL(period_percentage, 0.0) * 0.5
					FROM	glprd
					WHERE	period_start_date	= DATEDIFF(dd, "1/1/1980", @from_start_date) + 722815
			 
				END 	 	
		 
		 		
		 		EXEC @result = amGetFiscalPeriod_sp 
								@placed_date, 
								1, 
								@from_start_date OUT

			 	IF @result != 0
				BEGIN
						IF @debug_level >= 2
							SELECT "*Error: amGetFiscalPeriod_sp DATE_END:",placed_date=@placed_date,disp_yr_start_date=@disp_yr_start_date, disp_prd_start_date= @disp_prd_start_date

						RETURN @result
				END
			
				SELECT @from_start_date = DATEADD( dd, 1, @from_start_date)
			END		
	
		
		END 	 


		
		ELSE IF @convention_id = 3 
		BEGIN

			IF @debug_level >= 2
				SELECT "Full Month"

		
			EXEC @result = amGetPeriodMidPoint_sp 
								@disposed_date, 
								@disp_prd_mid_point OUT 

			IF @result != 0
				RETURN @result
		 
			 
			IF @disposed_date >= @disp_prd_mid_point
			 
				SELECT @to_start_date = @disp_prd_start_date

			ELSE
					
				SELECT @to_start_date = @prd_end_before_disp


			IF @placed_date > @disp_yr_start_date	 
			
			BEGIN
			 									
				 
				EXEC @result = amGetPeriodMidPoint_sp 
									@placed_date, 
									@placed_prd_mid_point OUT 

				IF @result != 0
					RETURN @result

				IF @placed_date < @placed_prd_mid_point 
				BEGIN
					 
					EXEC @result = amGetFiscalPeriod_sp 
								@placed_date, 
								0, 
								@from_start_date OUT

					IF @result != 0
						RETURN @result 		


				END
				ELSE
				BEGIN
					
					EXEC @result = amGetFiscalPeriod_sp 
								@placed_date, 
								1, 
								@from_start_date OUT

					IF @result != 0
						RETURN @result

					SELECT @from_start_date = DATEADD( dd, 1, @from_start_date)


				END
			END

		END 
	
		 	 
		ELSE IF @convention_id = 4 
		BEGIN 

			IF @debug_level >= 2
				SELECT "Entire Month"

		
									 
			SELECT @to_start_date = @disp_prd_start_date 
		 
		
			IF @placed_date > @disp_yr_start_date
			BEGIN

				 
				 EXEC @result = amGetFiscalPeriod_sp 
								@placed_date, 
								0, 
								@from_start_date OUT

				 IF @result != 0
					RETURN @result

		 
			END	
			 		
		END 

		ELSE IF @convention_id = 5 
		BEGIN 

			IF @debug_level >= 2
				SELECT "Placed Date"

	 
		  			 
		 						
			 	
			IF @placed_date <= @disp_prd_start_date
					SELECT @to_start_date = @disp_prd_start_date
		 	ELSE
					SELECT @to_start_date = @placed_date

	 		SELECT	@days_in_period = DATEDIFF(dd, @disp_prd_start_date, @disp_prd_end_date) + 1,
					@days_in_use = DATEDIFF(dd, @to_start_date, @disposed_date)	
					 
			SELECT @proportion = @days_in_use / @days_in_period
		 
		 	 			
		 	SELECT 	@last_prd_prop 	= ISNULL(period_percentage, 0.0) 
	 		FROM	glprd
		 	WHERE	period_start_date	= DATEDIFF(dd, "1/1/1980", @disp_prd_start_date) + 722815

			

			IF @debug_level >= 2
			BEGIN
				SELECT 	"last_period_proportion"
				SELECT 	disp_prd_start_date	=	@disp_prd_start_date,
					 	disp_prd_end_date	=	@disp_prd_end_date,
					 	days_in_period		=	@days_in_period
				SELECT 	to_start_date		=	@to_start_date,
						disposed_date		=	@disposed_date,
						days_in_use			=	@days_in_use
				SELECT 	days_in_period		= 	@proportion,
						last_prd_prop	= 	@last_prd_prop,
						days_in_proportion = @last_prd_prop * @proportion
						

			END

			SELECT @last_prd_prop = @last_prd_prop * @proportion 
			
						
			
			SELECT @to_start_date = @prd_end_before_disp

		
			
			IF @placed_date > @disp_yr_start_date 
			BEGIN
		 
				
				EXEC @result = amGetFiscalPeriod_sp 
										@placed_date, 
										0, 
										@placed_prd_start_date OUT
				IF @result != 0
						RETURN @result

				EXEC @result = amGetFiscalPeriod_sp 
										@placed_date, 
										1, 
										@placed_prd_end_date OUT 

				IF @result != 0
					RETURN @result

				IF @placed_date < @disp_prd_start_date
				BEGIN
				
					SELECT	@days_in_period = DATEDIFF(dd, @placed_prd_start_date, @placed_prd_end_date) + 1,
							@days_in_use = DATEDIFF(dd, @placed_date, @placed_prd_end_date)	+ 1


					SELECT @proportion = @days_in_use / @days_in_period
		 
		 			 			
				 	SELECT 	@first_prd_prop 	= ISNULL(period_percentage, 0.0) 
		 			FROM	glprd
		 			WHERE	period_start_date	= DATEDIFF(dd, "1/1/1980", @placed_prd_start_date) + 722815

					IF @debug_level >= 2
					BEGIN
						SELECT 	"first_period_proportion"
						SELECT 	placed_prd_start_date	=	@placed_prd_start_date,	
								placed_prd_end_date		=	@placed_prd_end_date,
								days_in_period			=	@days_in_period
						SELECT 	placed_date				=	@placed_date,
								placed_prd_end_date		=	@placed_prd_end_date,
								days_in_use				=	@days_in_use
						SELECT 	days_in_period			= 	@proportion,
								first_prd_prop	= 	@first_prd_prop,
								days_in_proportion 	= @first_prd_prop * @proportion


					END

					SELECT @first_prd_prop = @first_prd_prop * @proportion


				END

				
				SELECT @from_start_date = DATEADD( dd, 1,@placed_prd_end_date)
		

			END	
						

		END 

		
		IF @debug_level >= 3
		BEGIN
			SELECT "Calculations for all conventions: "
	 
			SELECT 	first_prd_prop=@first_prd_prop,
					last_prd_prop =@last_prd_prop,
					from_start_date=@from_start_date,
					to_start_date=@to_start_date
		END

	
		 
		EXEC @result = amGetFiscalPeriod_sp 
								@to_start_date, 
								0, 
								@to_start_date OUT 

		IF @result != 0
		BEGIN
		 IF @debug_level >= 2
				SELECT "*Error: amGetFiscalPeriod_sp DATE_START:",to_start_date=@to_start_date,disp_yr_start_date=@disp_yr_start_date, disp_prd_start_date= @disp_prd_start_date
		 RETURN @result
		END


		
		
		SELECT 	@proportion = @first_prd_prop + @last_prd_prop
	
		SELECT @proportion = @proportion + ISNULL(SUM(ISNULL(period_percentage, 0.0)), 0.0) 
		FROM	glprd
		WHERE	period_start_date		BETWEEN 	DATEDIFF(dd, "1/1/1980", @from_start_date) + 722815
										AND 	DATEDIFF(dd, "1/1/1980", @to_start_date) + 722815

		
		SELECT @proportion_year = ISNULL(SUM(ISNULL(period_percentage, 0.0)), 0.0) 
		FROM	glprd
		WHERE	period_start_date		BETWEEN 	DATEDIFF(dd, "1/1/1980", @disp_yr_start_date) + 722815
		AND 	DATEDIFF(dd, "1/1/1980", @disp_yr_end_date) + 722815

		SELECT @proportion = @proportion / @proportion_year

	END 

END	


IF @debug_level >= 3
	SELECT 	proportion = @proportion 

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amlstprp.sp" + ", line " + STR( 1238, 5 ) + " -- EXIT: "

RETURN 0 
GO
GRANT EXECUTE ON  [dbo].[amGetLastYearProportion_sp] TO [public]
GO
