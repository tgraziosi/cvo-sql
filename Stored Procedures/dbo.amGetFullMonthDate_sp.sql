SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[amGetFullMonthDate_sp] 
(
 @apply_date 	smApplyDate, 		 
	@effective_date	smApplyDate OUTPUT,	 
	@debug_level	smDebugLevel	= 0	
)
AS 

DECLARE 
	@error 			smErrorCode,
	@midpoint_date 	smApplyDate 

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amfllmth.sp" + ", line " + STR( 82, 5 ) + " -- ENTRY: "

IF @debug_level >= 5
	SELECT apply_date 		= @apply_date 

EXEC @error = amGetPeriodMidPoint_sp 
						@apply_date, 
						@midpoint_date OUT 
IF (@error <> 0)
	RETURN @error 

IF @apply_date < @midpoint_date 
BEGIN 
	 
	EXEC @error = amGetFiscalPeriod_sp 
						@apply_date, 
						0, 
						@effective_date OUT 
	IF (@error <> 0)
		RETURN @error 
END 
ELSE  
BEGIN 
	 
	EXEC @error = amGetFiscalPeriod_sp 
						@apply_date, 
						1, 
						@effective_date OUT 
	IF (@error <> 0)
		RETURN @error 
	
	SELECT @effective_date = DATEADD(dd, 1, @effective_date)

END  


IF @debug_level >= 3
	SELECT 	effective_date = @effective_date 

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amfllmth.sp" + ", line " + STR( 129, 5 ) + " -- EXIT: "

RETURN 0 
GO
GRANT EXECUTE ON  [dbo].[amGetFullMonthDate_sp] TO [public]
GO
