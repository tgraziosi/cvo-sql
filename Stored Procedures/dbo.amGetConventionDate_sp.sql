SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[amGetConventionDate_sp] 
(
 @apply_date smApplyDate, 			 
 	@convention_id 		smConventionID, 		 
 	@convention_date 	smApplyDate OUTPUT,		 
	@debug_level		smDebugLevel	= 0		
)
AS 

DECLARE 
	@error 					smErrorCode, 
	@nxt_qtr_start_date 	smApplyDate, 
	@qtr_start_date 		smApplyDate, 
	@qtr_end_date 			smApplyDate, 
	@yr_start_date 			smApplyDate, 
	@yr_end_date 			smApplyDate, 
	@num_periods 			smNumPeriods, 
	@temp 					smNumPeriods, 
	@prds_in_year 			smNumPeriods, 
	@num_prds_per_qtr 		smCounter, 
	@num_days 				smCounter, 
	@num_days_per_qtr 		smCounter, 
	@num_days_to_mid 		smCounter, 
	@qtr_midpoint 			smApplyDate, 
	@i 						smCounter 

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amconvdt.sp" + ", line " + STR( 141, 5 ) + " -- ENTRY: "

IF @debug_level >= 5
	SELECT apply_date 		= @apply_date, 
			convention_id 	= @convention_id 

IF @convention_id = 0 
BEGIN 
	 
	EXEC @error = amGetNumPeriodsPerYear_sp 
						@apply_date, 
						@num_periods OUT 
	IF @error <> 0 
		RETURN @error 

	IF @debug_level >= 5
		SELECT 	num_periods = @num_periods 

	EXEC @error = amGetFiscalYear_sp 
						@apply_date,
						0,
						@yr_start_date OUT 

	IF @error <> 0 
		RETURN @error 

	IF @debug_level >= 5
		SELECT 	yr_start_date = @yr_start_date 
	
	SELECT 	@temp 	= @num_periods / 2 
	SELECT @convention_date = @yr_start_date 
	EXEC 	@error 	= amAddNumPeriods_sp 
						@temp,
						@convention_date OUT 
	IF @error <> 0 
		RETURN @error 

	IF @num_periods % 2 = 1 
	BEGIN 
		 
		EXEC @error = amGetPeriodMidPoint_sp 
							@convention_date,
							@convention_date OUT 
		IF @error <> 0 
			RETURN @error 
	END 
			
END  

ELSE IF @convention_id = 2 
BEGIN 

	EXEC @error = amGetFiscalYear_sp 
							@apply_date, 
							0, 
							@yr_start_date OUT 

	IF @error <> 0 
		RETURN @error 

	EXEC 	@error = amGetNumPeriodsPerYear_sp 
							@yr_start_date, 
							@num_periods OUT 
						 

	IF @error <> 0 
		RETURN @error 
	
	 
	
	 
	IF (@num_periods % 4 = 0)
	BEGIN 
		 
		SELECT @num_prds_per_qtr = @num_periods / 4 
	
		IF @debug_level >= 5
			SELECT 	num_prds_per_qtr = @num_prds_per_qtr 

		 
		SELECT 	@qtr_start_date = @yr_start_date 
		SELECT 	@nxt_qtr_start_date = @qtr_start_date 
		SELECT 	@i = 1 
		
		WHILE @i <= 4 
		BEGIN 
			IF @debug_level >= 5
				SELECT 	qtr_start_date = @qtr_start_date 
 
 			EXEC @error = amAddNumPeriods_sp 
								@num_prds_per_qtr,
								@nxt_qtr_start_date OUT 
			
			IF @error <> 0 
				RETURN @error 

 			IF @debug_level >= 5
				SELECT 	nxt_qtr_start_date = @nxt_qtr_start_date 
	
			IF @apply_date < @nxt_qtr_start_date 
			BEGIN 
				EXEC 	@error = amGetQuarterMidPoint_sp 
									@qtr_start_date,
									@num_prds_per_qtr,
									@convention_date OUT 
				IF @error <> 0 
					RETURN @error 
				ELSE 
				BEGIN 
					IF @debug_level >= 3
						SELECT 	convention_date = @convention_date 
					IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amconvdt.sp" + ", line " + STR( 259, 5 ) + " -- EXIT: "
					RETURN 0 
				END 
			END 
			
			SELECT @qtr_start_date = @nxt_qtr_start_date 
			SELECT @i = @i + 1 
		END 
	END 
	
	ELSE  
	BEGIN 
		EXEC @error = amGetFiscalYear_sp 
								@apply_date, 
								1, 
								@yr_end_date OUT 


		IF @error <> 0 
			RETURN @error 
		
		SELECT 	@num_days = datediff(day, @yr_start_date, @yr_end_date) + 1 
		SELECT 	@num_days_per_qtr = @num_days / 4 
		SELECT 	@num_days_to_mid = @num_days_per_qtr / 2 

		 
		SELECT @qtr_start_date = @yr_start_date 
		SELECT 	@qtr_end_date = dateadd(dd, @num_days_per_qtr, @qtr_start_date)
		SELECT @i = 1 

		WHILE @i <= 4 
		BEGIN 
			IF @apply_date <= @qtr_end_date 
			BEGIN 
				SELECT @qtr_midpoint = dateadd(dd, @num_days_to_mid, @qtr_start_date)
				
				EXEC @error = amGetNearestHalfPeriod_sp 
									@qtr_midpoint,
									@convention_date OUT 
				IF @error <> 0 
					RETURN @error 
				ELSE 
				BEGIN 
					IF @debug_level >= 3
						SELECT 	convention_date = @convention_date 
					IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amconvdt.sp" + ", line " + STR( 304, 5 ) + " -- EXIT: "
					RETURN 0 
				END 
			END 
			 
			SELECT @qtr_start_date = dateadd(dd, 1, @qtr_end_date)
			IF @i = 3 
				SELECT 	@qtr_end_date = @yr_end_date 
			ELSE 
				SELECT 	@qtr_end_date = dateadd(dd, @num_days_per_qtr, @qtr_start_date)
			SELECT @i = @i + 1 
		END 
	END 
END  

ELSE IF @convention_id = 1 
BEGIN 
	 
	EXEC @error = amGetPeriodMidPoint_sp 
						@apply_date, 
						@convention_date OUT 
	IF (@error <> 0)
		RETURN @error 

END  

ELSE IF @convention_id = 3 
BEGIN 
	 
	EXEC @error = amGetFullMonthDate_sp 
						@apply_date, 
						@convention_date OUT 
	IF (@error <> 0)
		RETURN @error 

END  

ELSE IF @convention_id = 4 
BEGIN 
	 
	EXEC @error = amGetFiscalPeriod_sp 
						@apply_date, 
						0, 
						@convention_date OUT 

	IF (@error <> 0)
		RETURN @error 
END  

ELSE IF @convention_id = 5 
BEGIN 
	 
	SELECT @convention_date = @apply_date

END  

IF @debug_level >= 3
	SELECT 	convention_date = @convention_date 

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amconvdt.sp" + ", line " + STR( 370, 5 ) + " -- EXIT: "
				 
RETURN 0 
GO
GRANT EXECUTE ON  [dbo].[amGetConventionDate_sp] TO [public]
GO
