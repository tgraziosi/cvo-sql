SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE [dbo].[amGetCurrentFiscalPeriod_sp] 
(
 @company_id smCompanyID, 			
 @period_end_date smApplyDate OUTPUT, 	
	@debug_level		smDebugLevel	= 0		
)
AS 

DECLARE 
	@jul_date smJulianDate,
	@message smErrorLongDesc 

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amcurprd.sp" + ", line " + STR( 70, 5 ) + " -- ENTRY: "

SELECT @jul_date = period_end_date 
FROM glco 
WHERE company_id = @company_id 

IF @@rowcount = 0 
BEGIN 
	EXEC 		amGetErrorMessage_sp 20202, "tmp/amcurprd.sp", 78, @error_message = @message OUT 
	IF @message IS NOT NULL RAISERROR 	20202 @message 
	RETURN 		20202 
END 
ELSE 
	SELECT @period_end_date = DATEADD(dd, @jul_date-722815, "1/1/1980")

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amcurprd.sp" + ", line " + STR( 85, 5 ) + " -- EXIT: "

RETURN 0
GO
GRANT EXECUTE ON  [dbo].[amGetCurrentFiscalPeriod_sp] TO [public]
GO
