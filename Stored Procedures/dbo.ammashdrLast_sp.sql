SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

 
CREATE PROCEDURE [dbo].[ammashdrLast_sp]
(
	@rowsrequested		smCounter = 1
)
AS
 
DECLARE	@rowsfound	smCounter
DECLARE	@MSKmass_maintenance_id	smSurrogateKey
 
CREATE TABLE #temp
(
	timestamp	varbinary(8)	NULL,
	mass_maintenance_id	int	NULL,
	mass_description	varchar(40)	NULL,
	one_at_a_time	tinyint	NULL,
	user_id	int	NULL,
	group_id	int	NULL,
	assets_purged	tinyint	NULL,
	process_start_date	datetime	NULL,
	process_end_date	datetime	NULL,
	error_code	int	NULL,
	error_message	varchar(255)	NULL
)
 
SELECT	@rowsfound	= 0
 
 
SELECT	@MSKmass_maintenance_id	= MAX(mass_maintenance_id)
FROM	ammashdr
 
IF @MSKmass_maintenance_id IS NULL
BEGIN
	DROP TABLE #temp
	RETURN
END
 
INSERT INTO #temp
SELECT
	timestamp,
	mass_maintenance_id,
	mass_description,
	one_at_a_time,
	user_id,
	group_id,
	assets_purged,
	process_start_date,
	process_end_date,
	error_code,
	error_message
FROM	ammashdr
WHERE	mass_maintenance_id	= @MSKmass_maintenance_id
 
SELECT @rowsfound = @@rowcount
 
SELECT @MSKmass_maintenance_id	= MAX(mass_maintenance_id)
FROM	ammashdr
WHERE	mass_maintenance_id < @MSKmass_maintenance_id
 
WHILE @MSKmass_maintenance_id IS NOT NULL AND @rowsfound < @rowsrequested
BEGIN
 
	INSERT INTO #temp
	SELECT
		timestamp,
		mass_maintenance_id,
		mass_description,
		one_at_a_time,
		user_id,
		group_id,
		assets_purged,
		process_start_date,
		process_end_date,
		error_code,
		error_message
	FROM	ammashdr
	WHERE		mass_maintenance_id = @MSKmass_maintenance_id
 
	SELECT	@rowsfound = @rowsfound + @@rowcount
 
	SELECT @MSKmass_maintenance_id	= MAX(mass_maintenance_id)
	FROM ammashdr
	WHERE	mass_maintenance_id	< @MSKmass_maintenance_id
END
SELECT
	timestamp,
	mass_maintenance_id,
	mass_description,
	one_at_a_time,
	user_id,
	group_id,
	assets_purged,
	process_start_date = convert(char(8),process_start_date, 112),
	process_end_date = convert(char(8),process_end_date, 112),
	error_code,
	error_message
FROM	#temp
ORDER BY	mass_maintenance_id
 
DROP TABLE #temp
 
RETURN 0
GO
GRANT EXECUTE ON  [dbo].[ammashdrLast_sp] TO [public]
GO
