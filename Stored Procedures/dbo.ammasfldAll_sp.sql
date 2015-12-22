SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

 
CREATE PROCEDURE [dbo].[ammasfldAll_sp]
AS
 
SELECT
	timestamp,
	mass_maintenance_id,
	mass_maintenance_type,
	field_type,
	new_value
FROM	ammasfld
ORDER BY	mass_maintenance_id, mass_maintenance_type, field_type
 
RETURN 0
GO
GRANT EXECUTE ON  [dbo].[ammasfldAll_sp] TO [public]
GO
