SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

 
CREATE PROCEDURE [dbo].[amgrphdrLastFilt_sp]
(
	@rowsrequested		smCounter = 1,
	@group_code_filter 	smGroupCode
)
AS
 
DECLARE	@rowsfound	smCounter
DECLARE	@MSKgroup_code	smGroupCode
 
CREATE TABLE #temp
(
	timestamp	varbinary(8)	NULL,
	group_code	char(8)	NULL,
	group_id	int	NULL,
	group_description	varchar(40)	NULL,
	group_edited	tinyint	NULL
)
 
SELECT	@rowsfound	= 0
 
 
SELECT	@MSKgroup_code	= MAX(group_code)
FROM	amgrphdr
WHERE	group_code LIKE RTRIM(@group_code_filter)
 
IF @MSKgroup_code IS NULL
BEGIN
	DROP TABLE #temp
	RETURN
END
 
INSERT INTO #temp
SELECT
	timestamp,
	group_code,
	group_id,
	group_description,
	group_edited
FROM	amgrphdr
WHERE	group_code	= @MSKgroup_code
 
SELECT @rowsfound = @@rowcount
 
SELECT @MSKgroup_code	= MAX(group_code)
FROM	amgrphdr
WHERE	group_code < @MSKgroup_code
 AND group_code LIKE RTRIM(@group_code_filter)
 
WHILE @MSKgroup_code IS NOT NULL AND @rowsfound < @rowsrequested
BEGIN
 
	INSERT INTO #temp
	SELECT
		timestamp,
		group_code,
		group_id,
		group_description,
		group_edited
	FROM	amgrphdr
	WHERE		group_code = @MSKgroup_code
 
	SELECT	@rowsfound = @rowsfound + @@rowcount
 
	SELECT @MSKgroup_code	= MAX(group_code)
	FROM amgrphdr
	WHERE	group_code	< @MSKgroup_code
	AND	group_code LIKE RTRIM(@group_code_filter)
END
SELECT
	timestamp,
	group_code,
	group_id,
	group_description,
	group_edited
FROM	#temp
ORDER BY	group_code
 
DROP TABLE #temp
 
RETURN 0
GO
GRANT EXECUTE ON  [dbo].[amgrphdrLastFilt_sp] TO [public]
GO
