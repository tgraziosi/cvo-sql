SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[ammasast_vwExists_sp]
(
		@mass_maintenance_id smSurrogateKey, @company_id smSurrogateKey, @asset_ctrl_num smControlNumber,
		@valid						smLogical 	OUTPUT
)
AS

IF EXISTS (SELECT 1 
			FROM 	ammasast_vw
			WHERE	mass_maintenance_id		= @mass_maintenance_id
			AND		company_id				= @company_id
			AND		asset_ctrl_num			= @asset_ctrl_num
			)
	SELECT @valid = 1
ELSE
	SELECT @valid = 0

RETURN 0
GO
GRANT EXECUTE ON  [dbo].[ammasast_vwExists_sp] TO [public]
GO
