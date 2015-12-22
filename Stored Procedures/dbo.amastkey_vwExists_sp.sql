SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[amastkey_vwExists_sp] 
( 
	@co_asset_id		smSurrogateKey,
	@valid				int OUTPUT 
) 
AS 


IF EXISTS (SELECT 	co_asset_id 
			FROM 	amasset 
			WHERE 	co_asset_id	= @co_asset_id 
)
 SELECT @valid = 1 
ELSE 
 SELECT @valid = 0 

RETURN 0 
GO
GRANT EXECUTE ON  [dbo].[amastkey_vwExists_sp] TO [public]
GO
