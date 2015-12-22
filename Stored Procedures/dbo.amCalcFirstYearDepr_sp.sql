SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE [dbo].[amCalcFirstYearDepr_sp] 
( 	
	@co_asset_book_id smSurrogateKey, 	 
	@from_date 			smApplyDate, 		 
	@salvage_value 		smMoneyZero, 		
	@acquisition_date	smApplyDate,		
	@placed_date 		smApplyDate, 		 
	@method_id 			smDeprMethodID, 	 
	@convention_id 		smConventionID, 	 
	@do_post 			smLogical, 			 
	@first_time_depr	smLogical, 			 
	@curr_precision		smallint,			
	@depr_expense 		smMoneyZero OUTPUT,	
	@debug_level		smDebugLevel 	= 0,
	@perf_level			smPerfLevel 	= 0	
)
AS 

DECLARE 
	@result			 			smErrorCode, 
	@yearly_depr 				smMoneyZero, 
	@proportion 				float,
	@flag 						smControlNumber 







DECLARE
 @PERF_time_last datetime

SELECT @PERF_time_last = GETDATE()















									







SELECT @flag = CONVERT(char(16), @co_asset_book_id)

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amfrstyr.sp" + ", line " + STR( 82, 5 ) + " -- ENTRY: "
IF ( @perf_level >= 1 ) EXEC perf_sp @flag, "tmp/amfrstyr.sp", 83, "Entry amCalcFirstYearDepr_sp", @PERF_time_last OUTPUT

IF @debug_level >= 3
	SELECT 	method_id 		= @method_id,
			convention_id 	= @convention_id 

	
 
EXEC @result = amCalcYearlyDepr_sp 
						@co_asset_book_id,
						@method_id,	
						@convention_id,
						@from_date,		
						@salvage_value,
						@acquisition_date,
						@placed_date,
						1,			 
						@do_post,
						@curr_precision,
						@yearly_depr OUTPUT,
						@debug_level 
 

IF ( @result != 0 )
	RETURN @result

IF ( @perf_level >= 2 ) EXEC perf_sp @flag, "tmp/amfrstyr.sp", 111, "Completed yearly calculation", @PERF_time_last OUTPUT

 
EXEC @result = amGetFirstYearProportion_sp 
						@placed_date,
						@convention_id,
						@proportion OUTPUT,
						@debug_level 

IF ( @result != 0 )
	RETURN @result

SELECT @depr_expense 	= (SIGN(@yearly_depr * @proportion) * ROUND(ABS(@yearly_depr * @proportion) + 0.0000001, @curr_precision))

IF @debug_level >= 3
	SELECT 	depr_expense		= @depr_expense

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amfrstyr.sp" + ", line " + STR( 130, 5 ) + " -- EXIT: "
IF ( @perf_level >= 1 ) EXEC perf_sp @flag, "tmp/amfrstyr.sp", 131, "Exit amCalcFirstYearDepr_sp", @PERF_time_last OUTPUT

RETURN 0 
GO
GRANT EXECUTE ON  [dbo].[amCalcFirstYearDepr_sp] TO [public]
GO
