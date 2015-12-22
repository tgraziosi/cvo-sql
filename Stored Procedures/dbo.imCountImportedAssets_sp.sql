SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[imCountImportedAssets_sp] 
(
	@company_id 		smCompanyID, 			
	@start_asset 		smControlNumber, 		
	@end_asset 			smControlNumber, 		
	@num_assets			smCounter		OUTPUT,	 
	@debug_level		smDebugLevel	= 0		
)
AS 

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/imprimct.sp" + ", line " + STR( 58, 5 ) + " -- ENTRY: "

SELECT @num_assets = 0


IF @start_asset = "<Start>"
BEGIN
	SELECT 	@start_asset 	= MIN(asset_ctrl_num)
	FROM	amasset
	WHERE	company_id		= @company_id
END

IF @end_asset = "<End>"
BEGIN
	SELECT 	@end_asset 		= MAX(asset_ctrl_num)
	FROM	amasset
	WHERE	company_id		= @company_id
END


SELECT 	@num_assets 	= COUNT(asset_ctrl_num)
FROM	amasset 
WHERE 	company_id 		= @company_id 
AND		is_imported		= 1
AND		activity_state	= 100
AND		asset_ctrl_num	BETWEEN @start_asset AND @end_asset


IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/imprimct.sp" + ", line " + STR( 91, 5 ) + " -- EXIT: "
 
RETURN 0 
GO
GRANT EXECUTE ON  [dbo].[imCountImportedAssets_sp] TO [public]
GO
