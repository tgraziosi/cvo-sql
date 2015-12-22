SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROC [dbo].[arwoedt_sp]	@only_error	smallint,
				@debug_level	smallint = 0
AS

DECLARE	
	@result	smallint,
	@error_level	smallint

BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arwoedt.sp" + ", line " + STR( 31, 5 ) + " -- ENTRY: "

	
	IF ((	SELECT COUNT(*) 
		FROM #arvalpyt) < 1) 
		RETURN 0
	
	
	IF @only_error = 1
		SELECT @error_level = 3
	ELSE
		SELECT @error_level = 2
	
	EXEC @result = ARWOValidateHeader1_SP	@error_level,
							@debug_level
	IF( @result != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arwoedt.sp" + ", line " + STR( 54, 5 ) + " -- EXIT: "
		RETURN @result
	END

	
	EXEC @result = ARWOValidateDetail1_SP	@error_level,
							@debug_level
	IF( @result != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arwoedt.sp" + ", line " + STR( 66, 5 ) + " -- EXIT: "
		RETURN @result
	END


	RETURN 0
END
GO
GRANT EXECUTE ON  [dbo].[arwoedt_sp] TO [public]
GO
