SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[amGetQuarterMidPoint_sp] 
(
 @start_date 	smApplyDate, 		 
	@num_periods 		smNumPeriods, 		 
	@midpoint_date 		smApplyDate OUTPUT,  
	@debug_level		smDebugLevel	= 0	
)
AS 

DECLARE 
	@error 			smErrorCode, 
	@yr_start_date 	smApplyDate, 
	@half_of_prds 	smNumPeriods 

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amqurtmd.sp" + ", line " + STR( 80, 5 ) + " -- ENTRY: "

IF @debug_level >= 3
	SELECT 	start_date 		= @start_date, 
			num_periods 	= @num_periods 

SELECT @half_of_prds = @num_periods / 2 
EXEC @error = amAddNumPeriods_sp 
					@half_of_prds,
					@start_date OUT 
IF @error <> 0 
	RETURN @error 
ELSE 
BEGIN 
	SELECT @midpoint_date = @start_date 	
	IF @debug_level >= 3
		SELECT 	midpoint_date = @midpoint_date 
END 

IF @num_periods % 2 = 1 
BEGIN 
	IF @debug_level >= 3
		SELECT "Adjusting for odd number of periods" 

	 
	EXEC @error = amGetPeriodMidPoint_sp 
						@start_date,
						@midpoint_date OUT 
	IF @error <> 0 
		RETURN @error 
END 

IF @debug_level >= 3
	SELECT 	midpoint_date = @midpoint_date 

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amqurtmd.sp" + ", line " + STR( 118, 5 ) + " -- EXIT: "

RETURN 0 
GO
GRANT EXECUTE ON  [dbo].[amGetQuarterMidPoint_sp] TO [public]
GO
