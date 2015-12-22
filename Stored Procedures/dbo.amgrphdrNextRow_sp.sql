SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

 
CREATE PROCEDURE [dbo].[amgrphdrNextRow_sp]
(
	@group_code 	smGroupCode
)
AS
 
DECLARE	@MSKgroup_code	smGroupCode
 
SELECT	@MSKgroup_code	= @group_code
 
SELECT	@MSKgroup_code	= MIN(group_code)
FROM	amgrphdr
WHERE	group_code > @MSKgroup_code
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
GRANT EXECUTE ON  [dbo].[amgrphdrNextRow_sp] TO [public]
GO
