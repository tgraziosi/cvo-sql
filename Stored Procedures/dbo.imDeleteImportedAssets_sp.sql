SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[imDeleteImportedAssets_sp] 
(
	@company_id 		smCompanyID, 		
	@start_asset 		smControlNumber, 	
	@end_asset 			smControlNumber, 	
	@debug_level		smDebugLevel	= 0	
)
AS 

DECLARE @error_code 		smErrorCode

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/imdelimp.sp" + ", line " + STR( 64, 5 ) + " -- ENTRY: " 


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

DELETE
FROM	amasset
WHERE	company_id		= @company_id
AND		asset_ctrl_num	BETWEEN @start_asset AND @end_asset
AND		is_imported		= 1
AND		activity_state	= 100

SELECT	@error_code = @@error
IF @error_code <> 0
	RETURN @error_code

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/imdelimp.sp" + ", line " + STR( 94, 5 ) + " -- EXIT: "
 
RETURN 0 
GO
GRANT EXECUTE ON  [dbo].[imDeleteImportedAssets_sp] TO [public]
GO
