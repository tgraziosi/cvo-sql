SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

 
CREATE PROCEDURE [dbo].[amgrphdrNext_sp]
(
	@rowsrequested		smCounter = 1,
	@group_code 	smGroupCode
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
SELECT	@MSKgroup_code	= @group_code
 
SELECT @MSKgroup_code	= MIN(group_code)
FROM	amgrphdr
WHERE	group_code > @MSKgroup_code
 
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
 
	SELECT @MSKgroup_code	= MIN(group_code)
	FROM amgrphdr
	WHERE	group_code	> @MSKgroup_code
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
GRANT EXECUTE ON  [dbo].[amgrphdrNext_sp] TO [public]
GO
