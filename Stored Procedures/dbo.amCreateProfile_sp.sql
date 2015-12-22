SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE [dbo].[amCreateProfile_sp] 
( 	
	@co_asset_book_id 	smSurrogateKey, 	
	@profile_date 	smApplyDate, 			
	@cost 					smMoneyZero 	= 0,	
	@accum_depr 			smMoneyZero 	= 0,	
	@posting_flag 			smLogical 		= 0, 	
	@debug_level			smDebugLevel	= 0		
) 
AS 

DECLARE 
 	@effective_date 		smApplyDate, 
	@result					smErrorCode 

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amcreprf.sp" + ", line " + STR( 66, 5 ) + " -- ENTRY: "

IF @debug_level >= 3
	SELECT 	profile_date 	= @profile_date,
			cost 			= @cost,
			accum_depr 		= @accum_depr 

 
SELECT @effective_date 	= MAX(effective_date)
FROM 	amdprhst 
WHERE 	co_asset_book_id 	= @co_asset_book_id 
AND 	effective_date 		<= @profile_date 

IF @debug_level >= 3
	SELECT effective_date 		= @effective_date 

INSERT into #amastprf 
( 
	co_asset_book_id,
	fiscal_period_end,
	current_cost,
	accum_depr,
	effective_date,
	posting_flag
)
VALUES 
( 
	@co_asset_book_id,
	@profile_date,
	@cost, 
	@accum_depr, 
	@effective_date,
	@posting_flag
)

SELECT @result = @@error
IF ( @result != 0 ) 
	 RETURN @result 

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amcreprf.sp" + ", line " + STR( 107, 5 ) + " -- EXIT: "

RETURN 0 
GO
GRANT EXECUTE ON  [dbo].[amCreateProfile_sp] TO [public]
GO
