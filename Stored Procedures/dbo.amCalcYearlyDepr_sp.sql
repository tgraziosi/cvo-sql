SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE [dbo].[amCalcYearlyDepr_sp] 
( 	
	@co_asset_book_id smSurrogateKey, 	 
	@method_id 			smDeprMethodID, 	
	@convention_id		smConventionID,		
	@from_date 			smApplyDate, 		
	@salvage_value 		smMoneyZero, 		
	@acquisition_date	smApplyDate,		 
	@placed_date		smApplyDate,		
	@use_addition_info 	smLogical, 			
	@do_post 			smLogical, 			
	@curr_precision		smallint,			
	@depr_expense 		smMoneyZero OUTPUT,	
	@debug_level		smDebugLevel 	= 0,
	@perf_level			smPerfLevel 	= 0	
)
AS 







DECLARE
 @PERF_time_last datetime

SELECT @PERF_time_last = GETDATE()















									







DECLARE 
	@result			 	smErrorCode 		

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amcalcyr.sp" + ", line " + STR( 67, 5 ) + " -- ENTRY: "
IF ( @perf_level >= 1 ) EXEC perf_sp "", "tmp/amcalcyr.sp", 68, "Entry amCalcYearlyDepr_sp", @PERF_time_last OUTPUT

IF @debug_level >= 5
	SELECT 	co_asset_book_id 	= @co_asset_book_id,
			method_id 			= @method_id,
			from_date 			= @from_date,
			acquisition_date	= @acquisition_date,
			use_addition_info 	= @use_addition_info,
			do_post 			= @do_post 

 
IF @method_id = 1 
BEGIN 
	EXEC @result = amSLPercentage_sp 
							@co_asset_book_id,
							@from_date,
							@convention_id,
							@salvage_value,
							@use_addition_info,
							@acquisition_date,
							@placed_date,
							@curr_precision,
							@depr_expense OUTPUT,
							@debug_level,
							@perf_level 
	IF ( @result != 0 )
		RETURN @result

END 

ELSE IF @method_id = 2 
BEGIN 
	EXEC @result = amSLSpecifiedLife_sp 
							@co_asset_book_id,
							@from_date,
							@convention_id,
							@salvage_value,
							@use_addition_info,
							@acquisition_date,
							@placed_date,
							@curr_precision,
							@depr_expense OUTPUT,
							@debug_level,
							@perf_level 
							 
 
	IF ( @result != 0 )
		RETURN @result
		 
END 


ELSE IF @method_id = 3 
BEGIN 
	EXEC @result = amSLMaximumLife_sp 
							@co_asset_book_id,
							@from_date,
							@convention_id,
							@salvage_value,
							@use_addition_info,
							@acquisition_date,
							@placed_date,
							@curr_precision,
							@depr_expense OUTPUT,
							@debug_level 
 
	IF ( @result != 0 )
		RETURN @result

END 

ELSE IF @method_id = 4 
BEGIN 
	EXEC @result = amDB_sp 
							@co_asset_book_id,
							@from_date,
							@convention_id,
							@salvage_value,
							@use_addition_info,
							@acquisition_date,
							@placed_date,
							@curr_precision,
							@depr_expense OUTPUT,
							@debug_level 
 
	IF ( @result != 0 )
		RETURN @result 

END 

ELSE IF @method_id = 5 
BEGIN 
	EXEC @result = amDBToSL_sp 
							@co_asset_book_id,
							@from_date,
							@convention_id,
							@salvage_value,
							@use_addition_info,
							@acquisition_date,
							@placed_date,
							@do_post,
							@curr_precision,
							@depr_expense OUTPUT,
							@debug_level,
							@perf_level 
 
	IF ( @result != 0 )
		RETURN @result 

END 

IF @debug_level >= 5
	SELECT depr_expense = @depr_expense 

IF ( @perf_level >= 1 ) EXEC perf_sp "", "tmp/amcalcyr.sp", 185, "Exit amCalcYearlyDepr_sp", @PERF_time_last OUTPUT
IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amcalcyr.sp" + ", line " + STR( 186, 5 ) + " -- EXIT: "

RETURN 0
GO
GRANT EXECUTE ON  [dbo].[amCalcYearlyDepr_sp] TO [public]
GO
