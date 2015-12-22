SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[amAddNumPeriods_sp] 
(
	@num_periods 		smNumPeriods, 		
	@start_date 		smApplyDate OUTPUT,	
	@debug_level		smDebugLevel = 0	
)
AS 

DECLARE 
	@error 				smErrorCode,
	@message			smErrorLongDesc, 
	@jul_start_date 	smJulianDate, 
	@jul_end_date 		smJulianDate 

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amaddprd.sp" + ", line " + STR( 111, 5 ) + " -- ENTRY: "

IF @debug_level >= 3
	SELECT 	start_date = @start_date,
			num_periods = @num_periods 

 
SELECT @jul_start_date = DATEDIFF(dd, "1/1/1980", @start_date) + 722815

IF @debug_level >= 5
	SELECT 	jul_start_date = @jul_start_date 

 
WHILE @num_periods > 0 
BEGIN 
	
	
	SELECT	@jul_end_date 		= NULL

	SELECT 	@jul_end_date 		= period_end_date
	FROM 	glprd 
	WHERE 	period_start_date 	= @jul_start_date 

	IF @debug_level >= 3
		SELECT	num_periods 	= @num_periods,
				jul_end_date	= @jul_end_date 

	 
	IF @jul_end_date IS NULL 
	BEGIN 
	 	EXEC 		amGetErrorMessage_sp 20032, "tmp/amaddprd.sp", 143, @error_message = @message out 
	 IF @message IS NOT NULL RAISERROR 	20032 @message 
		RETURN 		20032 
	END 
	
	
	SELECT 	@jul_start_date = @jul_end_date + 1,
			@num_periods 	= @num_periods - 1 

END  

 
SELECT @start_date = DATEADD(dd, @jul_start_date - 722815, "1/1/1980")

IF @debug_level >= 3
	SELECT 	start_date = @start_date 

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amaddprd.sp" + ", line " + STR( 160, 5 ) + " -- EXIT: "

RETURN 0 
GO
GRANT EXECUTE ON  [dbo].[amAddNumPeriods_sp] TO [public]
GO
