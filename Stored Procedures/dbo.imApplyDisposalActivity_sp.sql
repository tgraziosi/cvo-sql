SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[imApplyDisposalActivity_sp] 
( 
	@co_asset_book_id 	smSurrogateKey, 	 
	@co_trx_id 			smSurrogateKey, 		
	@disposition_date	smApplyDate,			
	@curr_precision		smallint,			
	@cost 				smMoneyZero OUTPUT,		
	@accum_depr 		smMoneyZero OUTPUT,		
	@debug_level		smDebugLevel = 0		
)
AS 

DECLARE 
	@result 			smErrorCode,
	@delta_cost 		smMoneyZero, 
	@delta_accum_depr 	smMoneyZero,
	@gain				smMoneyZero,		 	
	@proceeds			smMoneyZero,		 	 
	@fiscal_period_end	smApplyDate			 	

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/imappdsp.sp" + ", line " + STR( 83, 5 ) + " -- ENTRY: "

IF @debug_level >= 5
	SELECT 	co_asset_book_id 	= @co_asset_book_id,
			co_trx_id 			= @co_trx_id,
			cost 				= @cost,
			accum_depr 			= @accum_depr 

SELECT 	@delta_cost 		= 0.0,
		@delta_accum_depr	= 0.0,
		@gain				= 0.0,
		@proceeds			= 0.0

SELECT 	@delta_cost 		= amount
FROM 	amvalues 
WHERE 	co_trx_id 			= @co_trx_id 
AND 	co_asset_book_id 	= @co_asset_book_id 
AND 	account_type_id 	= 0 

SELECT 	@delta_accum_depr 	= amount
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

SELECT 	@gain		 		= amount
FROM 	amvalues 
WHERE 	co_trx_id 			= @co_trx_id 
AND 	co_asset_book_id 	= @co_asset_book_id 
AND 	account_type_id 	= 8 

SELECT 	@proceeds		 	= amount
FROM 	amvalues 
WHERE 	co_trx_id 			= @co_trx_id 
AND 	co_asset_book_id 	= @co_asset_book_id 
AND 	account_type_id 	= 4

UPDATE	amastbk
SET		gain_loss			= @gain,
		proceeds			= @proceeds
FROM	amastbk
WHERE	co_asset_book_id 	= @co_asset_book_id 

SELECT @result = @@error
IF ( @result <> 0 )
	RETURN @result 

 
EXEC @result = amGetFiscalPeriod_sp
					@disposition_date,
					1,				
					@fiscal_period_end	OUTPUT

IF ( @result <> 0 )
	RETURN @result 

EXEC @result = imCreateProfile_sp
					@co_asset_book_id,
					@fiscal_period_end,
					@cost,
					@accum_depr
					
IF ( @result <> 0 ) 
	 RETURN @result 
	 
IF @debug_level >= 5
	SELECT 	cost 		= @cost,
			accum_depr 	= @accum_depr,
			delta_cost 	= @delta_cost,
			delta_accum = @delta_accum_depr 

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/imappdsp.sp" + ", line " + STR( 176, 5 ) + " -- EXIT: "
 
RETURN 0 
GO
GRANT EXECUTE ON  [dbo].[imApplyDisposalActivity_sp] TO [public]
GO
