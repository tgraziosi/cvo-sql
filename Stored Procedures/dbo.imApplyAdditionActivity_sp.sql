SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE [dbo].[imApplyAdditionActivity_sp] 
( 
	@co_asset_book_id 		smSurrogateKey,		 
	@acquisition_date		smApplyDate, 		 
	@placed_in_service_date	smApplyDate,		 
	@addition_co_trx_id		smSurrogateKey,		
	@debug_level			smDebugLevel	= 0	
)
AS 

DECLARE 
	@ret_status 			smErrorCode, 
	@convention_id 			smConventionID, 
	@effective_date 		smApplyDate, 
	@cost					smMoneyZero,
	@accum_depr				smMoneyZero

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/imappadd.sp" + ", line " + STR( 64, 5 ) + " -- ENTRY: "

IF @debug_level	>= 3
	SELECT 	co_asset_book_id = @co_asset_book_id
	
 
IF @placed_in_service_date IS NOT NULL 
BEGIN 
	EXEC @ret_status = amGetConventionID_sp 
							@co_asset_book_id,
							@acquisition_date,
							@convention_id 	OUTPUT 

	IF @ret_status <> 0 
		RETURN @ret_status 

	EXEC @ret_status = amGetEffectiveDate_sp 
							@placed_in_service_date,
							10,
							@convention_id,
						 	@effective_date OUTPUT 

	IF @ret_status <> 0 
		RETURN @ret_status 
END 
ELSE 
	SELECT @effective_date = NULL 

IF @debug_level	>= 3
	SELECT 	effective_date = @effective_date


SELECT	@cost 		= 0.0,
		@accum_depr	= 0.0 

SELECT 	@cost 				= amount 
FROM 	amvalues 
WHERE 	co_trx_id 			= @addition_co_trx_id 
AND 	co_asset_book_id 	= @co_asset_book_id 
AND 	account_type_id 	= 0 

SELECT 	@accum_depr 		= amount 
FROM 	amvalues 
WHERE 	co_trx_id 			= @addition_co_trx_id 
AND 	co_asset_book_id 	= @co_asset_book_id 
AND 	account_type_id 	= 1 

IF @debug_level	>= 3
	SELECT 	cost 		= @cost,
			accum_depr 	= @accum_depr

 
UPDATE 	amacthst 
SET 	revised_cost 		= @cost,
		revised_accum_depr 	= @accum_depr,
		delta_cost 			= @cost,
		delta_accum_depr 	= @accum_depr,				 
		effective_date 		= @effective_date 
WHERE 	co_trx_id 			= @addition_co_trx_id 
AND 	co_asset_book_id 	= @co_asset_book_id 

SELECT @ret_status = @@error
IF @ret_status <> 0
BEGIN
	IF @debug_level >= 3
		SELECT "Update of amacthst failed"
	RETURN @ret_status 
END

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/imappadd.sp" + ", line " + STR( 141, 5 ) + " -- EXIT: "

RETURN 0 
GO
GRANT EXECUTE ON  [dbo].[imApplyAdditionActivity_sp] TO [public]
GO
