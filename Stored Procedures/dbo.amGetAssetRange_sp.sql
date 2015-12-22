SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[amGetAssetRange_sp] 
( 
	@company_id				smCompanyID,			
	@co_trx_id 	 		smSurrogateKey, 		 
	@start_asset 			smControlNumber OUTPUT,  
	@end_asset 				smControlNumber	OUTPUT,	 	
	@debug_level			smDebugLevel	= 0		
)
AS 

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amastrng.sp" + ", line " + STR( 56, 5 ) + " -- ENTRY: " 

SELECT	@start_asset 	= NULL,
		@end_asset		= NULL

SELECT	@start_asset 	= ISNULL(from_code, "<Start>"),
		@end_asset		= ISNULL(to_code, "<End>")
FROM	amdprcrt
WHERE	co_trx_id		= @co_trx_id
AND		field_type		= 7

IF @start_asset IS NULL OR @start_asset = ""
	SELECT @start_asset = "<Start>"
IF @end_asset IS NULL OR @end_asset = ""
	SELECT @end_asset = "<End>"

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

IF @debug_level >= 5
	SELECT 	start_asset = @start_asset, 
			end_asset	= @end_asset

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amastrng.sp" + ", line " + STR( 94, 5 ) + " -- EXIT: " 

RETURN 0 
GO
GRANT EXECUTE ON  [dbo].[amGetAssetRange_sp] TO [public]
GO
