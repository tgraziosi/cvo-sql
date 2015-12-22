SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[amGetInitialFiscalPeriods_sp] 
(
	@debug_level	smDebugLevel = 0	
)
AS 

DECLARE @message smErrorLongDesc, 
	 	@apply_date_jul smJulianDate,
		@cur_yr_start_jul	smJulianDate, 
		@cur_yr_end_jul		smJulianDate, 
		@prev_yr_start_jul	smJulianDate, 
		@next_yr_end_jul	smJulianDate, 
		@yr_start_jul		smJulianDate, 
		@yr_end_jul			smJulianDate, 
 		@ret_status smErrorCode, 
		@start_date smApplyDate, 
		@start_date_jul smJulianDate, 
		@end_date smApplyDate, 
		@end_date_jul smJulianDate, 
		@apply_date smApplyDate, 
		@company_id smCompanyID, 
		@row_found smCounter 

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amintprd.sp" + ", line " + STR( 89, 5 ) + " -- ENTRY: "

 
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
	 
	SELECT @apply_date = GETDATE()
	
END 


SELECT @apply_date_jul = DATEDIFF(dd, "1/1/1980", @apply_date) + 722815

IF @debug_level >= 3
 SELECT apply_date = @apply_date_jul 


SELECT 	@cur_yr_start_jul 	= MAX(period_start_date)
FROM 	glprd 
WHERE 	period_start_date 	<= @apply_date_jul 
AND		period_type 		= 1001


SELECT 	@prev_yr_start_jul 	= NULL
SELECT 	@prev_yr_start_jul 	= MAX(period_start_date)
FROM 	glprd 
WHERE 	period_start_date 	< @cur_yr_start_jul 
AND		period_type 		= 1001

IF @prev_yr_start_jul IS NULL
	SELECT @start_date_jul = @cur_yr_start_jul
ELSE
	SELECT @start_date_jul = @prev_yr_start_jul
	

SELECT 	@cur_yr_end_jul = MIN(period_end_date)
FROM 	glprd 
WHERE 	period_end_date >= @apply_date_jul 
AND		period_type 	= 1003


SELECT 	@next_yr_end_jul = NULL
SELECT 	@next_yr_end_jul = MIN(period_end_date)
FROM 	glprd 
WHERE 	period_end_date > @cur_yr_end_jul 
AND		period_type 	= 1003

IF @next_yr_end_jul IS NULL
	SELECT @end_date_jul = @cur_yr_end_jul
ELSE
	SELECT @end_date_jul = @next_yr_end_jul
	

SELECT 
 	period_start_date 	= CONVERT(char(8), DATEADD(dd, period_start_date-722815, "1/1/1980"), 112),
 	period_end_date 	= CONVERT(char(8), DATEADD(dd, period_end_date-722815, "1/1/1980"), 112),
		period_description
FROM 	glprd 
WHERE 	period_start_date 	>= @start_date_jul
AND		period_end_date		<= @end_date_jul 
ORDER BY	
		period_start_date

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amintprd.sp" + ", line " + STR( 171, 5 ) + " -- EXIT: "

RETURN 0
GO
GRANT EXECUTE ON  [dbo].[amGetInitialFiscalPeriods_sp] TO [public]
GO
