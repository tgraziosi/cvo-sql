SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[amGetFiscalYear_sp] 
(	
 @apply_date 		smApplyDate, 		
 @want_end_date 		smLogical, 			
 @yr_start_date 		smApplyDate OUTPUT,	
	@debug_level		smDebugLevel	= 0	
)
AS 

DECLARE 
	@message smErrorLongDesc,		
	@param			smErrorParam,			
	@jul_apply_date smJulianDate,			
	@jul_date 		smJulianDate			

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amfsclyr.sp" + ", line " + STR( 87, 5 ) + " -- ENTRY: " 


SELECT 	@jul_apply_date = DATEDIFF(dd, "1/1/1980", @apply_date) + 722815,
		@param			= CONVERT(char(255), @apply_date, 107)

IF @debug_level >= 5
	SELECT jul_apply_date = @jul_apply_date 

IF ( @want_end_date = 1)
BEGIN 
 
 SELECT @jul_date = MIN(period_end_date)
 FROM glprd 
 WHERE period_end_date >= @jul_apply_date 
 AND period_type = 1003 

	IF NOT EXISTS (SELECT 	period_start_date
					FROM	glprd
					WHERE	period_start_date 	<= @jul_apply_date
					AND		period_type 		= 1001)
	BEGIN
	 	EXEC 		amGetErrorMessage_sp 
	 							20039, "tmp/amfsclyr.sp", 114, 
	 							@param, 
	 							@error_message = @message OUT 
	 IF @message IS NOT NULL RAISERROR 	20039 @message 
	 	RETURN 		20039 
	END
		
END 
ELSE 
BEGIN 
 
 SELECT @jul_date = MAX(period_start_date)
 FROM glprd 
 WHERE period_start_date <= @jul_apply_date 
 AND period_type = 1001 

	IF NOT EXISTS (SELECT 	period_end_date
					FROM	glprd
					WHERE	period_end_date 	>= @jul_apply_date
					AND		period_type 		= 1003)
	BEGIN
	 	EXEC 		amGetErrorMessage_sp 
	 							20039, "tmp/amfsclyr.sp", 138, 
	 							@param, 
	 							@error_message = @message OUT 
	 IF @message IS NOT NULL RAISERROR 	20039 @message 
	 	RETURN 		20039 
	END
END 

IF ( @jul_date IS NULL )
BEGIN 
 	EXEC 		amGetErrorMessage_sp 
 						20039, "tmp/amfsclyr.sp", 149, 
						@param,
 						@error_message = @message OUT 
 IF @message IS NOT NULL RAISERROR 	20039 @message 
 	RETURN 		20039 
END 


SELECT @yr_start_date = DATEADD(dd, @jul_date - 722815, "1/1/1980")

IF @debug_level >= 5
	SELECT yr_start_date = @yr_start_date 
 

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amfsclyr.sp" + ", line " + STR( 165, 5 ) + " -- EXIT: "

RETURN 0 
GO
GRANT EXECUTE ON  [dbo].[amGetFiscalYear_sp] TO [public]
GO
