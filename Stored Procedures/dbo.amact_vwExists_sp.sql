SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[amact_vwExists_sp] 
( 
	@co_asset_id		smSurrogateKey,
	@co_trx_id			smSurrogateKey, 
	@valid				int OUTPUT 
) 
AS 


IF EXISTS (SELECT 	co_trx_id 
			FROM 	amact_vw 
			WHERE 	co_asset_id		= @co_asset_id
			AND		co_trx_id		= @co_trx_id 
)
 SELECT @valid = 1 
ELSE 
 SELECT @valid = 0 
RETURN 0 
GO
GRANT EXECUTE ON  [dbo].[amact_vwExists_sp] TO [public]
GO
