SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

 
CREATE PROCEDURE [dbo].[amgrphdrFirstRow_sp]
AS
 
DECLARE	@MSKgroup_code	smGroupCode
 
 
 
SELECT	@MSKgroup_code	= MIN(group_code)
FROM	amgrphdr
 
SELECT
	timestamp,
	group_code,
	group_id,
	group_description,
	group_edited
FROM	amgrphdr
WHERE	group_code	= @MSKgroup_code
 
RETURN 0
GO
GRANT EXECUTE ON  [dbo].[amgrphdrFirstRow_sp] TO [public]
GO
