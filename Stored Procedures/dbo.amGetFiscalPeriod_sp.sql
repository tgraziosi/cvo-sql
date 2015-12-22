SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE [dbo].[amGetFiscalPeriod_sp] 
(
	
 @apply_date 	smApplyDate, 		
	@want_end_date 	smLogical, 			
 @period_date 	smApplyDate OUTPUT,	
	@debug_level		smDebugLevel	= 0	
)
AS 

DECLARE @message 	smErrorLongDesc, 
		@jul_date smJulianDate, 
 @period_date_jul smJulianDate, 
		@ret_state 			smErrorCode, 
		@rowcount smCounter 

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amfsclpd.sp" + ", line " + STR( 91, 5 ) + " -- ENTRY: " 

SELECT @period_date_jul = NULL 

SELECT 	@jul_date = DATEDIFF(dd, "1/1/1980", @apply_date) + 722815

IF @debug_level >= 5
 SELECT jul_date = @jul_date 

IF ( @want_end_date = 0 )
BEGIN 
 SELECT @period_date_jul 	= MAX(period_start_date)
 FROM glprd 
 WHERE period_start_date 	<= @jul_date 
END 
ELSE 
BEGIN 
 SELECT @period_date_jul 	= MIN(period_end_date)
 FROM glprd 
 WHERE period_end_date 		>= @jul_date 
END 

IF ( @period_date_jul IS NOT NULL )
BEGIN 
 SELECT @period_date = DATEADD(dd, @period_date_jul - 722815, "1/1/1980")
 
	IF @debug_level >= 5
		SELECT period_date = @period_date 

	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amfsclpd.sp" + ", line " + STR( 120, 5 ) + " -- EXIT: "
 	RETURN 0 
END 
ELSE 
BEGIN 
	EXEC 		amGetErrorMessage_sp 20032, "tmp/amfsclpd.sp", 125, @error_message = @message out 
	IF @message IS NOT NULL RAISERROR 	20032 @message 
	RETURN 		20032 
END 

GO
GRANT EXECUTE ON  [dbo].[amGetFiscalPeriod_sp] TO [public]
GO
