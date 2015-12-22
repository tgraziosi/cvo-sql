SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[amGetSwitchToSL_sp] 
( 	
	@co_asset_book_id smSurrogateKey, 	 
	@from_date 			smApplyDate, 		
	@sl_date 			smApplyDate OUTPUT,	
	@debug_level		smDebugLevel 	= 0 
)
AS 

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amswtsl.sp" + ", line " + STR( 51, 5 ) + " -- ENTRY: " 

SELECT @sl_date = NULL

SELECT 	@sl_date 			= switch_to_sl_date 
FROM 	amdprhst 
WHERE 	co_asset_book_id 	= @co_asset_book_id 
AND 	effective_date 	= (SELECT 	MAX(effective_date)
								FROM 	amdprhst 
								WHERE 	co_asset_book_id 	= @co_asset_book_id 
								AND 	effective_date 	<= @from_date)

IF @debug_level >= 4
	SELECT switch_to_sl_date = @sl_date
	
IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amswtsl.sp" + ", line " + STR( 66, 5 ) + " -- EXIT: "

RETURN 0 
GO
GRANT EXECUTE ON  [dbo].[amGetSwitchToSL_sp] TO [public]
GO
