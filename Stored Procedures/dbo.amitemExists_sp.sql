SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[amitemExists_sp] 
( 
	@co_asset_id	smSurrogateKey, 	
	@sequence_id	smSurrogateKey, 	
	@valid			int 	OUTPUT 		
) 
AS 

IF EXISTS (SELECT 	co_asset_id 
			FROM 	amitem 
			WHERE 	co_asset_id	= @co_asset_id 
			AND 	sequence_id	= @sequence_id )
 SELECT @valid = 1 
ELSE 
 SELECT @valid = 0

RETURN 0 
GO
GRANT EXECUTE ON  [dbo].[amitemExists_sp] TO [public]
GO
