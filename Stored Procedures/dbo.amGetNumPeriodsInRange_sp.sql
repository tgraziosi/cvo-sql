SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE [dbo].[amGetNumPeriodsInRange_sp] 
(
	@from_date 			smApplyDate, 			
	@to_date 			smApplyDate, 			
	@num_prds 			smNumPeriods OUTPUT, 	
	@debug_level		smDebugLevel	= 0		
)
AS 

DECLARE 
	@return_status 		smCounter, 
	@from_date_jul 		smJulianDate, 
	@to_date_jul 		smJulianDate 

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amprdnrg.sp" + ", line " + STR( 90, 5 ) + " -- ENTRY: "

SELECT @from_date_jul 	= DATEDIFF(dd, "1/1/1980", @from_date) + 722815
SELECT @to_date_jul 	= DATEDIFF(dd, "1/1/1980", @to_date) + 722815

 

SELECT 	@num_prds = COUNT(timestamp)
FROM 	glprd 
WHERE 	period_start_date >= 
			(SELECT 	MIN(period_start_date)
				FROM 	glprd 
				WHERE 	period_start_date >= @from_date_jul)
AND 	period_start_date <= 
			(SELECT 	period_start_date 
				FROM 	glprd 
				WHERE 	period_end_date = 
					(SELECT 	MAX(period_end_date)
						FROM 	glprd 
						WHERE 	period_end_date <= @to_date_jul))
					
IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amprdnrg.sp" + ", line " + STR( 111, 5 ) + " -- EXIT: "

RETURN 0
GO
GRANT EXECUTE ON  [dbo].[amGetNumPeriodsInRange_sp] TO [public]
GO
