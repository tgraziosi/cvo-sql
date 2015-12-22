SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO




CREATE PROCEDURE [dbo].[cmbtedt_sp] @only_errors smallint, @debug_level smallint = 0
AS

DECLARE
 @result int, @error_level smallint


IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/cmbtedt.sp" + ", line " + STR( 28, 5 ) + " -- ENTRY: "

IF ((SELECT COUNT(*) FROM #cmbtvhdr) < 1) RETURN 0

IF @only_errors = 1
 SELECT @error_level = 0
ELSE 
	SELECT @error_level = 1


EXEC @result = cmbthdr1_sp @error_level, @debug_level
IF (@result != 0)
 RETURN @result


IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/cmbtedt.sp" + ", line " + STR( 43, 5 ) + " -- EXIT: "

RETURN 0
GO
GRANT EXECUTE ON  [dbo].[cmbtedt_sp] TO [public]
GO
