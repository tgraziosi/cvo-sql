SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[amSLSpecifiedLife_sp] 
( 	
	@co_asset_book_id 	smSurrogateKey, 	 
	@from_date 			smApplyDate, 		
	@convention_id		smConventionID,		
	@salvage_value 		smMoneyZero, 		
	@use_addition_info 	smLogical, 			
	@acquisition_date	smApplyDate,		
	@placed_date		smApplyDate,		
	@curr_precision		smallint,			
	@depr_expense 	 	smMoneyZero OUTPUT,	
	@debug_level		smDebugLevel 	= 0,
	@perf_level			smPerfLevel 	= 0	
)
AS 

DECLARE 
	@result			 	smErrorCode,
	@basis 				smMoneyZero, 
	@end_life_date 		smApplyDate, 
	@apply_date 		smApplyDate, 
	@days_remaining 	float,
	@days_in_year 		float,
	@basis_date 		smApplyDate 







DECLARE
 @PERF_time_last datetime

SELECT @PERF_time_last = GETDATE()















									







IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amslspec.sp" + ", line " + STR( 71, 5 ) + " -- ENTRY: "
IF ( @perf_level >= 1 ) EXEC perf_sp "", "tmp/amslspec.sp", 72, "Entry amSLSpecifiedLife_sp", @PERF_time_last OUTPUT

IF @debug_level > 5
	SELECT 	from_date = @from_date 

SELECT @apply_date = @from_date 
IF @use_addition_info = 1 
BEGIN 
	 
	IF @from_date < @acquisition_date 
		SELECT @apply_date = @acquisition_date 

END 

EXEC @result = amGetBasis_sp 
						@co_asset_book_id,
						@placed_date,
						@from_date,
						@salvage_value,
						2,
						@convention_id,
						@use_addition_info,
						@curr_precision,
						@basis 			OUTPUT,
						@basis_date		OUTPUT,
						@debug_level,
						@perf_level 

IF ( @result != 0 )
	RETURN @result

IF ( @perf_level >= 1 ) EXEC perf_sp "", "tmp/amslspec.sp", 107, "Got Basis", @PERF_time_last OUTPUT

EXEC @result = amGetEndLifeDate_sp 
						@co_asset_book_id,
						@apply_date,
						@end_life_date 	OUTPUT,
						@debug_level 

IF ( @result != 0 )
	RETURN @result

IF ( @perf_level >= 1 ) EXEC perf_sp "", "tmp/amslspec.sp", 118, "Got End Life Date", @PERF_time_last OUTPUT

SELECT 	@days_remaining = DATEDIFF(day, @basis_date, @end_life_date) + 1 
SELECT 	@days_in_year 	= 365 		 

IF @debug_level > 3
	SELECT 	basis 			= @basis,
			basis_date 		= @basis_date,
			end_life_date 	= @end_life_date,
			days_remaining 	= @days_remaining,
			days_in_year 	= @days_in_year 

IF @days_remaining != 0
	SELECT @depr_expense= (SIGN((@basis * @days_in_year) / @days_remaining) * ROUND(ABS((@basis * @days_in_year) / @days_remaining) + 0.0000001, @curr_precision))
ELSE
BEGIN
	IF @debug_level > 3
		SELECT "amSLSpecifiedLife_sp - end life date has past take everything remaining"
 
 SELECT @depr_expense = @basis
END

IF @debug_level > 3
	SELECT 	basis 			= @basis,
			days_remaining 	= @days_remaining,
			depr_expense 	= @depr_expense 

IF ( @perf_level >= 1 ) EXEC perf_sp "", "tmp/amslspec.sp", 145, "Exit amSLSpecifiedLife_sp", @PERF_time_last OUTPUT
IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amslspec.sp" + ", line " + STR( 146, 5 ) + " -- EXIT: "

RETURN 0 
GO
GRANT EXECUTE ON  [dbo].[amSLSpecifiedLife_sp] TO [public]
GO
