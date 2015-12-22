SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

 
CREATE PROCEDURE [dbo].[amGetAssetID_sp] 
( 
	@asset_ctrl_num 	smControlNumber, 		
	@company_id 	smCompanyID, 			
 @co_asset_id 	smSurrogateKey OUTPUT, 	
	@debug_level		smDebugLevel	= 0		
)
AS 
 
DECLARE @message smErrorLongDesc 

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amastid.sp" + ", line " + STR( 58, 5 ) + " -- ENTRY: "

SELECT @co_asset_id = co_asset_id 
FROM amasset 
WHERE asset_ctrl_num = @asset_ctrl_num 
AND company_id = @company_id 

IF @@rowcount = 1 
 RETURN 0 
 
IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amastid.sp" + ", line " + STR( 68, 5 ) + " -- EXIT: "

RETURN 0
GO
GRANT EXECUTE ON  [dbo].[amGetAssetID_sp] TO [public]
GO
