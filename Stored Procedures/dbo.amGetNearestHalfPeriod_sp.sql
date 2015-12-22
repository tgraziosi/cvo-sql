SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[amGetNearestHalfPeriod_sp] 
(
 @calc_midpoint_date 	smApplyDate, 			 
	@actual_midpoint_date 	smApplyDate OUTPUT, 	 
	@debug_level			smDebugLevel	= 0		
)
AS 

DECLARE 
	@error 				smErrorCode, 
	@prd_start_date 	smApplyDate, 
	@prd_midpoint_date 	smApplyDate 

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amnearmd.sp" + ", line " + STR( 79, 5 ) + " -- ENTRY: "

IF @debug_level >= 5
	SELECT calc_midpoint_date 		= @calc_midpoint_date 

EXEC @error = amGetFiscalPeriod_sp 
					@calc_midpoint_date,
					0,
					@prd_start_date 	OUT 
IF @error <> 0 
	RETURN @error 

EXEC @error = amGetPeriodMidPoint_sp 
					@calc_midpoint_date,
					@prd_midpoint_date 	OUT 
IF @error <> 0 
	RETURN @error 


 
IF @prd_midpoint_date <= @calc_midpoint_date 
	SELECT @actual_midpoint_date = @prd_midpoint_date 	
ELSE 
	SELECT @actual_midpoint_date = @prd_start_date 
			
IF @debug_level >= 3
	SELECT 	actual_midpoint_date = @actual_midpoint_date 

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amnearmd.sp" + ", line " + STR( 107, 5 ) + " -- EXIT: "

RETURN 0 
GO
GRANT EXECUTE ON  [dbo].[amGetNearestHalfPeriod_sp] TO [public]
GO
