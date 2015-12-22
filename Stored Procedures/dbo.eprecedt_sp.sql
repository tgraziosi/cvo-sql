SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO




CREATE PROCEDURE [dbo].[eprecedt_sp] @only_errors smallint
AS

DECLARE
 @result int, @error_level smallint



IF ((SELECT COUNT(*) FROM #epinvhdr) < 1) RETURN 0

IF @only_errors = 1
	SELECT @error_level = 0
ELSE 
	SELECT @error_level = 1


EXEC @result = epinvhdr1_sp @error_level
EXEC @result = epinvdtl1_sp @error_level

RETURN 0
GO
GRANT EXECUTE ON  [dbo].[eprecedt_sp] TO [public]
GO
