SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

 
CREATE PROCEDURE [dbo].[ammasfldInsert_sp]
(
	@mass_maintenance_id 	smSurrogateKey,
	@mass_maintenance_type 	smMaintenanceType,
	@field_type 	smFieldType,
	@new_value 	smFieldData
)
AS
 
INSERT INTO ammasfld
(
	mass_maintenance_id,
	mass_maintenance_type,
	field_type,
	new_value
)
VALUES
(
	@mass_maintenance_id,
	@mass_maintenance_type,
	@field_type,
	@new_value
)
 
RETURN @@error
GO
GRANT EXECUTE ON  [dbo].[ammasfldInsert_sp] TO [public]
GO
