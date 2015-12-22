SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

 
CREATE PROCEDURE [dbo].[ammashdrExists_sp]
(
	@mass_maintenance_id 	smSurrogateKey,
	@valid		int OUTPUT
)
AS
 
IF EXISTS (SELECT 1 FROM ammashdr
			WHERE	mass_maintenance_id 	= @mass_maintenance_id
			)
	SELECT @valid = 1
ELSE
	SELECT @valid = 0
 
RETURN 0
GO
GRANT EXECUTE ON  [dbo].[ammashdrExists_sp] TO [public]
GO
