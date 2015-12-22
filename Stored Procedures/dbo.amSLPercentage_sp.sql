SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE [dbo].[amSLPercentage_sp] 
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
	@apply_date 		smApplyDate, 
	@basis_date 		smApplyDate, 
	@rate 				smRate 







DECLARE
 @PERF_time_last datetime

SELECT @PERF_time_last = GETDATE()















									







IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amslprcn.sp" + ", line " + STR( 69, 5 ) + " -- ENTRY: "
IF ( @perf_level >= 1 ) EXEC perf_sp "", "tmp/amslprcn.sp", 70, "Entry amSLPercentage_sp", @PERF_time_last OUTPUT

IF @debug_level > 3
	SELECT 	co_asset_book_id 	= @co_asset_book_id,
			from_date 			= @from_date,
			use_addition_info 	= @use_addition_info 

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
						1,
						@convention_id,
						@use_addition_info,
						@curr_precision,
						@basis 			OUTPUT,
						@basis_date		OUTPUT,		
						@debug_level,
						@perf_level 

IF ( @result != 0 )
	RETURN @result 

IF ( @perf_level >= 2 ) EXEC perf_sp "", "tmp/amslprcn.sp", 107, "Got Basis", @PERF_time_last OUTPUT

EXEC @result = amGetRate_sp 
						@co_asset_book_id,
						@apply_date,
						0,
						@rate OUTPUT 

IF ( @result != 0 )
	RETURN @result

IF ( @perf_level >= 2 ) EXEC perf_sp "", "tmp/amslprcn.sp", 118, "Got Rate", @PERF_time_last OUTPUT

SELECT @depr_expense = (SIGN(@basis * (@rate/100)) * ROUND(ABS(@basis * (@rate/100)) + 0.0000001, @curr_precision))

IF @debug_level > 3
	SELECT 	basis			= @basis,
			rate 			= @rate,
			depr_expense 	= @depr_expense 

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amslprcn.sp" + ", line " + STR( 127, 5 ) + " -- EXIT: "
IF ( @perf_level >= 1 ) EXEC perf_sp "", "tmp/amslprcn.sp", 128, "Exit amSLPercentage_sp", @PERF_time_last OUTPUT

RETURN 0 
GO
GRANT EXECUTE ON  [dbo].[amSLPercentage_sp] TO [public]
GO
