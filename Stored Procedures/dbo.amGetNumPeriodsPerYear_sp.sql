SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE [dbo].[amGetNumPeriodsPerYear_sp] 
(	
 @apply_date 		smApplyDate, 			
 @num_periods 		smCounter OUTPUT, 		
	@debug_level		smDebugLevel	= 0		
)
AS 

DECLARE 
	@message 	smErrorLongDesc, 
	@error				smErrorCode,
	@jul_date smCounter, 
 @period_start_date smApplyDate, 
 @period_end_date smApplyDate, 
 @period_start_jul smCounter, 
 @period_end_jul smCounter 

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amprdnyr.sp" + ", line " + STR( 81, 5 ) + " -- ENTRY: " 

EXEC @error = amGetFiscalYear_sp 
						@apply_date,
 0,
 @period_start_date OUTPUT 
IF @error <> 0
	RETURN @error
						 
EXEC @error = amGetFiscalYear_sp 
						@apply_date,
 1,
 @period_end_date OUTPUT 
IF @error <> 0
	RETURN @error

SELECT 	@period_start_jul 	= DATEDIFF(dd, "1/1/1980", @period_start_date) + 722815
SELECT 	@period_end_jul 	= DATEDIFF(dd, "1/1/1980", @period_end_date) + 722815


IF @debug_level >= 5
	SELECT 	period_start_date 	= @period_start_date,
			period_end_date 	= @period_end_date, 
 			period_start_jul 	= @period_start_jul,
 			period_end_jul 		= @period_end_jul 
 


SELECT @num_periods 	= COUNT(period_start_date)
FROM glprd 
WHERE period_start_date 	>= @period_start_jul 
AND period_end_date 	<= @period_end_jul 


IF @debug_level >= 5
	SELECT num_periods = @num_periods 


IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amprdnyr.sp" + ", line " + STR( 119, 5 ) + " -- EXIT: "
 
RETURN 0
GO
GRANT EXECUTE ON  [dbo].[amGetNumPeriodsPerYear_sp] TO [public]
GO
