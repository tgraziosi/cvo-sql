SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[amMinDispositionDate_sp] 
(
	@co_asset_id 		smSurrogateKey, 		
	@disp_date 			smISODate 	OUTPUT, 	
	@debug_level		smDebugLevel	= 0		
)
AS 

DECLARE 
	@disposition_date 	smApplyDate 

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/ammindsp.sp" + ", line " + STR( 57, 5 ) + " -- ENTRY: "

SELECT 	@disposition_date 	= NULL

SELECT	@disposition_date 	= MAX(last_posted_depr_date)
FROM	amastbk
WHERE	co_asset_id 		= @co_asset_id

IF @disposition_date IS NULL
BEGIN
	SELECT	@disposition_date 	= acquisition_date
	FROM	amasset
	WHERE	co_asset_id 		= @co_asset_id

	
	IF @disposition_date IS NULL
		SELECT @disposition_date = GETDATE()

END
ELSE
	SELECT @disposition_date = DATEADD(dd, 1, @disposition_date)

SELECT @disp_date = CONVERT(char(8), @disposition_date, 112)

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/ammindsp.sp" + ", line " + STR( 81, 5 ) + " -- EXIT: "
 
RETURN 0 
GO
GRANT EXECUTE ON  [dbo].[amMinDispositionDate_sp] TO [public]
GO
