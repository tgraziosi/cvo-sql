SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[amGetMoreFiscalPeriods_sp] 
(
	@load_forwards			smLogical,	
	@prd_end_date			smISODate,	
	@return_all_rows		smLogical,	
	@debug_level			smDebugLevel	= 0	
)
AS 

DECLARE @message smErrorLongDesc, 
		@start_prd_date_jul	smJulianDate,
		@end_prd_date_jul	smJulianDate,
 		@ret_status smErrorCode, 
		@start_date smApplyDate, 
		@start_date_jul smJulianDate, 
		@end_date smApplyDate, 
		@end_date_jul smJulianDate, 
		@apply_date smApplyDate, 
		@row_found smCounter 


IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/ammreprd.sp" + ", line " + STR( 88, 5 ) + " -- ENTRY: "

IF @debug_level >= 3
	SELECT	load_forwards 	= @load_forwards,
			prd_end_date	= @prd_end_date,
			return_all_rows = @return_all_rows


SELECT @apply_date = CONVERT(datetime, @prd_end_date)


SELECT @end_prd_date_jul = DATEDIFF(dd, "1/1/1980", @apply_date) + 722815

SELECT 	@start_prd_date_jul = period_start_date
FROM 	glprd 
WHERE 	period_end_date 	= @end_prd_date_jul 


IF @load_forwards = 1
BEGIN
	SELECT 	@start_date_jul = MIN(period_start_date)
	FROM 	glprd 
	WHERE 	period_end_date > @end_prd_date_jul 
	AND		period_type 	= 1001

	IF @return_all_rows = 1
	BEGIN
		SELECT 	@end_date_jul = MAX(period_end_date)
		FROM 	glprd 
	END
	ELSE
	BEGIN
		SELECT 	@end_date_jul = MIN(period_end_date)
		FROM 	glprd 
		WHERE 	period_end_date > @start_date_jul 
		AND		period_type 	= 1003
	END

END
ELSE
BEGIN
	SELECT 	@end_date_jul 	= MAX(period_end_date)
	FROM 	glprd 
	WHERE 	period_end_date < @start_prd_date_jul 
	AND		period_type 	= 1003
	
	IF @return_all_rows = 1
	BEGIN
		SELECT 	@start_date_jul = MIN(period_start_date)
		FROM 	glprd 
	END
	ELSE
	BEGIN
		SELECT 	@start_date_jul 	= MAX(period_start_date)
		FROM 	glprd 
		WHERE 	period_start_date 	< @start_prd_date_jul 
		AND		period_type 		= 1001
	END

END

IF @debug_level >= 3
	SELECT	start_date_jul 	= @start_date_jul,
			end_date_jul	= @end_date_jul
	

SELECT
 	period_start_date 	= CONVERT(char(8), DATEADD(dd, period_start_date-722815, "1/1/1980"), 112),
 	period_end_date 	= CONVERT(char(8), DATEADD(dd, period_end_date-722815, "1/1/1980"), 112),
		period_description
FROM 	glprd 
WHERE 	period_start_date 	>= @start_date_jul
AND		period_end_date		<= @end_date_jul 
ORDER BY	
		period_start_date

SELECT @row_found = @@rowcount 

IF @debug_level >= 3
 SELECT row_found = @row_found 

IF @row_found = 0 
 RETURN	20020 

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/ammreprd.sp" + ", line " + STR( 172, 5 ) + " -- EXIT: "

RETURN 0
GO
GRANT EXECUTE ON  [dbo].[amGetMoreFiscalPeriods_sp] TO [public]
GO
