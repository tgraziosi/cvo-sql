SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[amBookValuesGet_sp] 
(
 @co_asset_book_id smSurrogateKey,		
	@co_trx_id 	 		smSurrogateKey,		
	@debug_level		smDebugLevel = 0	
)
AS 

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amactget.sp" + ", line " + STR( 46, 5 ) + " -- ENTRY: "

SELECT 	account_type_id, 
		amount, 
		timestamp,
		posting_flag 
FROM 	amvalues 
WHERE 	co_trx_id 			= @co_trx_id 
AND 	co_asset_book_id	= @co_asset_book_id 

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amactget.sp" + ", line " + STR( 56, 5 ) + " -- EXIT: "

RETURN 0
GO
GRANT EXECUTE ON  [dbo].[amBookValuesGet_sp] TO [public]
GO
