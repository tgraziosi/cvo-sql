SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

 
CREATE PROCEDURE [dbo].[ammasfldFetch_sp]
(
	@rowsrequested		smCounter = 1,
	@mass_maintenance_id 	smSurrogateKey,
	@mass_maintenance_type 	smMaintenanceType,
	@field_type 	smFieldType
)
AS
 
DECLARE	@rowsfound	smCounter
DECLARE	@MSKfield_type	smFieldType
DECLARE	@MSKmass_maintenance_type	smMaintenanceType
DECLARE	@MSKmass_maintenance_id	smSurrogateKey
 
CREATE TABLE #temp
(
	timestamp	varbinary(8)	NULL,
	mass_maintenance_id	int	NULL,
	mass_maintenance_type	int	NULL,
	field_type	int	NULL,
	new_value	varchar(40)	NULL
)
 
SELECT	@rowsfound	= 0
SELECT	@MSKfield_type	= @field_type
SELECT	@MSKmass_maintenance_type	= @mass_maintenance_type
SELECT	@MSKmass_maintenance_id	= @mass_maintenance_id
 
IF EXISTS (SELECT * FROM ammasfld
			WHERE	mass_maintenance_id	= @MSKmass_maintenance_id
			AND		mass_maintenance_type	= @MSKmass_maintenance_type
			AND		field_type	= @MSKfield_type)
BEGIN
 
WHILE @MSKfield_type IS NOT NULL AND @rowsfound < @rowsrequested
BEGIN
 
	INSERT INTO #temp
	SELECT
		timestamp,
		mass_maintenance_id,
		mass_maintenance_type,
		field_type,
		new_value
	FROM	ammasfld
	WHERE		mass_maintenance_id = @MSKmass_maintenance_id
	AND		mass_maintenance_type = @MSKmass_maintenance_type
	AND		field_type = @MSKfield_type
 
	SELECT	@rowsfound = @rowsfound + @@rowcount
 
	SELECT @MSKfield_type	= MIN(field_type)
	FROM ammasfld
	WHERE	mass_maintenance_id = @MSKmass_maintenance_id
	AND	mass_maintenance_type = @MSKmass_maintenance_type
	AND	field_type	> @MSKfield_type
END
SELECT @MSKmass_maintenance_type	= MIN(mass_maintenance_type)
FROM	ammasfld
WHERE	mass_maintenance_id = @MSKmass_maintenance_id
AND	mass_maintenance_type > @MSKmass_maintenance_type
 
WHILE @MSKmass_maintenance_type IS NOT NULL AND @rowsfound < @rowsrequested
BEGIN
	SELECT	@MSKfield_type	= MIN(field_type)
	FROM	ammasfld
	WHERE	mass_maintenance_id	= @MSKmass_maintenance_id
	AND		mass_maintenance_type	= @MSKmass_maintenance_type
 
	WHILE @MSKfield_type IS NOT NULL AND @rowsfound < @rowsrequested
	BEGIN
 
		INSERT INTO #temp
		SELECT
			timestamp,
			mass_maintenance_id,
			mass_maintenance_type,
			field_type,
			new_value
		FROM	ammasfld
		WHERE		mass_maintenance_id = @MSKmass_maintenance_id
		AND		mass_maintenance_type = @MSKmass_maintenance_type
		AND		field_type = @MSKfield_type
 
		SELECT	@rowsfound = @rowsfound + @@rowcount
 
 
		SELECT	@MSKfield_type	= MIN(field_type)
		FROM	ammasfld
		WHERE	mass_maintenance_id = @MSKmass_maintenance_id
		AND		mass_maintenance_type = @MSKmass_maintenance_type
		AND		field_type	> @MSKfield_type
	END
 
	SELECT @MSKmass_maintenance_type	= MIN(mass_maintenance_type)
	FROM ammasfld
	WHERE	mass_maintenance_id = @MSKmass_maintenance_id
	AND	mass_maintenance_type	> @MSKmass_maintenance_type
END
SELECT @MSKmass_maintenance_id	= MIN(mass_maintenance_id)
FROM	ammasfld
WHERE	mass_maintenance_id > @MSKmass_maintenance_id
 
WHILE @MSKmass_maintenance_id IS NOT NULL AND @rowsfound < @rowsrequested
BEGIN
	SELECT	@MSKmass_maintenance_type	= MIN(mass_maintenance_type)
	FROM	ammasfld
	WHERE	mass_maintenance_id	= @MSKmass_maintenance_id
 
	WHILE @MSKmass_maintenance_type IS NOT NULL AND @rowsfound < @rowsrequested
	BEGIN
		SELECT	@MSKfield_type	= MIN(field_type)
		FROM	ammasfld
		WHERE	mass_maintenance_id	= @MSKmass_maintenance_id
		AND		mass_maintenance_type	= @MSKmass_maintenance_type
 
		WHILE @MSKfield_type IS NOT NULL AND @rowsfound < @rowsrequested
		BEGIN
 
			INSERT INTO #temp
			SELECT
				timestamp,
				mass_maintenance_id,
				mass_maintenance_type,
				field_type,
				new_value
			FROM	ammasfld
			WHERE		mass_maintenance_id = @MSKmass_maintenance_id
			AND		mass_maintenance_type = @MSKmass_maintenance_type
			AND		field_type = @MSKfield_type
 
			SELECT	@rowsfound = @rowsfound + @@rowcount
 
 
			SELECT	@MSKfield_type	= MIN(field_type)
			FROM	ammasfld
			WHERE	mass_maintenance_id = @MSKmass_maintenance_id
			AND		mass_maintenance_type = @MSKmass_maintenance_type
			AND		field_type	> @MSKfield_type
		END
 
 
		SELECT	@MSKmass_maintenance_type	= MIN(mass_maintenance_type)
		FROM	ammasfld
		WHERE	mass_maintenance_id = @MSKmass_maintenance_id
		AND		mass_maintenance_type	> @MSKmass_maintenance_type
	END
 
	SELECT @MSKmass_maintenance_id	= MIN(mass_maintenance_id)
	FROM ammasfld
	WHERE	mass_maintenance_id	> @MSKmass_maintenance_id
END
END
SELECT
	timestamp,
	mass_maintenance_id,
	mass_maintenance_type,
	field_type,
	new_value
FROM	#temp
ORDER BY	mass_maintenance_id, mass_maintenance_type, field_type
 
DROP TABLE #temp
 
RETURN 0
GO
GRANT EXECUTE ON  [dbo].[ammasfldFetch_sp] TO [public]
GO
