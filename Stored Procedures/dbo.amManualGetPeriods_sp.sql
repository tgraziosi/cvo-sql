SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[amManualGetPeriods_sp] 
(
	@debug_level	smDebugLevel	= 0	
)
AS 

DECLARE 
	@message smErrorLongDesc, 
	@apply_date_jul smJulianDate,
	@ret_status smErrorCode, 
 	@today_date smApplyDate, 
 	@apply_date smApplyDate, 
 	@company_id smCompanyID, 
 	@row_found smCounter, 
 @param				smErrorParam

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/ammnlprd.sp" + ", line " + STR( 90, 5 ) + " -- ENTRY: "

 
EXEC @ret_status = amGetCompanyID_sp 
					@company_id OUT 
	
IF @ret_status != 0 
	RETURN @ret_status 

EXEC @ret_status = amGetCurrentFiscalPeriod_sp 
					@company_id,
					@apply_date OUTPUT 
					
IF @ret_status != 0 
	RETURN @ret_status 

IF @apply_date IS NULL 
BEGIN 
	 
	SELECT @today_date = GETDATE()

	EXEC @ret_status = amGetFiscalYear_sp 
						@today_date,
						0,
						@apply_date OUT 
			
	IF @ret_status != 0 
		RETURN @ret_status 
	
END 


SELECT @apply_date_jul = DATEDIFF(dd, "1/1/1980", @apply_date) + 722815

IF @debug_level >= 3
	SELECT apply_date = @apply_date_jul 


SELECT 	@apply_date_jul = MAX(period_start_date)
FROM 	glprd 
WHERE 	period_end_date <= @apply_date_jul 
AND		period_type 	= 1001

SELECT 
 	period_start_date 	= CONVERT(char(8), DATEADD(dd, period_start_date-722815, "1/1/1980"), 112),
 	period_end_date 	= CONVERT(char(8), DATEADD(dd, period_end_date-722815, "1/1/1980"), 112),
		period_description
FROM 	glprd 
WHERE 	period_start_date 	>= @apply_date_jul 
ORDER BY	
		period_start_date

SELECT @row_found = @@rowcount 

IF @row_found = 0 
BEGIN 
 SELECT		@param = RTRIM(CONVERT(char(255), @apply_date))
 
 EXEC	 amGetErrorMessage_sp 20029, "tmp/ammnlprd.sp", 154, @param, @error_message = @message OUTPUT 
 IF @message IS NOT NULL RAISERROR 20029 @message 
 RETURN 20029 
END 

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/ammnlprd.sp" + ", line " + STR( 159, 5 ) + " -- EXIT: "

RETURN 0 
GO
GRANT EXECUTE ON  [dbo].[amManualGetPeriods_sp] TO [public]
GO
