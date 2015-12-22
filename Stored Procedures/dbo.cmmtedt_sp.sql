SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO




CREATE PROCEDURE [dbo].[cmmtedt_sp] @only_errors smallint, @debug_level smallint = 0
AS

DECLARE
 @result int, @error_level smallint


IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/cmmtedt.sp" + ", line " + STR( 31, 5 ) + " -- ENTRY: "

IF ((SELECT COUNT(*) FROM #cmmtvhdr) < 1) RETURN 0

IF @only_errors = 1
 SELECT @error_level = 0
ELSE 
	SELECT @error_level = 1


EXEC @result = cmmthdr1_sp @error_level, @debug_level
IF (@result != 0)
 RETURN @result

EXEC @result = cmmtdet1_sp @error_level, @debug_level
IF (@result != 0)
 RETURN @result


IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/cmmtedt.sp" + ", line " + STR( 50, 5 ) + " -- EXIT: "

RETURN 0
GO
GRANT EXECUTE ON  [dbo].[cmmtedt_sp] TO [public]
GO
