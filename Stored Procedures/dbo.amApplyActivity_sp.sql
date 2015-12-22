SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE [dbo].[amApplyActivity_sp] 
( 
	@co_asset_book_id 	smSurrogateKey, 	 
	@co_trx_id 			smSurrogateKey, 	
	@curr_precision		smallint,			
	@cost 				smMoneyZero OUTPUT,	
	@accum_depr 		smMoneyZero OUTPUT,	
	@debug_level		smDebugLevel = 0 	
)
AS 

DECLARE 
	@delta_cost 		smMoneyZero,	 
	@delta_accum_depr 	smMoneyZero, 	
	@result				smErrorCode 	

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amappact.sp" + ", line " + STR( 65, 5 ) + " -- ENTRY: "

IF @debug_level >= 3
	SELECT 	co_asset_book_id 	= @co_asset_book_id,
			co_trx_id 			= @co_trx_id,
			cost 				= @cost,
			accum_depr 			= @accum_depr 

SELECT 	@delta_cost 		= 0.0,
		@delta_accum_depr 	= 0.0 


SELECT 	@delta_cost 		= ISNULL(amount, 0.0)
FROM 	amvalues 
WHERE 	co_trx_id 			= @co_trx_id 
AND 	co_asset_book_id 	= @co_asset_book_id 
AND 	account_type_id 	= 0 


SELECT 	@delta_accum_depr 	= ISNULL(amount, 0.0)
FROM 	amvalues 
WHERE 	co_trx_id 			= @co_trx_id 
AND 	co_asset_book_id 	= @co_asset_book_id 
AND 	account_type_id 	= 1 

SELECT 	@cost 		= (SIGN(@cost + @delta_cost) * ROUND(ABS(@cost + @delta_cost) + 0.0000001, @curr_precision)),
		@accum_depr = (SIGN(@accum_depr + @delta_accum_depr) * ROUND(ABS(@accum_depr + @delta_accum_depr) + 0.0000001, @curr_precision)) 
		

UPDATE 	amacthst 
SET 	revised_cost 		= @cost,
		revised_accum_depr 	= @accum_depr,
		delta_cost 			= @delta_cost,
		delta_accum_depr 	= @delta_accum_depr 
WHERE 	co_trx_id 			= @co_trx_id 
AND 	co_asset_book_id 	= @co_asset_book_id 

SELECT @result = @@error
IF ( @result != 0 )
	RETURN @result 

IF @debug_level >= 3
	SELECT 	cost 		= @cost,
			accum_depr 	= @accum_depr,
			delta_cost 	= @delta_cost,
			delta_accum = @delta_accum_depr 

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amappact.sp" + ", line " + STR( 119, 5 ) + " -- EXIT: "

RETURN 0 
GO
GRANT EXECUTE ON  [dbo].[amApplyActivity_sp] TO [public]
GO
