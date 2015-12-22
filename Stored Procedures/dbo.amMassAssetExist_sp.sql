SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[amMassAssetExist_sp]
(
	@mass_maintenance_id 		smSurrogateKey,
	@valid						smLogical 	OUTPUT
)
AS


IF EXISTS (SELECT 1 
			FROM 	ammasast
			WHERE	mass_maintenance_id		= @mass_maintenance_id
			)
	SELECT @valid = 1
ELSE
	SELECT @valid = 0

RETURN 0
GO
GRANT EXECUTE ON  [dbo].[amMassAssetExist_sp] TO [public]
GO
