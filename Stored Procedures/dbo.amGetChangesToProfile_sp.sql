SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE [dbo].[amGetChangesToProfile_sp] 
( 
	@co_asset_book_id smSurrogateKey, 		 
	@start_date 		smApplyDate, 			
	@end_date 			smApplyDate, 			
	@curr_precision		smallint,			
	@cost_delta 		smMoneyZero 	OUTPUT,	
	@accum_depr_delta 	smMoneyZero 	OUTPUT,	
	@debug_level		smDebugLevel 	= 0		
)
AS 

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amchgprf.sp" + ", line " + STR( 56, 5 ) + " -- ENTRY: "

IF @debug_level >= 5
	SELECT 	start_date 	= @start_date,
			end_date 	= @end_date 

SELECT 	@cost_delta 		= 0.0, 
		@accum_depr_delta 	= 0.0 

SELECT 	@cost_delta 		= (SIGN(ISNULL(SUM(delta_cost), 0.0)) * ROUND(ABS(ISNULL(SUM(delta_cost), 0.0)) + 0.0000001, @curr_precision)), 
		@accum_depr_delta 	= (SIGN(ISNULL(SUM(delta_accum_depr), 0.0)) * ROUND(ABS(ISNULL(SUM(delta_accum_depr), 0.0)) + 0.0000001, @curr_precision))
FROM 	amacthst 
WHERE 	co_asset_book_id	 = 	@co_asset_book_id 
AND 	trx_type 			!= 50
AND 	apply_date	 		> 	@start_date 
AND 	apply_date 			<= 	@end_date 



SELECT 	@accum_depr_delta 	= (SIGN(@accum_depr_delta - ISNULL(SUM(disposed_depr), 0.0)) * ROUND(ABS(@accum_depr_delta - ISNULL(SUM(disposed_depr), 0.0)) + 0.0000001, @curr_precision))
FROM 	amacthst 
WHERE 	co_asset_book_id 	= @co_asset_book_id
AND		trx_type			= 70
AND 	apply_date	 		> 	@start_date 
AND 	apply_date 			<= 	@end_date 

IF @debug_level >= 3
	SELECT 	cost_delta 			= @cost_delta,
			accum_depr_delta 	= @accum_depr_delta 

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amchgprf.sp" + ", line " + STR( 89, 5 ) + " -- EXIT: "

RETURN 0 
GO
GRANT EXECUTE ON  [dbo].[amGetChangesToProfile_sp] TO [public]
GO
