SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[amGetValueRep_sp] 
(
 @co_asset_book_id 	smSurrogateKey,			 
 @account_type 	smAccountTypeID, 		
 @fiscal_period_start 	smApplyDate, 			
 @fiscal_period_end 	smApplyDate, 			
 @trx_type 	smTrxType, 				
	@curr_precision			smallint,				
 @value 	smMoneyZero OUTPUT, 	
	@debug_level			smDebugLevel	= 0		
)
AS 

DECLARE 
	@message 	smErrorLongDesc, 
	@result 	smErrorCode 

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amvalrep.sp" + ", line " + STR( 78, 5 ) + " -- ENTRY: "

SELECT @value = 0.0 

SELECT @value 				= (SIGN(ISNULL(SUM(amount), 0.0)) * ROUND(ABS(ISNULL(SUM(amount), 0.0)) + 0.0000001, @curr_precision))
FROM amvalues 
WHERE co_asset_book_id 	= @co_asset_book_id 
AND 	account_type_id 	= @account_type 
AND 	trx_type 			= @trx_type 
AND 	apply_date 		BETWEEN @fiscal_period_start AND @fiscal_period_end 

SELECT 	@result = @@error 

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amvalrep.sp" + ", line " + STR( 91, 5 ) + " -- EXIT: "

RETURN @result 
GO
GRANT EXECUTE ON  [dbo].[amGetValueRep_sp] TO [public]
GO
