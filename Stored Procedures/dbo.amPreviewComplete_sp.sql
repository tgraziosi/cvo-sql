SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[amPreviewComplete_sp] 
( 
	@co_trx_id 		smSurrogateKey, 	
	@valid 	smLogical 	OUTPUT,	
	@apply_date	 		smISODate	OUTPUT, 
 	@break_down_by_prd	smLogical	OUTPUT,	
	@debug_level		smDebugLevel	= 0	
) 
AS 

DECLARE	
	@d					smApplyDate,
	@co_asset_book_id	smSurrogateKey,
	@year_end_date		smApplyDate

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amprvcom.sp" + ", line " + STR( 91, 5 ) + " -- ENTRY: "

SELECT @apply_date = NULL

SELECT 	@d 			= MAX(apply_date)
FROM 	amcalval 
WHERE 	co_trx_id 	= @co_trx_id

IF @d IS NOT NULL
BEGIN
 SELECT @valid = 1 
	SELECT @apply_date = CONVERT(char(8), @d, 112)

	SELECT 	@co_asset_book_id 	= MIN(co_asset_book_id)
	FROM	amcalval
	WHERE	co_trx_id			= @co_trx_id
		
	SELECT 	@year_end_date		= year_end_date
	FROM	amcalval
	WHERE	co_trx_id			= @co_trx_id
	AND		co_asset_book_id	= @co_asset_book_id
	AND		apply_date			= @d

	IF @year_end_date IS NULL
		SELECT	@break_down_by_prd = 0
	ELSE
		SELECT	@break_down_by_prd = 1
END
ELSE 
 SELECT @valid = 0
 
IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amprvcom.sp" + ", line " + STR( 122, 5 ) + " -- EXIT: "

RETURN 0
GO
GRANT EXECUTE ON  [dbo].[amPreviewComplete_sp] TO [public]
GO
