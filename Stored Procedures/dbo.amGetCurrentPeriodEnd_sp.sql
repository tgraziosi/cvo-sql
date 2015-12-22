SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE [dbo].[amGetCurrentPeriodEnd_sp] 
(
 @company_id smCompanyID, 			
	@period_start_date	smISODate	OUTPUT,		
 @period_end_date smISODate 	OUTPUT, 	
	@debug_level		smDebugLevel	= 0		
)
AS 

DECLARE @apply_date 	smApplyDate, 
	 	@ret_status 		smErrorCode 

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amisoprd.sp" + ", line " + STR( 66, 5 ) + " -- ENTRY: "

EXEC @ret_status = amGetCurrentFiscalPeriod_sp 
						@company_id,
 @apply_date OUTPUT 

IF @ret_status != 0 
 RETURN @ret_status 

SELECT @period_end_date = CONVERT(char(8), @apply_date, 112)


EXEC @ret_status = amGetFiscalPeriod_sp 
						@apply_date,
						0,
 @apply_date OUTPUT 

IF @ret_status != 0 
 RETURN @ret_status 

SELECT @period_start_date = CONVERT(char(8), @apply_date, 112)

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amisoprd.sp" + ", line " + STR( 88, 5 ) + " -- EXIT: "

RETURN 0
GO
GRANT EXECUTE ON  [dbo].[amGetCurrentPeriodEnd_sp] TO [public]
GO
