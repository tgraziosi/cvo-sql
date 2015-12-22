SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO



CREATE PROCEDURE [dbo].[cminedt_sp] @only_errors smallint, @debug_level smallint = 0
AS

DECLARE
 @result int, @error_level smallint


IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/cminedt.sp" + ", line " + STR( 24, 5 ) + " -- ENTRY: "

IF ((SELECT COUNT(*) FROM #cminvdtl) < 1) RETURN 0

IF @only_errors = 1
 SELECT @error_level = 0
ELSE 
	SELECT @error_level = 1


EXEC @result = cmindet1_sp @error_level, @debug_level


IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/cminedt.sp" + ", line " + STR( 37, 5 ) + " -- EXIT: "

RETURN 0
GO
GRANT EXECUTE ON  [dbo].[cminedt_sp] TO [public]
GO
