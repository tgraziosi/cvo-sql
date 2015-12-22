SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

 
CREATE PROCEDURE [dbo].[amGetAssetCtrl_sp] 
( 
 @co_asset_id smSurrogateKey, 			
 	@asset_ctrl_num smControlNumber 	OUTPUT,	
 	@company_id smCompanyID 		OUTPUT,	
	@debug_level		smDebugLevel	= 	0		
)
AS 
 
IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amastctl.sp" + ", line " + STR( 57, 5 ) + " -- ENTRY: "

 

SELECT @asset_ctrl_num 	= asset_ctrl_num,
 @company_id 	= company_id 
FROM amasset 
WHERE co_asset_id 		= @co_asset_id 

IF @@rowcount != 1 
	RETURN 20020

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amastctl.sp" + ", line " + STR( 69, 5 ) + " -- EXIT: "

RETURN 0 
GO
GRANT EXECUTE ON  [dbo].[amGetAssetCtrl_sp] TO [public]
GO
