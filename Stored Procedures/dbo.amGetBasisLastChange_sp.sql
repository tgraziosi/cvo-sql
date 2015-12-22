SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[amGetBasisLastChange_sp] 
(
	@co_asset_book_id smSurrogateKey, 	
	@from_date 			smApplyDate, 		
	@prd_end_date		smApplyDate,		
	@salvage_value 		smMoneyZero, 		
	@curr_precision		smallint,			
	@basis 			smMoneyZero OUTPUT,	
	@basis_date 		smApplyDate OUTPUT,	
	@debug_level		smDebugLevel = 0, 	
	@perf_level			smPerfLevel 	= 0	
)
AS 

DECLARE 
	@return_status 	smErrorCode, 
	@start_fscl_yr 		smApplyDate, 
	@profile_date 		smApplyDate, 
	@activity_type 		smBoundaryType, 
	@cost 				smMoneyZero, 
	@accum_depr 		smMoneyZero, 
	@cost_delta 		smMoneyZero, 
	@accum_depr_delta 	smMoneyZero







DECLARE
 @PERF_time_last datetime

SELECT @PERF_time_last = GETDATE()















									







IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amlstchg.sp" + ", line " + STR( 73, 5 ) + " -- ENTRY: "

IF ( @perf_level >= 1 ) EXEC perf_sp "", "tmp/amlstchg.sp", 75, "Entry amGetBasisLastChange_sp", @PERF_time_last OUTPUT

IF @debug_level >= 4
	SELECT 	from_date 		= @from_date,
			salvage_value 	= @salvage_value 

EXEC @return_status = amGetFiscalYear_sp 
						@from_date,
						0,
						@start_fscl_yr 	OUTPUT 

IF ( @return_status != 0 )
	RETURN @return_status 


 
SELECT @activity_type = 1 

EXEC @return_status = amGetLastActivityDate_sp 	
						@co_asset_book_id,
						@start_fscl_yr,
						@from_date,
						2,
						@basis_date 	OUTPUT,
						@activity_type 	OUTPUT,
						@debug_level 

IF @return_status <> 0
	RETURN @return_status

IF @debug_level >= 5
	SELECT 	start_fscl_yr 	= @start_fscl_yr,
			activity_date 	= @basis_date,
			activity_type 	= @activity_type 

IF ( @perf_level >= 1 ) EXEC perf_sp "", "tmp/amlstchg.sp", 112, "Got last activity Date", @PERF_time_last OUTPUT

EXEC @return_status = amGetProfile_sp 	
							@co_asset_book_id,
							@basis_date,
							@cost 			OUTPUT,	
							@accum_depr 	OUTPUT,	
							@profile_date 	OUTPUT,
							@debug_level
						 
IF @return_status <> 0
	RETURN @return_status
			
IF @debug_level >= 5
	SELECT 	basis_date 	= @basis_date,
			cost 		= @cost,
			accum_depr 	= @accum_depr 

IF ( @perf_level >= 1 ) EXEC perf_sp "", "tmp/amlstchg.sp", 130, "Got profile", @PERF_time_last OUTPUT

 
EXEC @return_status = amGetChangesToProfile_sp 
						@co_asset_book_id,
						@profile_date, 
						@prd_end_date,
						@curr_precision,
						@cost_delta 		OUTPUT,	
						@accum_depr_delta 	OUTPUT,
						@debug_level 

IF ( @return_status != 0 )
	RETURN @return_status

SELECT @basis = (SIGN(@cost + @cost_delta + @accum_depr + @accum_depr_delta - @salvage_value) * ROUND(ABS(@cost + @cost_delta + @accum_depr + @accum_depr_delta - @salvage_value) + 0.0000001, @curr_precision)) 

IF @debug_level >= 3
	SELECT cost_delta 			= @cost_delta,
			accum_depr_delta 	= @accum_depr_delta,
			salvage 			= @salvage_value,
			basis 				= @basis 

IF ( @perf_level >= 1 ) EXEC perf_sp "", "tmp/amlstchg.sp", 155, "Exit amGetBasisLastChange_sp", @PERF_time_last OUTPUT
IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amlstchg.sp" + ", line " + STR( 156, 5 ) + " -- EXIT: "

RETURN 0 
GO
GRANT EXECUTE ON  [dbo].[amGetBasisLastChange_sp] TO [public]
GO
