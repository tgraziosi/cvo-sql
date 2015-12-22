SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[amGetNumPeriods_sp] 
(
	@convention_id	 	smConventionID, 		 
	@from_date 			smApplyDate, 			
	@to_date 			smApplyDate, 			
	@num_active 		float 			OUTPUT,	
	@debug_level		smDebugLevel = 0		
)
AS 

DECLARE 
	@result		 		smErrorCode, 
 @message 			smErrorLongDesc, 
	@from_date_jul 		smCounter,			 
	@to_date_jul 		smCounter, 			 
	@prd_start_date	 	smApplyDate, 		
	@prd_end_date	 	smApplyDate, 		
	@mid_point_date 	smApplyDate, 		
	@part_prd			float				

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amnumprd.sp" + ", line " + STR( 80, 5 ) + " -- ENTRY: "

IF @debug_level >= 3
	SELECT 	from_date 	= @from_date,
			to_date 	= @to_date 

SELECT @num_active = 0.0 

SELECT @from_date_jul 	= DATEDIFF(dd, "1/1/1980", @from_date) + 722815
SELECT @to_date_jul 	= DATEDIFF(dd, "1/1/1980", @to_date) + 722815

 
SELECT 	@num_active = COUNT(timestamp)
FROM 	glprd 
WHERE 	period_start_date >= ( 
			SELECT 	MIN(period_start_date)
			FROM 	glprd 
			WHERE	period_start_date >= @from_date_jul)
AND 	period_start_date <= ( 
			SELECT 	period_start_date 
			FROM 	glprd 
			WHERE 	period_end_date = ( 
			 		SELECT 	MAX(period_end_date)
					FROM 	glprd 
					WHERE 	period_end_date <= @to_date_jul))
					
IF @debug_level >= 5
	SELECT count_of_whole_periods = @num_active 

 
IF NOT EXISTS (SELECT period_start_date
				FROM glprd
				WHERE period_start_date = @from_date_jul) 

BEGIN 
	IF @convention_id = 1
	BEGIN
		 
		EXEC @result = amGetPeriodMidPoint_sp 
								@from_date,
								@mid_point_date OUTPUT 
		IF ( @result != 0 )
			RETURN @result 
		
		IF @debug_level >= 5
			SELECT 	from_date 		= @from_date,
					mid_point_date 	= @mid_point_date 

		IF @from_date = @mid_point_date 
			SELECT @num_active = @num_active + 0.5 
		ELSE 
		BEGIN 
			EXEC 		amGetErrorMessage_sp 20903, "tmp/amnumprd.sp", 136, @error_message = @message OUT 
			IF @message IS NOT NULL RAISERROR 	20903 @message 
			RETURN 		20903 
		END 
	END
	ELSE IF @convention_id = 5
	BEGIN

		IF @debug_level >= 5
			SELECT num_active = @num_active

		 
		EXEC @result = amGetFiscalPeriod_sp 
								@from_date,
								0,
								@prd_start_date OUTPUT 
		IF ( @result != 0 )
			RETURN @result 
		
		EXEC @result = amGetFiscalPeriod_sp 
								@from_date,
								1,
								@prd_end_date OUTPUT 
		IF ( @result != 0 )
			RETURN @result 
		
		SELECT @part_prd 	= DATEDIFF(dd, @from_date, @prd_end_date) + 1 
		SELECT @part_prd 	= @part_prd / (DATEDIFF(dd, @prd_start_date, @prd_end_date) + 1)
		SELECT @num_active 	= @num_active + @part_prd 


		IF @debug_level >= 5
			SELECT num_active = @num_active

	END
	ELSE
	BEGIN
		EXEC 		amGetErrorMessage_sp 20904, "tmp/amnumprd.sp", 175, @error_message = @message OUT 
		IF @message IS NOT NULL RAISERROR 	20904 @message 
		RETURN 		20904 
	END
END 


 
IF NOT EXISTS (SELECT period_end_date
				FROM glprd
				WHERE period_end_date = @to_date_jul)
BEGIN 
	IF @convention_id = 1
	BEGIN
		 

		EXEC @result = amGetPeriodMidPoint_sp 
								@to_date,
								@mid_point_date OUTPUT 
		IF ( @result != 0 )
			RETURN @result 

		 
		SELECT @mid_point_date = DATEADD(dd, -1, @mid_point_date)

		IF @debug_level >= 5
			SELECT 	to_date 		= @to_date,
					mid_point_date 	= @mid_point_date 

		IF @to_date = @mid_point_date 
			SELECT @num_active = @num_active + 0.5 
		ELSE 
		BEGIN 
	 		EXEC	 	amGetErrorMessage_sp 20903, "tmp/amnumprd.sp", 212, @error_message = @message OUT 
	 		IF @message IS NOT NULL RAISERROR 	20903 @message 
	 		RETURN 		20903 
		END 
	END

	ELSE IF @convention_id = 5
	BEGIN

		IF @debug_level >= 5
			SELECT num_active = @num_active
		 
		EXEC @result = amGetFiscalPeriod_sp 
								@to_date,
								0,
								@prd_start_date OUTPUT 
		IF ( @result != 0 )
			RETURN @result 
		
		EXEC @result = amGetFiscalPeriod_sp 
								@to_date,
								1,
								@prd_end_date OUTPUT 
		IF ( @result != 0 )
			RETURN @result 
		
		SELECT 	@part_prd 	= DATEDIFF(dd, @prd_start_date, @to_date) + 1
		SELECT	@part_prd 	= @part_prd / (DATEDIFF(dd, @prd_start_date, @prd_end_date) + 1)
		SELECT 	@num_active = @num_active +	@part_prd


		IF @debug_level >= 5
			SELECT 	to_date			= @to_date,
					prd_start_date 	= @prd_start_date,
					prd_end_date 	= @prd_end_date,
					num_active 		= @num_active
	END
	ELSE
	BEGIN
		EXEC 		amGetErrorMessage_sp 20905, "tmp/amnumprd.sp", 253, @error_message = @message OUT 
		IF @message IS NOT NULL RAISERROR 	20905 @message 
		RETURN 		20905 
	END

END 

IF @debug_level >= 3
	SELECT 	num_active = @num_active 
IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amnumprd.sp" + ", line " + STR( 262, 5 ) + " -- EXIT: "

RETURN 0 
GO
GRANT EXECUTE ON  [dbo].[amGetNumPeriods_sp] TO [public]
GO
