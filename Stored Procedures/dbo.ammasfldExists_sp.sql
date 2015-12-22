SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

 
CREATE PROCEDURE [dbo].[ammasfldExists_sp]
(
	@mass_maintenance_id 	smSurrogateKey,
	@mass_maintenance_type 	smMaintenanceType,
	@field_type 	smFieldType,
	@valid		int OUTPUT
)
AS
 
IF EXISTS (SELECT 1 FROM ammasfld
			WHERE	mass_maintenance_id 	= @mass_maintenance_id
	 		AND	mass_maintenance_type 	= @mass_maintenance_type
	 		AND	field_type 	= @field_type
			)
	SELECT @valid = 1
ELSE
	SELECT @valid = 0
 
RETURN 0
GO
GRANT EXECUTE ON  [dbo].[ammasfldExists_sp] TO [public]
GO
