SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE [dbo].[amGetPeriodMidPoint_sp] 
(	
 	@apply_date 	smApplyDate, 			
 	@mid_point_date 	smApplyDate OUTPUT, 	
	@debug_level		smDebugLevel	= 0		
)
AS 

DECLARE 
	@message 	 	smErrorLongDesc, 
	@jul_date smJulianDate, 
 @period_start_jul smJulianDate, 
 @period_end_jul smJulianDate, 
 	@mid_point 			smJulianDate

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amprdmid.sp" + ", line " + STR( 87, 5 ) + " -- ENTRY: " 

IF @debug_level >= 5
	SELECT apply_date = @apply_date 

SELECT 	@jul_date 			= DATEDIFF(dd, "1/1/1980", @apply_date) + 722815

SELECT		@period_start_jul 	= NULL,
 	@period_end_jul 	= NULL,
 	@mid_point_date 	= NULL 

IF @debug_level >= 5
	SELECT jul_apply_date = @jul_date 

SELECT @period_start_jul = MAX(period_start_date)
FROM glprd 
WHERE period_start_date <= @jul_date 

IF ( @period_start_jul IS NULL )
BEGIN 
	EXEC 		amGetErrorMessage_sp 20032, "tmp/amprdmid.sp", 107, @error_message = @message out 
 IF @message IS NOT NULL RAISERROR 	20032 @message 
 RETURN 		20032 
END 


SELECT @period_end_jul = MIN(period_end_date)
FROM glprd 
WHERE period_end_date >= @jul_date 

IF ( @period_end_jul IS NULL )
BEGIN 
 EXEC 		amGetErrorMessage_sp 20032, "tmp/amprdmid.sp", 119, @error_message = @message out 
	IF @message IS NOT NULL RAISERROR 	20032 @message 
 RETURN 		20032 
END 


SELECT @mid_point = @period_start_jul + 
 (( @period_end_jul - @period_start_jul + 1 ) / 2)


SELECT @mid_point_date = DATEADD(dd, @mid_point - 722815, "1/1/1980")

IF @debug_level >= 5
	SELECT 	period_start_jul 	= @period_start_jul, 
			period_end_jul 		= @period_end_jul, 
			mid_point_as_jul 	= @mid_point, 
			mid_point_date		= @mid_point_date 

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amprdmid.sp" + ", line " + STR( 137, 5 ) + " -- EXIT: "

RETURN 0 
GO
GRANT EXECUTE ON  [dbo].[amGetPeriodMidPoint_sp] TO [public]
GO
