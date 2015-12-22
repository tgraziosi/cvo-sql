SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[amGetAllFiscalYears_sp] 
(
	@debug_level	smDebugLevel = 0	
)
AS 

DECLARE @message smErrorLongDesc, 
		@ret_status smErrorCode, 
		@start_date smApplyDate, 
		@start_date_jul smJulianDate, 
		@end_date smApplyDate, 
	 	@end_date_jul smJulianDate 

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amallyrs.sp" + ", line " + STR( 71, 5 ) + " -- ENTRY: "

CREATE TABLE #period 
( 
	period_start_date char(8),
	period_end_date char(8)
)

SELECT @start_date_jul = NULL 

SELECT 	@start_date_jul = MIN(period_start_date)
FROM 	glprd 
WHERE	period_type 	= 1001

SELECT 	@end_date_jul 	= MIN(period_end_date)
FROM 	glprd 
WHERE	period_type 	= 1003

WHILE @start_date_jul IS NOT NULL 
BEGIN 


	IF @debug_level >= 3
		SELECT jul_start = @start_date_jul,
				jul_end = @end_date_jul 

	INSERT #period 
 VALUES 
 ( 
		CONVERT(char(8), DATEADD(dd, @start_date_jul-722815, "1/1/1980"), 112),
		CONVERT(char(8), DATEADD(dd, @end_date_jul-722815, "1/1/1980"), 112) 
 )
		 
  
	SELECT 	@start_date_jul = MIN(period_start_date)
	FROM 	glprd 
	WHERE	period_type 	= 1001
	AND		period_start_date > @start_date_jul

	SELECT 	@end_date_jul 	= MIN(period_end_date)
	FROM 	glprd 
	WHERE	period_type 	= 1003
	AND		period_end_date > @end_date_jul

END 

SELECT 
	period_start_date, 
	period_end_date
FROM #period 

DROP TABLE #period 

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amallyrs.sp" + ", line " + STR( 124, 5 ) + " -- EXIT: "

RETURN 0
GO
GRANT EXECUTE ON  [dbo].[amGetAllFiscalYears_sp] TO [public]
GO
