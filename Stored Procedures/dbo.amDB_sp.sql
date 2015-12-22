SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[amDB_sp] 
( 	
	@co_asset_book_id smSurrogateKey, 	 
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
	@basis_date 		smApplyDate, 
	@apply_date 		smApplyDate, 
	@service_life 		smLife, 
	@depr_rate 			smRate, 
	@rate 				smRate 







DECLARE
 @PERF_time_last datetime

SELECT @PERF_time_last = GETDATE()















									







IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amdb.sp" + ", line " + STR( 71, 5 ) + " -- ENTRY: "
IF ( @perf_level >= 1 ) EXEC perf_sp "", "tmp/amdb.sp", 72, "Entry amDB_sp", @PERF_time_last OUTPUT

IF @debug_level > 5
	SELECT 	co_asset_book_id 	= @co_asset_book_id,
			from_date 			= @from_date,
			use_addition_info 	= @use_addition_info,
			acquisition_date	= @acquisition_date 

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
						4,
						@convention_id,
						@use_addition_info,
						@curr_precision,
						@basis 			OUTPUT,
						@basis_date		OUTPUT,		
						@debug_level 

IF ( @result != 0 )
	RETURN @result

IF ( @perf_level >= 2 ) EXEC perf_sp "", "tmp/amdb.sp", 108, "Got Basis", @PERF_time_last OUTPUT


EXEC @result = amGetDBInfo_sp 
						@co_asset_book_id,
						@apply_date,
						@rate 			OUTPUT, 
						@service_life 	OUTPUT,
						@debug_level 

IF ( @result != 0 )
	RETURN @result

IF ( @perf_level >= 2 ) EXEC perf_sp "", "tmp/amdb.sp", 121, "Got DB info", @PERF_time_last OUTPUT

IF @debug_level > 3
	SELECT 	basis = @basis,
		 	rate = @rate,
		 	service_life = @service_life 

IF @service_life != 0 
	SELECT @depr_rate = @rate / (100 * @service_life)
ELSE 
	SELECT @depr_rate = @rate / 100 

SELECT @depr_expense = (SIGN(@basis * @depr_rate) * ROUND(ABS(@basis * @depr_rate) + 0.0000001, @curr_precision)) 

IF @debug_level > 3
	SELECT 	depr_rate = @depr_rate 

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amdb.sp" + ", line " + STR( 138, 5 ) + " -- EXIT: "
IF ( @perf_level >= 1 ) EXEC perf_sp "", "tmp/amdb.sp", 139, "Exit amDB_sp", @PERF_time_last OUTPUT

RETURN 0 
GO
GRANT EXECUTE ON  [dbo].[amDB_sp] TO [public]
GO
