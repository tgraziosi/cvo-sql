SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROC [dbo].[arcmedt_sp]	@only_error	smallint,
				@debug_level	smallint = 0
AS

DECLARE	
	@result	int,
	@error_level	smallint

BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcmedt.sp" + ", line " + STR( 41, 5 ) + " -- ENTRY: "
	
	
	IF ((	SELECT COUNT(*) 
		FROM #arvalchg) < 1) 
		RETURN 0
		
	
	IF @only_error = 1
		SELECT @error_level = 3
	ELSE
		SELECT @error_level = 2

	
	EXEC @result = ARCMValidateHeader1_SP	@error_level,
							@debug_level
	IF( @result != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcmedt.sp" + ", line " + STR( 65, 5 ) + " -- EXIT: "
		RETURN @result
	END

	
	EXEC @result = ARCMValidateHeader2_SP	@error_level,
							@debug_level
	IF( @result != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcmedt.sp" + ", line " + STR( 76, 5 ) + " -- EXIT: "
		RETURN @result
	END
	
	
	EXEC @result = ARCMValidateHeader3_SP	@error_level,
							@debug_level
	IF( @result != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcmedt.sp" + ", line " + STR( 87, 5 ) + " -- EXIT: "
		RETURN @result
	END
	
	
	EXEC @result = ARCMValidateHeader4_SP	@error_level,
							@debug_level
	IF( @result != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcmedt.sp" + ", line " + STR( 98, 5 ) + " -- EXIT: "
		RETURN @result
	END
	
	
	EXEC @result = ARCMValidateTaxDetail_SP	@error_level,
							@debug_level
	IF( @result != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcmedt.sp" + ", line " + STR( 109, 5 ) + " -- EXIT: "
		RETURN @result
	END
	
	
	EXEC @result = ARCMValidateLineItem_SP	@error_level,
							@debug_level
	IF( @result != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcmedt.sp" + ", line " + STR( 120, 5 ) + " -- EXIT: "
		RETURN @result
	END
	
	
	EXEC @result = ARCMValidateRefCode_SP	@error_level,
							@debug_level
	IF( @result != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcmedt.sp" + ", line " + STR( 131, 5 ) + " -- EXIT: "
		RETURN @result
	END


	RETURN 0
END
GO
GRANT EXECUTE ON  [dbo].[arcmedt_sp] TO [public]
GO
