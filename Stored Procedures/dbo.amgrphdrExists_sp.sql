SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

 
CREATE PROCEDURE [dbo].[amgrphdrExists_sp]
(
	@group_code 	smGroupCode,
	@valid		int OUTPUT
)
AS
 
IF EXISTS (SELECT 1 FROM amgrphdr
			WHERE	group_code 	= @group_code
			)
	SELECT @valid = 1
ELSE
	SELECT @valid = 0
 
RETURN 0
GO
GRANT EXECUTE ON  [dbo].[amgrphdrExists_sp] TO [public]
GO
