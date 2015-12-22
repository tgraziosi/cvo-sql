SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO




CREATE PROCEDURE [dbo].[appadedt_sp] @only_errors smallint,
							 @debug_level smallint = 0
AS

DECLARE
		 @result int,
 @batch_mode smallint,
		 @error_level smallint


IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/appadedt.sp" + ", line " + STR( 32, 5 ) + " -- ENTRY: "

IF @only_errors = 1
	SELECT @error_level = 0
ELSE
	SELECT @error_level = 1


EXEC @result = appahdr1_sp @error_level, @debug_level

EXEC @result = appahdr2_sp @error_level, @debug_level

EXEC @result = appadet1_sp @error_level, @debug_level


IF (@only_errors = 1)
 DELETE #ewerror
 FROM #ewerror a, apedterr b
 WHERE a.err_code = b.err_code
 AND b.err_type > 0 



IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/appadedt.sp" + ", line " + STR( 55, 5 ) + " -- EXIT: "

RETURN 0
GO
GRANT EXECUTE ON  [dbo].[appadedt_sp] TO [public]
GO
