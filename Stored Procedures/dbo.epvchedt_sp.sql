SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE [dbo].[epvchedt_sp] @only_errors smallint
AS

DECLARE
 @result int, @error_level smallint



IF ((SELECT COUNT(*) FROM #epvchhdr) < 1) RETURN 0

IF @only_errors = 1
	SELECT @error_level = 0
ELSE 
	SELECT @error_level = 1


EXEC @result = epvchhdr1_sp @error_level

EXEC @result = epvchdtl1_sp @error_level

RETURN 0
GO
GRANT EXECUTE ON  [dbo].[epvchedt_sp] TO [public]
GO
