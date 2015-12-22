SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[amGetFirstDeprDate_sp] 
( 	
	@co_asset_book_id smSurrogateKey, 	
	@start_date 		smApplyDate 	OUTPUT,	
	@debug_level		smDebugLevel	= 0		
)
AS 

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amfrstdt.sp" + ", line " + STR( 55, 5 ) + " -- ENTRY: "

SELECT 	@start_date 		= first_depr_date 
FROM 	amastbk 
WHERE 	co_asset_book_id 	= @co_asset_book_id 

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amfrstdt.sp" + ", line " + STR( 61, 5 ) + " -- EXIT: "

RETURN 0 
GO
GRANT EXECUTE ON  [dbo].[amGetFirstDeprDate_sp] TO [public]
GO
